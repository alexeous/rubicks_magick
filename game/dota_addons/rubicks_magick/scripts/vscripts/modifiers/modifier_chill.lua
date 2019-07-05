
LinkLuaModifier("modifier_frozen", "modifiers/modifier_frozen.lua", LUA_MODIFIER_MOTION_NONE)

if modifier_chill == nil then
	modifier_chill = class({})
end


local THINK_PERIOD = 0.1
local FREEZE_POINT = 220
local REDUCE_PER_SECOND = 22
local REDUCE_PER_THINK = REDUCE_PER_SECOND * THINK_PERIOD


function modifier_chill:IsHidden()
	return false
end

function modifier_chill:IsDebuff()
	return true
end

function modifier_chill:GetStatusEffectName()
	return "particles/status_fx/status_effect_snow_heavy.vpcf"
end

function modifier_chill:OnCreated(kv)
	if IsServer() then
		self.value = kv.power
		self:StartIntervalThink(THINK_PERIOD)

		self.enhanceTime = 0
	end
end

function modifier_chill:Enhance(value)
	if IsServer() then
		self.value = self.value + value
		if self.value >= FREEZE_POINT then
			self:StartIntervalThink(-1)
			self:GetParent():AddNewModifier(self:GetCaster(), nil, "modifier_frozen", { duration = 10.0 })
			self:Destroy()
		else
			self.enhanceTime = self:GetElapsedTime()
		end
	end
end

function modifier_chill:OnIntervalThink()
	if IsServer() then
		self.value = self.value - REDUCE_PER_THINK
		if self.value <= 0 then
			self:StartIntervalThink(-1)
			self:Destroy()
		end
	end
end

function modifier_chill:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
	}
	return funcs
end

function modifier_chill:GetModifierMoveSpeedBonus_Percentage(params)
	return -90 * ((self.value or 0) / FREEZE_POINT)
end