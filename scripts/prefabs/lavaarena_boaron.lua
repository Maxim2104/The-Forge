local assets =
{
    Asset("ANIM", "anim/lavaarena_boaron_basic.zip"),
    Asset("ANIM", "anim/fossilized.zip"),
}

SetSharedLootTable("lavaarena_boaron", {})

local targetDist = TUNING.LAVAARENA_BOARON.TARGET_DIST
local keepDistSq = TUNING.LAVAARENA_BOARON.KEEPDIST * TUNING.LAVAARENA_BOARON.KEEPDIST
local shareDist = TUNING.LAVAARENA_BOARON.SHARE_DIST

local function OnNewTarget(inst, data)
    if inst.components.sleeper:IsAsleep() then
        inst.components.sleeper:WakeUp()
    end
end

local function Retarget(inst)
    local musttags = {}
    local notags = {"lavaarena_enemy", "smallcreature", "FX", "NOCLICK", "INLIMBO"}
    return FindEntity(inst, targetDist, function(guy)
        return inst.components.combat:CanTarget(guy)
    end, musttags, notags)
end

local function KeepTarget(inst, target)
    return inst.components.combat:CanTarget(target) and inst:GetDistanceSqToInst(target) <= (keepDistSq)
end

local function OnAttacked(inst, data)
    if data.attacker == nil
        or data.attacker.components.combat == nil
        or data.attacker.components.health == nil
        then
        return
    end
    inst.components.combat:SetTarget(data.attacker)
    inst.components.combat:ShareTarget(data.attacker, shareDist, function(dude)
    return dude:HasTag("piggy") and not dude.components.health:IsDead() end, 2)
end

local function OnAttackOther(inst, data)
    inst.components.combat:ShareTarget(data.attacker, shareDist, function(dude)
    return dude:HasTag("piggy") and not dude.components.health:IsDead() end, 2)
end

local function GetDebugString(inst)
    return string.format("can charge in: %i", GetTime() - inst.chargeLastTime)
end

local function fn()
    local inst = CreateEntity()
    
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddPhysics()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    inst.entity:AddDynamicShadow()
    
    inst.DynamicShadow:SetSize(1.75, .75)
    inst.Transform:SetSixFaced()
    inst.Transform:SetScale(.8, .8, .8)
    
    MakeCharacterPhysics(inst, 50, .5)
    
    inst.AnimState:SetBank("boaron")
    inst.AnimState:SetBuild("lavaarena_boaron_basic")
    inst.AnimState:PlayAnimation("idle_loop", true)
    
    inst.AnimState:AddOverrideBuild("fossilized")
    
    inst:AddTag("scarytoprey")
    inst:AddTag("hostile")
    inst:AddTag("fossilizable")
    
    inst.entity:SetPristine()
    
    if not TheWorld.ismastersim then
        return inst
    end
    
    inst:AddComponent("fossilizable")
    inst.components.fossilizable:SetShatterFXLevel(1)
    inst.components.fossilizable:AddShatterFX("shatter", Vector3(0, 0, 0), "bod")
    
    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.runspeed = TUNING.LAVAARENA_BOARON.RUNSPEED
    
    inst:SetStateGraph("SGlavaarena_boaron")
    inst:SetBrain(require "brains/lavaarena_boaronbrain")
    
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.LAVAARENA_BOARON.HEALTH)
    
    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.LAVAARENA_BOARON.DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.LAVAARENA_BOARON.ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(3, Retarget)
    inst.components.combat:SetKeepTargetFunction(KeepTarget)
    inst.components.combat:SetRange(TUNING.LAVAARENA_BOARON.RANGE)
    
    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("lavaarena_boaron")
    
    inst:AddComponent("eater")
    inst.components.eater:SetDiet({FOODTYPE.MEAT}, {FOODTYPE.MEAT})
    inst.components.eater:SetCanEatHorrible()
    inst.components.eater:SetCanEatRaw()
    inst.components.eater.strongstomach = true -- can eat monster meat!
    
    inst:AddComponent("inspectable")
    
    inst:AddComponent("sleeper")
    
    MakeMediumFreezableCharacter(inst, "body")
    MakeMediumBurnableCharacter(inst, "body")
    
    inst.chargeLastTime = GetTime()
    
    inst:ListenForEvent("attacked", OnAttacked)
    --inst:ListenForEvent("onattackother", OnAttackOther)
    inst:ListenForEvent("newcombattarget", OnNewTarget)

    inst.debugstringfn = GetDebugString
    
    return inst
end

return Prefab("boaron", fn, assets, prefabs)
