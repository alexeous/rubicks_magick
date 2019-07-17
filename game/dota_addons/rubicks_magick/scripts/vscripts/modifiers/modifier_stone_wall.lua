local PURE_STONE_WALL_DURATION = 8.2
local ELEMENT_STONE_WALL_DURATION = 3.3
local ELEMENT_STONE_WALL_JUDDER_DELAY = 0.85

local PHASE_JUDDER = 0
local PHASE_DESTRUCT = 1

if modifier_stone_wall == nil then
	modifier_stone_wall = class({})
end

function modifier_stone_wall:IsPermanent()
	return false
end

function modifier_stone_wall:OnCreated(kv)
	if IsServer() then
		local wall = self:GetParent()

		self.particle = ParticleManager:CreateParticle("particles/stone_wall/stone_wall.vpcf", PATTACH_ABSORIGIN, wall)

		if wall.modifierElement == nil or wall.modifierElement == ELEMENT_EARTH then
			self.phase = PHASE_DESTRUCT
			self:StartIntervalThink(PURE_STONE_WALL_DURATION)
		else
			self.phase = PHASE_JUDDER
			self:StartIntervalThink(ELEMENT_STONE_WALL_JUDDER_DELAY)
		end
	end
end

function modifier_stone_wall:OnIntervalThink()
	local wall = self:GetParent()
	
	if self.phase == PHASE_DESTRUCT then
		wall:Kill(nil, nil)
		return
	end

	if self.phase == PHASE_JUDDER then
		StoneWall:MakeReadyForBlast(wall)
		ParticleManager:SetParticleControl(self.particle, 1, Vector(1, 0, 0))

		self.phase = PHASE_DESTRUCT
		self:StartIntervalThink(ELEMENT_STONE_WALL_DURATION - ELEMENT_STONE_WALL_JUDDER_DELAY)
	end
end

function modifier_stone_wall:OnDestroy()
	if IsServer() then
		ParticleManager:DestroyParticle(self.particle, false)
		self:StartIntervalThink(-1)
	end
end