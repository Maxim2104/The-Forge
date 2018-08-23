local DEGREES = GLOBAL.DEGREES
local MAX_WAVES = 15
local STRINGS = GLOBAL.STRINGS
local LanguageTranslator = GLOBAL.LanguageTranslator

-- fix translation things
if LanguageTranslator.defaultlang then
    -- LanguageTranslator.languages[LanguageTranslator.defaultlang]["STRINGS.BOARLORD_ROUND5_FIGHT_BANTER1.1"]
    for k,v in pairs(STRINGS) do
        if string.sub(k, 1, 8) == "BOARLORD" then
            for k2,v2 in pairs(v) do
                local localized = LanguageTranslator.languages[LanguageTranslator.defaultlang]["STRINGS."..k.."."..k2]
                if localized then
                    STRINGS[k][k2] = localized
                end
                -- print("STRINGS["..k.."]["..k2.."] = ", STRINGS[k][k2])
            end
        end
    end
end


local NameToPrefab = {
    Jagged_Wood_Armor     = "lavaarena_armormediumdamager",
    Barbed_Helm           = "lavaarena_lightdamagerhat",
    Crystal_Tiara         = "lavaarena_rechargerhat",
    Feathered_Wreath      = "lavaarena_feathercrownhat",

    Stone_Splint_Mail     = "lavaarena_armorheavy",
    Silken_Wood_Armor     = "lavaarena_armormediumrecharger",
    Woven_Garland         = "lavaarena_tiaraflowerpetalshat",
    Flower_Headband       = "lavaarena_healingflowerhat",

    Healing_Staff         = "healingstaff",
    Molten_Dart           = "blowdart_lava2",
    Spiral_Spear          = "spear_lance",
    Nox_Helm              = "lavaarena_strongdamagerhat",
    Meteor_Staff          = "fireballstaff",
    Steadfast_Stone_Armor = "lavaarena_armorextraheavy",
    Clairvoyant_Crown     = "lavaarena_eyecirclethat",
    Tome_of_Beckoning     = "book_elemental",
    Resplendent_Nox_Helm  = "lavaarena_crowndamagerhat",
    Blossomed_Wreath      = "lavaarena_healinggarlandhat",
}



