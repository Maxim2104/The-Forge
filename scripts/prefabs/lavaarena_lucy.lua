local function SetCooldownBonus(inst, owner)
	local armor = owner.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
	local head  = owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
	local hand  = owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HAND)
	
	local bonus = (armor and armor.cooldownbonus or 0) + (head and head.cooldownbonus or 0)
	if hand and hand.components.rechargeable then
		hand.components.rechargeable:SetBonus(bonus)
	end
end

local assets = {
  Asset("ANIM", "anim/swap_lucy_axe.zip"),
  Asset("ANIM", "anim/lavaarena_lucy.zip"),
  Asset("INV_IMAGE", "lucy"),
}

local assets_fx = {
  Asset("ANIM", "anim/lavaarena_lucy.zip"),
  Asset("MINIMAP_IMAGE", "lucy_axe"),
}

local prefabs = {
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

--------------------------------------------------------------------------

local function AttachClassified(inst, classified)
  inst.lucy_classified = classified
  inst.ondetachclassified = function() inst:DetachClassified() end
  inst:ListenForEvent("onremove", inst.ondetachclassified, classified)
end

local function DetachClassified(inst)
  inst.lucy_classified = nil
  inst.ondetachclassified = nil
end

local function OnRemoveEntity(inst)
  if inst.lucy_classified ~= nil then
    if TheWorld.ismastersim then
      inst.lucy_classified:Remove()
      inst.lucy_classified = nil
    else
      inst.lucy_classified._parent = nil
      inst:RemoveEventCallback("onremove", inst.ondetachclassified, inst.lucy_classified)
      inst:DetachClassified()
    end
  end
end

local function storeincontainer(inst, container)
  if container ~= nil and container.components.container ~= nil then
    inst:ListenForEvent("onputininventory", inst._oncontainerownerchanged, container)
    inst:ListenForEvent("ondropped", inst._oncontainerownerchanged, container)
    inst:ListenForEvent("onremove", inst._oncontainerremoved, container)
    inst._container = container
  end
end

local function unstore(inst)
  if inst._container ~= nil then
    inst:RemoveEventCallback("onputininventory", inst._oncontainerownerchanged, inst._container)
    inst:RemoveEventCallback("ondropped", inst._oncontainerownerchanged, inst._container)
    inst:RemoveEventCallback("onremove", inst._oncontainerremoved, inst._container)
    inst._container = nil
  end
end

local function topocket(inst, owner)
  if inst._container ~= owner then
    unstore(inst)
    storeincontainer(inst, owner)
  end
  inst.lucy_classified:SetTarget(owner.components.inventoryitem ~= nil and owner.components.inventoryitem.owner or owner)
end

local function toground(inst)
  unstore(inst)
  --No target means everyone receives it
  inst.lucy_classified:SetTarget(nil)
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

--------------------------------------------------------------------------

local function oncastcast(inst, doer, pos, data)
local damage = inst.components.aoespell:GetAOE()
local bv = data and data.zs or 0
local val = damage + (damage * bv)
local x,y,z = doer.Transform:GetWorldPosition()
doer:PushEvent('throw_line', {targetpos = pos, weapon = inst})
inst.AnimState:PlayAnimation("spin_loop")

local ents = TheSim:FindEntities(x,0,z, 7.5,{"_combat","_health"},{"FX","NOCLICK","DECOR","INLIMBO","player"})
if next(ents) ~= nil then
local ang = math.deg(math.atan2(z - pos.z, pos.x - x))
for k,v in pairs(ents) do
if v and v:IsValid() and not v.components.health:IsDead() then
local vp = v:GetPosition() 
local fx = SpawnPrefab("firehit")
fx.Transform:SetPosition(vp:Get())
v.components.combat:GetAttacked(doer, val, nil, nil, "AOE")
v.components.combat:BlankOutAttacks(v.components.combat.min_attack_period or 1.5)
end
end
end
end

--[[
local function oncastcast(inst, doer, item, pos)
    doer:PushEvent("throw_line", {weapon = inst, targetpos = pos})
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
			    inst.AnimState:PlayAnimation("spin_loop")

                end
            elseif v.Physics ~= nil and v.components.inventoryitem ~= nil then
                local xv, yv, zv = v.Transform:GetWorldPosition()
                v.Physics:Teleport(xv, 0.5, zv)
                local vec = Vector3(xv - pos.x, yv - pos.y, zv - pos.z):Normalize()
            end
        end
    end
end
--]]
local function onequip(inst, owner) 
	owner.AnimState:OverrideSymbol("swap_object", "swap_lucy_axe", "swap_lucy_axe")
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

local function ondonetalking(inst)
  inst.localsounds.SoundEmitter:KillSound("talk")
end

local function ontalk(inst)
  local sound = inst.lucy_classified ~= nil and inst.lucy_classified:GetTalkSound() or nil
  if sound ~= nil then
    inst.localsounds.SoundEmitter:KillSound("talk")
    inst.localsounds.SoundEmitter:PlaySound(sound)
  elseif not inst.localsounds.SoundEmitter:PlayingSound("talk") then
    inst.localsounds.SoundEmitter:PlaySound("dontstarve/characters/woodie/lucytalk_LP", "talk")
  end
end

local function CustomOnHaunt(inst)
  if inst.components.sentientaxe ~= nil then
    inst.components.sentientaxe:Say(STRINGS.LUCY.on_haunt)
    return true
  end
  return false
end

local function fn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
	inst.entity:AddMiniMapEntity()
  inst.entity:AddNetwork()

  MakeInventoryPhysics(inst)

	inst.MiniMapEntity:SetIcon("lucy_axe.png")

  inst.AnimState:SetBank("lavaarena_lucy")
  inst.AnimState:SetBuild("lavaarena_lucy")
  inst.AnimState:PlayAnimation("idle")

  inst.Transform:SetSixFaced()

  inst:AddTag("melee")
  inst:AddTag("sharp")
  inst:AddTag("throw_line")
  inst:AddTag("chop_attack")
  inst:AddTag("rechargeable")

	inst.AttachClassified = AttachClassified
  inst.DetachClassified = DetachClassified
  inst.OnRemoveEntity = OnRemoveEntity

	inst:AddComponent("talker")
  inst.components.talker.fontsize = 28
  inst.components.talker.font = TALKINGFONT
  inst.components.talker.colour = Vector3(.9, .4, .4)
  inst.components.talker.offset = Vector3(0, 0, 0)
  inst.components.talker.symbol = "swap_object"

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

	--Dedicated server does not need to spawn the local sound fx
  if not TheNet:IsDedicated() then
    inst.localsounds = CreateEntity()
    inst.localsounds:AddTag("FX")
    --[[Non-networked entity]]
    inst.localsounds.entity:AddTransform()
    inst.localsounds.entity:AddSoundEmitter()
    inst.localsounds.entity:SetParent(inst.entity)
    inst.localsounds:Hide()
    inst.localsounds.persists = false
    inst:ListenForEvent("ontalk", ontalk)
    inst:ListenForEvent("donetalking", ondonetalking)
  end

  inst.entity:SetPristine()

  if not TheWorld.ismastersim then
    return inst
  end

	inst:AddComponent("rechargeable")
	inst.components.rechargeable:SetRechargeTime(3)

	inst:AddComponent("aoespell")
	inst.components.aoespell:SetOnCastFn(oncastcast)

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.imagename = "lavaarena_lucy"
	inst.components.inventoryitem.atlasname = "images/inventoryimages/lavaarena_lucy.xml"

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)
	inst.components.equippable.equipstack = false

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(20)
	--inst.components.weapon:SetRange(10, 12)
	--inst.components.weapon:SetProjectile("lavaarena_lucy_spin")
	inst.components.weapon:SetOnAttack(onattack)

	inst:AddComponent("tool")
  inst.components.tool:SetAction(ACTIONS.CHOP, 2)

	inst:AddComponent("possessedaxe")
  inst.components.possessedaxe.revert_fx = "lucy_ground_transform_fx"
  inst.components.possessedaxe.transform_fx = "lucy_transform_fx"

	inst:AddComponent("sentientaxe")

	inst.lucy_classified = SpawnPrefab("lucy_classified")
  inst.lucy_classified.entity:SetParent(inst.entity)
  inst.lucy_classified._parent = inst
  inst.lucy_classified:SetTarget(nil)

  inst._container = nil

  inst._oncontainerownerchanged = function(container)
    topocket(inst, container)
  end

  inst._oncontainerremoved = function()
    unstore(inst)
  end

  inst:ListenForEvent("onputininventory", topocket)
  inst:ListenForEvent("ondropped", toground)

	MakeHauntableLaunch(inst)
	AddHauntableCustomReaction(inst, CustomOnHaunt, true, false, true)

  return inst
