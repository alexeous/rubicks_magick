ELEMENT_SHIELD = 1
ELEMENT_EARTH = 2
ELEMENT_LIGHTNING = 3
ELEMENT_LIFE = 4
ELEMENT_DEATH = 5
ELEMENT_WATER = 6
ELEMENT_FIRE = 7
ELEMENT_COLD = 8

NUM_ELEMENTS = 8

OPPOSITE_ELEMENTS = {
	[ELEMENT_WATER] =     { ELEMENT_LIGHTNING },
	[ELEMENT_LIFE] =      { ELEMENT_DEATH },
	[ELEMENT_SHIELD] =    { ELEMENT_SHIELD },
	[ELEMENT_COLD] =      { ELEMENT_FIRE },
	[ELEMENT_LIGHTNING] = { ELEMENT_WATER, ELEMENT_EARTH },
	[ELEMENT_DEATH] = 	  { ELEMENT_LIFE },
	[ELEMENT_EARTH] =	  { ELEMENT_LIGHTNING },
	[ELEMENT_FIRE] = 	  { ELEMENT_COLD }
}

ORB_PARTICLES = {
	[ELEMENT_WATER]     = "particles/orbs/water_orb/water_orb.vpcf",
	[ELEMENT_LIFE]      = "particles/orbs/life_orb/life_orb.vpcf",
	[ELEMENT_SHIELD]    = "particles/orbs/shield_orb/shield_orb.vpcf",
	[ELEMENT_COLD]      = "particles/orbs/cold_orb/cold_orb.vpcf",
	[ELEMENT_LIGHTNING] = "particles/orbs/lightning_orb/lightning_orb.vpcf",
	[ELEMENT_DEATH]     = "particles/orbs/death_orb/death_orb.vpcf",
	[ELEMENT_EARTH]     = "particles/orbs/earth_orb/earth_orb.vpcf",
	[ELEMENT_FIRE]      = "particles/orbs/fire_orb/fire_orb.vpcf"
}

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
	PrecacheResource("soundfile", "soundevents/game_sounds_ui.vsndevts", context)
end

function Elements:Init()
	ListenToGameEvent("entity_killed", Dynamic_Wrap(Elements, "OnEntityKilled"), self)
	CustomGameEventManager:RegisterListener("rm_pick_water",     Dynamic_Wrap(Elements, "PickWater"))
	CustomGameEventManager:RegisterListener("rm_pick_life",      Dynamic_Wrap(Elements, "PickLife"))
	CustomGameEventManager:RegisterListener("rm_pick_shield",    Dynamic_Wrap(Elements, "PickShield"))
	CustomGameEventManager:RegisterListener("rm_pick_cold",      Dynamic_Wrap(Elements, "PickCold"))
	CustomGameEventManager:RegisterListener("rm_pick_lightning", Dynamic_Wrap(Elements, "PickLightning"))
	CustomGameEventManager:RegisterListener("rm_pick_death",     Dynamic_Wrap(Elements, "PickDeath"))
	CustomGameEventManager:RegisterListener("rm_pick_earth",     Dynamic_Wrap(Elements, "PickEarth"))
	CustomGameEventManager:RegisterListener("rm_pick_fire",      Dynamic_Wrap(Elements, "PickFire"))
end

function Elements:PickWater(keys)      Elements:PickElement(keys.playerID, ELEMENT_WATER)  end
function Elements:PickLife(keys)       Elements:PickElement(keys.playerID, ELEMENT_LIFE)  end
function Elements:PickShield(keys)     Elements:PickElement(keys.playerID, ELEMENT_SHIELD)  end
function Elements:PickCold(keys)       Elements:PickElement(keys.playerID, ELEMENT_COLD)  end
function Elements:PickLightning(keys)  Elements:PickElement(keys.playerID, ELEMENT_LIGHTNING)  end
function Elements:PickDeath(keys)      Elements:PickElement(keys.playerID, ELEMENT_DEATH)  end
function Elements:PickEarth(keys)      Elements:PickElement(keys.playerID, ELEMENT_EARTH)  end
function Elements:PickFire(keys)       Elements:PickElement(keys.playerID, ELEMENT_FIRE)  end

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

function Elements:PickElement(playerID, element)
	local player = PlayerResource:GetPlayer(playerID)

	local hero = player:GetAssignedHero()
	if hero == nil or not hero:IsAlive() or hero:IsFrozen() then
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
	local hero = player:GetAssignedHero()
	player.orbParticles[index] = ParticleManager:CreateParticle(ORB_PARTICLES[element], PATTACH_ABSORIGIN_FOLLOW, hero)
	ParticleManager:SetParticleControl(player.orbParticles[index], CONTROL_OFFSET, ORB_ORIGIN_OFFSETS[index])
	EmitSoundOnClient("PickElement", player)
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