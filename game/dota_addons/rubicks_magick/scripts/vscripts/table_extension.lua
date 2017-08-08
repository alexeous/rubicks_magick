
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