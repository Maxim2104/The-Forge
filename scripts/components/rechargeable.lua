local Rechargeable = Class(function(self, inst)
	self.inst         = inst
	self.bonus        = 1.0 -- Percent
	self.rechargetime = 0
	self._remaining   = 0
	self.inst._task   = nil
end)

function Rechargeable:GetPercent()
	return (self.rechargetime - self._remaining) / self.rechargetime
end

-- bonus param must be in [0, 1] range
function Rechargeable:SetBonus(bonus)
	self.bonus = 1.0 + bonus
end

function Rechargeable:GetRechargeTime()
	return self.rechargetime
end

function Rechargeable:SetRechargeTime(rechargetime)
	self.rechargetime = rechargetime
end

local function Update(inst)
	if inst.components.rechargeable._remaining > 0 then
		inst.components.rechargeable._remaining = inst.components.rechargeable._remaining - (1 * inst.components.rechargeable.bonus)
	else
		inst._task:Cancel()
		inst.components.rechargeable._remaining = 0
		inst.components.aoetargeting:SetEnabled(true)
	end
end

function Rechargeable:Reset()
	self._remaining = self.rechargetime
	self.inst._task = self.inst:DoPeriodicTask(1, Update)
end

return Rechargeable