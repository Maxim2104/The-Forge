local TIMEOUT = 2
local function ToggleOffPhysics(inst)
    inst.sg.statemem.isphysicstoggle = true
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.GROUND)
end
local function ToggleOnPhysics(inst)
    inst.sg.statemem.isphysicstoggle = nil
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.WORLD)
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
    inst.Physics:CollidesWith(COLLISION.SMALLOBSTACLES)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)
    inst.Physics:CollidesWith(COLLISION.GIANTS)
end

local combat_leap_start = State{
        name = "combat_leap_start",
        tags = { "aoe", "doing", "busy", "nointerrupt", "nomorph" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("atk_leap_pre")

            local weapon = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if weapon ~= nil and weapon.components.aoetargeting ~= nil and weapon.components.aoetargeting.targetprefab ~= nil then
                local buffaction = inst:GetBufferedAction()
                if buffaction ~= nil and buffaction.pos ~= nil then
                    inst.sg.statemem.targetfx = SpawnPrefab(weapon.components.aoetargeting.targetprefab)
                    if inst.sg.statemem.targetfx ~= nil then
                        inst.sg.statemem.targetfx.Transform:SetPosition(buffaction.pos:Get())
                    end
                end
            end
        end,

        events =
        {
            EventHandler("combat_leap", function(inst, data)
                inst.sg.statemem.leap = true
                inst.sg:GoToState("combat_leap", {
                    targetfx = inst.sg.statemem.targetfx,
                    data = data,
                })
            end),
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    if inst.AnimState:IsCurrentAnimation("atk_leap_pre") then
                        inst.AnimState:PlayAnimation("atk_leap_lag")
                        inst:PerformBufferedAction()
                    else
                        inst.sg:GoToState("idle")
                    end
                end
            end),
        },

        onexit = function(inst)
            if not inst.sg.statemem.leap and inst.sg.statemem.targetfx ~= nil and inst.sg.statemem.targetfx:IsValid() then
                (inst.sg.statemem.targetfx.KillFX or inst.sg.statemem.targetfx.Remove)(inst.sg.statemem.targetfx)
            end
        end,
}

