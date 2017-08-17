
if modifier_beam_cast == nil then
    modifier_beam_cast = class({})
end

function modifier_beam_cast:IsHidden() 
    return true
end

function modifier_beam_cast:OnCreated(kv)
    if IsServer() then
        self.target = nil
        self.power = 1
        self.spellCastTable = self:GetCaster():GetPlayerOwner().spellCast
        self.effectFunction = self.spellCastTable.beams_EffectFunction
        self:StartIntervalThink(0.25)
    end
end

function modifier_beam_cast:SetTarget(target)
    if IsServer() then
        self.target = target or self.target
    end
end

function modifier_beam_cast:ResetTarget()
    if IsServer() then
        self.target = nil
    end
end

function modifier_beam_cast:OnIntervalThink()
    if IsServer() then
        if self.target ~= nil then
            self.effectFunction(self.target, self.power)
            self.power = self.power + 1
        elseif self.power > 1 then
            self.power = self.power - 1
        end
        self.spellCastTable.beams_Power = self.power
    end
end