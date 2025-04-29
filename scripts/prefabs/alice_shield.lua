--Aris 服装强化插板的设置。基本上都改为更高的耐久和防御
local assets =
{
    Asset("ANIM", "anim/wooden_shield.zip"),
    Asset("ANIM", "anim/metal_shield.zip"),
    Asset("ANIM", "anim/dread_shield.zip"),
    Asset("ANIM", "anim/composite_shield.zip"),
    Asset("ANIM", "anim/thorn_shield.zip"),
    Asset("ANIM", "anim/shadow_shield.zip"),

    Asset("ATLAS", "images/inventoryimages/alice_shield.xml"),
}

local function OnFinished(inst)
    -- todo brokensound
    inst:Remove()
end

local function fn(anim, abs_percent, condition, planar, bramble, shield)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst:AddTag("alice_shield")
    
    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank(anim)
    inst.AnimState:SetBuild(anim)
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    inst.targetslot = EQUIPSLOTS.BODY
    
    if not TheWorld.ismastersim then
        return inst
    end
    
    inst.abs_percent = abs_percent
    inst.planar = planar
    inst.bramble = bramble
    inst.shield = shield
    
    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(condition)
    inst.components.finiteuses:SetUses(condition)
    inst.components.finiteuses:SetOnFinished(OnFinished)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/alice_shield.xml"
	inst.components.inventoryitem.imagename = anim

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM
    
    MakeHauntableLaunch(inst)

    return inst
end

local shields = {
    {
        name = "wooden_shield", 
        abs_percent = 0.85, 
        condition = 300
    },
    {
        name = "metal_shield", 
        abs_percent = 0.85, 
        condition = 1050
    },
    {
        name = "dread_shield", 
        abs_percent = 0.9, 
        condition = 3360, 
        planar = 10
    },
    {
        name = "composite_shield", 
        abs_percent = 0.8, 
        condition = 1660, 
        planar = 25
    },
    {
        name = "thorn_shield", 
        abs_percent = 0.85, 
        condition = 1050, 
        planar = 15, 
        bramble = 10
    },
    {
        name = "shadow_shield", 
        abs_percent = 0, 
        condition = 40, 
        shield = true
    },
}

local prefabs = {}
for _, shield in ipairs(shields) do
    table.insert(prefabs, Prefab(shield.name, function()
        return fn(shield.name, shield.abs_percent, shield.condition, shield.planar, shield.bramble, shield.shield)
    end, assets))
end

return unpack(prefabs)