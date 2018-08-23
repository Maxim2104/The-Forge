require "regrowthutil"

local assets =
{
    Asset("ANIM", "anim/meteor.zip"),
    Asset("ANIM", "anim/warning_shadow.zip"),
    Asset("ANIM", "anim/meteor_shadow.zip"),
}

local prefabs =
{
    "meteorwarning",
    "burntground",
    "splash_ocean",
    "ground_chunks_breaking",
}

local meteordamage = TUNING.CCW.BOSSBOAR.METEORDAMAGE

local function onexplode(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/meteor_impact")

    local shakeduration = .7 * inst.size
    local shakespeed = .02 * inst.size
    local shakescale = .5 * inst.size
    local shakemaxdist = 40 * inst.size
    ShakeAllCameras(CAMERASHAKE.FULL, shakeduration, shakespeed, shakescale, inst, shakemaxdist)

    local x, y, z = inst.Transform:GetWorldPosition()

    if not inst:IsOnValidGround() then
        local splash = SpawnPrefab("splash_ocean")
        if splash ~= nil then
            splash.Transform:SetPosition(x, y, z)
        end
    else
        local scorch = SpawnPrefab("burntground")
        if scorch ~= nil then
            scorch.Transform:SetPosition(x, y, z)
            local scale = inst.size * 1.3
            scorch.Transform:SetScale(scale, scale, scale)
        end
		scorch:DoTaskInTime(10, function(inst) inst:Remove() end)
        local launched = {}
        local ents = TheSim:FindEntities(x, y, z, inst.size * TUNING.METEOR_RADIUS, nil)--, NON_SMASHABLE_TAGS, SMASHABLE_TAGS)
        for i, v in ipairs(ents) do
            if v:IsValid() and not v:IsInLimbo() then
                if v.components.combat ~= nil then
                    v.components.combat:GetAttacked(inst, meteordamage, nil) --inst.size * TUNING.METEOR_DAMAGE, nil)
				end
            end
        end
    end
end

local function DoStrike(inst)
    inst.striketask = nil
	inst.warnshadow:Remove()
    inst.AnimState:PlayAnimation("crash")
    inst:DoTaskInTime(0.33, onexplode)
    inst:ListenForEvent("animover", inst.Remove)
    inst:DoTaskInTime(3, inst.Remove)
end

local function StartMeteor(inst, size, angle)--, sz)

	inst.size = size and size or 0.3
	local rotate = angle and angle or 0
	inst.Transform:SetRotation(rotate)
    inst.warnshadow = SpawnPrefab("meteorwarning")
	inst.warnshadow.Transform:SetPosition(inst.Transform:GetWorldPosition())
	
    inst.Transform:SetScale(inst.size, inst.size, inst.size)
    inst.warnshadow.Transform:SetScale(inst.size, inst.size, inst.size)

    inst.striketask = inst:DoTaskInTime(1, DoStrike)
end

local function fn() 
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    
    inst.Transform:SetTwoFaced()

    inst.AnimState:SetBank("meteor")
    inst.AnimState:SetBuild("meteor")

    inst:AddTag("NOCLICK")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	
	inst.size = 1

    inst.StartMeteor = StartMeteor
    inst.striketask = nil

    inst.persists = false

    return inst
end

return Prefab("lavaarena_boarriormeteor", fn, assets, prefabs)
