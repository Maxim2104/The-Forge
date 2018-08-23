require "behaviours/faceentity"
require "behaviours/doaction"

local ElementalBrain = Class(Brain, function(self, inst)
	Brain._ctor(self, inst)
end)

local SEE_DIST = 8

local function AttackAction(inst)
	local target = FindEntity(inst, SEE_DIST, function(guy)
		return inst.components.combat:CanTarget(guy) and inst.components.combat:CanAttack(guy) and guy:IsValid() and guy.components.combat ~= nil
	end, nil, {"follower", "playerghost", "player"}, TUNING.MOD_LAVAARENA.TAGS)
	if target then
		inst.components.combat:SetTarget(target)
    return BufferedAction(inst, target, ACTIONS.ATTACK)
  end
end

local function GetTarget(inst)
  return inst.components.combat ~= nil and inst.components.combat.target ~= nil and inst.components.combat.target or nil
end

function ElementalBrain:OnStart()
	local root = PriorityNode({
		DoAction(self.inst, AttackAction, "attack", false),
		FaceEntity(self.inst, GetTarget, GetTarget),
	}, .25)
	
	self.bt = BT(self.inst, root)
end

return ElementalBrain