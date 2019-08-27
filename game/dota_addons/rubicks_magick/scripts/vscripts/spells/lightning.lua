if Lightning == nil then
	Lightning = class({})
end

DIRECTED_LIGHTNING_DISTANCE = { 440, 670, 900 }
OMNI_LIGHTNING_DISTANCE = { 440, 555, 670 }
COS_30 = math.cos(math.rad(30))

function Lightning:Precache(context)	
	LinkLuaModifier("modifier_lightning_stun", "modifiers/modifier_lightning_stun.lua", LUA_MODIFIER_MOTION_NONE)
	PrecacheResource("particle_folder", "particles/lightning", context)

	PrecacheResource("soundfile", "soundevents/rubicks_magick/lightning.vsndevts", context)
	
	PrecacheResource("soundfile", "sounds/weapons/creep/neutral/harpystorm_transfer_01.vsnd", context)
	PrecacheResource("soundfile", "sounds/weapons/creep/neutral/harpystorm_transfer_02.vsnd", context)
	PrecacheResource("soundfile", "sounds/weapons/creep/neutral/harpystorm_transfer_03.vsnd", context)
	PrecacheResource("soundfile", "sounds/weapons/creep/neutral/harpystorm_transfer_04.vsnd", context)
	PrecacheResource("soundfile", "sounds/weapons/hero/zuus/lightning_bolt.vsnd", context)
	PrecacheResource("soundfile", "sounds/weapons/hero/disruptor/thunder_strike_target.vsnd", context)
	PrecacheResource("soundfile", "sounds/weapons/hero/zuus/arc_lightning.vsnd", context)
	PrecacheResource("soundfile", "sounds/weapons/creep/neutral/harpystorm_transfer_01.vsnd", context)
	PrecacheResource("soundfile", "sounds/weapons/creep/neutral/harpystorm_transfer_02.vsnd", context)
	PrecacheResource("soundfile", "sounds/weapons/creep/neutral/harpystorm_transfer_03.vsnd", context)
	PrecacheResource("soundfile", "sounds/weapons/creep/neutral/harpystorm_transfer_04.vsnd", context)
	PrecacheResource("soundfile", "sounds/weapons/hero/razor/razor_lightning_strike_01.vsnd", context)
	PrecacheResource("soundfile", "sounds/weapons/hero/zuus/lightning_bolt.vsnd", context)
	
end

function Lightning:PlayerConnected(player)
end