-- Reference: http://dontstarve.wikia.com/wiki/The_Forge#Rounds
local WaveData = 
{
    -- WaveData[1]
    -- wave 1: 1 Pit Pig
    {
        msg = {
            {txt = STRINGS.BOARLORD_WELCOME_INTRO[1], delay = 0}, 
            {txt = STRINGS.BOARLORD_WELCOME_INTRO[2], delay = 2}, 
            {txt = STRINGS.BOARLORD_WELCOME_INTRO[3], delay = 4}, 
            {txt = STRINGS.BOARLORD_WELCOME_INTRO[4], delay = 6}, 
            {txt = STRINGS.BOARLORD_WELCOME_INTRO[5], delay = 8}, 
        }, 
        mobdelay = 10, 
        mobnum = 3,
        mob = {
            {"boaron", }, 
            {"boaron", }, 
            {"boaron", }, 
        }
    },
    -- WaveData[2]
    -- wave 2: 2 Pit Pigs
    {
        msg = {
            -- no message from Pugna
        }, 
        mobdelay = 0, 
        mobnum = 6,
        mob = {
            {"boaron", "boaron", }, 
            {"boaron", "boaron", }, 
            {"boaron", "boaron", }, 
        },
        moboffset = {
            {{theta=90,r=1.5},{theta=-90,r=1.5}},
            {{theta=90,r=1.5},{theta=-90,r=1.5}},
            {{theta=90,r=1.5},{theta=-90,r=1.5}}
        }
    },
    -- WaveData[3]
    -- wave 3: 3 Pit Pigs
    {
        msg = {
            {txt = STRINGS.BOARLORD_ROUND1_FIGHT_BANTER[1], delay = 0}, 
            {txt = STRINGS.BOARLORD_ROUND1_FIGHT_BANTER[2], delay = 2}, 
        }, 
        mobdelay = 4, 
        mobnum = 9,
        mob = {
            {"boaron", "boaron", "boaron", }, 
            {"boaron", "boaron", "boaron", }, 
            {"boaron", "boaron", "boaron", }, 
        },
        moboffset = {
            {{theta=90,r=1.5},{theta=210,r=1.5},{theta=-30,r=1.5}},
            {{theta=30,r=1.5},{theta=150,r=1.5},{theta=-90,r=1.5}},
            {{theta=90,r=1.5},{theta=210,r=1.5},{theta=-30,r=1.5}}
        }
    },
    -- WaveData[4]
    -- wave 4: 4 Pit Pigs
    {
        msg = {
            {txt = STRINGS.BOARLORD_ROUND1_FIGHT_BANTER[3], delay = 0}, 
            {txt = STRINGS.BOARLORD_ROUND1_FIGHT_BANTER[4], delay = 2}, 
        }, 
        mobdelay = 4, 
        mobnum = 12,
        mob = {
            {"boaron", "boaron", "boaron", "boaron", }, 
            {"boaron", "boaron", "boaron", "boaron", }, 
            {"boaron", "boaron", "boaron", "boaron", }, 
        },
        moboffset = {
            {{theta=0,r=1.5},{theta=90,r=1.5},{theta=180,r=1.5},{theta=-90,r=1.5}},
            {{theta=0,r=1.5},{theta=90,r=1.5},{theta=180,r=1.5},{theta=-90,r=1.5}},
            {{theta=0,r=1.5},{theta=90,r=1.5},{theta=180,r=1.5},{theta=-90,r=1.5}}
        }
    },
    -- WaveData[5]
    -- wave 5: 1 Crocovile and 3 Pit Pigs
    {
        msg = {
            {txt = STRINGS.BOARLORD_ROUND1_END[1], delay = 0}, 
            {txt = STRINGS.BOARLORD_ROUND1_END[2], delay = 2}, 
            {txt = STRINGS.BOARLORD_ROUND1_END[3], delay = 4}, 
        }, 
        mobdelay = 6, 
        mobnum = 8,
        mob = {
            {"snapper", "boaron", "boaron", "boaron", }, 
            {},
            {"snapper", "boaron", "boaron", "boaron", }, 
        },
        moboffset = {
            {{theta=0,r=0},{theta=0,r=1.5},{theta=90,r=1.5},{theta=180,r=1.5}},
            {},
            {{theta=0,r=0},{theta=0,r=1.5},{theta=90,r=1.5},{theta=180,r=1.5}}
        }
    },
    -- WaveData[6]
    -- wave 6: 1 Crocovile and 3 Pit Pigs (again)
    {
        msg = {
            {txt = STRINGS.BOARLORD_ROUND2_FIGHT_BANTER[1], delay = 0}, 
            {txt = STRINGS.BOARLORD_ROUND2_FIGHT_BANTER[2], delay = 2}, 
            {txt = STRINGS.BOARLORD_ROUND2_FIGHT_BANTER[3], delay = 4}, 
        }, 
        mobdelay = 6, 
        mobnum = 8,
        mob = {
            {"snapper", "boaron", "boaron", "boaron", }, 
            {},
            {"snapper", "boaron", "boaron", "boaron", }, 
        },
        moboffset = {
            {{theta=0,r=0},{theta=0,r=1.5},{theta=90,r=1.5},{theta=180,r=1.5}},
            {},
            {{theta=0,r=0},{theta=0,r=1.5},{theta=90,r=1.5},{theta=180,r=1.5}}
        }
    },
    -- WaveData[7]
    -- wave 7: 7 Tortanks
    {
        msg = {
            {txt = STRINGS.BOARLORD_ROUND2_END[1], delay = 0}, 
            {txt = STRINGS.BOARLORD_ROUND2_END[2], delay = 2}, 
            {txt = STRINGS.BOARLORD_ROUND2_END[3], delay = 4}, 
            {txt = STRINGS.BOARLORD_ROUND2_END[4], delay = 6}, 
        }, 
        mobdelay = 8, 
        mobnum = 7,
        mob = {
            {"turtillus", "turtillus", }, 
            {"turtillus", "turtillus", "turtillus", }, 
            {"turtillus", "turtillus", }, 
        },
        moboffset = {
            {{theta=90,r=1.5},{theta=-90,r=1.5}},
            {{theta=30,r=1.5},{theta=150,r=1.5},{theta=-90,r=1.5}},
            {{theta=90,r=1.5},{theta=-90,r=1.5}}
        }
    },
    -- WaveData[8]
    -- wave 8: 7 Venomeers
    {
        msg = {
            {txt = STRINGS.BOARLORD_ROUND3_END[1], delay = 0}, 
            {txt = STRINGS.BOARLORD_ROUND3_END[2], delay = 2}, 
            {txt = STRINGS.BOARLORD_ROUND3_END[3], delay = 4}, 
            {txt = STRINGS.BOARLORD_ROUND3_END[4], delay = 6}, 
            {txt = STRINGS.BOARLORD_ROUND3_END[5], delay = 8}, 
            {txt = STRINGS.BOARLORD_ROUND3_END[6], delay = 10}, 
        },
        mobdelay = 12, 
        mobnum = 7,
        mob = {
            {"peghook", "peghook", }, 
            {"peghook", "peghook", "peghook", }, 
            {"peghook", "peghook", }, 
        },
        moboffset = {
            {{theta=90,r=1.5},{theta=-90,r=1.5}},
            {{theta=30,r=1.5},{theta=150,r=1.5},{theta=-90,r=1.5}},
            {{theta=90,r=1.5},{theta=-90,r=1.5}}
        }
    },
    -----------------------------------
    -----------------------------------
    -- WaveData[9]
    -- wave 9: 1 Tortanks + 1 Venomeers
    {
        msg = {
            {txt = STRINGS.BOARLORD_ROUND4_FIGHT_BANTER[1], delay = 0}, 
            {txt = STRINGS.BOARLORD_ROUND4_FIGHT_BANTER[2], delay = 2}, 
        }, 
        mobdelay = 4, 
        mobnum = 4,
        mob = {
            {"turtillus", "peghook", }, 
            {}, 
            {"turtillus", "peghook", }, 
        },
        moboffset = {
            {{theta=90,r=1.5},{theta=-90,r=1.5}},
            {},
            {{theta=90,r=1.5},{theta=-90,r=1.5}}
        }
    },
    -- WaveData[10]
    -- wave 10: 1 Boarilla
    {
        msg = {
            {txt = STRINGS.BOARLORD_TRAILS_INTRO[1], delay = 0}, 
        }, 
        -- mobdelay = 18, 
        mobdelay = 2, 
        mobnum = 1,
        mob = {
            {}, 
            {"trails", }, 
            {}, 
        }
    },
    -----------------------------------
    -----------------------------------
    -- WaveData[11]
    -- wave 11: 2 Boarilla
    {
        msg = {
            {txt = STRINGS.BOARLORD_ROUND4_END[1], delay = 2}, 
            {txt = STRINGS.BOARLORD_ROUND4_END[2], delay = 4}, 
            {txt = STRINGS.BOARLORD_ROUND4_END[3], delay = 6}, 
            {txt = STRINGS.BOARLORD_ROUND4_END[4], delay = 8}, 
        }, 
        -- mobdelay = 10, 
        mobdelay = 10, 
        mobnum = 2,
        mob = {
            {"trails", }, 
            {}, 
            {"trails", }, 
        }
    },
    -- WaveData[12]
    -- wave 12: Team Snapper spawns after N seconds or when one Borilla has 50% lower hp. 
    {
        msg = {
            {txt = STRINGS.BOARLORD_ROUND5_FIGHT_BANTER1[1], delay = 0}, --25
            {txt = STRINGS.BOARLORD_ROUND5_FIGHT_BANTER1[2], delay = 2}, 
            {txt = STRINGS.BOARLORD_ROUND5_FIGHT_BANTER1[3], delay = 4}, 
        }, 
        -- mobdelay = 31, 
        mobdelay = 6, 
        mobnum = 3,
        mob = {
            {}, 
            {"snapper", "boaron", "boaron"}, 
            {}, 
        },
        moboffset = {
            {},
            {{theta=0,r=0},{theta=135,r=1.5},{theta=-90,r=1.5}},
            {}
        }
    },
    -- WaveData[13]
    -- wave 13: 
    {
        msg = {
            {txt = STRINGS.BOARLORD_ROUND5_FIGHT_BANTER2[1], delay = 0}, 
            {txt = STRINGS.BOARLORD_ROUND5_FIGHT_BANTER2[2], delay = 2}, 
            {txt = STRINGS.BOARLORD_ROUND5_FIGHT_BANTER2[3], delay = 4}, 
        }, 
        -- mobdelay = 41, 
        mobdelay = 6, 
        mobnum = 7,
        mob = {
            {"turtillus", "peghook", }, 
            {"snapper", "boaron", "boaron"}, 
            {"turtillus", "peghook", }, 
        },
        moboffset = {
            {{theta=90,r=1.5},{theta=-90,r=1.5}},
            {{theta=0,r=0},{theta=135,r=1.5},{theta=-90,r=1.5}},
            {{theta=90,r=1.5},{theta=-90,r=1.5}}
        }
    },
    -- WaveData[14]
    -- wave 14: 
    {
        msg = {
            {txt = STRINGS.BOARLORD_BOARRIOR_INTRO[1], delay = 0}, 
            {txt = STRINGS.BOARLORD_BOARRIOR_INTRO[2], delay = 2}, 
        }, 
        -- mobdelay = 34, 
        mobdelay = 4, 
        mobnum = 1,
        mob = {
            {}, 
            {"boarrior"}, 
            {}, 
        }
    },
    -- WaveData[15]
    -- wave 15: 
    {
        msg = {}, 
        mobdelay = 0, 
        mobnum = 10,
        mob = {
            {"boaron", "boaron", "boaron", }, 
            {"boaron", "boaron", "boaron", "boaron", }, 
            {"boaron", "boaron", "boaron", }, 
        },
        moboffset = {
            {{theta=90,r=1.5},{theta=210,r=1.5},{theta=-30,r=1.5}},
            {{theta=0,r=1.5},{theta=90,r=1.5},{theta=180,r=1.5},{theta=-90,r=1.5}},
            {{theta=90,r=1.5},{theta=210,r=1.5},{theta=-30,r=1.5}}
        }
    }
}


