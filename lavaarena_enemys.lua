local function LastEnemyDrop(inst)
    if inst.lastenemydrop and inst.lastenemydrop == "3round" then
	    inst.components.lootdropper:SpawnLootPrefab("healingstaff")
	    inst.components.lootdropper:SpawnLootPrefab("lavaarena_lightdamagerhat")
	end
    if inst.lastenemydrop and inst.lastenemydrop == "heal" then

	end
    if inst.lastenemydrop and inst.lastenemydrop == "leverprint" then
	    inst.components.lootdropper:SpawnLootPrefab("lasthope_coint")
	end
    if inst.lastenemydrop and inst.lastenemydrop == "flowerprint" then
	    inst.components.lootdropper:SpawnLootPrefab("lasthope_coint")
	end
    if inst.lastenemydrop and inst.lastenemydrop == "robojunk" then
	    inst.components.lootdropper:SpawnLootPrefab("lasthope_coint")
	end
end
--[[
local function LastEnemyDrop(inst)
    if inst.lastenemydrop and inst.lastenemydrop == "healingstaff" then
	    inst.components.lootdropper:SpawnLootPrefab("healingstaff")
	end
    if inst.lastenemydrop and inst.lastenemydrop == "heal" then

	end
    if inst.lastenemydrop and inst.lastenemydrop == "leverprint" then
	    inst.components.lootdropper:SpawnLootPrefab("lasthope_coint")
	end
    if inst.lastenemydrop and inst.lastenemydrop == "flowerprint" then
	    inst.components.lootdropper:SpawnLootPrefab("lasthope_coint")
	end
    if inst.lastenemydrop and inst.lastenemydrop == "robojunk" then
	    inst.components.lootdropper:SpawnLootPrefab("lasthope_coint")
	end
end
--]]
local function OnDeath(inst, data)
	LastEnemyDrop(inst)
end

local function InArenaZoneCheck(inst)
    local spawnplace = GLOBAL.TheWorld.spawnpos
	if spawnplace and inst:HasTag("lasthope_enemy") then
	local position = GLOBAL.Vector3(inst.Transform:GetWorldPosition())
	if ((position.x-spawnplace.x)^2+(position.z-spawnplace.z)^2) > 55^2 then
		inst.Transform:SetPosition(spawnplace.x,spawnplace.y,spawnplace.z)
	    end
    end
end
	