GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})
local wx78_moduledefs = require("wx78_moduledefs")
local module_definitions = wx78_moduledefs.module_definitions
local AddCreatureScanDataDefinition = wx78_moduledefs.AddCreatureScanDataDefinition
local GetModuleDefinitionFromNetID = wx78_moduledefs.GetModuleDefinitionFromNetID
local AddNewModuleDefinition = wx78_moduledefs.AddNewModuleDefinition
local getprefab = require("alice_utils/getprefab")
-- 魔法电路温度相关常量
local COMFORT_MIN_TEMP = 10
local COMFORT_MAX_TEMP = 60
local ORIGINAL_MIN_TEMP = nil
local ORIGINAL_MAX_TEMP = nil
---------------------------------------------
-------------------强化魔法-------------------
---------------------------------------------

-- 辅助函数：记录原始护盾上限
local function record_original_shield_max(wx)
    if wx.components.wx78_shield and wx._original_shield_max == nil then
        wx._original_shield_max = wx.components.wx78_shield.max
    end
end

-- 辅助函数：恢复原始护盾上限
local function restore_original_shield_max(wx)
    if wx.components.wx78_shield and wx._original_shield_max ~= nil then
        wx.components.wx78_shield.max = wx._original_shield_max
        wx._original_shield_max = nil
    end
end

-- 辅助函数：获取装备理智回复的增益（覆写 get_equippable_dappernessfn）
local function GetEquippableDappernessForMagic(owner, equippable)
    local original_fn = owner._original_get_equippable_dappernessfn
    local dapperness = original_fn and original_fn(owner, equippable) or equippable:GetDapperness(owner, owner.components.sanity.no_moisture_penalty)
    -- 应用增益
    if dapperness > 0 then
        dapperness = dapperness * (1 + TUNING.MAGIC_SANITY_REGEN_BONUS_PERCENT)
    end
    return dapperness
end

local function maxhealth_change(inst, wx, amount, isloading)
    if wx.components.health then
        local current_health_percent = wx.components.health:GetPercent()

        wx.components.health.maxhealth = wx.components.health.maxhealth + amount

        if not isloading then
            wx.components.health:SetPercent(current_health_percent)
            local up = amount > 0
            wx:PushEvent("forcehealthpulse", { up = up, down = not up })
        end
    end
end

local function maxhunger_change(inst, wx, amount, isloading)
    if wx.components.hunger then
        local current_hunger_percent = wx.components.hunger:GetPercent()

        wx.components.hunger:SetMax(wx.components.hunger.max + amount)

        -- Tie it to the module instance so we don't have to think too much about removing them.
        if inst._hunger_module_burnrate ~= nil then
            wx.components.hunger.burnratemodifiers:SetModifier(inst, inst._hunger_module_burnrate)
        end

        if not isloading then
            wx.components.hunger:SetPercent(current_hunger_percent, false)
        end
    end
end

local function maxsanity_change(inst, wx, amount, isloading)
    if wx.components.sanity then
        local current_sanity_percent = wx.components.sanity:GetPercent()

        wx.components.sanity:SetMax(wx.components.sanity.max + amount)

        if not isloading then
            wx.components.sanity:SetPercent(current_sanity_percent, false)
        end
    end
end

local function magic_tick(wx)
    if wx.components.health then
        if wx.components.health:IsHurt() then
            wx.components.health:DoDelta(TUNING.MAGIC_HEALTH_REGEN, false, "magic_regen", true)
        else
            if wx.components.wx78_shield then
                wx.components.wx78_shield:DoDelta(TUNING.MAGIC_FULLHEALTH_SHIELD_REGEN)
            end
        end
    end

    if wx.components.sanity then
        wx.components.sanity:DoDelta(TUNING.MAGIC_SANITY_REGEN)
    end

    if wx.components.wx78_shield then
        wx.components.wx78_shield:DoDelta(TUNING.MAGIC_SHIELD_REGEN)
    end
end

