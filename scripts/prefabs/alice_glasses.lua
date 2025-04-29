local assets=
{ 
	Asset("ANIM", "anim/alice_glasses.zip"), 
    Asset("ATLAS", "images/inventoryimages/alice_glasses.xml"),
}

local prefabs = {}

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_hat")
    owner.AnimState:Hide("HAT")
    owner.AnimState:Hide("HAIR_HAT")
    owner.AnimState:Show("HAIR_NOHAT")
    owner.AnimState:Show("HAIR")

    if owner:HasTag("player") then
        owner.AnimState:Show("HEAD")
        owner.AnimState:Hide("HEAD_HAT")
    end
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_hat", "alice_glasses", "swap_hat") 

    owner.AnimState:Show("HAT")
    owner.AnimState:Hide("HAIR_HAT")
    owner.AnimState:Show("HAIR_NOHAT")
    owner.AnimState:Show("HAIR")

    if owner:HasTag("player") then
        owner.AnimState:Show("HEAD")
        owner.AnimState:Hide("HEAD_HAT")  
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("alice_glasses")
    inst.AnimState:SetBuild("alice_glasses")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("alice_battlecoat")
    inst:AddTag("alice_critical")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("alice_critical")
    inst.components.alice_critical:Setchance(TUNING.ALICE_GLASSES_CHANCE)
    inst.components.alice_critical:Setvalue(TUNING.ALICE_GLASSES_VALUE)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/alice_glasses.xml"

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    MakeHauntableLaunch(inst)

    return inst
end

return  Prefab("alice_glasses", fn, assets, prefabs)