local function addLootToMobInWave(wave_idx, prefab, mob_idx)
    local loot = {prefab=prefab, idx=mob_idx}
    if not WaveData[wave_idx].loots then
        WaveData[wave_idx].loots = {}
    end
    -- print("addLootToRandomMobInWave()", "insert \"" .. prefab .. "\" into wave " .. wave_idx)
    table.insert(WaveData[wave_idx].loots, loot)
end


local function addLootToRandomMobInWave(wave_idx, prefab)
    mobnum = WaveData[wave_idx]["mobnum"]
    addLootToMobInWave(wave_idx, prefab, math.random(1, mobnum))
end


local function CountRemainEnemies()
    local count = 0
    for k,v in pairs(GLOBAL.Ents) do
        if v:HasTag("lavaarena_enemy") and not v:HasTag("dead") then
            count = count + 1
        end
    end
    return count
end


local function SetShinyEffect(inst)
    if not inst then return end
    inst.colouradd_time = 25*FRAMES
    inst.colouradd_timepassed = 0
    inst.colouradd_task = inst:DoPeriodicTask(FRAMES, function(inst) 
        local t = inst.colouradd_timepassed / inst.colouradd_time
        if t >= 1 then
            inst.colouradd_task:Cancel()
        end
        local c = GLOBAL.Lerp(1, 0.2, t)
        inst.AnimState:SetAddColour(c, c, c, 1)
        inst.colouradd_timepassed = inst.colouradd_timepassed + FRAMES
        end)

    local lb = SpawnPrefab("lavaarena_lootbeacon")
    lb.entity:SetParent(inst.entity)
    lb:Hide()
    inst.lootbeacon = lb
    lb:DoTaskInTime(0.8, function()
        -- lb.Transform:SetPosition(inst:GetPosition():Get())
        lb.AnimState:PlayAnimation("pre")
        lb.AnimState:PushAnimation("loop", true) 
        lb:Show()
        end)

    function onequipped(inst)
        inst.AnimState:SetAddColour(0, 0, 0, 0)
        local lb = inst.lootbeacon
        if lb then
            local t1 = lb.AnimState:GetCurrentAnimationLength() or 1
            local t2 = lb.AnimState:GetCurrentAnimationTime() or 0
            local delay = 2*t1 - math.fmod(t2, t1) -- do two more animations
            lb:DoTaskInTime(delay, function() lb.AnimState:PushAnimation("pst", false) end)
            lb:ListenForEvent("animover", lb.Remove)
        end
        inst:RemoveEventCallback("equipped", onequipped)
    end
    inst:ListenForEvent("equipped", onequipped)