-- 修改 magic_activate 函数签名，增加 isloading 参数
local function magic_activate(inst, wx, isloading)
    -- 暴击相关
    if wx.alc_baojilv then
        wx.alc_baojilv = wx.alc_baojilv + TUNING.ALICE_MAGIC_CHANCE
    end
    if wx.alc_baojizhi then
        wx.alc_baojizhi = wx.alc_baojizhi + TUNING.ALICE_MAGIC_VALUE
    end

    -- 三维提升
    maxhealth_change(inst, wx, TUNING.MAGIC_MAXHEALTH_BOOST, isloading)
    maxhunger_change(inst, wx, TUNING.MAGIC_MAXHUNGER_BOOST, isloading)
    maxsanity_change(inst, wx, TUNING.MAGIC_MAXSANITY_BOOST, isloading)

    -- 饥饿燃烧减慢
    if wx.components.hunger and wx.components.hunger.burnratemodifiers then
        wx.components.hunger.burnratemodifiers:SetModifier(inst, TUNING.MAGIC_HUNGER_BURN_SLOW_PERCENT)
    end

    -- 自动回复任务
    if not wx._magic_tick_task then
        wx._magic_tick_task = wx:DoPeriodicTask(TUNING.MAGIC_REGEN_INTERVAL, magic_tick, nil, wx)
    end

    -- 温度舒适范围
    if wx.components.temperature then
        ORIGINAL_MIN_TEMP = wx.components.temperature.mintemp
        ORIGINAL_MAX_TEMP = wx.components.temperature.maxtemp
        wx.components.temperature.mintemp = COMFORT_MIN_TEMP
        wx.components.temperature.maxtemp = COMFORT_MAX_TEMP
    end

    -- 降低疯狂光环影响
    if wx.components.sanity and wx.components.sanity.neg_aura_modifiers then
        wx.components.sanity.neg_aura_modifiers:SetModifier(inst, TUNING.MAGIC_SANITY_AURA_MOD_PERCENT)
    end

    -- 装备物品理智回复增益
    if wx.components.sanity then
        -- 保存原始的 get_equippable_dappernessfn
        if not wx._original_get_equippable_dappernessfn then
            wx._original_get_equippable_dappernessfn = wx.components.sanity.get_equippable_dappernessfn
        end
        wx.components.sanity.get_equippable_dappernessfn = GetEquippableDappernessForMagic
    end

    -- 护盾回复速度
    if wx.components.wx78_shield then
        wx.components.wx78_shield:AddChargeSource(inst, TUNING.MAGIC_SHIELD_REGEN_SPEED, "magic_shield_regen")
    end

    -- 护盾上限增加最大生命值比例
    if wx.components.wx78_shield and wx.components.health then
        record_original_shield_max(wx)
        local new_max = wx.components.health.maxhealth * (1 + TUNING.MAGIC_SHIELD_CAP_BONUS_PERCENT)
        wx.components.wx78_shield:SetMax(math.max(1, new_max))
    end

    -- 物理伤害减免（无法减少护甲生命值损耗）
    if wx.components.combat then
        wx.components.combat.externaldamagetakenmultipliers:SetModifier(
            inst,
            1 - TUNING.MAGIC_PHYSICAL_DAMAGE_REDUCTION_PERCENT,
            "magic_damage_reduction"
        )
    end
end

-- 修改 magic_deactivate
local function magic_deactivate(inst, wx)
    -- 暴击相关
    if wx.alc_baojilv then
        wx.alc_baojilv = wx.alc_baojilv - TUNING.ALICE_MAGIC_CHANCE
    end
    if wx.alc_baojizhi then
        wx.alc_baojizhi = wx.alc_baojizhi - TUNING.ALICE_MAGIC_VALUE
    end

    -- 三维恢复
    maxhealth_change(inst, wx, -TUNING.MAGIC_MAXHEALTH_BOOST)
    maxhunger_change(inst, wx, -TUNING.MAGIC_MAXHUNGER_BOOST)
    maxsanity_change(inst, wx, -TUNING.MAGIC_MAXSANITY_BOOST)

    -- 移除饥饿燃烧修改
    if wx.components.hunger and wx.components.hunger.burnratemodifiers then
        wx.components.hunger.burnratemodifiers:RemoveModifier(inst)
    end

    -- 移除自动回复任务
    if wx._magic_tick_task then
        wx._magic_tick_task:Cancel()
        wx._magic_tick_task = nil
    end

    -- 恢复温度范围
    if wx.components.temperature then
        wx.components.temperature.mintemp = ORIGINAL_MIN_TEMP
        wx.components.temperature.maxtemp = ORIGINAL_MAX_TEMP
    end


    -- 移除疯狂光环修正
    if wx.components.sanity and wx.components.sanity.neg_aura_modifiers then
        wx.components.sanity.neg_aura_modifiers:RemoveModifier(inst)
    end

    -- 恢复原始的 get_equippable_dappernessfn
    if wx.components.sanity then
        if wx._original_get_equippable_dappernessfn then
            wx.components.sanity.get_equippable_dappernessfn = wx._original_get_equippable_dappernessfn
            wx._original_get_equippable_dappernessfn = nil
        else
            wx.components.sanity.get_equippable_dappernessfn = nil
        end
    end

    -- 移除护盾回复速度来源
    if wx.components.wx78_shield then
        wx.components.wx78_shield:RemoveChargeSource(inst, "magic_shield_regen")
    end

    -- 恢复护盾上限
    if wx.components.wx78_shield then
        restore_original_shield_max(wx)
    end

    -- 移除物理伤害减免
    if wx.components.combat then
        wx.components.combat.externaldamagetakenmultipliers:RemoveModifier(inst, "magic_damage_reduction")
    end
