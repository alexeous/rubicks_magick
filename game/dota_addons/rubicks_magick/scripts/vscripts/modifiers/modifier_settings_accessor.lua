require("libraries/timers")

if modifier_settings_accessor == nil then
	modifier_settings_accessor = class({})
end

function modifier_settings_accessor:IsHidden()
	return true
end

function modifier_settings_accessor:CheckState()
	return {}
end

function modifier_settings_accessor:OnCreated(kv)
	if IsClient() then
		self:SetStackCount(100)
	end
end