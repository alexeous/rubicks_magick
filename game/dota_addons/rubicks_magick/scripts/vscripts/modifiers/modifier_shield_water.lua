require("modifiers/helper_modifier_shield")

if modifier_shield_water == nil then
	modifier_shield_water = class({})
end

function modifier_shield_water:IsDebuff()
	return false
end

function modifier_shield_water:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_shield_water:OnDestroy()
	HelperModifierShield:StdOnDestroy(self)
end

function modifier_shield_water:OnCreated(kv)
	HelperModifierShield:StdOnCreated(self, kv, ELEMENT_WATER, "particles/shield_circles/shield_circle_water.vpcf")
end