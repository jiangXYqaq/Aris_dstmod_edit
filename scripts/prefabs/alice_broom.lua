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
    data.has_speed_upgrade = inst.has_speed_upgrade
    data.has_teleport_upgrade = inst.has_teleport_upgrade
end

local function OnLoad(inst, data)
    if data then
        inst._had_fastbuilder = data._had_fastbuilder
        inst._had_fastpicker = data._had_fastpicker
        inst.has_speed_upgrade = data.has_speed_upgrade or false
        inst.has_teleport_upgrade = data.has_teleport_upgrade or false
         -- 加载后应用升级效果
        if inst.has_speed_upgrade then
            inst.components.equippable.walkspeedmult = TUNING.ALICE_BROOM_SPEED_MULT + 0.5
        end
    end
end

local function GetNextSkin(userid, target, tool, skip_base)
    local cached_skin = nil
    local prefab_to_skin = target.prefab
    local is_beard = false
    local skin_custom = nil
    if target.components.beard ~= nil and target.components.beard.is_skinnable then
        prefab_to_skin = target.prefab .. "_beard"
        is_beard = true
    end
    if target:IsValid() and tool:IsValid() and tool.parent and tool.parent:IsValid() then
        local curr_skin = is_beard and target.components.beard.skinname or target.skinname
        cached_skin = tool._cached_reskinname[prefab_to_skin]
        local search_for_skin = cached_skin ~= nil --also check if it's owned
        local force_change_cache
        local must_have, must_not_have
        if target.ReskinToolFilterFn ~= nil then
            must_have, must_not_have = target:ReskinToolFilterFn()
            if cached_skin then
                if must_have ~= nil and not StringContainsAnyInArray(cached_skin, must_have) or must_not_have ~= nil and StringContainsAnyInArray(cached_skin, must_not_have) then
                    force_change_cache = cached_skin
                end
            end
        end
        if force_change_cache or curr_skin == cached_skin or (search_for_skin and not TheInventory:CheckClientOwnership(userid, cached_skin)) or (cached_skin == nil and skip_base) then
            local new_reskinname = nil
    
            local prefabskins = PREFAB_SKINS[prefab_to_skin]
            if prefabskins ~= nil then
                local unlockableskins = nil
                local function UnlockableSkinDiffers(item_type)
                    if UNLOCKABLE_SKINS[item_type] and target.ReskinToolCustomDataDiffers then
                        if not unlockableskins then
                            unlockableskins = TheInventory:GetClientUnlockableItems(userid)
                        end
                        if unlockableskins[item_type] then
                            return target:ReskinToolCustomDataDiffers(unlockableskins[item_type].skin_custom)
                        end
                    end
                    return false
                end
                local maxindex = #prefabskins
                local foundskin = not search_for_skin
                local i = 1
                while i <= maxindex do
                    local item_type = prefabskins[i]
                    if item_type then
                        local skip_this = PREFAB_SKINS_SHOULD_NOT_SELECT[item_type] or false
                        if SKINS_EVENTLOCK[item_type] and not IsSpecialEventActive(SKINS_EVENTLOCK[item_type]) then
                            skip_this = true
                        end
                        if not skip_this then
                            if must_have ~= nil and not StringContainsAnyInArray(item_type, must_have) or must_not_have ~= nil and StringContainsAnyInArray(item_type, must_not_have) then
                                skip_this = true
                            end
                            if not skip_this then
                                if search_for_skin then
                                    if cached_skin == item_type then
                                        search_for_skin = false
                                        if UnlockableSkinDiffers(item_type) then
                                            new_reskinname = item_type
                                            skin_custom = unlockableskins[item_type].skin_custom
                                            break
                                        end
                                        if skip_base and i == maxindex then
                                            i = 0 -- Restart the loop.
                                        end
                                    end
                                elseif item_type ~= curr_skin then
                                    if TheInventory:CheckClientOwnership(userid, item_type) then
                                        new_reskinname = item_type
                                        break
                                    end
                                elseif UnlockableSkinDiffers(item_type) then
                                    new_reskinname = item_type
                                    skin_custom = unlockableskins[item_type].skin_custom
                                    break
                                end
                            end
                        end
                    end
                    i = i + 1
                end
            end
            cached_skin = new_reskinname
        end
        if force_change_cache and force_change_cache == cached_skin then
            cached_skin = nil
        end
    end
    return cached_skin, prefab_to_skin, is_beard, skin_custom
end

