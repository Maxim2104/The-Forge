local assets = {
  Asset("ANIM", "anim/swap_lucy_axe.zip"),
  Asset("ANIM", "anim/lavaarena_lucy.zip"),
  Asset("INV_IMAGE", "lucy"),
}

local assets_fx = {
  Asset("ANIM", "anim/lavaarena_lucy.zip"),
  Asset("MINIMAP_IMAGE", "lucy_axe"),
}


local prefabs =
{
  "reticulelong",
  "reticulelongping",
  "weaponsparks",
  "weaponsparks_piercing",
  "weaponsparks_bounce",
  "lucy_transform_fx",
  "splash_ocean",
  "lavaarena_lucy_spin",
  "sunderarmordebuff",
	"lucy_ground_transform_fx",
	"lucy_classified",
}

local function oncastfn(inst, doer, item, pos)
	doer:PushEvent("throw_line", { weapon=inst, targetpos=pos })
    if inst == nil or doer == nil or pos == nil then 
        return false
    end

    local notags = { "playerghost", "INLIMBO", "NOCLICK", "FX" }
    local damage = 20
	local ens = TheSim:FindEntities(pos.x, 0, pos.z, 5, nil, {"_combat","_health"}, {"player","FX","NOCLICK","DECOR","INLIMBO"})
for k,v in pairs(ens) do
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

local function OnHit(inst, attacker, target)
    local x, y, z = inst.Transform:GetWorldPosition()
    inst:Remove()
    SpawnPrefab("sleepbomb_burst").Transform:SetPosition(x, y, z)
    SpawnPrefab("sleepcloud").Transform:SetPosition(x, y, z)
end

local function onequip(inst, owner) 
    owner.AnimState:OverrideSymbol("swap_object", "swap_lucy_axe", "swap_lucy_axe")
    owner.AnimState:Show("ARM_carry") 
    owner.AnimState:Hide("ARM_normal") 
end

local function onunequip(inst, owner) 
    owner.AnimState:Hide("ARM_carry") 
    owner.AnimState:Show("ARM_normal") 
end

local function onthrown(inst)
    inst:AddTag("NOCLICK")
    inst.persists = false

    inst.AnimState:PlayAnimation("spin_loop")

    inst.Physics:SetMass(1)
    inst.Physics:SetCapsule(0.2, 0.2)
    inst.Physics:SetFriction(0)
    inst.Physics:SetDamping(0)
    inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.WORLD)
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
    inst.Physics:CollidesWith(COLLISION.ITEMS)
end

local function ReticuleTargetFn()
    local player = ThePlayer
    local ground = TheWorld.Map
    local pos = Vector3()
    --Attack range is 8, leave room for error
    --Min range was chosen to not hit yourself (2 is the hit range)
    for r = 6.5, 3.5, -.25 do
        pos.x, pos.y, pos.z = player.entity:LocalToWorldSpace(r, 0, 0)
        if ground:IsPassableAtPoint(pos:Get()) and not ground:IsGroundTargetBlocked(pos) then
            return pos
        end
    end
    return pos
end

local function ReticuleTargetFn()
  return Vector3(ThePlayer.entity:LocalToWorldSpace(6.5, 0, 0))
end

local function ReticuleMouseTargetFn(inst, mousepos)
  if mousepos ~= nil then
    local x, y, z = inst.Transform:GetWorldPosition()
    local dx = mousepos.x - x
    local dz = mousepos.z - z
    local l = dx * dx + dz * dz
    if l <= 0 then
      return inst.components.reticule.targetpos
    end
    l = 6.5 / math.sqrt(l)
    return Vector3(x + dx * l, 0, z + dz * l)
  end
end

local function ReticuleUpdatePositionFn(inst, pos, reticule, ease, smoothing, dt)
  local x, y, z = inst.Transform:GetWorldPosition()
  reticule.Transform:SetPosition(x, 0, z)
  local rot = -math.atan2(pos.z - z, pos.x - x) / DEGREES
  if ease and dt ~= nil then
    local rot0 = reticule.Transform:GetRotation()
    local drot = rot - rot0
    rot = Lerp((drot > 180 and rot0 + 360) or (drot < -180 and rot0 - 360) or rot0, rot, dt * smoothing)
  end
  reticule.Transform:SetRotation(rot)
end
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    --projectile (from complexprojectile component) added to pristine state for optimization
    inst:AddTag("projectile")


  inst.AnimState:SetBank("lavaarena_lucy")
  inst.AnimState:SetBuild("lavaarena_lucy")
  inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetDeltaTimeMultiplier(.75)

    inst:AddComponent("reticule")
    inst.components.reticule.targetfn = ReticuleTargetFn
    inst.components.reticule.ease = true
	
	inst:AddComponent("aoespell")
	inst.components.aoespell:SetOnCastFn(oncastfn)
	
	inst:AddComponent("aoetargeting")
  inst.components.aoetargeting:SetAlwaysValid(true)
  inst.components.aoetargeting.reticule.reticuleprefab = "reticulelong"
  inst.components.aoetargeting.reticule.pingprefab = "reticulelongping"
  inst.components.aoetargeting.reticule.targetfn = ReticuleTargetFn
  inst.components.aoetargeting.reticule.mousetargetfn = ReticuleMouseTargetFn
  inst.components.aoetargeting.reticule.updatepositionfn = ReticuleUpdatePositionFn
  inst.components.aoetargeting.reticule.validcolour = { 1, .75, 0, 1 }
  inst.components.aoetargeting.reticule.invalidcolour = { .5, 0, 0, 1 }
  inst.components.aoetargeting.reticule.ease = true
  inst.components.aoetargeting.reticule.mouseenabled = true

   inst:AddTag("nopunch")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("locomotor")

    inst:AddComponent("complexprojectile")
    inst.components.complexprojectile:SetHorizontalSpeed(15)
    inst.components.complexprojectile:SetGravity(-35)
    inst.components.complexprojectile:SetLaunchOffset(Vector3(.25, 1, 0))
    inst.components.complexprojectile:SetOnLaunch(onthrown)
    inst.components.complexprojectile:SetOnHit(OnHit)

        inst:AddComponent("weapon")
        inst.components.weapon:SetDamage(10)
        inst.components.weapon:SetRange(8, 10)
    

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("stackable")

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.equipstack = true

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("lavaarena_lucy", fn, assets, prefabs)
