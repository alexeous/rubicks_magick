
if modifier_shield_earth == nil then
	modifier_shield_earth = class({})
end

function modifier_shield_earth:IsDebuff()
	return false
end

function modifier_shield_earth:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_shield_cold:OnDestroy()
	if IsServer() then
		self:GetParent():GetPlayerOwner().shieldElements[self.index] = nil
		if self.particleIndex ~= nil then
			ParticleManager:DestroyParticle(self.particleIndex, false)
		end
	end
end

function modifier_shield_earth:OnCreated(kv)
	self.index = kv.index
	if IsServer() then
		self:GetParent():GetPlayerOwner().shieldElements[self.index] = ELEMENT_EARTH

		self.particleIndex = ParticleManager:CreateParticle("particles/shield_circles/shield_circle_earth.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
		ParticleManager:SetParticleControl(self.particleIndex, 1, Vector(kv.circleRadius, 0, 0))
		self:AddParticle(self.particleIndex, false, false, -1, false, false)
	end
end