local assets =
{
	Asset("ANIM", "anim/lavaarena_peghook_basic.zip"),
	Asset("ANIM", "anim/lavaarena_hits_splash.zip"),
	Asset("ANIM", "anim/gooball_fx.zip"),
	Asset("ANIM", "anim/fossilized.zip"),
}

SetSharedLootTable( "lavaarena_peghook", {})

local targetDist = TUNING.LAVAARENA_PEGHOOK.TARGET_DIST
local keepDist = TUNING.LAVAARENA_PEGHOOK.KEEPDIST

local spitRange = TUNING.LAVAARENA_PEGHOOK.SPITRANGE
local stickySpit = TUNING.LAVAARENA_PEGHOOK.STICKY_SPIT
local spitDamage = TUNING.LAVAARENA_PEGHOOK.SPITDAMAGE
local splashDamage = TUNING.LAVAARENA_PEGHOOK.SPLASHDAMAGE
local rangeRecharge = TUNING.LAVAARENA_PEGHOOK.RANGE_ATTACK_PERIOD

local splashRadius = TUNING.LAVAARENA_PEGHOOK.SPLASHRADIUS
local spreadTargets = TUNING.LAVAARENA_PEGHOOK.SPREAD_TARGETS

local function OnNewTarget(inst, data)
	if inst.components.sleeper:IsAsleep() then
		inst.components.sleeper:WakeUp()
	end
end

local function OnTimerDone(inst, data)
	if data ~= nil and data.name == "spread" then
		inst.canSpread = true
	end
end

local function Retarget(inst)
	local musttags = {}
	local notags = {"lavaarena_enemy", "smallcreature", "FX", "NOCLICK", "INLIMBO"}
	return FindEntity(inst, targetDist, function(guy)
		return  inst.components.combat:CanTarget(guy)
	end, musttags, notags)
end

local function KeepTarget(inst, target)
	return inst.components.combat:CanTarget(target) and inst:GetDistanceSqToInst(target) <= (keepDist * keepDist)
end

local function OnAttacked(inst, data)
	inst.components.combat:SetTarget(data.attacker)
	--inst.components.combat:ShareTarget(data.attacker, TUNING.CCW.SNAKE.SHARE_TARGET_DIST, function(dude) return dude:HasTag("snake") and not dude.components.health:IsDead() end, 5)
end

local function OnAttackOther(inst, data)
	--inst.components.combat:ShareTarget(data.target, TUNING.CCW.SNAKE.SHARE_TARGET_DIST, function(dude) return dude:HasTag("snake") and not dude.components.health:IsDead() end, 5)
	if not inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
		inst.spitCharge = inst.spitCharge + 1
	end
end

local function DoSpread(inst)
	local notags = { "smallcreature", "scorpion", "shadow", "playerghost", "INLIMBO", "NOCLICK", "FX" }
	local x, y, z = inst.Transform:GetWorldPosition()
	local hits = 0
	for _, v in pairs(TheSim:FindEntities(x, y, z, spitRange, {"_combat"}, notags)) do
		if v ~= inst 
			and v:IsValid() 
			and v.entity:IsVisible() 
			and v.components.combat ~= nil 
		then
			inst.components.combat:DoAttack(v) 
			hits = hits + 1
			if hits >= spreadTargets then break end
		end
	end
	inst.components.combat.laststartattacktime = GetTime()
end

local function SpitChargeTask(inst)
	if inst.spitCharge >= 5 then
		if inst._sctask ~= nil then
			inst._sctask:Cancel()
		end
	else
		inst.spitCharge = inst.spitCharge + 1
	end
end

local function EquipWeapons(inst)
    if inst.components.inventory ~= nil and not inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
        local mass = CreateEntity()
        mass.name = "scorpspit"
        --[[Non-networked entity]]
        mass.entity:AddTransform()
        mass:AddComponent("weapon")
        mass.components.weapon:SetDamage(spitDamage)
        mass.components.weapon:SetRange(TUNING.LAVAARENA_PEGHOOK.SPITRANGE, TUNING.LAVAARENA_PEGHOOK.SPITRANGE + 2)
        mass.components.weapon:SetProjectile("lavaarena_peghook_massproj")
        mass:AddComponent("inventoryitem")
        mass.persists = false
        mass.components.inventoryitem:SetOnDroppedFn(mass.Remove)
        mass:AddComponent("equippable")
        mass:AddTag("spit")

        inst.components.inventory:GiveItem(mass)
		inst.massweapon = mass
		
		local spit = CreateEntity()
        spit.name = "scorpspit"
        --[[Non-networked entity]]
        spit.entity:AddTransform()
        spit:AddComponent("weapon")
        spit.components.weapon:SetDamage(spitDamage)
        spit.components.weapon:SetRange(TUNING.LAVAARENA_PEGHOOK.SPITRANGE, TUNING.LAVAARENA_PEGHOOK.SPITRANGE + 2)
        spit.components.weapon:SetProjectile("lavaarena_peghook_proj")
        spit:AddComponent("inventoryitem")
        spit.persists = false
        spit.components.inventoryitem:SetOnDroppedFn(spit.Remove)
        spit:AddComponent("equippable")
        spit:AddTag("spit")

        inst.components.inventory:GiveItem(spit)
        inst.weapon = spit
    end
