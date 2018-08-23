require("stategraphs/commonstates")

local actionhandlers = {}

local events =
{
    EventHandler("attacked", function(inst, data) 
        if not inst.components.health:IsDead() 
            and data.stimuli == 'electric' then
            inst.sg:GoToState("stun") 
            return
        end
        if not inst.components.health:IsDead() 
            and not inst.sg:HasStateTag("hit") 
            and not inst.sg:HasStateTag("attack") 
            and not inst.sg:HasStateTag("casting") 
        then inst.sg:GoToState("hit") 
        end 
    end),
    EventHandler("death", function(inst) inst.sg:GoToState("death", inst.sg.statemem.dead) end),
    EventHandler("doattack", function(inst, data) if not inst.components.health:IsDead() and (inst.sg:HasStateTag("hit") or not inst.sg:HasStateTag("busy")) then inst.sg:GoToState("attack", data.target) end end),
	EventHandler("comboattack", function(inst, target) 
		if not inst.components.health:IsDead() 
			and (inst.sg:HasStateTag("hit") 
			    or not inst.sg:HasStateTag("busy")) 
        then 
            inst.sg:GoToState("combofirsthit", target) 
		end 
	end),
    EventHandler("meteorshower", function(inst) 
		if not inst.components.health:IsDead() 
			and (inst.sg:HasStateTag("hit") 
			or not inst.sg:HasStateTag("busy")) 
        then 
            inst.sg:GoToState("cast") 
		end 
	end),
	EventHandler("whirlwind", function(inst) 
		if not inst.components.health:IsDead() 
			and (inst.sg:HasStateTag("hit") 
			or not inst.sg:HasStateTag("busy")) 
        then 
            inst.sg:GoToState("whirlwind") 
		end 
	end),
	EventHandler("groundslam", function(inst) 
		if not inst.components.health:IsDead() 
			and (inst.sg:HasStateTag("hit") 
			or not inst.sg:HasStateTag("busy")) 
        then 
            inst.sg:GoToState("groundslam") 
		end 
	end),
    CommonHandlers.OnSleep(),
    CommonHandlers.OnLocomote(false, true),
    --CommonHandlers.OnFreeze(),
	--CommonHandlers.OnAttacked(),
}

