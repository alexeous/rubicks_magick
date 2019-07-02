require("util")
require("libraries/timers")

local DURATION_EVER_PRESENT_BIT = bit.lshift(1, 8)		-- to ensure that the modifier will not be destroyed too early
local DURATION_WRITING_FLAG = bit.lshift(1, 7)

if SettingsSaver == nil then
	SettingsSaver = class({})
end
	
function SettingsSaver:Precache()
	LinkLuaModifier("modifier_settings_accessor", "modifiers/modifier_settings_accessor.lua", LUA_MODIFIER_MOTION_NONE)
end

function SettingsSaver:Init()
	SettingsSaver.settingsHolders = {}

	CustomGameEventManager:RegisterListener("rm_req_settings", Dynamic_Wrap(SettingsSaver, "OnSettingsRequested"))
	CustomGameEventManager:RegisterListener("rm_save_settings", Dynamic_Wrap(SettingsSaver, "SaveSettings"))
end

function SettingsSaver:OnSettingsRequested(keys)
	local player = PlayerResource:GetPlayer(keys.playerID)
	SettingsSaver:AccessSettingsViaModifier(player, false)
end

function SettingsSaver:SaveSettings(keys)
	local player = PlayerResource:GetPlayer(keys.playerID)
	SettingsSaver:AccessSettingsViaModifier(player, true, keys.value)
end

function SettingsSaver:AccessSettingsViaModifier(player, isWriting, stacksValue)
	local function IsHeroAvailable()
		return player:GetAssignedHero() ~= nil
	end
	local function ReadSettingsViaModifier()
		local settingsHolder = SettingsSaver:GetOrCreateSettingsHolder(player)
		local duration = self:GetDurationValue(player:GetPlayerID(), isWriting)
		if settingsHolder:HasModifier("modifier_settings_accessor") then
			settingsHolder:RemoveModifierByName("modifier_settings_accessor")
		end
		settingsHolder:AddNewModifier(settingsHolder, nil, "modifier_settings_accessor", { duration = duration})
		settingsHolder:SetModifierStackCount("modifier_settings_accessor", settingsHolder, stacksValue or 0)
		CustomGameEventManager:Send_ServerToPlayer(player, "rm_settings_loading", { holder = settingsHolder:GetEntityIndex() })
	end
	local maxWaitingTime = 10
	Util:DoOnceTrue(IsHeroAvailable, ReadSettingsViaModifier, maxWaitingTime)
end

function SettingsSaver:GetOrCreateSettingsHolder(player)
	local playerID = player:GetPlayerID()
	local settingsHolder = SettingsSaver.settingsHolders[playerID] or Util:CreateDummy(Vector(0, 0, 0), player:GetAssignedHero())
	SettingsSaver.settingsHolders[playerID] = settingsHolder
	return settingsHolder
end

function SettingsSaver:GetDurationValue(playerID, isWriting)
	local writingBit = isWriting and DURATION_WRITING_FLAG or 0
	return bit.bor(playerID, DURATION_EVER_PRESENT_BIT, writingBit)
end