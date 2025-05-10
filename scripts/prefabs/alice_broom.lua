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

-- 模块1：处理巨大作物
local function HandleGiantCrop(target, doer)
    if target:HasTag("giantcrop") and not target:HasTag("waxed") then
        -- 敲击掉落果实和种子
        local loots = {
            { prefab = target.product.."_oversized", count = 1 }, -- 果实
            { prefab = target.seed, count = math.random(2,3) }   -- 种子
        }
        
        target:Remove()
        for _, v in ipairs(loots) do
            for i = 1, v.count do
                doer.components.inventory:GiveItem(SpawnPrefab(v.prefab))
            end
        end
        return true
    end
    return false
end

-- 模块2：处理可工作物品
local WORK_ACTIONS = {
    [ACTIONS.CHOP] = {"tree", "mast"},
    [ACTIONS.MINE] = {"rock", "boulder"},
    [ACTIONS.HAMMER] = {"mech"},
    [ACTIONS.DIG] = {"stump"}
}

-- 优化后的工作目标处理
local function HandleWorkable(target, doer)
    if target.components.workable and not target:HasTag("structure") then
        local action = target.components.workable.action
        
        -- 过滤不可操作植物
        if target:HasTag("plant") and not target:HasTag("stump") then
            return false
        end
        
        -- 执行动作（通过模拟玩家操作）
        if ACTION_MAP[action] then
            doer.components.playercontroller:DoAction(BufferedAction(doer, target, action))
            return true
        end
    end
    return false
end

-- 模块3：收获作物
local function HarvestCrops(doer, target)
    if target.components.crop and target.components.crop:IsReadyForHarvest() then
        local main_pos = target:GetPosition()
        local harvested = 0
        local max_harvest = 40
        
        -- 搜索附近同类型作物
        local crops = TheSim:FindEntities(main_pos.x, main_pos.y, main_pos.z, 15, {"crop"}, {"INLIMBO", "burnt"})
        for _, crop in ipairs(crops) do
            if harvested >= max_harvest then break end
            if crop.prefab == target.prefab and crop.components.crop:IsReadyForHarvest() then
                crop.components.crop:Harvest(doer)
                harvested = harvested + 1
            end
        end
        return true
    end
    return false
end

-- 整合目标处理
function HandleTargetAction(doer, target)
    return HandleGiantCrop(target, doer)
        or HandleWorkable(target, doer)
        or HarvestCrops(doer, target)
end

-- 模块4：地面物品收集
function CollectGroundItems(doer, pos, target_item)
    -- 获取目标物品类型（若无目标则返回）
    local target_prefab = target_item and target_item.prefab
    if not target_prefab then return end

    -- 搜索范围内同类物品
    local items = TheSim:FindEntities(pos.x, pos.y, pos.z, 8, {target_prefab}, {"INLIMBO", "irreplaceable"})
    
    -- 收集所有同类物品
    for _, item in ipairs(items) do
        if item.components.inventoryitem:CanBePickedUp() then
            doer.components.inventory:GiveItem(item)
            item:RemoveFromScene()
        end
    end
end

-- 模块5：地图传送
function OpenTeleportMap(doer)
    doer:DoTaskInTime(0, function() 
        -- 客户端打开地图
        TheFrontEnd:PushScreen(WorldMapScreen())
        
        -- 监听地图点击
        doer:ListenForEvent("mapexplored", function(_, pos)
            if TheWorld.Map:IsVisualGroundAtPoint(pos.x, 0, pos.z) then
                -- 服务端传送验证
                SendRPCToServer(RPC.TeleportTo, pos.x, 0, pos.z)
                TheFrontEnd:PopScreen() -- 关闭地图
            end
        end)
    end)
end

local original_spellCB = UpvalueHacker.GetUpvalue(Prefabs["reskin_tool"].fn, "spellCB")
local function custom_spellCB(inst, target, pos)
    local doer = inst.components.inventoryitem.owner

    -- 功能分支1：右键自己传送
    if target == doer then
        OpenTeleportMap(doer)
        return true -- 阻断后续操作
    end

    -- 功能分支2：处理地面点击（拾取物品）已废弃，合并到功能3
    if target == nil then
        return false
    end

    -- 功能分支3：处理特殊目标
    if target ~= nil then
        -- 优先处理巨大作物
        if target:HasTag("giantcrop") and not target:HasTag("waxed") then
            HandleGiantCrop(target, doer)
            return true
        end

        -- 处理可工作目标（砍树/开矿等）
        if HandleWorkable(target, doer) then
            return true
        end

        -- 批量收获作物
        if HarvestCrops(doer, target) then
            return true
        end

        --拾取地面物品
        if target.components.inventoryitem and target.components.inventoryitem:CanBePickedUp() then
            CollectGroundItems(doer, target:GetPosition(), target) -- 传入目标物品
            return true
        end
    end

    -- 未处理特殊操作时调用原版换肤逻辑
    return original_spellCB(inst, target, pos)
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
    inst.components.spellcaster:SetSpellFn(custom_spellCB)
    inst.components.spellcaster.canuseontargets = true
    inst.components.spellcaster.canuseondead = true
    inst.components.spellcaster.veryquickcast = true
    inst.components.spellcaster.canusefrominventory  = true

    local original_can_cast_fn = UpvalueHacker.GetUpvalue(Prefabs["reskin_tool"].fn, "can_cast_fn")
    if original_can_cast_fn then
        inst.components.spellcaster:SetCanCastFn(original_can_cast_fn)
    end


    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.MED_FUEL

    MakeHauntableLaunchAndIgnite(inst)

    inst._cached_reskinname = {}

	inst.OnSave = OnSave
	inst.OnLoad = OnLoad

    return inst
end

return Prefab("alice_broom", tool_fn, assets, prefabs)