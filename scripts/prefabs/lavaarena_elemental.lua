local brain = require("brains/elementalbrain")

local assets = {
    Asset("ANIM", "anim/lavaarena_elemental_basic.zip"),
}

local prefabs = {
    "fireball_projectile",
    "fireball_cast_fx",
}

local function FindTarget(inst)
    return FindEntity(inst, 8, function(guy)
        return inst.components.combat:CanTarget(guy) and inst.components.combat:CanAttack(guy) and guy:IsValid() and guy.components.combat ~= nil
    end, nil, TUNING.MOD_LAVAARENA.NOTTAGS, TUNING.MOD_LAVAARENA.TAGS)
end

local function retargetfn(inst)
    return FindTarget(inst)
end

local function shouldkeeptarget(inst, target)
    return true
end

local function fn()
    local inst = CreateEntity()
    
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddPhysics()
    inst.entity:AddNetwork()
    
    inst.DynamicShadow:SetSize(1.1, .7)
    inst.canattack = false
    
    inst.Transform:SetFourFaced()
    
    inst.AnimState:SetBank("lavaarena_elemental_basic")
    inst.AnimState:SetBuild("lavaarena_elemental_basic")
    inst.AnimState:Hide("head_spikes")
    inst.AnimState:PlayAnimation("idle", true)
    
    inst:AddTag("character")
    inst:AddTag("scarytoprey")
    inst:AddTag("elemental")
    inst:AddTag("companion")
    inst:AddTag("flying")
    inst:AddTag("notraptrigger")
    inst:AddTag("NOCLICK")
    
    inst:SetPhysicsRadiusOverride(.65)
    inst.Physics:SetMass(450)
    inst.Physics:SetFriction(10)
    inst.Physics:SetDamping(5)
    inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.WORLD)
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)
    inst.Physics:CollidesWith(COLLISION.GIANTS)
    inst.Physics:SetCapsule(inst.physicsradiusoverride, 1)
    
    inst.entity:SetPristine()
    
    if not TheWorld.ismastersim then
        return inst
    end
    
    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.runspeed = 0
    inst:SetStateGraph("SGelemental")
    
    inst:SetBrain(brain)
    
    local item = SpawnPrefab("fireballstaff")
    inst:AddComponent("inventory")
    inst.components.inventory:DisableDropOnDeath()
    inst.components.inventory:GiveItem(item)
    inst.components.inventory:SetActiveItem(item)
    inst.components.inventory:EquipActiveItem()
    
    inst:AddComponent("combat")
    inst.components.combat:SetAttackPeriod(0.5)
    inst.components.combat:SetRange(8)
    inst.components.combat:SetRetargetFunction(1, retargetfn)
    inst.components.combat:SetKeepTargetFunction(shouldkeeptarget)
    inst.components.combat:SetDefaultDamage(0)
    
    inst:AddComponent("health")
    inst.components.health:SetInvincible(true)
    
    return inst
end

return Prefab("lavaarena_elemental", fn, assets, prefabs)
