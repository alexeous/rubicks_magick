
if modifier_beam_target == nil then
    modifier_beam_target = class({})
end

function modifier_beam_target:IsHidden() 
    return true
end

function modifier_beam_target:OnCreated(kv)
    if IsServer() then
        self.effectFunction = kv.effectFunction
        self:StartIntervalThink(0.43)
    end
end

function modifier_beam_target:OnIntervalThink()
    if IsServer() then
        self.effectFunction(self:GetParent()
    end
end