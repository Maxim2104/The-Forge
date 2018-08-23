local function SetCooldownBonus(inst, owner)
    local armor = owner.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
    local head = owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
    local hand = owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HAND)

    local bonus = (armor and armor.cooldownbonus or 0) + (head and head.cooldownbonus or 0)
    if hand and hand.components.rechargeable then
        hand.components.rechargeable:SetBonus(bonus)
    end
end

local assets = {
    Asset("ANIM", "anim/hammer_mjolnir.zip"),
    Asset("ANIM", "anim/swap_hammer_mjolnir.zip"),
}

local assets_crackle = {
    Asset("ANIM", "anim/lavaarena_hammer_attack_fx.zip"),
}

local prefabs = {
    "hammer_mjolnir_crackle",
    "hammer_mjolnir_cracklehit",
    "reticuleaoe",
    "reticuleaoeping",
    "reticuleaoehostiletarget",
    "weaponsparks",
    "sunderarmordebuff",
}

local prefabs_crackle = {
    "hammer_mjolnir_cracklebase",
}

local function oncastfn(inst, doer, item, pos)
    doer:PushEvent("combat_leap", {weapon = inst, targetpos = pos})
    if inst == nil or doer == nil or pos == nil then
        return false
    end
    
    local notags = {"playerghost", "INLIMBO", "NOCLICK", "FX"}
    local damage = 20
    for _, v in pairs(TheSim:FindEntities(pos.x, pos.y, pos.z, 6, {}, notags)) do
        if v ~= doer and v:IsValid() and v.entity:IsVisible() and not v:IsInLimbo() then
            if v.components.combat ~= nil then
                if not doer.components.combat:IsTargetFriendly(v) then
                    doer.components.combat:AttackWithMods(v, damage, item)
                end
            elseif v.Physics ~= nil and v.components.inventoryitem ~= nil then
                local xv, yv, zv = v.Transform:GetWorldPosition()
                v.Physics:Teleport(xv, 0.5, zv)
                local vec = Vector3(xv - pos.x, yv - pos.y, zv - pos.z):Normalize()
            end
        end
    end
end

local function Jump(inst, doer, pos, data)
    local damage = inst.components.aoespell:GetAOE()
    local bv = data and data.zs or 0
    local val = damage + (damage * bv)
    doer.sg:GoToState("combat_leap", {
        data = {
            targetpos = pos,
            weapon = inst,
        }})
    doer:DoTaskInTime(0.5, function()
        local ens = TheSim:FindEntities(pos.x, 0, pos.z, 5, {"_combat", "_health"}, {"player", "FX", "NOCLICK", "DECOR", "INLIMBO"})
        for k, v in pairs(ens) do
            if not v.components.health:IsDead() then
                local fx = SpawnPrefab("hammer_mjolnir_cracklehit")
                fx.Transform:SetPosition(v.Transform:GetWorldPosition())
                fx:ListenForEvent("animover", fx.Remove)
                if v:HasTag("largecreature") then
                    fx.Transform:SetScale(2, 2, 2)
                end
                v.components.combat:GetAttacked(doer, val, inst, "electric", "AOE")
                v.components.combat:BlankOutAttacks(v.components.combat.min_attack_period or 1.5)
                v.components.combat:SetTarget(doer)
            end
        end
        local fx = SpawnPrefab("hammer_mjolnir_crackle")
        fx.Transform:SetPosition(pos:Get())
        fx:ListenForEvent("animover", fx.Remove)
        fx:DoTaskInTime(2, fx.Remove)
        local fx1 = SpawnPrefab("hammer_mjolnir_cracklebase")
        fx1.Transform:SetPosition(pos:Get())
        fx1:ListenForEvent("animover", fx1.Remove)
        fx1:DoTaskInTime(2, fx.Remove)
    end)
    
end
    
local function ReticuleTargetFn()
    local player = ThePlayer
    local ground = TheWorld.Map
    local pos = Vector3()
    --Cast range is 8, leave room for error
    --4 is the aoe range
    for r = 7, 0, -.25 do
        pos.x, pos.y, pos.z = player.entity:LocalToWorldSpace(r, 0, 0)
        if ground:IsPassableAtPoint(pos:Get()) and not ground:IsGroundTargetBlocked(pos) then
            return pos
        end
    end
    return pos
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_hammer_mjolnir", "swap_hammer_mjolnir")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
    SetCooldownBonus(inst, owner)
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_object")
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    SetCooldownBonus(inst, owner)
end

