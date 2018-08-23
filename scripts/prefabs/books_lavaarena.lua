local function SetCooldownBonus(inst, owner)
    local armor = owner.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
    local head = owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
    local hand = owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HAND)

    local bonus = (armor and armor.cooldownbonus or 0) + (head and head.cooldownbonus or 0)
    if hand and hand.components.rechargeable then
        hand.components.rechargeable:SetBonus(bonus)
    end
end

local prefabs_fossil = {
    "lavaarena_fossilizing",
    "reticuleaoe",
    "reticuleaoeping",
    "reticuleaoecctarget",
}

local prefabs_elemental = {
    "lavaarena_elemental",
    "reticuleaoesummon",
    "reticuleaoesummonping",
    "reticuleaoesummontarget",
}

--------------------------------------------------------------------------

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
    owner.AnimState:OverrideSymbol("book_closed", "swap_".. (inst.prefab), "book_closed")
end

local function onunequip(inst, owner)
    owner.AnimState:OverrideSymbol("book_open", "player_actions_uniqueitem", "book_open")
    owner.AnimState:OverrideSymbol("book_closed", "player_actions_uniqueitem", "book_closed")
    owner.AnimState:OverrideSymbol("book_open_pages", "player_actions_uniqueitem", "book_open_pages")
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function onattack(inst, attacker, target)
    if target.components.sleeper and target.components.sleeper:IsAsleep() then
        target.components.sleeper:WakeUp()
    end
    
    if target.components.combat then
        target.components.combat:SuggestTarget(attacker)
    end
end

local function createDebris()
    local i = math.ceil(math.random() * 3)
    return {prefab = SpawnPrefab("lavaarena_fossilizedebris"..i), t = i}
end

local function OnCastFossil(inst, doer, pos, target)
    local x, y, z = inst.Transform:GetWorldPosition()

    local notags = {"playerghost", "INLIMBO", "NOCLICK", "FX"}
    for _, v in pairs(TheSim:FindEntities(pos.x, pos.y, pos.z, 6, nil, notags)) do
        if v ~= doer
            and v:IsValid()
            and v.entity:IsVisible()
            and not v:IsInLimbo()
            and v.components.fossilizable
            then
            v.components.fossilizable:AddColdness(1)
        end
    end

    local debris = {}
    local centerdebris = createDebris()
    table.insert(debris, centerdebris)
    centerdebris.prefab.Transform:SetPosition(pos.x, pos.y, pos.z)

    
    for i = 1, 5 do
        local debri = createDebris()
        table.insert(debris, debri)
        debri.prefab.Transform:SetPosition(pos.x + 1.8 * math.cos(math.rad(i * 72)), pos.y, pos.z + 1.8 * math.sin(math.rad(i * 72)))
    end

    for i = 1, 9 do
        local debri = createDebris()
        table.insert(debris, debri)
        debri.prefab.Transform:SetPosition(pos.x + 3.7 * math.cos(math.rad(i * 40)), pos.y, pos.z + 3.7 * math.sin(math.rad(i * 40)))
    end

    for _, v in pairs(debris) do
        v.prefab:ListenForEvent("animover", function(inst)
            inst.AnimState:PlayAnimation("idle_"..v.t)
            inst:ListenForEvent("animover", inst.Remove)
        end)
    end
end

local function OnCastElemental(inst, doer, pos)
    local elemental = SpawnPrefab("lavaarena_elemental")
    elemental.Transform:SetPosition(pos.x, pos.y, pos.z);
end

local function MakeBook(booktype, reticule, prefabs, oncastfn)
    local name = "book_"..booktype
    local assets = {
        Asset("ANIM", "anim/"..name..".zip"),
        Asset("ANIM", "anim/swap_"..name..".zip"),
    }
    
    local function fn()
        local inst = CreateEntity()
        
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        
        MakeInventoryPhysics(inst)
        
        inst.AnimState:SetBank(name)
        inst.AnimState:SetBuild(name)
        inst.AnimState:PlayAnimation(name)

        inst.swapBuild = "swap_"..name..""
        
        inst:AddTag("book")
        inst:AddTag("rechargeable")
        
        inst:AddComponent("aoetargeting")
        inst.components.aoetargeting.reticule.reticuleprefab = reticule
        inst.components.aoetargeting.reticule.pingprefab = reticule.."ping"
        inst.components.aoetargeting.reticule.targetfn = ReticuleTargetFn
        inst.components.aoetargeting.reticule.validcolour = {1, .75, 0, 1}
        inst.components.aoetargeting.reticule.invalidcolour = {.5, 0, 0, 1}
        inst.components.aoetargeting.reticule.ease = true
        inst.components.aoetargeting.reticule.mouseenabled = true
        
        inst.entity:SetPristine()
        
        inst:AddComponent("rechargeable")

        if booktype == "elemental" then
            inst.components.rechargeable:SetRechargeTime(TUNING.MOD_LAVAARENA.BOOK_ELEMENTAL.RECHARGETIME)
        else
            inst.components.rechargeable:SetRechargeTime(30)
        end
        
        if not TheWorld.ismastersim then
            return inst
        end
        
        inst:AddComponent("aoespell")
        inst.components.aoespell:SetOnCastFn(oncastfn)
        
        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.imagename = name
        inst.components.inventoryitem.atlasname = "images/inventoryimages/"..name..".xml"
        
        inst:AddComponent("equippable")
        inst.components.equippable:SetOnEquip(onequip)
        inst.components.equippable:SetOnUnequip(onunequip)
        inst.components.equippable.equipstack = false
        
        inst:AddComponent("weapon")
        inst.components.weapon:SetDamage(15)
        inst.components.weapon:SetOnAttack(onattack)
        
        if booktype == "elemental" and TUNING.MOD_LAVAARENA.BOOK_ELEMENTAL.USES.TOTAL ~= -1 then
            inst:AddComponent("finiteuses")
            inst.components.finiteuses:SetMaxUses(TUNING.MOD_LAVAARENA.BOOK_ELEMENTAL.USES.TOTAL)
            inst.components.finiteuses:SetUses(TUNING.MOD_LAVAARENA.BOOK_ELEMENTAL.USES.TOTAL)
            inst.components.finiteuses:SetOnFinished(inst.Remove)
            inst.components.finiteuses:SetConsumption(ACTIONS.CASTAOE, TUNING.MOD_LAVAARENA.BOOK_ELEMENTAL.USES.SPECIAL * TUNING.MOD_LAVAARENA.HEALINGSTAFF.USES.TOTAL / 100)
        end
        
        MakeHauntableLaunch(inst)
        
        return inst
    end
    
    return Prefab(name, fn, assets, prefabs)
end

--For searching: "book_fossil", "book_elemental"
return MakeBook("fossil", "reticuleaoe", prefabs_fossil, OnCastFossil),
MakeBook("elemental", "reticuleaoesummon", prefabs_elemental, OnCastElemental)
