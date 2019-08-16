
if modifier_wet_cast_lightning == nil then
	modifier_wet_cast_lightning = class({})
end

function modifier_wet_cast_lightning:IsHidden()
	return false
end

function modifier_wet_cast_lightning:GetEffectName()
	return "particles/lightning/wet_cast_lightning.vpcf"
end

function modifier_wet_cast_lightning:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_wet_cast_lightning:OnCreated(kv)
	if IsServer() then
		HP:ApplyElement(self:GetParent(), self:GetParent(), ELEMENT_LIGHTNING, 150)
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
	return ACT_DOTA_CHANNEL_ABILITY_5
end

function modifier_wet_cast_lightning:GetOverrideAnimationRate(params)
	return 10.0
end

function modifier_wet_cast_lightning:GetActivityTranslationModifiers(params)
	return "witch_doctor_death_ward"
end