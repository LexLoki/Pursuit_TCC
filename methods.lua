local m = {}

local time_i = require'Pursuit/time_intercep'
local sort = require'sorting'
require'table-extension'

local pow, atan2, sin, cos, pi, sqrt = math.pow, math.atan2, math.sin, math.cos, math.pi, math.sqrt

local function norm(t)
	return math.sqrt(t[1]*t[1]+t[2]*t[2])
end
local function normalize(t)
	local n = norm(t)
	t[1] = t[1]/n
	t[2] = t[2]/n
	return t
end

local function toDegree(v)
	return v*180/pi
end

-- Get array of distances from array of points, where the first is the source
local function distances(points)
	local arr = {}
	local x,y = points[1][1],points[1][2]
	for i=2,#points do
		arr[i-1] = {x-points[i][1],y-points[i][2]}--{points[i][1]-x,points[i][2]-y}
	end
	return arr
end

-- Get array of angles from array of points, where the first is the source
local function angles(points)
	local arr = {}
	local p = points[1]
	local x,y = p[1],p[2]
	for i=2,#points do
		p = points[i]
		arr[i-1] = atan2(p[2]-y,p[1]-x)
	end
	return arr
end

local function dist_module(p1,p2)
	return sqrt(pow(p1[1]-p2[1],2) + pow(p1[2]-p2[2],2))
end

-- Moves pursuers towards evader
local function moveFollow(points,speeds,dt)
	local p1 = points[1]
	local p
	local mov = {0,0}
	for i = 2, #points do
		p = points[i]
		mov[1],mov[2] = p1[1]-p[1], p1[2]-p[2]
		normalize(mov)
		p[1] = p[1] + mov[1]*speeds[i]*dt
		p[2] = p[2] + mov[2]*speeds[i]*dt
	end
end

-- Moves character towards an angle
local function moveAngle(p,speed,alpha,dt)
	p[1] = p[1] + speed*cos(alpha)*dt
	p[2] = p[2] + speed*sin(alpha)*dt
end

-- Vector Arithmetic with coefficient k
function m.vector(points,speeds,dt,k)
	k = k or 2
	--do return end
	local sum = {0,0}
	local p1 = points[1] --evader
	local p, mod_div
	for i=2,#points do
		p = points[i]  --pursuer
		mod_div = pow(dist_module(p1,p),k)
		sum[1] = sum[1] + ( p1[1]-p[1] )  / mod_div
		sum[2] = sum[2] + ( p1[2]-p[2] ) / mod_div
	end
	normalize(sum)
	--print(sum[1],sum[2])
	local speed = speeds[1]
	p1[1] = p1[1] + sum[1]*speed*dt
	p1[2] = p1[2] + sum[2]*speed*dt
	return sum
end

-- Vector Arithmetic with no coefficient
function m.vectorWrong(points,speeds,dt)
	--do return end
	local sum = {0,0}
	local p1 = points[1] --evader
	local p
	for i=2,#points do
		p = points[i]  --pursuer
		sum[1] = sum[1] + ( p1[1]-p[1] )
		sum[2] = sum[2] + ( p1[2]-p[2] )
	end
	normalize(sum)
	--print(sum[1],sum[2])
	local speed = speeds[1]
	p1[1] = p1[1] + sum[1]*speed*dt
	p1[2] = p1[2] + sum[2]*speed*dt
end

-- Base pursuit behaviour
function m.weak(points,speeds,dt)
	moveFollow(points,speeds,dt)
end

--To prompt extra debug
appp = false

