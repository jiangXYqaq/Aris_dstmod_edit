local assets =
{
    Asset("ANIM", "anim/alice_broom.zip"),
    Asset("ATLAS", "images/inventoryimages/alice_broom.xml"),
}
-- alice_broom 手部装备，基于原版的清洁扫把，可以给物品换皮肤。
-- 当前功能：
-- 1. 拾取物品：点击地面上的物品拾取，同时拾取附近一定范围内的相同物品。已实现
-- 2. 收获物品：收获大部分可采集物品和作物。
-- 3. 地图传送：手持时，玩家打开地图，点击已探索的地形传送。

-- 注意：替换鼠标文本的功能未实现，始终显示为默认文本“打扫”。
-- 如果需要实现该功能，请进一步修改 `actionpicker` 组件。
-- 地图传送功能可以传送到漂浮平台上，可以传送到未探索的地形上。没有音效和特效。

local UpvalueHacker = require("alice_utils/upvaluehacker")

local function onequip(inst, owner)
    -- Progress: Map teleport logic is triggered when the broom is equipped.
    -- Ensure the owner is valid and pass it to EnableMapTeleport.
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
    -- Progress: Unhooking the MapScreen's OnClick function when the broom is unequipped.
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

    if owner.HUD and owner.HUD.controls.MapScreen then
        local MapScreen = owner.HUD.controls.MapScreen
        if MapScreen._alice_originalOnClick then
            MapScreen.OnClick = MapScreen._alice_originalOnClick
            MapScreen._alice_originalOnClick = nil
        end
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
        -- print("[Debug] ReskinTarget called for:", target.prefab)
        spellCB(inst, target, nil, doer)
        return true
    end
    -- print("[Debug] ReskinTarget failed for:", target.prefab)
    return false
end

-- 确保拾取半径已定义
if TUNING.ALICE_BROOM_PICKUP_RADIUS == nil then
    TUNING.ALICE_BROOM_PICKUP_RADIUS = 15 -- 默认拾取半径为 15
    -- print("[Debug] TUNING.ALICE_BROOM_PICKUP_RADIUS was nil. Set to default value: 15")
end

-- 拾取功能（修复后）
local function PickUpItems(inst, doer, target)
    if target == nil or not target:IsValid() then
        return false
    end

    -- 确保 doer 是玩家实体并具有 inventory 组件
    if not doer.components.inventory then
        -- print("[Debug] PickUpItems: Doer is not a valid player entity.")
        return false
    end

    -- 确保目标具有 inventoryitem 组件
    if not target.components.inventoryitem then
        -- print("[Debug] PickUpItems: Target does not have an inventoryitem component. Target:", target.prefab)
        return false
    end

    local x, y, z = target.Transform:GetWorldPosition()
    if x == nil or y == nil or z == nil then
        return false
    end

    -- 确保搜索半径有效
    local radius = TUNING.ALICE_BROOM_PICKUP_RADIUS
    if type(radius) ~= "number" or radius <= 0 then
        radius = 15
    end

    -- 排除不可拾取物品
    local exclude_tags = {"heavy", "irreplaceable", "nonpackable", "nosteal", "FX"}
    if target:HasOneOfTags(exclude_tags) or target.components.inventoryitem.nobounce then
        return false
    end

    -- 检查玩家是否有 inventory 组件
    if not doer.components.inventory then
        return false
    end

    -- 查找目标及其周围同类物品
    local target_prefab = target.prefab
    local items = TheSim:FindEntities(x, y, z, radius, nil, exclude_tags)

    -- 计算总堆叠数量
    local total_stack_size = 0
    local max_stack_size = 400
    local dropped_items = {} -- 用于存储未能拾取的物品
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
                break
            end

            total_stack_size = total_stack_size + stack_size
            item:Remove() -- 移除地面上的物品
        end
    end

    if total_stack_size > 0 then
        -- 使用 for 循环逐个生成物品并添加到玩家物品栏
        for i = 1, total_stack_size do
            local new_item = SpawnPrefab(target_prefab)
            if not doer.components.inventory:GiveItem(new_item) then
                -- 背包满时将物品存储到 dropped_items 表中
                table.insert(dropped_items, new_item)
            end
        end
    end

    -- 将未能拾取的物品掉落在玩家附近
    if #dropped_items > 0 then
        for _, item in ipairs(dropped_items) do
            local px, py, pz = doer.Transform:GetWorldPosition()
            item.Transform:SetPosition(px + math.random() * 2 - 1, py, pz + math.random() * 2 - 1)
        end
    end

    return true
