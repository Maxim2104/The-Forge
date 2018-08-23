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

--------------------------------------------------------------------------oncastcast

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

local function LucienGoesAway(inst)
    if inst.components.inventoryitem:IsHeld() then
        inst.components.inventoryitem.owner.components.inventory:DropItem(inst)
    end

    RemovePhysicsColliders(inst)
    inst:AddTag("NOCLICK")
    inst:AddTag("luciendone")
    inst:RemoveComponent("inventoryitem")

    inst.components.talker:Say(STRINGS.LUCIEN_AXE_ON_DONE[math.random(#(STRINGS.LUCIEN_AXE_ON_DONE))])

    inst.persists = false
    inst:DoTaskInTime(2, function() ErodeAway(inst, 2) end)
end

local function AfterBounce(inst)
    inst:RemoveEventCallback("animover", AfterBounce)
    if inst:HasTag("luciendone") then return end

    if not inst:IsOnValidGround() then
        local splash = SpawnPrefab("splash_ocean")
        if splash ~= nil then
            splash.Transform:SetPosition(inst.Transform:GetWorldPosition())
        end
        inst:Remove()
    else
        local thrower = inst.thrower
        if inst.components.inventoryitem ~= nil 
            and not inst.components.inventoryitem:IsHeld() --someone can pick it before
            and inst.wantsBack --back only after hit
            and thrower ~= nil --thrower should be valid, alive and with inventory
            and thrower:IsValid()
            and not thrower.components.health:IsDead()
            and thrower.components.inventory ~= nil 
        then 
            SpawnPrefab("small_puff").Transform:SetPosition(inst.Transform:GetWorldPosition())
            
            local currEquip = thrower.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if currEquip ~= nil then
                thrower.components.inventory:DropItem(currEquip)
            end
            thrower.components.inventory:Equip(inst)
        end
        inst.thrower = nil
        inst.wantsBack = false
    end
end

local function DoCollide(inst, other)
    if other.components.combat ~= nil then
        other.components.combat:GetAttacked(inst.thrower, inst.throwDamage)
    elseif other.components.workable ~= nil
        and other.components.workable:CanBeWorked() 
        and not (other.sg ~= nil and other.sg:HasStateTag("busy"))
        and other.components.workable:GetWorkAction() == ACTIONS.CHOP 
        and inst.thrower ~= nil
    then
        other.components.workable:WorkedBy(inst.thrower, 5)
    end
    --need to set it back
    inst.throwDamage = TUNING.CCW.SPELL.THROWLUCIEN.THROWDAMAGE
    inst.wantsBack = true

    inst:PushEvent("schackprojevent", {target = other, owner = inst.thrower})
    
    inst:MakeInventory()
    inst.spell:aftercastfn(inst, inst.thrower or inst)
end

--we can't collect the callback from collides with creatures
--because there is a problem with COLLISION.FLYERS
local function CheckForVictim(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    for k, v in pairs (TheSim:FindEntities(x, y, z, 3, {}, { "playerghost", "shadow", "INLIMBO", "FX", "NOCLICK" })) do
        if v.components.combat ~= nil 
            and v ~= inst.thrower
            and inst:GetDistanceSqToInst(v) <= v:GetPhysicsRadius(0) * v:GetPhysicsRadius(0) + 1
            and not (v:HasTag("player") and not TheNet:GetPVPEnabled())
        then
            DoCollide(inst, v)
            break
        end
    end
end

local function MakeProjectile(inst)
    inst.Transform:SetSixFaced()
    inst.AnimState:PlayAnimation("spin_loop", true)

    if inst.components.inventoryitem:IsHeld() then
        inst.components.inventoryitem.owner.components.inventory:DropItem(inst)
    end

    ToggleProjectilePhysics(inst)
    inst.Physics:SetCollisionCallback(DoCollide)
    inst:AddTag("NOCLICK")
    --inst:RemoveComponent("inventoryitem")
    inst.replica.inventoryitem:SetCanBePickedUp(false)

    inst._vtask = inst:DoPeriodicTask(0.1, CheckForVictim)
    inst._ftask = inst:DoTaskInTime(1.5, inst.MakeInventory)
end

local function MakeInventory(inst, noanim)
    if inst._ftask ~= nil then
        inst._ftask:Cancel()
        inst._ftask = nil
    end
    if inst._vtask ~= nil then
        inst._vtask:Cancel()
        inst._vtask = nil
    end
    if not inst.wantsBack then
        inst.components.talker:Say(STRINGS.LUCIEN_AXE_MISS[math.random(#(STRINGS.LUCIEN_AXE_MISS))])
    elseif math.random() < 0.08 then
        inst.components.talker:Say(STRINGS.LUCIEN_AXE_HIT[math.random(#(STRINGS.LUCIEN_AXE_HIT))])
    end
    inst.Physics:SetCollisionCallback(nil)
    inst:RemoveTag("NOCLICK")
    inst.Transform:SetTwoFaced()
    inst.Physics:Stop()
    ToggleItemPhysics(inst)
    if not noanim then
        local ang = (inst.Transform:GetRotation() - 180) * DEGREES
        local x, y, z = inst.Transform:GetWorldPosition()
        inst.Physics:Teleport(x, 1.5, z)
        inst.Physics:SetVel(math.cos(ang) * 2, 4, -math.sin(ang) * 2)
    end
    inst.AnimState:PlayAnimation("bounce")
    inst.AnimState:PushAnimation("idle", true)

    inst.replica.inventoryitem:SetCanBePickedUp(true)

    inst:ListenForEvent("animover", AfterBounce)

--[[     inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "lucien_axe"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/lucien_axe.xml" ]]
end

local function OnEnchanted(inst, data)
    inst.components.talker:Say(STRINGS.LUCIEN_AXE_ENCHANT[math.random(#(STRINGS.LUCIEN_AXE_ENCHANT))])
    --if inst.components.sceffectable then
        --inst.components.sceffectable:RemoveEffectsByTag("enchant")
    --end
end

local function GetDebugString(inst)
    return(string.format("thrower: %s, wants back: %s, vtask: %s, ftask: %s", 
        tostring(inst.thrower), tostring(inst.wantsBack), tostring(inst._vtask), tostring(inst._ftask)))
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

local function oncastcast(self, inst, doer, pos)
    if inst == nil or doer == nil or pos == nil then 
        print(("spell %s can not be casted"):format(self.name))
        return false
    end

    local x, y, z = doer.Transform:GetWorldPosition()
    local angle = doer.Transform:GetRotation()

    inst.thrower = doer
    inst.wantsBack = false
    --so, it is here, because I want to handle all spell damage in SpellCast functions
    --It doesn't make anything for now
    if doer.components.combat then
        inst.throwDamage = TUNING.CCW.SPELL.THROWLUCIEN.THROWDAMAGE * doer.components.combat:GetDamageMods()
    else
        inst.throwDamage = TUNING.CCW.SPELL.THROWLUCIEN.THROWDAMAGE
    end
    inst:MakeProjectile()
    
    --inst.Transform:SetRotation( math.atan2(pos.x - x, pos.z - z) - 1.5707) --/ pi/2
    inst:FacePoint(pos)
    inst.Physics:SetMotorVel(15, 0, 0)
    
    return true
    --lucien call aftercastfn in its prefab
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