end

local function GetDebugString(inst)
	return string.format("spit %s, spread %i", tostring(GetTime() - inst.components.combat.lastrangeattacktime > rangeRecharge), 
		inst.spitCharge)
end

local function fn(Sim)
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddPhysics()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()
	inst.entity:AddDynamicShadow()

	MakeCharacterPhysics(inst, 150, 1.5)

    inst.DynamicShadow:SetSize(3, 1.5)
    inst.Transform:SetSixFaced()
    inst.Transform:SetScale(.9, .9, .9)
	
	inst.AnimState:SetBank("peghook")
	inst.AnimState:SetBuild("lavaarena_peghook_basic")
	inst.AnimState:PlayAnimation("idle")

    inst.AnimState:AddOverrideBuild("fossilized")

	inst:AddTag("scarytoprey")
	--inst:AddTag("monster")
	inst:AddTag("hostile")
	inst:AddTag("scorpion")
	inst:AddTag("fossilizable")

	inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst:AddComponent("fossilizable")

	inst:AddComponent("knownlocations")

	inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
	inst.components.locomotor.runspeed = TUNING.LAVAARENA_PEGHOOK.RUNSPEED

	inst:SetStateGraph("SGlavaarena_peghook")
	inst:SetBrain(require "brains/lavaarena_peghookbrain")

	inst:AddComponent("eater")
	inst.components.eater:SetDiet({ FOODTYPE.MEAT }, { FOODTYPE.MEAT })
	inst.components.eater:SetCanEatHorrible(false)

	--inst.components.eater.strongstomach = true -- can eat monster meat!

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(TUNING.LAVAARENA_PEGHOOK.HEALTH)

	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(TUNING.LAVAARENA_PEGHOOK.DAMAGE)
	inst.components.combat:SetAttackPeriod(TUNING.LAVAARENA_PEGHOOK.ATTACK_PERIOD)
	inst.components.combat:SetRetargetFunction(3, Retarget)
	inst.components.combat:SetKeepTargetFunction(KeepTarget)
	inst.components.combat:SetRange(TUNING.LAVAARENA_PEGHOOK.RANGE)
	inst.components.combat.battlecryenabled = false
	inst.components.combat.lastrangeattacktime = GetTime()

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable("STRANGE_SCORPION")

	inst:AddComponent("inspectable")

	--inst:AddComponent("sanityaura")
	--inst.components.sanityaura.aurafn = SanityAura

	inst:AddComponent("sleeper")
	inst.components.sleeper:SetNocturnal(false)

	inst:AddComponent("inventory")

	--inst.OnSave = OnSave
	--inst.OnLoad = OnLoad

	inst:ListenForEvent("attacked", OnAttacked)
	inst:ListenForEvent("onattackother", OnAttackOther)
	inst:ListenForEvent("newcombattarget", OnNewTarget)

	MakeLargeFreezableCharacter(inst, "body")
	MakeMediumBurnableCharacter(inst, "body")
	EquipWeapons(inst)
	
	inst.spitCharge = 5
	inst._sctask = inst:DoPeriodicTask(5, SpitChargeTask)
	inst.canSpread = false

	inst.SpitChargeFN = SpitChargeTask
	inst.DoSpread = DoSpread
	inst.debugstringfn = GetDebugString

	return inst
end

