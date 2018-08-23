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
  Asset("ANIM", "anim/spear_gungnir.zip"),
  Asset("ANIM", "anim/swap_spear_gungnir.zip"),
}

local assets_fx = {
  Asset("ANIM", "anim/lavaarena_staff_smoke_fx.zip"),
}

local prefabs = {
  "reticuleline",
  "reticulelineping",
  "spear_gungnir_lungefx",
  "weaponsparks",
  "firehit",
}

local function ReticuleTargetFn()
  --Cast range is 8, leave room for error (6.5 lunge)
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

local function onequip(inst, owner) 
	owner.AnimState:OverrideSymbol("swap_object", "swap_spear_gungnir", "swap_spear_gungnir")
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

local function juzhen(angle,cd,kd,s1,vp)
local s3 = Vector3(s1.x + math.cos(0) * cd, 0, s1.z + math.sin(0) * cd)
local minx = s1.x + 0
local maxx = s3.x + cd
local minz = s3.z - kd/2
local maxz = s3.z + kd/2
local xdjd = math.deg(math.atan2( s1.z - vp.z, vp.x - s1.x ))
local ysjl = (s1 - vp):Length()
local Xangle = -angle
local xvp = Vector3(s1.x + math.cos(math.rad(xdjd + Xangle)) * ysjl, 0, s1.z + math.sin(math.rad(xdjd + Xangle)) * ysjl)
return minx <= xvp.x and xvp.x <= maxx and minz <= xvp.z and xvp.z <= maxz
end

local function MakeTrail(inst, doer, targetpos)
local x,y,z = doer.Transform:GetWorldPosition()
local distanceToTargetPos = math.abs(math.sqrt(math.pow(targetpos.x - x, 2) + math.pow(targetpos.z - z, 2)))
local x2 = targetpos.x - x
local z2 = targetpos.z - z
local angle = math.acos(x2/distanceToTargetPos)

if (x2 < 0 and z2 < 0 and math.deg(angle) < 180 and math.deg(angle) >= 90) or 
(x2 >= 0 and z2 < 0 and math.deg(angle) < 90 and math.deg(angle) > 0) then
angle = -angle
end
for i = 0, 10 do
local lungefx = SpawnPrefab("spear_gungnir_lungefx")
lungefx.Transform:SetPosition(x + ((i / 10) * distanceToTargetPos) * math.cos(angle), 0, z + ((i / 10) * distanceToTargetPos) * math.sin(angle))
end
end

local function oncastfn(inst, doer, pos, data)
local damage = inst.components.aoespell:GetAOE()
local bv = data and data.zs or 0
local val = damage + (damage * bv)
local x,y,z = doer.Transform:GetWorldPosition()
MakeTrail(inst, doer, pos)
doer:PushEvent('combat_lunge', {targetpos = pos, weapon = inst})
local ents = TheSim:FindEntities(x,0,z, 7.5,{"_combat","_health"},{"FX","NOCLICK","DECOR","INLIMBO","player"})
if next(ents) ~= nil then
local ang = math.deg(math.atan2(z - pos.z, pos.x - x))
for k,v in pairs(ents) do
if v and v:IsValid() and not v.components.health:IsDead() then
local vp = v:GetPosition() 
if juzhen(ang,7.5, 3, Vector3(x,y,z),vp) then
local fx = SpawnPrefab("firehit")
fx.Transform:SetPosition(vp:Get())
v.components.combat:GetAttacked(doer, val, nil, nil, "AOE")
v.components.combat:BlankOutAttacks(v.components.combat.min_attack_period or 1.5)
end
end
end
end
end