end

--------------------------------------------------------------------------

local function CreateSpinFX()
  local inst = CreateEntity()

  inst:AddTag("FX")
  --[[Non-networked entity]]
  inst.entity:SetCanSleep(false)
  inst.persists = false

  inst.entity:AddTransform()
  inst.entity:AddAnimState()

  inst.AnimState:SetBank("lavaarena_lucy")
  inst.AnimState:SetBuild("lavaarena_lucy")
  inst.AnimState:PlayAnimation("return")
  inst.AnimState:SetMultColour(.2, .2, .2, .2)

  inst.Transform:SetSixFaced()

  inst:DoTaskInTime(13 * FRAMES, inst.Remove)

  return inst
end

local function OnUpdateSpin(fx, inst)
  local parent = fx.owner.entity:GetParent()
  if fx.alpha >= .6 and (parent == nil or not (parent.AnimState:IsCurrentAnimation("catch_pre") or parent.AnimState:IsCurrentAnimation("catch"))) then
    fx.dalpha = -.1
  end
  local x, y, z = inst.Transform:GetWorldPosition()
  local x1, y1, z1 = fx.Transform:GetWorldPosition()
  local dx = x1 - x
  local dz = z1 - z
  local dist = math.sqrt(dx * dx + dz * dz)
  fx.offset = fx.offset * .8 + .2
  fx.vy = fx.vy + fx.ay
  fx.height = fx.height + fx.vy
  fx.Transform:SetPosition(x + dx * fx.offset / dist, fx.height, z + dz * fx.offset / dist)
  if fx.alpha ~= 0 then
    fx.alpha = fx.alpha + fx.dalpha
    if fx.alpha >= 1 then
      fx.dalpha = 0
      fx.alpha = 1
    elseif fx.alpha <= 0 then
      fx:Remove()
    end
    fx.AnimState:SetMultColour(fx.alpha, fx.alpha, fx.alpha, fx.alpha)
  end
