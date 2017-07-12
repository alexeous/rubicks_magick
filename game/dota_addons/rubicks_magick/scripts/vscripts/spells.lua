
require("elements")
require("move_controller")

require("spells/self_shield")
require("spells/magic_shield")
require("spells/stone_wall")
require("spells/lightning_wall")
require("spells/mines")
require("spells/element_walls")
require("spells/rock_throw")
require("spells/lightning")
require("spells/beams")
require("spells/element_sprays")
require("spells/ice_spikes")
require("spells/earth_stomp")
require("spells/self_heal")
require("spells/omni_pulses")
require("spells/omni_element_sprays")
require("spells/omni_ice_spikes")

if Spells == nil then
	Spells = class({})
end


function Spells:Precache(context)
	SelfShield:Precache(context)
	MagicShield:Precache(context)
	StoneWall:Precache(context)
	LightningWall:Precache(context)
	Mines:Precache(context)
	ElementWalls:Precache(context)
	RockThrow:Precache(context)
	Lightning:Precache(context)
	Beams:Precache(context)
	ElementSprays:Precache(context)
	IceSpikes:Precache(context)
	EarthStomp:Precache(context)
	SelfHeal:Precache(context)
	OmniPulses:Precache(context)
	OmniElementSprays:Precache(context)
	OmniIceSpikes:Precache(context)
end

function Spells:Init()
	GameRules:GetGameModeEntity():SetThink(Dynamic_Wrap(Spells, "OnSpellsThink"), "OnSpellsThink", 2)

	CustomGameEventManager:RegisterListener("me_ld", Dynamic_Wrap(Spells, "OnLeftDown"))
	CustomGameEventManager:RegisterListener("me_md", Dynamic_Wrap(Spells, "OnMiddleDown"))
end

function Spells:PlayerConnected(player)
	SelfShield:PlayerConnected(player)
	MagicShield:PlayerConnected(player)
	StoneWall:PlayerConnected(player)
	LightningWall:PlayerConnected(player)
	Mines:PlayerConnected(player)
	ElementWalls:PlayerConnected(player)
	RockThrow:PlayerConnected(player)
	Lightning:PlayerConnected(player)
	Beams:PlayerConnected(player)
	ElementSprays:PlayerConnected(player)
	IceSpikes:PlayerConnected(player)
	EarthStomp:PlayerConnected(player)
	SelfHeal:PlayerConnected(player)
	OmniPulses:PlayerConnected(player)
	OmniElementSprays:PlayerConnected(player)
	OmniIceSpikes:PlayerConnected(player)
end



function Spells:IndexOfPicked(pickedElements, element)
	for index, pickedElement in pairs(pickedElements) do
		if pickedElement == element then
			return index
		end
	end
	return nil
end

function Spells:ClonePickedElements(player)
	local result = {}
	for index, element in pairs(player.pickedElements) do 
		result[index] = element
	end
	return result
end


---------------------------------------------------------------------
---------------------------------------------------------------------
--------------------- LEFT MOUSE CLICK ------------------------------


