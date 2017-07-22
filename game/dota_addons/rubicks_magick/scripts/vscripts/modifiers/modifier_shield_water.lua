
if modifier_shield_water == nil then
	modifier_shield_water = class({})
end

function modifier_shield_water:IsDebuff()
	return false
end

function modifier_shield_water:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_shield_water:OnDestroy()
	if IsServer() then
		self:GetParent().shieldElements[self.index] = nil
		if self.particleIndex ~= nil then
			ParticleManager:DestroyParticle(self.particleIndex, false)
		end
	end
end

function modifier_shield_water:OnCreated(kv)
	self.index = kv.index
	if IsServer() then
		self:GetParent().shieldElements[self.index] = ELEMENT_WATER

		self.particleIndex = ParticleManager:CreateParticle("particles/shield_circles/shield_circle_water.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
		ParticleManager:SetParticleControl(self.particleIndex, 1, Vector(kv.circleRadius, 0, 0))
		self:AddParticle(self.particleIndex, false, false, -1, false, false)
	end
end