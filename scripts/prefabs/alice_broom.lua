local assets =
{
    Asset("ANIM", "anim/alice_broom.zip"),
    Asset("ATLAS", "images/inventoryimages/alice_broom.xml"),
}
--alice_broom 手部装备，基于原版的清洁扫把，可以给物品换皮肤。现在需要增加：1拾取物品 2收获物品 3地图传送
--1拾取物品，要求玩家手持时，点击地面上的物品即拾取，同时拾取附近一定范围内的相同物品。如果与更换皮肤冲突，则更换皮肤不拾取。点击空白地面不执行拾取操作。
--仅拾取普通的物品，不拾取可搬运的雕像重物，以及世界唯一物品如眼骨。
--UI提升此时的操作为拾取，如果是可以更换皮肤的物品需要显示为原来的打扫，即更换皮肤。
--2收获物品，收获大部分的可采集物品和作物。点击空白地面执行，收获点击位置附近一定范围内的可收获物品。包括但不限于：草，树枝，浆果丛，石果，香蕉，农田的成熟作物。
--如果附近有蜂箱建筑，则不拾取花。永远不拾取恶魔花。
--要求显示施法有效范围，同时UI提示此时的操作为收获。
--3手持时，玩家打开地图，点击已探索的地形即传送。同时额外增加手持时，玩家可以穿过建筑和障碍物，如墙体等。地图UI需要提示操作为地图传送。
--请一项项功能进行添加，测试通过后再尝试下一个。
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

-- 在alice_broom.lua中找到原版can_cast_fn的获取位置，替换为：
local original_can_cast_fn = can_cast_fn
local function safe_can_cast(doer, target, pos)
    return target ~= nil 
        and target:IsValid() 
        and original_can_cast_fn(doer, target, pos)
end

local function ReskinTarget(inst, doer, target)
    if safe_can_cast(doer, target, nil) then
        print("[Debug] ReskinTarget called for:", target.prefab)
        spellCB(inst, target, nil, doer)
        return true
    end
    print("[Debug] ReskinTarget failed for:", target.prefab)
    return false
end

-- 确保拾取半径已定义
if TUNING.ALICE_BROOM_PICKUP_RADIUS == nil then
    TUNING.ALICE_BROOM_PICKUP_RADIUS = 5 -- 默认拾取半径为 5
    print("[Debug] TUNING.ALICE_BROOM_PICKUP_RADIUS was nil. Set to default value: 5")
end

-- 拾取功能（重构后）
local function PickUpItems(inst, doer, target)
    if target == nil or not target:IsValid() then
        print("[Debug] PickUpItems: Invalid target")
        return false
    end

    local x, y, z = target.Transform:GetWorldPosition()
    if x == nil or y == nil or z == nil then
        print("[Debug] PickUpItems: Invalid target position")
        return false
    end

    -- 确保搜索半径有效
    local radius = TUNING.ALICE_BROOM_PICKUP_RADIUS
    if type(radius) ~= "number" or radius <= 0 then
        print("[Debug] PickUpItems: Invalid pickup radius. Using default value: 5")
        radius = 5
    end

    -- 排除不可拾取物品
    local exclude_tags = {"heavy", "irreplaceable", "nonpackable", "nosteal", "FX"}
    if target:HasOneOfTags(exclude_tags) or target.components.inventoryitem.nobounce then
        print("[Debug] PickUpItems: Target excluded by tags:", target.prefab)
        return false
    end

    -- 检查玩家是否有 inventory 组件
    if not doer.components.inventory then
        print("[Debug] PickUpItems: Doer has no inventory component. Cannot pick up items.")
        return false
    end

    -- 查找目标及其周围同类物品
    local target_prefab = target.prefab
    local items = TheSim:FindEntities(x, y, z, radius, nil, exclude_tags)

    -- 计算总堆叠数量
    local total_stack_size = 0
    local max_stack_size = 400
    for _, item in ipairs(items) do
        if item.prefab == target_prefab 
            and item.components.inventoryitem 
            and item.components.inventoryitem.canbepickedup 
            and not item:IsInLimbo() 
        then
            local stack_size = 1
            if item.components.stackable then
                stack_size = item.components.stackable:StackSize()
            end

            -- 检查是否会超过上限
            if total_stack_size + stack_size > max_stack_size then
                print("[Debug] PickUpItems: Reached stack size limit. Stopping collection.")
                break
            end

            total_stack_size = total_stack_size + stack_size
            print("[Debug] PickUpItems: Found item:", item.prefab, "with stack size:", stack_size)
            item:Remove() -- 移除地面上的物品
        end
    end

    if total_stack_size > 0 then
        print("[Debug] PickUpItems: Total stack size to pick up:", total_stack_size)
        -- 使用 for 循环逐个生成物品并添加到玩家物品栏
        for i = 1, total_stack_size do
            local new_item = SpawnPrefab(target_prefab)
            if doer.components.inventory:GiveItem(new_item) then
                print("[Debug] PickUpItems: Successfully added item to inventory:", target_prefab, "Item:", i)
            else
                print("[Debug] PickUpItems: Failed to add item to inventory. Dropping item at player's position.")
                new_item.Transform:SetPosition(doer.Transform:GetWorldPosition())
            end
        end
    else
        print("[Debug] PickUpItems: No valid items found to pick up.")
    end

    return true
