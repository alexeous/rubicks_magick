require("libraries/timers")

local WRITING_FLAG = bit.lshift(1, 31)
local READING_COMPLETED_FLAG = bit.lshift(1, 30)
local READING_FAILED_FLAG = bit.lshift(1, 29)

if modifier_settings_accessor == nil then
	modifier_settings_accessor = class({})
end

function modifier_settings_accessor:IsHidden()
	return true
end

function modifier_settings_accessor:CheckState()
	return {}
end

function modifier_settings_accessor:OnCreated(kv)
	if self:IsTargetClient() then
		
	end
end

function modifier_settings_accessor:OnRefresh(kv)
	self:OnCreated(kv)
end

function modifier_settings_accessor:IsTargetClient()
	if not IsClient() then
		return false
	end
	local localPlayerID = self:GetCaster():GetPlayerOwnerID()
	local targetPlayerID = self:GetStackCount()
	return localPlayerID == targetPlayerID
end

function modifier_settings_accessor:Read()
	WRITING_FLAG
end