local function onattack(inst, attacker, target)
    if target.components.sleeper and target.components.sleeper:IsAsleep() then
        target.components.sleeper:WakeUp()
    end
    
    if target.components.combat then
        target.components.combat:SuggestTarget(attacker)
    end
end

local function fn()
    local inst = CreateEntity()
    
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    
    MakeInventoryPhysics(inst)
    
    inst.AnimState:SetBank("hammer_mjolnir")
    inst.AnimState:SetBuild("hammer_mjolnir")
    inst.AnimState:PlayAnimation("idle")
    
    inst:AddTag("melee")
    inst:AddTag("hammer")
    inst:AddTag("aoeweapon_leap")
    inst:AddTag("rechargeable")
    inst:AddTag("combat_leap")
    
    inst:AddComponent("aoetargeting")
    inst.components.aoetargeting:SetTargetFX("weaponsparks")
    inst.components.aoetargeting.reticule.reticuleprefab = "reticuleaoe"
    inst.components.aoetargeting.reticule.pingprefab = "reticuleaoeping"
    inst.components.aoetargeting.reticule.targetfn = ReticuleTargetFn
    inst.components.aoetargeting.reticule.validcolour = {1, .75, 0, 1}
    inst.components.aoetargeting.reticule.invalidcolour = {.5, 0, 0, 1}
    inst.components.aoetargeting.reticule.ease = true
    inst.components.aoetargeting.reticule.mouseenabled = true
    
    inst:AddComponent("rechargeable")
    inst.components.rechargeable:SetRechargeTime(30)
    
    inst:AddComponent("aoeweapon_leap")
    
    inst.entity:SetPristine()
    
    if not TheWorld.ismastersim then
        return inst
    end
    
    inst:AddComponent("aoespell")
    inst.components.aoespell:SetOnCastFn(Jump)
    
    inst:AddComponent("tool")
    inst.components.tool:SetAction(ACTIONS.HAMMER)
    
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "hammer_mjolnir"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/hammer_mjolnir.xml"
    
    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.equipstack = false
    
    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(20)
    inst.components.weapon:SetOnAttack(onattack)
    
    MakeHauntableLaunch(inst)
    
    return inst
end

local function cracklefn()
    local inst = CreateEntity()
    
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    
    inst.AnimState:SetBank("lavaarena_hammer_attack_fx")
    inst.AnimState:SetBuild("lavaarena_hammer_attack_fx")
    inst.AnimState:PlayAnimation("crackle_hit")
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetFinalOffset(1)
    
    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    
    inst.entity:SetPristine()
    
    if not TheWorld.ismastersim then
        return inst
    end
    
    return inst
end

local function cracklebasefn()
    local inst = CreateEntity()
    
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    
    inst.AnimState:SetBank("lavaarena_hammer_attack_fx")
    inst.AnimState:SetBuild("lavaarena_hammer_attack_fx")
    inst.AnimState:PlayAnimation("crackle_projection")
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)
    inst.AnimState:SetScale(1.5, 1.5)
    
    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    
    inst.entity:SetPristine()
    
    if not TheWorld.ismastersim then
        return inst
    end
    
    inst.persists = false
    
    return inst
end

local function MakeCrackleHit(name, withsound)
    local function fn()
        local inst = CreateEntity()
        
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        if withsound then
            inst.entity:AddSoundEmitter()
        end
        inst.entity:AddNetwork()
        
        inst.AnimState:SetBank("lavaarena_hammer_attack_fx")
        inst.AnimState:SetBuild("lavaarena_hammer_attack_fx")
        inst.AnimState:PlayAnimation("crackle_loop")
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetFinalOffset(1)
        inst.AnimState:SetScale(1.5, 1.5)
        
        inst:AddTag("FX")
        inst:AddTag("NOCLICK")
        
        inst.entity:SetPristine()
        
        if not TheWorld.ismastersim then
            return inst
        end
        
        return inst
    end
    
    return Prefab(name, fn, assets_crackle)
end

return Prefab("hammer_mjolnir", fn, assets, prefabs),
Prefab("hammer_mjolnir_crackle", cracklefn, assets_crackle, prefabs_crackle),
Prefab("hammer_mjolnir_cracklebase", cracklebasefn, assets_crackle),
MakeCrackleHit("hammer_mjolnir_cracklehit", false),
MakeCrackleHit("cracklehitfx", true)

   