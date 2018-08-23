local assets =
{
    Asset("ANIM", "anim/lavaarena_boarrior_basic.zip"),
	Asset("ANIM", "anim/fossilized.zip"),
}

local prefabs =
{
	"lavaarena_boarriormeteor",
	"groundfire",
	"groundpound_fx"
}

SetSharedLootTable( "lavaarena_boarrior",
{
})

function ListenForEventOnce(inst, event, fn, source)
    -- Currently, inst2 is the source, but I don't want to make that assumption.
    local function gn(inst2, data)
        inst:RemoveEventCallback(event, gn, source) --as you can see, it removes the event listener even before firing the function
        return fn(inst2, data)
    end
     
    return inst:ListenForEvent(event, gn, source)
end

function IsEntityOnLine(ent, pt1, pt2) -- not net, geometry
	local xe, _, ye = ent.Transform:GetWorldPosition() 
    local radius = ent:GetPhysicsRadius(0) or 0.5

    local p1, p2 = {}, {}
    p1.x = pt1.x - xe
    p1.y = pt1.y - ye
    p2.x = pt2.x - xe
    p2.y = pt2.y - ye
    local dx = (p2.x - p1.x)
    local dy = (p2.y - p1.y)
    local a = dx * dx + dy * dy;
    local b = 2 * ( p1.x * dx + p1.y * dy);
    local c = p1.x * p1.x + p1.y * p1.y - radius * radius;

    if -b < 0 then return c < 0 end
    if -b < 2 * a then return 4 * a * c - b * b < 0 end
    return ((a + b + c < 0))
end

function IsEntityInside(polygon, ent)
	local pt = {}
	pt.x, pt.o, pt.y = ent.Transform:GetWorldPosition() -- "_" does't work, let it be pt.o
	local radius = ent:GetPhysicsRadius(0) or 0.5
	local intersections = 0
	local prev = #polygon
	local prevUnder = polygon[prev].y < pt.y
	for i = 1, #polygon do
		local currUnder = polygon[i].y < pt.y
		local p1, p2 = {}, {}
		p1.x = polygon[prev].x - pt.x
		p1.y = polygon[prev].y - pt.y
        p2.x = polygon[i].x - pt.x
		p2.y = polygon[i].y - pt.y
		local dx = (p2.x - p1.x)
		local dy = (p2.y - p1.y)
		local t = (p1.x * dy - p1.y * dx)
		
		local a = dx * dx + dy * dy;
        local b = 2 * ( p1.x * dx + p1.y * dy);
        local c = p1.x * p1.x + p1.y * p1.y - radius * radius;

        if -b < 0 and c < 0 then return true end
        if -b < 2 * a and 4 * a * c - b * b < 0  then return true end
        if (a + b + c < 0) then return true end
		
		if currUnder and not prevUnder then
            if (t > 0) then
                intersections = intersections + 1
			end
		end
        
        if not currUnder and prevUnder then
            if (t < 0) then
                intersections = intersections + 1
			end
		end
		
		prev = i
        prevUnder = currUnder
	end
	return not IsNumberEven(intersections)
end

local function OnTimerDone(inst, data)
	if data.name == "regen_bossboar" then
		if inst._spawntask ~= nil then
			inst._spawntask:Cancel()
			inst._spawntask = nil
		end
		inst:Show()
		inst.DynamicShadow:Enable(true)
		SoftColorChange(inst, {0, 0, 0, 1}, {0, 0, 0, 0}, 2, 0.1)
		inst:DoTaskInTime(2, function(inst) SoftColorChange(inst, {1, 1, 1, 1}, {0, 0, 0, 1}, 2, 0.1) end)
		inst:DoTaskInTime(4, function(inst) 
			inst.brain:Start() 
			inst:SetEngaged()
			inst:ReTarget()
		end)
	end
end

local function OnAttacked(inst, data)
	if data == nil or data.attacker == nil then return end
	if data.attacker:HasTag("player") or inst.components.combat.target == nil then
		inst.components.combat:SetTarget(data.attacker)
	end
	if not inst.engaged then
		inst:SetEngaged(inst)
	end
	table.insert(inst.engagedUnits, data.attacker)
end

local function ReTarget(inst)

	if not inst.engaged then return nil end
    local newtarget = FindEntity(inst, 50, 
		function(guy)
			return inst.components.combat:CanTarget(guy)
				--and table.contains(inst.engagedUnits, guy)
        end,
        { "_combat" },
        { "smallcreature", "playerghost", "shadow", "INLIMBO", "FX", "NOCLICK" }
    )

    if newtarget then
		return newtarget
	end