end

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

    --inst.components.spellcaster:SetSpellFn(function(inst, doer, target, pos)
    inst.components.spellcaster:SetSpellFn(function(inst, target, pos, doer)

        -- 确保参数正确传递
        if target == nil then
            print("[Debug] SpellFn: Target is nil. Doer:", doer.prefab, "Position:", pos and (pos.x .. ", " .. pos.y .. ", " .. pos.z) or "nil")
            return false
        end
    
        if not target:IsValid() then
            print("[Debug] SpellFn: Target is not valid:", target.prefab or "unknown")
            return false
        end
    
        print("[Debug] SpellFn: Valid target:", target.prefab)
    
        -- 如果 pos 为 nil，尝试从目标获取位置
        if pos == nil then
            local x, y, z = target.Transform:GetWorldPosition()
            if x == nil or y == nil or z == nil then
                print("[Debug] SpellFn: Unable to retrieve target's position.")
                return false
            end
            pos = { x = x, y = y, z = z }
            print("[Debug] SpellFn: Retrieved target position:", pos.x, pos.y, pos.z)
        end
    
        -- 检查是否可以换肤
        if safe_can_cast(doer, target, pos) then
            print("[Debug] SpellFn: Attempting reskin")
            spellCB(inst, target, pos, doer)
            return true
        else
            print("[Debug] SpellFn: Attempting pickup")
            -- 检查是否可以拾取
            if target.components.inventoryitem and not target:IsInLimbo() then
                return PickUpItems(inst, doer, target)
            end
        end
    
        print("[Debug] SpellFn: No valid action for target:", target.prefab)
        return false
    end)
    
    inst.components.spellcaster:SetCanCastFn(function(doer, target, pos)
        -- 确保参数正确传递
        if target == nil then
            print("[Debug] CanCastFn: Target is nil")
            return false
        end
    
        if not target:IsValid() then
            print("[Debug] CanCastFn: Target is not valid:", target.prefab or "unknown")
            return false
        end
    
        -- 检查是否可以换肤或拾取
        local can_reskin = safe_can_cast(doer, target, pos)
        local can_pickup = target.components.inventoryitem and not target:HasTag("heavy")
    
        print("[Debug] CanCastFn: can_reskin =", can_reskin, ", can_pickup =", can_pickup, ", target =", target.prefab or "unknown")
        return can_reskin or can_pickup
    end)

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.MED_FUEL

    MakeHauntableLaunchAndIgnite(inst)

    inst._cached_reskinname = {}

	inst.OnSave = OnSave
	inst.OnLoad = OnLoad

    return inst
end

return Prefab("alice_broom", tool_fn, assets, prefabs)