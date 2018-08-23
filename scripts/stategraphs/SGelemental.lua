require("stategraphs/commonstates")

local actionshandlers = {
	ActionHandler(ACTIONS.ATTACK, "attack"),
}

local events = {
	EventHandler("attacked", function(inst)
		if not inst.sg:HasStateTag("attack") then
			inst.sg:GoToState("hit")
		end
	end),
  EventHandler("death", function(inst)
		inst.sg:GoToState("death", inst.sg.statemem.dead)
	end),
}

local states = {
	State {
		name = "spawn",
		tags = { "spawn", "canrotate", "busy" },
		onenter = function(inst)
			inst.AnimState:PlayAnimation("spawn")
		end,
		events = {
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end)
		},
	},
	State {
		name = "idle",
		tags = { "idle", "canrotate" },
		onenter = function(inst, playanim)
			inst.Physics:Stop()
			if playanim then
				inst.AnimState:PlayAnimation(playanim)
				inst.AnimState:PushAnimation("idle", true)
			else
				inst.AnimState:PlayAnimation("idle", true)
			end
			if inst._task == nil then
				inst._task = inst:DoTaskInTime(TUNING.MOD_LAVAARENA.BOOK_ELEMENTAL.SPELLDURATION, function(inst)
					inst.sg:GoToState("death")
				end)
			end
		end,
	},
	State {
		name = "attack",
		tags = { "attack", "busy" },
		onenter = function(inst, target)
			inst.sg.statemem.target = target
			inst.Physics:Stop()
			inst.components.combat:StartAttack()
			inst.AnimState:PlayAnimation("attack", false)
			if inst._task == nil then
				inst._task = inst:DoTaskInTime(TUNING.MOD_LAVAARENA.BOOK_ELEMENTAL.SPELLDURATION, function(inst)
					inst.sg:GoToState("death")
				end)
			end
		end,
		timeline = {
			TimeEvent(5*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/common/lava_arena/fireball")
				--inst.components.combat:DoAttack(inst.sg.statemem.target)
				inst.components.combat:DoAttack()
			end),
			TimeEvent(16*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/common/lava_arena/fireball")
				--inst.components.combat:DoAttack(inst.sg.statemem.target)
				inst.components.combat:DoAttack()
			end),
    },
		events = {
			EventHandler("animover", function(inst)
				if inst.components.combat.target and inst.components.combat.target.components.health and not inst.components.combat.target.components.health:IsDead() then
					inst.sg:GoToState("attack")
				else
					inst.sg:GoToState("idle")
				end
			end),
		},
	},
	State {
		name = "hit",
		tags = { "hit", "busy" },
		onenter = function(inst)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("hit")
			if inst._task then
				inst._task:Cancel()
			end
		end,
		events = {
			EventHandler("animover", function(inst)
				inst.sg:GoToState("death")
			end)
		},
	},
	State {
		name = "death",
		tags = { "busy" },
		onenter = function(inst)
			inst.AnimState:PlayAnimation("death")
			inst.Physics:Stop()
			RemovePhysicsColliders(inst)
		end,
		events = {
			EventHandler("animover", function(inst) inst:Remove() end)
		},
	},
}

return StateGraph("lavaarena_elemental", states, events, "spawn", actionshandlers)