function Lightning:DirectedLightning(player, pickedElements)
	local caster = player:GetAssignedHero()
	if caster:HasModifier("modifier_wet") then
		Spells:WetCastLightning(caster)
		return
	end
	local additionalEffectTable = {
		[ELEMENT_LIGHTNING] = {
			[ELEMENT_LIGHTNING] = {
				[ELEMENT_LIFE] = function(target) HP:ApplyElement(target, caster, ELEMENT_LIFE, 75) end,
				[ELEMENT_DEATH] = function(target) HP:ApplyElement(target, caster, ELEMENT_DEATH, 52) end,
				[ELEMENT_FIRE] = function(target) HP:ApplyElement(target, caster, ELEMENT_FIRE, 15) end,
				[ELEMENT_COLD] = function(target) HP:ApplyElement(target, caster, ELEMENT_COLD, 18) end
			},
			[ELEMENT_LIFE] = {
				[ELEMENT_LIFE] = function(target) HP:ApplyElement(target, caster, ELEMENT_LIFE, 106) end,
				[ELEMENT_FIRE] = function(target) 
					HP:ApplyElement(target, caster, ELEMENT_LIFE, 75)
					HP:ApplyElement(target, caster, ELEMENT_FIRE, 15)
				end,
				[ELEMENT_COLD] = function(target) 
					HP:ApplyElement(target, caster, ELEMENT_LIFE, 75)
					HP:ApplyElement(target, caster, ELEMENT_COLD, 18)
				end,
				[EMPTY] = function(target) HP:ApplyElement(target, caster, ELEMENT_LIFE, 75) end
			},
			[ELEMENT_DEATH] = {
				[ELEMENT_DEATH] = function(target) HP:ApplyElement(target, caster, ELEMENT_DEATH, 74) end,
				[ELEMENT_FIRE] = function(target) 
					HP:ApplyElement(target, caster, ELEMENT_DEATH, 52)
					HP:ApplyElement(target, caster, ELEMENT_FIRE, 15)
				end,
				[ELEMENT_COLD] = function(target) 
					HP:ApplyElement(target, caster, ELEMENT_DEATH, 52)
					HP:ApplyElement(target, caster, ELEMENT_COLD, 18)
				end,
				[EMPTY] = function(target) HP:ApplyElement(target, caster, ELEMENT_DEATH, 52) end
			},
			[ELEMENT_FIRE] = {
				[ELEMENT_FIRE] = function(target) HP:ApplyElement(target, caster, ELEMENT_FIRE, 21) end,
				[EMPTY] = function(target) HP:ApplyElement(target, caster, ELEMENT_FIRE, 15) end
			},
			[ELEMENT_COLD] = {
				[ELEMENT_COLD] = function(target) HP:ApplyElement(target, caster, ELEMENT_COLD, 26) end,
				[EMPTY] = function(target) HP:ApplyElement(target, caster, ELEMENT_COLD, 18) end
			}
		}
	}
	local additionalEffectFunc = table.serialRetrieve(additionalEffectTable, pickedElements)
	local lightningCount = table.count(pickedElements, ELEMENT_LIGHTNING)
	local lightningDamage = ({ 42, 60, 73 })[lightningCount]
	local spellCastTable = {
		castType = CAST_TYPE_INSTANT,
		duration = 1.5,
		dontMoveWhileCasting = true,
		castingGesture = ACT_DOTA_CAST_ABILITY_3,
		castingGestureRate = 0.5,
		thinkFunction = function(player) Lightning:OnDirectedLightningThink(player) end,
		thinkPeriod = 0.4,
		lightning_Color = Lightning:GetColor(pickedElements),
		lightning_IsLife = table.indexOf(pickedElements, ELEMENT_LIFE) ~= nil,
		lightning_IsDeath = table.indexOf(pickedElements, ELEMENT_DEATH) ~= nil,
		lightning_Distance = DIRECTED_LIGHTNING_DISTANCE[lightningCount],
		lightning_StrikesLeft = 3,
		lightning_EffectFunction = Lightning:MakeEffectFunction(caster, lightningDamage, additionalEffectFunc)
	}
	Spells:StartCasting(player, spellCastTable)
end