-- spellCB（简化版，去掉特效部分）
local function spellCB(tool, target, pos, caster)
    target = target or caster
    if not target then return end
    
    if target.reskin_tool_target_redirect and target.reskin_tool_target_redirect:IsValid() then
        target = target.reskin_tool_target_redirect
    end
    if target._playerlink ~= nil and target._playerlink ~= caster then
        return
    end
    if target.reskin_tool_cannot_target_this then
        return
    end

    local userid = tool.parent and tool.parent.userid or ""
    local skip_base = PREFAB_SKINS_SHOULD_NOT_SELECT[target.prefab]
    local cached_skin, prefab_to_skin, is_beard, skin_custom = GetNextSkin(userid, target, tool, skip_base)
    if cached_skin == nil and skip_base then
        return
    end
    tool._cached_reskinname[prefab_to_skin] = cached_skin

    -- 应用皮肤（去掉特效部分）
    tool:DoTaskInTime(0, function()
        if target:IsValid() and tool:IsValid() and tool.parent and tool.parent:IsValid() then
            if is_beard then
                target.components.beard:SetSkin(cached_skin)
            else
                TheSim:ReskinEntity(target.GUID, target.skinname, cached_skin, nil, userid)
            end
        end
    end)
end

local function can_cast_fn(doer, target, pos, tool)
    if target.reskin_tool_target_redirect and target.reskin_tool_target_redirect:IsValid() then
        target = target.reskin_tool_target_redirect
    end

    -- NOTES(DiogoW): Expand this into a target function in case more cases are added.
    if target._playerlink ~= nil and target._playerlink ~= doer then
        return false -- Only our owner is allowed to change our skin.
    end

    if target.reskin_tool_cannot_target_this then
        return false
    end

    local prefab_to_skin = target.prefab
    local is_beard = false

    if table.contains( DST_CHARACTERLIST, prefab_to_skin ) then
        --We found a player, check if it's us
        if doer.userid == target.userid and target.components.beard ~= nil and target.components.beard.is_skinnable then
            prefab_to_skin = target.prefab .. "_beard"
            is_beard = true
        else
            return false
        end
    end

    local skip_base = PREFAB_SKINS_SHOULD_NOT_SELECT[target.prefab]
    local cached_skin = GetNextSkin(doer.userid, target, tool, skip_base)
    if cached_skin == nil and skip_base then
        return false -- Client does not own any skin but they tried to reskin it anyway.
    end
    if cached_skin then
        return true
    end

    --Is there a skin to turn off?
    local curr_skin = is_beard and target.components.beard.skinname or target.skinname
    if curr_skin ~= nil then
        return true
    end

    return false
end

-- 在alice_broom.lua中找到原版can_cast_fn的获取位置，替换为：
local original_can_cast_fn = can_cast_fn
local function safe_can_cast(doer, target, pos, tool)
    return doer ~= nil
        and doer:IsValid()
        and target ~= nil 
        and target:IsValid() 
        and original_can_cast_fn(doer, target, pos, tool)
end

local function ReskinTarget(inst, doer, target)
    if safe_can_cast(doer, target, nil, inst) then
        spellCB(inst, target, nil, doer)
        return true
    end
    return false
end

-- 确保拾取半径已定义
if TUNING.ALICE_BROOM_PICKUP_RADIUS == nil then
    TUNING.ALICE_BROOM_PICKUP_RADIUS = 15 -- 默认拾取半径为 15
    -- print("[Debug] TUNING.ALICE_BROOM_PICKUP_RADIUS was nil. Set to default value: 15")
end