end

local MAGIC_MODULE_DATA =
{
    name = "alc_magic",
    slots = 2,
    type = CIRCUIT_BARS.ALPHA,   -- 阿尔法
    activatefn = magic_activate,
    deactivatefn = magic_deactivate,
}

table.insert(module_definitions, MAGIC_MODULE_DATA)
AddNewModuleDefinition(MAGIC_MODULE_DATA)
AddCreatureScanDataDefinition("rocky", "alc_magic", 5)

-------------------------------------------------
-------------------战斗分析模块-------------------
-------------------------------------------------
--光之勇者部分代码在scripts\prefabs\alice.lua\@UpdateBuffAnim
local function nightvision_onworldstateupdate(wx)
    wx:SetForcedNightVision(TheWorld.state.isnight and not TheWorld.state.isfullmoon, true)
end

local function battle_activate(inst, wx)
    wx:DoTaskInTime(0, function()
        wx.alc_goggles:set(true)
        wx.alc_night:set(true)
        wx.battle_activate = true
        if TheWorld and TheWorld:HasTag("cave") then
            wx:SetForcedNightVision(true)
        else
            wx:WatchWorldState("isnight", nightvision_onworldstateupdate)
            wx:WatchWorldState("isfullmoon", nightvision_onworldstateupdate)
            nightvision_onworldstateupdate(wx)
        end
    end)
end

local function battle_deactivate(inst, wx)
    wx:DoTaskInTime(0, function()
        wx.alc_goggles:set(false)
        wx.alc_night:set(false)
        wx.battle_activate = false

        wx:SetForcedNightVision(false)
        if not (TheWorld and TheWorld:HasTag("cave")) then
            wx:StopWatchingWorldState("isnight", nightvision_onworldstateupdate)
            wx:StopWatchingWorldState("isfullmoon", nightvision_onworldstateupdate)
        end
    end)
end

local BATTLE_MODULE_DATA =
{
    name = "alc_battle",
    slots = 3,
    type = CIRCUIT_BARS.GAMMA,   -- 伽马
    activatefn = battle_activate,
    deactivatefn = battle_deactivate,
}

table.insert(module_definitions, BATTLE_MODULE_DATA)
AddNewModuleDefinition(BATTLE_MODULE_DATA)
AddCreatureScanDataDefinition("rocky", "alc_battle", 5)

---------------------------------------------
-------------------充电模块-------------------
---------------------------------------------

local function charge_produce(wx)
    local modules = wx._charge_modules or 0
    if modules <= 0 then return end

    -- 产出量 = 每模块产出量 × 模块数量
    local amount = TUNING.ALICE_CHARGE_PER_TICK * modules
    wx._charge_stored = (wx._charge_stored or 0) + amount
    -- 存储上限 = 每模块上限 × 模块数量
    wx._charge_stored = math.min(wx._charge_stored, TUNING.ALICE_CHARGE_MAX * modules)
end