local states =
{
    State{
        name = "stun",
        tags = {"busy", "stunned"},
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("stun_loop", true)
            inst:PushEvent("stun_start")
            inst:DoTaskInTime(inst.stun_time or 1.0, function(inst) 
                inst:PushEvent("stun_over")
                inst.AnimState:PlayAnimation("stun_pst")
                inst.sg:GoToState("idle") 
                inst:PerformBufferedAction()
                if inst.components.combat then
                    inst.components.combat:TryRetarget()
                end
                end)
        end,
        events= {},
    },

    State{
        name = "idle",
        tags = { "idle", "canrotate" },
        onenter = function(inst, playanim)
            --inst.SoundEmitter:PlaySound("dontstarve/creatures/hound/pant")
            inst.Physics:Stop()
            if playanim then
                inst.AnimState:PlayAnimation(playanim)
                inst.AnimState:PushAnimation("idle_loop", true)
            else
                inst.AnimState:PlayAnimation("idle_loop", true)
            end
            inst.sg:SetTimeout(2 * math.random() + .5)
        end,
		
		events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "attack",
        tags = { "attack", "busy" },

        onenter = function(inst, target)
            inst.sg.statemem.target = target
            inst.Physics:Stop()
            inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/boarrior/grunt")
            inst.components.combat:StartAttack()
			if (math.random(1, 2) == 1) then
                inst.sg.statemem.attackAnim = 1
				inst.AnimState:PlayAnimation("attack1")
				inst.AnimState:PushAnimation("attack1_pst", false)
			else
                inst.sg.statemem.attackAnim = 2
				inst.AnimState:PlayAnimation("attack3")
			end
            --inst.AnimState:PushAnimation("attack", false)
        end,

        timeline =
        {
            TimeEvent(12 * FRAMES, function(inst)  
                if inst.sg.statemem.attackAnim == 1 then
                    inst.components.combat:DoAttack(inst.sg.statemem.target) 
                    inst.sg:RemoveStateTag("attack")
                    inst.sg:RemoveStateTag("busy")
                end
            end),
            TimeEvent(3 * FRAMES, function(inst) 
				if inst.sg.statemem.attackAnim == 2 then
                    inst.components.combat:DoAttack(inst.sg.statemem.target) 
                    inst.sg:RemoveStateTag("attack")
                    inst.sg:RemoveStateTag("busy")
                end
			end),
        },

        events =
        {
            EventHandler("animover", function(inst) 
				inst.sg:GoToState("idle")
			end),
        },
    },
	
    State{
        name = "hit",
        tags = { "busy", "hit" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/boarrior/hit")
            inst.AnimState:PlayAnimation("hit")
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "taunt",
        tags = { "busy" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")
        end,

        timeline =
        {
            TimeEvent(13 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/boarrior/taunt") end),
        },

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "death",
        tags = { "busy" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("death2", false)
            inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/boarrior/death") 
            -- RemovePhysicsColliders(inst)
            -- inst.components.health:SetCurrentHealth(1)
            -- inst.components.health:SetInvincible(true)
            inst.components.lootdropper:DropLoot(inst:GetPosition())
        end,

        timeline =
        {
            TimeEvent(FRAMES * 7, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/boarrior/bone_drop_stick")
            end),
            TimeEvent(FRAMES * 8, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/boarrior/bone_drop_stick")
            end),
            TimeEvent(FRAMES * 16, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/boarrior/death_bodyfall")
            end),
        },
    },

    State{
        name = "forcesleep",
        tags = { "busy", "sleeping" },

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("sleep_loop", true)
        end,
    },
	
	State{
        name = "cast",
        tags = { "busy", "casting" },
        onenter = function(inst)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("banner_pre", false)
            inst.AnimState:PushAnimation("banner_loop", false)
            --inst.sg:SetTimeout(5)
            inst.sg.statemem.loops = 0
            
            inst.lastGroundBurn = GetTime()
            inst.sg.statemem.gbdone = false
        end,

        events = {
            EventHandler("animover", function(inst)
                if inst.AnimState:IsCurrentAnimation("banner_loop") and inst.sg.statemem.loops <= 3 then
                    --print("need to play sound")
                    if not inst.sg.statemem.gbdone then
                        inst:GroundBurn()
                        inst.sg.statemem.gbdone = true
                    end
                    inst.AnimState:PlayAnimation("banner_loop", false)
                    inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/boarrior/bone_drop_stick")
                    inst.sg.statemem.loops = inst.sg.statemem.loops + 1
                else
                    inst.AnimState:PlayAnimation("banner_pst")
			        inst.sg:GoToState("idle")
                end
            end)
        },
    },
	
	State{
        name = "whirlwind",
        tags = { "busy", "casting" },
        onenter = function(inst)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("attack4") 
            inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/boarrior/spin")
            inst.lastWirlWind = GetTime()
        end,

        onexit = function(inst)
            inst.wwHitList = {}
        end,
		
		timeline =
        {
            TimeEvent(13 * FRAMES, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_lostrod") 
                inst:WhirlWind(inst) 
            end),
            TimeEvent(24 * FRAMES, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_lostrod") 
                inst:WhirlWind(inst) 
            end),
        },

		events =
        {
            EventHandler("animover", function(inst)
                inst:ReTarget(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },
	
	State{
        name = "groundslam",
        tags = { "casting", "busy" },

        onenter = function(inst)
            inst.Physics:Stop()

            local x, y, z = inst.Transform:GetWorldPosition()
			local target = FindClosestPlayerInRange(x, y, z, 20, true)
            if target ~= nil then
                inst.AnimState:PlayAnimation("attack5")
				inst.sg.mem.slamTarget = target
				local tx, ty, tz = target.Transform:GetWorldPosition()
				inst:ForceFacePoint(tx, ty, tz)
                inst.components.combat.laststartattacktime = GetTime()
			else
				inst.sg:GoToState("idle")
			end
        end,

        timeline =
        {
			TimeEvent(10 * FRAMES, function(inst) 
				inst:GroundSlam(inst.sg.mem.slamTarget)
                inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/boarrior/bonehit2")
                inst.lastGroundSlam = GetTime()
                inst.components.combat.laststartattacktime = GetTime()
            end),

            TimeEvent(40 * FRAMES, function(inst) 
				--inst.sg:RemoveStateTag("attack")
                --inst.sg:RemoveStateTag("busy")
			end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst) 
				if math.random() < 0.8 then 
					inst.sg:GoToState("taunt") 
				else 
					inst.sg:GoToState("idle")
				end
			end),
        },
    },

    State{
        name = "dash",
        tags = { "busy", "attack" },
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst:ClearBufferedAction()

			inst.AnimState:PlayAnimation("dash") 
            inst.sg.statemem.dashspeed = 1
            inst.Physics:SetMotorVel(inst.sg.statemem.dashspeed, 0, 0)
        end,

        onupdate = function(inst)
            inst.Physics:SetMotorVel(inst.sg.statemem.dashspeed, 0, 0)
        end,
		
		timeline =
        {
            TimeEvent(3 * FRAMES, function(inst) 
                inst.sg.statemem.dashspeed = 12
            end),
            TimeEvent(3 * FRAMES, function(inst) 
                inst.sg.statemem.dashspeed = 20
            end),
            TimeEvent(3 * FRAMES, function(inst) 
                inst.sg.statemem.dashspeed = 12
            end),
            TimeEvent(9 * FRAMES, function(inst)
                inst.sg.statemem.dashspeed = 0 
            end),
        },

		events =
        {
            EventHandler("animover", function(inst)
                inst.Physics:ClearMotorVelOverride()
                inst.sg:GoToState("combothirdhit")
            end),
        },

        onexit = function(inst)
            inst.components.locomotor:Stop()
            inst.Physics:ClearMotorVelOverride()
        end,
    },
	
	State{
        name = "combofirsthit",
        tags = { "busy", "attack" },
        onenter = function(inst, target)
            inst.Physics:Stop()
            if target and target:IsValid() then 
                inst.sg.statemem.target = target
                inst:ForceFacePoint(target.Transform:GetWorldPosition())
                inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/boarrior/stun")
                inst.AnimState:PlayAnimation("attack1") 
                inst.lastCombo = GetTime()
            end
        end,
		
		timeline =
        {
            TimeEvent(12 * FRAMES, function(inst) --20 frames total
                inst.components.combat:DoAttack(inst.sg.statemem.target) 
            end), 
        },

		events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("combosecondhit", inst.sg.statemem.target)
            end),
        },
    },
	
	State{
        name = "combosecondhit",
        tags = { "busy", "attack" },
        onenter = function(inst, target)
            if target and target:IsValid() then --inst.components.combat:CanAttack(inst.sg.statemem.target) then
                inst.sg.statemem.target = target
                inst.Physics:Stop()
                inst.AnimState:PlayAnimation("attack2") 
            else
                inst.sg:GoToState("idle")
            end
        end,
		
		timeline =
        {
            TimeEvent(3 * FRAMES, function(inst) -- 9 frames total
                inst.components.combat:DoAttack(inst.sg.statemem.target) 
            end), 
        },

		events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("combothirdhit", inst.sg.statemem.target)
                --inst.sg:GoToState("dash")
            end),
        },
    },
	
	State{
        name = "combothirdhit",
        tags = { "busy", "attack" },
        onenter = function(inst, target)
            if target and target:IsValid()
                and not target.components.health:IsDead() 
            then
                inst.Physics:Stop()
                inst.sg.statemem.target = target
                inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/boarrior/stun")
                inst:ForceFacePoint(target.Transform:GetWorldPosition())
                inst.AnimState:PlayAnimation("attack3") 
            else
                inst.sg:GoToState("idle")
            end
        end,
		
		timeline =
        {
            TimeEvent(7 * FRAMES, function(inst) --25 frames total
                local sm = inst.sg.statemem
                if sm.target and sm.target:IsValid()
                    and not sm.target.components.health:IsDead() 
                then
                    inst:ComboHit(sm.target)
                end
                inst:ReTarget(inst)
                inst.components.combat.laststartattacktime = GetTime()
            end), 
        },

		events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

}

CommonStates.AddSleepStates(states,
{
    --[[ starttimeline =
    {
        
    }, ]]
    sleeptimeline = {
        TimeEvent(0, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/boarrior/sleep_out") end),
        --TimeEvent(9 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/boarrior/sleep_in") end),
    },
})

CommonStates.AddWalkStates(states,
{
    walktimeline =
    {
        TimeEvent(0, function(inst) 
            ShakeAllCameras(CAMERASHAKE.VERTICAL, .5, .03, 1, inst, 30)
            inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/boarrior/step") 
        end),
        TimeEvent(18, function(inst) 
            ShakeAllCameras(CAMERASHAKE.VERTICAL, .5, .03, 1, inst, 30)
            inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/boarrior/step") 
        end),
    },
})

CommonStates.AddFrozenStates(states)

return StateGraph("lavaarena_boarrior", states, events, "taunt", actionhandlers)
