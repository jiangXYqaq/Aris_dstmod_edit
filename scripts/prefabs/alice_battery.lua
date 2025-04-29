local assets =
{
    Asset("ANIM", "anim/alice_battery.zip"),
    Asset("ATLAS", "images/inventoryimages/alice_battery.xml"),
}

local function tool_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst:AddTag("alice_battery")

    inst.AnimState:SetBank("alice_battery")
    inst.AnimState:SetBuild("alice_battery")
    inst.AnimState:PlayAnimation("alice_battery")

    inst.entity:SetPristine()

    inst.targetslot = EQUIPSLOTS.HANDS

    if not TheWorld.ismastersim then
        return inst
    end
    
    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(1000)--增加耐久
    inst.components.finiteuses:SetUses(1000)

    inst:AddComponent("inspectable")
    
    inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/alice_battery.xml"

    MakeHauntableLaunch(inst)
    
    return inst
end

return Prefab("alice_battery", tool_fn, assets, prefabs)