--Pursuit Prediction 
--implementation: O(n^3)
function m.prediction(points,speeds,dt,shouldWalk)
	shouldWalk = shouldWalk==nil or shouldWalk
	local dist = distances(points)

	--Calculating interception maximums
	local maxs = {}
	for i=1,#dist do
		--always oposite angle
		maxs[i] = atan2(dist[i][2],dist[i][1])
	end

	--Calculating times interceptions equalities between characters
	--checking every pair for alp_{i,j}
	local interc = {}
	local comp = function(e1,e2) return e1 > e2 and 1 or e1 < e2 and -1 or 0 end
	for i=1,#dist do
		for j=i+1,#dist do
			local alp1,alp2 = time_i.calculate(dist[i][1],dist[i][2],dist[j][1],dist[j][2],speeds[i+1],speeds[j+1],speeds[1])
			if alp1 then
				table.insert(interc,alp1)
				table.insert(interc,alp2)
			end
			if appp then
				if alp1 then
					print(i,j,':',toDegree(alp1),toDegree(alp2))
					print(i,j,'in',toDegree(alp1),':',time_i.evaluate(dist[i][1],dist[i][2],speeds[i+1],speeds[1],alp1),time_i.evaluate(dist[j][1],dist[j][2],speeds[j+1],speeds[1],alp1))
					print(i,j,'in',toDegree(alp2),':',time_i.evaluate(dist[i][1],dist[i][2],speeds[i+1],speeds[1],alp2),time_i.evaluate(dist[j][1],dist[j][2],speeds[j+1],speeds[1],alp2))
				else
					print(i,j,':','no intersections')
				end
			end
		end
	end
	--sorting (in-place quick sort)
	sort.quickGen(interc,comp)

	table.insert(interc,1,0)
	table.insert(interc,2*pi)

	--test order
	if appp then
		print('dists')
		for i,v in ipairs(dist) do print(v[1],v[2]) end
		print('max')
		for i,v in ipairs(maxs) do print(v*180/pi) end
		print('int')
		for i,v in ipairs(interc) do print(v*180/pi) end
	end

	--computing global maximum
	local gam1,gam2
	local ev = function(idx,alpha) return time_i.evaluate(dist[idx][1],dist[idx][2],speeds[idx+1],speeds[1],alpha) end
	local opt_a,opt_v
	for i=1,#interc-1 do
		gam1,gam2 = interc[i],interc[i+1]
		local mid = (gam1+gam2)/2
		--finding the index of the lower bound function for [gam1,gam2]
		local lowerf_i = 1
		local v
		local lowerf_v = ev(1,mid)
		for i=2,#dist do
			v = ev(i,mid)
			if v < lowerf_v then
				lowerf_i,lowerf_v = i,v
			end
		end
		--getting [gam1,gam2] local optimal max, and v = f(max)
		local max = maxs[lowerf_i]
		if max < gam1 or max > gam2 then
			local v1,v2 = ev(lowerf_i,gam1),ev(lowerf_i,gam2)
			if v1 > v2 then
				max = gam1
				v = v1
			else
				max = gam2
				v = v2
			end
		else
			v = ev(lowerf_i,max)
		end
		if appp then
			print('Best on (' .. toDegree(gam1) .. ','..toDegree(gam2)..'):\n\tAngle: '..toDegree(max)..'\n\tTime: '..v)
		end
		--comparing to have global optimal
		if (not opt_a) or (v>opt_v) then
			opt_a,opt_v = max,v
		end
	end
	if appp then
		appp = false
		print('Global best: '..toDegree(opt_a),opt_v)
	end
	if shouldWalk then
		moveAngle(points[1],speeds[1],opt_a,dt)
	end
	return opt_a,opt_v
end


--Pursuit Prediction
--implementation: O(n^2log(n))
function m.predictionOpt(points,speeds,dt,shouldWalk)
	shouldWalk = shouldWalk==nil or shouldWalk
	local dist = distances(points)

	--Calculating interception maximums
	local maxs = {}
	for i=1,#dist do
		--always oposite angle
		maxs[i] = atan2(dist[i][2],dist[i][1])
	end

	--Calculating times interceptions equalities between characters
	--checking every pair for alp_{i,j}
	local interc = {}
	for i=1,#dist do
		for j=i+1,#dist do
			local alp1,alp2 = time_i.calculate(dist[i][1],dist[i][2],dist[j][1],dist[j][2],speeds[i+1],speeds[j+1],speeds[1])
			if alp1 then
				--add angle and indexes of intercepting functions
				table.insert(interc,{alp1,i,j})
				table.insert(interc,{alp2,i,j})
			end
		end
	end

	--sorting (in-place quick sort)
	local comp = function(e1,e2) return e1[1] > e2[1] and 1 or e1[1] < e2[1] and -1 or 0 end
	sort.quickGen(interc,comp)

	table.insert(interc,1,{0})
	table.insert(interc,{2*pi})

	--computing global maximum
	local gam1,gam2
	local ev = function(idx,alpha) return time_i.evaluate(dist[idx][1],dist[idx][2],speeds[idx+1],speeds[1],alpha) end
	local opt_a,opt_v

	local gam1,gam2 = interc[1][1],interc[2][1]
	local mid = (gam1+gam2)/2
	--finding the index of the lower bound function for first interval
	local lowerf_i = 1
	local v
	local lowerf_v = ev(1,mid)
	for i=2,#dist do
		v = ev(i,mid)
		if v < lowerf_v then
			lowerf_i,lowerf_v = i,v
		end
	end

	local function getLocal(index,min_a,max_a)
		local max = maxs[index]
		if max < min_a or max > max_a then
			local v1,v2 = ev(index,min_a), ev(index,max_a)
			if v1 > v2 then return min_a,v1 end
			return max_a,v2
		end
		return max,ev(index,max)
	end

	opt_a,opt_v = getLocal(lowerf_i,interc[1][1],interc[2][1])
	local intp1,intp2
	local idx1,idx2

	for i=1,#interc-1 do
		intp1,intp2 = interc[i],interc[i+1]
		gam1,gam2 = intp1[1], intp2[1]
		local mid = (gam1+gam2)/2

		idx1,idx2 = intp1[2],intp1[3]
		--lower function only change where it intercepts other
		if idx1 == lowerf_i or idx2 == lowerf_i then
			local idx = idx1 == lowerf_i and idx2 or idx1
			if ev(idx,mid) < ev(lowerf_i,mid) then
				lowerf_i = idx
			end
		end

		--getting [gam1,gam2] local optimal max, and v = f(max)
		local max,v = getLocal(lowerf_i,gam1,gam2)
		if appp then
			print('Best on (' .. toDegree(gam1) .. ','..toDegree(gam2)..'):\n\tAngle: '..toDegree(max)..'\n\tTime: '..v)
		end
		--comparing to have global optimal
		if (not opt_a) or (v>opt_v) then
			opt_a,opt_v = max,v
		end
	end
	if appp then
		appp = false
		print('Global best: '..toDegree(opt_a),opt_v)
	end
	if shouldWalk then
		moveAngle(points[1],speeds[1],opt_a,dt)
	end
	return opt_a,opt_v
