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
	local function AccessSettings()
		local hero = player:GetAssignedHero()
		local duration = self:GetDurationValue(player:GetPlayerID(), isWriting)
		if hero:HasModifier("modifier_settings_accessor") then
			hero:RemoveModifierByName("modifier_settings_accessor")
		end
		local modifier = hero:AddNewModifier(hero, nil, "modifier_settings_accessor", { duration = duration })
		hero:SetModifierStackCount("modifier_settings_accessor", hero, stacksValue or 0)
		if not isWriting then
			local index = table.indexOf(hero:FindAllModifiers(), modifier) - 1 -- minus one because in JS indexing starts with 0 while in lua with 1
			CustomGameEventManager:Send_ServerToPlayer(player, "rm_settings_loading", { modifierIdx = index })
		end
	end
	local maxWaitingTime = 100
	Util:DoOnceTrue(IsHeroAvailable, AccessSettings, maxWaitingTime)
end

function SettingsSaver:GetDurationValue(playerID, isWriting)
	local writingBit = isWriting and DURATION_WRITING_FLAG or 0
	return bit.bor(playerID, DURATION_EVER_PRESENT_BIT, writingBit)
end