-- 拾取功能（优化版：不可堆叠直接拾取，可堆叠批量拾取）
local function PickUpItems(inst, doer, target)
    if not target or not target:IsValid() then
        return false
    end
    if not doer or not doer.components.inventory then
        return false
    end
    if not target.components.inventoryitem then
        return false
    end
    --[[ if target.components.container or target:HasTag("bundle") or target:HasTag("alice_remote") then
        return false
    end ]]
    if target:HasOneOfTags({"heavy", "irreplaceable", "nonpackable", "nosteal", "FX"}) 
        or target.components.inventoryitem.nobounce then
        return false
    end

    -- 判断是否可堆叠
    local function IsStackable(item)
        return item.components.stackable and item.components.stackable:IsStack()
    end

    -- 不可堆叠物品：直接拾取原物品，不进行批量
    if not IsStackable(target) then
        return doer.components.inventory:GiveItem(target)
    end

    -- 可堆叠物品：走批量拾取逻辑
    local x, y, z = target.Transform:GetWorldPosition()
    if not x then return false end

    local radius = TUNING.ALICE_BROOM_PICKUP_RADIUS or 15
    local target_prefab = target.prefab
    local exclude_tags = {"heavy", "irreplaceable", "nonpackable", "nosteal", "FX"}
    local items = TheSim:FindEntities(x, y, z, radius, nil, exclude_tags)

    local total_stack_size = 0
    local max_stack_size = 400
    local dropped_items = {}

    for _, item in ipairs(items) do
        if item.prefab == target_prefab 
            and item.components.inventoryitem 
            and item.components.inventoryitem.canbepickedup 
            and not item:IsInLimbo() 
            and not item.components.container 
            and item.prefab ~= "bullkelp_beachedroot" 
            and IsStackable(item)  -- 只处理可堆叠物品
        then
            local stack_size = item.components.stackable:StackSize()
            if total_stack_size + stack_size > max_stack_size then
                break
            end
            total_stack_size = total_stack_size + stack_size
            item:Remove()
        end
    end

    if total_stack_size > 0 then
        for i = 1, total_stack_size do
            local new_item = SpawnPrefab(target_prefab)
            if not doer.components.inventory:GiveItem(new_item) then
                table.insert(dropped_items, new_item)
            end
        end
    end

    if #dropped_items > 0 then
        for _, item in ipairs(dropped_items) do
            local px, py, pz = doer.Transform:GetWorldPosition()
            item.Transform:SetPosition(px + math.random() * 2 - 1, py, pz + math.random() * 2 - 1)
        end
    end

    return true
end

