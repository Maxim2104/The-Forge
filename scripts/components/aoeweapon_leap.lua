-- Unofficial AOEWeapon_Leap component
local AOEWeapon_Leap = Class(function(self, inst)
	self.inst = inst
end)

function AOEWeapon_Leap:DoLeap(jumper, startpos, targetpos)
	jumper.Physics:Teleport(targetpos.x, 0, targetpos.z)
	--TODO
end

return AOEWeapon_Leap