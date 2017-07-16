
if modifier_shield_water_lua == nil then
	modifier_shield_water_lua = class({})
end

function modifier_shield_water_lua:IsDebuff()
	return false
end

function modifier_shield_water_lua:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_shield_cold_lua:OnDestroy()
	if IsServer() then
		self:GetParent():GetPlayerOwner().shieldElements[self.index] = nil
		if self.particleIndex ~= nil then
			ParticleManager:DestroyParticle(self.particleIndex, false)
		end
	end
end

function modifier_shield_water_lua:OnCreated(kv)
	self.index = kv.index
	self.duration = kv.duration
	if IsServer() then
		self:GetParent():GetPlayerOwner().shieldElements[self.index] = ELEMENT_WATER
		self:SetDuration(self.duration, true)
		self:StartIntervalThink(self.duration)

		self.particleIndex = ParticleManager:CreateParticle("particles/shield_circles/shield_circle_water.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
		ParticleManager:SetParticleControl(self.particleIndex, 1, Vector(kv.circleRadius, 0, 0))
		self:AddParticle(self.particleIndex, false, false, -1, false, false)
	end
end

function modifier_shield_cold_lua:OnIntervalThink()
	if IsServer() then
		self:StartIntervalThink(-1)
		self:Destroy()
	end
end