require("table_extension")

require("libraries/animations")

require("elements")
require("move_controller")
require("hp")
require("modifiers")

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
require("spells/projectile")

local SPELLS_THINK_PERIOD = 0.02

OMNI_SPELLS_RADIUSES = { 200, 300, 400 }

CAST_TYPE_INSTANT = 1
CAST_TYPE_CONTINUOUS = 2
CAST_TYPE_CHARGING = 3


DRY_WARM_EXTINGUISH_GUARD_DURATION = 0.8

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
	LinkLuaModifier("modifier_knockdown", "modifiers/modifier_knockdown.lua", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_wet_cast_lightning", "modifiers/modifier_wet_cast_lightning.lua", LUA_MODIFIER_MOTION_NONE)

	PrecacheResource("particle", "particles/status_fx/status_effect_snow_heavy.vpcf", context)
	PrecacheResource("particle", "particles/status_fx/status_effect_slardar_amp_damage.vpcf", context)
	PrecacheResource("particle", "particles/wet_drips.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_huskar/huskar_burning_spear_debuff.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_tusk/tusk_frozen_sigil_death.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_ancient_apparition/ancient_apparition_cold_feet_frozen.vpcf", context)
	PrecacheResource("particle", "particles/lightning/wet_cast_lightning.vpcf", context)

	PrecacheResource("particle", "particles/status_fx/status_effect_burn.vpcf", context)
	PrecacheResource("particle_folder", "particles/modifier_status_fx/chilled", context)

	PrecacheResource("soundfile", "soundevents/rubicks_magick/melee_attack.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_kunkka.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_earth_spirit.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds.vsndevts", context)

	PrecacheResource("soundfile", "sounds/weapons/hero/earth_spirit/attack01.vsnd", context)
	PrecacheResource("soundfile", "sounds/weapons/hero/earth_spirit/attack02.vsnd", context)
	PrecacheResource("soundfile", "sounds/weapons/hero/shared/large_blade/whoosh01.vsnd", context)
	PrecacheResource("soundfile", "sounds/weapons/hero/shared/large_blade/whoosh02.vsnd", context)
	PrecacheResource("soundfile", "sounds/weapons/hero/shared/large_blade/whoosh03.vsnd", context)
	PrecacheResource("soundfile", "sounds/physics/damage/building/damage01.vsnd", context)
	PrecacheResource("soundfile", "sounds/physics/damage/building/damage02.vsnd", context)
	PrecacheResource("soundfile", "sounds/physics/damage/building/damage03.vsnd", context)

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
	ListenToGameEvent("entity_killed", Dynamic_Wrap(Spells, "OnEntityKilled"), self)

	CustomGameEventManager:RegisterListener("rm_directed_cast_down", Dynamic_Wrap(Spells, "OnDirectedCastKeyDown"))
	CustomGameEventManager:RegisterListener("rm_directed_cast_up", Dynamic_Wrap(Spells, "OnDirectedCastKeyUp"))
	CustomGameEventManager:RegisterListener("rm_self_cast_down", Dynamic_Wrap(Spells, "OnSelfCastKeyDown"))
	CustomGameEventManager:RegisterListener("rm_self_cast_up", Dynamic_Wrap(Spells, "OnSelfCastKeyUp"))

	HP:Init()
	RockThrow:Init()
	ElementSprays:Init()
	MagicShield:Init()
	Beams:Init()
	Placer:Init()
	Projectile:Init()
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
	local hero = player:GetAssignedHero()
	if hero == nil or not hero:IsAlive() then
		return
	end
	if player.spellCast ~= nil or hero:IsStunned() or Spells:IsCoolingDown(player) then 
		player.wantsToStartNewDirectedSpell = true
		return
	end

	MoveController:UpdateRotation(player, hero)
	
	local pickedElements = Elements:GetPickedElements(player)
	if next(pickedElements) == nil then
		Spells:MeleeAttack(player)
		return
	end	
	table.sort(pickedElements)
	Elements:RemoveAllElements(player)

	local castTable = {
		[ELEMENT_SHIELD] = {
			[ELEMENT_EARTH]     = function() StoneWall:PlaceStoneWallSpell(player, pickedElements[3]) end,
			[ELEMENT_LIGHTNING] = function() LightningWall:PlaceLightningWall(player, pickedElements[3]) end,
			[ELEMENT_LIFE]      = function() Mines:PlaceLifeMines(player, pickedElements[3]) end,
			[ELEMENT_DEATH]     = function() Mines:PlaceDeathMines(player, pickedElements[3]) end,
			[ELEMENT_WATER] = {
				[ELEMENT_FIRE] = function() ElementWalls:PlaceSteamWall(player) end,
				[ELEMENT_COLD] = function() ElementWalls:PlaceIceWallSpell(player) end,
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
	local hero = player:GetAssignedHero()
	if hero == nil or not hero:IsAlive() then
		return
	end
	if player.spellCast ~= nil or hero:IsStunned() or Spells:IsCoolingDown(player) then
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
			[DEFAULT] = function() SelfShield:ApplyElementSelfShield(hero, pickedElements) end
		},
		[ELEMENT_EARTH]     = function() EarthStomp:EarthStompSpell(player, pickedElements) end,
		[ELEMENT_LIGHTNING] = function() Lightning:OmniLightning(player, pickedElements) end,
		[ELEMENT_LIFE] = {
			[ELEMENT_WATER] = {
				[ELEMENT_COLD] = function() OmniIceSpikes:OmniIceSpikesSpell(player, ELEMENT_LIFE) end
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
				[ELEMENT_COLD] = function() OmniIceSpikes:OmniIceSpikesSpell(player, ELEMENT_DEATH) end
			},
			[DEFAULT] = function() OmniPulses:OmniDeathPulseSpell(player, pickedElements) end
		},
		[ELEMENT_WATER] = {
			[ELEMENT_WATER] = {
				[ELEMENT_FIRE] = function() OmniElementSprays:OmniSteamSpraySpell(player, ELEMENT_WATER) end,
				[ELEMENT_COLD] = function() OmniIceSpikes:OmniIceSpikesSpell(player, ELEMENT_WATER) end,
				[DEFAULT]      = function() OmniElementSprays:OmniWaterSpraySpell(player, #pickedElements) end
			},
			[ELEMENT_FIRE] = function() OmniElementSprays:OmniSteamSpraySpell(player, pickedElements[3]) end,
			[ELEMENT_COLD] = function() OmniIceSpikes:OmniIceSpikesSpell(player, pickedElements[3]) end,
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
		Spells:BaseOnCastKeyUp(player, false)
	end
end

function Spells:OnSelfCastKeyUp(keys)
	local player = PlayerResource:GetPlayer(keys.playerID)
	if player ~= nil then
		player.wantsToStartNewSelfSpell = false
		Spells:BaseOnCastKeyUp(player, true)
	end
end

function Spells:BaseOnCastKeyUp(player, isSelfCast)
	local spellCast = player.spellCast
	if spellCast == nil or (spellCast.isSelfCast or false) ~= (isSelfCast or false) then
		return
	end

	local castType = spellCast.castType
	if castType ~= CAST_TYPE_INSTANT then
		local minDuration = spellCast.minDuration
		if castType == CAST_TYPE_CONTINUOUS and minDuration ~= nil and Spells:TimeElapsedSinceCast(player) < minDuration then
			spellCast.wantsToStopContinuousCast = true
		else
			Spells:StopCasting(player)
		end
	end
end

----------     ----------     ----------     ----------     ----------     ----------     ----------     ----------     ----------     ----------

function Spells:OnSpellsThink()
	for playerID = 0, DOTA_MAX_PLAYERS - 1 do
		local player = PlayerResource:GetPlayer(playerID)
		Spells:SpellCastThink(player)
		Spells:CheckIfPlayerWantsToStartNewSpell(player)
	end

	return SPELLS_THINK_PERIOD
end

function Spells:SpellCastThink(player)
	if player == nil or player.spellCast == nil then
		return
	end
	local spellCast = player.spellCast
	local time = GameRules:GetGameTime()
	local hero = player:GetAssignedHero()
	local heroIsOff = not hero:IsAlive() or hero:IsStunned()
	local timeIsOver = time > spellCast.endTime
	local stopContinuousCastWithMinDuration = spellCast.wantsToStopContinuousCast and Spells:TimeElapsedSinceCast(player) > spellCast.minDuration
	if heroIsOff or timeIsOver or stopContinuousCastWithMinDuration then
		Spells:StopCasting(player)
	elseif spellCast.thinkFunction ~= nil and (spellCast.thinkPeriod == nil or time - spellCast.lastThinkTime >= spellCast.thinkPeriod) then
		spellCast.thinkFunction(player)
		spellCast.lastThinkTime = time
	end
end

function Spells:CheckIfPlayerWantsToStartNewSpell(player)
	if player == nil then
		return
	end
	if player.wantsToStartNewSelfSpell then
		player.wantsToStartNewSelfSpell = false
		Spells:OnSelfCastKeyDown({ playerID = player:GetPlayerID() })
	end
	if player.wantsToStartNewDirectedSpell then
		player.wantsToStartNewDirectedSpell = false
		Spells:OnDirectedCastKeyDown({ playerID = player:GetPlayerID() })
	end
end

function Spells:IsCoolingDown(player)
	return player.cooldownEnd ~= nil and GameRules:GetGameTime() < player.cooldownEnd
end

function Spells:TimeElapsedSinceCast(player)
	return GameRules:GetGameTime() - player.spellCast.startTime
end

function Spells:StartCasting(player, infoTable)
	player.spellCast = infoTable
	local spellCast = player.spellCast

	spellCast.startTime = GameRules:GetGameTime()
	spellCast.endTime = spellCast.startTime + spellCast.duration
	spellCast.lastThinkTime = GameRules:GetGameTime()

	local hero = player:GetAssignedHero()
	if hero ~= nil then
		if spellCast.castingGesture ~= nil then
			if player.moveToPos ~= nil then
				if spellCast.dontMoveWhileCasting then
					MoveController:StopMove(player)
				end
				hero:FadeGesture(ACT_DOTA_RUN)
			end
			local animationParams = {
				duration = spellCast.duration,
				activity = spellCast.castingGesture,
				rate = spellCast.castingGestureRate,
				translate = spellCast.castingGestureTranslate
			}
			StartAnimation(hero, animationParams)
			if spellCast.loopSoundList ~= nil then
				for _, sound in pairs(spellCast.loopSoundList) do
					hero:EmitSound(sound)
				end
			end
		end

		if spellCast.slowMovePercentage ~= nil then
			local kv = { duration = spellCast.duration, slowMovePercentage = spellCast.slowMovePercentage }
			hero:AddNewModifier(hero, nil, "modifier_slow_move", kv)
		end

		if spellCast.castType == CAST_TYPE_CHARGING then
			local info = { phase1 = spellCast.chargingPhase1Duration, phase2 = spellCast.chargingPhase2Duration }
			CustomGameEventManager:Send_ServerToPlayer(player, "rm_cb_e", info)
			if spellCast.chargingParticle ~= nil then
				spellCast.chargingParticleID = ParticleManager:CreateParticle(spellCast.chargingParticle, PATTACH_ABSORIGIN_FOLLOW, hero)
			end
		end
	end
end

function Spells:StopCasting(player)
	local spellCast = player.spellCast
	if spellCast == nil then
		return
	end

	if spellCast.endFunction ~= nil then
		spellCast.endFunction(player)
	end

	local hero = player:GetAssignedHero()
	if hero ~= nil then
		if spellCast.castingGesture ~= nil then
			EndAnimation(hero)
			if player.moveToPos ~= nil then
				hero:StartGesture(ACT_DOTA_RUN)
			end
			MoveController:UpdateRotation(player, hero)
		end
		if hero:HasModifier("modifier_slow_move") then
			hero:RemoveModifierByName("modifier_slow_move")
		end	
		if spellCast.loopSoundList ~= nil then
			for _, sound in pairs(spellCast.loopSoundList) do
				hero:StopSound(sound)
			end
		end
	end

	if spellCast.castType == CAST_TYPE_CHARGING then
		CustomGameEventManager:Send_ServerToPlayer(player, "rm_cb_d", {})
		if spellCast.chargingParticleID ~= nil then
			ParticleManager:DestroyParticle(spellCast.chargingParticleID, false)
		end
	end

	if spellCast.cooldown ~= nil then
		player.cooldownEnd = GameRules:GetGameTime() + spellCast.cooldown
	end

	player.spellCast = nil

	Spells:CheckIfPlayerWantsToStartNewSpell(player)
end

------------------------- MELEE ATTACK ------------------------------

function Spells:MeleeAttack(player)
	local spellCastTable = {
		castType = CAST_TYPE_INSTANT,
		duration = 0.6,
		dontMoveWhileCasting = true,
		castingGesture = ACT_DOTA_ATTACK,
		castingGestureRate = 1.5
	}
	spellCastTable.thinkFunction = function(player)
		local timeHasCome = Spells:TimeElapsedSinceCast(player) > 0.3
		if timeHasCome and not player.spellCast.hasAttacked then 		-- do damage only after a small delay
			player.spellCast.hasAttacked = true
			local hero = player:GetAssignedHero()
			local center = hero:GetAbsOrigin() + hero:GetForwardVector() * 110
			if HP:ApplyElementAoE(center, 110, hero, ELEMENT_EARTH, 210, true, true) then
				player:GetAssignedHero():EmitSound("MeleeAttack")
			elseif #Util:FindUnitsInRadius(center, 110, DOTA_UNIT_TARGET_FLAG_INVULNERABLE) > 1 then
				player:GetAssignedHero():EmitSound("MeleeAttackBlocked")
			end			
		end
	end
	spellCastTable.hasAttacked = false

	Spells:StartCasting(player, spellCastTable)
	Timers:CreateTimer(0.1, function() player:GetAssignedHero():EmitSound("MeleeAttackWhoosh") end)
end

function Spells:WetCastLightning(caster)
	Timers:CreateTimer(0.1, function()
		caster:AddNewModifier(caster, nil, "modifier_wet_cast_lightning", { duration = 0.5 })
	end)
	caster:EmitSound("WetCastLightning1")
	caster:EmitSound("WetCastLightning2")
	caster:EmitSound("WetCastLightning3")
end

function Spells:RegisterCastedSolidWall(caster, wall)
	caster.castedSolidWalls = caster.castedSolidWalls or {}
	table.insert(caster.castedSolidWalls, wall)
end

function Spells:UnregisterCastedSolidWall(caster, wall)
	if caster.castedSolidWalls ~= nil then
		table.removeItem(caster.castedSolidWalls, wall)
	end
end

function Spells:RemoveMagicShieldAndSolidWalls(player)
	local hero = player:GetAssignedHero()
	if hero.castedSolidWalls ~= nil then
		local solidWallCopy = table.clone(hero.castedSolidWalls) -- in onKilledCallback there is a removal from castedSolidWalls, so looping over it itself can went wrong
		for _, wall in pairs(solidWallCopy) do
			Placer:KillQuietly(wall)
		end
		hero.castedSolidWalls = {}
	end
	MagicShield:DestroyCurrentShield(player)
end