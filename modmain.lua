local require = GLOBAL.require

PrefabsFiles = {
    "books_lavaarena.lua",
    "lavaarena_boarrior",
    "lavaarena_boarriormeteor",
    "groundfire",
    "lavaarena_portal",
    "lavaarena_boarriorfireburst",
    "lavaarena_boaron",
    "lavaarena_peghook",
    "lavaarena_turtillus",
    "lavaarena_trails",
    "lavaarena_snapper",
}
modimport("portal/state")

Assets = {
    Asset("ATLAS", "images/inventoryimages/lavaarena_armorlight.xml"),
    Asset("IMAGE", "images/inventoryimages/lavaarena_armorlight.tex"),
    Asset("ATLAS", "images/inventoryimages/lavaarena_armorlightspeed.xml"),
    Asset("IMAGE", "images/inventoryimages/lavaarena_armorlightspeed.tex"),
    Asset("ATLAS", "images/inventoryimages/lavaarena_armormedium.xml"),
    Asset("IMAGE", "images/inventoryimages/lavaarena_armormedium.tex"),
    Asset("ATLAS", "images/inventoryimages/lavaarena_armormediumdamager.xml"),
    Asset("IMAGE", "images/inventoryimages/lavaarena_armormediumdamager.tex"),
    Asset("ATLAS", "images/inventoryimages/lavaarena_armormediumrecharger.xml"),
    Asset("IMAGE", "images/inventoryimages/lavaarena_armormediumrecharger.tex"),
    Asset("ATLAS", "images/inventoryimages/lavaarena_armorheavy.xml"),
    Asset("IMAGE", "images/inventoryimages/lavaarena_armorheavy.tex"),
    Asset("ATLAS", "images/inventoryimages/lavaarena_armorextraheavy.xml"),
    Asset("IMAGE", "images/inventoryimages/lavaarena_armorextraheavy.tex"),
    Asset("ATLAS", "images/inventoryimages/lavaarena_feathercrownhat.xml"),
    Asset("IMAGE", "images/inventoryimages/lavaarena_feathercrownhat.tex"),
    Asset("ATLAS", "images/inventoryimages/lavaarena_lightdamagerhat.xml"),
    Asset("IMAGE", "images/inventoryimages/lavaarena_lightdamagerhat.tex"),
    Asset("ATLAS", "images/inventoryimages/lavaarena_rechargerhat.xml"),
    Asset("IMAGE", "images/inventoryimages/lavaarena_rechargerhat.tex"),
    Asset("ATLAS", "images/inventoryimages/lavaarena_healingflowerhat.xml"),
    Asset("IMAGE", "images/inventoryimages/lavaarena_healingflowerhat.tex"),
    Asset("ATLAS", "images/inventoryimages/lavaarena_tiaraflowerpetalshat.xml"),
    Asset("IMAGE", "images/inventoryimages/lavaarena_tiaraflowerpetalshat.tex"),
    Asset("ATLAS", "images/inventoryimages/lavaarena_strongdamagerhat.xml"),
    Asset("IMAGE", "images/inventoryimages/lavaarena_strongdamagerhat.tex"),
    Asset("ATLAS", "images/inventoryimages/lavaarena_crowndamagerhat.xml"),
    Asset("IMAGE", "images/inventoryimages/lavaarena_crowndamagerhat.tex"),
    Asset("ATLAS", "images/inventoryimages/lavaarena_healinggarlandhat.xml"),
    Asset("IMAGE", "images/inventoryimages/lavaarena_healinggarlandhat.tex"),
    Asset("ATLAS", "images/inventoryimages/lavaarena_eyecirclethat.xml"),
    Asset("IMAGE", "images/inventoryimages/lavaarena_eyecirclethat.tex"),
    
    Asset("ATLAS", "images/inventoryimages/blowdart_lava.xml"),
    Asset("IMAGE", "images/inventoryimages/blowdart_lava.tex"),
    Asset("ATLAS", "images/inventoryimages/blowdart_lava2.xml"),
    Asset("IMAGE", "images/inventoryimages/blowdart_lava2.tex"),
    Asset("ATLAS", "images/inventoryimages/fireballstaff.xml"),
    Asset("IMAGE", "images/inventoryimages/fireballstaff.tex"),
    Asset("ATLAS", "images/inventoryimages/healingstaff.xml"),
    Asset("IMAGE", "images/inventoryimages/healingstaff.tex"),
    Asset("ATLAS", "images/inventoryimages/hammer_mjolnir.xml"),
    Asset("IMAGE", "images/inventoryimages/hammer_mjolnir.tex"),
    Asset("ATLAS", "images/inventoryimages/spear_gungnir.xml"),
    Asset("IMAGE", "images/inventoryimages/spear_gungnir.tex"),
    Asset("ATLAS", "images/inventoryimages/spear_lance.xml"),
    Asset("IMAGE", "images/inventoryimages/spear_lance.tex"),
    Asset("ATLAS", "images/inventoryimages/lavaarena_lucy.xml"),
    Asset("IMAGE", "images/inventoryimages/lavaarena_lucy.tex"),
    Asset("ATLAS", "images/inventoryimages/book_fossil.xml"),
    Asset("IMAGE", "images/inventoryimages/book_fossil.tex"),
    Asset("ATLAS", "images/inventoryimages/book_elemental.xml"),
    Asset("IMAGE", "images/inventoryimages/book_elemental.tex"),
    Asset("ATLAS", "images/tabimages/theforge_tab.xml"),
    Asset("IMAGE", "images/tabimages/theforge_tab.tex"),
}

