
if modifier_shield_cold == nil then
	modifier_shield_cold = class({})
end

function modifier_shield_cold:IsDebuff()
	return false
end

function modifier_shield_cold:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_shield_cold:OnDestroy()
	if IsServer() then
		self:GetParent().shieldElements[self.index] = nil
		if self.particleIndex ~= nil then
			ParticleManager:DestroyParticle(self.particleIndex, false)
		end
	end
end

function modifier_shield_cold:OnCreated(kv)
	self.index = kv.index
	if IsServer() then
		self:GetParent().shieldElements[self.index] = ELEMENT_COLD

		self.particleIndex = ParticleManager:CreateParticle("particles/shield_circles/shield_circle_cold.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
		ParticleManager:SetParticleControl(self.particleIndex, 1, Vector(kv.circleRadius, 0, 0))
		self:AddParticle(self.particleIndex, false, false, -1, false, false)
	end
end