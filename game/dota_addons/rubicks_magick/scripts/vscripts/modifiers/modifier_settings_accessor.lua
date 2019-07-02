require("libraries/timers")

local FILENAME = "rubicks_magick_control_config"

local DURATION_EVER_PRESENT_BIT = bit.lshift(1, 8)		-- to ensure that the modifier will not be destroyed too early
local DURATION_WRITING_FLAG = bit.lshift(1, 7)
local DURATION_PLAYER_ID_MASK = bit.bnot(bit.bor(DURATION_EVER_PRESENT_BIT, DURATION_WRITING_FLAG))

local STACK_COUNT_READING_COMPLETED_FLAG = bit.lshift(1, 31)
local STACK_COUNT_READING_FAILED_FLAG = bit.lshift(1, 30)
local STORED_VALUE_MASK = bit.bnot(bit.bor(STACK_COUNT_READING_COMPLETED_FLAG, STACK_COUNT_READING_FAILED_FLAG))

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
		if self:IsWritingFlagSet() then
			local masked = bit.band(self:GetStackCount(), STORED_VALUE_MASK)
			self:Write(masked)
		else
			self:Read()
		end
	end
end

function modifier_settings_accessor:OnRefresh(kv)
	self:OnCreated(kv)
end

function modifier_settings_accessor:IsTargetClient()
	if not IsClient() then
		return false
	end
	local function DecodeTargetPlayerID()
		local duration = math.floor(self:GetDuration())
		return bit.band(duration, DURATION_PLAYER_ID_MASK)
	end
	local localPlayerID = self:GetCaster():GetPlayerOwnerID()
	local targetPlayerID = DecodeTargetPlayerID()
	return localPlayerID == targetPlayerID
end

function modifier_settings_accessor:IsWritingFlagSet()
	return bit.band(math.floor(self:GetDuration()), DURATION_WRITING_FLAG) ~= 0
end

function modifier_settings_accessor:Read()
	local file = io.open(FILENAME, "r")
	if file == nil then
		self:ReadingFailed()
		print("Failed to read file '" .. FILENAME .. "': file handle == nil")
		return
	end
	local rawValue = file:read()
	local value = tonumber(rawValue)
	file:close()
	if value == nil then
		self:ReadingFailed()
		print("Failed to read file '" .. FILENAME .. "': value is not a number: ", rawValue)
		return
	end
	self:ReadingCompletedSuccessfully(value)
end

function modifier_settings_accessor:Write(value)
	local file = io.open(FILENAME, "w")
	if file ~= nil then
		file:write(value)
		file:close()
	else
		print("Failed to write to file '" .. FILENAME .. "': file handle == nil")
	end
end

function modifier_settings_accessor:ReadingFailed()
	self:SetStackCount(bit.bor(STACK_COUNT_READING_COMPLETED_FLAG, STACK_COUNT_READING_FAILED_FLAG))
end

function modifier_settings_accessor:ReadingCompletedSuccessfully(value)
	local masked = bit.band(value, STORED_VALUE_MASK)
	self:SetStackCount(bit.bor(masked, STACK_COUNT_READING_COMPLETED_FLAG))
end