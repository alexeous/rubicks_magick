require("modifiers/helper_modifier_shield")

if modifier_shield_death == nil then
	modifier_shield_death = class({})
end

function modifier_shield_death:IsDebuff()
	return false
end

function modifier_shield_death:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_shield_death:OnDestroy()
	HelperModifierShield:StdOnDestroy(self)
end

function modifier_shield_death:OnCreated(kv)
	HelperModifierShield:StdOnCreated(self, kv, ELEMENT_DEATH, "particles/shield_circles/shield_circle_death.vpcf")
end