
if modifier_wet == nil then
	modifier_wet = class({})
end

function modifier_wet:IsHidden()
	return false
end

function modifier_wet:IsDebuff()
	return true
end

function modifier_wet:GetStatusEffectName()
	return "particles/status_fx/status_effect_slardar_amp_damage.vpcf"
end


function modifier_wet:OnDestroy()
	if IsServer() and self.particleIndex ~= nil then
		ParticleManager:DestroyParticle(self.particleIndex, false)
	end
end

function modifier_wet:OnCreated(kv)
	if IsServer() then
		self.particleIndex = ParticleManager:CreateParticle("particles/wet_drips.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
		self:AddParticle(self.particleIndex, false, false, -1, false, false)
	end
end