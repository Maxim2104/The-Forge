local function MakeBuff(name, build, scale, offset)
    local assets =
    {
        Asset("ANIM", "anim/"..build..".zip"),
    }

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        inst.AnimState:SetBank(build)
        inst.AnimState:SetBuild(build)
    inst.AnimState:PlayAnimation("in")
    inst.AnimState:PushAnimation("idle") 
    inst.AnimState:PushAnimation("out") 
	inst.AnimState:SetMultColour(.5, .5, .5, .5)

        inst.Transform:SetScale(scale, scale, scale)

        inst:AddTag("DECOR") --"FX" will catch mouseover
        inst:AddTag("NOCLICK")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end
		
    inst:DoTaskInTime(1.415, inst.Remove)

        event_server_data("lavaarena", "prefabs/wathgrithr_bloodlustbuff").master_postinit(inst, offset)

        return inst
    end

    return Prefab(name, fn, assets)
end

return MakeBuff("wathgrithr_bloodlustbuff_self", "lavaarena_attack_buff_effect", 1.4, 0),
    MakeBuff("wathgrithr_bloodlustbuff_other", "lavaarena_attack_buff_effect2", 1, 1)
