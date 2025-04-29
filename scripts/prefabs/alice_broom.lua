<<<<<<< HEAD
local assets =
{
    Asset("ANIM", "anim/alice_broom.zip"),
    Asset("ATLAS", "images/inventoryimages/alice_broom.xml"),
}

local UpvalueHacker = require("alice_utils/upvaluehacker")

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "alice_broom", "symbol0")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    inst._had_fastbuilder = owner:HasTag("fastbuilder")
    inst._had_fastpicker = owner:HasTag("fastpicker")

    if not inst._had_fastbuilder then
        owner:AddTag("fastbuilder")
    end
    if not inst._had_fastpicker then
        owner:AddTag("fastpicker")
    end
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")

    --只有爱丽丝能装备，所以不检测原来有没有这个tag了
    --还是加一下，万一玩家开了其他快速工作mod
    if not inst._had_fastbuilder then
        owner:RemoveTag("fastbuilder") 
    end
    if not inst._had_fastpicker then
        owner:RemoveTag("fastpicker")
    end
end

local function OnSave(inst, data)
	data._had_fastbuilder = inst._had_fastbuilder
	data._had_fastpicker = inst._had_fastpicker
end

local function OnLoad(inst, data)
    if data then
        inst._had_fastbuilder = data._had_fastbuilder
        inst._had_fastpicker = data._had_fastpicker
    end
end

local spellCB = UpvalueHacker.GetUpvalue(Prefabs["reskin_tool"].fn, "spellCB")
local can_cast_fn = UpvalueHacker.GetUpvalue(Prefabs["reskin_tool"].fn, "can_cast_fn")

local function tool_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    
    inst.AnimState:SetBank("alice_broom")
    inst.AnimState:SetBuild("alice_broom")
    inst.AnimState:PlayAnimation("dimian")

    inst:AddTag("nopunch")

    inst.spelltype = "RESKIN"

    inst:AddTag("veryquickcast")

    inst.scrapbook_specialinfo = "RESKINTOOL"

    MakeInventoryFloatable(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/alice_broom.xml"

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.walkspeedmult = TUNING.ALICE_BROOM_SPEED_MULT
    inst.components.equippable.restrictedtag = "alice"

    inst:AddComponent("spellcaster")
    inst.components.spellcaster.canuseontargets = true
    inst.components.spellcaster.canuseondead = true
    inst.components.spellcaster.veryquickcast = true
    inst.components.spellcaster.canusefrominventory  = true
    if spellCB then
        inst.components.spellcaster:SetSpellFn(spellCB)
    end
    if can_cast_fn then
        inst.components.spellcaster:SetCanCastFn(can_cast_fn)
    end

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.MED_FUEL

    MakeHauntableLaunchAndIgnite(inst)

    inst._cached_reskinname = {}

	inst.OnSave = OnSave
	inst.OnLoad = OnLoad

    return inst
end

=======
local assets =
{
    Asset("ANIM", "anim/alice_broom.zip"),
    Asset("ATLAS", "images/inventoryimages/alice_broom.xml"),
}

local UpvalueHacker = require("alice_utils/upvaluehacker")

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "alice_broom", "symbol0")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    inst._had_fastbuilder = owner:HasTag("fastbuilder")
    inst._had_fastpicker = owner:HasTag("fastpicker")

    if not inst._had_fastbuilder then
        owner:AddTag("fastbuilder")
    end
    if not inst._had_fastpicker then
        owner:AddTag("fastpicker")
    end
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")

    --只有爱丽丝能装备，所以不检测原来有没有这个tag了
    --还是加一下，万一玩家开了其他快速工作mod
    if not inst._had_fastbuilder then
        owner:RemoveTag("fastbuilder") 
    end
    if not inst._had_fastpicker then
        owner:RemoveTag("fastpicker")
    end
end

local function OnSave(inst, data)
	data._had_fastbuilder = inst._had_fastbuilder
	data._had_fastpicker = inst._had_fastpicker
end

local function OnLoad(inst, data)
    if data then
        inst._had_fastbuilder = data._had_fastbuilder
        inst._had_fastpicker = data._had_fastpicker
    end
end

local spellCB = UpvalueHacker.GetUpvalue(Prefabs["reskin_tool"].fn, "spellCB")
local can_cast_fn = UpvalueHacker.GetUpvalue(Prefabs["reskin_tool"].fn, "can_cast_fn")

local function tool_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    
    inst.AnimState:SetBank("alice_broom")
    inst.AnimState:SetBuild("alice_broom")
    inst.AnimState:PlayAnimation("dimian")

    inst:AddTag("nopunch")

    inst.spelltype = "RESKIN"

    inst:AddTag("veryquickcast")

    inst.scrapbook_specialinfo = "RESKINTOOL"

    MakeInventoryFloatable(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/alice_broom.xml"

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.walkspeedmult = TUNING.ALICE_BROOM_SPEED_MULT
    inst.components.equippable.restrictedtag = "alice"

    inst:AddComponent("spellcaster")
    inst.components.spellcaster.canuseontargets = true
    inst.components.spellcaster.canuseondead = true
    inst.components.spellcaster.veryquickcast = true
    inst.components.spellcaster.canusefrominventory  = true
    if spellCB then
        inst.components.spellcaster:SetSpellFn(spellCB)
    end
    if can_cast_fn then
        inst.components.spellcaster:SetCanCastFn(can_cast_fn)
    end

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.MED_FUEL

    MakeHauntableLaunchAndIgnite(inst)

    inst._cached_reskinname = {}

	inst.OnSave = OnSave
	inst.OnLoad = OnLoad

    return inst
end

>>>>>>> 23121469d84d981b602c8a05fcc5a165255f6831
return Prefab("alice_broom", tool_fn, assets, prefabs)