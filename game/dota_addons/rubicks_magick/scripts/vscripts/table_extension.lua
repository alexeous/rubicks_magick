
table.indexOf = function(t, key)
	for k, v in pairs(t) do
		if v == key then
			return k 
		end
	end
	return nil
end

table.clone = function(t)
	local result = {}
	for k, v in pairs(t) do 
		result[k] = v
	end
	return result
end