function Lightning:OmniLightning(player, pickedElements)
	local caster = player:GetAssignedHero()
	if caster:HasModifier("modifier_wet") then
		Spells:WetCastLightning(caster)
		return
	end
	local additionalEffectTable = {
		[ELEMENT_LIGHTNING] = {
			[ELEMENT_LIGHTNING] = {
				[ELEMENT_LIFE] = function(target) HP:ApplyElement(target, caster, ELEMENT_LIFE, 65) end,
				[ELEMENT_DEATH] = function(target) HP:ApplyElement(target, caster, ELEMENT_DEATH, 55) end,
				[ELEMENT_FIRE] = function(target) HP:ApplyElement(target, caster, ELEMENT_FIRE, 15) end,
				[ELEMENT_COLD] = function(target) HP:ApplyElement(target, caster, ELEMENT_COLD, 20) end
			},
			[ELEMENT_LIFE] = {
				[ELEMENT_LIFE] = function(target) HP:ApplyElement(target, caster, ELEMENT_LIFE, 92) end,
				[ELEMENT_FIRE] = function(target) 
					HP:ApplyElement(target, caster, ELEMENT_LIFE, 65)
					HP:ApplyElement(target, caster, ELEMENT_FIRE, 15)
				end,
				[ELEMENT_COLD] = function(target) 
					HP:ApplyElement(target, caster, ELEMENT_LIFE, 65)
					HP:ApplyElement(target, caster, ELEMENT_COLD, 20)
				end,
				[EMPTY] = function(target) HP:ApplyElement(target, caster, ELEMENT_LIFE, 65) end
			},
			[ELEMENT_DEATH] = {
				[ELEMENT_DEATH] = function(target) HP:ApplyElement(target, caster, ELEMENT_DEATH, 78) end,
				[ELEMENT_FIRE] = function(target) 
					HP:ApplyElement(target, caster, ELEMENT_DEATH, 55)
					HP:ApplyElement(target, caster, ELEMENT_FIRE, 15)
				end,
				[ELEMENT_COLD] = function(target) 
					HP:ApplyElement(target, caster, ELEMENT_DEATH, 55)
					HP:ApplyElement(target, caster, ELEMENT_COLD, 20)
				end,
				[EMPTY] = function(target) HP:ApplyElement(target, caster, ELEMENT_DEATH, 55) end
			},
			[ELEMENT_FIRE] = {
				[ELEMENT_FIRE] = function(target) HP:ApplyElement(target, caster, ELEMENT_FIRE, 22) end,
				[EMPTY] = function(target) HP:ApplyElement(target, caster, ELEMENT_FIRE, 15) end
			},
			[ELEMENT_COLD] = {
				[ELEMENT_COLD] = function(target) HP:ApplyElement(target, caster, ELEMENT_COLD, 28) end,
				[EMPTY] = function(target) HP:ApplyElement(target, caster, ELEMENT_COLD, 20) end
			}
		}
	}
	local additionalEffectFunc = table.serialRetrieve(additionalEffectTable, pickedElements)
	local lightningCount = table.count(pickedElements, ELEMENT_LIGHTNING)
	local lightningDamage = ({ 48, 68, 83 })[lightningCount]
	local spellCastTable = {
		castType = CAST_TYPE_INSTANT,
		duration = 1.65,
		dontMoveWhileCasting = true,
		castingGesture = ACT_DOTA_CAST_ABILITY_5,
		castingGestureRate = 0.5,
		castingGestureTranslate = "guardian_angel",
		thinkFunction = function(player) Lightning:OnOmniLightningThink(player) end,
		thinkPeriod = 0.4,
		lightning_Color = Lightning:GetColor(pickedElements),
		lightning_IsLife = table.indexOf(pickedElements, ELEMENT_LIFE) ~= nil,
		lightning_IsDeath = table.indexOf(pickedElements, ELEMENT_DEATH) ~= nil,
		lightning_Distance = OMNI_LIGHTNING_DISTANCE[lightningCount],
		lightning_StrikesLeft = 3,
		lightning_EffectFunction = Lightning:MakeEffectFunction(caster, lightningDamage, additionalEffectFunc)
	}
	Spells:StartCasting(player, spellCastTable)
	
	if table.indexOf(pickedElements, ELEMENT_COLD) then
		Modifiers:ExtinguishWithElement(caster, ELEMENT_COLD)
	end
	if table.indexOf(pickedElements, ELEMENT_FIRE) then
		Modifiers:DryAndWarm(caster)
	end
end

function Lightning:GetColor(pickedElements)
	local color = Vector(160, 80, 255)
	if table.indexOf(pickedElements, ELEMENT_LIFE)  then color = Vector(97, 255, 65) end
	if table.indexOf(pickedElements, ELEMENT_DEATH) then color = Vector(255, 30, 30) end
	if table.indexOf(pickedElements, ELEMENT_FIRE)  then color = Vector(255, 135, 70) end
	if table.indexOf(pickedElements, ELEMENT_COLD)  then color = Vector(113, 190, 240) end
	return color
end

function Lightning:MakeEffectFunction(caster, lightningDamage, additionalEffectFunc)
	return function(target)
		HP:ApplyElement(target, caster, ELEMENT_LIGHTNING, lightningDamage)
		if additionalEffectFunc ~= nil then
			additionalEffectFunc(target)
		end
		target:AddNewModifier(caster, nil, "modifier_lightning_stun", { duration = 0.15 })
		target:EmitSound("LightningArc")
	end
