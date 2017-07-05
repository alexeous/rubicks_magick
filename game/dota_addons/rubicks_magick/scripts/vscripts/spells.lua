
require("elements")
require("move_controller")

if Spells == nil then
	Spells = class({})
end

function Spells:Precache(context)

end

function Spells:Init()
	CustomGameEventManager:RegisterListener("me_ld", Dynamic_Wrap(Spells, "OnLeftDown"))
	CustomGameEventManager:RegisterListener("me_md", Dynamic_Wrap(Spells, "OnMiddleDown"))
end

function Spells:IndexOfPicked(pickedElements, element)
	for index, pickedElement in pairs(pickedElements) do
		if pickedElement == element then
			return index
		end
	end
	return nil
end


---------------------------------------------------------------------
---------------------------------------------------------------------
--------------------- LEFT MOUSE CLICK ------------------------------


function Spells:OnLeftDown(keys)
	local player = PlayerResource:GetPlayer(keys.playerID)
	local pickedElements = player.pickedElements

	if next(pickedElements) == nil then 	-- no picked elements
		Spells:MeleeAttack(player)
		return
	end

	Elements:RemoveAllElements(player)

	local shieldInd = Spells:IndexOfPicked(pickedElements, ELEMENT_SHIELD)
	if shieldInd ~= nil then
		table.remove(pickedElements, shieldInd)
		if next(pickedElements) == nil then 	-- if only shield orb is picked
			Spells:PlaceMagicShield(player, true) 	-- then place magic shield
		else
			Spells:DirectedDefensiveSpell(player, pickedElements) 	-- otherwise handle the other elements as a defensive combination
		end
		return
	end

	local earthInd = Spells:IndexOfPicked(pickedElements, ELEMENT_EARTH)
	if earthInd ~= nil then
		table.remove(pickedElements, earthInd)
		Spells:StartRockThrow(player, pickedElements) 	-- earth [+ <element>] [+ <element>] = throw rock
		return
	end

	local lightningInd = Spells:IndexOfPicked(pickedElements, ELEMENT_LIGHTNING)
	if lightningInd ~= nil then
		table.remove(pickedElements, lightningInd)
		Spells:DirectedLightning(player, pickedElements) 	-- lightning [+ <element>] [+ <element>] = lightning
		return
	end

	local lifeInd = Spells:IndexOfPicked(pickedElements, ELEMENT_LIFE)
	if lifeInd ~= nil then
		local waterInd = Spells:IndexOfPicked(pickedElements, ELEMENT_WATER)
		local coldInd = Spells:IndexOfPicked(pickedElements, ELEMENT_COLD)
		if not (waterInd and coldInd) then 		-- if not ice spikes
			table.remove(pickedElements, lifeInd)
			Spells:StartLifeBeam(player, pickedElements) 	-- otherwise life [+ <element>] [+ <element>] = life beam
		else
			Spells:StartIceSpikes(player, ELEMENT_LIFE)
		end
		return
	end

	local deathInd = Spells:IndexOfPicked(pickedElements, ELEMENT_DEATH)
	if deathInd ~= nil then
		local waterInd = Spells:IndexOfPicked(pickedElements, ELEMENT_WATER)
		local coldInd = Spells:IndexOfPicked(pickedElements, ELEMENT_COLD)
		if not (waterInd and coldInd) then 		-- if not ice spikes
			table.remove(pickedElements, deathInd)
			Spells:StartDeathBeam(player, pickedElements) 	-- otherwise death [+ <element>] [+ <element>] = death beam
		else
			Spells:StartIceSpikes(player, ELEMENT_DEATH)
		end
		return
	end

	local waterInd = Spells:IndexOfPicked(pickedElements, ELEMENT_WATER)
	if waterInd ~= nil then
		table.remove(pickedElements, waterInd)
		
		local fireInd = Spells:IndexOfPicked(pickedElements, ELEMENT_FIRE)
		if fireInd ~= nil then
			table.remove(pickedElements, fireInd)
			Spells:StartSteamSpray(player, pickedElements[1]) 	-- water + fire [+ water/fire] = steam spray
			return
		end

		local coldInd = Spells:IndexOfPicked(pickedElements, ELEMENT_COLD)
		if coldInd ~= nil then
			table.remove(pickedElements, coldInd)
			Spells:StartIceSpikes(player, pickedElements[1])	-- water + cold [+ cold/water] = ice spikes
			return
		end

		Spells:StartWaterSpray(player, #pickedElements + 1) 	-- otherwise it is water spray (second arg is power of spray)
	end

	local fireInd = Spells:IndexOfPicked(pickedElements, ELEMENT_FIRE)
	if fireInd ~= nil then
		Spells:StartFireSpray(player, #pickedElements)
		return
	end

	Spells:StartColdSpray(player, #pickedElements)
end

function Spells:DirectedDefensiveSpell(player, pickedElements)	-- picked shield and clicked left mouse
	local earthInd = Spells:IndexOfPicked(pickedElements, ELEMENT_EARTH)
	if earthInd ~= nil then 	-- shield + earth [+ <element>] = stone wall [perhaps modified by the last picked element]
		table.remove(pickedElements, earthInd)
		Spells:PlaceStoneWall(player, pickedElements[1])
		return
	end

	local lightningInd = Spells:IndexOfPicked(pickedElements, ELEMENT_LIGHTNING)
	if lightningInd ~= nil then 	-- shield + lightning = lightning wall
		table.remove(pickedElements, lightningInd)
		Spells:PlaceLightningWall(player, pickedElements[1])
		return
	end

	local lifeInd = Spells:IndexOfPicked(pickedElements, ELEMENT_LIFE)
	if lifeInd ~= nil then -- shield + life = life mines
		table.remove(pickedElements, lifeInd)
		Spells:PlaceLifeMines(player, pickedElements[1])
		return
	end

	local deathInd = Spells:IndexOfPicked(pickedElements, ELEMENT_DEATH)
	if deathInd ~= nil then -- shield + death = death mines
		table.remove(pickedElements, deathInd)
		Spells:PlaceDeathMines(player, pickedElements[1])
		return
	end

	local waterInd = Spells:IndexOfPicked(pickedElements, ELEMENT_WATER)
	if waterInd ~= nil then
		table.remove(pickedElements, waterInd)
		if pickedElements[1] == ELEMENT_COLD then 	-- shield + water + cold = ice wall
			Spells:PlaceIceWall(player)
		elseif pickedElements[1] == ELEMENT_FIRE then 	-- shield + water + fire = steam wall
			Spells:PlaceSteamWall(player)
		else
			Spells:PlaceWaterWall(player, pickedElements[1]) -- shield + water [+ water] = water wall
		end
		return
	end

	local fireInd = Spells:IndexOfPicked(pickedElements, ELEMENT_FIRE)
	if fireInd ~= nil then 		-- shield + fire = fire wall
		Spells:PlaceFireWall(player, pickedElements[2])
		return
	end

	Spells:PlaceColdWall(player, pickedElements[2]) 	-- otherwise it is shield + cold [+cold] = cold wall
end


--------------------- LEFT MOUSE CLICK ------------------------------
---------------------------------------------------------------------
---------------------------------------------------------------------

---------------------------------------------------------------------
---------------------------------------------------------------------
--------------------- MIDDLE MOUSE CLICK ----------------------------

function Spells:OnMiddleDown(keys)
	local player = PlayerResource:GetPlayer(keys.playerID)
	local pickedElements = player.pickedElements

	if next(pickedElements) == nil then 	-- no picked elements
		return
	end

	Elements:RemoveAllElements(player)

	local shieldInd = Spells:IndexOfPicked(pickedElements, ELEMENT_SHIELD)
	if shieldInd ~= nil then
		table.remove(pickedElements, shieldInd)
		if next(pickedElements) == nil then 	-- if only shield orb is picked
			Spells:PlaceMagicShield(player, false) 	-- then place magic shield
		else
			Spells:ApplyElementSelfShield(player, pickedElements) 	-- otherwise apply element shield on caster
		end
		return
	end

	local earthInd = Spells:IndexOfPicked(pickedElements, ELEMENT_EARTH)
	if earthInd ~= nil then
		table.remove(pickedElements, earthInd)
		Spells:EarthStomp(player, pickedElements) 	-- earth + elements = stomp
		return
	end

	local lightningInd = Spells:IndexOfPicked(pickedElements, ELEMENT_LIGHTNING)
	if lightningInd ~= nil then
		table.remove(pickedElements, lightningInd)
		Spells:OmniLightning(player, pickedElements)
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
				Spells:StartSelfHeal(player, #pickedElements + 1) 	-- if only life is picked then self-healing
			else
				Spells:LifeOmniPulse(player, pickedElements) 	-- otherwise pulse of life
			end
		else
			Spells:IceOmniSpikes(player, ELEMENT_LIFE)
		end
		return
	end

	local deathInd = Spells:IndexOfPicked(pickedElements, ELEMENT_DEATH)
	if deathInd ~= nil then
		table.remove(pickedElements, deathInd)
		local waterInd = Spells:IndexOfPicked(pickedElements, ELEMENT_WATER)
		local coldInd = Spells:IndexOfPicked(pickedElements, ELEMENT_COLD)
		if not (waterInd and coldInd) then 		-- if not ice spikes
			Spells:DeathOmniPulse(player, pickedElements)
		else
			Spells:IceOmniSpikes(player, ELEMENT_DEATH)
		end
		return
	end

	local waterInd = Spells:IndexOfPicked(pickedElements, ELEMENT_WATER)
	if waterInd ~= nil then
		table.remove(pickedElements, waterInd)

		local fireInd = Spells:IndexOfPicked(pickedElements, ELEMENT_FIRE)
		if fireInd ~= nil then
			table.remove(pickedElements, fireInd)
			Spells:SteamOmniSpray(player, pickedElements[1]) 	-- water + fire [+ water/fire] = steam omni spray
			return
		end

		local coldInd = Spells:IndexOfPicked(pickedElements, ELEMENT_COLD)
		if coldInd ~= nil then
			table.remove(pickedElements, coldInd)
			Spells:IceOmniSpikes(player, pickedElements[1])	-- water + cold [+ cold/water] = ice omni spikes
			return
		end

		Spells:WaterOmniSpray(player, #pickedElements + 1)
	end

	local fireInd = Spells:IndexOfPicked(pickedElements, ELEMENT_FIRE)
	if fireInd ~= nil then
		Spells:FireOmniSpray(player, #pickedElements)
		return
	end

	Spells:ColdOmniSpray(player, #pickedElements)
end

--------------------- MIDDLE MOUSE CLICK ----------------------------
---------------------------------------------------------------------
---------------------------------------------------------------------

----------     ----------     ----------     ----------     ----------     ----------     ----------     ----------     ----------     ----------

------------------------- MELEE ATTACK ------------------------------

function Spells:MeleeAttack(player)
	-------- TODO ---------
end

---------------------------------------------------------------------
------------------------- WALLS AND SHIELDS -------------------------


function Spells:PlaceMagicShield(player, isDirected)
	-------- TODO ---------
end

function Spells:PlaceStoneWall(player, modifierElement)
	-------- TODO ---------
end

function Spells:PlaceLightningWall(player, modifierElement)
	-------- TODO ---------
end

function Spells:PlaceLifeMines(player, modifierElement)
	-------- TODO ---------
end

function Spells:PlaceDeathMines(player, modifierElement)
	-------- TODO ---------
end

function Spells:PlaceIceWall(player)
	-------- TODO ---------
end

function Spells:PlaceSteamWall(player)
	-------- TODO ---------
end

function Spells:PlaceWaterWall(player, modifierElement)
	-------- TODO ---------
end

function Spells:PlaceFireWall(player, modifierElement)
	-------- TODO ---------
end

function Spells:PlaceColdWall(player, modifierElement)
	-------- TODO ---------
end


------------------------- WALLS AND SHIELDS -------------------------
---------------------------------------------------------------------

---------------------------------------------------------------------
------------------------- DIRECTED CASTING --------------------------


function Spells:StartRockThrow(player, modifierElements)
	-------- TODO ---------
end

function Spells:DirectedLightning(player, modifierElements)
	-------- TODO ---------
end

function Spells:StartLifeBeam(player, modifierElements)
	-------- TODO ---------
end

function Spells:StartDeathBeam(player, modifierElements)
	-------- TODO ---------
end

function Spells:StartSteamSpray(player, modifierElement)
	-------- TODO ---------
end

function Spells:StartIceSpikes(player, modifierElement)
	-------- TODO ---------
end

function Spells:StartWaterSpray(player, power)
	-------- TODO ---------
end

function Spells:StartFireSpray(player, power)
	-------- TODO ---------
end

function Spells:StartColdSpray(player, power)
	-------- TODO ---------
end


------------------------- DIRECTED CASTING --------------------------
---------------------------------------------------------------------

---------------------------------------------------------------------
------------------------- SELF CASTING ------------------------------


function Spells:ApplyElementSelfShield(player, shieldElements)
	-------- TODO ---------
end

function Spells:EarthStomp(player, modifierElements)
	-------- TODO ---------
end

function Spells:OmniLightning(player, modifierElements)
	-------- TODO ---------
end

function Spells:StartSelfHeal(player, power)
	-------- TODO ---------
end

function Spells:LifeOmniPulse(player, modifierElements)
	-------- TODO ---------
end

function Spells:DeathOmniPulse(player, modifierElements)
	-------- TODO ---------
end

function Spells:SteamOmniSpray(player, modifierElement)
	-------- TODO ---------
end

function Spells:IceOmniSpikes(player, modifierElement)
	-------- TODO ---------
end

function Spells:WaterOmniSpray(player, power)
	-------- TODO ---------
end

function Spells:FireOmniSpray(player, power)
	-------- TODO ---------
end

function Spells:ColdOmniSpray(player, power)
	-------- TODO ---------
end


------------------------- SELF CASTING ------------------------------
---------------------------------------------------------------------