require("util")
require("libraries/timers")

local WRITING_FLAG = bit.lshift(1, 31)

if SettingsSaver == nil then
	SettingsSaver = class({})
end
	
function SettingsSaver:Precache()
	LinkLuaModifier("modifier_settings_accessor", "modifiers/modifier_settings_accessor.lua", LUA_MODIFIER_MOTION_NONE)
end

function SettingsSaver:Init()
	SettingsSaver.settingsHolders = {}

	CustomGameEventManager:RegisterListener("rm_send_settings", Dynamic_Wrap(SettingsSaver, "OnSettingsRequested"))
end

function SettingsSaver:OnSettingsRequested(keys)
	local player = PlayerResource:GetPlayer(keys.playerID)
	local function IsHeroAvailable()
		return player:GetAssignedHero() ~= nil 
	end
	local function ReadSettingsViaModifier()
		local stacksValue = SettingsSaver:GetStacksValueForReading(player)
		local settingsHolder = SettingsSaver:AccessSettingsViaModifier(player, stacksValue)
		CustomGameEventManager:Send_ServerToPlayer(player, "rm_settings_loading", { holder = settingsHolder:GetEntityIndex() })
	end
	local maxWaitingTime = 10
	Util:DoOnceTrue(IsHeroAvailable, ReadSettingsViaModifier, maxWaitingTime)
end

function SettingsSaver:AccessSettingsViaModifier(player, stacksValue)
	local settingsHolder = SettingsSaver:GetOrCreateSettingsHolder(player)
	settingsHolder:AddNewModifier(settingsHolder, nil, "modifier_settings_accessor", {})
	settingsHolder:SetModifierStackCount("modifier_settings_accessor", settingsHolder, stacksValue)
	return settingsHolder
end

function SettingsSaver:GetOrCreateSettingsHolder(player)
	local playerID = player:GetPlayerID()
	local settingsHolder = SettingsSaver.settingsHolders[playerID] or Util:CreateDummy(Vector(0, 0, 0), player:GetAssignedHero())
	SettingsSaver.settingsHolders[playerID] = settingsHolder
	return settingsHolder
end

function SettingsSaver:GetStacksValueForReading(player)
	return player:GetPlayerID()
end

function SettingsSaver:GetStacksValueForWriting(player)
	return bit.bor(player:GetPlayerID(), WRITING_FLAG)
end