end

-- 收获功能（修复后）
local function HarvestItems(inst, doer, target)
    if target == nil or not target:IsValid() then
        -- print("[Debug] HarvestItems: Invalid target")
        return false
    end

    -- 确保目标具有 pickable 组件
    if not target.components.pickable then
        -- print("[Debug] HarvestItems: Target does not have a pickable component. Target:", target.prefab)
        return false
    end

    local x, y, z = target.Transform:GetWorldPosition()
    if x == nil or y == nil or z == nil then
        -- print("[Debug] HarvestItems: Invalid target position")
        return false
    end

    -- 确保搜索半径有效
    local radius = TUNING.ALICE_BROOM_PICKUP_RADIUS or 15
    local max_harvest_count = 40
    local harvested_count = 0

    -- 查找蜂箱，范围为 2 倍 radius
    local beeboxes = TheSim:FindEntities(x, y, z, radius * 2, nil, nil, {"beebox"})
    local has_beebox_nearby = #beeboxes > 0
    -- print("[Debug] Actual radius used:", radius, "Beebox search radius:", radius*2)

    -- 特殊处理：收获地面上的花瓣（不包括恶魔花），但附近有蜂箱时跳过
--entities = TheSim:FindEntities(x, y, z, radius, must_have_tags, cant_have_tags, must_have_one_of_tags)
    local flowers = TheSim:FindEntities(x, y, z, radius, {"flower", "cattoy"}, {"INLIMBO", "FX", "NOCLICK"}) -- 只匹配prefab为"flower"的实体
    -- print(string.format(
    --     "[Debug] HarvestParams | PlayerPos: (%.2f, %.2f, %.2f) | Beeboxes: %d | Flowers: %d",
    --     x, y, z, #beeboxes, #flowers
    -- ))

    for _, flower in ipairs(flowers) do
        if harvested_count >= max_harvest_count then
            -- print("[Debug] HarvestItems: Reached harvest limit. Stopping flower collection.")
            break
        end

        -- 优化判断顺序：先验证有效性
        if flower:IsValid() and flower.components.pickable then
            -- 蜂箱存在时跳过所有普通花
            if not has_beebox_nearby then
                -- 执行收获
                if flower.components.pickable:CanBePicked() then
                    flower.components.pickable:Pick(doer)
                    local loot = SpawnPrefab(flower.components.pickable.product)
                    if loot and not doer.components.inventory:GiveItem(loot) then
                        -- 修复：背包满时将物品掉落在玩家位置
                        loot.Transform:SetPosition(doer.Transform:GetWorldPosition())
                    end
                    harvested_count = harvested_count + 1
                    -- print("[Debug] Harvested flower:", flower.prefab)
                end
            else
                -- 添加玩家说话逻辑
                if doer.components.talker then
                    doer.components.talker:Say(STRINGS.ACTIONS.ALICE_BROOM_BEEKEEPING_WARNING)
                end
                -- print("[Debug] HarvestItems: Skipping flower (beebox nearby):", flower.prefab)
            end
        else
            -- print("[Debug] HarvestItems: Invalid flower:", flower and flower.prefab or "nil")
        end
    end

    -- 查找目标及其周围的可收获物品，排除所有花
    local items = TheSim:FindEntities(x, y, z, radius, {"pickable"}, {"INLIMBO", "FX", "NOCLICK", "flower"}) -- 排除所有花
    for _, item in ipairs(items) do
        if harvested_count >= max_harvest_count then
            -- print("[Debug] HarvestItems: Reached harvest limit. Stopping collection.")
            break
        end

        if item.components.pickable and item.components.pickable:CanBePicked() then
            -- print("[Debug] HarvestItems: Picking item:", item.prefab)
            local product = item.components.pickable.product
            local num = item.components.pickable.numtoharvest or 1

            -- 收获物品
            item.components.pickable:Pick(doer)
            harvested_count = harvested_count + 1

            -- 将产物放入玩家背包
            for i = 1, num do
                local loot = SpawnPrefab(product)
                if loot and not doer.components.inventory:GiveItem(loot) then
                    -- 修复：背包满时将物品掉落在玩家位置
                    loot.Transform:SetPosition(doer.Transform:GetWorldPosition())
                end
            end
        else
            -- print("[Debug] HarvestItems: Item cannot be picked or is invalid:", item and item.prefab or "nil")
        end
    end

    return harvested_count > 0
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
    inst:AddTag("bramble_resistant") -- 添加 bramble_resistant 标签到装备本身

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

    inst.components.spellcaster:SetSpellFn(function(inst, target, pos, doer)
        -- 确保参数正确传递
        if target == nil then
            -- print("[Debug] SpellFn: Target is nil. Doer:", doer.prefab, "Position:", pos and (pos.x .. ", " .. pos.y .. ", " .. pos.z) or "nil")
            return false
        end
    
        if not target:IsValid() then
            -- print("[Debug] SpellFn: Target is not valid:", target.prefab or "unknown")
            return false
        end
    
        -- print("[Debug] SpellFn: Valid target:", target.prefab)
    
        -- 如果 pos 为 nil，尝试从目标获取位置
        if pos == nil then
            local x, y, z = target.Transform:GetWorldPosition()
            if x == nil or y == nil or z == nil then
                -- print("[Debug] SpellFn: Unable to retrieve target's position.")
                return false
            end
            pos = { x = x, y = y, z = z }
            -- print("[Debug] SpellFn: Retrieved target position:", pos.x, pos.y, pos.z)
        end
        
        -- 检查是否可以换肤
        if safe_can_cast(doer, target, pos) then
            -- print("[Debug] SpellFn: Attempting reskin")
            spellCB(inst, target, pos, doer)
            return true
        end

        -- 检查是否可以收获
        if target.components.pickable and target.components.pickable:CanBePicked() then
            -- print("[Debug] SpellFn: Attempting harvest")
            return HarvestItems(inst, doer, target)
        end

        -- 检查是否可以拾取
        if target.components.inventoryitem and not target:IsInLimbo() then
            -- print("[Debug] SpellFn: Attempting pickup")
            return PickUpItems(inst, doer, target)
        end
    
        -- print("[Debug] SpellFn: No valid action for target:", target.prefab)
        return false
    end)
    
    inst.components.spellcaster:SetCanCastFn(function(doer, target, pos)
        -- 确保参数正确传递
        if target == nil then
            -- print("[Debug] CanCastFn: Target is nil")
            return false
        end
    
        if not target:IsValid() then
            -- print("[Debug] CanCastFn: Target is not valid:", target.prefab or "unknown")
            return false
        end
    
        -- 检查是否可以换肤
        local can_reskin = safe_can_cast(doer, target, pos)
    
        -- 检查是否可以拾取
        local can_pickup = target.components.inventoryitem and not target:HasTag("heavy")
    
        -- 检查是否可以收获
        local can_harvest = target.components.pickable and target.components.pickable:CanBePicked()
    
        -- print("[Debug] CanCastFn: can_reskin =", can_reskin, ", can_pickup =", can_pickup, ", can_harvest =", can_harvest, ", target =", target.prefab or "unknown")
    
        return can_reskin or can_pickup or can_harvest
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