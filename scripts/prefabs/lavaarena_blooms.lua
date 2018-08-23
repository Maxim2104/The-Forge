local assets = {
  Asset("ANIM", "anim/lavaarena_heal_flowers_fx.zip"),
}

local prefabs_healblooms = {
  "lavaarena_bloom",
  "lavaarena_bloomhealbuff",
  "lavaarena_bloomsleepdebuff",
}

--------------------------------------------------------------------------

local NUM_BLOOM_VARIATIONS = 6

local function OnSave(inst, data)
	data.variation = inst.variation
end

local function OnLoad(inst, data)
	if data ~= nil and data.variation ~= nil then
		inst.variation = data.variation
	end
end

local function MakeBloom(name, variation, prefabs)
	local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.variation = tostring(variation or math.random(NUM_BLOOM_VARIATIONS))

    inst.AnimState:SetBank("lavaarena_heal_flowers")
    inst.AnimState:SetBuild("lavaarena_heal_flowers_fx")
    inst.AnimState:Hide("buffed_hide_layer")
    inst.AnimState:PlayAnimation("in_"..inst.variation)
		inst:ListenForEvent("animover", function(inst)
			inst.AnimState:PlayAnimation("idle_"..inst.variation)
		end)
		inst:DoTaskInTime(10, function(inst)
			inst.AnimState:PlayAnimation("out_"..inst.variation)
			inst:ListenForEvent('animover', inst.Remove)
		end)

    inst:AddTag("FX")
    inst:AddTag("lavaarena_bloom")

    if variation == nil then
      inst:SetPrefabName(name..inst.variation)
    end
    inst:SetPrefabNameOverride("lavaarena_bloom")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
      return inst
    end

		inst.OnSave = OnSave
		inst.OnLoad = OnLoad

    return inst
  end

  return Prefab(name, fn, assets, prefabs)
end

local ret = {}
local prefs = {}
for i = 1, NUM_BLOOM_VARIATIONS do
  local name = "lavaarena_bloom"..tostring(i)
  table.insert(prefs, name)
  table.insert(ret, MakeBloom(name, i))
end
table.insert(ret, MakeBloom("lavaarena_bloom", nil, prefs))
prefs = nil

--------------------------------------------------------------------------

local function healbloomsfn()
  --return event_server_data("lavaarena", "prefabs/lavaarena_blooms").createhealblooms()
end

table.insert(ret, Prefab("lavaarena_healblooms", healbloomsfn, nil, prefabs_healblooms))

--------------------------------------------------------------------------

local function sleepdebufffn()
  --return event_server_data("lavaarena", "prefabs/lavaarena_blooms").createsleepdebuff()
end

table.insert(ret, Prefab("lavaarena_bloomsleepdebuff", sleepdebufffn))

--------------------------------------------------------------------------

local function OnInitHealBuff(inst)
  local parent = inst.entity:GetParent()
  if parent ~= nil then
    parent:PushEvent("starthealthregen", inst)
  end
end

local function healbufffn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddNetwork()

  inst:AddTag("CLASSIFIED")

  inst:DoTaskInTime(0, OnInitHealBuff)

  inst.entity:SetPristine()

  if not TheWorld.ismastersim then
    return inst
  end

  return inst
end

table.insert(ret, Prefab("lavaarena_bloomhealbuff", healbufffn))

--------------------------------------------------------------------------

--For searching: "lavaarena_bloom1", "lavaarena_bloom2", "lavaarena_bloom3",
--               "lavaarena_bloom4", "lavaarena_bloom5", "lavaarena_bloom6"
return unpack(ret)
