local PURE_STONE_WALL_DURATION = 8.2
local ELEMENT_STONE_WALL_DURATION = 3.3
local ELEMENT_STONE_WALL_JUDDER_DELAY = 0.85

local PHASE_JUDDER = 0
local PHASE_DESTRUCT = 1
local PHASE_DEATH = 2

if modifier_stone_wall == nil then
	modifier_stone_wall = class({})
end

function modifier_stone_wall:IsPermanent()
	return false
end

function modifier_stone_wall:OnCreated(kv)
	if IsServer() then
		local wall = self:GetParent()
		
		self:CreateParticle()
		self:StartSounds()

		if wall.modifierElement == nil or wall.modifierElement == ELEMENT_EARTH then
			self.phase = PHASE_DESTRUCT
			self:StartIntervalThink(PURE_STONE_WALL_DURATION)
		else
			self.phase = PHASE_JUDDER
			self:StartIntervalThink(ELEMENT_STONE_WALL_JUDDER_DELAY)
		end
	end
end

function modifier_stone_wall:CreateParticle()
	local wall = self:GetParent()
	self.particle = ParticleManager:CreateParticle("particles/stone_wall/stone_wall.vpcf", PATTACH_ABSORIGIN, wall)

	local modifierElement = wall.modifierElement
	if modifierElement == nil or modifierElement == ELEMENT_EARTH then
		return
	end
	
	local water, life, cold, death, fire = 0, 0, 0, 0, 0
	if 		modifierElement == ELEMENT_WATER then	water = 1
	elseif	modifierElement == ELEMENT_LIFE then	life = 1
	elseif	modifierElement == ELEMENT_COLD then	cold = 1
	elseif	modifierElement == ELEMENT_DEATH then	death = 1
	elseif	modifierElement == ELEMENT_FIRE then	fire = 1
	end
	ParticleManager:SetParticleControl(self.particle, 2, Vector(water, life, cold))
	ParticleManager:SetParticleControl(self.particle, 3, Vector(death, fire, 0))
end

function modifier_stone_wall:StartSounds()
	local wall = self:GetParent()
	local modifierElement = wall.modifierElement
	if modifierElement == nil or modifierElement == ELEMENT_EARTH then
		return
	end
	
	local sounds
	if 		modifierElement == ELEMENT_WATER then	sounds = { "WaterStoneWall1" }
	elseif	modifierElement == ELEMENT_LIFE then	sounds = { "LifeStoneWall1", "LifeStoneWall2", "LifeStoneWall3" }
	elseif	modifierElement == ELEMENT_COLD then	sounds = { "ColdStoneWall1", "ColdStoneWall2" }
	elseif	modifierElement == ELEMENT_DEATH then	sounds = { "DeathStoneWall1", "DeathStoneWall2", "DeathStoneWall3" }
	elseif	modifierElement == ELEMENT_FIRE then	sounds = { "FireStoneWall1", "FireStoneWall2", "FireStoneWall3" }
	end
	
	wall.modifierSounds = sounds
	for _, sound in pairs(sounds) do
		wall:EmitSound(sound)
	end
end

function modifier_stone_wall:StopSounds()
	local wall = self:GetParent()
	local sounds = wall.modifierSounds
	if sounds == nil then
		return
	end
	for _, sound in pairs(sounds) do
		wall:StopSound(sound)
	end
end

function modifier_stone_wall:OnIntervalThink()
	local wall = self:GetParent()
	
	if self.phase == PHASE_DESTRUCT then
		self.phase = PHASE_DEATH
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
		self:StopSounds()
		self:GetParent():EmitSound("DestroyStoneWall1")
		self:StartIntervalThink(-1)
	end
end