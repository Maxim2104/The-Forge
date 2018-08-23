
local assets =
{
    Asset( "ANIM", "anim/lavaarena_boarrior_fx.zip" ),
}

local prefabs =
{
    "groundfire",
    "groundpound_fx",
}

local meteordamage = TUNING.CCW.BOSSBOAR.METEORDAMAGE

local function DoStrike(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    inst.striketask = nil
	inst.warnshadow:Remove()
    inst.fireeffect = SpawnPrefab("groundfire")
    inst.fireeffect.Transform:SetPosition(x, y, z)
    
    local ents = TheSim:FindEntities(x, y, z, inst.size * TUNING.METEOR_RADIUS, nil)--, NON_SMASHABLE_TAGS, SMASHABLE_TAGS)

    for i, ent in ipairs(ents) do
        if inst.parent and ent:IsValid() and not ent:IsInLimbo() 
            and ent.prefab ~= "bossboar"
            and ent.components.combat ~= nil 
            and not table.contains(inst.parent.showerHittedList, ent)
        then
            ent.components.combat:GetAttacked(inst, meteordamage, nil) --inst.size * TUNING.METEOR_DAMAGE, nil)
            table.insert(inst.parent.showerHittedList, ent)
            inst.parent:DoTaskInTime(0.75, function(inst, ent) 
                RemoveByValue(inst.showerHittedList, ent)
            end, ent)
        end
    end

    inst:Remove()
end

local function StartBurst(inst, parent, size)--, sz)
	inst.size = size and size or 1
    inst.parent = parent
    inst.warnshadow = SpawnPrefab("groundpound_fx")
	inst.warnshadow.Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst.warnshadow.Transform:SetScale(inst.size * 0.4, inst.size  * 0.4, inst.size  * 0.4)
    inst.striketask = inst:DoTaskInTime(1, DoStrike)
end

local function fn() 
    local inst = CreateEntity()

    inst.entity:AddTransform()
    --inst.entity:AddNetwork()

    inst:AddTag("NOCLICK")
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("propagator")
    inst.components.propagator.propagaterange = 4
    inst.components.propagator:StartSpreading() 
	--inst.entity:Hide()

    inst.StartBurst = StartBurst
    inst.striketask = nil

    inst:DoTaskInTime(3, function() inst:Remove() end)

    return inst
end

return Prefab("lavaarena_boarriorfireburst", fn, assets, prefabs)