--single projectile------------------------
-------------------------------------------
local function OnProjectileHit(inst, other)
	local x, y, z = inst.Transform:GetWorldPosition()

	SpawnPrefab("lavaarena_peghook_splash").Transform:SetPosition(x, y, z)
	inst.SoundEmitter:PlaySound("dontstarve/impacts/lava_arena/poison_drop")
	local notags = { "scorpion", "shadow", "playerghost", "INLIMBO", "NOCLICK", "FX" }
	for _, ent in pairs (TheSim:FindEntities(x, y, z, splashRadius, 
		{"_combat"}, notags)) 
	do
		if ent:IsValid() 
			and ent.entity:IsVisible() 
			and ent.components.combat ~= nil 
		then
			ent.components.combat:GetAttacked(inst.components.complexprojectile.attacker, splashDamage)
			if ent.components.pinnable ~= nil and stickySpit then
				local pin = ent.components.pinnable
				pin:Stick()
				if pin:IsStuck() then
					pin.attacks_since_pinned = 3
					pin:SpawnShatterFX()
					pin:UpdateStuckStatus()
				end
			end
			-------------------------------
			-- other:DoTaskInTime(10, function(other) -- 10 — длительность действия яда
				-- if other._poisontask ~= nil then
					-- other._poisontask:Cancel()
					-- other._poisontask = nil
				-- end
			-- end
			-- other._poisontask = DoPeriodicTask(1, function(other) -- 1 — раз в сколько секнуд будет тикать яд, модно указывать дробные значения
				-- other.components.health:DoDelta(-10) -- 10 — урон, ачисло должно быть отрицательным, иначе будет хилить
				-- --для спецэффекта раскомментить строку и вписать название префаба
				-- --SpawnPrefab("Тут имя спецэффекта для яда").Transform:SetPosition(other.Transform:GetWorldPosition())
			-- end)
			-------------------------------
			--end
		end
	end
	
	RemovePhysicsColliders(inst) 
	inst.AnimState:PlayAnimation("blast", false)
	inst:ListenForEvent("animover", inst.Remove)
end

local function projectilefn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddPhysics()
    inst.entity:AddNetwork()

    inst.Physics:SetMass(1)
    inst.Physics:SetFriction(10)
    inst.Physics:SetDamping(5)
    inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.GROUND)
	inst.Physics:SetCapsule(0.02, 0.02)
	
	inst.Transform:SetScale(0.7, 0.7, 0.7)

    inst.AnimState:SetBank("gooball_fx")
    inst.AnimState:SetBuild("gooball_fx")
    inst.AnimState:PlayAnimation("idle_loop", true)
	inst.AnimState:SetMultColour(0, 1, 0.3, 1)

	inst.entity:SetPristine()
	
	inst:AddTag("_projectile")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.Physics:SetCollisionCallback(OnProjectileHit)

    inst.persists = false

    inst:AddComponent("locomotor")
    inst:AddComponent("complexprojectile")
	inst.components.complexprojectile:SetHorizontalSpeed(40)
	inst.components.complexprojectile:SetOnHit(OnProjectileHit)
	inst.components.complexprojectile:SetLaunchOffset(Vector3(2, 4, 2))
	inst.components.complexprojectile.usehigharc = false
	
	inst._lifeTask = inst:DoTaskInTime(10, inst.Remove)

    return inst
end

--mass projectile--------------------------
-------------------------------------------
local function massprojectilefn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddPhysics()
    inst.entity:AddNetwork()

    inst.Physics:SetMass(1)
    inst.Physics:SetFriction(10)
    inst.Physics:SetDamping(5)
    inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.GROUND)
    --inst.Physics:CollidesWith(COLLISION.OBSTACLES)
    --inst.Physics:CollidesWith(COLLISION.CHARACTERS)
	inst.Physics:SetCapsule(0.02, 0.02)
	
	inst.Transform:SetScale(0.7, 0.7, 0.7)

    inst.AnimState:SetBank("gooball_fx")
    inst.AnimState:SetBuild("gooball_fx")
    inst.AnimState:PlayAnimation("idle_loop", true)
	inst.AnimState:SetMultColour(0, 1, 0.3, 1)

	inst.entity:SetPristine()
	
	inst:AddTag("_projectile")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.Physics:SetCollisionCallback(OnProjectileHit)

    inst.persists = false

    inst:AddComponent("locomotor")
    inst:AddComponent("complexprojectile")
	inst.components.complexprojectile:SetHorizontalSpeed(20)
    inst.components.complexprojectile:SetGravity(-35)
	inst.components.complexprojectile:SetOnHit(OnProjectileHit)
	--inst.components.complexprojectile:SetGravity(-15)
	inst.components.complexprojectile:SetLaunchOffset(Vector3(0, 4, 0))
	--inst.components.complexprojectile.usehigharc = false
	
	inst._lifeTask = inst:DoTaskInTime(10, inst.Remove)

    return inst
end

--splash-------------------
---------------------------
local function splashfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()
	
	inst.Transform:SetScale(0.5, 0.5, 0.5)

    inst.AnimState:SetBank("lavaarena_hits_splash")
    inst.AnimState:SetBuild("lavaarena_hits_splash")
    inst.AnimState:PlayAnimation("aoe_hit")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
	inst.AnimState:SetSortOrder(3)
	inst.AnimState:SetMultColour(0, 1, 0.3, 1)

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    --inst:AddComponent("bloomer")
    --inst.components.bloomer:PushBloom("fx", "shaders/anim.ksh", -2)

    if not TheWorld.ismastersim then
        return inst
    end

	inst.persists = false
	inst:ListenForEvent("animover", inst.Remove)
	
    return inst
end

return Prefab("peghook", fn, assets, prefabs),
	Prefab("peghook_massproj", massprojectilefn, assets, prefabs),
	Prefab("peghook_proj", projectilefn, assets, prefabs),
	Prefab("peghook_splash", splashfn, assets, prefabs)