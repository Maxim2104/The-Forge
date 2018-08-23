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
  Asset("ANIM", "anim/healingstaff.zip"),
  Asset("ANIM", "anim/swap_healingstaff.zip"),
}

local assets_fx = {
  Asset("ANIM", "anim/lavaarena_heal_projectile.zip"),
}

local prefabs = {
  "blossom_projectile",
  "blossom_cast_fx",
  "lavaarena_healblooms",
  "reticuleaoe",
  "reticuleaoeping",
  "reticuleaoefriendlytarget",
}

local PROJECTILE_DELAY = 4 * FRAMES

--------------------------------------------------------------------------

local TICK_PERIOD = .5

local TICK_VALUE = 10
local MAX_SLEEP_TIME = 5
local MIN_SLEEP_TIME = 1.5

local PLAYER_TICK_VALUE = 1
local PLAYER_MAX_SLEEP_TIME = 4
local PLAYER_MIN_SLEEP_TIME = 1

local ATTACK_SLEEP_DELAY = 2
local CHAIN_SLEEP_DELAY = 4

local OVERLAY_COORDS =
{
    { 0,0,0,               1 },
    { 5/2,0,0,             0.8, 0 },
    { 2.5/2,0,-4.330/2,    0.8 , 5/3*180 },
    { -2.5/2,0,-4.330/2,   0.8, 4/3*180 },
    { -5/2,0,0,            0.8, 3/3*180 },
    { 2.5/2,0,4.330/2,     0.8, 1/3*180 },
    { -2.5/2,0,4.330/2,    0.8, 2/3*180 },
}

local function SpawnOverlayFX(inst, i, set, isnew)
    if i ~= nil then
        inst._overlaytasks[i] = nil
        if next(inst._overlaytasks) == nil then
            inst._overlaytasks = nil
        end
    end

    local fx = SpawnPrefab("sleepcloud_overlay")
    fx.entity:SetParent(inst.entity)
    fx.Transform:SetPosition(set[1] * .85, 0, set[3] * .85)
    fx.Transform:SetScale(set[4], set[4], set[4])
    if set[5] ~= nil then
        fx.Transform:SetRotation(set[4])
    end

    if not isnew then
        fx.AnimState:PlayAnimation("sleepcloud_overlay_loop")
        fx.AnimState:SetTime(math.random() * .7)
    end

    if inst._overlayfx == nil then
        inst._overlayfx = { fx }
    else
        table.insert(inst._overlayfx, fx)
    end
end

local function OnStateDirty(inst)
    if inst._state:value() > 0 then
        if inst._inittask ~= nil then
            inst._inittask:Cancel()
            inst._inittask = nil
        end
        if inst._state:value() == 1 then
            if inst._basefx == nil then
                inst._basefx = CreateBase(false)
                inst._basefx.entity:SetParent(inst.entity)
            end
        elseif inst._basefx ~= nil then
            inst._basefx.AnimState:PlayAnimation("sporecloud_base_pst")
        end
    end
end

local function DoDisperse(inst)
    if inst._inittask ~= nil then
        inst._inittask:Cancel()
        inst._inittask = nil
    end

    if inst._drowsytask ~= nil then
        inst._drowsytask:Cancel()
        inst._drowsytask = nil
    end

    inst:RemoveEventCallback("animover", OnAnimOver)
    inst._state:set(2)

    inst.AnimState:PlayAnimation("sleepcloud_pst")
    inst.SoundEmitter:KillSound("spore_loop")
    inst.persists = false
    inst:DoTaskInTime(3, inst.Remove) --anim len + 1.5 sec

    if inst._basefx ~= nil then
        inst._basefx.AnimState:PlayAnimation("sporecloud_base_pst")
    end

    if inst._overlaytasks ~= nil then
        for k, v in pairs(inst._overlaytasks) do
            v:Cancel()
        end
        inst._overlaytasks = nil
    end
    if inst._overlayfx ~= nil then
        for i, v in ipairs(inst._overlayfx) do
            v:DoTaskInTime(i == 1 and 0 or math.random() * .5, KillOverlayFX)
        end
    end
end

local function OnTimerDone(inst, data)
    if data.name == "disperse" then
        DoDisperse(inst)
    end
end

local function OnLoad(inst, data)
    --Not a brand new cloud, cancel initial sound and pre-anims
    if inst._inittask ~= nil then
        inst._inittask:Cancel()
        inst._inittask = nil
    end

    inst:RemoveEventCallback("animover", OnAnimOver)

    if inst._overlaytasks ~= nil then
        for k, v in pairs(inst._overlaytasks) do
            v:Cancel()
        end
        inst._overlaytasks = nil
    end
    if inst._overlayfx ~= nil then
        for i, v in ipairs(inst._overlayfx) do
            v:Remove()
        end
        inst._overlayfx = nil
    end

    local t = inst.components.timer:GetTimeLeft("disperse")
    if t == nil or t <= 0 then
        if inst._drowsytask ~= nil then
            inst._drowsytask:Cancel()
            inst._drowsytask = nil
        end
        inst._state:set(2)
        inst.SoundEmitter:KillSound("spore_loop")
        inst:Hide()
        inst.persists = false
        inst:DoTaskInTime(0, inst.Remove)
    else
        inst._state:set(1)
        inst.AnimState:PlayAnimation("sleepcloud_loop", true)

        --Dedicated server does not need to spawn the local fx
        if not TheNet:IsDedicated() then
            inst._basefx = CreateBase(false)
            inst._basefx.entity:SetParent(inst.entity)
        end

        for i, v in ipairs(OVERLAY_COORDS) do
            SpawnOverlayFX(inst, nil, v, false)
        end
    end
