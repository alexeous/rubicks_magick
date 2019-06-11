require("modifiers/helper_modifier_shield")

if modifier_shield_earth == nil then
	modifier_shield_earth = class({})
end

function modifier_shield_earth:IsDebuff()
	return false
end

function modifier_shield_earth:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_shield_earth:OnDestroy()
	HelperModifierShield:StdOnDestroy(self)
end

function modifier_shield_earth:OnCreated(kv)
	HelperModifierShield:StdOnCreated(self, kv, ELEMENT_EARTH, "particles/shield_circles/shield_circle_earth.vpcf")
end

function modifier_shield_earth:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
	}
	return funcs
end

function modifier_shield_earth:GetModifierMoveSpeedBonus_Percentage(params)
	return -10.0
end