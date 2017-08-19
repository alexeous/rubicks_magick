ELEMENT_SHIELD = 1
ELEMENT_EARTH = 2
ELEMENT_LIGHTNING = 3
ELEMENT_LIFE = 4
ELEMENT_DEATH = 5
ELEMENT_WATER = 6
ELEMENT_FIRE = 7
ELEMENT_COLD = 8

NUM_ELEMENTS = 8

OPPOSITE_ELEMENTS = {}
OPPOSITE_ELEMENTS[ELEMENT_WATER] =     { ELEMENT_LIGHTNING }
OPPOSITE_ELEMENTS[ELEMENT_LIFE] =      { ELEMENT_DEATH }
OPPOSITE_ELEMENTS[ELEMENT_SHIELD] =    { ELEMENT_SHIELD }
OPPOSITE_ELEMENTS[ELEMENT_COLD] =      { ELEMENT_FIRE }
OPPOSITE_ELEMENTS[ELEMENT_LIGHTNING] = { ELEMENT_WATER, ELEMENT_EARTH }
OPPOSITE_ELEMENTS[ELEMENT_DEATH] = 	   { ELEMENT_LIFE }
OPPOSITE_ELEMENTS[ELEMENT_EARTH] =	   { ELEMENT_LIGHTNING }
OPPOSITE_ELEMENTS[ELEMENT_FIRE] = 	   { ELEMENT_COLD }

ORB_PARTICLES = {}
ORB_PARTICLES[ELEMENT_WATER]     = "particles/orbs/water_orb/water_orb.vpcf"
ORB_PARTICLES[ELEMENT_LIFE]      = "particles/orbs/life_orb/life_orb.vpcf"
ORB_PARTICLES[ELEMENT_SHIELD]    = "particles/orbs/shield_orb/shield_orb.vpcf"
ORB_PARTICLES[ELEMENT_COLD]      = "particles/orbs/cold_orb/cold_orb.vpcf"
ORB_PARTICLES[ELEMENT_LIGHTNING] = "particles/orbs/lightning_orb/lightning_orb.vpcf"
ORB_PARTICLES[ELEMENT_DEATH]     = "particles/orbs/death_orb/death_orb.vpcf"
ORB_PARTICLES[ELEMENT_EARTH]     = "particles/orbs/earth_orb/earth_orb.vpcf"
ORB_PARTICLES[ELEMENT_FIRE]      = "particles/orbs/fire_orb/fire_orb.vpcf"

ORB_ORIGIN_OFFSETS = { Vector(73, -43, -200), Vector(-73,  -43, -200), Vector(0, 85, -200) }
CONTROL_OFFSET = 1

if Elements == nil then
	Elements = class({})
end

function Elements:Precache(context)
	PrecacheResource("particle_folder", "particles/orbs/fire_orb", context)
	PrecacheResource("particle_folder", "particles/orbs/death_orb", context)
	PrecacheResource("particle_folder", "particles/orbs/cold_orb", context)
	PrecacheResource("particle_folder", "particles/orbs/lightning_orb", context)
	PrecacheResource("particle_folder", "particles/orbs/shield_orb", context)
	PrecacheResource("particle_folder", "particles/orbs/earth_orb", context)
	PrecacheResource("particle_folder", "particles/orbs/life_orb", context)
	PrecacheResource("particle_folder", "particles/orbs/water_orb", context)
end

function Elements:Init()
	ListenToGameEvent("entity_killed", Dynamic_Wrap(Elements, "OnEntityKilled"), self)
end

function Elements:PlayerConnected(player)
	player.pickedElements = {}
	player.orbParticles = {}
end

function Elements:OnEntityKilled(keys)
	local killedUnit = EntIndexToHScript(keys.entindex_killed)
	if killedUnit ~= nil and killedUnit:IsRealHero() then
		local player = killedUnit:GetPlayerOwner()
		if player ~= nil then
			Elements:RemoveAllElements(killedUnit:GetPlayerOwner())
		end
	end
end

function Elements:GetPickedElements(player)
	if player == nil or player.pickedElements == nil then
		return nil
	end

	local result = {}
	for _, pickedElement in pairs(player.pickedElements) do
		if pickedElement ~= nil then
			table.insert(result, pickedElement)
		end
	end
	return result
end

function Elements:OnPickElement(playerID, element)
	local player = PlayerResource:GetPlayer(playerID)

	local heroEntity = player:GetAssignedHero()
	local isAble = (heroEntity ~= nil) and (heroEntity:IsAlive()) and (not heroEntity:IsStunned()) and (not heroEntity:IsFrozen())
	if not isAble then
		return
	end

	-- trying to find an opposite
	local oppositeIndex = Elements:IndexOfOpposite(player, element)
	if oppositeIndex ~= nil then
		Elements:RemoveElement(player, oppositeIndex)
	else
		-- trying to find an empty place for the new element
		for i = 1, 3 do
			if player.pickedElements[i] == nil then
				Elements:AddElement(player, element, i)
				break
			end
		end
	end
end

function Elements:IndexOfOpposite(player, element)
	for index, pickedElement in pairs(player.pickedElements) do
		local pickedElementOpposites = OPPOSITE_ELEMENTS[pickedElement]
		for _, opposite in pairs(pickedElementOpposites) do
			if opposite == element then     -- if there is an opposite of this element in the picked elements
				return index
			end
		end
	end
	return nil
end

function Elements:AddElement(player, element, index)
	player.pickedElements[index] = element
	local heroEntity = player:GetAssignedHero()
	player.orbParticles[index] = ParticleManager:CreateParticle(ORB_PARTICLES[element], PATTACH_ABSORIGIN_FOLLOW, heroEntity)
	ParticleManager:SetParticleControl(player.orbParticles[index], CONTROL_OFFSET, ORB_ORIGIN_OFFSETS[index])
end

function Elements:RemoveElement(player, index)
	if player.pickedElements ~= nil then
		player.pickedElements[index] = nil
	end
	if player.orbParticles ~= nil and player.orbParticles[index] ~= nil then
		ParticleManager:DestroyParticle(player.orbParticles[index], false)
		ParticleManager:ReleaseParticleIndex(player.orbParticles[index])
	end
end

function Elements:RemoveAllElements(player)
	Elements:RemoveElement(player, 1)
	Elements:RemoveElement(player, 2)
	Elements:RemoveElement(player, 3)
end