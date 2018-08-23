local function GetDamages(inst, attacker, defaultdmg)
	local head = attacker and attacker.components.inventory and attacker.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
	return head and head.magicdamagemult and defaultdmg * head.magicdamagemult or defaultdmg
end

local assets_fireballhit = {
  Asset("ANIM", "anim/fireball_2_fx.zip"),
  Asset("ANIM", "anim/deer_fire_charge.zip"),
}

local assets_blossomhit = {
  Asset("ANIM", "anim/lavaarena_heal_projectile.zip"),
}

local assets_gooballhit = {
  Asset("ANIM", "anim/gooball_fx.zip"),
}

--------------------------------------------------------------------------

local function CreateTail(bank, build, lightoverride, addcolour, multcolour)
  local inst = CreateEntity()

  inst:AddTag("FX")
  inst:AddTag("NOCLICK")
  --[[Non-networked entity]]
  inst.entity:SetCanSleep(false)
  inst.persists = false

  inst.entity:AddTransform()
  inst.entity:AddAnimState()

  MakeInventoryPhysics(inst)
  inst.Physics:ClearCollisionMask()

  inst.AnimState:SetBank(bank)
  inst.AnimState:SetBuild(build)
  inst.AnimState:PlayAnimation("disappear")
  if addcolour ~= nil then
    inst.AnimState:SetAddColour(unpack(addcolour))
  end
  if multcolour ~= nil then
    inst.AnimState:SetMultColour(unpack(multcolour))
  end
  if lightoverride > 0 then
    inst.AnimState:SetLightOverride(lightoverride)
  end
  inst.AnimState:SetFinalOffset(-1)

  inst:ListenForEvent("animover", inst.Remove)

  return inst
end

local function OnUpdateProjectileTail(inst, bank, build, speed, lightoverride, addcolour, multcolour, hitfx, tails)
  local x, y, z = inst.Transform:GetWorldPosition()
  for tail, _ in pairs(tails) do
    tail:ForceFacePoint(x, y, z)
  end
  if inst.entity:IsVisible() then
    local tail = CreateTail(bank, build, lightoverride, addcolour, multcolour)
    local rot = inst.Transform:GetRotation()
    tail.Transform:SetRotation(rot)
    rot = rot * DEGREES
    local offsangle = math.random() * 2 * PI
    local offsradius = math.random() * .2 + .2
    local hoffset = math.cos(offsangle) * offsradius
    local voffset = math.sin(offsangle) * offsradius
    tail.Transform:SetPosition(x + math.sin(rot) * hoffset, y + voffset, z + math.cos(rot) * hoffset)
    tail.Physics:SetMotorVel(speed * (.2 + math.random() * .3), 0, 0)
    tails[tail] = true
    inst:ListenForEvent("onremove", function(tail) tails[tail] = nil end, tail)
    tail:ListenForEvent("onremove", function(inst)
      tail.Transform:SetRotation(tail.Transform:GetRotation() + math.random() * 30 - 15)
    end, inst)
  end
end

local function OnHitFireBallFn(inst, attacker, target)
	if not target:HasTag("dragonfly") then
		target.components.combat:GetAttacked(attacker, GetDamages(inst, attacker, 25))
	end
	inst:Remove()
	local x,y,z = target.Transform:GetWorldPosition()
	local cast = SpawnPrefab("fireball_hit_fx")
	cast.Transform:SetPosition(x,y,z)
	if cast and cast:IsAsleep() then
	    cast:Remove()
	end
end

local function OnHitBlossomFn(inst, attacker, target)
	target.components.combat:GetAttacked(attacker, GetDamages(inst, attacker, 10))
	inst:Remove()
end

local function OnHitGooballFn(inst, attacker, target)
	
end

local function OnThrowFireballFn(inst)
	inst:AddTag("NOCLICK")
	inst:ListenForEvent("entitysleep", inst.Remove)
	local x,y,z = inst.Transform:GetWorldPosition()
	local cast = SpawnPrefab("fireball_cast_fx")
	cast.Transform:SetPosition(x,y,z)
	cast:Show()
	--cast.AnimState:PlayAnimation("pre")
end

local function OnThrowBlossomFn(inst)
	inst:AddTag("NOCLICK")
	inst:ListenForEvent("entitysleep", inst.Remove)
end

local function OnThrowGooballFn(inst)
	inst:AddTag("NOCLICK")
	inst:ListenForEvent("entitysleep", inst.Remove)
end