local function charge_tick(wx)
    local inventory = wx.components.inventory
    if inventory == nil then
        return
    end

    -- 1. 收集当前需要充电的目标标识符
    local current_ids = {}
    
    for i = 1, inventory:GetNumSlots() do
        local item = inventory:GetItemInSlot(i)
        if item and item.components.batteryuser then
            local is_full = item.components.fueled and item.components.fueled:IsFull()
            if not is_full then
                table.insert(current_ids, i)
            end
        end
    end

    local hand_item = inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    if hand_item and hand_item:HasTag("lightsword") and hand_item.components.container then
        local inner_item = hand_item.components.container:GetItemInSlot(1)
        if inner_item and inner_item.components.batteryuser then
            local is_full = inner_item.components.fueled and inner_item.components.fueled:IsFull()
            if not is_full then
                table.insert(current_ids, "hand_inner")
            end
        end
    end

    if hand_item and hand_item.components.batteryuser then
        local is_full = hand_item.components.fueled and hand_item.components.fueled:IsFull()
        if not is_full then
            table.insert(current_ids, "hand")
        end
    end

    if not wx.components.upgrademoduleowner:ChargeIsMaxed() then
        table.insert(current_ids, "player")
    end

    -- 2. 初始化队列并去重
    wx._charge_queue = wx._charge_queue or {}
    for _, id in ipairs(current_ids) do
        local already = false
        for _, q in ipairs(wx._charge_queue) do
            if id == q then
                already = true
                break
            end
        end
        if not already then
            table.insert(wx._charge_queue, id)
        end
    end

    -- 3. 队列为空或没有电荷则返回
    if #wx._charge_queue == 0 or wx._charge_stored <= 0 then
        return
    end

    -- 4. 处理队首
    local id = wx._charge_queue[1]

    -- 玩家特殊处理
    if id == "player" then
        local current = wx.components.upgrademoduleowner:GetChargeLevel()
        local max = wx.components.upgrademoduleowner:GetMaxChargeLevel()
        local needed = max - current
        local actual = math.min(needed, wx._charge_stored)
        if actual > 0 then
            wx.components.upgrademoduleowner:AddCharge(actual)
            wx._charge_stored = wx._charge_stored - actual
            if wx.components.upgrademoduleowner:ChargeIsMaxed() then
                table.remove(wx._charge_queue, 1)
            end
        end
        return
    end

    -- 物品通用处理：根据标识符获取 target
    local target = nil
    if id == "hand" then
        target = inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    elseif id == "hand_inner" then
        local hand = inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if hand and hand:HasTag("lightsword") and hand.components.container then
            target = hand.components.container:GetItemInSlot(1)
        end
    elseif type(id) == "number" then
        target = inventory:GetItemInSlot(id)
    else
        table.remove(wx._charge_queue, 1)
        return
    end

    if not target or not target.components.batteryuser then
        table.remove(wx._charge_queue, 1)
        return
    end

    -- 统一物品充电逻辑
    local chargemultfn = target.components.batteryuser.chargemultfn
    local onbatteryused = target.components.batteryuser.onbatteryused
    if chargemultfn and onbatteryused then
        local needed = chargemultfn(target, wx)
        if needed and needed > 0 then
            local actual = math.min(needed, wx._charge_stored)
            if actual > 0 then
                if onbatteryused(target, wx, actual) then
                    wx._charge_stored = wx._charge_stored - actual
                    if target.components.fueled and target.components.fueled:IsFull() then
                        table.remove(wx._charge_queue, 1)
                    end
                else
                    table.remove(wx._charge_queue, 1)
                end
            end
        else
            table.remove(wx._charge_queue, 1)
        end
    else
        table.remove(wx._charge_queue, 1)
    end
end

local function charge_activate(inst, wx, isloading)
    wx._charge_modules = (wx._charge_modules or 0) + 1

    if wx._charge_modules == 1 then
        wx._charge_stored = wx._charge_stored or 0

        if wx._charge_task then
            wx._charge_task:Cancel()
            wx._charge_task = nil
        end

        wx._charge_task = wx:DoPeriodicTask(TUNING.ALICE_CHARGE_INTERVAL, function()
            charge_produce(wx)
            charge_tick(wx)
        end)
        charge_produce(wx)
        charge_tick(wx)
    end
end

local function charge_deactivate(inst, wx)
    wx._charge_modules = math.max(0, (wx._charge_modules or 1) - 1)

    if wx._charge_modules <= 0 then
        if wx._charge_task then
            wx._charge_task:Cancel()
            wx._charge_task = nil
        end
    end
end

-- 模块定义
local CHARGE_MODULE_DATA = {
    name = "alc_charge",
    slots = 1,
    type = CIRCUIT_BARS.BETA,
    activatefn = charge_activate,
    deactivatefn = charge_deactivate,
}

