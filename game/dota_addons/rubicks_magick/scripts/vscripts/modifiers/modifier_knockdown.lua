
if modifier_knockdown == nil then
	modifier_knockdown = class({})
end

function modifier_knockdown:IsHidden()
	return false
end

function modifier_knockdown:IsDebuff()
	return true
end

function modifier_knockdown:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE,
		MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS
	}
	return funcs
end

function modifier_knockdown:CheckState()
	local state = {
		[MODIFIER_STATE_STUNNED] = true
	} 
	return state
end

function modifier_knockdown:GetOverrideAnimation(params)
	return ACT_DOTA_CAST_ABILITY_5
end

function modifier_knockdown:GetOverrideAnimationRate(params)
	return 0.8
end

function modifier_knockdown:GetActivityTranslationModifiers(params)
	return "mana_void"
end