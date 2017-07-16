
if modifier_burn == nil then
	modifier_burn = class({})
end

function modifier_burn:IsHidden()
	return false
end

function modifier_burn:IsDebuff()
	return true
end

function modifier_burn:GetStatusEffectName()
	return "particles/status_fx/status_effect_burn.vpcf.vpcf"
end


function modifier_burn:OnDestroy()
	if IsServer() and self.particleIndex ~= nil then
		ParticleManager:DestroyParticle(self.particleIndex, false)
	end
end

function modifier_burn:OnCreated(kv)
	if IsServer() then
		self.count = 10
		self.damage = kv.startDamage / 2
		self:SetStackCount(self.damage)
		self:StartIntervalThink(0.5)

		self.particleIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_huskar/huskar_burning_spear_debuff.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
		self:AddParticle(self.particleIndex, false, false, -1, false, false)
	end
end

function modifier_burn:Reapply(newDamage)
	if IsServer() then
		self.count = 10
		self.damage = newDamage / 2
		self:SetStackCount(self.damage)
	end
end

function modifier_burn:OnIntervalThink()
	if IsServer() then
		Spells:ApplyElementDamage(self:GetParent(), self:GetCaster(), ELEMENT_FIRE, self.damage, false)
		
		self.damage = self.damage - 8
		self:SetStackCount(self.damage)
		self.count = self.count - 1
		if self.count <= 0 or self.damage <= 0 then
			self:StartIntervalThink(-1)
			self:Destroy()
		end
	end
end