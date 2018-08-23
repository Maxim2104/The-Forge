local assets =
{
    Asset("ANIM", "anim/swap_lucy_axe.zip"),
    Asset("ANIM", "anim/swap_lucy_axe.zip"),
}

local function ToggleProjectilePhysics(inst)
    inst.Physics:SetSphere(1)
    --inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
    inst.Physics:CollidesWith(COLLISION.SMALLOBSTACLES)
    --inst.Physics:CollidesWith(COLLISION.CHARACTERS)
    --inst.Physics:CollidesWith(COLLISION.GIANTS)
    --inst.Physics:CollidesWith(COLLISION.FLYERS)
end

local function ToggleItemPhysics(inst)
    inst.Physics:SetSphere(.5)
    --inst.Physics:SetCollisionGroup(COLLISION.ITEMS)
    inst.Physics:ClearCollisionMask()
	inst.Physics:CollidesWith(COLLISION.WORLD)
	inst.Physics:CollidesWith(COLLISION.OBSTACLES)
	inst.Physics:CollidesWith(COLLISION.SMALLOBSTACLES)
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

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_lucy_axe", "swap_lucy_axe")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    if inst.components.sctargeting then
        inst.components.sctargeting:StopTargeting()
    end
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
    if inst:HasTag("lucydone") then return end

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
local function Jump(self, inst, doer, pos)
    if inst == nil or doer == nil or pos == nil then 
        print(("spell %s can not be casted"):format(self.name))
        return false
    end
	
    inst.thrower = doer
    inst.wantsBack = false
    --so, it is here, because I want to handle all spell damage in SpellCast functions
    --It doesn't make anything for now
    if doer.components.combat then
        inst.throwDamage = 20
    end
    inst:MakeProjectile()
    
    --inst.Transform:SetRotation( math.atan2(pos.x - x, pos.z - z) - 1.5707) --/ pi/2
    inst:FacePoint(pos)
    inst.Physics:SetMotorVel(15, 0, 0)
    
    return true
    --lucien call aftercastfn in its prefab
end

local function oncastcast(inst, doer, pos, data)
    local damage = inst.components.aoespell:GetAOE()
    local bv = data and data.zs or 0
    local val = damage + (damage * bv)
    doer.sg:GoToState("throw_line", {
        data = {
            targetpos = pos,
            weapon = inst,
        }})
    inst:MakeProjectile()
    
    --inst.Transform:SetRotation( math.atan2(pos.x - x, pos.z - z) - 1.5707) --/ pi/2
    inst:FacePoint(pos)
    inst.Physics:SetMotorVel(15, 0, 0) 
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.Transform:SetTwoFaced()
    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("lavaarena_lucy")
    inst.AnimState:SetBuild("lavaarena_lucy")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("axe")
    inst:AddTag("lusien")
    inst:AddTag("castingitem")
    
    inst:AddComponent("talker")
    inst.components.talker.fontsize = 35
    inst.components.talker.font = TALKINGFONT
    inst.components.talker.colour = Vector3(111/255, 172/255, 62/255)
    inst.components.talker.offset = Vector3(0, -250, 0)
    inst.components.talker:MakeChatter()

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	
	inst:AddComponent("rechargeable")
	inst.components.rechargeable:SetRechargeTime(3)

	inst:AddComponent("aoespell")
	inst.components.aoespell:SetOnCastFn(oncastcast)
	
    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(20)

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("tool")
    inst.components.tool:SetAction(ACTIONS.CHOP)

    MakeHauntableLaunch(inst)

    inst.MakeInventory = MakeInventory
    inst.MakeProjectile = MakeProjectile
    return inst
end

return Prefab("lavaarena_lucy", fn, assets, prefabs)