local function ProcessFarmPlant(crop_entity, doer)
    -- Ensure the crop name matches the original naming convention
    local base_crop = crop_entity.prefab:match("^farm_plant_(.+)$")
    if not base_crop then
        -- Ignore non-standard crop names
        -- support for other mod crops edit this
        return false
    end

    -- Define product configurations
    local products = {
        normal_veg = base_crop,                   -- Regular crop (e.g., carrot)
        normal_seed = base_crop .. "_seeds",      -- Regular seed
        giant_veg = base_crop .. "_oversized"     -- Giant crop product
    }

    -- Validate product existence
    local can_normal = PrefabExists(products.normal_veg) and PrefabExists(products.normal_seed)
    if not can_normal then
        -- Ignore crops with missing product definitions
        return false
    end

    -- Get crop position
    local x, y, z = crop_entity.Transform:GetWorldPosition()
    local is_oversized = crop_entity.is_oversized

    -- Determine output based on stress value
    local stress = crop_entity.components.farmplantstress and crop_entity.components.farmplantstress:GetFinalStressState() or 0
    local veg_count, seed_count = 0, 0

    if is_oversized then
        --magicgrowable = true 
        --if use magic book even if stress is 0 is_oversized = false
        veg_count, seed_count = 2.75 * 2, 2.25 * 2 -- Double the output
    elseif stress <= 6 then
        veg_count, seed_count = 1 * 2, 2 * 2
    elseif stress <= 11 then
        veg_count, seed_count = 1 * 2, 1 * 2
    else
        veg_count, seed_count = 1 * 2, 0
    end

    -- Remove the crop entity
    -- may not compatible with mods like crop regrowth
    crop_entity:Remove()

    -- Handle fractional parts using probabilities
    local function spawn_items(prefab, count)
        local whole = math.floor(count)
        local fractional = count - whole

        -- Spawn whole items
        for _ = 1, whole do
            local item = SpawnPrefab(prefab)
            if not doer.components.inventory:GiveItem(item) then
                -- Drop near the player if inventory is full
                local px, py, pz = doer.Transform:GetWorldPosition()
                item.Transform:SetPosition(px + math.random(-1, 1), py, pz + math.random(-1, 1))
            end
        end

        -- Handle fractional part with probability
        if math.random() < fractional then
            local item = SpawnPrefab(prefab)
            if not doer.components.inventory:GiveItem(item) then
                -- Drop near the player if inventory is full
                local px, py, pz = doer.Transform:GetWorldPosition()
                item.Transform:SetPosition(px + math.random(-1, 1), py, pz + math.random(-1, 1))
            end
        end
    end

    -- Spawn vegetables and seeds
    spawn_items(products.normal_veg, veg_count)
    spawn_items(products.normal_seed, seed_count)

    return true, is_oversized
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

        -- 第一阶段：专门处理农田作物（包含 farm_plant 标签）
    local farm_plant_items = TheSim:FindEntities(x, y, z, radius, {"pickable", "farm_plant"}, {"INLIMBO", "FX", "NOCLICK", "flower"})
    for _, item in ipairs(farm_plant_items) do
        if harvested_count >= max_harvest_count then
            break
        end

        if item.components.pickable and item.components.pickable:CanBePicked() then
            if item.prefab and item.components.farmplantstress then
                local success, is_oversized = ProcessFarmPlant(item, doer)
                if success then
                    harvested_count = harvested_count + (is_oversized and 5 or 2)
                end
            end
        end
    end

        -- 第二阶段：处理其他可收获物品（排除 farm_plant 标签）
    local non_farm_items = TheSim:FindEntities(x, y, z, radius, {"pickable"}, {"INLIMBO", "FX", "NOCLICK", "flower", "farm_plant"})
    for _, item in ipairs(non_farm_items) do
        if harvested_count >= max_harvest_count then
            break
        end

        if item.components.pickable and item.components.pickable:CanBePicked() then
            -- 原始普通物品收获逻辑（对应行349附近代码）
            -- print("[Debug] HarvestItems: Picking item:", item.prefab)
            local product = item.components.pickable.product
            local num = item.components.pickable.numtoharvest or 1

            item.components.pickable:Pick(doer)
            harvested_count = harvested_count + 1

            -- 产物放入背包或掉落
            if product then
                for i = 1, num do
                    local loot = SpawnPrefab(product)
                    if loot and not doer.components.inventory:GiveItem(loot) then
                        loot.Transform:SetPosition(doer.Transform:GetWorldPosition())
                    end
                end
            end
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
    inst:AddTag("nosteal")

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
    inst.components.spellcaster.canusefrominventory = true

    inst.components.spellcaster:SetSpellFn(function(inst, target, pos, doer)
        if not target or not target:IsValid() then
            return false
        end

        -- 1. 换肤（最高优先级）
        if safe_can_cast(doer, target, pos, inst) then
            spellCB(inst, target, pos, doer)
            return true
        end

        -- 2. 收获
        if target.components.pickable and target.components.pickable:CanBePicked() then
            return HarvestItems(inst, doer, target)
        end

        -- 3. 拾取
        if target.components.inventoryitem and not target:IsInLimbo() then
            return PickUpItems(inst, doer, target)
        end

        return false
    end)

    inst.components.spellcaster:SetCanCastFn(function(doer, target, pos)
        if not target or not target:IsValid() then
            return false
        end

        -- 只要任一功能可用就返回 true
        local can_reskin = safe_can_cast(doer, target, pos, inst)
        local can_harvest = target.components.pickable and target.components.pickable:CanBePicked()
        local can_pickup = target.components.inventoryitem and not target:HasTag("heavy")

        return can_reskin or can_harvest or can_pickup
    end)

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.MED_FUEL

    MakeHauntableLaunchAndIgnite(inst)

    inst._cached_reskinname = {}

    -- 添加交易组件
    inst:AddComponent("trader")
    inst.components.trader.acceptnontradable = true
    inst.components.trader:SetAcceptTest(function(inst, item, giver)
        -- 海象牙交易检查
        if item.prefab == "rabbit" and not inst.has_speed_upgrade then
            return true
        -- 橙宝石交易检查
        elseif item.prefab == "orangegem" and not inst.has_teleport_upgrade then
            return true
        end
        return false
    end)
    
    inst.components.trader.onrefuse = function(inst, giver, item)
        -- 可选：添加拒绝音效或提示
    end
    
    inst.components.trader.onaccept = function(inst, giver, item)
        -- 处理海象牙交易
        if item.prefab == "rabbit" then
            inst.has_speed_upgrade = true
            -- 提升移动速度（假设基础值1.0）
            inst.components.equippable.walkspeedmult = TUNING.ALICE_BROOM_SPEED_MULT + 0.5
            
        -- 处理橙宝石交易
        elseif item.prefab == "orangegem" then
            inst.has_teleport_upgrade = true
        end
    end

    -- 初始化升级状态
    inst.has_speed_upgrade = false
    inst.has_teleport_upgrade = false

	inst.OnSave = OnSave
	inst.OnLoad = OnLoad

    return inst
end

return Prefab("alice_broom", tool_fn, assets, prefabs)