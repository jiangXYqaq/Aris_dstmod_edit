local assets =
{
    Asset("ANIM", "anim/alice_buff.zip"),
}

local prefabs = {}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst.AnimState:SetBank("alice_buff")
    inst.AnimState:SetBuild("alice_buff")

    inst.entity:SetPristine()

    inst.Transform:SetScale(2, 2, 2)

    inst:AddTag("NOCLICK")
    inst:AddTag("FX")

    return inst
end

return Prefab("alice_buff", fn, assets, prefabs)
