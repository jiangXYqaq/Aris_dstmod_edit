GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})
local wx78_moduledefs = require("wx78_moduledefs")
local module_definitions = wx78_moduledefs.module_definitions
local AddCreatureScanDataDefinition = wx78_moduledefs.AddCreatureScanDataDefinition
local GetModuleDefinitionFromNetID = wx78_moduledefs.GetModuleDefinitionFromNetID
local AddNewModuleDefinition = wx78_moduledefs.AddNewModuleDefinition
local getprefab = require("alice_utils/getprefab")

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

-- 修改 magic_activate 函数签名，增加 isloading 参数
local function magic_activate(inst, wx, isloading)
    -- 暴击相关（原有）
    if wx.alc_baojilv then
        wx.alc_baojilv = wx.alc_baojilv + TUNING.ALICE_MAGIC_CHANCE
    end
    if wx.alc_baojizhi then
        wx.alc_baojizhi = wx.alc_baojizhi + TUNING.ALICE_MAGIC_VALUE
    end

    -- 三维提升（原有）
    maxhealth_change(inst, wx, TUNING.MAGIC_MAXHEALTH_BOOST, isloading)
    maxhunger_change(inst, wx, TUNING.MAGIC_MAXHUNGER_BOOST, isloading)
    maxsanity_change(inst, wx, TUNING.MAGIC_MAXSANITY_BOOST, isloading)

    -- 饥饿燃烧减慢（原有）
    if wx.components.hunger and wx.components.hunger.burnratemodifiers then
        wx.components.hunger.burnratemodifiers:SetModifier(inst, TUNING.MAGIC_HUNGER_BURN_SLOW_PERCENT)
    end

    -- 自动回复任务（原有，但需修改 magic_tick 函数）
    if not wx._magic_tick_task then
        wx._magic_tick_task = wx:DoPeriodicTask(TUNING.MAGIC_REGEN_INTERVAL, magic_tick, nil, wx)
    end

    -- 温度舒适范围（原有）
    if wx.components.temperature then
        record_original_temps(wx)
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
        restore_original_temps(wx)
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
--加快了充电速度
local function charge_activate(inst, wx)
    inst:AddTag("FX")
    inst:AddTag("CLASSIFIED")
    getprefab.Hide(inst)
    if inst.chargetask ~= nil then
        inst.chargetask:Cancel()
        inst.chargetask = nil
    end

    inst.chargetask = inst:DoPeriodicTask(3, function()
        local batterys = inst.components.container:GetAllItems()
        for k, v in ipairs(batterys) do -- 遍历容器
            if v:HasTag("alice_battery") and v.components.finiteuses then
                local use = v.components.finiteuses:GetUses() + 10
                use = math.min(1000, use)
                v.components.finiteuses:SetUses(use)
            end

            if v:HasTag("alice_remote") and v.components.fueled then
                local use = v.components.fueled:GetPercent() + 0.1
                use = math.min(1, use) 
                v.components.fueled:SetPercent(use)
            end
        end
    end)
end

local function charge_deactivate(inst, wx)
    if inst.chargetask ~= nil then
        inst.chargetask:Cancel()
        inst.chargetask = nil
    end

    inst:DoTaskInTime(0, function()
        if wx and wx.components.freezable and wx.components.freezable:IsFrozen() then
            return
        end

        inst:RemoveTag("FX")
        inst:RemoveTag("CLASSIFIED")
        getprefab.Show(inst)
        if inst.components.container ~= nil then
            inst.components.container:Open(wx)
        end
    end)
end

local CHARGE_MODULE_DATA =
{
    name = "alc_charge",
    slots = 1,
    type = CIRCUIT_BARS.BETA,    -- 贝塔
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

                -- 为 alc_charge 添加按钮（按线路分组存储）
                if modname == "alc_charge" then
                    self.chipbutton = self.chipbutton or {}
                    self.chipbutton[bartype] = self.chipbutton[bartype] or {}
                    if self.chipbutton[bartype][idx] == nil then
                        local btn = new_chip:AddChild(ImageButton("images/ui/select.xml", "select.tex"))
                        btn:SetScale(.5, .5, .5)
                        btn:SetPosition(-80, 0, 0)
                        btn:SetOnClick(function()
                            SendModRPCToServer(MOD_RPC["alice"]["alic_charge"], idx)
                            btn:OnSelect()
                        end)
                        self.chipbutton[bartype][idx] = btn
                    end
                end
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

AddPrefabPostInit("wx78module_alc_charge", function(inst)
    if not TheWorld.ismastersim then
        return inst
    end
    
    inst:AddComponent("container")
    inst.components.container:WidgetSetup("wx78module_alc_charge")
	inst.components.container.canbeopened = true
    inst.components.container.stay_open_on_hide = true
    inst:ListenForEvent("itemget", OnShieldLoaded)
    inst:ListenForEvent("itemlose", OnShieldUnloaded)


    local olfn = inst.components.finiteuses.onfinished
    inst.components.finiteuses.onfinished = function(self, fn, ...)
        for k = 1, 2 do
            inst.components.container:DropItemBySlot(k)
        end
        if olfn then
            olfn(self, fn, ...)
        end
    end
end)