if GLOBAL.TheNet:GetServerGameMode() == "lavaarena" then
    
    local SpawnPrefab = GLOBAL.SpawnPrefab
    local DEGREES = GLOBAL.DEGREES
    local Vector3 = GLOBAL.Vector3
    
    modimport "lavaarena_worldtimer.lua"
    modimport "lavaarena_enemys.lua"
    
    local function OnLoadWorld(inst, data)
        if data then
            if data.deathonload then
                inst:DoTaskInTime(7, function(inst)
                    inst.lavaarena_world_state = "death"
                    inst.lavaarena_timer_active = true
                    inst.lavaarena_seconds = 10
                    GLOBAL.TheNet:Announce("WARNING!!! EVENT DONT CAN BE LOAD!")
                    GLOBAL.TheNet:Announce("SERVER REGENERATE MAP IN 10 SECONDS")
                end)
            end
        end
        if inst.Old_L ~= nil then
            return inst.Old_L(inst, data)
        end
    end
    
    if GLOBAL.TheNet:GetServerGameMode() == "lavaarena" then
        local function CheckEveryPlayer(inst, checktype)
            if GLOBAL.AllPlayers[1] ~= nil then
                local totalplayers = 0
                for k, v in pairs (GLOBAL.AllPlayers) do
                    if checktype == "dead" then
                        if v:HasTag("corpse") then
                            totalplayers = totalplayers + 1
                        end
                    end
                end
                if #GLOBAL.AllPlayers == totalplayers then
                    return true
                else
                    return false
                end
            else
                return false
            end
        end
        
        AddPrefabPostInit("world", function(inst)
            if GLOBAL.TheWorld.ismastersim then
                inst.Old_S = inst.OnSave
                inst.Old_L = inst.OnLoad
                inst.OnSave = OnSaveWorld
                inst.OnLoad = OnLoadWorld
                inst:DoTaskInTime(0, function()
                    inst:DoPeriodicTask(20, function()
                        inst:PushEvent("ms_setphase", "day", TheWorld)
                    end)
                    GLOBAL.TheWorld:PushEvent("lavaarena_begin")
                end)
                inst:DoPeriodicTask(1, function()
                    if inst.lavaarena_world_state ~= "death" and CheckEveryPlayer(inst, "dead") then
                        inst.lavaarena_world_state = "death"
                        inst.lavaarena_timer_active = true
                        inst.lavaarena_seconds = 10
                        for k, v in pairs (GLOBAL.AllPlayers) do
                        end
                    end
                end)
                inst:ListenForEvent("ms_newplayercharacterspawned", function(world, data)
                    if data and data.player then
                        data.player:DoTaskInTime(0, function(inst)
                        end)
                    end
                end, GLOBAL.TheWorld)
            end
        end)
    end
end


local function UserOnline(clienttable, userid)
    local found = false
    for k, v in pairs(clienttable) do
        if v.userid == userid then
            found = true
        end
    end
    return found
end


local function GetPlayerTable()
    local clienttbl = GLOBAL.TheNet:GetClientTable()
    if clienttbl == nil then
        return {}
    elseif GLOBAL.TheNet:GetServerIsClientHosted() then
        return clienttbl
    end

    for i, v in ipairs(clienttbl) do
        if v.performance ~= nil then
            table.remove(clienttbl, i)
            break
        end
    end
    return clienttbl
