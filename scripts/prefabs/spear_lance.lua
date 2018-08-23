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
  Asset("ANIM", "anim/spear_lance.zip"),
  Asset("ANIM", "anim/swap_spear_lance.zip"),
}

local prefabs = {
  "reticuleaoesmall",
  "reticuleaoesmallping",
  "reticuleaoesmallhostiletarget",
  "weaponsparks",
  "weaponsparks_thrusting",
  "firehit",
  "superjump_fx",
}
local function Jump(inst, caster, pos)
	caster:PushEvent("superjump", { weapon=inst, targetpos=pos })
end

local function oncastfn(inst, doer, pos, data)
local damage = inst.components.aoespell:GetAOE()
local bv = data and data.zs or 0
local val = damage + (damage * bv)
doer.sg:GoToState('combat_superjump', {
startingpos = doer.Transform:GetWorldPosition(),
data = {
targetpos = pos,
weapon = inst
}
})
doer:DoTaskInTime(1.2, function()
local ens = TheSim:FindEntities(pos.x, 0, pos.z, 3, {"_combat","_health"}, {"player","FX","NOCLICK","DECOR","INLIMBO"})
for k,v in pairs(ens) do
if not v.components.health:IsDead() then
v.components.combat:GetAttacked(doer, val, nil, nil, "AOE")
v.components.combat:BlankOutAttacks(v.components.combat.min_attack_period or 1.5)
end
end
local fx = SpawnPrefab("superjump_fx")
fx.Transform:SetPosition(pos:Get())
end)
local fx1 = SpawnPrefab("reticuleaoesmallhostiletarget")
fx1.Transform:SetPosition(pos:Get())
fx1:DoTaskInTime(0.5, function()
fx1._fade:set(11)
end)
end

local function ReticuleTargetFn()
  local player = ThePlayer
  local ground = TheWorld.Map
  local pos = Vector3()
  --Cast range is 8, leave room for error
  --2 is the aoe range
  for r = 5, 0, -.25 do
    pos.x, pos.y, pos.z = player.entity:LocalToWorldSpace(r, 0, 0)
    if ground:IsPassableAtPoint(pos:Get()) and not ground:IsGroundTargetBlocked(pos) then
      return pos
    end
  end
  return pos
end

local function onequip(inst, owner) 
	owner.AnimState:OverrideSymbol("swap_object", "swap_spear_lance", "swap_spear_lance")
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
  inst.entity:AddNetwork()

  MakeInventoryPhysics(inst)

  inst.AnimState:SetBank("spear_lance")
  inst.AnimState:SetBuild("spear_lance")
  inst.AnimState:PlayAnimation("idle")

  inst:AddTag("melee")
  inst:AddTag("sharp")
  inst:AddTag("pointy")
  inst:AddTag("superjump")
  inst:AddTag("aoeweapon_leap")
  inst:AddTag("rechargeable")

  inst:AddComponent("aoetargeting")
  inst.components.aoetargeting:SetRange(16)
  inst.components.aoetargeting:SetTargetFX("superjump_fx")
  inst.components.aoetargeting.reticule.reticuleprefab = "reticuleaoesmall"
  inst.components.aoetargeting.reticule.pingprefab = "reticuleaoesmallping"
  inst.components.aoetargeting.reticule.targetfn = ReticuleTargetFn
  inst.components.aoetargeting.reticule.validcolour = { 1, .75, 0, 1 }
  inst.components.aoetargeting.reticule.invalidcolour = { .5, 0, 0, 1 }
  inst.components.aoetargeting.reticule.ease = true
  inst.components.aoetargeting.reticule.mouseenabled = true

	inst:AddComponent("aoeweapon_leap")

	inst:AddComponent("rechargeable")
	inst.components.rechargeable:SetRechargeTime(30)

	inst.entity:SetPristine()

  if not TheWorld.ismastersim then
    return inst
  end

	inst:AddComponent("aoespell")
	inst.components.aoespell:SetOnCastFn(oncastfn)

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.imagename = "spear_lance"
	inst.components.inventoryitem.atlasname = "images/inventoryimages/spear_lance.xml"

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)
	inst.components.equippable.equipstack = false

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(30)
	inst.components.weapon:SetOnAttack(onattack)

  MakeHauntableLaunch(inst)

  return inst
end

return Prefab("spear_lance", fn, assets, prefabs)
