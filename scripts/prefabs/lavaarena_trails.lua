local assets =
{
    Asset("ANIM", "anim/lavaarena_trails_basic.zip"),
    Asset("ANIM", "anim/fossilized.zip"),
}

local prefabs =
{
    "fossilizing_fx",
    "fossilized_break_fx",
    "lavaarena_creature_teleport_small_fx",
}

SetSharedLootTable( "lavaarena_trails", {})

local targetDist = TUNING.LAVAARENA_TRAILS.TARGET_DIST
local keepDistSq = TUNING.LAVAARENA_TRAILS.KEEP_TARGET_DIST * TUNING.LAVAARENA_TRAILS.KEEP_TARGET_DIST
local slamRadius = TUNING.LAVAARENA_TRAILS.SLAM_RADIUS
local slamDamage = TUNING.LAVAARENA_TRAILS.SLAM_DAMAGE

local function OnNewTarget(inst, data)
	if inst.components.sleeper:IsAsleep() then
		inst.components.sleeper:WakeUp()
	end
end

local function Retarget(inst)
    local musttags = {}
    local notags = {"lavaarena_enemy", "smallcreature", "FX", "NOCLICK", "INLIMBO"}
    return FindEntity(inst, targetDist, function(guy)
        return  inst.components.combat:CanTarget(guy)
    end, musttags, notags)
end

local function KeepTarget(inst, target)
	return inst.components.combat:CanTarget(target) and inst:GetDistanceSqToInst(target) <= keepDistSq
end

local function OnAttacked(inst, data)
    if data.attacker == nil and inst.components.combat:CanTarget(data.attacker) then 
        return 
    end

	inst.components.combat:SetTarget(data.attacker)
end

local function OnAttackOther(inst, data)

end

local function SlamAttack(inst)
    local musttags = {}
    local notags = {"lavaarena_enemy", "smallcreature", "FX", "NOCLICK", "INLIMBO"}
    local x, y, z = inst.Transform:GetWorldPosition()
    for _, v in pairs(TheSim:FindEntities(x, y, z, slamRadius, musttags, notags)) do
        if v ~= inst 
            and v:IsValid() 
            and v.entity:IsVisible() 
            and v.components.combat ~= nil 
        then
            v.components.combat:GetAttacked(inst, slamDamage)
            if v:HasTag("player") then
                local knockback_proof = false
                if v.components.inventory then
                    local body_armor = v.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
                    if body_armor and body_armor:HasTag("heavyarmor") then
                        knockback_proof = true
                    end
                end
                if not knockback_proof then
                    v.sg:GoToState("knockback", {knocker = inst, radius = 5})
                end
            end 
        end
    end
    inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/turtillus/grunt")
    inst.components.combat.laststartattacktime = GetTime()
    inst.lastTimeSlam = GetTime()
end

local function GetDebugString(inst)
    return string.format("last slam %i", GetTime() - inst.lastTimeSlam)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()
    inst.entity:AddPhysics()

    inst.DynamicShadow:SetSize(3.25, 1.75)
    inst.Transform:SetFourFaced()
    inst.Transform:SetScale(1.2, 1.2, 1.2)


    MakeCharacterPhysics(inst, 500, 1.75)

    inst.AnimState:SetBank("trails")
    inst.AnimState:SetBuild("lavaarena_trails_basic")
    inst.AnimState:PlayAnimation("idle_loop")

    inst.AnimState:AddOverrideBuild("fossilized")

    inst:AddTag("scarytoprey")
    inst:AddTag("largecreature")
    inst:AddTag("fossilizable")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("fossilizable")

    inst:AddComponent("locomotor")
	inst.components.locomotor.runspeed = TUNING.LAVAARENA_TRAILS.SPEED

	inst:SetStateGraph("SGlavaarena_trails")
	inst:SetBrain(require "brains/lavaarena_trailsbrain")

	inst:AddComponent("knownlocations")

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(TUNING.LAVAARENA_TRAILS.HEALTH)

	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(TUNING.LAVAARENA_TRAILS.DAMAGE)
	inst.components.combat:SetAttackPeriod(TUNING.LAVAARENA_TRAILS.ATTACK_PERIOD)
	inst.components.combat:SetRetargetFunction(5, Retarget)
	inst.components.combat:SetRange(TUNING.LAVAARENA_TRAILS.ATTACK_RANGE)
	inst.components.combat.battlecryenabled = true

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable("lavaarena_trails")

	inst:AddComponent("inspectable")
    inst:AddComponent("inventory")
    
    inst:AddComponent("eater")
    inst.components.eater:SetDiet({ FOODGROUP.OMNI }, { FOODGROUP.OMNI })
    inst.components.eater:SetCanEatHorrible()
    inst.components.eater:SetCanEatRaw()
    inst.components.eater.strongstomach = true

    inst:AddComponent("sleeper")
    
    MakeMediumFreezableCharacter(inst, "body")
    MakeMediumBurnableCharacter(inst, "body")

    inst.lastTimeSlam = GetTime()

    inst.SlamAttack = SlamAttack

    inst:ListenForEvent("attacked", OnAttacked)

    inst.debugstringfn = GetDebugString

    return inst
end

return Prefab("trails", fn, assets, prefabs)