end


local function doDropLoot(inst, islast)
    local wave_idx = inst.wave_idx
    local mob_idx = inst.mob_idx
    local loots = WaveData[wave_idx]["loots"]
    -- print("doDropLoot()", "wave: " .. wave_idx .. ", mob: " .. mob_idx)
    if loots then
        for i in pairs(loots) do
            local loot_item = loots[i].prefab
            local idx = loots[i].idx
            -- if the mob id matches or it is the last mob of current wave
            if loot_item and 
                (mob_idx == idx or (islast and idx==-1)) then
                local prefab = inst.components.lootdropper:SpawnLootPrefab(loot_item)

                -- shiny effect
                SetShinyEffect(prefab)
            end
        end
    end
end


local function DoSpawnWave(inst, wave_idx)
    if WaveData[wave_idx].spawned then 
        print("[Error] Multi-called DoSpawnWave()", wave_idx)
        return 
    end
    print("DoSpawnWave()", wave_idx)
    WaveData[wave_idx].spawned = true
    local spawners = inst.lavaarena_spawners
    -- local wave_idx = inst.lavaarena_wavenum
    if wave_idx >= MAX_WAVES then return end

    -- check if the three spawners are there
    if spawners and #spawners == 3 then
        local center_pos = (spawners[1]:GetPosition() + spawners[3]:GetPosition())/2
        local mob_idx = 1
        for i=1,#spawners do
            local spawner = spawners[i]
            local spawner_rot = spawner.Transform:GetRotation()
            local pt = spawner:GetPosition()
            local mobs2spawn = WaveData[wave_idx]["mob"][i]
            for ii,mob in pairs(mobs2spawn) do
                -- spawn fireworks fx
                local dcors = spawner.highlightchildren
                local tbl = {cw = {1,2,3,4,5,6}, ccw = {6,5,4,3,2,1}}  -- one of three firework patterns

                for i,v in ipairs(dcors) do
                    local p = SpawnPrefab("lavaarena_spawnerdecor_fx_small")
                    local vpos = v:GetPosition()
                    p.Transform:SetPosition(vpos:Get())
                    v:DoTaskInTime(1.5+0.07*tbl.cw[i], function()
                        SpawnPrefab("lavaarena_spawnerdecor_fx_1").Transform:SetPosition(vpos:Get())
                    end)
                    v:DoTaskInTime(1.5+0.6+0.07*tbl.ccw[i], function()
                        SpawnPrefab("lavaarena_spawnerdecor_fx_1").Transform:SetPosition(vpos:Get())
                    end)
                end

                TheSim:LoadPrefabs({"lavaarena_creature_teleport_small_fx"})
                TheSim:LoadPrefabs({"lavaarena_creature_teleport_medium_fx"})
                spawner:DoTaskInTime(0.9, function() 
                    local spawn = SpawnPrefab(mob)
                    local spawn_fx = (mob=="trails" or mob=="boarrior") 
                        and SpawnPrefab("lavaarena_creature_teleport_medium_fx")
                        or SpawnPrefab("lavaarena_creature_teleport_small_fx")

                    spawn.wave_idx = wave_idx
                    spawn.mob_idx = mob_idx
                    mob_idx = mob_idx + 1

                    -- spawn mobs with specifi offset pattern
                    local moboffset = WaveData[wave_idx]["moboffset"]
                    if moboffset then
                        local x,y,z = pt:Get()
                        local r = moboffset[i][ii]["r"]
                        local theta = moboffset[i][ii]["theta"] - spawner_rot
                        x = x + r * math.cos(theta*DEGREES)
                        z = z + r * math.sin(theta*DEGREES)
                        spawn.Physics:Teleport(x,y,z)
                        spawn_fx.Transform:SetPosition(x,y,z)
                    else
                        spawn.Physics:Teleport(pt:Get())
                        spawn_fx.Transform:SetPosition(pt:Get())
                    end

                    -- make mobs face center point
                    spawn:FacePoint(center_pos)

                    -- fade in spawn
                    -- adai: doesnt seem to be necessary
                    -- if not spawn.components.spawnfader then spawn:AddComponent("spawnfader") end
                    -- spawn.components.spawnfader:FadeIn()

                    -- suggest target      Adai: it doesn't work well here
                    local target = GLOBAL.GetClosestInstWithTag("player", spawn, 1001)
                    spawn.components.combat:SetTarget(target)

                    spawn:AddTag("lavaarena_enemy")

                    -- when mob is dead, count if there's any mob remain
                    spawn:ListenForEvent("death", function()
                        spawn:AddTag("dead")
                        local count = CountRemainEnemies()
                        inst.lavaarena_mobnum = inst.lavaarena_mobnum - 1
                        local mobnum = inst.lavaarena_mobnum
                        -- print("count", count, "mobnum", mobnum)
                        if count == 0 and mobnum <= 0 then
                            doDropLoot(spawn, true)
                            inst.lavaarena_mobnum = 0

                            local wavenum = inst.lavaarena_wavenum
                            if (wavenum>=MAX_WAVES) then
                                -- what if boarrior is instant killed? do we still have to spawn the last piggy waves?
                                inst:PushEvent("LavaArena_WaveComplete")
                                print("Push LavaArena_WaveComplete", "CountRemainEnemies()")
                                inst.lavaarena_world_state = "escape"
                            elseif (wavenum>=1 and wavenum<=8) or (wavenum==10) then
                                inst:PushEvent("LavaArena_BeginWave")
                                print("Push LavaArena_BeginWave", "CountRemainEnemies()")
                            else
                                print("Don't Push LavaArena_BeginWave", "Special wave", wavenum)
                            end
                        else
                            doDropLoot(spawn, false)
                        end
                        print("Read death", spawn)
                    end)
                end)
            end
        end
    else
        -- should not reach here
        print("Missing lavaarena_spawner")
    end
