require("modifiers/helper_modifier_shield")

if modifier_shield_fire == nil then
	modifier_shield_fire = class({})
end

function modifier_shield_fire:IsDebuff()
	return false
end

function modifier_shield_fire:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_shield_fire:OnDestroy()
	HelperModifierShield:StdOnDestroy(self)
end

function modifier_shield_fire:OnCreated(kv)
	HelperModifierShield:StdOnCreated(self, kv, ELEMENT_FIRE, "particles/shield_circles/shield_circle_fire.vpcf")
end