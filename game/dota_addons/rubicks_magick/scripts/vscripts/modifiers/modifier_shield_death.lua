
if modifier_shield_death == nil then
	modifier_shield_death = class({})
end

function modifier_shield_death:IsDebuff()
	return false
end

function modifier_shield_death:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_shield_death:OnDestroy()
	if IsServer() then
		self:GetParent().shieldElements[self.index] = nil
		if self.particleIndex ~= nil then
			ParticleManager:DestroyParticle(self.particleIndex, false)
		end
	end
end

function modifier_shield_death:OnCreated(kv)
	self.index = kv.index
	if IsServer() then
		self:GetParent().shieldElements[self.index] = ELEMENT_DEATH

		self.particleIndex = ParticleManager:CreateParticle("particles/shield_circles/shield_circle_death.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
		ParticleManager:SetParticleControl(self.particleIndex, 1, Vector(kv.circleRadius, 0, 0))
		self:AddParticle(self.particleIndex, false, false, -1, false, false)
	end
end