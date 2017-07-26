
if modifier_frozen == nil then
	modifier_frozen = class({})
end

function modifier_frozen:IsHidden()
	return false
end

function modifier_frozen:IsDebuff()
	return true
end

function modifier_frozen:GetStatusEffectName()
	return "particles/status_fx/status_effect_snow_heavy.vpcf"
end

function modifier_frozen:OnDestroy()
	if IsServer() then
		self:GetParent():SetAbsOrigin(self.startOrigin)

		if self.particleIndex ~= nil then
			ParticleManager:DestroyParticle(self.particleIndex, false)
		end
		local releaseBurst = ParticleManager:CreateParticle("particles/units/heroes/hero_tusk/tusk_frozen_sigil_death.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(releaseBurst, 2, self.startOrigin + Vector(0, 0, 80))
		self:AddParticle(releaseBurst, false, false, -1, false, false)
	end
end

function modifier_frozen:OnCreated(kv)
	if IsServer() then
		self:RemoveAllModifiers()

		self.startOrigin = self:GetParent():GetAbsOrigin()
		self:SetStackCount(10)

		self.particleIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_ancient_apparition/ancient_apparition_cold_feet_frozen.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
		self:AddParticle(self.particleIndex, false, false, -1, false, false)
	end
end

function modifier_frozen:RemoveAllModifiers()
	local parent = self:GetParent()
	SelfShield:RemoveAllShields(parent)

	local player = parent:GetPlayerOwner()
	if player ~= nil then
		Elements:RemoveAllElements(player)
		Spells:StopCasting(player)
	end
end

function modifier_frozen:ReleaseProgress()
	if IsServer() then
		self:DecrementStackCount()
		if self:GetStackCount() <= 0 then
			self:Destroy()
		else
			self.shakeRadius = 30 - self:GetStackCount() * 2.5
			self:StartIntervalThink(0.02)
			self:OnIntervalThink()
		end
	end
end


RANDOM_SHAKE_DIRECTIONS = {
	Vector(    1,     0,  0), 
	Vector( 0.87,   0.5,  0),
	Vector(  0.5,  0.87,  0),
	Vector(    0,     1,  0),
	Vector( -0.5,  0.87,  0),
	Vector(-0.87,   0.5,  0),
	Vector(   -1,     0,  0),
	Vector(-0.87,  -0.5,  0),
	Vector( -0.5, -0.87,  0),
	Vector(    0,    -1,  0),
	Vector(  0.5, -0.87,  0),
	Vector( 0.87,  -0.5,  0)
}
function modifier_frozen:OnIntervalThink()
	if IsServer() then
		if self.shakeRadius <= 0 then
			self:StartIntervalThink(-1)
			self:GetParent():SetAbsOrigin(self.startOrigin)
		else
			local offset = self.shakeRadius * RANDOM_SHAKE_DIRECTIONS[math.random(1, 12)]
			self:GetParent():SetAbsOrigin(self.startOrigin + offset)
			self.shakeRadius = self.shakeRadius - 5
		end
	end
end

function modifier_frozen:CheckState()
	local state = {
		[MODIFIER_STATE_FROZEN] = true,
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_INVULNERABLE] = true
	} 
	return state
end