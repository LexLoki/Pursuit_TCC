local sorting = {}

function sorting.bubble(array)
	local aux
	for last=#array,1,-1 do
		for i=2,last do
			if array[i-1]>array[i] then
				aux = array[i-1]
				array[i-1] = array[i]
				array[i] = aux
			end
			coroutine.yield({i,i-1})
		end
	end
end

function sorting.insertion(array)
	local r,i,j
	for i=2,#array do
		r = array[i]
		j = i-1
		while j>=1 do
			if array[j]<r then break end
			array[j+1] = array[j]
			coroutine.yield({j,j+1})
			j = j-1
		end
		array[j+1] = r
		coroutine.yield({j+1})
	end
end

function sorting.merge(array)
	local parts,x,i = {}
	for i,v in ipairs(array) do table.insert(parts,{v}) end
	while #parts>1 do
		c=1
		i = 1
		while i<=#parts-1 do
			local p1,p2,p3 = table.remove(parts,i),table.remove(parts,i),{}
			while #p1>0 and #p2>0 do
				x = p1[1] > p2[1] and table.remove(p2,1) or table.remove(p1,1)
				table.insert(p3, x)
				array[c] = x
				coroutine.yield({c})
				c = c+1
			end
			while #p1>0 do
				x = table.remove(p1,1)
				table.insert(p3,x)
				array[c] = x
				coroutine.yield({c})
				c = c+1
			end
			while #p2>0 do
				x = table.remove(p2,1)
				table.insert(p3,x)
				array[c] = x
				coroutine.yield({c})
				c = c+1
			end
			table.insert(parts,i,p3)
			i = i+1
		end
	end
end

local function is_sorted(array)
	for i=2,#array do
		if array[i]<array[i-1] then
			return false
		end
	end
	return true
end

function sorting.bogo(array)
	local aux,ind
	while not is_sorted(array) do
		for i=#array,1,-1 do
			ind = math.random(i)
			aux = array[i]
			array[i] = array[ind]
			array[ind] = aux
			coroutine.yield({i,ind})
		end
		--coroutine.yield()
	end
end

--comp: 0 equal, 1 higher, -1 lower
function sorting.quickGen(array,comp)
	local list,pivot,p,first,last,i,j,aux = {{1,#array}}
	while #list>0 do
		first = table.remove(list,1)
		last,first = first[2],first[1]
		p = math.floor((first+last)/2)
		pivot = array[p]
		i = first
		j = last
		while i<j do
			while comp(array[i],pivot)<0 do
				i = i+1
			end
			--coroutine.yield({{i,j},{p,first,last}})
			while comp(array[j],pivot)>0 do
				j = j-1
			end
			--coroutine.yield({{i,j},{p,first,last}})
			if i<=j then
				aux = array[i]
				array[i] = array[j]
				array[j] = aux
				i = i+1
				j = j-1
			end
			--coroutine.yield({{i,j},{p,first,last}})
		end
		if j>first then
			table.insert(list,{first,j})
		end
		if i<last then
			table.insert(list,{i,last})
		end
		--i = first, j=last
		--while i
	end
end

function sorting.quick(array)
	local list,pivot,p,first,last,i,j,aux = {{1,#array}}
	while #list>0 do
		first = table.remove(list,1)
		last,first = first[2],first[1]
		p = math.floor((first+last)/2)
		pivot = array[p]
		i = first
		j = last
		while i<j do
			while array[i]<pivot do
				i = i+1
			end
			coroutine.yield({{i,j},{p,first,last}})
			while array[j]>pivot do
				j = j-1
			end
			coroutine.yield({{i,j},{p,first,last}})
			if i<=j then
				aux = array[i]
				array[i] = array[j]
				array[j] = aux
				i = i+1
				j = j-1
			end
			coroutine.yield({{i,j},{p,first,last}})
		end
		if j>first then
			table.insert(list,{first,j})
		end
		if i<last then
			table.insert(list,{i,last})
		end
		--i = first, j=last
		--while i
	end
end

function sorting.counting(array)
	--assuming that every array of size n has interval k=n
	local k = #array
	local counter = {}
	for i=1,k do
		counter[i] = 0
	end
	for i,v in ipairs(array) do
		counter[i] = counter[i]+1
		coroutine.yield({i})
	end
	k=1
	for i,v in ipairs(counter) do
		while v>0 do
			array[k] = i
			k = k+1
			v = v-1
			coroutine.yield({k})
		end
	end
end


return sorting