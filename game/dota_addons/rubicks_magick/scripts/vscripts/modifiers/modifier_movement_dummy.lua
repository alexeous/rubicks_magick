
if modifier_movement_dummy == nil then
	modifier_movement_dummy = class({})
end

function modifier_movement_dummy:IsHidden()
	return true
end

function modifier_movement_dummy:IsPermanent()
	return true
end

function modifier_movement_dummy:CheckState()
	local state = {
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_NOT_ON_MINIMAP] = true,
		[MODIFIER_STATE_OUT_OF_GAME] = true,
		[MODIFIER_STATE_UNSELECTABLE] = true
	} 
	return state
end