
if modifier_lightning_stun == nil then
	modifier_lightning_stun = class({})
end

function modifier_lightning_stun:IsHidden()
	return true
end

function modifier_lightning_stun:CheckState()
	local state = {
		[MODIFIER_STATE_ROOTED] = true
	} 
	return state
end