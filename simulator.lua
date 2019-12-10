require 'table-extension'
local methods = require'methods'

local points, speeds

math.randomseed( os.time() )

local n = arg[1] or 10
local N = arg[2] or 10--1000--10
local dt = arg[3] or (1/60)

--print(n,N)

local w,h = 1000,1000

local output = 'new_output.csv'

local function generateRandom()
	points = {}
	speeds = {}
	local rand = math.random
	for i=1,n do
		points[i] = {rand(w),rand(h)}
		speeds[i] = rand(100,150) --150
	end
	speeds[1] = rand(10,90) --100
end


local test_pool = {
	{'SectionW',methods.sectionWeight},
	{'Prediction_n3',methods.prediction},
	{'Prediction',methods.predictionOpt},
	{'Analytical',methods.analytical},
	{'Vector',methods.vector},
	{'VectorW',methods.vectorWrong}
}

local function dist_module(p1,p2)
	return math.sqrt(math.pow(p1[1]-p2[1],2) + math.pow(p1[2]-p2[2],2))
end

local function did_reach(ps,dt)
	for i=2,#ps do
		if dist_module(ps[i],ps[1]) <= dt*speeds[i-1] then
			return true
		end
	end
	return false
end

local ps
local timer, name
local start, sum, exe
print('Starting simulation with '..(n-1)..' pursuers and '..N..' simulations')

local execution = {}
for j=#test_pool,1,-1 do execution[j] = {fitness = 0, time = 0} end

-- PRINTING CSV
local file = io.open(output,'w')
file:write('px,py')
for i=1,n-1 do file:write(',px'..i..',py'..i) end
file:write(',m')
for i=1,n-1 do file:write(',m'..i) end
for i,v in ipairs(test_pool) do file:write(','..v[1]) end
file:write('\n')
--

for i=1,N do
	print('Simulation '..i)
	generateRandom()
	--CSV
	file:write(points[1][1]..','..points[1][2])
	for i=2,n do file:write(','..points[i][1]..','..points[i][2]) end
	for i=1,n do file:write(','..speeds[i]) end
	--
	--Run each test pool algorithm
	for j,v in ipairs(test_pool) do
		name = v[1]
		v = v[2]
		print('\t'..name)
		ps = table.copy(points)
		timer = 1
		sum = 0
		while not did_reach(ps,dt) do
			start = os.clock()
			v(ps,speeds,dt)
			sum = sum + os.clock()-start
			methods.weak(ps,speeds,dt)
			timer = timer + 1
		end
		file:write(','..timer)
		print(("\t\tTime: %d"):format(timer))

		local micro_t_exe = timer>1 and sum*1000000/(timer-1) or 0
		print(("\t\tExecution per iteration: %f (micro)s"):format(micro_t_exe))

		--execution status
		exe = execution[j]
		exe.fitness = exe.fitness + timer
		exe.time = exe.time + micro_t_exe
	end
	file:write('\n')
end
file:close()

for j,v in ipairs(execution) do
	print(test_pool[j][1], v.fitness/N, v.time/N)
end