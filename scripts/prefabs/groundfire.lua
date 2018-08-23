local assets =
{
	Asset( "ANIM", "anim/lavaarena_boarrior_fx.zip" ),
}

local function fn(Sim)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	inst.entity:AddNetwork()
    local anim = inst.entity:AddAnimState()
    
    anim:SetBuild("lavaarena_boarrior_fx")
   	anim:SetBank("lavaarena_boarrior_fx")
   	--anim:SetOrientation( ANIM_ORIENTATION.OnGround )
	anim:PlayAnimation( "ground_hit_1", false ) 

	inst:AddTag( "FX" )
	inst:AddTag( "NOCLICK" )

	inst.entity:SetPristine()
	
	if not TheWorld.ismastersim then
        return inst
    end

	inst:RemoveTag("_named")

	inst:ListenForEvent( "animover", function(inst) inst:Remove() end )

    return inst
end

return Prefab( "common/fx/groundfire", fn, assets ) 
 
