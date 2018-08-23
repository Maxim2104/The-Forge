local function fn(inst, prefab)
	if prefab == "willow" and TheWorld.ismastersim then
		inst.components.health.fire_damage_scale = 0
		local function OnAttack(inst, data)
			if math.random() > 0.8 then
				local fire = SpawnPrefab("houndfire")
				fire.Transform:SetPosition(inst:GetPosition():Get())
				fire.Physics:SetVel(math.random(-7,7), 0, math.random(-7,7))
			end
		end
		inst:ListenForEvent("onattackother", OnAttack)
		inst:ListenForEvent("onmissother", OnAttack)
	end
	----------------------------------------------------------------------------------------
	if prefab == "wendy" and TheWorld.ismastersim then
		inst.abi = nil
		local function KillAbi(abi)
			abi.components.health:Kill()
		end
		local function SpawnAbi(inst, target)
			local abi = SpawnPrefab("abigail")
			inst.abi = abi
			abi:AddTag("notarget")
			inst.components.leader:AddFollower(abi)
			abi.Transform:SetPosition(inst:GetPosition():Get())
			abi.components.combat:SetTarget(target)
			abi.components.combat.externaldamagetakenmultipliers:SetModifier("abi", 0)
			abi.components.combat:SetPlayerStunlock(PLAYERSTUNLOCK.NEVER)
			abi.components.teamer:SetTeam(inst.components.teamer.team)
			abi:ListenForEvent("teamchange", function(abi, data) abi.components.teamer:SetTeam(data.team) end, inst)
			abi.killtask = abi:DoTaskInTime(3, KillAbi)
			abi:ListenForEvent("onremove", function()
				inst.abi = nil
			end)
		end
		local function RefreshAbi(inst, target)
			if inst.abi ~= nil and not inst.abi.components.health:IsDead() then
				if inst.abi.killtask ~= nil then
					inst.abi.killtask:Cancel()
					inst.abi.killtask = nil
				end
				inst.abi.killtask = inst.abi:DoTaskInTime(3, KillAbi)
				inst.abi.components.combat:SetTarget(target)
			end
		end
		local function OnAttackOrMiss(inst, data)
			if inst.abi == nil and data.target ~= nil then
				SpawnAbi(inst, data.target)
			elseif data.target ~= nil then
				RefreshAbi(inst, data.target)
			end
		end
		local function OnAttacked(inst, data)
			if inst.abi == nil and data.attacker ~= nil then
				SpawnAbi(inst, data.attacker)
			elseif data.attacker ~= nil then
				RefreshAbi(inst, data.attacker)
			end
		end
		inst:ListenForEvent("onattackother", OnAttackOrMiss)
		inst:ListenForEvent("onmissother", OnAttackOrMiss)
		inst:ListenForEvent("attacked", OnAttacked)
	end
	---------------------------------------------------------------------------
	if prefab == "wx78" then
		inst.components.inventory.IsInsulated = function() return true end -- immune to stun
		local hitcountdown = 4
		local function OnAttack(inst, data)
			hitcountdown = hitcountdown - 1
			if hitcountdown == 0 then
				if data.target ~= nil and data.target:HasTag("player") then
					data.target.sg:GoToState("electrocute")
				end
				hitcountdown = 4
			end
		end
		inst:ListenForEvent("onattackother", OnAttack)
	end
	---------------------------------------------------------------------------- 
	
end
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

AddPrefabPostInit("webber",function(inst)
inst._bb = {}
inst:DoTaskInTime(0, function()
for i=1, 3 do
local zhizhu = GLOBAL.SpawnPrefab("spider")
if zhizhu then
zhizhu.persists = false
zhizhu._zhuren = inst
MakeGhostPhysics(zhizhu, 1, 0.3)
table.insert(inst._bb, zhizhu)
local x,y,z = inst.Transform:GetWorldPosition()
zhizhu.Transform:SetPosition(x,y,z)
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

local function KillWenDy(inst, data)
if inst._abigail == nil and data.victim then
local abigail = GLOBAL.SpawnPrefab("abigail")
local x,y,z = data.victim.Transform:GetWorldPosition()
abigail.Transform:SetPosition(x,y,z)
inst._abigail = abigail
abigail:LinkToPlayer(inst)
end
end

AddPrefabPostInit("wendy",function(inst)
inst._abigail = nil
inst:ListenForEvent("killed", KillWenDy)
end)

return fn
