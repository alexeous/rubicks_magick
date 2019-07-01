require("util")
require("libraries/timers")

if SettingsSaver == nil then
	SettingsSaver = class({})
end
	
function SettingsSaver:Precache()
	LinkLuaModifier("modifier_settings_accessor", "modifiers/modifier_settings_accessor.lua", LUA_MODIFIER_MOTION_NONE)
end

function SettingsSaver:Init()
	CustomGameEventManager:RegisterListener("rm_send_settings", Dynamic_Wrap(SettingsSaver, "SendSettings"))
end

function SettingsSaver:SendSettings(keys)
	local player = PlayerResource:GetPlayer(keys.playerID)
	local dummy = Util:CreateDummy(Vector(0, 0, 0))
	dummy:AddNewModifier(dummy, nil, "modifier_settings_accessor", {}) 
	CustomGameEventManager:Send_ServerToPlayer(player, "rm_settings_holder", { index = dummy:GetEntityIndex() })
end