function Spells:OnLeftDown(keys)
	local player = PlayerResource:GetPlayer(keys.playerID)
	if player.thinksToCastingEnd ~= nil then return end

	local pickedElements = Spells:ClonePickedElements(player)

	if next(pickedElements) == nil then 	-- if player is casting a spell now or no picked elements
		Spells:MeleeAttack(player)
		return
	end

	Elements:RemoveAllElements(player)

	local shieldInd = Spells:IndexOfPicked(pickedElements, ELEMENT_SHIELD)
	if shieldInd ~= nil then
		table.remove(pickedElements, shieldInd)
		if next(pickedElements) == nil then 	-- if only shield orb is picked
			MagicShield:PlaceMagicShield(player, true) 	-- then place magic shield
		else
			Spells:DirectedDefensiveSpell(player, pickedElements) 	-- otherwise handle the other elements as a defensive combination
		end
		return
	end

	local earthInd = Spells:IndexOfPicked(pickedElements, ELEMENT_EARTH)
	if earthInd ~= nil then
		table.remove(pickedElements, earthInd)
		RockThrow:StartRockThrow(player, pickedElements) 	-- earth [+ <element>] [+ <element>] = throw rock
		return
	end

	local lightningInd = Spells:IndexOfPicked(pickedElements, ELEMENT_LIGHTNING)
	if lightningInd ~= nil then
		table.remove(pickedElements, lightningInd)
		Lightning:DirectedLightning(player, pickedElements) 	-- lightning [+ <element>] [+ <element>] = lightning
		return
	end

	local lifeInd = Spells:IndexOfPicked(pickedElements, ELEMENT_LIFE)
	if lifeInd ~= nil then
		local waterInd = Spells:IndexOfPicked(pickedElements, ELEMENT_WATER)
		local coldInd = Spells:IndexOfPicked(pickedElements, ELEMENT_COLD)
		if not (waterInd and coldInd) then 		-- if not ice spikes
			table.remove(pickedElements, lifeInd)
			Beams:StartLifeBeam(player, pickedElements) 	-- otherwise life [+ <element>] [+ <element>] = life beam
		else
			IceSpikes:StartIceSpikes(player, ELEMENT_LIFE)
		end
		return
	end

	local deathInd = Spells:IndexOfPicked(pickedElements, ELEMENT_DEATH)
	if deathInd ~= nil then
		local waterInd = Spells:IndexOfPicked(pickedElements, ELEMENT_WATER)
		local coldInd = Spells:IndexOfPicked(pickedElements, ELEMENT_COLD)
		if not (waterInd and coldInd) then 		-- if not ice spikes
			table.remove(pickedElements, deathInd)
			Beams:StartDeathBeam(player, pickedElements) 	-- otherwise death [+ <element>] [+ <element>] = death beam
		else
			IceSpikes:StartIceSpikes(player, ELEMENT_DEATH)
		end
		return
	end

	local waterInd = Spells:IndexOfPicked(pickedElements, ELEMENT_WATER)
	if waterInd ~= nil then
		table.remove(pickedElements, waterInd)
		
		local fireInd = Spells:IndexOfPicked(pickedElements, ELEMENT_FIRE)
		if fireInd ~= nil then
			table.remove(pickedElements, fireInd)
			ElementSprays:StartSteamSpray(player, pickedElements[1]) 	-- water + fire [+ water/fire] = steam spray
			return
		end

		local coldInd = Spells:IndexOfPicked(pickedElements, ELEMENT_COLD)
		if coldInd ~= nil then
			table.remove(pickedElements, coldInd)
			IceSpikes:StartIceSpikes(player, pickedElements[1])	-- water + cold [+ cold/water] = ice spikes
			return
		end

		ElementSprays:StartWaterSpray(player, #pickedElements + 1) 	-- otherwise it is water spray (second arg is power of spray)
	end

	local fireInd = Spells:IndexOfPicked(pickedElements, ELEMENT_FIRE)
	if fireInd ~= nil then
		ElementSprays:StartFireSpray(player, #pickedElements)
		return
	end

	ElementSprays:StartColdSpray(player, #pickedElements)
end

function Spells:DirectedDefensiveSpell(player, pickedElements)	-- picked shield and clicked left mouse
	local earthInd = Spells:IndexOfPicked(pickedElements, ELEMENT_EARTH)
	if earthInd ~= nil then 	-- shield + earth [+ <element>] = stone wall [perhaps modified by the last picked element]
		table.remove(pickedElements, earthInd)
		StoneWall:PlaceStoneWall(player, pickedElements[1])
		return
	end

	local lightningInd = Spells:IndexOfPicked(pickedElements, ELEMENT_LIGHTNING)
	if lightningInd ~= nil then 	-- shield + lightning = lightning wall
		table.remove(pickedElements, lightningInd)
		LightningWall:PlaceLightningWall(player, pickedElements[1])
		return
	end

	local lifeInd = Spells:IndexOfPicked(pickedElements, ELEMENT_LIFE)
	if lifeInd ~= nil then -- shield + life = life mines
		table.remove(pickedElements, lifeInd)
		Mines:PlaceLifeMines(player, pickedElements[1])
		return
	end

	local deathInd = Spells:IndexOfPicked(pickedElements, ELEMENT_DEATH)
	if deathInd ~= nil then -- shield + death = death mines
		table.remove(pickedElements, deathInd)
		Mines:PlaceDeathMines(player, pickedElements[1])
		return
	end

	local waterInd = Spells:IndexOfPicked(pickedElements, ELEMENT_WATER)
	if waterInd ~= nil then
		table.remove(pickedElements, waterInd)
		if pickedElements[1] == ELEMENT_COLD then 	-- shield + water + cold = ice wall
			ElementWalls:PlaceIceWall(player)
		elseif pickedElements[1] == ELEMENT_FIRE then 	-- shield + water + fire = steam wall
			ElementWalls:PlaceSteamWall(player)
		else
			ElementWalls:PlaceWaterWall(player, pickedElements[1]) -- shield + water [+ water] = water wall
		end
		return
	end

	local fireInd = Spells:IndexOfPicked(pickedElements, ELEMENT_FIRE)
	if fireInd ~= nil then 		-- shield + fire = fire wall
		ElementWalls:PlaceFireWall(player, pickedElements[2])
		return
	end

	ElementWalls:PlaceColdWall(player, pickedElements[2]) 	-- otherwise it is shield + cold [+cold] = cold wall
end


--------------------- LEFT MOUSE CLICK ------------------------------
---------------------------------------------------------------------
---------------------------------------------------------------------

---------------------------------------------------------------------
---------------------------------------------------------------------
--------------------- MIDDLE MOUSE CLICK ----------------------------

function Spells:OnMiddleDown(keys)
	local player = PlayerResource:GetPlayer(keys.playerID)
	local pickedElements = Spells:ClonePickedElements(player)

	if player.thinksToCastingEnd or next(pickedElements) == nil then 	-- if player is casting a spell now or no picked elements
		return
	end

	Elements:RemoveAllElements(player)

	local shieldInd = Spells:IndexOfPicked(pickedElements, ELEMENT_SHIELD)
	if shieldInd ~= nil then
		table.remove(pickedElements, shieldInd)
		if next(pickedElements) == nil then 	-- if only shield orb is picked
			MagicShield:PlaceMagicShield(player, false) 	-- then place magic shield
		else
			SelfShield:ApplyElementSelfShield(player, pickedElements) 	-- otherwise apply element shield on caster
		end
		return
	end

	local earthInd = Spells:IndexOfPicked(pickedElements, ELEMENT_EARTH)
	if earthInd ~= nil then
		table.remove(pickedElements, earthInd)
		EarthStomp:EarthStomp(player, pickedElements) 	-- earth + elements = stomp
		return
	end

	local lightningInd = Spells:IndexOfPicked(pickedElements, ELEMENT_LIGHTNING)
	if lightningInd ~= nil then
		table.remove(pickedElements, lightningInd)
		Lightning:OmniLightning(player, pickedElements)
		return
	end

	local lifeInd = Spells:IndexOfPicked(pickedElements, ELEMENT_LIFE)
	if lifeInd ~= nil then
		table.remove(pickedElements, lifeInd)
		local waterInd = Spells:IndexOfPicked(pickedElements, ELEMENT_WATER)
		local coldInd = Spells:IndexOfPicked(pickedElements, ELEMENT_COLD)
		if not (waterInd and coldInd) then 		-- if not ice spikes
			local isLife1 = (pickedElements[1] == ELEMENT_LIFE) or (pickedElements[1] == nil)
			local isLife2 = (pickedElements[2] == ELEMENT_LIFE) or (pickedElements[2] == nil)
			if isLife1 and isLife2 then
				SelfHeal:StartSelfHeal(player, #pickedElements + 1) 	-- if only life is picked then self-healing
			else
				OmniPulses:OmniLifePulse(player, pickedElements) 	-- otherwise pulse of life
			end
		else
			OmniIceSpikes:OmniIceSpikes(player, ELEMENT_LIFE)
		end
		return
	end

	local deathInd = Spells:IndexOfPicked(pickedElements, ELEMENT_DEATH)
	if deathInd ~= nil then
		table.remove(pickedElements, deathInd)
		local waterInd = Spells:IndexOfPicked(pickedElements, ELEMENT_WATER)
		local coldInd = Spells:IndexOfPicked(pickedElements, ELEMENT_COLD)
		if not (waterInd and coldInd) then 		-- if not ice spikes
			OmniPulses:OmniDeathPulse(player, pickedElements)
		else
			OmniIceSpikes:OmniIceSpikes(player, ELEMENT_DEATH)
		end
		return
	end

	local waterInd = Spells:IndexOfPicked(pickedElements, ELEMENT_WATER)
	if waterInd ~= nil then
		table.remove(pickedElements, waterInd)

		local fireInd = Spells:IndexOfPicked(pickedElements, ELEMENT_FIRE)
		if fireInd ~= nil then
			table.remove(pickedElements, fireInd)
			OmniElementSprays:OmniSteamSpray(player, pickedElements[1]) 	-- water + fire [+ water/fire] = steam omni spray
			return
		end

		local coldInd = Spells:IndexOfPicked(pickedElements, ELEMENT_COLD)
		if coldInd ~= nil then
			table.remove(pickedElements, coldInd)
			OmniIceSpikes:OmniIceSpikes(player, pickedElements[1])	-- water + cold [+ cold/water] = ice omni spikes
			return
		end

		OmniElementSprays:OmniWaterpray(player, #pickedElements + 1)
	end

	local fireInd = Spells:IndexOfPicked(pickedElements, ELEMENT_FIRE)
	if fireInd ~= nil then
		OmniElementSprays:OmniFireSpray(player, #pickedElements)
		return
	end

	OmniElementSprays:OmniColdSpray(player, #pickedElements)
end

--------------------- MIDDLE MOUSE CLICK ----------------------------
---------------------------------------------------------------------
---------------------------------------------------------------------

SPELLS_THINK_PERIOD = 0.03
function Spells:OnSpellsThink()
	for playerID = 0, DOTA_MAX_PLAYERS - 1 do
		local player = PlayerResource:GetPlayer(playerID)
		if player ~= nil and player.thinksToCastingEnd ~= nil then
			if player.thinksToCastingEnd <= 0 then
				Spells:StopCasting(player)
			else

				if player.spellThinkFunction ~= nil then
					pcall(player.spellThinkFunction, player)
				end
				player.thinksToCastingEnd = player.thinksToCastingEnd - 1

			end
		end		
	end
	return SPELLS_THINK_PERIOD
end

----------     ----------     ----------     ----------     ----------     ----------     ----------     ----------     ----------     ----------

CAST_TYPE_INSTANT = 1
CAST_TYPE_CONTINUOUS = 2
CAST_TYPE_CHARGING = 3

function Spells:TimeToThinks(time)
	return time / SPELLS_THINK_PERIOD
end

function Spells:StartCasting(player, infoTable)
	player.dontMoveWhileCasting = infoTable.dontMoveWhileCasting
	player.thinksToCastingEnd = Spells:TimeToThinks(infoTable.duration)
	if infoTable.thinkFunction ~= nil then
		player.spellThinkFunction = infoTable.thinkFunction
	end
	if infoTable.castingGesture ~= nil then
		Spells:StartCastingGesture(player, infoTable.castingGesture, infoTable.castingGestureRate)
	end
end

function Spells:StopCasting(player)
	player.dontMoveWhileCasting = nil
	player.thinksToCastingEnd = nil
	player.spellThinkFunction = nil
	local heroEntity = player:GetAssignedHero()
	if heroEntity ~= nil and player.castingGesture ~= nil then
		heroEntity:FadeGesture(player.castingGesture)
		if player.moveToPos ~= nil then
			heroEntity:StartGesture(ACT_DOTA_RUN)
		end
		player.castingGesture = nil
	end
end

function Spells:StartCastingGesture(player, gesture, castingGestureRate)
	player.castingGesture = gesture
	local heroEntity = player:GetAssignedHero()
	if heroEntity == nil then return end

	if player.moveToPos ~= nil then
		heroEntity:FadeGesture(ACT_DOTA_RUN)
	end
	if castingGestureRate ~= nil then
		heroEntity:StartGestureWithPlaybackRate(player.castingGesture, castingGestureRate)
	else
		heroEntity:StartGesture(player.castingGesture)
	end
end

------------------------- MELEE ATTACK ------------------------------

function Spells:MeleeAttack(player)
	local spellCastTable = {
		castType = CAST_TYPE_INSTANT,
		duration = 0.6,
		dontMoveWhileCasting = true,
		castingGesture = ACT_DOTA_ATTACK,
		castingGestureRate = 1.4
	}
	spellCastTable.thinkFunction = function(player)
		if player.thinksToCastingEnd == Spells:TimeToThinks(0.3) then 	-- do damage only after a small delay
			local heroEntity = player:GetAssignedHero()
			local center = heroEntity:GetAbsOrigin() + heroEntity:GetForwardVector() * 110
			Spells:ApplyElementDamageAoE(center, 110, heroEntity, ELEMENT_EARTH, 150, true)
		end
	end
	Spells:StartCasting(player, spellCastTable)
end


------------------------- DAMAGE APPLYING  --------------------------

function Spells:ApplyElementDamageAoE(center, radius, attacker, element, damage, dontDamageAttacker)
	local unitsToHurt = FindUnitsInRadius(attacker:GetTeamNumber(), center, nil, radius, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL,
	    DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, true)
	for _, unit in pairs(unitsToHurt) do
		if not (unit == attacker and dontDamageAttacker) then
			Spells:ApplyElementDamage(unit, attacker, element, damage)
		end
	end
end

function Spells:ApplyElementDamage(victim, attacker, element, damage)
	local player = attacker:GetPlayerOwner()
	if (element ~= nil) and (player ~= nil) and (player.shieldElements ~= nil) then
		local halfDamage = damage / 2
		if player.shieldElements[1] == element then  damage = damage - halfDamage  end
		if player.shieldElements[2] == element then	 damage = damage - halfDamage  end
	end
	if damage > 0.5 then
		ApplyDamage({ victim = victim, attacker = attacker, damage = damage, damage_type = DAMAGE_TYPE_PURE })
	end
end