end

function Lightning:OnDirectedLightningThink(player)
	local spellCast = player.spellCast
	spellCast.thinkPeriod = 0.25

	local caster = player:GetAssignedHero()
	local distance = spellCast.lightning_Distance
	local effectFunc = spellCast.lightning_EffectFunction
	local isDeath = spellCast.lightning_IsDeath
	local isLife = spellCast.lightning_IsLife
	local color = spellCast.lightning_Color

	Lightning:EmitDirectedLightning(caster, distance, effectFunc, isDeath, isLife, color)

	spellCast.lightning_StrikesLeft = spellCast.lightning_StrikesLeft - 1
	if spellCast.lightning_StrikesLeft <= 0 then
		spellCast.thinkFunction = nil
	end

	Lightning:EmitStrikeSound(caster)
end

function Lightning:OnOmniLightningThink(player)
	local spellCast = player.spellCast
	spellCast.thinkPeriod = 0.25

	local caster = player:GetAssignedHero()
	local distance = player.spellCast.lightning_Distance
	local effectFunc = spellCast.lightning_EffectFunction
	local isDeath = spellCast.lightning_IsDeath
	local isLife = spellCast.lightning_IsLife
	local color = spellCast.lightning_Color

	Lightning:EmitOmniLightning(caster, distance, effectFunc, isDeath, isLife, color)
	
	spellCast.lightning_StrikesLeft = spellCast.lightning_StrikesLeft - 1
	if spellCast.lightning_StrikesLeft <= 0 then
		spellCast.thinkFunction = nil
	end

	Lightning:EmitStrikeSound(caster)
end

function Lightning:EmitDirectedLightning(caster, distance, effectFunc, isDeath, isLife, color)
	local target = Lightning:GetDirectedLightningTarget(caster, distance)
	if target == nil then
		local endPos = caster:GetAbsOrigin() + caster:GetForwardVector() * distance
		local randomOffset = Vector(math.random(-50, 50), math.random(-50, 50), math.random(-100, 100))
		Lightning:CreateParticleStartingAtStaff(caster, endPos + randomOffset, true, isDeath, isLife, color)
	else
		effectFunc(target)
		Lightning:CreateParticleStartingAtStaff(caster, target:GetAbsOrigin(), false, isDeath, isLife, color)
		Lightning:ChainLightning(caster, target, distance * 0.65, { target }, effectFunc, isDeath, isLife, color)
	end
end

function Lightning:EmitOmniLightning(caster, distance, effectFunc, isDeath, isLife, color)
	local targets = Lightning:GetOmniLightningTargets(caster, distance)
	
	if not table.any(targets) then
		for i = 1, math.random(2, 3) do
			local randomEndPos = caster:GetAbsOrigin() + RandomVector(1):Normalized() * distance
			Lightning:CreateParticleStartingAtStaff(caster, randomEndPos, true, isDeath, isLife, color)
		end
		return
	end

	for _, target in pairs(targets) do
		effectFunc(target)
		Lightning:CreateParticleStartingAtStaff(caster, target:GetAbsOrigin(), false, isDeath, isLife, color)
	end
end

function Lightning:ChainLightning(caster, startUnit, distance, affectedUnits, effectFunc, isDeath, isLife, color)
	local target = Lightning:GetChainLightningTarget(caster, startUnit, distance, affectedUnits)
	if target == nil then
		return
	end
	effectFunc(target)
	Lightning:CreateParticle(startUnit:GetAbsOrigin(), target:GetAbsOrigin(), false, isDeath, isLife, color)
	table.insert(affectedUnits, target)
	Lightning:ChainLightning(caster, target, distance * 0.65, affectedUnits, effectFunc, isDeath, isLife, color)
end

