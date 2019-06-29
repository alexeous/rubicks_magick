require("util")

if CameraSlider == nil then
    CameraSlider = class({})
end

CAMERA_SLIDE_THINK_PERIOD = 0.01
CAMERA_SLIDE_LERP_FACTOR = CAMERA_SLIDE_THINK_PERIOD * 16.0
CAMERA_SLIDE_MAX_DISTANCE = 1000

function CameraSlider:Init()
    GameRules:GetGameModeEntity():SetThink(Dynamic_Wrap(CameraSlider, "OnCameraSlideThink"), "CameraSlideThink", 2)
    CustomGameEventManager:RegisterListener("rm_mouse_cycle", Dynamic_Wrap(CameraSlider, "OnMouseCycle"))
end

function CameraSlider:OnCameraSlideThink()
    return nil
   --[[ for playerID = 0, DOTA_MAX_PLAYERS - 1 do
        local player = PlayerResource:GetPlayer(playerID)
		if player ~= nil and player.cameraSliderDummy ~= nil then
            local unit = player.cameraSliderDummy:GetOwner()
            local unitPosition = unit:GetAbsOrigin()
            local dummyPosition = player.cameraSliderDummy:GetAbsOrigin()
            local targetPosition = player.cameraSliderDummy.targetPosition + Vector(0, -240, 0)
            local unitToTarget = targetPosition - unitPosition
            local unitToTargetLen = unitToTarget:Length2D()
            if unitToTargetLen > CAMERA_SLIDE_MAX_DISTANCE then
                targetPosition = unitPosition + unitToTarget:Normalized() * CAMERA_SLIDE_MAX_DISTANCE
                unitToTargetLen = CAMERA_SLIDE_MAX_DISTANCE
            end
            targetPosition = (targetPosition * 3 + unitPosition * 2) / 5
            targetPosition.z = unitPosition.z
            local lerpFactor = CAMERA_SLIDE_LERP_FACTOR-- * math.pow(unitToTargetLen / CAMERA_SLIDE_MAX_DISTANCE, 2)
            dummyPosition = dummyPosition + (targetPosition - dummyPosition) * CAMERA_SLIDE_LERP_FACTOR
            player.cameraSliderDummy:SetAbsOrigin(dummyPosition)
            PlayerResource:SetCameraTarget(playerID, player.cameraSliderDummy)
        end
    end
    return CAMERA_SLIDE_THINK_PERIOD]]
end

function CameraSlider:OnMouseCycle(keys)
    local player = PlayerResource:GetPlayer(keys.playerID)
    if player.cameraSliderDummy == nil then
        local heroEntity = player:GetAssignedHero()
        if heroEntity == nil then
            return
        end
        CameraSlider:Create(player, heroEntity)
    end
    player.cameraSliderDummy.targetPosition = Vector(keys.worldX, keys.worldY, keys.worldZ)
end

function CameraSlider:Create(player, target)
    player.cameraSliderDummy = Util:CreateDummy(target:GetAbsOrigin(), target)
end

function CameraSlider:Attach(player, target)
    if player.cameraSliderDummy == nil then
        CameraSlider:Create(player, target)
    end
    player.cameraSliderDummy:SetOwner(target)
end