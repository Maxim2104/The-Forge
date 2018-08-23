modimport("portal/c_fn")
 

AddStategraphState(
    "wilson",
    State{
        name = "portal_fire",
        tags = { "doing", "busy", "porting" },

        onenter = function(inst)
            if inst.components.playercontroller then
                inst.components.playercontroller:Enable(false)
            end
            inst:Hide()
            local playerfx = SpawnPrefab("lavaarena_portal_player_fx")
            playerfx.Transform:SetPosition(inst.Transform:GetWorldPosition())

            inst:DoTaskInTime(.62, function()
                inst:Show()
                if inst.components.playercontroller then    
                    inst.components.playercontroller:Enable(true)
                end
                inst.sg:GoToState("idle")
            end)
        end,

        events =
        {
            EventHandler("animover", function(inst)
            
            end),
        },
    }
)


        
AddPlayerPostInit(function(player)
  --player:DoTaskInTime(.7, function() player.sg:GoToState("portal_fire") end)
end)
