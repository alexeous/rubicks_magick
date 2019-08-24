require("libraries/timers")

if Util == nil then
	Util = class({})
end

function Util:Precache(context)
	LinkLuaModifier("modifier_dummy", "modifiers/modifier_dummy.lua", LUA_MODIFIER_MOTION_NONE)
	PrecacheUnitByNameSync("npc_dummy_blank", context)
end

function Util:FindUnitsInRadius(center, radius, flagFilter)
	flagFilter = flagFilter or DOTA_UNIT_TARGET_FLAG_NONE
	return FindUnitsInRadius(DOTA_TEAM_NOTEAM, center, nil, radius, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, flagFilter, FIND_ANY_ORDER, true)
end

function Util:FindUnitsInLine(pos1, pos2, radius, flagFilter)
	flagFilter = flagFilter or DOTA_UNIT_TARGET_FLAG_NONE
	return FindUnitsInLine(DOTA_TEAM_NOTEAM, pos1, pos2, nil, radius, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, flagFilter)
end

function Util:FindUnitsInSector(center, radius, forward, angle, flagFilter)
	local units = Util:FindUnitsInRadius(center, radius, flagFilter)
	local halfCos = math.cos(math.rad(angle / 2))
	for key, unit in pairs(units) do
        if not Util:AngleBetweenVectorsLessThanAcosOf(forward, unit:GetAbsOrigin() - center, halfCos) then
			units[key] = nil
		end
	end
	return units
end

function Util:CreateDummy(position, owner)
	local dummy = Util:CreateDummyWithoutModifier(position, owner)
	dummy:AddNewModifier(dummy, nil, "modifier_dummy", {})
	return dummy
end

function Util:CreateDummyWithoutModifier(position, owner)
	local team = owner ~= nil and owner:GetTeam() or DOTA_TEAM_NOTEAM
	local dummy = CreateUnitByName("npc_dummy_blank", position, false, owner, nil, team)
	dummy:SetAbsOrigin(position)
	return dummy
end

function Util:EmitSoundOnLocation(location, soundName, caster)
	EmitSoundOnLocationWithCaster(location, soundName, caster)
end

function Util:Lerp(a, b, t)
	return a + (b - a) * t
end

function Util:DoOnceTrue(predicate, callback, maxWaitingTime, predicateCheckInterval)
	if predicate == nil or callback == nil then
		return
	end
	local startTime = GameRules:GetGameTime()
	return Timers:CreateTimer(function()
		if predicate() then
			callback()
			return nil
		end
		if maxWaitingTime ~= nil and GameRules:GetGameTime() - startTime > maxWaitingTime then
			return nil
		end
		return predicateCheckInterval or 0.02
	end)
end

function Util:CancelDoOnceTrue(name)
	Timers:RemoveTimer(name)
end

function Util:AngleBetweenVectorsLessThanAcosOf(vector1, vector2, cos)
	return vector1:Normalized():Dot(vector2:Normalized()) > cos
end

function Util:ClampVectorLength(vector, minLength, maxLength)
	local length = #vector
	if length < minLength then
		return vector / length * minLength
	elseif length > maxLength then
		return vector / length * maxLength
	end
	return vector
end

function Util:ProjectPointOnLine(point, lineA, lineB)
	local ab = lineB - lineA
	local abLen = #ab
	local ap = point - lineA
	local projVecLen = ab:Dot(ap) / abLen
	return lineA + ab * projVecLen / abLen	-- = lineA + (ab / abLen) * projVecLen = lineA + ab:Normalized() * projVecLen
end