require("modifiers/helper_modifier_shield")

if modifier_shield_life == nil then
	modifier_shield_life = class({})
end

function modifier_shield_life:IsDebuff()
	return false
end

function modifier_shield_life:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_shield_life:OnDestroy()
	HelperModifierShield:StdOnDestroy(self)
end

function modifier_shield_life:OnCreated(kv)
	HelperModifierShield:StdOnCreated(self, kv, ELEMENT_LIFE, "particles/shield_circles/shield_circle_life.vpcf")
	if IsServer() then
		self:StartIntervalThink(1)
	end
end

function modifier_shield_life:OnIntervalThink()
	local parent = self:GetParent()
	HP:ApplyElement(parent, parent, ELEMENT_LIFE, 25, true)

	ParticleManager:CreateParticle("particles/shield_life_healing/shield_life_healing.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
	parent:EmitSound("SelfShieldLifeThink")
end