end

local function ChangeRageMult(inst)
	inst.sg:GoToState("taunt")
	if inst.components.health:GetPercent() <= 0.76 then
		--inst.rageMult = 1.25
	elseif inst.components.health:GetPercent() <= 0.51 then
		--inst.rageMult = 1.5
	elseif inst.components.health:GetPercent() <= 0.26 then
		--inst.rageMult = 2
		--[[ inst._mtask = inst:DoPeriodicTask(3, function(inst)
			local obj = SpawnPrefab("bossboarmeteor")
			local radius = math.random(5, 40)
			local angle = math.random(360) * DEGREES
			local x, y, z = inst.Transform:GetWorldPosition()
			obj.Transform:SetPosition(x + math.cos(angle) * radius, y, z + math.sin(angle))
			obj:StartMeteor(0.8, math.random(360))
		end) ]]
	end
end

local function SetEngaged(inst)
	if not inst.engaged then
		--print("pulled")
		inst.components.health:SetMaxHealth(TUNING.LAVAARENA_BOARRIOR.HEALTH + TUNING.LAVAARENA_BOARRIOR.BONUSHEALTH * #AllPlayers)
		inst.engaged = true
		inst.lastWirlWind = GetTime()
		inst.lastGroundSlam = GetTime()
		inst.lastGroundBurn = GetTime()
		inst.lastCombo = GetTime()

		--inst.components.timer:StartTimer("whirlwindcd", TUNING.CCW.BOSSBOAR.WHIRLWINDCD)
		--inst.components.timer:StartTimer("groundslamcd", inst:CalculateGroundSlamCD(inst))
		--inst.components.timer:StartTimer("meteorshowercd", TUNING.CCW.BOSSBOAR.METEORCD)
		--inst.components.timer:StartTimer("comboattack", inst:CalculateComboCD(inst))

		inst:ChangeRageMult(inst)
		--inst._rtask = inst:DoPeriodicTask(1, function(inst) 
			--inst.rageCount = inst.rageCount < 100 and inst.rageCount + 25 * inst.rageMult or 100
		--end)
	end
end

local function SetEvaded(inst)
	if inst.engaged then
		inst.components.health:SetMaxHealth(TUNING.LAVAARENA_BOARRIOR.HEALTH)
		--print("evaded")
		inst.engaged = false
		inst.components.health:SetPercent(100)
		--inst._rtask:Cancel()
		if inst._mtask ~= nil then
			inst._mtask:Cancel()
			inst._mtask = nil
		end

		if inst._rtask ~= nil then
			inst._rtask:Cancel()
			inst._rtask = nil
		end

		inst.engagedUnits = {}
	end
end

local function CalculateComboCD(inst)
	return math.max(5, math.modf(inst.components.health:GetPercent() * TUNING.LAVAARENA_BOARRIOR.COMBOCD))
end

local function CalculateGroundSlamCD(inst)
	local cd = TUNING.LAVAARENA_BOARRIOR.GROUNDSLAMCD_4
	if inst.components.health:GetPercent() > 0.75 then
		cd = TUNING.LAVAARENA_BOARRIOR.GROUNDSLAMCD_1
	elseif inst.components.health:GetPercent() > 0.5 then
		cd = TUNING.LAVAARENA_BOARRIOR.GROUNDSLAMCD_2
	elseif inst.components.health:GetPercent() > 0.3 then
		cd = TUNING.LAVAARENA_BOARRIOR.GROUNDSLAMCD_3
	--elseif inst.components.health:GetPercent() > 0.15 then
		--cd = 2
	end
	--print("slam cd: " .. cd)
	return cd
end

--groundslam-----------------------------------
-----------------------------------------------
local function GroundSlamTargets(inst, polygon)
	local x, y, z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, y, z, 16, nil, { "NOCLICK", "FX", "shadow", "playerghost", "INLIMBO" })
	for _, ent in pairs(ents) do
		if ent ~= inst and ent:IsValid() and ent.entity:IsVisible()  then
			local entPoint = {}
			entPoint[1], _, entPoint[2] = ent.Transform:GetWorldPosition()
			--local str = "checking " .. ent.prefab or "something" .. " x: " .. entPoint[1] .. " y:" .. entPoint[2] .. "... "
			if IsEntityInside(polygon, ent) then
				--str = str .. "is in!"
				if ent.components.workable 
					and ent.components.workable:CanBeWorked() 
					and not (ent.sg ~= nil and ent.sg:HasStateTag("busy")) 
				then
					--print("digging", ent)
                    if ent.components.workable:GetWorkAction() == ACTIONS.DIG then
						ent.components.workable:WorkedBy(inst, 1)
                    end
				elseif ent.components.combat ~= nil then
					ent.components.combat:GetAttacked(inst, TUNING.LAVAARENA_BOARRIOR.GROUNDSLAMDAMAGE, nil)
				end
			--else
				--str = str .. "nope"
			end
			--print(str)
		end
	end
