
table.indexOf = function(t, key)
	for i = 1, #t do
		if t[i] == key then
			return i 
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