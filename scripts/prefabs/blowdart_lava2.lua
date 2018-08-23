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
	Asset("ANIM", "anim/blowdart_lava2.zip"),
	Asset("ANIM", "anim/swap_blowdart_lava2.zip"),
}

local assets_projectile = {
	Asset("ANIM", "anim/lavaarena_blowdart_attacks.zip"),
}

local PROJECTILE_DELAY = 2 * FRAMES

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

local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_object", "swap_blowdart_lava2", "swap_blowdart_lava2")
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

local function oncastfn(inst, doer, pos, data)
	local damage = inst.components.aoespell:GetAOE()
	local bv = data and data.zs or 0
	if doer.prefab == "willow" then
		bv = bv + 0.2
	end
	local val = damage + (damage * bv)
	local item = SpawnPrefab("blowdart_lava2_projectile_explosive")
	if not item then return end
	item.spawner = doer
	local x1, y1, z1 = inst:GetPosition():Get()
	item.Transform:SetPosition(x1, 0.7, z1)
	local face_pos = pos
	if doer.components.combat.target then
		face_pos = doer.components.combat.target:GetPosition()
	end
	item:ForceFacePoint(face_pos:Get())
	item.Physics:SetMotorVelOverride(40, 0.7, 0)
	item:DoPeriodicTask(.01, function()
		local x, y, z = item.Transform:GetWorldPosition()
		local ents = TheSim:FindEntities(x, 0, z, 1, {"_combat", "_health"}, {"player", "FX", "NOCLICK", "DECOR", "INLIMBO"})
		for k, v in pairs(ents) do
			if v and v ~= doer and not v.components.health:IsDead() then
				local fx = SpawnPrefab("explode_firecrackers")
				fx.Transform:SetPosition(v.Transform:GetWorldPosition())
				fx:ListenForEvent("animover", fx.Remove)
				fx:DoTaskInTime(3, inst.Remove)
				v.components.combat:GetAttacked(item.spawner or item, val, nil, nil, "AOE")
				v.components.combat:BlankOutAttacks(v.components.combat.min_attack_period or 1.5)
				item:Remove()
				return
			end
		end
	end, 0)
	item:DoTaskInTime(0.7, item.Remove)
end

local function fn()
	local inst = CreateEntity()
	
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()
	
	MakeInventoryPhysics(inst)
	
	inst.AnimState:SetBank("blowdart_lava2")
	inst.AnimState:SetBuild("blowdart_lava2")
	inst.AnimState:PlayAnimation("idle")
	
	inst:AddTag("dart")
	inst:AddTag("blowdart")
	inst:AddTag("aoeblowdart_long")
	inst:AddTag("sharp")
	inst:AddTag("rechargeable")
		
	inst.entity:SetPristine()
	
	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("aoetargeting")
	inst.components.aoetargeting:SetAlwaysValid(true)
	inst.components.aoetargeting.reticule.reticuleprefab = "reticulelong"
	inst.components.aoetargeting.reticule.pingprefab = "reticulelongping"
	inst.components.aoetargeting.reticule.targetfn = ReticuleTargetFn
	inst.components.aoetargeting.reticule.mousetargetfn = ReticuleMouseTargetFn
	inst.components.aoetargeting.reticule.updatepositionfn = ReticuleUpdatePositionFn
	inst.components.aoetargeting.reticule.validcolour = {1, .75, 0, 1}
	inst.components.aoetargeting.reticule.invalidcolour = {.5, 0, 0, 1}
	inst.components.aoetargeting.reticule.ease = true
	inst.components.aoetargeting.reticule.mouseenabled = true
	
	inst:AddComponent("rechargeable")
	inst.components.rechargeable:SetRechargeTime(30)

	inst:AddComponent("aoespell")
	inst.components.aoespell:SetOnCastFn(oncastfn)

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(25)
	inst.components.weapon:SetRange(10, 12)
	inst.components.weapon:SetProjectile("blowdart_lava2_projectile")
	
	inst:AddComponent("inspectable")
	
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.imagename = "blowdart_lava2"

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)

	inst.projectiledelay = PROJECTILE_DELAY
	MakeHauntableLaunch(inst)
	
	return inst
end