end

local function InitFX(inst)
    inst._inittask = nil

    --Dedicated server does not need to spawn the local fx
    if not TheNet:IsDedicated() then
        inst._basefx = CreateBase(true)
        inst._basefx.entity:SetParent(inst.entity)
    end
end

local function ReticuleTargetFn()
  local player = ThePlayer
  local ground = TheWorld.Map
  local pos = Vector3()
  --Cast range is 8, leave room for error
  --4 is the aoe range
  --Walk a tiny distance into healing range
  for r = 6, 0, -.25 do
    pos.x, pos.y, pos.z = player.entity:LocalToWorldSpace(r, 0, 0)
    if ground:IsPassableAtPoint(pos:Get()) and not ground:IsGroundTargetBlocked(pos) then
      return pos
    end
  end
  return pos
end

local function onequip(inst, owner) 
	owner.AnimState:OverrideSymbol("swap_object", "swap_healingstaff", "swap_healingstaff")
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

local function createBloom()
	local i = math.ceil(math.random() * 6)
	return {prefab = SpawnPrefab("lavaarena_bloom"..i), t = i}
end

local function AreaMobSleep(inst, doer, pos)
	local ents = TheSim:FindEntities(pos.x,pos.y,pos.z, 4, nil, "follower", "playerghost", "smallcreature", "monster", "hostile", "animal", "pig", "largecreature", "tentacle_pillar", "walrus")
	for _,v in pairs(ents) do
		if v ~= doer and v.components.sleeper ~= nil and not v.components.sleeper:IsAsleep() then
			v.components.sleeper:GoToSleep(10)
		end
	end
end
local function DoDisperse(inst)
    if inst._inittask ~= nil then
        inst._inittask:Cancel()
        inst._inittask = nil
    end

    if inst._drowsytask ~= nil then
        inst._drowsytask:Cancel()
        inst._drowsytask = nil
    end

    inst:RemoveEventCallback("animover", OnAnimOver)
    inst._state:set(2)

    inst.AnimState:PlayAnimation("sleepcloud_pst")
    inst.SoundEmitter:KillSound("spore_loop")
    inst.persists = false
    inst:DoTaskInTime(3, inst.Remove) --anim len + 1.5 sec

    if inst._basefx ~= nil then
        inst._basefx.AnimState:PlayAnimation("sporecloud_base_pst")
    end

    if inst._overlaytasks ~= nil then
        for k, v in pairs(inst._overlaytasks) do
            v:Cancel()
        end
        inst._overlaytasks = nil
    end
    if inst._overlayfx ~= nil then
        for i, v in ipairs(inst._overlayfx) do
            v:DoTaskInTime(i == 1 and 0 or math.random() * .5, KillOverlayFX)
        end
    end
