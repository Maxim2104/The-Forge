local function SetCooldownBonus(inst, owner)
	local armor = owner.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
	local head  = owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
	local hand  = owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HAND)
	
	local bonus = (armor and armor.cooldownbonus or 0) + (head and head.cooldownbonus or 0)
	if hand and hand.components.rechargeable then
		hand.components.rechargeable:SetBonus(bonus)
	end
end

local function OnBlocked(owner)
	owner.SoundEmitter:PlaySound("dontstarve/wilson/hit_armour")
end

local function g_onequip(inst, owner)
  owner.AnimState:OverrideSymbol("swap_body", inst.armor, "swap_body")
	inst:ListenForEvent("blocked", OnBlocked, owner)
	SetCooldownBonus(inst, owner)
end

local function g_onunequip(inst, owner)
	owner.AnimState:ClearOverrideSymbol("swap_body")
  inst:RemoveEventCallback("blocked", OnBlocked, owner)
	SetCooldownBonus(inst, owner)
end

local function MakeArmour(name, data)
  local assets = {
    Asset("ANIM", "anim/"..data.armor..".zip"),
  }
	
  local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
		
		inst.armor = data.armor
		inst.cooldownreduc = data.cooldownreduc or 0

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank(data.armor)
    inst.AnimState:SetBuild(data.armor)
    inst.AnimState:PlayAnimation("anim")

    for i, v in ipairs(data.tags) do
      inst:AddTag(v)
    end
    inst:AddTag("hide_percentage")

    inst.foleysound = data.foleysound

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
      return inst
    end

		inst:AddComponent("inspectable")

		inst:AddComponent("inventoryitem")
		inst.components.inventoryitem.imagename = name
		inst.components.inventoryitem.atlasname = "images/inventoryimages/"..name..".xml"

		inst:AddComponent("armor")
		inst.components.armor:InitIndestructible(data.absorption)

		inst:AddComponent("equippable")
		inst.components.equippable.equipslot = EQUIPSLOTS.BODY
		inst.components.equippable:SetOnEquip(g_onequip)
		inst.components.equippable:SetOnUnequip(g_onunequip)
		if data.speedmult ~= nil then
			inst.components.equippable.walkspeedmult = data.speedmult
		end

		if data.damagemult ~= nil then
			inst:AddComponent("damagereflect")
			inst.components.damagereflect:SetDefaultDamage(data.damagemult)
		end

		MakeHauntableLaunch(inst)

    return inst
  end

  return Prefab(name, fn, assets)
end

local armors = {}
for k, v in pairs({
  ["lavaarena_armorlight"] = {
    armor = "armor_light",
    tags = { "grass" },
    foleysound = "dontstarve/movement/foley/grassarmour",
		absorption = .5,
		cooldownreduc = 0.05
  },
  ["lavaarena_armorlightspeed"] = {
    armor = "armor_lightspeed",
    tags = { "grass" },
    foleysound = "dontstarve/movement/foley/grassarmour",
		absorption = .6,
		speedmult  = 1.1,
  },
  ["lavaarena_armormedium"] = {
    armor = "armor_medium",
    tags = { "wood" },
    foleysound = "dontstarve/movement/foley/logarmour",
		absorption = .75,
  },
  ["lavaarena_armormediumdamager"] = {
    armor = "armor_mediumdamager",
    tags = { "wood" },
    foleysound = "dontstarve/movement/foley/logarmour",
		absorption = .75,
		cooldownreduc = 0.1,
		damagemult = 1.1,
  }, 
  ["lavaarena_armormediumrecharger"] = {
    armor = "armor_mediumrecharger",
    tags = { "wood" },
    foleysound = "dontstarve/movement/foley/logarmour",
		absorption = .75,
  },
  ["lavaarena_armorheavy"] = {
    armor = "armor_heavy",
    tags = { "marble" },
    foleysound = "dontstarve/movement/foley/marblearmour",
		absorption = .85,
  },
  ["lavaarena_armorextraheavy"] = {
    armor = "armor_extraheavy",
    tags = { "marble", "heavyarmor" },
    foleysound = "dontstarve/movement/foley/marblearmour",
		absorption = .9,
		speedmult  = 0.85,
  },
}) do
  table.insert(armors, MakeArmour(k, v))
end

return unpack(armors)
