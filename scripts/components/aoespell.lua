local Aoespell = Class(function(self, inst)
    self.inst = inst
    self._changCD = 30
    self.period = 0
    self.oncastfn = nil
    self.default_damage = 20
    self._cdjg = self._changCD or 30
end)

function Aoespell:SetOnCastFn(fn)
    self.oncastfn = fn
end

function Aoespell:SetPeriod(d)
    self._changCD = d
end

function Aoespell:CanCast(doer, pos)
    return true
end

function Aoespell:SetAOE(num)
    self.default_damage = num
end

function Aoespell:GetAOE()
    return self.default_damage or 20
end

function Aoespell:GetFJ()
    local a = {cd = 0, fj = 0, zs = 0}
    local owner = self.inst.components.inventoryitem and self.inst.components.inventoryitem:GetGrandOwner()
    if owner then
        if owner.components.inventory then
            for k, v in pairs(owner.components.inventory.equipslots) do
                local eq = v
                if eq then
                    if eq._Cooling then
                        a.cd = a.cd + eq._Cooling
                    end
                    if eq._Gain then
                        a.fj = a.fj + eq._Gain
                    end
                    if eq._injury then
                        a.zs = a.zs + eq._injury
                    end
                end
            end
        end
        if type(owner._Sxing) == "table" and next(owner._Sxing) ~= nil then
            local v = owner._Sxing
            if v._Cooling then
                a.cd = a.cd + v._Cooling
            end
            if v._Gain then
                a.fj = a.fj + v._Gain
            end
            if v._injury then
                a.zs = a.zs + v._injury
            end
        end
    end
    return a
end

function Aoespell:CastSpell(doer, pos)
    if pos ~= nil and doer then
        local t = self:GetFJ()
        if self.oncastfn ~= nil then
            self.oncastfn(self.inst, doer, pos, t)
        end
        if self.inst.components.aoetargeting then
            self.inst.components.aoetargeting:SetEnabled(false)
        end
        local bv = self._changCD / (self._changCD * (1 + t.cd))
        self._cdjg = math.max(1, self._changCD * bv)
        self.period = 0
        self.inst:StartUpdatingComponent(self)
    end
end

function Aoespell:OnUpdate(dt)
    if self.period < self._cdjg then
        self.period = math.max(0, self.period + dt)
        self.inst:PushEvent("rechargechange", {percent = (self.period / self._cdjg)})
    else
        self.period = 0
        self.inst:PushEvent("rechargechange", {percent = 1})
        if self.inst.components.aoetargeting then
            self.inst.components.aoetargeting:SetEnabled(true)
        end
        self._cdjg = self._changCD or 30
        self.inst:StopUpdatingComponent(self)
    end
end

---------------------------------------
-- local cdset = {
--     ["spear_gungnir"] = {cd = 30, damage = 20, aoe = 45},
--     ["spear_lance"] = {cd = 50, damage = 30, aoe = 175},
--     ["blowdart_lava2"] = {cd = 30, damage = 25, aoe = 60},
--     ["hammer_mjolnir"] = {cd = 20, damage = 20, aoe = 45},
--     ["book_fossil"] = {cd = 30, damage = 15, aoe = 0},
--     ["book_elemental"] = {cd = 40, damage = 15, aoe = 0},
--     ["fireballstaff"] = {cd = 50, damage = 25, aoe = 210},
--     ["healingstaff"] = {cd = 40, damage = 10, aoe = 0.2},
--     ["blowdart_lava"] = {cd = 30, damage = 20, aoe = 20},
-- }

-- for k, v in pairs(cdset) do
--     AddPrefabPostInit(k, function(inst)
--         if inst.components.aoespell then
--             inst.components.aoespell:SetPeriod(v.cd or 60)
--             --inst.components.aoespell:SetPeriod(1)
--             inst.components.aoespell:SetAOE(v.aoe or 0)
--         end
--         if inst.components.weapon then
--             inst.components.weapon:SetDamage(v.damage or 20)
--         end
--     end)
-- end

return Aoespell