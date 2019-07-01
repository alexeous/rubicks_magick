if Lightning == nil then
	Lightning = class({})
end

DIRECTED_LIGHTNING_DISTANCE = { 410, 560, 760 }
OMNI_LIGHTNING_DISTANCE = { 410, 485, 560 }

function Lightning:Precache(context)	
	LinkLuaModifier("modifier_lightning_stun", "modifiers/modifier_lightning_stun.lua", LUA_MODIFIER_MOTION_NONE)
	PrecacheResource("particle_folder", "particles/lightning", context)

	PrecacheResource("soundfile", "soundevents/rubicks_magick/lightning.vsndevts", context)
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
				[ELEMENT_LIFE] = function(target) Spells:Heal(target, caster, 75) end,
				[ELEMENT_DEATH] = function(target) Spells:ApplyElementDamage(target, caster, ELEMENT_DEATH, 52) end,
				[ELEMENT_FIRE] = function(target) Spells:ApplyElementDamage(target, caster, ELEMENT_FIRE, 15, true) end,
				[ELEMENT_COLD] = function(target) Spells:ApplyElementDamage(target, caster, ELEMENT_COLD, 18, true) end
			},
			[ELEMENT_LIFE] = {
				[ELEMENT_LIFE] = function(target) Spells:Heal(target, caster, 106) end,
				[ELEMENT_FIRE] = function(target) 
					Spells:Heal(target, caster, 75)
					Spells:ApplyElementDamage(target, caster, ELEMENT_FIRE, 15, true)
				end,
				[ELEMENT_COLD] = function(target) 
					Spells:Heal(target, caster, 75)
					Spells:ApplyElementDamage(target, caster, ELEMENT_COLD, 18, true)
				end,
				[EMPTY] = function(target) Spells:Heal(target, caster, 75) end
			},
			[ELEMENT_DEATH] = {
				[ELEMENT_DEATH] = function(target) Spells:ApplyElementDamage(target, caster, ELEMENT_DEATH, 74) end,
				[ELEMENT_FIRE] = function(target) 
					Spells:ApplyElementDamage(target, caster, ELEMENT_DEATH, 52)
					Spells:ApplyElementDamage(target, caster, ELEMENT_FIRE, 15, true)
				end,
				[ELEMENT_COLD] = function(target) 
					Spells:ApplyElementDamage(target, caster, ELEMENT_DEATH, 52)
					Spells:ApplyElementDamage(target, caster, ELEMENT_COLD, 18, true)
				end,
				[EMPTY] = function(target) Spells:ApplyElementDamage(target, caster, ELEMENT_DEATH, 52) end
			},
			[ELEMENT_FIRE] = {
				[ELEMENT_FIRE] = function(target) Spells:ApplyElementDamage(target, caster, ELEMENT_FIRE, 21, true) end,
				[EMPTY] = function(target) Spells:ApplyElementDamage(target, caster, ELEMENT_FIRE, 15, true) end
			},
			[ELEMENT_COLD] = {
				[ELEMENT_COLD] = function(target) Spells:ApplyElementDamage(target, caster, ELEMENT_COLD, 26, true) end,
				[EMPTY] = function(target) Spells:ApplyElementDamage(target, caster, ELEMENT_COLD, 18, true) end
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
				[ELEMENT_LIFE] = function(target) Spells:Heal(target, caster, 65) end,
				[ELEMENT_DEATH] = function(target) Spells:ApplyElementDamage(target, caster, ELEMENT_DEATH, 55) end,
				[ELEMENT_FIRE] = function(target) Spells:ApplyElementDamage(target, caster, ELEMENT_FIRE, 15, true) end,
				[ELEMENT_COLD] = function(target) Spells:ApplyElementDamage(target, caster, ELEMENT_COLD, 20, true) end
			},
			[ELEMENT_LIFE] = {
				[ELEMENT_LIFE] = function(target) Spells:Heal(target, caster, 92) end,
				[ELEMENT_FIRE] = function(target) 
					Spells:Heal(target, caster, 65)
					Spells:ApplyElementDamage(target, caster, ELEMENT_FIRE, 15, true)
				end,
				[ELEMENT_COLD] = function(target) 
					Spells:Heal(target, caster, 65)
					Spells:ApplyElementDamage(target, caster, ELEMENT_COLD, 20, true)
				end,
				[EMPTY] = function(target) Spells:Heal(target, caster, 65) end
			},
			[ELEMENT_DEATH] = {
				[ELEMENT_DEATH] = function(target) Spells:ApplyElementDamage(target, caster, ELEMENT_DEATH, 78) end,
				[ELEMENT_FIRE] = function(target) 
					Spells:ApplyElementDamage(target, caster, ELEMENT_DEATH, 55)
					Spells:ApplyElementDamage(target, caster, ELEMENT_FIRE, 15, true)
				end,
				[ELEMENT_COLD] = function(target) 
					Spells:ApplyElementDamage(target, caster, ELEMENT_DEATH, 55)
					Spells:ApplyElementDamage(target, caster, ELEMENT_COLD, 20, true)
				end,
				[EMPTY] = function(target) Spells:ApplyElementDamage(target, caster, ELEMENT_DEATH, 55) end
			},
			[ELEMENT_FIRE] = {
				[ELEMENT_FIRE] = function(target) Spells:ApplyElementDamage(target, caster, ELEMENT_FIRE, 22, true) end,
				[EMPTY] = function(target) Spells:ApplyElementDamage(target, caster, ELEMENT_FIRE, 15, true) end
			},
			[ELEMENT_COLD] = {
				[ELEMENT_COLD] = function(target) Spells:ApplyElementDamage(target, caster, ELEMENT_COLD, 28, true) end,
				[EMPTY] = function(target) Spells:ApplyElementDamage(target, caster, ELEMENT_COLD, 20, true) end
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
		Spells:ExtinguishWithElement(caster, ELEMENT_COLD)
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
		Spells:ApplyElementDamage(target, caster, ELEMENT_LIGHTNING, lightningDamage)
		if additionalEffectFunc ~= nil then
			additionalEffectFunc(target)
		end
		target:AddNewModifier(caster, nil, "modifier_lightning_stun", { duration = 0.2 })
		target:EmitSound("LightningArc")
	end
end

function Lightning:CreateParticle(player, startPos, endPos, noTarget)
	local particle = Lightning:CreateParticleBase(player, endPos, noTarget)
	ParticleManager:SetParticleControl(particle, 0, startPos + Vector(0, 0, 100))
end

function Lightning:CreateParticleStartingAtStaff(player, caster, endPos, noTarget)
	local particle = Lightning:CreateParticleBase(player, endPos, noTarget)
	ParticleManager:SetParticleControlEnt(particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_staff", caster:GetOrigin(), true)
end

function Lightning:CreateParticleBase(player, endPos, noTarget)
	local particleName = player.spellCast.lightning_IsDeath and "particles/lightning/lightning_death.vpcf" or "particles/lightning/lightning.vpcf"
	local particle = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 1, endPos + Vector(0, 0, 100))
	ParticleManager:SetParticleControl(particle, 3, player.spellCast.lightning_Color)
	ParticleManager:SetParticleControl(particle, 4, Vector(noTarget and 0 or 1, player.spellCast.lightning_IsLife and 1 or 0, 0))
	return particle
end

function Lightning:ChainLightning(player, startUnit, maxDistance, startPos, attachAtStaff)
	startPos = startPos or startUnit:GetAbsOrigin()
	local effectFunc = player.spellCast.lightning_EffectFunction
	local caster = player:GetAssignedHero()	
	local ignoreUnits = { startUnit, caster }
	local units = Util:FindUnitsInRadius(startUnit:GetAbsOrigin(), maxDistance, DOTA_UNIT_TARGET_FLAG_INVULNERABLE)
	local secondaryStartUnits = {}
	for _, unit in pairs(units) do
		if table.indexOf(ignoreUnits, unit) == nil then
			table.insert(ignoreUnits, unit)
			table.insert(secondaryStartUnits, unit)
			effectFunc(unit)
			if attachAtStaff then
				Lightning:CreateParticleStartingAtStaff(player, startUnit, unit:GetAbsOrigin(), false)				
			else
				Lightning:CreateParticle(player, startPos, unit:GetAbsOrigin(), false)
			end
		end
	end
	for _, secondaryStartUnit in pairs(secondaryStartUnits) do
		local secondaryUnits = Util:FindUnitsInRadius(secondaryStartUnit:GetAbsOrigin(), maxDistance * 0.7, DOTA_UNIT_TARGET_FLAG_INVULNERABLE)
		for _, secondaryUnit in pairs(secondaryUnits) do
			if table.indexOf(ignoreUnits, secondaryUnit) == nil then
				table.insert(ignoreUnits, secondaryUnit)
				effectFunc(secondaryUnit)
				Lightning:CreateParticle(player, secondaryStartUnit:GetAbsOrigin(), secondaryUnit:GetAbsOrigin())
			end
		end
	end
end

function Lightning:EmitStrikeSound(caster)
	caster:EmitSound("LightningStrike1")
	caster:EmitSound("LightningStrike2")
	caster:EmitSound("LightningStrike3")
end

function Lightning:OnDirectedLightningThink(player)
	player.spellCast.thinkPeriod = 0.25
	
	local caster = player:GetAssignedHero()
	local forwardVec = caster:GetForwardVector()
	local lightningDistance = player.spellCast.lightning_Distance
	local startPos = caster:GetAbsOrigin() + forwardVec * 160
	local endPos = caster:GetAbsOrigin() + forwardVec * lightningDistance
	
	local units = Util:FindUnitsInLine(startPos, endPos, 150, DOTA_UNIT_TARGET_FLAG_INVULNERABLE)
	table.remove(units, table.indexOf(units, caster))
	local minDistance = math.huge
	local closestUnit = nil
	for _, unit in pairs(units) do
		local distance = (unit:GetAbsOrigin() - startPos):Length2D()
		if distance < minDistance then
			closestUnit = unit
			minDistance = distance
		end
	end
	if closestUnit == nil then
		local randomOffset = Vector(math.random(-50, 50), math.random(-50, 50), math.random(-100, 100))
		Lightning:CreateParticleStartingAtStaff(player, caster, endPos + randomOffset, true)
	else
		player.spellCast.lightning_EffectFunction(closestUnit)
		Lightning:CreateParticleStartingAtStaff(player, caster, closestUnit:GetAbsOrigin(), false)
		Lightning:ChainLightning(player, closestUnit, lightningDistance * 0.7)
	end

	player.spellCast.lightning_StrikesLeft = player.spellCast.lightning_StrikesLeft - 1
	if player.spellCast.lightning_StrikesLeft <= 0 then
		player.spellCast.thinkFunction = nil
	end

	Lightning:EmitStrikeSound(caster)
end

function Lightning:OnOmniLightningThink(player)
	player.spellCast.thinkPeriod = 0.25

	local caster = player:GetAssignedHero()
	local distance = player.spellCast.lightning_Distance
	local origin = caster:GetAbsOrigin()
	local units = Util:FindUnitsInRadius(origin, distance, DOTA_UNIT_TARGET_FLAG_INVULNERABLE)
	local startPos = origin + Vector(0, 0, 145) - (50 * caster:GetForwardVector():Normalized())
	if #units > 1 then
		Lightning:ChainLightning(player, caster, distance, startPos, true)
	else
		for i = 1, math.random(2, 3) do
			local randomEndPos = origin + RandomVector(1):Normalized() * distance
			Lightning:CreateParticleStartingAtStaff(player, caster, randomEndPos, true)
		end
	end

	player.spellCast.lightning_StrikesLeft = player.spellCast.lightning_StrikesLeft - 1
	if player.spellCast.lightning_StrikesLeft <= 0 then
		player.spellCast.thinkFunction = nil
	end

	Lightning:EmitStrikeSound(caster)
end