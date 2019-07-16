
if modifier_bursted_body_invis == nil then
	modifier_bursted_body_invis = class({})
end

function modifier_bursted_body_invis:IsHidden()
	return true
end

function modifier_bursted_body_invis:RemoveOnDeath()
	return false
end

function modifier_bursted_body_invis:IsPermanent()
	return true
end

function modifier_bursted_body_invis:CheckState()
	local state = {
		[MODIFIER_STATE_INVISIBLE] = true,
		[MODIFIER_STATE_TRUESIGHT_IMMUNE] = true
	}
	return state	
end