end

function m.angle(p,speed,angle,dt)
	moveAngle(p,speed,angle,dt)
end

-- Analytical step
function m.analytical(points, speeds, dt)
	local p
	local n = #points-1
	local s = {n*points[1][1],n*points[1][2]}
	local x,y = points[1][1], points[1][2]
	for i=2, n+1 do
		p = points[i]
		s[1] = s[1] - p[1]
		s[2] = s[2] - p[2]
	end
	--normalize(s)
	local alpha = math.atan2(s[2],s[1])
	moveAngle(points[1],speeds[1],alpha,dt)
	return alpha
end

local function baseSection(points,speeds,dt,mean)
	local ang = angles(points)
	for i=1,#ang do
		ang[i] = {ang[i],i+1}
	end
	local comp = function(e1,e2) return e1[1] > e2[1] and 1 or e1[1] < e2[1] and -1 or 0 end
	sort.quickGen(ang,comp)
	local higher, size, idx_min,idx_max = 0,-1
	local s
	for i=2,#ang do
		s = ang[i][1]-ang[i-1][1]
		if s > size then
			higher,size,idx_min,idx_max = ang[i-1][1],s,ang[i-1][2], ang[i][2]
		end
	end
	local alpha = mean(idx_min, idx_max, higher, size)
	moveAngle(points[1],speeds[1],alpha,dt)
	return alpha
end

-- Section method
function m.section(points,speeds,dt)
	local mean = function(idx_min,idx_max,angle_min,size)
		return angle_min + size/2
	end
	return baseSection(points,speeds,dt,mean)
end

-- Section weighted method
function m.sectionWeight(points,speeds,dt)
	local mean = function(idx_min,idx_max,angle_min,size)
		local px,py = points[1][1],points[1][2]
		local x,y = px-points[idx_min][1], py-points[idx_min][2]
		local d1 = math.sqrt(x*x+y*y)
		x,y = px-points[idx_max][1], py-points[idx_max][2]
		local d2 = math.sqrt(x*x+y*y)
		return (d1*angle_min + d2*(angle_min+size)) / (d1+d2)
	end
	return baseSection(points,speeds,dt,mean)
end

local attt = false

function m.numerical(points, speeds, dt, shouldWalk, N)
	shouldWalk = shouldWalk == nil or shouldWalk
	N = N or 128
	local dttt = dt
	dt = dt*5
	local alp
	local a,a_v = nil,-1
	local dist = distances(points)
	for i=0,N-1 do
		alp = i*pi*2/N
		local reach = false
		ps = table.copy(points)
		local count = 0
		--print('step',i,alp)
		while not reach do
			moveFollow(ps,speeds,dt)
			moveAngle(ps[1],speeds[1],alp,dt)
			for i=2,#ps do
				if dist_module(ps[1],ps[i]) < dt*speeds[i] then
					reach = true
					--[[test]]
					if attt then
						print('idx'..i,'angle: '..toDegree(alp))
						print('predict: '..time_i.evaluate(dist[i-1][1],dist[i-1][2],speeds[i],speeds[1],alp))
					end
					--endtest
					break
				end
			end
			count = count+1
		end
		if attt then
			print('sim time: '..count*dt)
		end
		if count > a_v then
			a = alp
			a_v = count
		end
	end
	attt = false
	if shouldWalk then
		moveAngle(points[1],speeds[1],a,dttt)
	end
	return a
end


return m