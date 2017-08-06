if Util == nil then
	Util = class({})
end

function Util:FindUnitsInRadius(center, radius, flagFilter)
	flagFilter = flagFilter or DOTA_UNIT_TARGET_FLAG_NONE
	return FindUnitsInRadius(DOTA_TEAM_NOTEAM, center, nil, radius, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, flagFilter, FIND_ANY_ORDER, true)
end

function Util:FindUnitsInLine(pos1, pos2, radius, flagFilter)
	flagFilter = flagFilter or DOTA_UNIT_TARGET_FLAG_NONE
	return FindUnitsInLine(DOTA_TEAM_NOTEAM, pos1, pos2, nil, radius, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, flagFilter)
end