end


local function GetSpawnPortal()
    local spawners = {}
    for k,ent in pairs(GLOBAL.Ents) do
        if ent.prefab == "lavaarena_spawner" then
            table.insert(spawners, ent)
        end
    end

    -- sort the spawners with their GUID, 
    -- such that the right and left ones will be [1] or [3], and 
    -- the middle one will be [2]
    table.sort(spawners, function(a,b) return a.GUID < b.GUID end)
    if spawners[1] then spawners[1].Transform:SetRotation(90) end
    if spawners[2] then spawners[2].Transform:SetRotation(180) end
    if spawners[3] then spawners[3].Transform:SetRotation(-90) end

    return spawners
end


function DoPugnaAnnounce(inst, wave)
    inst.lavaarena_mobnum = inst.lavaarena_mobnum + WaveData[wave]["mobnum"]
    -- local wave = inst.lavaarena_wavenum
    local msgs = WaveData[wave]["msg"]
    local mobdelay = WaveData[wave]["mobdelay"]
    if msgs then
        if inst.pugna_announce_queue then
            for k in pairs(inst.pugna_announce_queue) do
                inst.pugna_announce_queue[k] = nil
            end
        else
            inst.pugna_announce_queue = {}
        end
        for i = 1, #msgs do
            local task = inst:DoTaskInTime(msgs[i]["delay"], function() 
                print('DoPugnaAnnounce(' .. wave .. ', ' .. i .. ')')
                local pugna = TheSim:FindFirstEntityWithTag("king")
                if pugna then pugna.components.talker:Say(msgs[i]["txt"]) end
            end)
            table.insert(inst.pugna_announce_queue, task)
        end
    end
