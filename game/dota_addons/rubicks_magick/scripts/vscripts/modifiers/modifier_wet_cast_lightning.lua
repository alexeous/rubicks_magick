
if modifier_wet_cast_lightning == nil then
	modifier_wet_cast_lightning = class({})
end

function modifier_wet_cast_lightning:IsHidden()
	return true
end

function modifier_wet_cast_lightning:OnDestroy()
	if IsServer() and self.particleIndex ~= nil then
		ParticleManager:DestroyParticle(self.particleIndex, false)
	end
end

function modifier_wet_cast_lightning:OnCreated(kv)
	if IsServer() then
		Spells:ApplyElementDamage(self:GetParent(), self:GetParent(), ELEMENT_LIGHTNING, 150)

		self.particleIndex = ParticleManager:CreateParticle("particles/items_fx/chain_lightning_impact.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
		self:AddParticle(self.particleIndex, false, false, -1, false, false)
	end
end

function modifier_wet_cast_lightning:CheckState()
	local state = {
		[MODIFIER_STATE_STUNNED] = true
	} 
	return state
end

function modifier_wet_cast_lightning:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE,
		MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS
	}
	return funcs
end

function modifier_wet_cast_lightning:GetOverrideAnimation(params)
	return ACT_DOTA_CAST_ABILITY_5
end

function modifier_wet_cast_lightning:GetOverrideAnimationRate(params)
	return 1.0
end

function modifier_wet_cast_lightning:GetActivityTranslationModifiers(params)
	return "ravage"
end