function Lightning:GetDirectedLightningTarget(caster, distance)
	local origin = caster:GetAbsOrigin()
	local forward = caster:GetForwardVector()

	local targets = Util:FindUnitsInRadius(origin, distance, DOTA_UNIT_TARGET_FLAG_INVULNERABLE)
	targets = table.where(targets, function(_, t)
		if t == caster then
			return false
		end
		local toTarget = t:GetAbsOrigin() - origin
		return Util:AngleBetweenVectorsLessThanAcosOf(forward, toTarget, COS_30)
	end)
	return Lightning:GetMostAttractiveTarget(targets, caster)
end

function Lightning:GetOmniLightningTargets(caster, distance) 
	local origin = caster:GetAbsOrigin()
	local targets = Util:FindUnitsInRadius(origin, distance, DOTA_UNIT_TARGET_FLAG_INVULNERABLE)

	targets = table.where(targets, function(_, t)
		if t == caster then
			return false
		end
		local unitsInLine = Util:FindUnitsInLine(origin, t:GetAbsOrigin(), 50, DOTA_UNIT_TARGET_FLAG_INVULNERABLE)
		return not table.any(unitsInLine, function(_, u) 
			return u ~= t and u.isWall 
		end)
	end)
	return targets
end

function Lightning:GetChainLightningTarget(caster, startUnit, distance, affectedUnits)
	local startPos = startUnit:GetAbsOrigin()
	local startToCaster = caster:GetAbsOrigin() - startPos

	local targets = Util:FindUnitsInRadius(startPos, distance, DOTA_UNIT_TARGET_FLAG_INVULNERABLE)
	targets = table.where(targets, function(_, t)
		return t ~= caster and t ~= startUnit and not table.indexOf(affectedUnits, t) and
			Lightning:TraceLineToTarget(startUnit, t) and 
			not Util:AngleBetweenVectorsLessThanAcosOf(t:GetAbsOrigin() - startPos, startToCaster, COS_30)
	end)
	return Lightning:GetMostAttractiveTarget(targets, caster)
end

function Lightning:TraceLineToTarget(from, target)
	local traceTable = { startpos = from:GetAbsOrigin(), endpos = target:GetAbsOrigin(), ignore = from }
	return TraceLine(traceTable) and traceTable.hit and traceTable.enthit == target
end

function Lightning:GetMostAttractiveTarget(candidates, caster)
	if not table.any(candidates) then
		return nil
	end

	local casterPos = caster:GetAbsOrigin()
	local function SqrLength2D(vec)
		return vec:Dot(vec)
	end
	local function IsACloserToCasterThanB(a, b)
		local aPos = a:GetAbsOrigin()
		local bPos = b:GetAbsOrigin()
		return SqrLength2D(casterPos - aPos) < SqrLength2D(casterPos - bPos)
	end
	local walls = table.where(candidates, function(_, x) return x.isWall end)
	return table.min(walls, IsACloserToCasterThanB) or table.min(candidates, IsACloserToCasterThanB)
end

function Lightning:CreateParticle(startPos, endPos, noTarget, isDeath, isLife, color)
	local particle = Lightning:CreateParticleBase(endPos, noTarget, isDeath, isLife, color)
	ParticleManager:SetParticleControl(particle, 0, startPos + Vector(0, 0, 100))
end

function Lightning:CreateParticleStartingAtStaff(caster, endPos, noTarget, isDeath, isLife, color)
	local particle = Lightning:CreateParticleBase(endPos, noTarget, isDeath, isLife, color)
	ParticleManager:SetParticleControlEnt(particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_staff", caster:GetOrigin(), true)
end

function Lightning:CreateParticleBase(endPos, noTarget, isDeath, isLife, color)
	local particleName = isDeath and "particles/lightning/lightning_death.vpcf" or "particles/lightning/lightning.vpcf"
	local particle = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 1, endPos + Vector(0, 0, 100))
	ParticleManager:SetParticleControl(particle, 3, color)
	ParticleManager:SetParticleControl(particle, 4, Vector(noTarget and 0 or 1, isLife and 1 or 0, 0))
	return particle
end

function Lightning:EmitStrikeSound(caster)
	caster:EmitSound("LightningStrike1")
	caster:EmitSound("LightningStrike2")
	caster:EmitSound("LightningStrike3")
end