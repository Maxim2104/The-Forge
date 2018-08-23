local brain = require("brains/berniebrain")

local assets =
{
    Asset("ANIM", "anim/bernie.zip"),
    Asset("ANIM", "anim/bernie_build.zip"),
}

local prefabs =
{
    "small_puff",
}
local function goinactive(inst)
    local inactive = SpawnPrefab("bernie_inactive")
    if inactive ~= nil then
        --Transform health % into fuel.
        inactive.components.fueled:SetPercent(inst.components.health:GetPercent())
        inactive.Transform:SetPosition(inst.Transform:GetWorldPosition())
        inst:Remove()
        return inactive
    end
end

local function onpickup(inst, owner)
    local inactive = goinactive(inst)
    if inactive ~= nil then
        owner.components.inventory:GiveItem(inactive, nil, owner:GetPosition())
    end
    return true
end

local function CanBeRevivedBy(inst, reviver)
    return reviver:HasTag("bernie_reviver")
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst:SetPhysicsRadiusOverride(.35)
    MakeCharacterPhysics(inst, 50, inst.physicsradiusoverride)
    inst.DynamicShadow:SetSize(1.1, .55)

    inst.Transform:SetScale(1.4, 1.4, 1.4)
    inst.Transform:SetFourFaced()

    inst.AnimState:SetBank("bernie")
    inst.AnimState:SetBuild("bernie_build")
    inst.AnimState:PlayAnimation("idle_loop", true)

    inst:AddTag("character")
    inst:AddTag("smallcreature")
    inst:AddTag("companion")
    inst:AddTag("notarget")
    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = TUNING.BERNIE_SPEED
    inst:AddComponent("combat")
    inst:AddComponent("timer")
	
    inst:AddComponent("revivablecorpse")
    inst.components.revivablecorpse:SetCanBeRevivedByFn(CanBeRevivedBy)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.BERNIE_HEALTH)
    inst.components.health.nofadeout = true
	
    inst:SetStateGraph("SGbernie")
    inst:SetBrain(brain)
	
	inst.GoInactive = goinactive

    event_server_data("lavaarena", "prefabs/lavaarena_bernie").master_postinit(inst)

    return inst
end

return Prefab("lavaarena_bernie", fn, assets, prefabs)
