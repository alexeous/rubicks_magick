if SelfHeal == nil then
	SelfHeal = class({})
end

function SelfHeal:Precache(context)
	PrecacheResource("particle_folder", "particles/self_heal", context)	

	PrecacheResource("soundfile", "soundevents/rubicks_magick/self_heal.vsndevts", context)
end

function SelfHeal:PlayerConnected(player)
end


function SelfHeal:StartSelfHeal(player, power)
	local spellCastTable = {
		castType = CAST_TYPE_CONTINUOUS,
		isSelfCast = true,
		duration = 5.0,
		dontMoveWhileCasting = true,
		castingGesture = ACT_DOTA_CHANNEL_ABILITY_5,
		thinkFunction = function(player) SelfHeal:SelfHealThink(player) end,
		thinkPeriod = 0.5,
		endFunction = function(player) SelfHeal:SelfHealEnd(player) end,
		selfHeal_ExpMultiplier = 0.3 + power * 0.07,
		selfHeal_BaseHeal = 33 * power,
		selfHeal_LastTime = GameRules:GetGameTime(),
		selfHeal_HealCount = 0
	}
	local heroEntity = player:GetAssignedHero() 
	local particle = ParticleManager:CreateParticle("particles/self_heal/self_heal_start.vpcf", PATTACH_CUSTOMORIGIN, heroEntity)
	local pos = heroEntity:GetAbsOrigin()
	pos.z = pos.z + 80
	ParticleManager:SetParticleControl(particle, 0, pos)
	ParticleManager:SetParticleControlEnt(particle, 1, heroEntity, PATTACH_POINT_FOLLOW, "attach_attack3", heroEntity:GetAbsOrigin(), true)	
	ParticleManager:SetParticleControlEnt(particle, 2, heroEntity, PATTACH_POINT_FOLLOW, "attach_staff_ambient", heroEntity:GetAbsOrigin(), true)
	local y = (power >= 2) and 1 or 0
	local z = (power >= 3) and 1 or 0
	ParticleManager:SetParticleControl(particle, 5, Vector(1, y, z))
	spellCastTable.selfHeal_Particle = particle

	Spells:StartCasting(player, spellCastTable)
	heroEntity:EmitSound("SelfHealPrestart")
	heroEntity:EmitSound("SelfHealLoop")
end

function SelfHeal:SelfHealThink(player)
	SelfHeal:DoHeal(player)
	if player.spellCast.selfHeal_FirstHeal == nil then
		player.spellCast.selfHeal_FirstHeal = true
		player:GetAssignedHero():EmitSound("SelfHealStart")
	end
end

function SelfHeal:SelfHealEnd(player)
	if Spells:TimeElapsedSinceCast(player) >= 4.9 then
		SelfHeal:DoHeal(player)
	end
	ParticleManager:DestroyParticle(player.spellCast.selfHeal_Particle, false)
	player:GetAssignedHero():StopSound("SelfHealLoop")
end


function SelfHeal:DoHeal(player)
	local heroEntity = player:GetAssignedHero()
	local heal = player.spellCast.selfHeal_BaseHeal + math.exp(player.spellCast.selfHeal_ExpMultiplier * player.spellCast.selfHeal_HealCount)
	player.spellCast.selfHeal_HealCount = player.spellCast.selfHeal_HealCount + 1
	Spells:Heal(heroEntity, heroEntity, heal, false)
	heroEntity:EmitSound("SelfHealThink")
end