end


local function SetDirty(netvar, val)
    netvar:set_local(val)
    netvar:set(val)
end

AddPrefabPostInit("lavaarena_center", function(inst)
    if not GLOBAL.TheWorld.ismastersim then
        GLOBAL.TheWorld:PushEvent("ms_register_lavaarenacenter", inst)
    end
end)


AddPrefabPostInit("world", function(inst)
    if inst.ismastersim and GLOBAL.TheNet:GetServerGameMode() == "lavaarena" then
    end
    inst:ListenForEvent("ms_register_lavaarenacenter", function(world, center)
        world.centerpoint = center
    end)
end)


AddPrefabPostInit("lavaarena_network", function(inst)
    if GLOBAL.TheNet:GetServerGameMode() == "lavaarena" then
        inst:AddComponent("worldvoter")
    end
end)
---------------------------------------------------------------------

AddModRPCHandler(modname, "locationrequest", function(inst, x, z)
    local pos = GLOBAL.Vector3(x, 0, z)
    inst._spintargetpos = pos
end)


AddComponentPostInit('health', function(self, inst)
    self.OnUpdate = function(dt)
        if self.lastfiredamagetime ~= nil then
            local time = GLOBAL.GetTime()

            if time - self.lastfiredamagetime > .5 then
                self.takingfiredamage = false
                self.inst:StopUpdatingComponent(self)
                self.inst:PushEvent("stopfiredamage")
                GLOBAL.ProfileStatsAdd("fireout")
                inst.isUpdatingHealth = false
            end
        end
        self:Recalc(dt)
    end

    function self:Recalc(dt)
        local x, y, z = self.inst.Transform:GetWorldPosition()
        local aura_found = false
        local aura_delta = 0
        -- Finding entities
        local ents = TheSim:FindEntities(x, y, z, 4)
        for i, v in ipairs(ents) do
            if v.components.healthaura ~= nil and v ~= self.inst then
                local head = doer and doer.components.inventory and doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD) or nil
                local mult = head and head.healreceivemult or 1
                aura_delta = aura_delta + v.components.healthaura:GetAura(self.inst) * mult

                if not aura_found then
                    aura_found = true
                    if self.inst.bloomhealbuff == nil then
                        self.inst.bloomhealbuff = GLOBAL.SpawnPrefab("lavaarena_bloomhealbuff");
                    end
                    self.inst:AddChild(self.inst.bloomhealbuff)
                end
            end
        end

        if not aura_found and self.inst.bloomhealbuff ~= nil then
            self.inst:RemoveChild(self.inst.bloomhealbuff)
            self.inst.bloomhealbuff = nil
        end

        self:DoDelta(aura_delta, true)
    end

    self.LongUpdate = self.OnUpdate
end)

AddPlayerPostInit(function(inst)
    inst:ListenForEvent('locomote', function(inst)
        if inst.components.health ~= nil and (not inst.isUpdatingHealth or inst.isUpdatingHealth == nil) then
            inst:StartUpdatingComponent(inst.components.health)
            inst.isUpdatingHealth = true
        end
    end)
end)

local stategraph_postinits = require("stategraph_postinits")
for stategraph, states in pairs(stategraph_postinits) do
    for _, state in pairs(states) do
        AddStategraphState(stategraph, state)
    end
end
for k, v in pairs({"wilson", "wilson_client"}) do
    AddStategraphPostInit(v, function(self)
        local deststate_castaoe_old = self.actionhandlers[GLOBAL.ACTIONS.CASTAOE].deststate
        self.actionhandlers[GLOBAL.ACTIONS.CASTAOE].deststate = function(inst, act)
            return act.invobject ~= nil and
            act.invobject:HasTag("focusattack") and "focusattack" or
            act.invobject:HasTag("combat_jump") and "combat_jump_start" or
            act.invobject:HasTag("superjump") and "superjump_start" or
            act.invobject:HasTag("shelluse") and "shelluse" or
            deststate_castaoe_old(inst, act)
        end
    end)
end

AddComponentPostInit("combat", function(self)
    function self:DoDamageWithMods(target, damage, damageType)
        if not (target and target.components.combat and damage) then return end
        
        --local playermultiplier = target ~= nil and target:HasTag("player")
        --local pvpmultiplier = playermultiplier and self.inst:HasTag("player") and self.pvp_damagemod or 1
        
        local calcDamage = damage * self:GetDamageMods()
        
        target.components.combat:GetAttacked(self.inst, calcDamage, nil, damageType)
    end
    
    function self:GetDamageMods()
        return self.externaldamagemultipliers:Get() * (self.damagemultiplier or 1)
    end
end)

