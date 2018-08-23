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
	Asset("ANIM", "anim/blowdart_lava.zip"),
	Asset("ANIM", "anim/swap_blowdart_lava.zip"),
}

local assets_projectile = {
	Asset("ANIM", "anim/lavaarena_blowdart_attacks.zip"),
}

local prefabs = {
	"blowdart_lava_projectile",
	"blowdart_lava_projectile_alt",
	"reticulelongmulti",
	"reticulelongmultiping",
}

local prefabs_projectile = {
	"weaponsparks_piercing",
}

local PROJECTILE_DELAY = 2 * FRAMES

--------------------------------------------------------------------------

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
	owner.AnimState:OverrideSymbol("swap_object", "swap_blowdart_lava", "swap_blowdart_lava")
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



	local val = damage + (damage * bv)
	local op = inst:GetPosition()
	local function c(doer, pt, pos)
		local item = SpawnPrefab("blowdart_lava_projectile")
		if not item then return end
		item.spawner = doer
		local x1, y1, z1 = pt:Get()
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
					local fx = SpawnPrefab("weaponsparks")
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
	for i = 2, -2, -1 do
		local angle = 90
		local pt1 = Vector3(op.x + math.cos(angle) * 0.2 * i, 0, op.z - math.sin(angle) * 0.2 * i)
		local pt = Vector3(pos.x + math.cos(angle) * 0.2 * i, 0, pos.z - math.sin(angle) * 0.2 * i)
		doer:DoTaskInTime(math.random() * 0.3, c, pt1, pt)
	end
end

local function fn()
	local inst = CreateEntity()
	
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()
	
	MakeInventoryPhysics(inst)
	
	inst.AnimState:SetBank("blowdart_lava")
	inst.AnimState:SetBuild("blowdart_lava")
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
	inst.components.aoetargeting.reticule.reticuleprefab = "reticulelongmulti"
	inst.components.aoetargeting.reticule.pingprefab = "reticulelongmultiping"
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
	inst.components.weapon:SetDamage(20)
	inst.components.weapon:SetRange(10, 12)
	inst.components.weapon:SetProjectile("blowdart_lava_projectile")
	
	inst:AddComponent("inspectable")
	
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.imagename = "blowdart_lava"
	
	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)
	
	inst.projectiledelay = PROJECTILE_DELAY
	MakeHauntableLaunch(inst)
	
	return inst
end

--------------------------------------------------------------------------

local FADE_FRAMES = 5

local function CreateTail()
	local inst = CreateEntity()
	
	inst:AddTag("FX")
	inst:AddTag("NOCLICK")
	--[[Non-networked entity]]
	inst.entity:SetCanSleep(false)
	inst.persists = false
	
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	
	inst.AnimState:SetBank("lavaarena_blowdart_attacks")
	inst.AnimState:SetBuild("lavaarena_blowdart_attacks")
	inst.AnimState:PlayAnimation("tail_1")
	inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	
	inst:ListenForEvent("animover", inst.Remove)
	
	return inst
end

local function OnUpdateProjectileTail(inst)
	local c = (not inst.entity:IsVisible() and 0) or (inst._fade ~= nil and (FADE_FRAMES - inst._fade:value() + 1) / FADE_FRAMES) or 1
	if c > 0 then
		local tail = CreateTail()
		tail.Transform:SetPosition(inst.Transform:GetWorldPosition())
		tail.Transform:SetRotation(inst.Transform:GetRotation())
		if c < 1 then
			tail.AnimState:SetTime(c * tail.AnimState:GetCurrentAnimationLength())
		end
	end
end

local function OnHitNormalFn(inst, attacker, target)
	target.components.combat:GetAttacked(attacker, 20)
	inst:Remove()
end

local function OnHitAltFn(inst, attacker, target)
	inst:Remove()
end

local function commonprojectilefn(alt)
	local inst = CreateEntity()
	
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()
	
	inst.alt = alt
	
	MakeInventoryPhysics(inst)
	RemovePhysicsColliders(inst)
	
	inst.AnimState:SetBank("lavaarena_blowdart_attacks")
	inst.AnimState:SetBuild("lavaarena_blowdart_attacks")
	inst.AnimState:PlayAnimation("attack_3", true)
	inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	inst.AnimState:SetAddColour(1, 1, 0, 0)
	inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
	
	inst:AddTag("projectile")
	
	if not TheNet:IsDedicated() then
		inst:DoPeriodicTask(0, OnUpdateProjectileTail)
	end
	
	if alt then
		inst._fade = net_tinybyte(inst.GUID, "blowdart_lava_projectile_alt._fade")
	end
	
	inst.entity:SetPristine()
	
	if not TheWorld.ismastersim then
		return inst
	end
	
	inst:AddComponent("projectile")
	inst.components.projectile:SetSpeed(50)
	inst.components.projectile:SetHoming(not inst.alt)
	inst.components.projectile:SetHitDist(math.sqrt(5))
	inst.components.projectile:SetOnHitFn(inst.alt and OnHitAltFn or OnHitNormalFn)
	inst.components.projectile:SetOnMissFn(inst.Remove)
	inst.components.projectile:SetLaunchOffset(Vector3(0, 1.0, 0))
	inst.components.projectile:SetOnThrownFn(function(inst)
		if inst.alt then
			print('alt')
			inst:AddTag("NOCLICK")
		end
		inst:ListenForEvent("entitysleep", inst.Remove)
	end)

	return inst
end

local function projectilefn()
	return commonprojectilefn(false)
end

local function projectilealtfn()
	return commonprojectilefn(true)
end

return Prefab("blowdart_lava", fn, assets, prefabs),
Prefab("blowdart_lava_projectile", projectilefn, assets_projectile, prefabs_projectile),
Prefab("blowdart_lava_projectile_alt", projectilealtfn, assets_projectile, prefabs_projectile)