local tails =
{
	["tail_5_2"] = .15,
	["tail_5_3"] = .15,
	["tail_5_4"] = .2,
	["tail_5_5"] = .8,
	["tail_5_6"] = 1,
	["tail_5_7"] = 1,
}

local thintails =
{
	["tail_5_8"] = 1,
	["tail_5_9"] = .5,
}

local function CreateTail(thintail, isBig)
	local inst = CreateEntity()
	
	inst:AddTag("FX")
	inst:AddTag("NOCLICK")
	
	inst.entity:SetCanSleep(false)
	inst.persists = false
	
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	
	inst.AnimState:SetBank("lavaarena_blowdart_attacks")
	inst.AnimState:SetBuild("lavaarena_blowdart_attacks")
	inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	
	inst.AnimState:PlayAnimation(weighted_random_choice(thintail and thintails or tails) .. (isBig == true and "_large" or ""))
	
	inst:ListenForEvent("animover", inst.Remove)
	
	return inst
end

local function OnUpdateProjectileTail(inst, isBig)
	local c = math.random()
	local tail = CreateTail(inst.thintailcount > 0, isBig)
	tail.Transform:SetPosition(inst.Transform:GetWorldPosition())
	tail.Transform:SetRotation(inst.Transform:GetRotation())
	tail.AnimState:SetTime(c * tail.AnimState:GetCurrentAnimationLength())
	inst.thintailcount = inst.thintailcount - 1
end

local function projectilefn()
	local inst = CreateEntity()
	
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()
	
	MakeInventoryPhysics(inst)
	RemovePhysicsColliders(inst)
	
	inst.AnimState:SetBank("lavaarena_blowdart_attacks")
	inst.AnimState:SetBuild("lavaarena_blowdart_attacks")
	inst.AnimState:PlayAnimation("attack_4")
	inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
	inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	inst.AnimState:SetFinalOffset(-1)
	inst.AnimState:SetAddColour(1, 1, 0, 0)
	
	inst:AddTag("FX")
	inst:AddTag("NOCLICK")
	inst:AddTag("projectile")
	
	if not TheNet:IsDedicated() then
		inst.thintailcount = math.random(3, 4)
		inst:DoPeriodicTask(0, OnUpdateProjectileTail)
	end
	
	inst.entity:SetPristine()
	
	if not TheWorld.ismastersim then
		return inst
	end
	
	inst:AddComponent("projectile")
	inst.components.projectile:SetSpeed(50)
	inst.components.projectile:SetHoming(false)
	inst.components.projectile:SetHitDist(math.sqrt(5))
	inst.components.projectile:SetOnHitFn(inst.Remove)
	inst.components.projectile:SetOnMissFn(inst.Remove)
	inst.components.projectile:SetLaunchOffset(Vector3(0, 1.0, 0))
	inst.components.projectile:SetOnThrownFn(function(inst)
		if inst.alt then
			inst:AddTag("NOCLICK")
		end
		inst:ListenForEvent("entitysleep", inst.Remove)
	end)
	
	-- inst.persists = false
	
	return inst
end

local function projectileexplosivefn()
	local inst = CreateEntity()
	
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()
	
	MakeInventoryPhysics(inst)
	RemovePhysicsColliders(inst)
	
	inst.AnimState:SetBank("lavaarena_blowdart_attacks")
	inst.AnimState:SetBuild("lavaarena_blowdart_attacks")
	inst.AnimState:PlayAnimation("attack_4_large")
	inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
	inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	inst.AnimState:SetFinalOffset(-1)
	inst.AnimState:SetAddColour(1, 1, 0, 0)
	
	inst.Transform:SetScale(0.7, 0.7, 0.7)
	
	inst:AddTag("FX")
	
	if not TheNet:IsDedicated() then
		inst.thintailcount = math.random(3, 4)
		inst:DoPeriodicTask(0, OnUpdateProjectileTail, nil, true)
	end
	
	inst.entity:SetPristine()
	
	if not TheWorld.ismastersim then
		return inst
	end
	
	inst.persists = false
	
	return inst
end

return Prefab("blowdart_lava2", fn, assets),
Prefab("blowdart_lava2_projectile", projectilefn, assets_projectile),
Prefab("blowdart_lava2_projectile_explosive", projectileexplosivefn, assets_projectile)
