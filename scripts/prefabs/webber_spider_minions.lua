local assets =
{
    Asset("ANIM", "anim/ds_spider_basic.zip"),
    Asset("ANIM", "anim/spider_build.zip"),
    Asset("SOUND", "sound/spider.fsb"),
}

local prefab =
{
    "die_fx",
}

local SCALE = .5

local function OnAttacked(inst, data)
    if data.attacker ~= nil then
		if data.attacker.components.combat ~= nil then
			inst.components.combat:SuggestTarget(data.attacker)
		end
	end
end

local function retargetfn(inst)
    --Find things attacking leader
    local leader = inst.components.follower:GetLeader()
    return leader ~= nil
        and FindEntity(
            leader,
            TUNING.SHADOWWAXWELL_TARGET_DIST,
            function(guy)
                return guy ~= inst
                    and (guy.components.combat:TargetIs(leader) or
                        guy.components.combat:TargetIs(inst))
                    and inst.components.combat:CanTarget(guy)
            end,
            { "_combat" }, -- see entityreplica.lua
            { "playerghost", "INLIMBO" }
        )
        or nil
end

local function keeptargetfn(inst, target)
    --Is your leader nearby and your target not dead? Stay on it.
    --Match KEEP_WORKING_DIST in brain
    return inst.components.follower:IsNearLeader(14)
        and inst.components.combat:CanTarget(target)
end

local function DoReturn(inst)
    local home = inst.components.homeseeker ~= nil and inst.components.homeseeker.home or nil
    if home ~= nil and
        home.components.childspawner ~= nil and
        not (inst.components.follower ~= nil and
            inst.components.follower.leader ~= nil) then
        home.components.childspawner:GoHome(inst)
    end
end


local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLightWatcher()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 10, .2)

    inst.DynamicShadow:SetSize(1.5 * SCALE, .25 * SCALE)

    inst.Transform:SetScale(SCALE, SCALE, SCALE)
    inst.Transform:SetFourFaced()

    inst.AnimState:SetBank("spider")
    inst.AnimState:SetBuild("spider_build")
    inst.AnimState:PlayAnimation("idle", true)
	
	inst:SetPrefabNameOverride("spider")
	
    inst:AddTag("scarytoprey")
    inst:AddTag("smallcreature")
    inst:AddTag("spider")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	
	inst.OnEntitySleep = DoReturn
	
	-- locomotor must be constructed before the stategraph!
    inst:AddComponent("locomotor")
    inst.components.locomotor:SetSlowMultiplier( 1 )
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.pathcaps = { ignorecreep = true }

    inst:SetStateGraph("SGwebber_minion")
	inst:SetBrain(require "brains/webber_minion_brain")

    ---------------------        
    MakeMediumBurnableCharacter(inst, "body")
    MakeMediumFreezableCharacter(inst, "body")
    inst.components.burnable.flammability = TUNING.SPIDER_FLAMMABILITY
    ---------------------     
    inst:AddComponent("health")
	inst.components.health:SetMaxHealth(350)
	inst.components.health.nofadeout = true
	inst.components.health:StartRegen(6, 5)
		
    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "body"
	inst.components.combat:SetRange(2)
    inst.components.combat:SetDefaultDamage(10)
    inst.components.combat:SetAttackPeriod(TUNING.SHADOWWAXWELL_ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(2, retargetfn) --Look for leader's target.
    inst.components.combat:SetKeepTargetFunction(keeptargetfn) --Keep attacking while leader is near.

    inst:AddComponent("follower")
	inst.components.follower:KeepLeaderOnAttacked()
	inst.components.follower.keepdeadleader = true
    ------------------
    inst:AddComponent("inspectable")
	
    inst:AddComponent("colourtweener")


    inst:ListenForEvent("attacked", OnAttacked)
    --inst:ListenForEvent("death", OnDeath)

    return inst
end

return Prefab("webber_spider_minion", fn, assets, prefabs)
