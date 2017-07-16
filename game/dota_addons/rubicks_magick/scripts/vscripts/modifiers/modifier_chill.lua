
LinkLuaModifier("modifier_frozen", "modifiers/modifier_frozen.lua", LUA_MODIFIER_MOTION_NONE)

if modifier_chill == nil then
	modifier_chill = class({})
end

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
		self:SetStackCount(kv.power)
		self:StartIntervalThink(0.6)

		self.enhanceTime = 0
	end
end

function modifier_chill:Enhance(value)
	if IsServer() then
		self:SetStackCount(self:GetStackCount() + value)
		if self:GetStackCount() >= 30 then
			self:StartIntervalThink(-1)
			self:GetParent():AddNewModifier(self:GetCaster(), nil, "modifier_frozen", {})
			self:Destroy()
		else
			self.enhanceTime = self:GetElapsedTime()
		end
	end
end

function modifier_chill:OnIntervalThink()
	if IsServer() then
		if self:GetElapsedTime() - self.enhanceTime < 2.0 then
			return
		end

		self:DecrementStackCount()
		if self:GetStackCount() == 0 then
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
	return -20 - self:GetStackCount()
end