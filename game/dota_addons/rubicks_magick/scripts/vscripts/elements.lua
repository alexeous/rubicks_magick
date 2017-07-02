ELEMENT_WATER = 1
ELEMENT_LIFE = 2
ELEMENT_SHIELD = 3
ELEMENT_COLD = 4
ELEMENT_LIGHTNING = 5
ELEMENT_DEATH = 6

if Elements == nil then
	Elements = class({})
end

ELEMENT_EARTH = 7
ELEMENT_FIRE = 8

NUM_ELEMENTS = 8
MAX_PICKED_ELEMENTS = 3

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

function Elements:Init()
	Convars:RegisterCommand("+rm_wtr",  function(...) return Elements:PickElement(ELEMENT_WATER) end, "Picked water element", 0)
	Convars:RegisterCommand("+rm_lif",  function(...) return Elements:PickElement(ELEMENT_LIFE) end, "Picked life element", 0)
	Convars:RegisterCommand("+rm_shld", function(...) return Elements:PickElement(ELEMENT_SHIELD) end, "Picked shield element", 0)
	Convars:RegisterCommand("+rm_cld",  function(...) return Elements:PickElement(ELEMENT_COLD) end, "Picked cold element", 0)
	Convars:RegisterCommand("+rm_ltg",  function(...) return Elements:PickElement(ELEMENT_LIGHTNING) end, "Picked lightning element", 0)
	Convars:RegisterCommand("+rm_dth",  function(...) return Elements:PickElement(ELEMENT_DEATH) end, "Picked death element", 0)
	Convars:RegisterCommand("+rm_ert",  function(...) return Elements:PickElement(ELEMENT_EARTH) end, "Picked earth element", 0)
	Convars:RegisterCommand("+rm_fir",  function(...) return Elements:PickElement(ELEMENT_FIRE) end, "Picked fire element", 0)
end

function Elements:PlayerConnected(player)
	player.pickedElements = {}
	player.orbParticles = {}
end

function Elements:PickElement(element)
	local player = Convars:GetCommandClient()
	-- trying to find an opposite
	local oppositeIndex = Elements:FindIndexOfOpposite(player, element)
	if oppositeIndex ~= nil then
		Elements:RemoveElement(player, oppositeIndex)
	else
		-- trying to find an empty place for the new element
		for i = 1, MAX_PICKED_ELEMENTS do
			if player.pickedElements[i] == nil then
				Elements:AddElement(player, element, i)
				break
			end
		end
	end
end

function Elements:FindIndexOfOpposite(player, element)
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
	player.pickedElements[index] = nil
	ParticleManager:DestroyParticle(player.orbParticles[index], false)
	ParticleManager:ReleaseParticleIndex(player.orbParticles[index])
end