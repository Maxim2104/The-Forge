require("stategraphs/commonstates")

function TableConcat(t1,t2)
    for i=1,#t2 do
        t1[#t1+1] = t2[i]
    end
    return t1
end

local function DoSwarmAttack(inst)
    inst.components.combat:DoAreaAttack(inst, inst.components.combat.hitrange - 0.5, nil, nil, nil, { "INLIMBO", "notarget", "invisible", "noattack", "playerghost", "shadow", "shadowcreature", "shadowminion" })
end

local actionhandlers = 
{
    ActionHandler(ACTIONS.GOHOME, "action"),
	ActionHandler(ACTIONS.ATTACK, function(inst)
		if inst.altattack and inst.altattack == true then
			return "attack2"
		else
			return "attack"
		end	
	end),
	ActionHandler(ACTIONS.PICKUP, "action"),
	ActionHandler(ACTIONS.DROP, "action"),
	ActionHandler(ACTIONS.EAT, "action"),
	ActionHandler(ACTIONS.HEAL, "action"),
	ActionHandler(ACTIONS.PICK, "action"),
	ActionHandler(ACTIONS.ACTIVATE, "action"),
	ActionHandler(ACTIONS.FEED, "action"),
	ActionHandler(ACTIONS.PET, "action"),
	ActionHandler(ACTIONS.DEPLOY, "action"),
	ActionHandler(ACTIONS.GIVE, "action"),
	ActionHandler(ACTIONS.GIVETOPLAYER, "action"),
	ActionHandler(ACTIONS.GIVEALLTOPLAYER, "action"),
	ActionHandler(ACTIONS.JUMPIN, "action"),
	ActionHandler(ACTIONS.TRAVEL, "action"),
	ActionHandler(ACTIONS.LOOKAT, "action"),
	ActionHandler(ACTIONS.COOK, "action"),
	ActionHandler(ACTIONS.FILL, "action"),
	ActionHandler(ACTIONS.DRY, "action"),
	ActionHandler(ACTIONS.ADDFUEL, "action"),
	ActionHandler(ACTIONS.ADDWETFUEL, "action"),
	ActionHandler(ACTIONS.LIGHT, "action"),
	ActionHandler(ACTIONS.MIGRATE, "action"),
	ActionHandler(ACTIONS.WRAPBUNDLE, "action"),
	ActionHandler(ACTIONS.UNWRAP, "action"),
	ActionHandler(ACTIONS.UNLOCK, "action"),
	ActionHandler(ACTIONS.USEKLAUSSACKKEY, "action"),	
	
}

local mobCraftActions =
{
ActionHandler(ACTIONS.GOHOME, "gohome"),
	ActionHandler(ACTIONS.ATTACK, function(inst)
		if inst.altattack and inst.altattack == true then
			return "attack2"
		else
			return "attack"
		end	
	end),
	ActionHandler(ACTIONS.PICKUP, "action"),
	ActionHandler(ACTIONS.FEED, "action"),
	ActionHandler(ACTIONS.PET, "action"),
	ActionHandler(ACTIONS.PICK, "action"),
	ActionHandler(ACTIONS.DROP, "action"),
	ActionHandler(ACTIONS.ACTIVATE, "action"),
	ActionHandler(ACTIONS.EAT, "action"),
	ActionHandler(ACTIONS.HEAL, "action"),
	ActionHandler(ACTIONS.FAN, "action"),
	ActionHandler(ACTIONS.DIG, "work"),
	ActionHandler(ACTIONS.CHOP, "work"),
	ActionHandler(ACTIONS.MINE, "work"),
	ActionHandler(ACTIONS.GIVE, "action"),
	ActionHandler(ACTIONS.GIVEALLTOPLAYER, "action"),
	ActionHandler(ACTIONS.COOK, "action"),
	ActionHandler(ACTIONS.FILL, "action"),
	ActionHandler(ACTIONS.DRY, "work"),
	ActionHandler(ACTIONS.ADDFUEL, "work"),
	ActionHandler(ACTIONS.ADDWETFUEL, "work"),
	ActionHandler(ACTIONS.LIGHT, "work"),
	ActionHandler(ACTIONS.BAIT, "action"),
	ActionHandler(ACTIONS.BUILD, "work"),
	ActionHandler(ACTIONS.PLANT, "action"),
	ActionHandler(ACTIONS.REPAIR, "work"),
	ActionHandler(ACTIONS.HARVEST, "action"),
	ActionHandler(ACTIONS.STORE, "action"),
	ActionHandler(ACTIONS.RUMMAGE, "action"),
	ActionHandler(ACTIONS.DEPLOY, "action"),
	ActionHandler(ACTIONS.HAMMER, "work"),
	ActionHandler(ACTIONS.FERTILIZE, "action"),
	ActionHandler(ACTIONS.MURDER, "action"),
	ActionHandler(ACTIONS.UNLOCK, "action"),
	ActionHandler(ACTIONS.TURNOFF, "action"),
	ActionHandler(ACTIONS.TURNON, "action"),
	ActionHandler(ACTIONS.SEW, "action"),
	ActionHandler(ACTIONS.COMBINESTACK, "action"),
	ActionHandler(ACTIONS.UPGRADE, "action"),
	ActionHandler(ACTIONS.WRITE, "action"),
	ActionHandler(ACTIONS.FEEDPLAYER, "action"),
	ActionHandler(ACTIONS.TERRAFORM, "action"),
	ActionHandler(ACTIONS.NET, "action"),
	ActionHandler(ACTIONS.CHECKTRAP, "action"),
	ActionHandler(ACTIONS.SHAVE, "action"),
	ActionHandler(ACTIONS.FISH, "action"),
	ActionHandler(ACTIONS.REEL, "action"),
	ActionHandler(ACTIONS.CATCH, "action"),
	ActionHandler(ACTIONS.TEACH, "action"),
	ActionHandler(ACTIONS.MANUALEXTINGUISH, "work"),
	ActionHandler(ACTIONS.RESETMINE, "action"),
	ActionHandler(ACTIONS.BLINK, "action"),
	--ActionHandler(ACTIONS.CHANGEIN, "changeskin"),
	ActionHandler(ACTIONS.SMOTHER, "work"),
	ActionHandler(ACTIONS.WRAPBUNDLE, "action"),
	ActionHandler(ACTIONS.UNWRAP, "action"),
	ActionHandler(ACTIONS.UNLOCK, "action"),
	ActionHandler(ACTIONS.USEKLAUSSACKKEY, "action"),
	ActionHandler(ACTIONS.CASTSPELL, "action"),
}


local extraActions = 
{
	--ActionHandler(ACTIONS.SLEEPIN, "sleep"),
	ActionHandler(ACTIONS.TRAVEL, "taunt"),
	ActionHandler(ACTIONS.LOOKAT, "taunt"),
}

if MOBCRAFT_EVENT == "Enable" then
	extraActions = mobCraftActions
end

actionhandlers = TableConcat(actionhandlers, extraActions)

local function SetSleeperAwakeState(inst)
    if inst.components.grue ~= nil then
        inst.components.grue:RemoveImmunity("sleeping")
    end
    if inst.components.talker ~= nil then
        inst.components.talker:StopIgnoringAll("sleeping")
    end
    if inst.components.firebug ~= nil then
        inst.components.firebug:Enable()
    end
    if inst.components.playercontroller ~= nil then
        inst.components.playercontroller:EnableMapControls(true)
        inst.components.playercontroller:Enable(true)
    end
    inst:OnWakeUp()
    inst.components.inventory:Show()
    inst:ShowActions(true)
	--inst.sg:GoToState("taunt")
end

local function SetSleeperSleepState(inst)
    if inst.components.grue ~= nil then
        inst.components.grue:AddImmunity("sleeping")
    end
    if inst.components.talker ~= nil then
        inst.components.talker:IgnoreAll("sleeping")
    end
    if inst.components.firebug ~= nil then
        inst.components.firebug:Disable()
    end
    if inst.components.playercontroller ~= nil then
        inst.components.playercontroller:EnableMapControls(false)
        inst.components.playercontroller:Enable(false)
    end
    inst:OnSleepIn()
    inst.components.inventory:Hide()
    inst:PushEvent("ms_closepopups")
    inst:ShowActions(false)
end

local events=
{
    EventHandler("attacked", function(inst) 
		if not inst.components.health:IsDead() and not inst.sg:HasStateTag("busy") then 
			inst.sg:GoToState("hit") 
		end 
	end),
    EventHandler("death", function(inst) inst.sg:GoToState("death") end),
    EventHandler("doattack", function(inst, data) if not inst.components.health:IsDead() and (inst.sg:HasStateTag("hit") or not inst.sg:HasStateTag("busy")) then inst.sg:GoToState("attack", data.target) end end),
    CommonHandlers.OnSleep(),
    CommonHandlers.OnLocomote(true,false),
    CommonHandlers.OnFreeze(),
	
	 EventHandler("ms_opengift",
        function(inst)
            if not inst.sg:HasStateTag("busy") then
                inst.sg:GoToState("opengift")
            end
        end),
		
	EventHandler("respawnfromghost", function(inst)  
			if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:Enable(true)
            end

            inst.components.health:SetInvincible(false)
            inst:ShowHUD(true)
            inst:SetCameraDistance()

            SerializeUserSession(inst) end),	
}


 local states=
{

    State{
        name = "idle",
        tags = {"idle", "canrotate"},
        onenter = function(inst, playanim)
            --inst.SoundEmitter:PlaySound("dontstarve/creatures/hound/pant")
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("idle_loop", true)
        end,

    },
	
	State{
        name = "work", 
        tags = {"busy"},
		
		onenter = function(inst, target)
        inst.components.locomotor:Stop()
        inst.Physics:Stop()
        inst.AnimState:PlayAnimation("attack_pre")
		inst.AnimState:PushAnimation("attack", false)
	end,
	
    timeline=
    {

			TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/peghook/grunt") 
			--inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderwarrior/attack_grunt")
			end), --spikes out
			TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/peghook/attack")
			--inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
			end), --spikes in
			TimeEvent(13*FRAMES, function(inst) inst:PerformBufferedAction() end),
    },

        events=
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle")  end),
        },
	
    },
	
	State{
		name = "work2",
        tags = {"busy"},

        onenter = function(inst, cb)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")
        end,

		timeline=
        {
			TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/peghook/taunt") 
			--inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderwarrior/scream")
			end),
        },

        events=
        {
			EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
		
	},	

    State{
        name = "attack", 
        tags = {"attack", "busy"},
		
		  onenter = function(inst, target)
        local buffaction = inst:GetBufferedAction()
        local target = buffaction ~= nil and buffaction.target or nil
        inst.components.combat:SetTarget(target)
        inst.components.combat:StartAttack()
        inst.components.locomotor:Stop()
        inst.Physics:Stop()
        inst.AnimState:PlayAnimation("attack_pre")
		inst.AnimState:PushAnimation("attack", false)
        if target ~= nil then
            if target:IsValid() then
                inst:FacePoint(target:GetPosition())
                inst.sg.statemem.attacktarget = target
            end
        end
	end,
	
	onexit = function(inst)
        inst.components.combat:SetTarget(nil)
    end,
	
    timeline=
    {

			TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/peghook/grunt") 
			--inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderwarrior/attack_grunt")
			end), --spikes out
			TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/peghook/attack")
			--inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
			end), --spikes in
			TimeEvent(13*FRAMES, function(inst) inst:PerformBufferedAction() end),
    },

        events=
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle", "atk_pst")  end),
        },
	
    },
	
	State{
        name = "attack2",
        tags = {"attack", "busy"},

        onenter = function(inst)
            --inst.components.combat:StartAttack()
			
			local buffaction = inst:GetBufferedAction()
			local target = buffaction ~= nil and buffaction.target or nil
			inst.components.combat:SetTarget(target)
			if target ~= nil then
            if target:IsValid() then
                inst:FacePoint(target:GetPosition())
                inst.sg.statemem.attacktarget = target
				end
			end
			inst.sg.statemem.target = target
			inst.AnimState:PlayAnimation("attack_pre")
            inst.AnimState:PushAnimation("spit", false)
        end,

        timeline=
        {

            TimeEvent(0*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/peghook/taunt")
				--inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderwarrior/scream")
            end),                
            TimeEvent(12*FRAMES, function(inst) 
				inst.components.combat:SetRange(0)
				inst:PerformBufferedAction()
				inst.altattack = false
				inst.components.combat:SetRange(3.5)
                inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/lava_arena/peghook/spit")
            end),
            TimeEvent(30*FRAMES, function(inst) inst.altattack = false end),
        },
        
        events=
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end),
        },
		
		onexit = function(inst)
			inst:DoTaskInTime(20, function(inst) inst.altattack = true end) --incase interupted		
		end
    },	
		
	State{
        name = "opengift",
        tags = { "busy", "pausepredict" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.components.locomotor:Clear()
            inst:ClearBufferedAction()

            --if IsNearDanger(inst) then
                --inst.sg.statemem.isdanger = true
                --inst.sg:GoToState("idle")
                --if inst.components.talker ~= nil then
                   -- inst.components.talker:Say(GetString(inst, "ANNOUNCE_NODANGERGIFT"))
                --end
                --return
           -- end

            inst.SoundEmitter:PlaySound("dontstarve/common/player_receives_gift")
            inst.AnimState:PlayAnimation("taunt")
            inst.AnimState:PushAnimation("taunt", true)
            -- NOTE: the previously used ripping paper anim is called "giift_loop"

            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:RemotePausePrediction()
                inst.components.playercontroller:EnableMapControls(false)
                inst.components.playercontroller:Enable(false)
            end
            inst.components.inventory:Hide()
            inst:PushEvent("ms_closepopups")
            inst:ShowActions(false)
            inst:ShowGiftItemPopUp(true)

            if inst.components.giftreceiver ~= nil then
                inst.components.giftreceiver:OnStartOpenGift()
            end
        end,

        timeline =
        {
            -- Timing of the gift box opening animation on giftitempopup.lua
            TimeEvent(155 * FRAMES, function(inst)
               -- inst.AnimState:PlayAnimation("gift_open_pre")
                inst.AnimState:PushAnimation("taunt", true)
            end),
        },

        events =
        {
            EventHandler("firedamage", function(inst)
                inst.AnimState:PlayAnimation("taunt")
                inst.sg:GoToState("idle", true)
                if inst.components.talker ~= nil then
                    inst.components.talker:Say(GetString(inst, "ANNOUNCE_NODANGERGIFT"))
                end
            end),
            EventHandler("ms_doneopengift", function(inst, data)
				inst.sg:GoToState("idle", true)
                
            end),
        },

        onexit = function(inst)
            if inst.sg.statemem.isdanger then
                return
            elseif not inst.sg.statemem.isopeningwardrobe then
                if inst.components.playercontroller ~= nil then
                    inst.components.playercontroller:EnableMapControls(true)
                    inst.components.playercontroller:Enable(true)
                end
                inst.components.inventory:Show()
                inst:ShowActions(true)
            end
            inst:ShowGiftItemPopUp(false)
        end,
    },
	
	State{
		name = "hit",
        tags = {"busy", "hit"},

        onenter = function(inst, cb)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("hit") 
			inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/peghook/hit")--hit_2 if it doesn't work
			--inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderwarrior/hit")
        end,

        events=
        {
			EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
	
	
	State{
		name = "special_atk1ev",
        tags = {"busy"},

        onenter = function(inst, cb)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")
        end,

		timeline=
        {
			TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/peghook/taunt") 
			--inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderwarrior/scream")
			end),
        },

        events=
        {
			EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },	
	
	State{
		name = "action",
        tags = {"busy"},

        onenter = function(inst, cb)
            inst.Physics:Stop()
			inst:PerformBufferedAction()
            inst.AnimState:PlayAnimation("run_pst")
        end,

		timeline=
        {

        },

        events=
        {
			EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
	
    State{
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
			inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/peghook/death")
			--inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderwarrior/die")
            inst.AnimState:PlayAnimation("death")
            inst.Physics:Stop()
            RemovePhysicsColliders(inst)     
			inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))
			inst.components.inventory:DropEverything(true)
        end,

		timeline = 
		{
			TimeEvent(5*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/peghook/bodyfall") end ),
		},
		
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
					if MOBGHOST_EVENT == "Enable" then
                     inst:PushEvent(inst.ghostenabled and "makeplayerghost" or "playerdied", { skeleton = false })
					else
						TheWorld:PushEvent("ms_playerdespawnanddelete", inst)
					end
                end
            end),
        },

    },
	
	State {
        name = "sleep",
        tags = { "sleeping", "busy" }, --add tag "busy" if you hate sliding

        onenter = function(inst)
            if inst.components.locomotor ~= nil then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("sleep_pre")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/peghook/taunt")
			--inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderwarrior/fallAsleep")
            --if fns ~= nil and fns.onsleep ~= nil then
                --fns.onsleep(inst)
            --end
        end,

        timeline=
        {
			TimeEvent(45*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt") end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("sleeping") end ),
            EventHandler("onwakeup", function(inst) inst.sg:GoToState("wake") end),
        },
    },

    State
    {
        name = "sleeping",
        tags = { "sleeping", "busy" },

        --onenter = onentersleeping,
		
		onenter = function(inst)
				inst.components.locomotor:StopMoving()
				--if inst.components.sanity.current >= 50 then
				local hungerpercent = inst.components.hunger:GetPercent()
				inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/peghook/sleep_in")
				--inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderwarrior/sleeping")
				if hungerpercent ~= nil and hungerpercent ~= 0 then -- We don't want players to heal out starvation.
				inst.components.health:DoDelta(12, false)
				end
				--end
				--inst.components.sanity:DoDelta(1, false)
				--inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/sleep")
				inst.AnimState:PlayAnimation("sleep_loop")
			end,
			
		onexit = function(inst)
		--inst.components.sanity.dapperness = -0.5
		end,
        --timeline = timelines ~= nil and timelines.sleeptimeline or nil,
		timeline=
        {
			TimeEvent(20*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/peghook/sleep_out") end),
        },

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("sleeping") end ),
			EventHandler("onwakeup", function(inst) inst.sg:GoToState("wake") end),
        },
    },

    State
    {
        name = "wake",
        tags = { "busy", "waking" },

        onenter = function(inst)
            if inst.components.locomotor ~= nil then
                inst.components.locomotor:StopMoving()
            end
			inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/peghook/grunt")
			--inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderwarrior/wakeUp")
            inst.AnimState:PlayAnimation("sleep_pst")
            if inst.components.sleeper ~= nil and inst.components.sleeper:IsAsleep() then
                inst.components.sleeper:WakeUp()
            end
            --if fns ~= nil and fns.onwake ~= nil then
                --fns.onwake(inst)
            --end
        end,

        --timeline = timelines ~= nil and timelines.waketimeline or nil,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
	
	State
    {
        name = "run_start",
        tags = { "moving", "running", "canrotate" },

        onenter = function(inst)
			inst.components.locomotor:RunForward()
            inst.AnimState:PlayAnimation("run_pre")
			
        end,
		
		timeline = 
		{
			--TimeEvent(0*FRAMES, function(inst) inst.Physics:Stop() end ),
		},
		
        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("run") end ),
        },
    },
	
	State
    {
        name = "run",
        tags = { "moving", "running", "canrotate" },

        onenter = function(inst)
			inst.components.locomotor:RunForward()
			inst.AnimState:PlayAnimation("run_loop")
        end,
		
		timeline = {
		    TimeEvent(1*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/peghook/step") end),
			TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/peghook/step") end),
			TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/peghook/step") end),
			TimeEvent(15*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/peghook/step") end),       
			TimeEvent(20*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/peghook/step") end),
			TimeEvent(25*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/peghook/step") end),
			TimeEvent(30*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/peghook/step") end),
			TimeEvent(36*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/peghook/step") end),
			TimeEvent(44*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/peghook/step") end),
		},
		
        events=
			{
				EventHandler("animqueueover", function(inst) inst.sg:GoToState("run") end ),
			},

    },
	
	State
    {
        name = "run_stop",
        tags = { "idle" },

        onenter = function(inst) 
            inst.components.locomotor:StopMoving()
			inst.AnimState:PlayAnimation("run_pst")
			
            
        end,

        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end ),
        },
    },
	
	State{
		name = "stun",
        tags = {"busy"},

        onenter = function(inst, cb)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("stun_loop")
        end,

		timeline=
        {
			--TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/turtillus/stun") end),
        },
		
		onexit = function(inst)
            
        end,

        events=
        {
			EventHandler("animover", function(inst) inst.sg:GoToState("stun_pst") end),
        },
    },
	
	State{
		name = "stun_pst",
        tags = {"busy"},

        onenter = function(inst, cb)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("stun_pst")
        end,

		timeline=
        {
			--TimeEvent(10*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/turtillus/hide_pst") end),
        },
		
		onexit = function(inst)
            
        end,

        events=
        {
			EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
	
}

--CommonStates.AddFrozenStates(states)



    
return StateGraph("peghookp", states, events, "idle", actionhandlers)