modimport "scripts/tuning.lua"

---------------------------------------
local cdset = {
    ["blowdart_lava"]   =   {cd = 30, damage = 20, aoe = 20},
    ["blowdart_lava2"]  =   {cd = 30, damage = 25, aoe = 60},
    ["book_elemental"]  =   {cd = 40, damage = 15, aoe = 0},
    ["book_fossil"]     =   {cd = 30, damage = 15, aoe = 0},
    ["fireballstaff"]   =   {cd = 50, damage = 25, aoe = 210},
    ["hammer_mjolnir"]  =   {cd = 20, damage = 20, aoe = 45},
    ["healingstaff"]    =   {cd = 40, damage = 10, aoe = 0.2},
    ["spear_gungnir"]   =   {cd = 30, damage = 20, aoe = 45},
    ["spear_lance"]     =   {cd = 50, damage = 30, aoe = 175},
}

for k, v in pairs(cdset) do
    AddPrefabPostInit(k, function(inst)
        if inst.components.aoespell then
            inst.components.aoespell:SetPeriod(v.cd or 60)
            inst.components.aoespell:SetAOE(v.aoe or 0)
        end
        if inst.components.weapon then
            inst.components.weapon:SetDamage(v.damage or 20)
        end
    end)
end
--[[
 
AddPrefabPostInit("waxwell",function(inst)
    inst:AddComponent("chongneng")
    inst.components.chongneng:SetN(500)
    inst.components.chongneng:SetFN(function(inst, data)
        local target = data.target
        local damage = data.damage
            inst:StartThread(function()
        for i,v in ipairs({0,45,90,135,180,225,270,315}) do
        if target ~= nil and not target.components.health:IsDead() then
        target.components.combat:GetAttacked(inst, damage, nil, nil,"AOE")
    local fx = GLOBAL.SpawnPrefab("shadowstrike_slash_fx")
    fx.Transform:SetRotation(v)
    fx.entity:SetParent(target.entity)
    fx.Transform:SetPosition(0,1,0)
    else
    break
    end
GLOBAL.Sleep(0.1)
end
end)
end)
end)
--]]
AddPrefabPostInit("webber", function(inst)
    inst._bb = {}
    inst:DoTaskInTime(0, function()
        for i = 1, 3 do
            local zhizhu = GLOBAL.SpawnPrefab("spider")
            if zhizhu then
                zhizhu.persists = false
                zhizhu._zhuren = inst
                --MakeGhostPhysics(zhizhu, 1, 0.3)
                table.insert(inst._bb, zhizhu)
                local x, y, z = inst.Transform:GetWorldPosition()
                zhizhu.Transform:SetPosition(x, y, z)
                zhizhu.AnimState:SetScale(0.4, 0.4)
                zhizhu.components.combat:SetDefaultDamage(3)
                zhizhu.components.combat:SetAttackPeriod(1)
                zhizhu.components.health:SetInvincible(true)
                if zhizhu.components.follower == nil then
                    zhizhu:AddComponent("follower")
                end
                zhizhu.components.follower:KeepLeaderOnAttacked()
                zhizhu.components.follower.keepdeadleader = true
                inst.components.leader:AddFollower(zhizhu)
                zhizhu:SetBrain(BI_1)
            end
        end
    end)
end)

--[[
AddPrefabPostInit("wathgrithr",function(inst)
inst:AddComponent("chongneng")
inst.components.chongneng:SetN(500)
inst.components.chongneng:SetFN(function(inst)
for k,v in pairs(GLOBAL.AllPlayers) do
if v and not v:HasTag("playerghost") then
v._ewaishanghai = 30
local fx = GLOBAL.SpawnPrefab("wathgrithr_bloodlustbuff_self")
fx.entity:SetParent(v.entity)
end
end
end)
end)
--]]
local function KillWendy(inst, data)
    if inst._abigail == nil and data.victim then
        local abigail = GLOBAL.SpawnPrefab("lavaarena_abigail")
        local x, y, z = data.victim.Transform:GetWorldPosition()
        abigail.Transform:SetPosition(x, y, z)
        inst._abigail = abigail
        abigail:LinkToPlayer(inst)
    end
end

AddPrefabPostInit("wendy", function(inst)
    inst._abigail = nil
    inst:ListenForEvent("killed", KillWendy)
end)