end

local function GroundSlam(inst, target)
	local points = {}
	local polygon = {}
	local x, y, z = inst.Transform:GetWorldPosition() 
	--local target = FindClosestPlayerInRange(x, y, z, 20, true)
	if target == nil and not target:IsValid() and not target.entity:IsVisible() then return end
	local tx, ty, tz = target.Transform:GetWorldPosition()
	inst:ForceFacePoint(tx, ty, tz)
	local angle = (inst.Transform:GetRotation())
	local angle1 = (angle - 60) * DEGREES
	local angle2 = (angle + 60) * DEGREES
	angle = angle * DEGREES
	local x1 = x + math.cos(angle1) * 2 
	local z1 = z - math.sin(angle1) * 2 
	local x2 = x + math.cos(angle2) * 2 
	local z2 = z - math.sin(angle2) * 2 
	local maxDistance = 15
	local minDistance = 1
	for i = minDistance, maxDistance, 2 do
		local tile = nil
		local pt1 = {x + math.cos(angle) * i, y, z - math.sin(angle) * i}
		local pt2 = {x1 + math.cos(angle) * i, y, z1 - math.sin(angle) * i}
		local pt3 = {x2 + math.cos(angle) * i, y, z2 - math.sin(angle) * i}
		tile = TheWorld.Map:GetTileAtPoint(pt1[1], pt1[2], pt1[3])
		if tile ~= GROUND.IMPASSABLE and tile ~= GROUND.INVALID then
			table.insert(points, pt1)
		end
		tile = TheWorld.Map:GetTileAtPoint(pt2[1], pt2[2], pt2[3])
		if tile ~= GROUND.IMPASSABLE and tile ~= GROUND.INVALID then
			table.insert(points, pt2)
		end
		tile = TheWorld.Map:GetTileAtPoint(pt3[1], pt3[2], pt3[3])
		if tile ~= GROUND.IMPASSABLE and tile ~= GROUND.INVALID then
			table.insert(points, pt3)
		end
		if i == minDistance then
			table.insert(polygon, { x = pt3[1], y = pt3[3] })
			table.insert(polygon, { x = pt2[1], y = pt2[3] })
		end
		if i == maxDistance then
			table.insert(polygon, { x = pt2[1], y = pt2[3] })
			table.insert(polygon, { x = pt3[1], y = pt3[3] })
		end
	end
	-------------------------------------
	--[[for k, v in pairs(polygon) do
		print("x: ".. k .. v[1] .. " y: " .. k .. " " .. v[2])
	end]]
	GroundSlamTargets(inst, polygon)
	--------------------------------------
	for i, pt in pairs(points) do
		local scale = 0.4
		local obj = SpawnPrefab("groundpound_fx")
		if i == 2 or i == 8 or i == 20 then
			obj.entity:AddSoundEmitter()
			obj.SoundEmitter:PlaySound("dontstarve/common/lava_arena/boarrior/attack_5")
		end
		obj.Transform:SetPosition(pt[1], pt[2], pt[3])
		obj.Transform:SetScale(scale, scale, scale)		
	end
	inst:DoTaskInTime(0.5, function(inst, points, polygon)
		for i, pt in pairs(points) do
			local obj = SpawnPrefab("groundfire")
			if i == 2 or i == 8 or i == 20 then
				--obj.entity:AddSoundEmitter()
				--obj.SoundEmitter:PlaySound("dontstarve/common/fireBurstSmall")
			end
			--obj.Transform:SetPosition(pt[1], pt[2], pt[3])	
		end
		GroundSlamTargets(inst, polygon)
	end, points, polygon)
end