end


local function isBorillaLowHealthOrDead()
    local found = false
    local isLowHealth = false
    for k,v in pairs(GLOBAL.Ents) do
        if v.prefab == "trails" then
            found = true
            isLowHealth = (v.components.health:GetPercent() < 51)
        end
    end
    return not found or isLowHealth
end


AddPrefabPostInit("world", function(inst)
    if GLOBAL.TheWorld.ismastersim then
        inst:DoTaskInTime(0, function() 
            inst.lavaarena_spawners = GetSpawnPortal()
            inst:ListenForEvent("LavaArena_BeginWave", function()
                print("Read LavaArena_BeginWave", inst.lavaarena_wavenum .. " => " .. (inst.lavaarena_wavenum+1))
                inst.lavaarena_wavenum = inst.lavaarena_wavenum + 1
                inst.lavaarena_world_state = "wave"
                inst.lavaarena_timer_active = true
                local wavenum = inst.lavaarena_wavenum
                DoPugnaAnnounce(inst, wavenum)
                inst:DoTaskInTime(WaveData[inst.lavaarena_wavenum]["mobdelay"], function() DoSpawnWave(inst, wavenum) end)

                if wavenum == 9 then
                    inst.wave9_stage = 0
                    inst.wave9_tick = 0
                    inst.wave9_task = inst:DoPeriodicTask(1, function(inst)
                        inst.wave9_tick = inst.wave9_tick + 1
                        -- print("wave9", "stage: " .. inst.wave9_stage, "tick: " .. inst.wave9_tick)
                        if inst.wave9_stage == 0 then
                            -- check if (1) all mobs are dead or (2) tick >= 20
                            if (inst.wave9_tick >= 20)
                                or (inst.wave9_tick > WaveData[9]["mobdelay"]+2 and CountRemainEnemies() == 0) then
                                print(inst.wave9_tick >= 20, (inst.wave9_tick > WaveData[9]["mobdelay"]+2 and CountRemainEnemies() == 0))
                                inst.wave9_stage = 1
                                inst.wave9_tick = 0
                                inst.lavaarena_wavenum = 10
                                DoPugnaAnnounce(inst, 10)
                                inst:DoTaskInTime(WaveData[10]["mobdelay"], function() DoSpawnWave(inst, 10) end)
                                -- print("wave9", "End inst.wave9_task")
                                inst.wave9_task:Cancel()
                            end
                        end
                    end)
                elseif wavenum == 11 then
                    inst.wave11_stage = 0
                    inst.wave11_tick = 0
                    inst.wave11_task = inst:DoPeriodicTask(1, function(inst)
                        inst.wave11_tick = inst.wave11_tick + 1
                        -- print("wave11", "stage: " .. inst.wave11_stage, "tick: " .. inst.wave11_tick)
                        if inst.wave11_stage == 0 then
                            -- check if (1) all mobs are dead or (2) tick >= 20 or (3) any Borilla has hp < 50% 
                            if (inst.wave11_tick >= 20)
                                or (inst.wave11_tick > WaveData[11]["mobdelay"]+2 and CountRemainEnemies() == 0)
                                or (inst.wave11_tick > WaveData[11]["mobdelay"]+2 and isBorillaLowHealthOrDead()) then
                                -- spawn first team crocodile
                                inst.wave11_stage = 1
                                inst.wave11_tick = 0
                                inst.lavaarena_wavenum = 12
                                DoPugnaAnnounce(inst, 12)
                                inst:DoTaskInTime(WaveData[12]["mobdelay"], function() DoSpawnWave(inst, 12) end)
                            end
                        elseif inst.wave11_stage == 1 then
                            -- check if (1) all mobs are dead or (2) tick >= 20
                            if (inst.wave11_tick >= 20)
                                or (inst.wave11_tick > WaveData[12]["mobdelay"]+2 and CountRemainEnemies() == 0) then
                                -- spawn second team crocodile and two pairs of tortank/scropian
                                inst.wave11_stage = 2
                                inst.wave11_tick = 0
                                inst.lavaarena_wavenum = 13
                                DoPugnaAnnounce(inst, 13)
                                inst:DoTaskInTime(WaveData[13]["mobdelay"], function() DoSpawnWave(inst, 13) end)
                            end
                        elseif inst.wave11_stage == 2 then
                            -- check if (1) all mobs are dead or (2) tick >= 20
                            if (inst.wave11_tick >= 20)
                                or (inst.wave11_tick > WaveData[13]["mobdelay"]+2 and CountRemainEnemies() == 0) then
                                -- spawn king boarrior
                                inst.wave11_stage = 3
                                inst.wave11_tick = 0
                                inst.lavaarena_wavenum = 14
                                DoPugnaAnnounce(inst, 14)
                                inst:DoTaskInTime(WaveData[14]["mobdelay"], function() DoSpawnWave(inst, 14) end)

                                inst.wave11_task:Cancel()
                                -- print("wave11", "End inst.wave11_task")
                            end
                        end
                    end)
                end
            end)

            inst:ListenForEvent("LavaArena_WaveComplete", function()
                print("Read LavaArena_WaveComplete")
                inst.lavaarena_timer_active = true
            end)

            inst:ListenForEvent("LavaArena_BeginBoarriorPiggySpawn", function()
                print("Read LavaArena_BeginBoarriorPiggySpawn")
                DoSpawnWave(inst, 15)
                inst.lavaarena_timer_active = true
            end)
        end)
    end 
end)


