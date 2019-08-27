local ELEMENT_WALL_DURATION = 9
local EFFECT_APPLYING_INTERVAL = 0.5
local EFFECT_AREA_RADIUS = 65

if modifier_element_wall == nil then
	modifier_element_wall = class({})
end

function modifier_element_wall:IsPermanent()
	return false
end

function modifier_element_wall:OnCreated(kv)
	if IsServer() then
		self.element = kv.element
		self.effectFunc = self:GetParent().effectFunc
		self.startTime = GameRules:GetGameTime()
		self:CreateParticle()
		self:StartSounds()
		self:StartIntervalThink(EFFECT_APPLYING_INTERVAL)
	end
end

function modifier_element_wall:CreateParticle()
	local wall = self:GetParent()
	self.particle = ParticleManager:CreateParticle("particles/stone_wall/stone_wall.vpcf", PATTACH_ABSORIGIN, wall)
end

function modifier_element_wall:StartSounds()
	local wall = self:GetParent()
	
	wall.sounds = {}
	for _, sound in pairs(wall.sounds) do
		wall:EmitSound(sound)
	end
end

function modifier_element_wall:StopSounds()
	for _, sound in pairs(self:GetParent().sounds) do
		wall:StopSound(sound)
	end
end

function modifier_element_wall:OnIntervalThink()
	if IsServer() then
		local wall = self:GetParent()

		local expired = GameRules:GetGameTime() - self.startTime > ELEMENT_WALL_DURATION
		if expired then
			wall:Kill(nil, nil)
			return
		end
		
		self.applyingNumber = (self.applyingNumber or 0) + 1
		local targets = Util:FindUnitsInRadius(wall:GetAbsOrigin(), EFFECT_AREA_RADIUS)
		for _, target in pairs(targets) do
			if target ~= wall then
				self.effectFunc(wall, target, self.applyingNumber)
			end
		end
	end
end

function modifier_element_wall:OnDestroy()
	if IsServer() then
		ParticleManager:DestroyParticle(self.particle, false)
		self:StopSounds()
		--self:GetParent():EmitSound("DestroyStoneWall1")
		self:StartIntervalThink(-1)
	end
end