--meteors-----------------------------------
-----------------------------------------------
local function GroundBurn(inst)
	local pos = Vector3(inst.Transform:GetWorldPosition())
	local victims = FindPlayersInRangeSq(pos.x, pos.y, pos.z, 400, true)
	if not victims or #victims == 0 then return end
	if #victims > 1 and inst.components.combat ~= nil and inst.components.combat.target ~= nil then -- we dont want use shower on current tank, if there are other targets
		RemoveByValue(victims, inst.components.combat.target)
	end
	local victim = victims[math.random(#victims)]
	
	if victim and victim:IsValid() then
		local metAngle = math.random(360)
		for i = 1, 10 do
			inst:DoTaskInTime(0.2 * i, function(inst, victim) 
				if victim and victim:IsValid() then
					--local obj = SpawnPrefab("lavaarena_boarriorfireburst")
					--obj.Transform:SetPosition(victim.Transform:GetWorldPosition()) 
					--obj:StartBurst(inst, 0.7)
				end
			end, victim)
		end
	end
end

--whirldwind-----------------------------------
-----------------------------------------------
local knockbackSpeedNoLoco = 5
local wwRadius = TUNING.LAVAARENA_BOARRIOR.WHIRLWINDRADIUS
local wwDamage = TUNING.LAVAARENA_BOARRIOR.WHIRLWINDDAMAGE

local function WhirlWind(inst)
	--local creatures = {}
	local x1, y1, z1 = inst.Transform:GetWorldPosition()
	local x2, y2, z2 = nil, nil, nil
	local ents = TheSim:FindEntities(x1, y1, z1, wwRadius, nil, { "NOCLICK", "FX", "shadow", "playerghost", "INLIMBO" })
	for i, ent in pairs(ents) do
		if ent ~= inst and ent:IsValid() 
			and ent.entity:IsVisible() 
			and not table.contains(inst.wwHitList, ent) 
		then
			--print(ent.prefab .. " knocked")
			table.insert(inst.wwHitList, ent)
			x2, y2, z2 = ent.Transform:GetWorldPosition()
			if ent.components.inventoryitem ~= nil then
				local str = ent:HasTag("heavy") and knockbackSpeedNoLoco / 2 or knockbackSpeedNoLoco
				ent.Physics:Teleport(x2, 0.5, z2)
				local vec = Vector3(x2 - x1, y2 - y1, z2 - z1):Normalize()
				ent.Physics:SetVel(vec.x * str, str, vec.z * str)
			elseif ent.components.locomotor ~= nil and not ent:HasTag("player") then
				--TODO
				--rework knockback for non-players cretures
			end

			if ent.components.combat ~= nil 
				and not ent.components.health:IsInvincible() then

				if ent:HasTag("player") then
					ent.sg:GoToState("knockback", { knocker = inst, radius = 8 })
					ent.sg:AddStateTag("nointerrupt")
					ent.components.combat:GetAttacked(inst, wwDamage, nil)
					ent.sg:RemoveStateTag("noiterrupt")
				else 
					ent.components.combat:GetAttacked(inst, wwDamage, nil)
				end
			end
		end
	end
end

--combo----------------------------------------
-----------------------------------------------
local function ComboHit(inst, target)
	if not target then return end
	local damage = TUNING.LAVAARENA_BOARRIOR.COMBOLASTHITDAMAGE
	if target:IsValid() and target.entity:IsVisible() 
		and inst:GetDistanceSqToInst(target) <= TUNING.LAVAARENA_BOARRIOR.ATTACK_RANGE * TUNING.LAVAARENA_BOARRIOR.ATTACK_RANGE + 4
	then
		if target:HasTag("player") then
			target.sg:GoToState("knockback", { knocker = inst, radius = 8 })
			target.sg:AddStateTag("nointerrupt")
			target.components.combat:GetAttacked(inst, damage, nil)
			target.sg:RemoveStateTag("noiterrupt")
		else
			damage = TUNING.LAVAARENA_BOARRIOR.COMBOLASTHITDAMAGE_FATAL
			target.components.combat:GetAttacked(inst, damage, nil)
		end
	end
end


local function OnSave(inst, data)
	data.engaged = inst.engaged
	if inst.engaged then
		data.rageCount = inst.rageCount
	end
end

local function OnLoad(inst, data)
	if data ~= nil then
		if data.engaged then
			SetEngaged(inst)
			--inst.rageCount = data.rageCount
			ReTarget(inst)
		end
	end
end

local function GetDebugString(inst)
	return string.format("WW: %.2f, GS: %.2f, GB: %.2f, CA: %.2f",
		math.max(TUNING.LAVAARENA_BOARRIOR.WHIRLWINDCD - (GetTime() - inst.lastWirlWind), 0),
		math.max(inst:CalculateGroundSlamCD() - (GetTime() - inst.lastGroundSlam), 0),
		math.max(TUNING.LAVAARENA_BOARRIOR.GROUNDBURNCD - (GetTime() - inst.lastGroundBurn), 0),
		math.max(inst:CalculateComboCD() - (GetTime() - inst.lastCombo), 0)
	)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.DynamicShadow:SetSize(5.25, 1.75)
    inst.Transform:SetFourFaced()

    inst:SetPhysicsRadiusOverride(2)
    MakeGiantCharacterPhysics(inst, 1000, 1.2)
    inst.Physics:SetCapsule(2, 2)

    inst.AnimState:SetBank("boarrior")
    inst.AnimState:SetBuild("lavaarena_boarrior_basic")
    inst.AnimState:PlayAnimation("idle_loop", true)

    inst.AnimState:AddOverrideBuild("fossilized")

    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("largecreature")
    inst:AddTag("epic")
	inst:AddTag("fossilizable")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst:AddComponent("fossilizable")

	inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
	inst.components.locomotor.runspeed = TUNING.LAVAARENA_BOARRIOR.SPEED
	local sg = require "stategraphs/SGlavaarena_boarrior"
	inst:SetStateGraph("SGlavaarena_boarrior")

	local brain = require "brains/lavaarena_boarriorbrain"
	inst:SetBrain(brain)

	inst:AddComponent("knownlocations")

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(TUNING.LAVAARENA_BOARRIOR.HEALTH)
	inst.components.health.nofadeout = true
	
	inst:AddComponent("healthtrigger")
	inst.components.healthtrigger:AddTrigger(0.75, ChangeRageMult)
	inst.components.healthtrigger:AddTrigger(0.50, ChangeRageMult)
	inst.components.healthtrigger:AddTrigger(0.25, ChangeRageMult)
	--inst.components.health.poison_damage_scale = 0 -- immune to poison

	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(TUNING.LAVAARENA_BOARRIOR.HANDDAMAGE)--(100)
	inst.components.combat:SetAttackPeriod(TUNING.LAVAARENA_BOARRIOR.ATTACK_PERIOD)
	inst.components.combat:SetRetargetFunction(5, ReTarget)
	--inst.components.combat:SetKeepTargetFunction(KeepTarget)
	inst.components.combat:SetRange(TUNING.LAVAARENA_BOARRIOR.ATTACK_RANGE, TUNING.LAVAARENA_BOARRIOR.ATTACK_RANGE + 2)
	inst.components.combat.battlecryenabled = false

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable("lavaarena_boarrior")

	inst:AddComponent("inspectable")
	inst:AddComponent("sanityaura")
	inst:AddComponent("explosiveresist")
	
	inst:AddComponent("sleeper")
	inst.components.sleeper:SetResistance(4)
    inst.components.sleeper.diminishingreturns = true
	
	inst:AddComponent("timer")
	
	inst.OnSave = OnSave
    inst.OnLoad = OnLoad
	inst.ReTarget = ReTarget
	--pull/evade
	inst.engaged = false
	inst.engagedUnits = {}
	inst.SetEngaged = SetEngaged
	inst.SetEvaded = SetEvaded

	inst.lastWirlWind = GetTime()
	inst.lastGroundSlam = GetTime()
	inst.lastGroundBurn = GetTime()
	inst.lastCombo = GetTime()

	inst.ChangeRageMult = ChangeRageMult
	inst.CalculateComboCD = CalculateComboCD
	inst.CalculateGroundSlamCD = CalculateGroundSlamCD
	
	--spells
	inst._rtask = nil
	inst._mtask = nil

	inst.rageCount = 0
	inst.rageMult = 1

	inst.GroundSlam = GroundSlam
	inst.GroundBurn = GroundBurn
	inst.WhirlWind = WhirlWind
	inst.ComboHit = ComboHit

	inst.showerHittedList = {}
	inst.wwHitList = {}

	--inst:ListenForEvent("death", OnDeath)
	inst:ListenForEvent("attacked", OnAttacked)
	inst:ListenForEvent("timerdone", OnTimerDone)

	--MakeMediumFreezableCharacter(inst, "hound_body")
	--MakeMediumBurnableCharacter(inst, "body")

	inst.debugstringfn = GetDebugString

    return inst
end

return Prefab("boarrior", fn, assets, prefabs)
