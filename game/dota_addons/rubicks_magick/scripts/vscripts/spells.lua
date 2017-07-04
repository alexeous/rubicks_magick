
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
	if shieldInd ~= nil then 		-- if shield orb is picked
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
		Spells:StartDirectedLightning(player, pickedElements) 	-- lightning [+ <element>] [+ <element>] = lightning
		return
	end

	local lifeInd = Spells:IndexOfPicked(pickedElements, ELEMENT_LIFE)
	if lifeInd ~= nil then
		table.remove(pickedElements, lifeInd)
		local ice1 = (pickedElements[1] == ELEMENT_WATER and pickedElements[2] == ELEMENT_COLD)
		local ice2 = (pickedElements[2] == ELEMENT_WATER and pickedElements[1] == ELEMENT_COLD)
		if not ice1 and not ic2 then 		-- if not ice spikes
			Spells:StartLifeBeam(player, pickedElements) 	-- otherwise life [+ <element>] [+ <element>] = life beam
		end
	end

	local deathInd = Spells:IndexOfPicked(pickedElements, ELEMENT_DEATH)
	if deathInd ~= nil then
		table.remove(pickedElements, deathInd)
		local ice1 = (pickedElements[1] == ELEMENT_WATER and pickedElements[2] == ELEMENT_COLD)
		local ice2 = (pickedElements[2] == ELEMENT_WATER and pickedElements[1] == ELEMENT_COLD)
		if not ice1 and not ic2 then 		-- if not ice spikes
			Spells:StartDeathBeam(player, pickedElements) 	-- otherwise death [+ <element>] [+ <element>] = death beam
		end
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
			Spells:StartIceSpikes(player, pickedElements[1])	-- water + cold [+ cold/life/death] = ice spikes
			return
		end

		Spells:StartWaterSpray(player, #pickedElements + 1) 	-- otherwise it is water spray (second arg is power of spray)
	end
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
	end

	local lifeInd = Spells:IndexOfPicked(pickedElements, ELEMENT_LIFE)
	if lifeInd ~= nil then -- shield + life = life mines
		table.remove(pickedElements, lifeInd)
		Spells:PlaceLifeMines(player, pickedElements[1])
	end

	local deathInd = Spells:IndexOfPicked(pickedElements, ELEMENT_DEATH)
	if deathInd ~= nil then -- shield + death = death mines
		table.remove(pickedElements, deathInd)
		Spells:PlaceDeathMines(player, pickedElements[1])
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
	end

	local fireInd = Spells:IndexOfPicked(pickedElements, ELEMENT_FIRE)
	if fireInd ~= nil then 		-- shield + fire = fire wall
		Spells:PlaceFireWall(player, pickedElements[2])
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

end

--------------------- MIDDLE MOUSE CLICK ----------------------------
---------------------------------------------------------------------
---------------------------------------------------------------------



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

function Spells:StartDirectedLightning(player, modifierElements)
	-------- TODO ---------
end

function Spells:StartLifeBeam(player, modifierElements)
	-------- TODO ---------
end

function Spells:StartDeathBeam(player, modifierElements)
	-------- TODO ---------
end

function Spells:StartSteamSpray(player, modifierElement)

end

function Spells:StartIceSpikes(player, modifierElement)

end

function Spells:StartWaterSpray(player, power)

end


------------------------- DIRECTED CASTING --------------------------
---------------------------------------------------------------------