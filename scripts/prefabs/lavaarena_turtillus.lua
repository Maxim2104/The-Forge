local assets =
{
	Asset("ANIM", "anim/lavaarena_turtillus_basic.zip"),
	Asset("ANIM", "anim/fossilized.zip"),
}

SetSharedLootTable( "lavaarena_turtillus", {})

local targetDist = TUNING.LAVAARENA_TURTILLUS.TARGET_DIST
local keepTargetDistSq = TUNING.LAVAARENA_TURTILLUS.KEEPDIST * TUNING.LAVAARENA_TURTILLUS.KEEPDIST

local function OnNewTarget(inst, data)
	if inst.components.sleeper:IsAsleep() then
		inst.components.sleeper:WakeUp()
	end
end

local function OnTimerDone(inst, data)
	if data ~= nil and data.name == "slide" then
		inst.canSlide = true
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
	return inst.components.combat:CanTarget(target) and inst:GetDistanceSqToInst(target) <= (keepTargetDistSq)
end

local function OnAttacked(inst, data)
	if not inst.components.timer:TimerExists("slide") 
		and not inst.canSlide 
		and not inst.sg:HasStateTag("slide")
	then
		inst.components.timer:StartTimer("slide", 15)
	end
	inst.components.combat:SetTarget(data.attacker)
	--inst.components.combat:ShareTarget(data.attacker, TUNING.CCW.SNAKE.SHARE_TARGET_DIST, function(dude) return dude:HasTag("snake") and not dude.components.health:IsDead() end, 5)
end

local function OnAttackOther(inst, data)
	--inst.components.combat:ShareTarget(data.target, TUNING.CCW.SNAKE.SHARE_TARGET_DIST, function(dude) return dude:HasTag("snake") and not dude.components.health:IsDead() end, 5)
end

local function SlideTask(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local musttags = {}
	local notags = {"lavaarena_enemy", "smallcreature", "FX", "NOCLICK", "INLIMBO"}
	local damage = TUNING.LAVAARENA_TURTILLUS.SLIDEDAMAGE
	for _, v in pairs(TheSim:FindEntities(x, y, z, TUNING.LAVAARENA_TURTILLUS.SLIDE_RADIUS, musttags, notags)) do
		if v ~= inst 
			and v:IsValid() 
			and v.entity:IsVisible() 
			and v.components.combat ~= nil 
			and not table.contains(inst.slidehitted, v)
		then
			table.insert(inst.slidehitted, v)
			v.components.combat:GetAttacked(inst, damage)
		end
	end
end

local function GetDebugString(inst)
	return string.format("can slide: %s", tostring(inst.canSlide))
end

local function fn(Sim)
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddPhysics()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()
	inst.entity:AddDynamicShadow()

	MakeCharacterPhysics(inst, 250, 1.5)

    inst.DynamicShadow:SetSize(2.5, 1.75)
    inst.Transform:SetSixFaced()
    inst.Transform:SetScale(.8, .8, .8)

	inst.AnimState:SetBank("turtillus")
	inst.AnimState:SetBuild("lavaarena_turtillus_basic")
	inst.AnimState:PlayAnimation("idle")

    inst.AnimState:AddOverrideBuild("fossilized")

	inst:AddTag("scarytoprey")
	--inst:AddTag("monster")
	inst:AddTag("hostile")
	inst:AddTag("turtle")
	inst:AddTag("flippable")
	inst:AddTag("fossilizable")

	inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst:AddComponent("fossilizable")

	inst:AddComponent("knownlocations")

	inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
	inst.components.locomotor.walkspeed = TUNING.LAVAARENA_TURTILLUS.WALKSPEED

	inst:SetStateGraph("SGlavaarena_turtillus")
	inst:SetBrain(require "brains/lavaarena_turtillusbrain")

	inst:AddComponent("eater")
	inst.components.eater:SetDiet({ FOODTYPE.MEAT }, { FOODTYPE.MEAT })
	inst.components.eater:SetCanEatHorrible(false)

	--inst.components.eater.strongstomach = true -- can eat monster meat!

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(TUNING.LAVAARENA_TURTILLUS.HEALTH)

	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(TUNING.LAVAARENA_TURTILLUS.DAMAGE)
	inst.components.combat:SetAttackPeriod(TUNING.LAVAARENA_TURTILLUS.ATTACK_PERIOD)
	inst.components.combat:SetRetargetFunction(3, Retarget)
	inst.components.combat:SetKeepTargetFunction(KeepTarget)
	inst.components.combat:SetRange(TUNING.LAVAARENA_TURTILLUS.RANGE)

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable("lavaarena_turtillus")

	inst:AddComponent("inspectable")
    inst:AddTag("fossilizable")

	--inst:AddComponent("sanityaura")
	--inst.components.sanityaura.aurafn = SanityAura

	inst:AddComponent("sleeper")
	inst.components.sleeper:SetNocturnal(false)

	inst:AddComponent("timer")

	inst.SlideTask = SlideTask

	inst.canSlide = false
	inst.slides = 0
	inst.slidehitted = {}

	--inst.OnSave = OnSave
	--inst.OnLoad = OnLoad

	inst:ListenForEvent("attacked", OnAttacked)
	--inst:ListenForEvent("onattackother", OnAttackOther)
	inst:ListenForEvent("newcombattarget", OnNewTarget)
	inst:ListenForEvent("timerdone", OnTimerDone)

	MakeLargeFreezableCharacter(inst, "body")
    MakeMediumBurnableCharacter(inst, "body")

	inst.debugstringfn = GetDebugString

	return inst
end

return Prefab("turtillus", fn, assets, prefabs)