local function fn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddNetwork()

  MakeInventoryPhysics(inst)

  inst.AnimState:SetBank("spear_gungnir")
  inst.AnimState:SetBuild("spear_gungnir")
  inst.AnimState:PlayAnimation("idle")

  inst:AddTag("melee")
  inst:AddTag("sharp")
  inst:AddTag("pointy")
  inst:AddTag("aoeweapon_lunge")
  inst:AddTag("rechargeable")

  inst:AddComponent("aoetargeting")
	inst.components.aoetargeting:SetTargetFX("spear_gungnir_lungefx")
  inst.components.aoetargeting.reticule.reticuleprefab = "reticuleline"
  inst.components.aoetargeting.reticule.pingprefab = "reticulelineping"
  inst.components.aoetargeting.reticule.targetfn = ReticuleTargetFn
  inst.components.aoetargeting.reticule.mousetargetfn = ReticuleMouseTargetFn
  inst.components.aoetargeting.reticule.updatepositionfn = ReticuleUpdatePositionFn
  inst.components.aoetargeting.reticule.validcolour = { 1, .75, 0, 1 }
  inst.components.aoetargeting.reticule.invalidcolour = { .5, 0, 0, 1 }
  inst.components.aoetargeting.reticule.ease = true
  inst.components.aoetargeting.reticule.mouseenabled = true

	inst:AddComponent("rechargeable")
	inst.components.rechargeable:SetRechargeTime(TUNING.MOD_LAVAARENA.SPEAR_GUNGNIR.RECHARGETIME)

	inst:AddComponent("aoeweapon_lunge")

	inst.entity:SetPristine()

  if not TheWorld.ismastersim then
    return inst
  end

	inst:AddComponent("aoespell")
	inst.components.aoespell:SetOnCastFn(oncastfn)

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.imagename = "spear_gungnir"
	inst.components.inventoryitem.atlasname = "images/inventoryimages/spear_gungnir.xml"

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)
	inst.components.equippable.equipstack = false

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(0)
	inst.components.weapon:SetOnAttack(onattack)

	if TUNING.MOD_LAVAARENA.SPEAR_GUNGNIR.USES.TOTAL ~= -1 then
		inst:AddComponent("finiteuses")
		inst.components.finiteuses:SetMaxUses(TUNING.MOD_LAVAARENA.SPEAR_GUNGNIR.USES.TOTAL)
		inst.components.finiteuses:SetUses(TUNING.MOD_LAVAARENA.SPEAR_GUNGNIR.USES.TOTAL)
		inst.components.finiteuses:SetOnFinished(inst.Remove)
		inst.components.finiteuses:SetConsumption(ACTIONS.ATTACK, TUNING.MOD_LAVAARENA.SPEAR_GUNGNIR.USES.NORMAL)
		inst.components.finiteuses:SetConsumption(ACTIONS.CASTAOE, TUNING.MOD_LAVAARENA.SPEAR_GUNGNIR.USES.SPECIAL * TUNING.MOD_LAVAARENA.SPEAR_GUNGNIR.USES.TOTAL / 100)
	end

	MakeHauntableLaunch(inst)

  return inst
end

local function FastForwardFX(inst, pct)
  if inst._task ~= nil then
    inst._task:Cancel()
  end
  local len = inst.AnimState:GetCurrentAnimationLength()
  pct = math.clamp(pct, 0, 1)
  inst.AnimState:SetTime(len * pct)
  inst._task = inst:DoTaskInTime(len * (1 - pct) + 2 * FRAMES, inst.Remove)
end

--[[local function SetMotionFX(inst, dx, dy, dz)
    inst.Physics:SetMotorVel(dx, dy, dz)
end]]

local function fxfn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  --inst.entity:AddPhysics()
  inst.entity:AddNetwork()

  --[[inst.Physics:SetMass(1)
  inst.Physics:CollidesWith(COLLISION.GROUND)
  inst.Physics:SetSphere(.2)]]

  inst:AddTag("FX")
  inst:AddTag("NOCLICK")

  inst.AnimState:SetBank("lavaarena_staff_smoke_fx")
  inst.AnimState:SetBuild("lavaarena_staff_smoke_fx")
  inst.AnimState:PlayAnimation("idle")
  inst.AnimState:SetAddColour(1, 1, 0, 0)
  inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

  inst.entity:SetPristine()

  if not TheWorld.ismastersim then
    return inst
  end

  inst.persists = false
  inst._task = inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength() + 2 * FRAMES, inst.Remove)

  inst.FastForward = FastForwardFX
  --inst.SetMotion = SetMotionFX

  return inst
end

return Prefab("spear_gungnir", fn, assets, prefabs),
       Prefab("spear_gungnir_lungefx", fxfn, assets_fx)
