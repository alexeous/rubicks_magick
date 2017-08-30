
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

function GetScaledRadiuses(factor)
	return { OMNI_SPELLS_RADIUSES[1] * factor, OMNI_SPELLS_RADIUSES[2] * factor, OMNI_SPELLS_RADIUSES[3] * factor }
end


if Spells == nil then
	Spells = class({})
end


function Spells:Precache(context)
	LinkLuaModifier("modifier_slow_move", "modifiers/modifier_slow_move.lua", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_wet", "modifiers/modifier_wet.lua", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_chill", "modifiers/modifier_chill.lua", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_burn", "modifiers/modifier_burn.lua", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_water_push", "modifiers/modifier_water_push.lua", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_knockdown", "modifiers/modifier_knockdown.lua", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_wet_cast_lightning", "modifiers/modifier_wet_cast_lightning.lua", LUA_MODIFIER_MOTION_NONE)

	PrecacheResource("particle", "particles/status_fx/status_effect_snow_heavy.vpcf", context)
	PrecacheResource("particle", "particles/status_fx/status_effect_slardar_amp_damage.vpcf", context)
	PrecacheResource("particle", "particles/wet_drips.vpcf", context)
	PrecacheResource("particle", "particles/status_fx/status_effect_burn.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_huskar/huskar_burning_spear_debuff.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_tusk/tusk_frozen_sigil_death.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_ancient_apparition/ancient_apparition_cold_feet_frozen.vpcf", context)
	PrecacheResource("particle", "particles/lightning/wet_cast_lightning.vpcf", context)

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
	ListenToGameEvent("entity_killed", Dynamic_Wrap(Spells, "OnEntityKilled"), self)

	CustomGameEventManager:RegisterListener("rm_directed_cast_down", Dynamic_Wrap(Spells, "OnDirectedCastKeyDown"))
	CustomGameEventManager:RegisterListener("rm_directed_cast_up", Dynamic_Wrap(Spells, "OnDirectedCastKeyUp"))
	CustomGameEventManager:RegisterListener("rm_self_cast_down", Dynamic_Wrap(Spells, "OnSelfCastKeyDown"))
	CustomGameEventManager:RegisterListener("rm_self_cast_up", Dynamic_Wrap(Spells, "OnSelfCastKeyUp"))

	RockThrow:Init()
	ElementSprays:Init()
	MagicShield:Init()
	Beams:Init()
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

function Spells:OnEntityKilled(keys)
	local killedUnit = EntIndexToHScript(keys.entindex_killed)
	if killedUnit ~= nil and killedUnit:IsRealHero() then
		local player = killedUnit:GetPlayerOwner()
		if player ~= nil then
			Spells:StopCasting(player)
		end
	end
end