end

local function OnOriginDirty(inst)
  local parent = inst.entity:GetParent()
  if parent ~= nil then
    local x, y, z = inst.Transform:GetWorldPosition()
    local dx = inst._originx:value() - x
    local dz = inst._originz:value() - z
    local distsq = dx * dx + dz * dz
    local dist = math.sqrt(distsq)
    local fx = CreateSpinFX()
    fx.owner = inst
    fx.offset = math.min(3, dist)
    fx.height = 2
    fx.vy = .2
    fx.ay = -.05
    fx.alpha = .2
    fx.dalpha = .2
    fx.Transform:SetPosition(x + dx * fx.offset / dist, fx.height, z + dz * fx.offset / dist)
    fx:ForceFacePoint(inst._originx:value(), 0, inst._originz:value())
    fx:ListenForEvent("onremove", function() fx:Remove() end, inst)
    fx:DoPeriodicTask(0, OnUpdateSpin, nil, inst)
  end
end

local function SetOrigin(inst, x, y, z)
  if x == 0 then
    --make sure something is dirty for sure
    inst._originx:set_local(0)
  end
  inst._originx:set(x)
  inst._originz:set(z)
  if not TheNet:IsDedicated() then
    OnOriginDirty(inst)
  end
end

local function fxfn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddNetwork()

  inst:AddTag("FX")

  inst._originx = net_float(inst.GUID, "lavaarena_lucy_spin._originx", "origindirty")
  inst._originz = net_float(inst.GUID, "lavaarena_lucy_spin._originz", "origindirty")

  inst.entity:SetPristine()

  if not TheWorld.ismastersim then
    inst:ListenForEvent("origindirty", OnOriginDirty)
    return inst
  end

  inst.persists = false
  inst.SetOrigin = SetOrigin
  inst:DoTaskInTime(.5, inst.Remove)

  return inst
end

return Prefab("lavaarena_lucy", fn, assets, prefabs),
       Prefab("lavaarena_lucy_spin", fxfn, assets_fx)
