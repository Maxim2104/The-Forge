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
  Asset("ANIM", "anim/fireballstaff.zip"),
  Asset("ANIM", "anim/swap_fireballstaff.zip"),
}

local assets_fx = {
  Asset("ANIM", "anim/fireball_2_fx.zip"),
  Asset("ANIM", "anim/deer_fire_charge.zip"),
}

local prefabs = {
  "fireball_projectile",
  "fireball_cast_fx",
  "lavaarena_meteor",
  "reticuleaoe",
  "reticuleaoeping",
  "reticuleaoehostiletarget",
}

local PROJECTILE_DELAY = 4 * FRAMES

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
	owner.AnimState:OverrideSymbol("swap_object", "swap_fireballstaff", "swap_fireballstaff")
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

local function oncastfn(inst, doer, pos)
	local meteor = SpawnPrefab("lavaarena_meteor")
	meteor.Transform:SetPosition(pos.x, pos.y, pos.z)
	
	meteor:ListenForEvent("animover", function(inst)
		local x, y, z = inst.Transform:GetWorldPosition()
		local splash_base = SpawnPrefab("lavaarena_meteor_splashbase")
		local splash      = SpawnPrefab("lavaarena_meteor_splash")
		local splashhit   = SpawnPrefab("lavaarena_meteor_splashhit")
		splash_base.Transform:SetPosition(x, y, z)
		splash.Transform:SetPosition(x, y, z)
		splashhit.Transform:SetPosition(x, y, z)
		inst:Remove()

		local head = doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
		local mult = head and head.magicdamagemult or 1

		local ents    = TheSim:FindEntities(x,y,z, 4, nil, TUNING.MOD_LAVAARENA.NOTTAGS, TUNING.MOD_LAVAARENA.TAGS)
		local damages = (TUNING.MOD_LAVAARENA.FIREBALLSTAFF.DAMAGES.SPECIAL.MIN + (math.random() + (TUNING.MOD_LAVAARENA.FIREBALLSTAFF.DAMAGES.SPECIAL.MAX - TUNING.MOD_LAVAARENA.FIREBALLSTAFF.DAMAGES.SPECIAL.MIN))) * mult
		for _,v in pairs(ents) do
			if v ~= doer and v.components.combat ~= nil then
				v.components.combat:GetAttacked(doer, damages)
			end
		end
	end)
end

local function fn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddSoundEmitter()
  inst.entity:AddNetwork()

  MakeInventoryPhysics(inst)

  inst.AnimState:SetBank("fireballstaff")
  inst.AnimState:SetBuild("fireballstaff")
  inst.AnimState:PlayAnimation("idle")

  inst:AddTag("staff")
  inst:AddTag("rangedweapon")
  inst:AddTag("firestaff")
  inst:AddTag("pyroweapon")
  inst:AddTag("rechargeable")

  inst:AddComponent("aoetargeting")
  inst.components.aoetargeting.reticule.reticuleprefab = "reticuleaoe"
  inst.components.aoetargeting.reticule.pingprefab = "reticuleaoeping"
  inst.components.aoetargeting.reticule.targetfn = ReticuleTargetFn
  inst.components.aoetargeting.reticule.validcolour = { 1, .75, 0, 1 }
  inst.components.aoetargeting.reticule.invalidcolour = { .5, 0, 0, 1 }
  inst.components.aoetargeting.reticule.ease = true
  inst.components.aoetargeting.reticule.mouseenabled = true

	inst:AddComponent("rechargeable")
	inst.components.rechargeable:SetRechargeTime(TUNING.MOD_LAVAARENA.FIREBALLSTAFF.RECHARGETIME)

	inst.entity:SetPristine()

  if not TheWorld.ismastersim then
    return inst
  end

	inst:AddComponent("aoespell")
	inst.components.aoespell:SetOnCastFn(oncastfn)

  inst.projectiledelay = PROJECTILE_DELAY

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.imagename = "fireballstaff"
	inst.components.inventoryitem.atlasname = "images/inventoryimages/fireballstaff.xml"

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)
	inst.components.equippable.equipstack = false

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(0)
	inst.components.weapon:SetRange(10, 12)
	inst.components.weapon:SetProjectile("fireball_projectile")
	inst.components.weapon:SetOnAttack(onattack)

	MakeHauntableLaunch(inst)

  return inst
end

--------------------------------------------------------------------------

local function castfxfn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddNetwork()

  inst.AnimState:SetBank("fireball_fx")
  inst.AnimState:SetBuild("deer_fire_charge")
  inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
  inst.AnimState:SetLightOverride(1)
  inst.AnimState:SetFinalOffset(-1)

  inst:Hide()

  inst:AddTag("FX")
  inst:AddTag("NOCLICK")

	inst.entity:SetPristine()

  if not TheWorld.ismastersim then
    return inst
  end

  return inst
end

--------------------------------------------------------------------------

return Prefab("fireballstaff", fn, assets, prefabs),
       Prefab("fireball_cast_fx", castfxfn, assets_fx)