table.insert(module_definitions, CHARGE_MODULE_DATA)
AddNewModuleDefinition(CHARGE_MODULE_DATA)
AddCreatureScanDataDefinition("rocky", "alc_charge", 5)

-------------------添加新模块-------------------

local modmodule = {
    "alc_charge",
    "alc_magic", 
    "alc_battle", 
}

local dianlu = {
    alc_battle = "music_chip",
    alc_magic = "maxhealth2_chip",
    alc_charge = "maxsanity1_chip",
}


local ImageButton = require "widgets/imagebutton"

-- ============================================================
-- 适配新版三线电路结构的 OnModuleAdded 覆写
-- ============================================================
AddClassPostConstruct("widgets/upgrademodulesdisplay", function(self)
    local oldOnModuleAdded = self.OnModuleAdded

    self.OnModuleAdded = function(self, bartype, moduledefinition_index, ...)
        -- 调用原版处理，确保电路被正确插入对应线路
        if oldOnModuleAdded then
            oldOnModuleAdded(self, bartype, moduledefinition_index, ...)
        end

        local module_def = GetModuleDefinitionFromNetID(moduledefinition_index)
        if module_def == nil then
            return
        end

        local modname = module_def.name
        for _, v in pairs(modmodule) do
            if modname == v then
                -- 获取对应线路的芯片池和当前使用索引
                local pool = self.chip_objectpools[bartype]
                if pool == nil then return end
                local idx = self.chip_poolindexes[bartype] - 1  -- 新插入的芯片索引
                local new_chip = pool[idx]
                if new_chip == nil then return end

                -- 替换芯片符号
                new_chip:GetAnimState():OverrideSymbol("movespeed2_chip", "status_alice", dianlu[modname])

                break
            end
        end
    end


    if self.owner and self.owner:HasTag("alice") then
        self.battery_frame:GetAnimState():SetBank("status_alice")
        self.battery_frame:GetAnimState():SetBuild("status_alice")
        self.battery_frame:GetAnimState():PlayAnimation("aliceframe")
    end
end)

-- ============================================================
-- 覆盖新交互窗口 UI（新增）
-- ============================================================
AddClassPostConstruct("widgets/upgrademodulesdisplay_inspecting", function(self)
    local oldOnModuleAdded = self.OnModuleAdded

    self.OnModuleAdded = function(self, bartype, moduledefinition_index, init)
        -- 先调用原版逻辑
        if oldOnModuleAdded then
            oldOnModuleAdded(self, bartype, moduledefinition_index, init)
        end

        local module_def = GetModuleDefinitionFromNetID(moduledefinition_index)
        if module_def == nil then
            return
        end

        local modname = module_def.name
        for _, v in pairs(modmodule) do
            if modname == v then
                local pool = self.chip_objectpools[bartype]
                if pool == nil then return end
                local idx = self.chip_poolindexes[bartype] - 1
                local new_chip = pool[idx]
                if new_chip == nil then return end

                -- 替换芯片符号（新窗口使用的是 status_wx_chest 或 overrideuibuild）
                -- 但既然你的资源在 status_alice 里，直接指定
                new_chip:GetAnimState():OverrideSymbol("movespeed2_chip", "status_alice", dianlu[modname])
                -- 新窗口还有 glow 和 symbol 子对象，也需要覆盖
--[[                 if new_chip.glow then
                    new_chip.glow:GetAnimState():OverrideSymbol("movespeed2_chip", "status_alice", dianlu[modname])
                end
                if new_chip.symbol then
                    new_chip.symbol:GetAnimState():OverrideSymbol("movespeed2_chip", "status_alice", dianlu[modname])
                end ]]
                break
            end
        end
    end
end)

for k, v in pairs(modmodule) do
    AddPrefabPostInit("wx78module_" .. v, function(inst)
        if inst.components.inventoryitem then
            inst.components.inventoryitem.atlasname = "images/inventoryimages/alice_moudle.xml"
            inst.components.inventoryitem.imagename = v
        end
        
		inst:DoTaskInTime(0, function()
            inst.AnimState:SetBank("alice_moudle")
            inst.AnimState:SetBuild("alice_moudle")
            inst.AnimState:PlayAnimation("alice_moudle" .. k)
		end)
    end)
end

local function OnShieldLoaded(inst, data)
end

local function OnShieldUnloaded(inst, data)
end