--[[
    function GatherAllMobs()
        for k,v in pairs(Ents) do
            if v:HasTag("lavaarena_enemy") then
                v.Physics:Teleport(ThePlayer:GetPosition():Get())
            end
        end
    end
--]]

function ForceNextWave()
    local world = TheWorld
    if world then
        world:PushEvent("LavaArena_BeginWave")
        print("Push LavaArena_BeginWave", "ForceNextWave()")
    end
end


--[[
-- easy item
"lavaarena_armormediumdamager",    --(1~2) 1   3 4     {7}               Jagged Wood Armor +10% Physical Damage
"lavaarena_lightdamagerhat",       --(1)     2   4   6                   Barbed Helm +10% Physical Damage
"lavaarena_rechargerhat",          --(1)     2     5                     Crystal Tiara +10% CDR
"lavaarena_feathercrownhat",       --(1)       3     6                   Feathered Wreath +20% Movespeed

-- hard item
"lavaarena_armorheavy",            --(1)           5 6                   Stone Splint Mail (85%) 
"lavaarena_armormediumrecharger",  --(1~2)         5   {7}               Silken Wood Armor +10% CDR
"lavaarena_tiaraflowerpetalshat",  --(1)                7     9          Woven Garland +20% Healing Dealt
"lavaarena_healingflowerhat",      --(1)                7     9          Flower Headband 25% Healing Received

-- must item
"healingstaff",                    --         [3]                        Healing Staff
"blowdart_lava2",                  --               [6]         <10>     Molten Dart
"spear_lance",                     --                           <10>     Spiral Spear
"lavaarena_strongdamagerhat",      --                  [7]               Nox Helm +15% Physical Damage
"fireballstaff",                   --                  [7]               Meteor Staff
"lavaarena_armorextraheavy",       --                  [7]      [10]     Steadfast Stone Armor (90%) -15% Movespeed, Resistance to Knockback
"lavaarena_eyecirclethat",         --                           [10]     Clairvoyant Crown +25% Magic Damage Dealt, +10% CDR, +10% Movespeed
"books_lavaarena",                 --                     [8]            Tome of Beckoning
"lavaarena_crowndamagerhat",       --                               {12} Resplendent Nox Helm +15% physical damage, +10% CDR, +10% Movespeed
"lavaarena_healinggarlandhat",     --                               {12} Blossomed Wreath +2 HP/Second (up to 80% HP), +10% CDR, +10% Movespeed

1. Jagged Wood Armor drops in wave (1,2,3,4)

2. Determine (Silken Wood Armor) drops in which wave (5,7)
if 5 => wave 6 drops (Stone Splint Mail)
        wave 7 drops (Silken, Jagged) Wood Armor
else => wave 5 drops (Stone Splint Mail)

3. Determine in which (2,3,4,5,6) wave will (Barbed Helm, Crystal Tiara, Feathered Wreath) drop
each wave only drops one of three

4. Determine wheather (Woven Garland, Flower Headband) drops in wave (7,9) or (9,7)

5. In wave 10, check wheather Wigfrid exists:
if true  => (Spiral Spear)
else     => (Molten Dart)

6. In wave 12, determine wheather it drops (Resplendent Nox Helm, Blossomed Wreath)

7. After last mob of certain wave is killed, it drops specific item:
(3, "Healing Staff")
(6, "Molten Dart")
(7, "Nox Helm")
(7, "Meteor Staff")
(7, "Steadfast Stone Armor")
(8, "Tome of Beckoning")
(10, "Steadfast Stone Armor")
(10, "Clairvoyant Crown")
--]]