function Spells:OnDirectedCastKeyDown(keys)
	local player = PlayerResource:GetPlayer(keys.playerID)
	local heroEntity = player:GetAssignedHero()
	if heroEntity == nil or heroEntity:IsStunned() or not heroEntity:IsAlive() then
		return
	end
	if player.spellCast ~= nil then 
		player.wantsToStartNewDirectedSpell = true
		return
	end

	local pickedElements = Elements:GetPickedElements(player)
	if next(pickedElements) == nil then
		Spells:MeleeAttack(player)
		return
	end	
	table.sort(pickedElements)
	Elements:RemoveAllElements(player)

	local castTable = {
		[ELEMENT_SHIELD] = {
			[ELEMENT_EARTH]     = function() StoneWall:PlaceStoneWall(player, pickedElements[3]) end,
			[ELEMENT_LIGHTNING] = function() LightningWall:PlaceLightningWall(player, pickedElements[3]) end,
			[ELEMENT_LIFE]      = function() Mines:PlaceLifeMines(player, pickedElements[3]) end,
			[ELEMENT_DEATH]     = function() Mines:PlaceDeathMines(player, pickedElements[3]) end,
			[ELEMENT_WATER] = {
				[ELEMENT_FIRE] = function() ElementWalls:PlaceSteamWall(player) end,
				[ELEMENT_COLD] = function() ElementWalls:PlaceIceWall(player) end,
				[DEFAULT]	   = function() ElementWalls:PlaceWaterWall(player, pickedElements[3]) end
			},
			[ELEMENT_FIRE] = function() ElementWalls:PlaceFireWall(player, pickedElements[3]) end,
			[ELEMENT_COLD] = function() ElementWalls:PlaceColdWall(player, pickedElements[3]) end,
			[EMPTY]        = function() MagicShield:PlaceFlatMagicShieldSpell(player) end,
		},
		[ELEMENT_EARTH] 	= function() RockThrow:StartRockThrow(player, pickedElements) end,
		[ELEMENT_LIGHTNING] = function() Lightning:DirectedLightning(player, pickedElements) end,
		[ELEMENT_LIFE] = {
			[ELEMENT_WATER] = {
				[ELEMENT_COLD] = function() IceSpikes:StartIceSpikes(player, ELEMENT_LIFE) end
			},
			[DEFAULT] = function() Beams:StartLifeBeam(player, pickedElements) end 
		},
		[ELEMENT_DEATH] = {
			[ELEMENT_WATER] = {
				[ELEMENT_COLD] = function() IceSpikes:StartIceSpikes(player, ELEMENT_DEATH) end
			},
			[DEFAULT] = function() Beams:StartDeathBeam(player, pickedElements) end
		},
		[ELEMENT_WATER] = {
			[ELEMENT_WATER] = {
				[ELEMENT_FIRE] = function() ElementSprays:StartSteamSpray(player, ELEMENT_WATER) end,
				[ELEMENT_COLD] = function() IceSpikes:StartIceSpikes(player, ELEMENT_WATER) end,
				[DEFAULT]      = function() ElementSprays:StartWaterSpray(player, #pickedElements) end,
			},
			[ELEMENT_FIRE] = function() ElementSprays:StartSteamSpray(player, pickedElements[3]) end,
			[ELEMENT_COLD] = function() IceSpikes:StartIceSpikes(player, pickedElements[3]) end,
			[EMPTY]        = function() ElementSprays:StartWaterSpray(player, 1) end,
		},
		[ELEMENT_FIRE] = function() ElementSprays:StartFireSpray(player, #pickedElements) end,
		[ELEMENT_COLD] = function() ElementSprays:StartColdSpray(player, #pickedElements) end
	}
	local spellFunction = table.serialRetrieve(castTable, pickedElements)
	if spellFunction ~= nil then
		spellFunction()
	else
		print("ERROR: no such spell in cast table")
	end
end

function Spells:OnSelfCastKeyDown(keys)
	local player = PlayerResource:GetPlayer(keys.playerID)
	local heroEntity = player:GetAssignedHero()
	if heroEntity == nil or heroEntity:IsStunned() or not heroEntity:IsAlive() then
		return
	end
	if player.spellCast ~= nil then
		player.wantsToStartNewSelfSpell = true
		return
	end

	local pickedElements = Elements:GetPickedElements(player)
	if next(pickedElements) == nil then
		return
	end	
	table.sort(pickedElements)
	Elements:RemoveAllElements(player)

	local castTable = {
		[ELEMENT_SHIELD] = {
			[EMPTY]   = function() MagicShield:PlaceRoundMagicShieldSpell(player) end,
			[DEFAULT] = function() SelfShield:ApplyElementSelfShield(heroEntity, pickedElements) end
		},
		[ELEMENT_EARTH]     = function() EarthStomp:EarthStomp(player, pickedElements) end,
		[ELEMENT_LIGHTNING] = function() Lightning:OmniLightning(player, pickedElements) end,
		[ELEMENT_LIFE] = {
			[ELEMENT_WATER] = {
				[ELEMENT_COLD] = function() OmniIceSpikes:OmniIceSpikes(player, ELEMENT_LIFE) end
			},
			[ELEMENT_LIFE] = {
				[ELEMENT_LIFE] = function() SelfHeal:StartSelfHeal(player, 3) end,
				[EMPTY]        = function() SelfHeal:StartSelfHeal(player, 2) end,
				[DEFAULT]      = function() OmniPulses:OmniLifePulseSpell(player, pickedElements) end
			},
			[EMPTY]        = function() SelfHeal:StartSelfHeal(player, 1) end,
			[DEFAULT]      = function() OmniPulses:OmniLifePulseSpell(player, pickedElements) end
		},
		[ELEMENT_DEATH] = {
			[ELEMENT_WATER] = {
				[ELEMENT_COLD] = function() OmniIceSpikes:OmniIceSpikes(player, ELEMENT_DEATH) end
			},
			[DEFAULT] = function() OmniPulses:OmniDeathPulseSpell(player, pickedElements) end
		},
		[ELEMENT_WATER] = {
			[ELEMENT_WATER] = {
				[ELEMENT_FIRE] = function() OmniElementSprays:OmniSteamSpraySpell(player, ELEMENT_WATER) end,
				[ELEMENT_COLD] = function() OmniIceSpikes:OmniIceSpikes(player, ELEMENT_WATER) end,
				[DEFAULT]      = function() OmniElementSprays:OmniWaterSpraySpell(player, #pickedElements) end
			},
			[ELEMENT_FIRE] = function() OmniElementSprays:OmniSteamSpraySpell(player, pickedElements[3]) end,
			[ELEMENT_COLD] = function() OmniIceSpikes:OmniIceSpikes(player, pickedElements[3]) end,
			[EMPTY]        = function() OmniElementSprays:OmniWaterSpraySpell(player, 1) end
		},
		[ELEMENT_FIRE] = function() OmniElementSprays:OmniFireSpraySpell(player, #pickedElements) end,
		[ELEMENT_COLD] = function() OmniElementSprays:OmniColdSpraySpell(player, #pickedElements) end
	}
	local spellFunction = table.serialRetrieve(castTable, pickedElements)
	if spellFunction ~= nil then
		spellFunction()
	else
		print("ERROR: no such spell in cast table")
	end
end

function Spells:OnDirectedCastKeyUp(keys)
	local player = PlayerResource:GetPlayer(keys.playerID)
	if player ~= nil then
		player.wantsToStartNewDirectedSpell = false
		if player.spellCast ~= nil and player.spellCast.castType ~= CAST_TYPE_INSTANT and not player.spellCast.isSelfCast then
			Spells:StopCasting(player)
		end
	end
end

function Spells:OnSelfCastKeyUp(keys)
	local player = PlayerResource:GetPlayer(keys.playerID)
	if player ~= nil then
		player.wantsToStartNewSelfSpell = false
		if player.spellCast ~= nil and player.spellCast.castType ~= CAST_TYPE_INSTANT and player.spellCast.isSelfCast then
			Spells:StopCasting(player)
		end
	end
end

----------     ----------     ----------     ----------     ----------     ----------     ----------     ----------     ----------     ----------

SPELLS_THINK_PERIOD = 0.03
function Spells:OnSpellsThink()
	local time = GameRules:GetGameTime()
	for playerID = 0, DOTA_MAX_PLAYERS - 1 do
		local player = PlayerResource:GetPlayer(playerID)
		if player ~= nil and player.spellCast ~= nil then
			local heroEntity = player:GetAssignedHero()
			if time > player.spellCast.endTime or not heroEntity:IsAlive() or heroEntity:IsStunned() then
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
							Spells:ApplyChill(victim, attacker, damage)
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
				if player.spellCast.dontMoveWhileCasting then
					MoveController:StopMove(player)
				end
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

	if player.spellCast.endFunction ~= nil then
		player.spellCast.endFunction(player)
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

	player.spellCast = nil

	if player.wantsToStartNewSelfSpell then
		Spells:OnSelfCastKeyDown({ playerID = player:GetPlayerID() })
		player.wantsToStartNewSelfSpell = false
	end
	if player.wantsToStartNewDirectedSpell then
		Spells:OnDirectedCastKeyDown({ playerID = player:GetPlayerID() })
		player.wantsToStartNewDirectedSpell = false
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
			Spells:ApplyElementDamageAoE(center, 110, heroEntity, ELEMENT_EARTH, 210, true, true)
		end
	end

	spellCastTable.hasAttacked = false

	Spells:StartCasting(player, spellCastTable)
end



------------------------- HEALTH MANIPULATION  --------------------------

function Spells:ApplyElementDamageAoE(center, radius, attacker, element, damage, dontDamageAttacker, applyModifiers, blockPerShield)
	local damagedAnyone = false
	local unitsToHurt = Util:FindUnitsInRadius(center, radius)
	for _, unit in pairs(unitsToHurt) do
		if not (unit == attacker and dontDamageAttacker) then
			damagedAnyone = damagedAnyone or Spells:ApplyElementDamage(unit, attacker, element, damage, applyModifiers, blockPerShield)
		end
	end
	return damagedAnyone
end

function Spells:ApplyElementDamage(victim, attacker, element, damage, applyModifiers, blockPerShield)
	if victim:IsInvulnerable() then
		return false
	end

	damage = Spells:GetDamageAfterShields(victim, damage, element, blockPerShield)

	if victim:HasModifier("modifier_wet") and ((element == ELEMENT_LIGHTNING) or (element == ELEMENT_COLD)) then
		damage = damage * 2
		victim:RemoveModifierByName("modifier_wet")
	end
	if damage < 0.5 then
		return false
	end
	local info = { damage = damage, element = element, applyModifiers = applyModifiers }
	if Spells.damagePool[victim] == nil then
		Spells.damagePool[victim] = {}
	end
	if Spells.damagePool[victim][attacker] == nil then
		Spells.damagePool[victim][attacker] = {}
	end
	table.insert(Spells.damagePool[victim][attacker], info)
	return true
end

function Spells:HealAoE(center, radius, source, heal, dontHealSource)
	local healedAnyone = false
	local unitsToHeal = Util:FindUnitsInRadius(center, radius)
	for _, unit in pairs(unitsToHeal) do
		if not (unit == source and dontHealSource) then
			healedAnyone = healedAnyone or Spells:Heal(unit, source, heal, false)
		end
	end
	return healedAnyone
end

function Spells:Heal(target, source, heal, ignoreLifeShield)
	if target:IsInvulnerable() then
		return false
	end
	
	if not ignoreLifeShield then
		heal = Spells:GetDamageAfterShields(target, heal, ELEMENT_LIFE)
	end
	if heal < 0.5 then
		return false
	end
	if Spells.healPool[target] == nil then
		Spells.healPool[target] = {}
		Spells.healPool[target][source] = heal
	elseif Spells.healPool[target][source] == nil then
		Spells.healPool[target][source] = heal
	else
		Spells.healPool[target][source] = heal + Spells.healPool[target][source]
	end
	return true
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
		return false
	end

	local wasBurning = Spells:ExtinguishWithWater(target)
	if not wasBurning and not target:HasModifier("modifier_chill") then
		target:AddNewModifier(caster, nil, "modifier_wet", {})
	end
	return true
end

function Spells:ApplyChill(target, caster, power)
	if Spells:IsResistantTo(target, ELEMENT_COLD) or target:IsInvulnerable() then
		return false
	end

	local wasBurning = Spells:ExtinguishWithCold(target)
	if not wasBurning then
		local currentChillModifier = target:FindModifierByName("modifier_chill")
		if currentChillModifier ~= nil then
			currentChillModifier:Enhance(power)
		else
			if target:HasModifier("modifier_wet") then
				target:RemoveModifierByName("modifier_wet")
			end
			target:AddNewModifier(caster, nil, "modifier_chill", { power = power })
		end
	end
	return true
end

function Spells:ApplyBurn(target, caster, damage)
	if Spells:IsResistantTo(target, ELEMENT_FIRE) or target:IsInvulnerable() then
		return false
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
	return true
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

------------------- WATER PUSH ------------------------

function Spells:AddWaterPush(target, caster, velocity, acceleration)
	local waterResist = Spells:ResistanceLevelTo(target, ELEMENT_WATER)
	if waterResist == 2 then
		return false
	end

	local earthResist = Spells:ResistanceLevelTo(target, ELEMENT_EARTH)
	local reduceFactor = math.pow(0.5, earthResist)
	velocity = (velocity or Vector(0, 0, 0)) * reduceFactor
	acceleration = (acceleration or Vector(0, 0, 0)) * reduceFactor
	local currentModifier = target:FindModifierByName("modifier_water_push")
	if currentModifier ~= nil then
		currentModifier:Enhance(velocity, acceleration)
	else
		local kv = {
			vel_x = velocity.x, vel_y = velocity.y, vel_z = velocity.z,
			acc_x = acceleration.x, acc_y = acceleration.y, acc_z = acceleration.z				
		}
		target:AddNewModifier(caster, nil, "modifier_water_push", kv)
	end
	return true
end

----------------------------------------------------------

function Spells:WetCastLightning(caster)
	Timers:CreateTimer(0.1, function()
		caster:AddNewModifier(caster, nil, "modifier_wet_cast_lightning", { duration = 1.0 })
	end)
end