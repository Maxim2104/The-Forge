require "behaviours/chaseandattack"
require "behaviours/runaway"
require "behaviours/wander"
require "behaviours/doaction"
require "behaviours/attackwall"
require "behaviours/panic"
require "behaviours/minperiod"
require "behaviours/standstill"
require "giantutils"

local Boarrior = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local SEE_DIST = 30
local CHASE_DIST = 32
local CHASE_TIME = 20
local arsq = TUNING.LAVAARENA_BOARRIOR.ATTACK_RANGE * TUNING.LAVAARENA_BOARRIOR.ATTACK_RANGE
local wwRadius = TUNING.LAVAARENA_BOARRIOR.WHIRLWINDRADIUS
local wwTargetNeed = TUNING.LAVAARENA_BOARRIOR.WHIRLWINDNEEDTARGETS
local wwcd = TUNING.LAVAARENA_BOARRIOR.WHIRLWINDCD
local gbcd = TUNING.LAVAARENA_BOARRIOR.GROUNDBURNCD

local function GetHomePos(inst)
    local home = GetHome(inst)
    return home ~= nil and home:GetPosition() or nil
end

local function GetWanderPoint(inst)
    local target = inst.components.knownlocations:GetLocation("spawnpoint")
    return target ~= nil and target:GetPosition() or nil
end

local function ShouldGroundBurn(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	return GetTime() - inst.lastGroundBurn > gbcd
		and #FindPlayersInRangeSq(x, y, z, 400, true) ~= 0
end

local function ShouldWhirlWind(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	return GetTime() - inst.lastWirlWind > wwcd
		and #TheSim:FindEntities(x, y, z, wwRadius, { "_combat" }, { "INLIMBO" }) > wwTargetNeed
end

local function ShouldPreformCombo(inst)
	return inst.components.combat.target
		and inst:GetDistanceSqToInst(inst.components.combat.target) <= arsq + 4
		and GetTime() - inst.lastCombo > inst:CalculateComboCD()
end

local function ShouldGroundSlam(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	return GetTime() - inst.lastGroundSlam > inst:CalculateGroundSlamCD()
		and IsAnyPlayerInRange(x, y, z, 12, true) 
end

function Boarrior:OnStart()
    
    local root = PriorityNode(
    {
		--WhileNode(function() return self.inst.components.health.takingfiredamage end, "OnFire", Panic(self.inst) ),
		--IfNode(function() return self.inst.engaged end, "Is Engaged", {
		--I have no idea, whith node to use to evade multycheck for self.inst.engaged 
		WhileNode(function() return self.inst.engaged and ShouldGroundBurn(self.inst) end, "Ground Burn", 
			ActionNode(function() self.inst:PushEvent("meteorshower") end)
		),
		WhileNode(function() return self.inst.engaged and ShouldWhirlWind(self.inst) end, "Whirlwind", 
			ActionNode(function() self.inst:PushEvent("whirlwind") end)
		),
		WhileNode(function() return self.inst.engaged and ShouldPreformCombo(self.inst) end, "Combo Attack", 
			ActionNode(function() self.inst:PushEvent("comboattack", self.inst.components.combat.target) end)
		),
		WhileNode(function() return self.inst.engaged and ShouldGroundSlam(self.inst) end, "Ground Slam", 
			ActionNode(function() self.inst:PushEvent("groundslam") end)
		),
		ChaseAndAttack(self.inst, CHASE_TIME, CHASE_DIST),
		--}),
		
		ParallelNode{
            SequenceNode{
                WaitNode(10),
                ActionNode(function() self.inst:SetEvaded() end),
            },
            Wander(self.inst, GetWanderPoint, 5),
        },

		StandStill(self.inst, function() return true end),
    }, .25)
    
    self.bt = BT(self.inst, root)
    
end

return Boarrior
