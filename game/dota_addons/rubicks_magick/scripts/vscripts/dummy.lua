if Dummy == nil then
	Dummy = class({})
end

function Dummy:Precache(context)
	LinkLuaModifier("modifier_dummy", "modifiers/modifier_dummy.lua", LUA_MODIFIER_MOTION_NONE)
	PrecacheUnitByNameSync("npc_dummy_blank", context)
end

function Dummy:Create(position, owner)
	local dummy = CreateUnitByName("npc_dummy_blank", position, false, owner, owner, owner:GetTeam())
	dummy:SetAbsOrigin(position)
	dummy:AddNewModifier(dummy, nil, "modifier_dummy", {})
	return dummy
end