end
local function oncastfn(inst, doer, pos, sleeptimecache, sleepdelaycache)
	local x, y, z = inst.Transform:GetWorldPosition()

	local head = doer and doer.components.inventory and doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD) or nil
	local mult = head and head.healdealtmult or 1
	
	--local healbuf = SpawnPrefab("lavaarena_bloomhealbuff")
	local blooms = {}
	local centerbloom = createBloom()
	table.insert(blooms, centerbloom)
	centerbloom.prefab.Transform:SetPosition(pos.x, pos.y, pos.z)
	--centerbloom.prefab:AddChild(healbuf)
	centerbloom.prefab:AddComponent('healthaura')
	centerbloom.prefab.components.healthaura.aura = (5 * mult * 10) / (33.5 * 10)

	for i=1,5 do
		local bloom = createBloom()
		table.insert(blooms, bloom)
		bloom.prefab.Transform:SetPosition(pos.x + 1.8 * math.cos(math.rad(i * 72)), pos.y, pos.z + 1.8 * math.sin(math.rad(i * 72)))
	end
	
	for i=1,9 do
		local bloom = createBloom()
		table.insert(blooms, bloom)
		bloom.prefab.Transform:SetPosition(pos.x + 3.7 * math.cos(math.rad(i * 40)), pos.y, pos.z + 3.7 * math.sin(math.rad(i * 40)))
	end
    local range = 3.5

    local ents =
        TheNet:GetPVPEnabled() and
        TheSim:FindEntities(pos.x, pos.y, pos.z, range, nil, { "playerghost", "FX", "DECOR", "INLIMBO" }, { "sleeper", "player" }) or
        TheSim:FindEntities(pos.x, pos.y, pos.z, range, { "sleeper" }, { "player", "FX", "DECOR", "INLIMBO" })
    for i, v in ipairs(ents) do
        local delayed = false
        if (sleepdelaycache[v] or 0) > TICK_PERIOD then
            if v.components.sleeper ~= nil then
                if not v.components.sleeper:IsAsleep() then
                    sleepdelaycache[v] = sleepdelaycache[v] - TICK_PERIOD
                    delayed = true
                end
            elseif v.components.grogginess ~= nil
                and not v.components.grogginess:IsKnockedOut() then
                sleepdelaycache[v] = sleepdelaycache[v] - TICK_PERIOD
                delayed = true
            end
        end
        if not delayed and
            not (v.components.combat ~= nil and v.components.combat:GetLastAttackedTime() + ATTACK_SLEEP_DELAY > t) and
            not (v.components.burnable ~= nil and v.components.burnable:IsBurning()) and
            not (v.components.freezable ~= nil and v.components.freezable:IsFrozen()) and
            not (v.components.pinnable ~= nil and v.components.pinnable:IsStuck()) and
            not (v.components.fossilizable ~= nil and v.components.fossilizable:IsFrozen()) then
            local mount = v.components.rider ~= nil and v.components.rider:GetMount() or nil
            if mount ~= nil then
                mount:PushEvent("ridersleep", { sleepiness = TICK_VALUE, sleeptime = MAX_SLEEP_TIME })
            end
            if v.components.sleeper ~= nil then
                local sleeptime = sleeptimecache[v] or MAX_SLEEP_TIME
                v.components.sleeper:AddSleepiness(TICK_VALUE, sleeptime / v.components.sleeper:GetSleepTimeMultiplier())
                if v.components.sleeper:IsAsleep() then
                    sleeptimecache[v] = math.max(MIN_SLEEP_TIME, sleeptime - TICK_PERIOD)
                    sleepdelaycache[v] = CHAIN_SLEEP_DELAY
                else
                    sleeptimecache[v] = nil
                end
            elseif v.components.grogginess ~= nil then
                local sleeptime = sleeptimecache[v] or PLAYER_MAX_SLEEP_TIME
                if v.components.grogginess:IsKnockedOut() then
                    v.components.grogginess:ExtendKnockout(sleeptime)
                    sleeptimecache[v] = math.max(PLAYER_MIN_SLEEP_TIME, sleeptime - TICK_PERIOD)
                    sleepdelaycache[v] = CHAIN_SLEEP_DELAY
                else
                    v.components.grogginess:AddGrogginess(PLAYER_TICK_VALUE, sleeptime)
                    if v.components.grogginess:IsKnockedOut() then
                        sleeptimecache[v] = math.max(PLAYER_MIN_SLEEP_TIME, sleeptime - TICK_PERIOD)
                        sleepdelaycache[v] = CHAIN_SLEEP_DELAY
                    else
                        sleeptimecache[v] = nil
                    end
                end
            else
                v:PushEvent("knockedout")
            end
        else
            sleeptimecache[v] = nil
        end
    end
end

local function fn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddSoundEmitter()
  inst.entity:AddNetwork()

  MakeInventoryPhysics(inst)

  inst.AnimState:SetBank("healingstaff")
  inst.AnimState:SetBuild("healingstaff")
  inst.AnimState:PlayAnimation("idle")

	inst:AddTag("staff")
  inst:AddTag("rangedweapon")
  inst:AddTag("rechargeable")

	inst:AddComponent("aoetargeting")
  inst.components.aoetargeting.reticule.reticuleprefab = "reticuleaoe"
  inst.components.aoetargeting.reticule.pingprefab = "reticuleaoeping"
  inst.components.aoetargeting.reticule.targetfn = ReticuleTargetFn
  inst.components.aoetargeting.reticule.validcolour = { 0, 1, .5, 1 }
  inst.components.aoetargeting.reticule.invalidcolour = { 0, .4, 0, 1 }
  inst.components.aoetargeting.reticule.ease = true
  inst.components.aoetargeting.reticule.mouseenabled = true

	inst:AddComponent("rechargeable")
	inst.components.rechargeable:SetRechargeTime(30)

	inst.entity:SetPristine()

  if not TheWorld.ismastersim then
    return inst
  end
    inst:AddComponent("timer")
    inst.components.timer:StartTimer("disperse", TUNING.SLEEPBOMB_DURATION)
	
	inst:AddComponent("aoespell")
	inst.components.aoespell:SetOnCastFn(oncastfn)

  inst.projectiledelay = PROJECTILE_DELAY

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.imagename = "healingstaff"
	inst.components.inventoryitem.atlasname = "images/inventoryimages/healingstaff.xml"

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)
	inst.components.equippable.equipstack = false

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(0)
	inst.components.weapon:SetRange(10, 12)
	inst.components.weapon:SetProjectile("blossom_projectile")
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

  inst.AnimState:SetBank("lavaarena_heal_projectile")
  inst.AnimState:SetBuild("lavaarena_heal_projectile")
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

return Prefab("healingstaff", fn, assets, prefabs),
       Prefab("blossom_cast_fx", castfxfn, assets_fx)
