function table.find(t,obj)
	for i=1,#t do
		if t[i]==obj then
			return i
		end
	end
	return nil
end

function table.copy(t)
	local tn = {}
	for i,v in pairs(t) do
		tn[i] = type(v)=='table' and table.copy(v) or v
	end
	return tn
end

return true