local function setLootDrops()
    -- 1. 
    local wave_idx = math.random(1,4)
    addLootToRandomMobInWave(wave_idx, NameToPrefab["Jagged_Wood_Armor"])

    -- 2.
    local rand1 = 5 + 2 * math.random(0,1)
    addLootToRandomMobInWave(rand1, NameToPrefab["Silken_Wood_Armor"])
    if rand1 == 5 then
        addLootToRandomMobInWave(6, NameToPrefab["Stone_Splint_Mail"])
        if math.random(0,1) == 0 then
            addLootToRandomMobInWave(7, NameToPrefab["Silken_Wood_Armor"])
        else
            addLootToRandomMobInWave(7, NameToPrefab["Jagged_Wood_Armor"])
        end
    else
        addLootToRandomMobInWave(5, NameToPrefab["Stone_Splint_Mail"])
    end

    -- 3.
    local tbl = {2,3,4,5,6}
    local size = #tbl
    for i=1,size do
        local r = math.random(size)
        tbl[i], tbl[r] = tbl[r], tbl[i]
    end
    addLootToRandomMobInWave(tbl[1], NameToPrefab["Barbed_Helm"])
    addLootToRandomMobInWave(tbl[2], NameToPrefab["Crystal_Tiara"])
    addLootToRandomMobInWave(tbl[3], NameToPrefab["Feathered_Wreath"])

    -- 4. 
    local tbl = {7,9}
    if math.random(0,1) == 0 then tbl = {9,7} end
    addLootToRandomMobInWave(tbl[1], NameToPrefab["Woven_Garland"])
    addLootToRandomMobInWave(tbl[2], NameToPrefab["Flower_Headband"])

    -- 5.
    local foundWigfrid = false
    for k,v in pairs(GLOBAL.AllPlayers) do
        if v.prefab == "wathgrithr" then
            foundWigfrid = true
            break
        end
    end
    if foundWigfrid then
        addLootToRandomMobInWave(10, NameToPrefab["Spiral_Spear"])
    else
        addLootToRandomMobInWave(10, NameToPrefab["Molten_Dart"])
    end

    -- 6.
    if math.random(0,1) == 0 then
        addLootToRandomMobInWave(12, NameToPrefab["Resplendent_Nox_Helm"])
    else
        addLootToRandomMobInWave(12, NameToPrefab["Blossomed_Wreath"])
    end

    -- 7.
    addLootToMobInWave(3, NameToPrefab["Healing_Staff"], -1)
    addLootToMobInWave(6, NameToPrefab["Molten_Dart"], -1)
    addLootToMobInWave(7, NameToPrefab["Nox_Helm"], -1)
    addLootToMobInWave(7, NameToPrefab["Meteor_Staff"], -1)
    addLootToMobInWave(7, NameToPrefab["Steadfast_Stone_Armor"], -1)
    addLootToMobInWave(8, NameToPrefab["Tome_of_Beckoning"], -1)
    addLootToMobInWave(10, NameToPrefab["Steadfast_Stone_Armor"], -1)
    addLootToMobInWave(10, NameToPrefab["Clairvoyant_Crown"], -1)
end


-- WaveData post init
for k,v in pairs(WaveData) do
    WaveData[k].spawned = false
end
setLootDrops()

for i in pairs(WaveData) do
    local loots = WaveData[i].loots
    if loots then
        for k,v in pairs(loots) do
            print(i, v.idx, v.prefab)
        end
    else
        print("no loots in wave " .. i)
    end
end