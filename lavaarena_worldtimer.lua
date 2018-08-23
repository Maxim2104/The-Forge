modimport "lavaarena_waver.lua"

local function TimerDone(inst)
    if inst.lavaarena_world_state == "intermission" then
        if GLOBAL.TheNet:GetServerGameMode() == "lavaarena" then
            inst:PushEvent("LavaArena_BeginWave")
            print("Push LavaArena_BeginWave")
        end
    elseif inst.lavaarena_world_state == "death" or inst.lavaarena_world_state == "escape" then
        GLOBAL.TheNet:SendWorldResetRequestToServer()
    end
end

local function TickTack(inst)
    if inst.lavaarena_timer_active then
        if inst.lavaarena_seconds <= 0 then
            inst.lavaarena_timer_active = false
            TimerDone(inst)
        end
    end
end

local function EverySecond(inst)
    if GLOBAL.AllPlayers and GLOBAL.AllPlayers[1] ~= nil then
        if inst.lavaarena_timer_active then
            if inst.lavaarena_seconds > 0 then
                inst.lavaarena_seconds = inst.lavaarena_seconds - 1
            end
        end
    end
end

local function Begin(inst)
    inst.lavaarena_world_state = "intermission"
    inst.lavaarena_seconds = 3        -- time before first wave starts
    inst.lavaarena_timer_active = true
end

AddPrefabPostInit("world", function(inst)
    if GLOBAL.TheWorld.ismastersim then
        inst.lavaarena_wavenum = 0
        inst.lavaarena_world_state = "waiting"
        inst.lavaarena_timer_active = false     
        inst.lavaarena_seconds = 0
        inst.lavaarena_mobnum = 0
        inst:DoPeriodicTask(0, TickTack)
        inst:DoPeriodicTask(1, EverySecond)
        inst:ListenForEvent("lavaarena_begin", Begin)
    end 
end)