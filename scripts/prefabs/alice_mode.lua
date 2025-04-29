local assets =
{
    Asset("ANIM", "anim/alice_mode.zip"),
    Asset("ATLAS", "images/inventoryimages/alice_mode.xml"),
}

local function commonfn(mode)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst:AddTag("swordmode")

    inst.AnimState:SetBank("alice_mode")
    inst.AnimState:SetBuild("alice_mode")
    inst.AnimState:PlayAnimation("alice_mode" .. mode)

    inst.entity:SetPristine()

    inst.targetslot = EQUIPSLOTS.HANDS

    if not TheWorld.ismastersim then
        return inst
    end
    
    inst.mode = mode
    
    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/alice_mode.xml"
	inst.components.inventoryitem.imagename = "alice_mode" .. mode

    MakeHauntableLaunch(inst)

    return inst
end

local prefabs = {}
for i = 1, 4 do
	local function fn()
		local inst = commonfn(i)

		return inst
	end
	table.insert(prefabs, Prefab("alice_mode"..i, fn, assets))
end

return unpack(prefabs)