local function MakeProjectile(name, bank, build, speed, lightoverride, addcolour, multcolour, hitfx, onhitfn, onthrowfn)
  local assets = {
    Asset("ANIM", "anim/"..build..".zip"),
  }

  local prefabs = hitfx ~= nil and { hitfx } or nil

  local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    RemovePhysicsColliders(inst)

    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild(build)
    inst.AnimState:PlayAnimation("idle_loop", true)
    if addcolour ~= nil then
      inst.AnimState:SetAddColour(unpack(addcolour))
    end
    if multcolour ~= nil then
      inst.AnimState:SetMultColour(unpack(multcolour))
    end
    if lightoverride > 0 then
      inst.AnimState:SetLightOverride(lightoverride)
    end
    inst.AnimState:SetFinalOffset(-1)

    inst:AddTag("projectile")

    if not TheNet:IsDedicated() then
      inst:DoPeriodicTask(0, OnUpdateProjectileTail, nil, bank, build, speed, lightoverride, addcolour, multcolour, hitfx, {})
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
      return inst
    end

		inst:AddComponent("projectile")
		inst.components.projectile:SetSpeed(speed)
		inst.components.projectile:SetHoming(true) -- Lock the target and follow it
		inst.components.projectile:SetOnThrownFn(onthrowfn)
		inst.components.projectile:SetOnHitFn(onhitfn)
		inst.components.projectile:SetOnMissFn(inst.Remove)
		inst.components.projectile:SetHitDist(1.5) -- distance before the target is registered "hits" by the projectile
		inst:ListenForEvent("onthrown", function(inst, data)
			inst.AnimState:SetOrientation(ANIM_ORIENTATION.Default)
			if inst.Physics ~= nil and not inst:HasTag("nocollisionoverride") then
				inst.Physics:ClearCollisionMask()
				inst.Physics:CollidesWith(COLLISION.GROUND)
				if TUNING.COLLISIONSAREON then
					inst.Physics:CollidesWith(COLLISION.OBSTACLES)
				end
			end
		end)

    return inst
  end

  return Prefab(name, fn, assets, prefabs)
end

--------------------------------------------------------------------------

local function fireballhit_fn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddSoundEmitter()
  inst.entity:AddNetwork()

  inst.AnimState:SetBank("fireball_fx")
  inst.AnimState:SetBuild("deer_fire_charge")
  inst.AnimState:PlayAnimation("blast")
  inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
  inst.AnimState:SetLightOverride(1)
  inst.AnimState:SetFinalOffset(-1)

  inst:AddTag("FX")
  inst:AddTag("NOCLICK")

  inst.entity:SetPristine()

  if not TheWorld.ismastersim then
    return inst
  end

	inst:ListenForEvent("animover", inst.Remove)
	inst.persists = false

  return inst
end

--------------------------------------------------------------------------

local function blossomhit_fn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddSoundEmitter()
  inst.entity:AddNetwork()

  inst.AnimState:SetBank("lavaarena_heal_projectile")
  inst.AnimState:SetBuild("lavaarena_heal_projectile")
  inst.AnimState:PlayAnimation("hit")
  inst.AnimState:SetAddColour(0, .1, .05, 0)
  inst.AnimState:SetFinalOffset(-1)

  inst:AddTag("FX")
  inst:AddTag("NOCLICK")

  inst.entity:SetPristine()

  if not TheWorld.ismastersim then
    return inst
  end

	inst.persists = false

  return inst
end

--------------------------------------------------------------------------

local function gooballhit_fn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddSoundEmitter()
  inst.entity:AddNetwork()

  inst.AnimState:SetBank("gooball_fx")
  inst.AnimState:SetBuild("gooball_fx")
  inst.AnimState:PlayAnimation("blast")
  inst.AnimState:SetMultColour(.2, 1, 0, 1)
  inst.AnimState:SetFinalOffset(-1)

  inst:AddTag("FX")
  inst:AddTag("NOCLICK")

  inst.entity:SetPristine()

  if not TheWorld.ismastersim then
    return inst
  end

	inst.persists = false

  return inst
end

--------------------------------------------------------------------------

return MakeProjectile("fireball_projectile", "fireball_fx", "fireball_2_fx", 15, 1, nil, nil, "fireball_hit_fx", OnHitFireBallFn, OnThrowFireballFn),
       MakeProjectile("blossom_projectile", "lavaarena_heal_projectile", "lavaarena_heal_projectile", 15, 0, { 0, .2, .1, 0 }, nil, "blossom_hit_fx", OnHitBlossomFn, OnThrowBlossomFn),
       MakeProjectile("gooball_projectile", "gooball_fx", "gooball_fx", 20, 0, nil, { .2, 1, 0, 1 }, "gooball_hit_fx", OnHitGooballFn, OnThrowGooballFn),
       Prefab("fireball_hit_fx", fireballhit_fn, assets_fireballhit),
       Prefab("blossom_hit_fx", blossomhit_fn, assets_blossomhit),
       Prefab("gooball_hit_fx", gooballhit_fn, assets_gooballhit)
