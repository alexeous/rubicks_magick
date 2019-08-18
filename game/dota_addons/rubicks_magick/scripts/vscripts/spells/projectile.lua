require("libraries/timers")
--local FALL_G_CONST = 2 * START_HEIGHT / (FLY_TIME * FLY_TIME)
local PROJECTILE_THINK_PERIOD = 0.018

if Projectile == nil then
    Projectile = class({})
end

function Projectile:Init()
    Projectile.projectileList = {}
	GameRules:GetGameModeEntity():SetThink(Dynamic_Wrap(Projectile, "OnThink"), "ProjectileThink", PROJECTILE_THINK_PERIOD)
end

function Projectile:Create(infoTable)
    local caster = infoTable.caster
    local start = infoTable.start
    
    local projectile = Util:CreateDummy(start, caster)
    projectile.caster = caster
    projectile.collisionRadius = infoTable.collisionRadius
    projectile.direction = infoTable.direction:Normalized()
    projectile.distance = infoTable.distance
    projectile.flightDuration = infoTable.flightDuration
    projectile.destroyDelay = infoTable.destroyDelay or 0
    projectile.particleDestroyDelay = infoTable.particleDestroyDelay or 0

    projectile.onUnitHitCallback = infoTable.onUnitHitCallback
    projectile.onDeathCallback = infoTable.onDeathCallback

    if infoTable.createParticleCallback ~= nil then
        projectile.particle = infoTable.createParticleCallback(projectile)
    end
    
    local startHeight = (start - GetGroundPosition(start, nil)).z
    projectile.gravityConst = 2 * startHeight / (projectile.flightDuration * projectile.flightDuration)
    projectile.velocity = projectile.direction * (projectile.distance / projectile.flightDuration)

    table.insert(Projectile.projectileList, projectile)
    return projectile
end

function Projectile:OnThink()
    local currentTime = GameRules:GetGameTime()
    if Projectile.lastThinkTime == nil then
        Projectile.lastThinkTime = currentTime
    end
    local deltaTime = currentTime - Projectile.lastThinkTime
    Projectile.lastThinkTime = currentTime

    for k, projectile in pairs(Projectile.projectileList) do
        local free, unitsTouched = Projectile:OnProjectileThink(projectile, deltaTime)
        if not free then
            Projectile:Destroy(k, projectile, unitsTouched)
        end
    end
    return PROJECTILE_THINK_PERIOD
end

function Projectile:OnProjectileThink(projectile, deltaTime)
    local origin = projectile:GetAbsOrigin()
	if origin.z <= GetGroundHeight(origin, projectile) then
		return false
    end

	projectile.time = (projectile.time or 0) + deltaTime
    if projectile.time <= deltaTime then
        -- We want to skip the first think to let the rock just even draw first before moving away from start pos
		return true
    end
    
    projectile.velocity.z = projectile.velocity.z - projectile.gravityConst * deltaTime
    local moveStep = projectile.velocity * deltaTime

    local oldOrigin = origin
	origin = origin + moveStep
	--origin.z = rockDummy.startZ - ROCK_FALL_G_CONST * time * time / 2
    projectile:SetAbsOrigin(origin)
    
    local caster = projectile.caster
	local trees = GridNav:GetAllTreesAroundPoint(origin, projectile.collisionRadius, true)
	if next(trees) ~= nil then
		return false
    end
    
    local unitsTouched = Util:FindUnitsInLine(oldOrigin, origin, projectile.collisionRadius, DOTA_UNIT_TARGET_FLAG_INVULNERABLE)
    for _, unit in pairs(unitsTouched) do
        if unit ~= projectile and unit ~= caster then
            if projectile.onUnitHitCallback == nil or not projectile.onUnitHitCallback(projectile, unit) then
                local newOriginAtUnit = Util:ProjectPointOnLine(unit:GetAbsOrigin(), oldOrigin, origin)
                projectile:SetAbsOrigin(newOriginAtUnit)
                return false, unitsTouched
            end
        end
    end
    return true
end

function Projectile:Destroy(listKey, projectile, unitsTouched)
    Projectile.projectileList[listKey] = nil
    unitsTouched = unitsTouched or {}
    table.removeItem(unitsTouched, projectile.caster)

    projectile.onDeathCallback(projectile, unitsTouched)
    if projectile.particle ~= nil then
        Timers:CreateTimer(projectile.particleDestroyDelay, function() 
            ParticleManager:DestroyParticle(projectile.particle, false) 
        end)
    end
    Timers:CreateTimer(projectile.destroyDelay, function() 
        projectile:Destroy() 
    end)
end