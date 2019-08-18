local DURATION = 8.2

local PHASE_DESTRUCT = 1
local PHASE_DEATH = 2

if modifier_ice_wall == nil then
	modifier_ice_wall = class({})
end

function modifier_ice_wall:IsPermanent()
	return false
end

function modifier_ice_wall:OnCreated(kv)
	if IsServer() then
		self.phase = PHASE_DESTRUCT
		self:StartIntervalThink(DURATION)
		self:CreateParticle()
	end
end

function modifier_ice_wall:CreateParticle()
	local wall = self:GetParent()
	self.particle = ParticleManager:CreateParticle("particles/element_walls/ice_wall/ice_wall.vpcf", PATTACH_ABSORIGIN, wall)
end

function modifier_ice_wall:OnIntervalThink()
	if self.phase == PHASE_DESTRUCT then
		self.phase = PHASE_DEATH
		self:GetParent():Kill(nil, nil)
	end
end

function modifier_ice_wall:OnDestroy()
	if IsServer() then
		ParticleManager:DestroyParticle(self.particle, false)
		self:GetParent():EmitSound("DestroyIceWall1")
		self:StartIntervalThink(-1)
	end
end