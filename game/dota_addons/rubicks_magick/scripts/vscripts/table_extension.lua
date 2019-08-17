
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

table.count = function(t, key)
	local result = 0
	for k, v in pairs(t) do
		if v == key then
			result = result + 1
		end
	end
	return result
end

DEFAULT = 0
EMPTY = -1
table.serialRetrieve = function(t, indexTable, currentLevel)
	currentLevel = currentLevel or 1
	local index = indexTable[currentLevel]
	if index == nil then
		return t[EMPTY] or t[DEFAULT]
	end
	local currentNode = t[index] or t[DEFAULT]
	if type(currentNode) == "table" then
		local result = table.serialRetrieve(currentNode, indexTable, 1 + currentLevel)
		return result or t[DEFAULT]
	else
		return currentNode
	end
end

table.where = function(t, predicate)
	local result = {}
	for k, v in pairs(t) do
		if predicate(k, v) then
			result[k] = v
		end
	end
	return result
end

table.min = function(t, lessPredicate)
	local min = nil
	for _, v in pairs(t) do
		if min == nil or lessPredicate(v, min) then
			min = v
		end
	end
	return min
end

table.any = function(t, predicateOptional)
	if predicateOptional == nil then
		return next(t) ~= nil
	end

	for k, v in pairs(t) do
		if predicateOptional(k, v) then
			return true
		end
	end
	return false
end

table.removeItem = function(t, item)
	local index = table.indexOf(t, item)
	if index ~= nil then
		table.remove(t, index)
	end
end

table.createRange = function(start, count)
	local list = {}
	for i = 0, count - 1 do
		list[i + 1] = start + i
	end
	return list
end

table.popRandom = function(t)
	local length = #t
	if length == 0 then 
		return nil 
	end
	local i = RandomInt(1, length)
	local value = t[i]
	table.remove(t, i)
	return value
end