
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
	return "particles/status_fx/status_effect_burn.vpcf"
end


function modifier_burn:OnDestroy()
	if IsServer() and self.particleIndex ~= nil then
		ParticleManager:DestroyParticle(self.particleIndex, false)
	end
end

function modifier_burn:OnCreated(kv)
	if IsServer() then
		self:SetDamage(30)
		
		self:StartIntervalThink(0.5)

		self.particleIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_huskar/huskar_burning_spear_debuff.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
		self:AddParticle(self.particleIndex, false, false, -1, false, false)
	end
end

function modifier_burn:Reapply()
	if IsServer() then
		self:SetDamage(30)
	end
end

function modifier_burn:SetDamage(damage)
	self.count = 10
	self:SetStackCount(self.count)

	damage = 10 * math.ceil(damage / 10)	-- snap to tens: 10, 20, 30 and so on
	self.damage = math.max(10, math.min(damage, 30))

	self.thinksToReduce = math.random(2, 4)
end

function modifier_burn:OnIntervalThink()
	if IsServer() then
		HP:ApplyElement(self:GetParent(), self:GetCaster(), ELEMENT_FIRE, self.damage, false, true)
		
		self.thinksToReduce = self.thinksToReduce - 1
		if self.thinksToReduce <= 0 then
			self.thinksToReduce = math.random(2, 4)
			self.damage = math.max(10, self.damage - 10)
		end

		self.count = self.count - 1
		self:SetStackCount(self.count)
		if self.count <= 0 then
			self:StartIntervalThink(-1)
			self:Destroy()
		end
	end
end