local combat_leap = State{
        name = "combat_leap",
        tags = { "aoe", "doing", "busy", "nointerrupt", "nopredict", "nomorph" },

        onenter = function(inst, data)
            if data ~= nil then
                inst.sg.statemem.targetfx = data.targetfx
                data = data.data
                if data ~= nil and
                    data.targetpos ~= nil and
                    data.weapon ~= nil and
                    data.weapon.components.aoeweapon_leap ~= nil and
                    inst.AnimState:IsCurrentAnimation("atk_leap_lag") then
                    ToggleOffPhysics(inst)
                    inst.AnimState:PlayAnimation("atk_leap")
                    inst.SoundEmitter:PlaySound("dontstarve/common/deathpoof")
                    inst.sg.statemem.startingpos = inst:GetPosition()
                    inst.sg.statemem.weapon = data.weapon
                    inst.sg.statemem.targetpos = data.targetpos
                    inst.sg.statemem.flash = 0
                    if inst.sg.statemem.startingpos.x ~= data.targetpos.x or inst.sg.statemem.startingpos.z ~= data.targetpos.z then
                        inst:ForceFacePoint(data.targetpos:Get())
                        inst.Physics:SetMotorVel(math.sqrt(distsq(inst.sg.statemem.startingpos.x, inst.sg.statemem.startingpos.z, data.targetpos.x, data.targetpos.z)) / (12 * FRAMES), 0 ,0)
                    end
                    return
                end
            end
            --Failed
            inst.sg:GoToState("idle", true)
        end,

        onupdate = function(inst)
            if inst.sg.statemem.flash > 0 then
                inst.sg.statemem.flash = math.max(0, inst.sg.statemem.flash - .1)
                local c = math.min(1, inst.sg.statemem.flash)
                inst.components.colouradder:PushColour("leap", c, c, 0, 0)
            end
        end,

        timeline =
        {
            TimeEvent(4 * FRAMES, function(inst)
                if inst.sg.statemem.targetfx ~= nil and inst.sg.statemem.targetfx:IsValid() then
                    (inst.sg.statemem.targetfx.KillFX or inst.sg.statemem.targetfx.Remove)(inst.sg.statemem.targetfx)
                    inst.sg.statemem.targetfx = nil
                end
            end),
            TimeEvent(10 * FRAMES, function(inst)
                inst.components.colouradder:PushColour("leap", .1, .1, 0, 0)
            end),
            TimeEvent(11 * FRAMES, function(inst)
                inst.components.colouradder:PushColour("leap", .2, .2, 0, 0)
            end),
            TimeEvent(12 * FRAMES, function(inst)
                inst.components.colouradder:PushColour("leap", .4, .4, 0, 0)
                ToggleOnPhysics(inst)
                inst.Physics:Stop()
                inst.Physics:SetMotorVel(0, 0, 0)
                inst.Physics:Teleport(inst.sg.statemem.targetpos.x, 0, inst.sg.statemem.targetpos.z)
            end),
            TimeEvent(13 * FRAMES, function(inst)
	           local pos = Vector3()
			
			local x, y, z = inst.Transform:GetWorldPosition()
	SpawnPrefab("hammer_mjolnir_crackle").Transform:SetPosition(x, y, z)
    SpawnPrefab("hammer_mjolnir_cracklebase").Transform:SetPosition(x, y, z)

    inst.SoundEmitter:PlaySound("dontstarve/impacts/lava_arena/hammer")
    
                ShakeAllCameras(CAMERASHAKE.VERTICAL, .7, .015, .8, inst, 20)
                inst.components.bloomer:PushBloom("leap", "shaders/anim.ksh", -2)
                inst.components.colouradder:PushColour("leap", 1, 1, 0, 0)
                inst.sg.statemem.flash = 1.3
                inst.sg:RemoveStateTag("nointerrupt")
                if inst.sg.statemem.weapon:IsValid() then
                    inst.sg.statemem.weapon.components.aoeweapon_leap:DoLeap(inst, inst.sg.statemem.startingpos, inst.sg.statemem.targetpos)
                end
            end),
            TimeEvent(25 * FRAMES, function(inst)
                inst.components.bloomer:PopBloom("leap")
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            if inst.sg.statemem.isphysicstoggle then
                ToggleOnPhysics(inst)
                inst.Physics:Stop()
                inst.Physics:SetMotorVel(0, 0, 0)
                local x, y, z = inst.Transform:GetWorldPosition()
                if TheWorld.Map:IsPassableAtPoint(x, 0, z) and not TheWorld.Map:IsGroundTargetBlocked(Vector3(x, 0, z)) then
                    inst.Physics:Teleport(x, 0, z)
                else
                    inst.Physics:Teleport(inst.sg.statemem.targetpos.x, 0, inst.sg.statemem.targetpos.z)
                end
            end
            inst.components.bloomer:PopBloom("leap")
            inst.components.colouradder:PopColour("leap")
            if inst.sg.statemem.targetfx ~= nil and inst.sg.statemem.targetfx:IsValid() then
                (inst.sg.statemem.targetfx.KillFX or inst.sg.statemem.targetfx.Remove)(inst.sg.statemem.targetfx)
            end
        end,
} 
	
local combat_leap_start_client = State{
        name = "combat_leap_start",
        tags = { "doing", "busy", "nointerrupt" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("atk_leap_pre")
            inst.AnimState:PlayAnimation("atk_leap_lag", false)

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst:HasTag("doing") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.sg:GoToState("idle")
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end,
}
local superjump_start = State{
        name = "superjump_start",
        tags = { "aoe", "doing", "busy", "nointerrupt", "nomorph" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("superjump_pre")

            local weapon = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if weapon ~= nil and weapon.components.aoetargeting ~= nil and weapon.components.aoetargeting.targetprefab ~= nil then
                local buffaction = inst:GetBufferedAction()
                if buffaction ~= nil and buffaction.pos ~= nil then
                    inst.sg.statemem.targetfx = SpawnPrefab(weapon.components.aoetargeting.targetprefab)
                    if inst.sg.statemem.targetfx ~= nil then
                        inst.sg.statemem.targetfx.Transform:SetPosition(buffaction.pos:Get())
                    end
                end
            end
        end,

        events =
        {
            EventHandler("superjump", function(inst, data)
                inst.sg.statemem.superjump = true
                inst.sg:GoToState("superjump", {
                    targetfx = inst.sg.statemem.targetfx,
                    data = data,
                })
            end),
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    if inst.AnimState:IsCurrentAnimation("superjump_pre") then
                        inst.AnimState:PlayAnimation("superjump_lag")
                        inst:PerformBufferedAction()
                    else
                        inst.sg:GoToState("idle")
                    end
                end
            end),
        },

        onexit = function(inst)
            if not inst.sg.statemem.superjump and inst.sg.statemem.targetfx ~= nil and inst.sg.statemem.targetfx:IsValid() then
                (inst.sg.statemem.targetfx.KillFX or inst.sg.statemem.targetfx.Remove)(inst.sg.statemem.targetfx)
            end
        end,
    }

local superjump = State{
        name = "superjump",
        tags = { "aoe", "doing", "busy", "nointerrupt", "nopredict", "nomorph" },

        onenter = function(inst, data)
            if data ~= nil then
                inst.sg.statemem.targetfx = data.targetfx
                inst.sg.statemem.data = data
                data = data.data
                if data ~= nil and
                    data.targetpos ~= nil and
                    data.weapon ~= nil and
                    data.weapon.components.aoeweapon_leap ~= nil and
                    inst.AnimState:IsCurrentAnimation("superjump_lag") then
                    ToggleOffPhysics(inst)
                    inst.AnimState:PlayAnimation("superjump")
                    inst.AnimState:SetMultColour(.8, .8, .8, 1)
                    inst.components.colouradder:PushColour("superjump", .1, .1, .1, 0)
                    inst.sg.statemem.data.startingpos = inst:GetPosition()
                    inst.sg.statemem.weapon = data.weapon
                    if inst.sg.statemem.data.startingpos.x ~= data.targetpos.x or inst.sg.statemem.data.startingpos.z ~= data.targetpos.z then
                        inst:ForceFacePoint(data.targetpos:Get())
                    end
                    inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt", nil, .4)
                    inst.SoundEmitter:PlaySound("dontstarve/common/deathpoof")
                    inst.sg:SetTimeout(1)
                    return
                end
            end
            --Failed
            inst.sg:GoToState("idle", true)
        end,

        onupdate = function(inst)
            if inst.sg.statemem.dalpha ~= nil and inst.sg.statemem.alpha > 0 then
                inst.sg.statemem.dalpha = math.max(.1, inst.sg.statemem.dalpha - .1)
                inst.sg.statemem.alpha = math.max(0, inst.sg.statemem.alpha - inst.sg.statemem.dalpha)
                inst.AnimState:SetMultColour(0, 0, 0, inst.sg.statemem.alpha)
            end
        end,

        timeline =
        {
            TimeEvent(FRAMES, function(inst)
                inst.DynamicShadow:Enable(false)
                inst.sg:AddStateTag("noattack")
                inst.components.health:SetInvincible(true)
                inst.AnimState:SetMultColour(.5, .5, .5, 1)
                inst.components.colouradder:PushColour("superjump", .3, .3, .2, 0)
                inst:PushEvent("dropallaggro")
                if inst.sg.statemem.weapon ~= nil and inst.sg.statemem.weapon:IsValid() then
                    inst.sg.statemem.weapon:PushEvent("superjumpstarted", inst)
                end
            end),
            TimeEvent(2 * FRAMES, function(inst)
                inst.AnimState:SetMultColour(0, 0, 0, 1)
                inst.components.colouradder:PushColour("superjump", .6, .6, .4, 0)
            end),
            TimeEvent(3 * FRAMES, function(inst)
                inst.sg.statemem.alpha = 1
                inst.sg.statemem.dalpha = .5
            end),
            TimeEvent(1 - 7 * FRAMES, function(inst)
                if inst.sg.statemem.targetfx ~= nil and inst.sg.statemem.targetfx:IsValid() then
                    (inst.sg.statemem.targetfx.KillFX or inst.sg.statemem.targetfx.Remove)(inst.sg.statemem.targetfx)
                    inst.sg.statemem.targetfx = nil
                end
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst:Hide()
                    inst.Physics:Teleport(inst.sg.statemem.data.data.targetpos.x, 0, inst.sg.statemem.data.data.targetpos.z)
                end
            end),
        },

        ontimeout = function(inst)
            inst.sg.statemem.superjump = true
            inst.sg.statemem.data.isphysicstoggle = inst.sg.statemem.data.isphysicstoggle
            inst.sg.statemem.data.targetfx = nil
            inst.sg:GoToState("combat_superjump_pst", inst.sg.statemem.data)
        end,

        onexit = function(inst)
            if not inst.sg.statemem.superjump then
                inst.components.health:SetInvincible(false)
                if inst.sg.statemem.isphysicstoggle then
                    ToggleOnPhysics(inst)
                end
                inst.components.colouradder:PopColour("superjump")
                inst.AnimState:SetMultColour(1, 1, 1, 1)
                inst.DynamicShadow:Enable(true)
                if inst.sg.statemem.weapon ~= nil and inst.sg.statemem.weapon:IsValid() then
                    inst.sg.statemem.weapon:PushEvent("superjumpcancelled", inst)
                end
            end
            if inst.sg.statemem.targetfx ~= nil and inst.sg.statemem.targetfx:IsValid() then
                (inst.sg.statemem.targetfx.KillFX or inst.sg.statemem.targetfx.Remove)(inst.sg.statemem.targetfx)
            end
            inst:Show()
        end,
    }

local superjump_pst = State{
        name = "superjump_pst",
        tags = { "aoe", "doing", "busy", "noattack", "nopredict", "nomorph" },

        onenter = function(inst, data)
            if data ~= nil and data.data ~= nil then
                inst.sg.statemem.startingpos = data.startingpos
                inst.sg.statemem.isphysicstoggle = data.isphysicstoggle
                data = data.data
                inst.sg.statemem.weapon = data.weapon
                if inst.sg.statemem.startingpos ~= nil and
                    data.targetpos ~= nil and
                    data.weapon ~= nil and
                    data.weapon.components.aoeweapon_leap ~= nil and
                    inst.AnimState:IsCurrentAnimation("superjump") then
                    inst.AnimState:PlayAnimation("superjump_land")
                    inst.AnimState:SetMultColour(.4, .4, .4, .4)
                    inst.sg.statemem.targetpos = data.targetpos
                    inst.sg.statemem.flash = 0
                    if not inst.sg.statemem.isphysicstoggle then
                        ToggleOffPhysics(inst)
                    end
                    inst.Physics:Teleport(data.targetpos.x, 0, data.targetpos.z)
                    inst.components.health:SetInvincible(true)
                    inst.sg:SetTimeout(22 * FRAMES)
                    return
                end
            end
            --Failed
            inst.sg:GoToState("idle", true)
        end,

        onupdate = function(inst)
            if inst.sg.statemem.flash > 0 then
                inst.sg.statemem.flash = math.max(0, inst.sg.statemem.flash - .1)
                local c = math.min(1, inst.sg.statemem.flash)
                inst.components.colouradder:PushColour("superjump", c, c, 0, 0)
            end
        end,

        timeline =
        {
            TimeEvent(FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon")
                inst.AnimState:SetMultColour(.7, .7, .7, .7)
                inst.components.colouradder:PushColour("superjump", .1, .1, 0, 0)
            end),
            TimeEvent(2 * FRAMES, function(inst)
                inst.AnimState:SetMultColour(.9, .9, .9, .9)
                inst.components.colouradder:PushColour("superjump", .2, .2, 0, 0)
            end),
            TimeEvent(3 * FRAMES, function(inst)
                inst.AnimState:SetMultColour(1, 1, 1, 1)
                inst.components.colouradder:PushColour("superjump", .4, .4, 0, 0)
                inst.DynamicShadow:Enable(true)
            end),
            TimeEvent(4 * FRAMES, function(inst)
                inst.components.colouradder:PushColour("superjump", 1, 1, 0, 0)
                inst.components.bloomer:PushBloom("superjump", "shaders/anim.ksh", -2)
                ToggleOnPhysics(inst)
                ShakeAllCameras(CAMERASHAKE.VERTICAL, .7, .015, .8, inst, 20)
                inst.sg.statemem.flash = 1.3
                inst.sg:RemoveStateTag("noattack")
                inst.components.health:SetInvincible(false)
                if inst.sg.statemem.weapon:IsValid() then
                    inst.sg.statemem.weapon.components.aoeweapon_leap:DoLeap(inst, inst.sg.statemem.startingpos, inst.sg.statemem.targetpos)
                    inst.sg.statemem.weapon = nil
                end
            end),
            TimeEvent(8 * FRAMES, function(inst)
                inst.components.bloomer:PopBloom("superjump")
            end),
            TimeEvent(19 * FRAMES, PlayFootstep),
        },

        ontimeout = function(inst)
            inst.sg:GoToState("idle", true)
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            if inst.sg.statemem.isphysicstoggle then
                ToggleOnPhysics(inst)
            end
            inst.AnimState:SetMultColour(1, 1, 1, 1)
            inst.DynamicShadow:Enable(true)
            inst.components.health:SetInvincible(false)
            inst.components.bloomer:PopBloom("superjump")
            inst.components.colouradder:PopColour("superjump")
            if inst.sg.statemem.weapon ~= nil and inst.sg.statemem.weapon:IsValid() then
                inst.sg.statemem.weapon:PushEvent("superjumpcancelled", inst)
            end
        end,
}

local superjump_start_client = State
    {
        name = "superjump_start",
        tags = { "doing", "busy", "nointerrupt" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("superjump_pre")
            inst.AnimState:PlayAnimation("superjump_lag", false)

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst:HasTag("doing") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.sg:GoToState("idle")
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end,
    }
local blowdart_special = State
    {
        name = "blowdart_special",
        tags = { "doing", "busy", "nointerrupt", "nomorph" },

        onenter = function(inst)
            local buffaction = inst:GetBufferedAction()
            local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("dart_pre")
            if equip ~= nil and equip:HasTag("aoeblowdart_long") then
                inst.sg.statemem.long = true
                inst.AnimState:PushAnimation("dart_long", false)
                inst.sg:SetTimeout(29 * FRAMES)
            else
                inst.AnimState:PushAnimation("dart", false)
                inst.sg:SetTimeout(22 * FRAMES)
            end

            if buffaction ~= nil and buffaction.pos ~= nil then
                inst:ForceFacePoint(buffaction.pos:Get())
            end

            if (equip ~= nil and equip.projectiledelay or 0) > 0 then
                --V2C: Projectiles don't show in the initial delayed frames so that
                --     when they do appear, they're already in front of the player.
                --     Start the attack early to keep animation in sync.
                inst.sg.statemem.projectiledelay = 14 * FRAMES - equip.projectiledelay
                if inst.sg.statemem.projectiledelay <= 0 then
                    inst.sg.statemem.projectiledelay = nil
                end
            end
        end,

        onupdate = function(inst, dt)
            if (inst.sg.statemem.projectiledelay or 0) > 0 then
                inst.sg.statemem.projectiledelay = inst.sg.statemem.projectiledelay - dt
                if inst.sg.statemem.projectiledelay <= 0 then
                    inst:PerformBufferedAction()
                    inst.sg:RemoveStateTag("nointerrupt")
                end
            end
        end,

        timeline =
        {
            TimeEvent(13 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/wilson/blowdart_shoot")
            end),
            TimeEvent(14 * FRAMES, function(inst)
                if inst.sg.statemem.projectiledelay == nil then
                    inst:PerformBufferedAction()
                    inst.sg:RemoveStateTag("nointerrupt")
                end
            end),
            TimeEvent(20 * FRAMES, function(inst)
                if inst.sg.statemem.long then
                    inst.SoundEmitter:PlaySound("dontstarve/wilson/blowdart_shoot", nil, .4)
                end
            end),
        },

        ontimeout = function(inst)
            inst.sg:GoToState("idle", true)
        end,

        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    }
	
local blowdart_special_client = State
    {
        name = "blowdart_special",
        tags = { "doing", "busy", "nointerrupt" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("dart_pre")
            inst.AnimState:PushAnimation("dart_lag", false)

            local buffaction = inst:GetBufferedAction()
            if buffaction ~= nil then
                inst:PerformPreviewBufferedAction()

                if buffaction.pos ~= nil then
                    inst:ForceFacePoint(buffaction.pos:Get())
                end
            end

            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst:HasTag("doing") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.sg:GoToState("idle")
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end,
    }

return {
	wilson = {
		combat_leap_start = combat_leap_start,
		combat_leap = combat_leap,
		superjump_start = superjump_start,
		superjump = superjump,
		superjump_pst = superjump_pst,
		blowdart_special = blowdart_special,

	},
	wilson_client = {
		superjump_start = superjump_start_client,
		combat_leap_start = combat_leap_start_client,
		blowdart_special = blowdart_special_client,

	}
}