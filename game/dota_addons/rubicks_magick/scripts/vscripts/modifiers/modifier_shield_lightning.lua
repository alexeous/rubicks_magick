require("modifiers/helper_modifier_shield")

if modifier_shield_lightning == nil then
	modifier_shield_lightning = class({})
end

function modifier_shield_lightning:IsDebuff()
	return false
end

function modifier_shield_lightning:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_shield_lightning:OnDestroy()
	HelperModifierShield:StdOnDestroy(self)
end

function modifier_shield_lightning:OnCreated(kv)
	HelperModifierShield:StdOnCreated(self, kv, ELEMENT_LIGHTNING, "particles/shield_circles/shield_circle_lightning.vpcf")
end