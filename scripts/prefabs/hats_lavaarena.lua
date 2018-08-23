local function SetCooldownBonus(inst, owner)
	local armor = owner.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
	local head  = owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
	local hand  = owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HAND)
	
	local bonus = (armor and armor.cooldownbonus or 0) + (head and head.cooldownbonus or 0)
	if hand and hand.components.rechargeable then
		hand.components.rechargeable:SetBonus(bonus)
	end
end

local function onequip(inst, owner) 
	owner.AnimState:OverrideSymbol("swap_hat", inst.hat, "swap_hat")
	owner.AnimState:Show("HAT")
  owner.AnimState:Show("HAIR_HAT")
	if inst.ishelm then
		owner.AnimState:Hide("HAIR_NOHAT")
		owner.AnimState:Hide("HAIR")
		if owner:HasTag("player") then
			owner.AnimState:Hide("HEAD")
			owner.AnimState:Show("HEAD_HAT")
		end
  end
	
	if inst.regentask then
		if owner.components.health:GetPercent() < .8 then
			owner.components.health:StartRegen(2, 1, false)
		else
			owner.components.health:StopRegen()
		end
	end
	
	SetCooldownBonus(inst, owner)
end

local function onunequip(inst, owner) 
	owner.AnimState:ClearOverrideSymbol("swap_hat")
	owner.AnimState:Hide("HAT")
  owner.AnimState:Hide("HAIR_HAT")
  owner.AnimState:Show("HAIR_NOHAT")
  owner.AnimState:Show("HAIR")

  if owner:HasTag("player") then
     owner.AnimState:Show("HEAD")
    owner.AnimState:Hide("HEAD_HAT")
  end
	
	if inst.regentask then
		owner.components.health:StopRegen()
	end
	
	SetCooldownBonus(inst, owner)
end

local function MakeHat(name, data)
  local symbol = name.."hat"
	local fullname = "lavaarena_"..name.."hat"
		
  local assets = {
    Asset("ANIM", "anim/"..data.hat..".zip"),
  }

  local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

		inst.hat = data.hat
		inst.regentask = data.regentask or false
		inst.magicdamagemult = data.magicdamagemult or 1
		inst.cooldownreduc   = data.cooldownreduc or 0
		inst.healdealtmult   = data.healdealtmult or 1
		inst.healreceivemult = data.healreceivemult or 1
		inst.ishelm          = data.ishelm or false

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank(symbol)
    inst.AnimState:SetBuild(data.hat)
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("hat")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
      return inst
    end

		inst:AddComponent("inventoryitem")
		inst.components.inventoryitem.imagename = fullname
		inst.components.inventoryitem.atlasname = "images/inventoryimages/"..fullname..".xml"

		inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
		if data.movespeedmult ~= nil then
			inst.components.equippable.walkspeedmult = data.movespeedmult
		end

		if data.damagemult ~= nil then
			inst:AddComponent("damagereflect")
			inst.components.damagereflect:SetDefaultDamage(data.damagemult)
		end

		MakeHauntableLaunch(inst)

    return inst
  end

  return Prefab(fullname, fn, assets)
end

return MakeHat("feathercrown", {
	movespeedmult = 1.2,
	hat = "hat_feathercrown"
}),
MakeHat("lightdamager", {
	damagemult = 1.1,
	hat = "hat_lightdamager",
	ishelm = true
}),
MakeHat("recharger", {
	cooldownreduc = 1.1,
	hat = "hat_recharger"
}),
MakeHat("healingflower", {
	healreceivemult = 1.2,
	hat = "hat_healingflower"
}),
MakeHat("tiaraflowerpetals", {
	healdealtmult = 1.2,
	hat = "hat_tiaraflowerpetals"
}),
MakeHat("strongdamager", {
  damagemult = 1.15,
	hat = "hat_strongdamager",
	ishelm = true
}),
MakeHat("crowndamager", {
	damagemult    = 1.15,
	cooldownreduc = 1.1,
  movespeedmult = 1.1,
	hat = "hat_crowndamager",
	ishelm = true
}),
MakeHat("healinggarland", {
	regentask     = true,
	cooldownreduc = 1.1,
	movespeedmult = 1.1,
	hat = "hat_healinggarland"
}),
MakeHat("eyecirclet", {
	magicdamagemult = 1.25,
	cooldownreduc   = 1.1,
	movespeedmult   = 1.1,
	hat = "hat_eyecirclet"
})
