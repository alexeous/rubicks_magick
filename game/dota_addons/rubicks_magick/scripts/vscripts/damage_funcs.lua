if DamageFuncs == nil then
    DamageFuncs = class({})
end

function DamageFuncs:ResolveValue(value, target)
	local t = type(value)
	if t == "number" then
		return value
	elseif t == "function" then
		return value(target)
	end
    return 0
end

function DamageFuncs:Reciprocal(initialValue)
    local hitCounts = {}
    return function(target)
        local count = (hitCounts[target] or 0) + 1
        hitCounts[target] = count
        return initialValue / count
    end
end