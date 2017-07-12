
if modifier_slow_move == nil then
	modifier_slow_move = class({})
end

function modifier_slow_move:IsHidden()
	return true
end

function modifier_slow_move:OnCreated(kv)
	self.percentage = -kv.slowMovePercentage
end

function modifier_slow_move:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
	}
	return funcs
end

function modifier_slow_move:GetModifierMoveSpeedBonus_Percentage(params)
	return self.percentage
end