
require("table_extension")

require("libraries/animations")

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


OMNI_SPELLS_RADIUSES = { 200, 300, 400 }


if Spells == nil then
	Spells = class({})
end


function Spells:Precache(context)
	LinkLuaModifier("modifier_slow_move", "modifiers/modifier_slow_move.lua", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_wet", "modifiers/modifier_wet.lua", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_chill", "modifiers/modifier_chill.lua", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_burn", "modifiers/modifier_burn.lua", LUA_MODIFIER_MOTION_NONE)

	PrecacheResource("particle", "particles/status_fx/status_effect_snow_heavy.vpcf", context)
	PrecacheResource("particle", "particles/status_fx/status_effect_slardar_amp_damage.vpcf", context)
	PrecacheResource("particle", "particles/wet_drips.vpcf", context)
	PrecacheResource("particle", "particles/status_fx/status_effect_burn.vpcf.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_huskar/huskar_burning_spear_debuff.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_tusk/tusk_frozen_sigil_death.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_ancient_apparition/ancient_apparition_cold_feet_frozen.vpcf", context)

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
	Spells.damagePool = {}
	Spells.healPool = {}

	GameRules:GetGameModeEntity():SetThink(Dynamic_Wrap(Spells, "OnSpellsThink"), "OnSpellsThink", 2)

	CustomGameEventManager:RegisterListener("me_ld", Dynamic_Wrap(Spells, "OnLeftDown"))
	CustomGameEventManager:RegisterListener("me_md", Dynamic_Wrap(Spells, "OnMiddleDown"))
	CustomGameEventManager:RegisterListener("me_lu", Dynamic_Wrap(Spells, "OnLeftUp"))
	CustomGameEventManager:RegisterListener("me_mu", Dynamic_Wrap(Spells, "OnMiddleUp"))
	CustomGameEventManager:RegisterListener("me_rd", Dynamic_Wrap(Spells, "OnRightDown"))

	RockThrow:Init()
	ElementSprays:Init()
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


---------------------- RIGHT MOUSE DOWN ------------------------------

function Spells:OnRightDown(keys)
	local heroEntity = PlayerResource:GetPlayer(keys.playerID):GetAssignedHero()

	if heroEntity ~= nil and heroEntity:IsAlive() and heroEntity:IsFrozen() then 
		heroEntity:FindModifierByName("modifier_frozen"):ReleaseProgress()
	end
end

---------------------------------------------------------------------
---------------------------------------------------------------------
--------------------- LEFT MOUSE CLICK ------------------------------


function Spells:OnLeftDown(keys)
	local player = PlayerResource:GetPlayer(keys.playerID)
	local heroEntity = player:GetAssignedHero()

	if heroEntity ~= nil then
		if heroEntity:IsFrozen() then
			heroEntity:FindModifierByName("modifier_frozen"):ReleaseProgress()
			return
		elseif heroEntity:IsStunned() or not heroEntity:IsAlive() then
			return
		end
	end

	if player.spellCast ~= nil then 
		player.wantsToStartNewSpell_left = true
		return
	end

	local pickedElements = table.clone(player.pickedElements)

	if next(pickedElements) == nil then 	-- if player is casting a spell now or no picked elements
		Spells:MeleeAttack(player)
		return
	end

	Elements:RemoveAllElements(player)

	local shieldInd = table.indexOf(pickedElements, ELEMENT_SHIELD)
	if shieldInd ~= nil then
		table.remove(pickedElements, shieldInd)
		if next(pickedElements) == nil then 	-- if only shield orb is picked
			MagicShield:PlaceMagicShield(player, true) 	-- then place magic shield
		else
			Spells:DirectedDefensiveSpell(player, pickedElements) 	-- otherwise handle the other elements as a defensive combination
		end
		return
	end

	local earthInd = table.indexOf(pickedElements, ELEMENT_EARTH)
	if earthInd ~= nil then
		table.remove(pickedElements, earthInd)
		RockThrow:StartRockThrow(player, pickedElements) 	-- earth [+ <element>] [+ <element>] = throw rock
		return
	end

	local lightningInd = table.indexOf(pickedElements, ELEMENT_LIGHTNING)
	if lightningInd ~= nil then
		table.remove(pickedElements, lightningInd)
		Lightning:DirectedLightning(player, pickedElements) 	-- lightning [+ <element>] [+ <element>] = lightning
		return
	end

	local lifeInd = table.indexOf(pickedElements, ELEMENT_LIFE)
	if lifeInd ~= nil then
		local waterInd = table.indexOf(pickedElements, ELEMENT_WATER)
		local coldInd = table.indexOf(pickedElements, ELEMENT_COLD)
		if not (waterInd and coldInd) then 		-- if not ice spikes
			table.remove(pickedElements, lifeInd)
			Beams:StartLifeBeam(player, pickedElements) 	-- otherwise life [+ <element>] [+ <element>] = life beam
		else
			IceSpikes:StartIceSpikes(player, ELEMENT_LIFE)
		end
		return
	end

	local deathInd = table.indexOf(pickedElements, ELEMENT_DEATH)
	if deathInd ~= nil then
		local waterInd = table.indexOf(pickedElements, ELEMENT_WATER)
		local coldInd = table.indexOf(pickedElements, ELEMENT_COLD)
		if not (waterInd and coldInd) then 		-- if not ice spikes
			table.remove(pickedElements, deathInd)
			Beams:StartDeathBeam(player, pickedElements) 	-- otherwise death [+ <element>] [+ <element>] = death beam
		else
			IceSpikes:StartIceSpikes(player, ELEMENT_DEATH)
		end
		return
	end

	local waterInd = table.indexOf(pickedElements, ELEMENT_WATER)
	if waterInd ~= nil then
		table.remove(pickedElements, waterInd)
		
		local fireInd = table.indexOf(pickedElements, ELEMENT_FIRE)
		if fireInd ~= nil then
			table.remove(pickedElements, fireInd)
			ElementSprays:StartSteamSpray(player, pickedElements[1]) 	-- water + fire [+ water/fire] = steam spray
			return
		end

		local coldInd = table.indexOf(pickedElements, ELEMENT_COLD)
		if coldInd ~= nil then
			table.remove(pickedElements, coldInd)
			IceSpikes:StartIceSpikes(player, pickedElements[1])	-- water + cold [+ cold/water] = ice spikes
			return
		end

		ElementSprays:StartWaterSpray(player, #pickedElements + 1) 	-- otherwise it is water spray (second arg is power of spray)
	end

	local fireInd = table.indexOf(pickedElements, ELEMENT_FIRE)
	if fireInd ~= nil then
		ElementSprays:StartFireSpray(player, #pickedElements)
		return
	end

	ElementSprays:StartColdSpray(player, #pickedElements)
end

function Spells:DirectedDefensiveSpell(player, pickedElements)	-- picked shield and clicked left mouse
	local earthInd = table.indexOf(pickedElements, ELEMENT_EARTH)
	if earthInd ~= nil then 	-- shield + earth [+ <element>] = stone wall [perhaps modified by the last picked element]
		table.remove(pickedElements, earthInd)
		StoneWall:PlaceStoneWall(player, pickedElements[1])
		return
	end

	local lightningInd = table.indexOf(pickedElements, ELEMENT_LIGHTNING)
	if lightningInd ~= nil then 	-- shield + lightning = lightning wall
		table.remove(pickedElements, lightningInd)
		LightningWall:PlaceLightningWall(player, pickedElements[1])
		return
	end

	local lifeInd = table.indexOf(pickedElements, ELEMENT_LIFE)
	if lifeInd ~= nil then -- shield + life = life mines
		table.remove(pickedElements, lifeInd)
		Mines:PlaceLifeMines(player, pickedElements[1])
		return
	end

	local deathInd = table.indexOf(pickedElements, ELEMENT_DEATH)
	if deathInd ~= nil then -- shield + death = death mines
		table.remove(pickedElements, deathInd)
		Mines:PlaceDeathMines(player, pickedElements[1])
		return
	end

	local waterInd = table.indexOf(pickedElements, ELEMENT_WATER)
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

	local fireInd = table.indexOf(pickedElements, ELEMENT_FIRE)
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
	local heroEntity = player:GetAssignedHero()

	if heroEntity ~= nil then
		if heroEntity:IsStunned() or not heroEntity:IsAlive() then
			return
		elseif heroEntity:IsFrozen() then 
			heroEntity:FindModifierByName("modifier_frozen"):ReleaseProgress()
			return
		end
	end

	if player.spellCast ~= nil then 	-- if player is casting a spell now
		player.wantsToStartNewSpell_middle = true
		return
	end

	local pickedElements = table.clone(player.pickedElements)

	if next(pickedElements) == nil then
		return
	end

	Elements:RemoveAllElements(player)

	local shieldInd = table.indexOf(pickedElements, ELEMENT_SHIELD)
	if shieldInd ~= nil then
		table.remove(pickedElements, shieldInd)
		if next(pickedElements) == nil then 	-- if only shield orb is picked
			MagicShield:PlaceMagicShield(player, false) 	-- then place magic shield
		else
			SelfShield:ApplyElementSelfShield(heroEntity, pickedElements) 	-- otherwise apply element shield on caster
		end
		return
	end

	local earthInd = table.indexOf(pickedElements, ELEMENT_EARTH)
	if earthInd ~= nil then
		table.remove(pickedElements, earthInd)
		EarthStomp:EarthStomp(player, pickedElements) 	-- earth + elements = stomp
		return
	end

	local lightningInd = table.indexOf(pickedElements, ELEMENT_LIGHTNING)
	if lightningInd ~= nil then
		table.remove(pickedElements, lightningInd)
		Lightning:OmniLightning(player, pickedElements)
		return
	end

	local lifeInd = table.indexOf(pickedElements, ELEMENT_LIFE)
	if lifeInd ~= nil then
		table.remove(pickedElements, lifeInd)
		local waterInd = table.indexOf(pickedElements, ELEMENT_WATER)
		local coldInd = table.indexOf(pickedElements, ELEMENT_COLD)
		if not (waterInd and coldInd) then 		-- if not ice spikes
			local isLife1 = (pickedElements[1] == ELEMENT_LIFE) or (pickedElements[1] == nil)
			local isLife2 = (pickedElements[2] == ELEMENT_LIFE) or (pickedElements[2] == nil)
			if isLife1 and isLife2 then
				SelfHeal:StartSelfHeal(player, #pickedElements + 1) 	-- if only life is picked then self-healing
			else
				OmniPulses:OmniLifePulseSpell(player, pickedElements) 	-- otherwise pulse of life
			end
		else
			OmniIceSpikes:OmniIceSpikes(player, ELEMENT_LIFE)
		end
		return
	end

	local deathInd = table.indexOf(pickedElements, ELEMENT_DEATH)
	if deathInd ~= nil then
		table.remove(pickedElements, deathInd)
		local waterInd = table.indexOf(pickedElements, ELEMENT_WATER)
		local coldInd = table.indexOf(pickedElements, ELEMENT_COLD)
		if not (waterInd and coldInd) then 		-- if not ice spikes
			OmniPulses:OmniDeathPulseSpell(player, pickedElements)
		else
			OmniIceSpikes:OmniIceSpikes(player, ELEMENT_DEATH)
		end
		return
	end

	local waterInd = table.indexOf(pickedElements, ELEMENT_WATER)
	if waterInd ~= nil then
		table.remove(pickedElements, waterInd)

		local fireInd = table.indexOf(pickedElements, ELEMENT_FIRE)
		if fireInd ~= nil then
			table.remove(pickedElements, fireInd)
			OmniElementSprays:OmniSteamSpraySpell(player, pickedElements[1]) 	-- water + fire [+ water/fire] = steam omni spray
			return
		end

		local coldInd = table.indexOf(pickedElements, ELEMENT_COLD)
		if coldInd ~= nil then
			table.remove(pickedElements, coldInd)
			OmniIceSpikes:OmniIceSpikes(player, pickedElements[1])	-- water + cold [+ cold/water] = ice omni spikes
			return
		end

		OmniElementSprays:OmniWaterSpraySpell(player, #pickedElements + 1)
		return
	end

	local fireInd = table.indexOf(pickedElements, ELEMENT_FIRE)
	if fireInd ~= nil then
		OmniElementSprays:OmniFireSpraySpell(player, #pickedElements)
		return
	end

	OmniElementSprays:OmniColdSpraySpell(player, #pickedElements)
end

--------------------- MIDDLE MOUSE CLICK ----------------------------
---------------------------------------------------------------------
---------------------------------------------------------------------

---------------------------------------------------------------------
--------------------- LEFT MOUSE UP ---------------------------------

function Spells:OnLeftUp(keys)
	local player = PlayerResource:GetPlayer(keys.playerID)
	if player ~= nil then
		player.wantsToStartNewSpell_left = false
		if player.spellCast ~= nil and player.spellCast.castType ~= CAST_TYPE_INSTANT and not player.spellCast.isSelfCast then
			Spells:StopCasting(player)
		end
	end
end

--------------------- LEFT MOUSE UP ---------------------------------
---------------------------------------------------------------------

---------------------------------------------------------------------
--------------------- MIDDLE MOUSE UP -------------------------------

function Spells:OnMiddleUp(keys)
	local player = PlayerResource:GetPlayer(keys.playerID)
	if player ~= nil then
		player.wantsToStartNewSpell_middle = false
		if player.spellCast ~= nil and player.spellCast.castType ~= CAST_TYPE_INSTANT and player.spellCast.isSelfCast then
			Spells:StopCasting(player)
		end
	end
end

--------------------- MIDDLE MOUSE UP -------------------------------
---------------------------------------------------------------------

----------     ----------     ----------     ----------     ----------     ----------     ----------     ----------     ----------     ----------


SPELLS_THINK_PERIOD = 0.03
function Spells:OnSpellsThink()
	local time = GameRules:GetGameTime()
	for playerID = 0, DOTA_MAX_PLAYERS - 1 do
		local player = PlayerResource:GetPlayer(playerID)
		if player ~= nil and player.spellCast ~= nil then
			if time > player.spellCast.endTime then
				Spells:StopCasting(player)
			elseif player.spellCast.thinkFunction ~= nil then
				local time = GameRules:GetGameTime()
				if player.spellCast.thinkPeriod == nil or time - player.spellCast.lastThinkTime >= player.spellCast.thinkPeriod then
					player.spellCast.thinkFunction(player)
					player.spellCast.lastThinkTime = time
				end
			end
		end		
	end

	for target, healInfos in pairs(Spells.healPool) do
		for source, heal in pairs(healInfos) do
			local healthShortage = target:GetMaxHealth() - target:GetHealth()
			heal = math.min(heal, healthShortage)
			if heal > 0 then
				target:Heal(heal, source)
				SendOverheadEventMessage(target, OVERHEAD_ALERT_HEAL, target, heal, target)
			end
		end
	end
	Spells.healPool = {}
	for victim, damageSources in pairs(Spells.damagePool) do
		for attacker, damageRecords in pairs(damageSources) do
			local sum = 0
			for _, damageRecord in pairs(damageRecords) do
				sum = sum + damageRecord.damage
			end
			ApplyDamage({ victim = victim, attacker = attacker, damage = sum, damage_type = DAMAGE_TYPE_PURE })

			if victim:IsAlive() then
				for _, damageRecord in pairs(damageRecords) do
					local damage = damageRecord.damage
					local element = damageRecord.element
					local applyModifiers = damageRecord.applyModifiers

					if applyModifiers then
						if element == ELEMENT_WATER then
							Spells:ApplyWet(victim, attacker)
						elseif element == ELEMENT_COLD then
							local value = math.ceil(damage / 20)
							Spells:ApplyChill(victim, attacker, value)
						elseif element == ELEMENT_FIRE then
							Spells:ApplyBurn(victim, attacker, damage)
						end
					end
				end
			end
		end
	end
	Spells.damagePool = {}

	return SPELLS_THINK_PERIOD
end

CAST_TYPE_INSTANT = 1
CAST_TYPE_CONTINUOUS = 2
CAST_TYPE_CHARGING = 3

function Spells:TimeElapsedSinceCast(player)
	return GameRules:GetGameTime() - player.spellCast.startTime
end

function Spells:StartCasting(player, infoTable)
	infoTable.startTime = GameRules:GetGameTime()
	infoTable.endTime = infoTable.startTime + infoTable.duration
	infoTable.lastThinkTime = GameRules:GetGameTime()
	player.spellCast = infoTable

	local heroEntity = player:GetAssignedHero()
	if heroEntity ~= nil then
		if player.spellCast.castingGesture ~= nil then
			if player.moveToPos ~= nil then
				heroEntity:FadeGesture(ACT_DOTA_RUN)
			end
			local animationParams = {
				duration = player.spellCast.duration,
				activity = player.spellCast.castingGesture,
				rate = player.spellCast.castingGestureRate,
				translate = player.spellCast.castingGestureTranslate
			}
			StartAnimation(heroEntity, animationParams)
		end

		if player.spellCast.slowMovePercentage ~= nil then
			local kv = { duration = player.spellCast.duration, slowMovePercentage = player.spellCast.slowMovePercentage }
			heroEntity:AddNewModifier(heroEntity, nil, "modifier_slow_move", kv)
		end

		if player.spellCast.castType == CAST_TYPE_CHARGING then
			CustomGameEventManager:Send_ServerToPlayer(player, "rm_cb_e", {})
			if player.spellCast.chargingParticle ~= nil then
				player.spellCast.chargingParticleID = ParticleManager:CreateParticle(player.spellCast.chargingParticle, PATTACH_ABSORIGIN_FOLLOW, heroEntity)
			end
		end
	end
end

function Spells:StopCasting(player)
	if player.spellCast == nil then
		return
	end

	local heroEntity = player:GetAssignedHero()
	if heroEntity ~= nil then
		if player.spellCast.castingGesture ~= nil then
			EndAnimation(heroEntity)
			if player.moveToPos ~= nil then
				heroEntity:StartGesture(ACT_DOTA_RUN)
			end
			MoveController:HeroLookAt(heroEntity, player.cursorPos)
		end

		if heroEntity:HasModifier("modifier_slow_move") then
			heroEntity:RemoveModifierByName("modifier_slow_move")
		end
	end

	if player.spellCast.castType == CAST_TYPE_CHARGING then
		CustomGameEventManager:Send_ServerToPlayer(player, "rm_cb_d", {})
		if player.spellCast.chargingParticleID ~= nil then
			ParticleManager:DestroyParticle(player.spellCast.chargingParticleID, false)
		end
	end

	if player.spellCast.endFunction ~= nil then
		player.spellCast.endFunction(player)
	end

	player.spellCast = nil

	if player.wantsToStartNewSpell_middle then
		Spells:OnMiddleDown({ playerID = player:GetPlayerID() })
		player.wantsToStartNewSpell_middle = false
	end
	if player.wantsToStartNewSpell_left then
		Spells:OnLeftDown({ playerID = player:GetPlayerID() })
		player.wantsToStartNewSpell_left = false
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
		local timeHasCome = Spells:TimeElapsedSinceCast(player) > 0.3 
		if timeHasCome and not player.spellCast.hasAttacked then 		-- do damage only after a small delay
			player.spellCast.hasAttacked = true
			local heroEntity = player:GetAssignedHero()
			local center = heroEntity:GetAbsOrigin() + heroEntity:GetForwardVector() * 110
			Spells:ApplyElementDamageAoE(center, 110, heroEntity, ELEMENT_EARTH, 150, true, true)
		end
	end

	spellCastTable.hasAttacked = false

	Spells:StartCasting(player, spellCastTable)
end


------------------------- DAMAGE APPLYING  --------------------------

function Spells:ApplyElementDamageAoE(center, radius, attacker, element, damage, dontDamageAttacker, applyModifiers, blockPerShield)
	local unitsToHurt = FindUnitsInRadius(attacker:GetTeamNumber(), center, nil, radius, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL,
	    DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, true)
	for _, unit in pairs(unitsToHurt) do
		if not (unit == attacker and dontDamageAttacker) then
			Spells:ApplyElementDamage(unit, attacker, element, damage, applyModifiers, blockPerShield)
		end
	end
end

function Spells:ApplyElementDamage(victim, attacker, element, damage, applyModifiers, blockPerShield)
	if victim:IsInvulnerable() then
		return
	end

	damage = Spells:GetDamageAfterShields(victim, damage, element, blockPerShield)

	if (element == ELEMENT_LIGHTNING) and victim:HasModifier("modifier_wet") and (not Spells:IsResistantTo(victim, ELEMENT_LIGHTNING)) then
		damage = damage * 2
		victim:RemoveModifierByName("modifier_wet")
	end
	if damage > 0.5 then
		local info = { damage = damage, element = element, applyModifiers = applyModifiers }
		if Spells.damagePool[victim] == nil then
			Spells.damagePool[victim] = {}
		end
		if Spells.damagePool[victim][attacker] == nil then
			Spells.damagePool[victim][attacker] = {}
		end
		table.insert(Spells.damagePool[victim][attacker], info)
	end
end

function Spells:GetDamageAfterShields(victim, damage, element, blockPerShield)
	if victim.shieldElements ~= nil then
		local blockFactor = blockPerShield or 0.5
		local portion = damage * blockFactor
		damage = damage - portion * Spells:ResistanceLevelTo(victim, element)
	end
	return damage
end


------------------------- MODIFIERS APPLYING --------------------------

function Spells:ResistanceLevelTo(target, element)
	if target == nil or target.shieldElements == nil then
		return 0
	end
	local result = 0
	if target.shieldElements[1] == element then  result = result + 1  end
	if target.shieldElements[2] == element then  result = result + 1  end
	return result
end

function Spells:IsResistantTo(target, element)
	return Spells:ResistanceLevelTo(target, element) > 0
end

function Spells:ApplyWet(target, caster)
	if Spells:IsResistantTo(target, ELEMENT_WATER) or target:IsInvulnerable() then
		return
	end

	local wasBurning = Spells:ExtinguishWithWater(target)
	if not wasBurning and not target:HasModifier("modifier_chill") then
		target:AddNewModifier(caster, nil, "modifier_wet", {})
	end
end

function Spells:ApplyChill(target, caster, power)
	if Spells:IsResistantTo(target, ELEMENT_COLD) or target:IsInvulnerable() then
		return
	end

	local wasBurning = Spells:ExtinguishWithCold(target)
	if not wasBurning then
		local currentChillModifier = target:FindModifierByName("modifier_chill")
		if currentChillModifier ~= nil then
			currentChillModifier:Enhance(power)
		else
			if target:HasModifier("modifier_wet") then
				power = power * 2
				target:RemoveModifierByName("modifier_wet")
			end
			target:AddNewModifier(caster, nil, "modifier_chill", { power = power })
		end
	end
end

function Spells:ApplyBurn(target, caster, damage)
	if Spells:IsResistantTo(target, ELEMENT_FIRE) or target:IsInvulnerable() then
		return
	end

	local wasWetOrChilled = Spells:DryAndWarm(target)
	if not wasWetOrChilled then
		local currentBurnModifier = target:FindModifierByName("modifier_burn")
		if currentBurnModifier ~= nil then
			currentBurnModifier:Reapply(damage)
		else
			target:AddNewModifier(caster, nil, "modifier_burn", { damage = damage })
		end
	end
end

function Spells:DryAndWarm(target)
	if target == nil or Spells:IsResistantTo(target, ELEMENT_FIRE) then
		return false
	end
	if target:HasModifier("modifier_wet") then
		target:RemoveModifierByName("modifier_wet")
		return true
	elseif target:HasModifier("modifier_chill") then
		target:RemoveModifierByName("modifier_chill")
		return true
	end
	return false
end

function Spells:ExtinguishWithWater(target)
	if target == nil or Spells:IsResistantTo(target, ELEMENT_WATER) then
		return false
	end
	if target:HasModifier("modifier_burn") then
		target:RemoveModifierByName("modifier_burn")
		return true
	end
	return false
end

function Spells:ExtinguishWithCold(target)
	if target == nil or Spells:IsResistantTo(target, ELEMENT_COLD) then
		return false
	end
	if target:HasModifier("modifier_burn") then
		target:RemoveModifierByName("modifier_burn")
		return true
	end
	return false
end


------------------------- HEALING  --------------------------

function Spells:Heal(target, source, heal, ignoreLifeShield)
	if (target.shieldElements ~= nil) and not ignoreLifeShield then
		local halfHeal = heal / 2
		heal = heal - halfHeal * Spells:ResistanceLevelTo(target, ELEMENT_LIFE)
	end

	if heal > 0.5 then
		if Spells.healPool[target] == nil then
			Spells.healPool[target] = {}
			Spells.healPool[target][source] = heal
		elseif Spells.healPool[target][source] == nil then
			Spells.healPool[target][source] = heal
		else
			Spells.healPool[target][source] = heal + Spells.healPool[target][source]
		end
	end
end

function Spells:HealAoE(center, radius, source, heal, dontHealSource)
	local unitsToHeal = FindUnitsInRadius(source:GetTeamNumber(), center, nil, radius, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL,
	    DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, true)
	for _, unit in pairs(unitsToHeal) do
		if not (unit == source and dontHealSource) then
			Spells:Heal(unit, source, heal, false)
		end
	end
end