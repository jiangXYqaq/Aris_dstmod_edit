local MakePlayerCharacter = require("prefabs/player_common")
local WX78MoistureMeter = require("widgets/wx78moisturemeter")
local WX78Common = require("prefabs/wx78_common")
local easing = require("easing")

local assets = {
    Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
    Asset( "ANIM", "anim/alice.zip"),
    Asset( "ANIM", "anim/alice_red.zip"),
    Asset( "ANIM", "anim/alice_maid.zip"),
    Asset( "ANIM", "anim/alice_maid_red.zip"),
}

local prefabs =
{
    "cracklehitfx",
    "gears",
    "sparks",
    "wx78_big_spark",
    "wx78_heat_steam",
    "wx78_moduleremover",
    "wx78_musicbox_fx",
    "wx78_scanner_item",
}

local WX78ModuleDefinitionFile = require("wx78_moduledefs")
local GetWX78ModuleByNetID = WX78ModuleDefinitionFile.GetModuleDefinitionFromNetID

local WX78ModuleDefinitions = WX78ModuleDefinitionFile.module_definitions
for mdindex, module_def in ipairs(WX78ModuleDefinitions) do
    table.insert(prefabs, "wx78module_"..module_def.name)
end

-- 初始物品
local start_inv = {
    "alice_battlecoat",
    "alice_lightsword",
    "alice_battery",
}
prefabs = FlattenTree({ prefabs, start_inv }, true)

local CHARGEREGEN_TIMERNAME = "chargeregenupdate"
local MOISTURETRACK_TIMERNAME = "moisturetrackingupdate"
local HUNGERDRAIN_TIMERNAME = "hungerdraintick"
local HEATSTEAM_TIMERNAME = "heatsteam_tick"

local function CLIENT_GetEnergyLevel(inst)
    if inst.components.upgrademoduleowner ~= nil then
        return inst.components.upgrademoduleowner.charge_level
    elseif inst.player_classified ~= nil then
        return inst.player_classified.currentenergylevel:value()
    else
        return 0
    end
end

local function OnForcedNightVisionDirty(inst)
    if inst.components.playervision ~= nil then
        if inst._forced_nightvision:value() or inst.alc_night:value() then
            inst.components.playervision:PushForcedNightVision(inst)
        else
            inst.components.playervision:PopForcedNightVision(inst)
        end
    end
end

-- 夜视
local function SetForcedNightVision(inst, nightvision_on, update)
    inst._forced_nightvision:set(nightvision_on)
    inst.alc_night:set(nightvision_on)

    if inst.components.playervision ~= nil then
        if nightvision_on then
            inst.components.playervision:PushForcedNightVision(inst)
        else
            inst.components.playervision:PopForcedNightVision(inst)
        end
    end
    
    if update then
        return
    end

    if nightvision_on then
        inst.components.grue:AddImmunity("wxnightvisioncircuit")
    else
        inst.components.grue:RemoveImmunity("wxnightvisioncircuit")
    end
end


local function OnPlayerDeactivated(inst)
    inst:RemoveEventCallback("onremove", OnPlayerDeactivated)
    if not TheNet:IsDedicated() then
        inst:RemoveEventCallback("forced_nightvision_dirty", OnForcedNightVisionDirty)
    end
end

local function OnPlayerActivated(inst)
    inst:ListenForEvent("onremove", OnPlayerDeactivated)
    if not TheNet:IsDedicated() then
        inst:ListenForEvent("forced_nightvision_dirty", OnForcedNightVisionDirty)
        OnForcedNightVisionDirty(inst)
    end
end

local function do_chargeregen_update(inst)
    if not inst.components.upgrademoduleowner:ChargeIsMaxed() then
        inst.components.upgrademoduleowner:AddCharge(1)
    end
end

local function OnUpgradeModuleChargeChanged(inst, data)
    -- 每当能量水平变化时，无论是否由再生定时器引起，都会重置再生定时器。
    inst.components.timer:StopTimer(CHARGEREGEN_TIMERNAME)
    if not inst.components.upgrademoduleowner:ChargeIsMaxed() then
        inst.components.timer:StartTimer(CHARGEREGEN_TIMERNAME, TUNING.WX78_CHARGE_REGENTIME)
        -- 如果我们刚刚从非0值降到0，请告诉玩家。
        if data.old_level ~= 0 and data.new_level == 0 then
            inst.components.talker:Say(GetString(inst, "ANNOUNCE_DISCHARGE"))
        end
    else
        -- 如果我们的充能已满（这是一个赋值后的回调），而我们之前的充能不是满的，
        -- 我们刚刚达到最大值，因此告诉玩家。
        if data.old_level ~= inst.components.upgrademoduleowner.max_charge then
            inst.components.talker:Say(GetString(inst, "ANNOUNCE_CHARGE"))
        end
    end
end

local function onbecamehuman(inst)
	inst.components.locomotor:SetExternalSpeedMultiplier(inst, "alice_speed", 1.25)
	if inst.als_ring == nil then
		inst.als_ring=SpawnPrefab("alice_ring_light")
		inst.als_ring.entity:SetParent(inst.entity)
	end
end

local function onbecameghost(inst)
	inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "alice_speed")
	if inst.als_ring ~= nil then
		inst.als_ring:Remove()
		inst.als_ring = nil
	end
end

local function onknockedout(inst)
	if inst.als_ring then
		inst.als_ring.Light:Enable(false)
	end
	inst.AnimState:Hide("HAIR")
	inst.AnimState:Hide("HAIR_NOHAT")
end

local function oncometo(inst)
	if inst.als_ring then
		inst.als_ring.Light:Enable(true)
	end
	inst.AnimState:Show("HAIR")
	inst.AnimState:Show("HAIR_NOHAT")
end

local function onsanitydelta(inst, data)
    if not data then
        return
    end
    --阻止在精神值为0时光环关闭
	--[[ if inst.als_ring then
        inst.als_ring.Light:Enable(data.newpercent > 0 and true or false)
	end ]]
    local oldskin = inst.components.skinner.skin_name
    local newskin = ""
    if data.newpercent > 0.5 then
        newskin = inst.is_maid and "alice_maid" or "alice"
        if inst.components.grue ~= nil then
			inst.components.grue:RemoveImmunity("alice_red")
		end
    else
        newskin = inst.is_maid and "alice_maid_red" or "alice_red"
        if inst.components.grue ~= nil then
			inst.components.grue:AddImmunity("alice_red")
		end
    end
    --print(oldskin, newskin)
    if oldskin ~= newskin then
		inst.AnimState:ClearOverrideBuild(oldskin)
        inst.components.skinner:SetSkinName(newskin)
        inst.AnimState:AddOverrideBuild(newskin)
        inst:PushEvent("alice_update_state")
    end
end

local function OnLoad(inst, data)
    inst:ListenForEvent("ms_respawnedfromghost", onbecamehuman)
    inst:ListenForEvent("ms_becameghost", onbecameghost)

    if inst:HasTag("playerghost") then
        onbecameghost(inst)
    else
        onbecamehuman(inst)
    end
    if data ~= nil then
        --[[ if data.gears_eaten ~= nil then
            inst._gears_eaten = data.gears_eaten
        end ]]
        --[[ if data.level ~= nil then
            inst._gears_eaten = (inst._gears_eaten or 0) + data.level
        end ]]
        if data._wx78_health then
            inst.components.health:SetCurrentHealth(data._wx78_health)
        end
        if data._wx78_sanity then
            inst.components.sanity.current = data._wx78_sanity
        end
        if data._wx78_hunger then
            inst.components.hunger.current = data._wx78_hunger
        end
    end
end

local function OnSave(inst, data)
    --data.gears_eaten = inst._gears_eaten
    data._wx78_health = inst.components.health.currenthealth
    data._wx78_sanity = inst.components.sanity.current
    data._wx78_hunger = inst.components.hunger.current
end

local function OnLightningStrike(inst)
    if inst.components.health ~= nil and not (inst.components.health:IsDead() or inst.components.health:IsInvincible()) then
        if inst.components.inventory:IsInsulated() then
            inst:PushEvent("lightningdamageavoided")
        else
            inst.components.health:DoDelta(TUNING.HEALING_SUPERHUGE, false, "lightning")
            inst.components.sanity:DoDelta(-TUNING.SANITY_LARGE)

            inst.components.upgrademoduleowner:AddCharge(1)
        end
    end
end

local HEATSTEAM_TICKRATE = 5
local function do_steam_fx(inst)
    local steam_fx = SpawnPrefab("wx78_heat_steam")
    steam_fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    steam_fx.Transform:SetRotation(inst.Transform:GetRotation())

    inst.components.timer:StartTimer(HEATSTEAM_TIMERNAME, HEATSTEAM_TICKRATE)
end

local function AddTemperatureModuleLeaning(inst, leaning_change)
    inst._temperature_modulelean = inst._temperature_modulelean + leaning_change

    if inst._temperature_modulelean > 0 then
        inst.components.heater:SetThermics(true, false)
        if not inst.components.timer:TimerExists(HEATSTEAM_TIMERNAME) then
            inst.components.timer:StartTimer(HEATSTEAM_TIMERNAME, HEATSTEAM_TICKRATE, false, 0.5)
        end
        inst.components.frostybreather:ForceBreathOff()
    elseif inst._temperature_modulelean == 0 then
        inst.components.heater:SetThermics(false, false)
        inst.components.timer:StopTimer(HEATSTEAM_TIMERNAME)
        inst.components.frostybreather:ForceBreathOff()
    else
        inst.components.heater:SetThermics(false, true)
        inst.components.timer:StopTimer(HEATSTEAM_TIMERNAME)
        inst.components.frostybreather:ForceBreathOn()
    end
end

local function initiate_moisture_update(inst)
    if not inst.components.timer:TimerExists(MOISTURETRACK_TIMERNAME) then
        inst.components.timer:StartTimer(MOISTURETRACK_TIMERNAME, TUNING.WX78_MOISTUREUPDATERATE*FRAMES)
    end
end

local function stop_moisturetracking(inst)
    inst.components.timer:StopTimer(MOISTURETRACK_TIMERNAME)
    inst._moisture_steps = 0
end

local function moisturetrack_update(inst)
    local current_moisture = inst.components.moisture:GetMoisture()
    if current_moisture > TUNING.WX78_MINACCEPTABLEMOISTURE then
        -- 更新将持续循环，直到湿度降至可接受水平以下。
        initiate_moisture_update(inst)
    end
    if inst.components.moisture:IsForceDry() then
        return
    end
    inst._moisture_steps = inst._moisture_steps + 1

    local x, y, z = inst.Transform:GetWorldPosition()
    SpawnPrefab("sparks").Transform:SetPosition(x, y + 1 + math.random() * 1.5, z)

    if inst._moisture_steps >= TUNING.WX78_MOISTURESTEPTRIGGER then
        local damage_per_second = easing.inSine(
                current_moisture - TUNING.WX78_MINACCEPTABLEMOISTURE,
                TUNING.WX78_MIN_MOISTURE_DAMAGE,
                TUNING.WX78_PERCENT_MOISTURE_DAMAGE,
                inst.components.moisture:GetMaxMoisture() - TUNING.WX78_MINACCEPTABLEMOISTURE
        )
        local seconds_per_update = TUNING.WX78_MOISTUREUPDATERATE / 30

        inst.components.health:DoDelta(inst._moisture_steps * seconds_per_update * damage_per_second, false, "water")
        inst.components.upgrademoduleowner:AddCharge(-1)
        inst._moisture_steps = 0

        SpawnPrefab("wx78_big_spark"):AlignToTarget(inst)
        inst.sg:GoToState("hit")
    end
    -- 发送一个消息给用户界面。
    inst:PushEvent("do_robot_spark")
    if inst.player_classified ~= nil then
        inst.player_classified.uirobotsparksevent:push()
    end
end

-- 监听雨露值
local function OnWetnessChanged(inst, data)
    if not (inst.components.health ~= nil and inst.components.health:IsDead()) then
        if data.new >= TUNING.WX78_COLD_ICEMOISTURE and inst.components.upgrademoduleowner:GetModuleTypeCount("cold") > 0 then
            inst.components.moisture:SetMoistureLevel(0)

            local x, y, z = inst.Transform:GetWorldPosition()
            for i = 1, TUNING.WX78_COLD_ICECOUNT do
                local ice = SpawnPrefab("ice")
                ice.Transform:SetPosition(x, y, z)
                Launch(ice, inst)
            end

            stop_moisturetracking(inst)
        elseif data.new > TUNING.WX78_MINACCEPTABLEMOISTURE and data.old <= TUNING.WX78_MINACCEPTABLEMOISTURE then
            initiate_moisture_update(inst)
        elseif data.new <= TUNING.WX78_MINACCEPTABLEMOISTURE and data.old > TUNING.WX78_MINACCEPTABLEMOISTURE then
            stop_moisturetracking(inst)
        end
    end
end

local function OnBecameRobot(inst)
    inst.Light:Enable(false)
    inst.Light:SetRadius(2)
    inst.Light:SetFalloff(0.75)
    inst.Light:SetIntensity(.9)
    inst.Light:SetColour(235 / 255, 121 / 255, 12 / 255)

    if not inst.components.upgrademoduleowner:ChargeIsMaxed() then
        inst.components.timer:StartTimer(CHARGEREGEN_TIMERNAME, TUNING.WX78_CHARGE_REGENTIME)
    end
end

local function OnBecameGhost(inst)
    stop_moisturetracking(inst)
    inst.components.timer:StopTimer(HUNGERDRAIN_TIMERNAME)
    inst.components.timer:StopTimer(CHARGEREGEN_TIMERNAME)
end

local function OnDeath(inst)
    inst.components.upgrademoduleowner:PopAllModules()
    inst.components.upgrademoduleowner:SetChargeLevel(0)

    stop_moisturetracking(inst)
    inst.components.timer:StopTimer(HUNGERDRAIN_TIMERNAME)
    inst.components.timer:StopTimer(CHARGEREGEN_TIMERNAME)

end

local function OnEat(inst, food)
    if food ~= nil and food.components.edible ~= nil then
        --[[ if food.components.edible.foodtype == FOODTYPE.GEARS then
            inst._gears_eaten = inst._gears_eaten + 1

            inst.SoundEmitter:PlaySound("dontstarve/characters/wx78/levelup")
        end ]]
    end

    local charge_amount = TUNING.WX78_CHARGING_FOODS[food.prefab]
    if charge_amount ~= nil then
        inst.components.upgrademoduleowner:AddCharge(charge_amount)
    end
end

-- 被冰冻回调函数
local function OnFrozen(inst)
    if inst.components.freezable == nil or not inst.components.freezable:IsFrozen() then
        SpawnPrefab("wx78_big_spark"):AlignToTarget(inst)

        if not inst.components.upgrademoduleowner:IsChargeEmpty() then
            inst.components.upgrademoduleowner:AddCharge(-TUNING.WX78_FROZEN_CHARGELOSS)
        end
    end
end

-- 插入芯片时的回调
local function OnUpgradeModuleAdded(inst, moduleent)
    local moduletype = moduleent.components.upgrademodule:GetType()

    inst:PushEvent("upgrademodulesdirty", inst:GetModulesData())
    if inst.wx78_classified ~= nil then
        local newmodule_index = inst.components.upgrademoduleowner:GetNumModules(moduletype)
        inst.wx78_classified.upgrademodulebars[moduletype][newmodule_index]:set(moduleent._netid or 0)
    end
end

-- 移除芯片时的回调（原版处理耐久度逻辑）
local function OnUpgradeModuleRemoved(inst, moduleent)
    if moduleent.components.finiteuses == nil or moduleent.components.finiteuses:GetUses() > 0.5 then
        if not inst.components.upgrademoduleowner:IsSwapping() and moduleent.components.inventoryitem ~= nil and inst.components.inventory ~= nil then
            local pos = not inst.components.health:IsDead() and inst:GetPosition() or nil
            inst.components.inventory:GiveItem(moduleent, nil, pos)
        end
    end
end

-- 弹出芯片时的回调（扣除电量）
local function OnOneUpgradeModulePopped(inst, moduleent, was_activated)
    local moduletype = moduleent.components.upgrademodule:GetType()
    local moduleslotcount = moduleent.components.upgrademodule:GetSlots()
    if was_activated then
        local charge_cost = -moduleslotcount
        local skilltreeupdater = inst.components.skilltreeupdater
        if skilltreeupdater and skilltreeupdater:IsActivated("wx78_circuitry_bettercharge") then
            charge_cost = math.min(charge_cost + TUNING.SKILLS.WX78.SAVE_CHARGE_ON_UNPLUG, -1)
        end
        inst.components.upgrademoduleowner:DoDeltaCharge(charge_cost)
    end

    inst:PushEvent("upgrademodulesdirty", inst:GetModulesData())
    if inst.wx78_classified ~= nil then
        for i, netvar in ipairs(inst.wx78_classified.upgrademodulebars[moduletype]) do
            local module = inst.components.upgrademoduleowner:GetModule(moduletype, i)
            netvar:set(module ~= nil and module._netid or 0)
        end
    end
end

-- 全部弹出时的回调
local function OnAllUpgradeModulesRemoved(inst)
    SpawnPrefab("wx78_big_spark"):AlignToTarget(inst)
    inst:PushEvent("upgrademoduleowner_popallmodules")

    if inst.wx78_classified ~= nil then
        for i, modules in pairs(inst.wx78_classified.upgrademodulebars) do
            for j, netvar in ipairs(modules) do
                netvar:set(0)
            end
        end
    end
end

-- 检查是否有足够电量插入
local function CanUseUpgradeModule(inst, moduleent)
    local moduletype = moduleent.components.upgrademodule:GetType()
    local slots_in_use = inst.components.upgrademoduleowner:GetUsedSlotCount(moduletype)
    local max_charge = inst.components.upgrademoduleowner:GetMaxChargeLevel()
    if max_charge - slots_in_use < moduleent.components.upgrademodule:GetSlots() then
        return false, "NOTENOUGHSLOTS"
    else
        return true
    end
end

local function OnChargeFromBattery(inst, battery)
    if inst.components.upgrademoduleowner:ChargeIsMaxed() then
        return false, "CHARGE_FULL"
    end

    inst.components.health:DoDelta(TUNING.HEALING_SMALL, false, "lightning")
    inst.components.sanity:DoDelta(-TUNING.SANITY_SMALL)

    inst.components.upgrademoduleowner:AddCharge(1)

    if not inst.components.inventory:IsInsulated() then
        inst.sg:GoToState("electrocute")
    end

    return true
end

local function ModuleBasedPreserverRateFn(inst, item)
    return (inst._temperature_modulelean > 0 and TUNING.WX78_PERISH_HOTRATE)
        or (inst._temperature_modulelean < 0 and TUNING.WX78_PERISH_COLDRATE)
        or 1
end

local function GetThermicTemperatureFn(inst, observer)
    return inst._temperature_modulelean * TUNING.WX78_HEATERTEMPPERMODULE
end

-- 睡觉时检测是否插入发光芯片
local function CanSleepInBagFn(wx, bed)
    if wx._light_modules == nil or wx._light_modules == 0 then
        return true
    else
        return false, "ANNOUNCE_NOSLEEPHASPERMANENTLIGHT"
    end
end

local function OnStartStarving(inst)
    inst.components.timer:StartTimer(HUNGERDRAIN_TIMERNAME, TUNING.WX78_HUNGRYCHARGEDRAIN_TICKTIME)
end

local function OnStopStarving(inst)
    inst.components.timer:StopTimer(HUNGERDRAIN_TIMERNAME)
end

local function on_hunger_drain_tick(inst)
    if inst.components.health ~= nil and not (inst.components.health:IsDead() or inst.components.health:IsInvincible()) then
        inst.components.upgrademoduleowner:AddCharge(-1)

        SpawnPrefab("wx78_big_spark"):AlignToTarget(inst)

        inst.sg:GoToState("hit")
    end
    inst.components.timer:StartTimer(HUNGERDRAIN_TIMERNAME, TUNING.WX78_HUNGRYCHARGEDRAIN_TICKTIME)
end

-- 暴击
local function GetCritical(inst)
    local base = inst.alc_baojilv
    local buff = (inst.light_buff or 0) * 0.2--有改动原0.15
    local equip = 0

    local damage = inst.alc_baojizhi
    for k, v in pairs(inst.components.inventory.equipslots) do
        if v.components.alice_critical then
            local v1 = v.components.alice_critical:Getvalue()
            local v2 = v.components.alice_critical:Getchance()
            damage = damage + v1
            equip = equip + v2
        end
    end
    --新增溢出暴击率转暴击伤害
	local total_crit_chance = base + buff + equip
	local overflow = math.max(total_crit_chance - 1, 0)
	local crit_chance = math.min(total_crit_chance, 1)
    local extra_crit_damage = TUNING.ALICE_LIGHTSWORD_DAMAGE_RATE or 1
	damage = damage + overflow * extra_crit_damage * 3
    --print("暴击概率：", base + buff + equip, "暴击数值：", damage)
    return crit_chance, damage
end

local function customdamagemult(inst)
    if inst.replica.rider:IsRiding() then  -- 更直接的骑乘检查
        return 1
    end
    local chance, damage = GetCritical(inst)
    return math.random() < chance and damage or 1
end

--引用的wx78 prefab方法
local function COMMON_GetShieldPenetrationThreshold(inst)
    if inst.components.wx78_shield ~= nil then
        return inst.components.wx78_shield:GetPenetrationThreshold()
    elseif inst.wx78_classified ~= nil then
        return inst.wx78_classified.shieldpenetrationthreshold:value()
    else
        return 15
    end
end

local function COMMON_GetCurrentShield(inst)
    if inst.components.wx78_shield ~= nil then
        return inst.components.wx78_shield:GetCurrent()
    elseif inst.wx78_classified ~= nil then
        return inst.wx78_classified.currentshield:value()
    else
        return 0
    end
end

local function COMMON_GetMaxShield(inst)
    if inst.components.wx78_shield ~= nil then
        return inst.components.wx78_shield:GetMax()
    elseif inst.wx78_classified ~= nil then
        return inst.wx78_classified.maxshield:value()
    else
        return 1
    end
end

local function COMMON_GetCanShieldCharge(inst)
    if inst.components.wx78_shield ~= nil then
        return inst.components.wx78_shield:GetCanShieldCharge()
    elseif inst.wx78_classified ~= nil then
        return inst.wx78_classified.canshieldcharge:value()
    else
        return false
    end
end

local function common_postinit(inst) --客机函数
    inst:AddTag("alice")
    inst:AddTag("electricdamageimmune") -- 免疫闪电伤害
    inst:AddTag("batteryuser")          -- batteryuserz组件
    inst:AddTag("chessfriend")          -- 发条仇恨范围降低一半
    inst:AddTag("HASHEATER")            -- heater组件
    inst:AddTag("soulless")             -- 没有灵魂
    inst:AddTag("upgrademoduleowner")   -- upgrademoduleowner组件
	inst:AddTag("mightiness_mighty")    -- 重物不减速
    inst:AddTag("wx78_shield")          -- from wx78_shield component

    if not TheNet:IsDedicated() then
        inst.CreateMoistureMeter = WX78MoistureMeter
    end

	inst.MiniMapEntity:SetIcon("alice.tex")

    inst._forced_nightvision = net_bool(inst.GUID, "wx78.forced_nightvision", "forced_nightvision_dirty")
    inst:ListenForEvent("playeractivated", OnPlayerActivated)
    inst:ListenForEvent("playerdeactivated", OnPlayerDeactivated)

    inst.AnimState:AddOverrideBuild("wx_upgrade")
    inst.AnimState:AddOverrideBuild("action_remote")
    inst.AnimState:AddOverrideBuild("alice_action")
    inst.AnimState:AddOverrideBuild("alice")

    inst.components.talker.mod_str_fn = string.utf8upper

    --修复无GetMaxEnergy方法
    WX78Common.SetupUpgradeModuleOwnerInstanceFunctions(inst)
    --使用原版新增的技能冷却方法
    inst:AddComponent("wx78_abilitycooldowns")

    -- 挂载护盾查询方法（与wx78 一致）
    inst.GetShieldPenetrationThreshold = COMMON_GetShieldPenetrationThreshold
    inst.GetCurrentShield = COMMON_GetCurrentShield
    inst.GetMaxShield = COMMON_GetMaxShield
    inst.GetCanShieldCharge = COMMON_GetCanShieldCharge
end
----------------光之勇者----------------
--来源于战斗分析模块main\module.lua\@AddNewModuleDefinition(BATTLE_MODULE_DATA)
--进入战斗后每2秒获得光，30秒内没有战斗视为脱战，失去所有光。
local function UpdateBuffAnim(inst)
    if inst.bufffx == nil then
        inst.bufffx = SpawnPrefab("alice_buff")
		inst.bufffx.entity:SetParent(inst.entity)
    end

    local anim = "level" .. inst.light_buff
    if not inst.bufffx.AnimState:IsCurrentAnimation(anim) then
        inst.bufffx.AnimState:PlayAnimation(anim)
    end

    if inst.light_buff <= 0 and inst.bufffx ~= nil then
        inst.bufffx:Remove()
        inst.bufffx = nil
    end
end

local function UpdateLightBuff(inst)
    if inst.alc_atk_state then
        if inst.light_buff < 10 then -- 最多10层BUFF有改动
            inst.light_buff = inst.light_buff + 1
        end
    else
        if inst.light_buff > 0 then
            inst.light_buff = inst.light_buff - 1
        end
    end
    if inst.light_buff == 0 then
        if inst.light_buff_task ~= nil then
            inst.light_buff_task:Cancel()
            inst.light_buff_task = nil
        end
        if inst.light_buff_task2 ~= nil then
            inst.light_buff_task2:Cancel()
            inst.light_buff_task2 = nil
        end
    end
    UpdateBuffAnim(inst)
end
--对窃贼造成200点伤害
local function PunishOffender(inst, offender)
    if offender:IsValid() and offender.components.combat then
        -- 造成200点雷电伤害
        offender.components.combat:GetAttacked(inst, 200, nil, "electric")
    end
end
-- 通用偷窃处理函数（适用于任何实体）
local function OnItemStolen(inst, data)
    if data and data.thief and data.thief:IsValid() then
        PunishOffender(inst, data.thief)  -- 使用统一惩罚函数
    end
end

local function AttackOrAttacked(inst, data)
    if not inst.battle_activate then
        return
    end
    
    if not inst.alc_atk_state then
        inst.alc_atk_state = true
    end
    inst.alc_atk_time = 10

    if inst.light_buff_task == nil then
        inst.light_buff_task = inst:DoPeriodicTask(2, function() -- 增加一次Buff有改动为2s
            UpdateLightBuff(inst)
        end)
    end

    if inst.light_buff_task2 ~= nil then
        inst.light_buff_task2:Cancel()
        inst.light_buff_task2 = nil
    end

    inst.light_buff_task2 = inst:DoTaskInTime(30, function() -- 30s脱离战斗原10S
        inst.alc_atk_state = false
    end)
    --处理被猴子偷的情况
    if data and data.target == inst then  -- 只有自己被攻击时才触发
        if data.attacker and data.attacker:IsValid() then
            local attacker = data.attacker
            local weapon = attacker.components.combat and 
                           attacker.components.combat:GetWeapon()
            
            -- 检查武器是否为cutless
            if weapon and weapon.prefab == "cutless" then
                PunishOffender(inst, attacker)  -- 使用统一惩罚函数
            end
        end
    end
end


local function OnTimerFinished(inst, data)
    if data.name == HUNGERDRAIN_TIMERNAME then
        on_hunger_drain_tick(inst)
    elseif data.name == MOISTURETRACK_TIMERNAME then
        moisturetrack_update(inst)
    elseif data.name == CHARGEREGEN_TIMERNAME then
        do_chargeregen_update(inst)
    elseif data.name == HEATSTEAM_TIMERNAME then
        do_steam_fx(inst)
    end
end

local function RedirectToWxShield(inst, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
	return inst.components.wx78_shield ~= nil and inst.components.wx78_shield:OnTakeDamage(amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
end

--仅服务端执行
----------------主机函数----------------
local function master_postinit(inst)
    -- 初始物品
    inst.starting_inventory = start_inv
    -- 角色声音
	inst.soundsname = "willow" 

    inst.wx78_classified = SpawnPrefab("wx78_classified")
    inst.wx78_classified.entity:SetParent(inst.entity)

    -- 三维
    inst.components.health:SetMaxHealth(TUNING.ALICE_HEALTH)
    inst.components.hunger:SetMax(TUNING.ALICE_HUNGER)
    inst.components.sanity:SetMax(TUNING.ALICE_SANITY)

    --inst._gears_eaten = 0
    inst._chip_inuse = 0
    inst._moisture_steps = 0
    inst._temperature_modulelean = 0        -- 正值表示“高温”，负值表示“低温”；参见 wx78_moduledefs
    inst._num_frostybreath_modules = 0      -- 使模块在冬季或低环境温度之外激活 WX 的寒冷呼吸
    inst.alc_baojilv = TUNING.ALICE_BASIC_CHANCE       -- 暴击率
    inst.alc_baojizhi = TUNING.ALICE_BASIC_VALUE       -- 暴击值
    inst.light_buff = 0                     -- BUFF层数

    if inst.components.eater ~= nil then
        inst.components.eater:SetIgnoresSpoilage(true)
        --inst.components.eater:SetCanEatGears()
        inst.components.eater:SetOnEatFn(OnEat)
    end

    if inst.components.freezable ~= nil then
        inst.components.freezable.onfreezefn = OnFrozen
    end

    -- 芯片
    inst:AddComponent("upgrademoduleowner")
    inst.components.upgrademoduleowner.onmoduleadded = OnUpgradeModuleAdded
    inst.components.upgrademoduleowner.onmoduleremoved = OnUpgradeModuleRemoved
    inst.components.upgrademoduleowner.ononemodulepopped = OnOneUpgradeModulePopped
    inst.components.upgrademoduleowner.onallmodulespopped = OnAllUpgradeModulesRemoved
    inst.components.upgrademoduleowner.canupgradefn = CanUseUpgradeModule
    inst.components.upgrademoduleowner:SetChargeLevel(3)

    inst:ListenForEvent("energylevelupdate", OnUpgradeModuleChargeChanged)

	--携带重物不减速
	inst:AddComponent("mightiness")
	inst.components.mightiness.current = inst.components.mightiness.max
	inst.components.mightiness.state = "mighty"
	inst.components.mightiness.CanTransform = function() return false end
	inst.components.mightiness.GetPercent = function() return 1 end
	inst.components.mightiness.DoDelta = function() end

    inst:AddComponent("dataanalyzer")
    inst.components.dataanalyzer:StartDataRegen(TUNING.SEG_TIME)

    inst:AddComponent("batteryuser")
    inst.components.batteryuser.onbatteryused = OnChargeFromBattery

    inst:AddComponent("wx78_shield")
    inst.components.wx78_shield:SetMax(1)
    inst.components.wx78_shield:SetCurrent(0)
    inst.components.health.deltamodifierfn = RedirectToWxShield

    inst:AddComponent("preserver")
    inst.components.preserver:SetPerishRateMultiplier(ModuleBasedPreserverRateFn)

    -- 芯片的温度调节
    inst:AddComponent("heater")
    inst.components.heater:SetThermics(false, false)
    inst.components.heater.heatfn = GetThermicTemperatureFn 

	inst.components.combat.customdamagemultfn = customdamagemult

    inst.components.foodaffinity:AddPrefabAffinity("butterflymuffin", TUNING.AFFINITY_15_CALORIES_LARGE)

    inst.components.sleepingbaguser:SetCanSleepFn(CanSleepInBagFn)

    --自定义的组件，在装备暗影防护板对抗天体阵营时生效
    inst:AddComponent("alice_shadow_embrace")

    -- 延迟初始化以确保所有组件就绪
    inst:DoTaskInTime(0, function()
        if inst.components.alice_shadow_embrace then
            inst.components.alice_shadow_embrace:SetupListeners()
            print("[AliceShadowEmbrace] Listeners set up")
        else
            print("[ERROR] AliceShadowEmbrace component missing")
        end
    end)

    -- 移除滑倒组件，防止在任何冰面上滑倒
    if inst.components.slipperyfeet then
        inst:RemoveComponent("slipperyfeet")
    end
    -- 睡觉时光环熄灭
    local oldDoSleep = inst.components.sleepingbaguser.DoSleep
    inst.components.sleepingbaguser.DoSleep = function(self, ...)
        inst.AnimState:Hide("HAIR")
        inst.AnimState:Hide("HAIR_NOHAT")
        if inst.als_ring then
            inst.als_ring.Light:Enable(false)
        end
        if oldDoSleep then
            oldDoSleep(self, ...)
        end
    end

    local oldDoWakeUp = inst.components.sleepingbaguser.DoWakeUp
    inst.components.sleepingbaguser.DoWakeUp = function(self, ...)
        inst.AnimState:Show("HAIR")
        inst.AnimState:Show("HAIR_NOHAT")
        if inst.als_ring then
            inst.als_ring.Light:Enable(true)
        end
        if oldDoWakeUp then
            oldDoWakeUp(self, ...)
        end
    end

    -- 护盾免伤 此处是关于骨甲护盾的缓冲机制，不是wx78的护盾
    local old_get_attacked = inst.components.combat.GetAttacked
    inst.components.combat.GetAttacked = function(self, ...)
        if self.inst and self.inst.light_buff and self.inst.light_buff >= 1 then --改为1层，原2层
            local fx = SpawnPrefab("shadow_shield1")
            fx.entity:SetParent(self.inst.entity)
            self.inst.light_buff = self.inst.light_buff - 1
            UpdateBuffAnim(inst)
            return false
        end
        return old_get_attacked(self, ...)
    end

    -- 事件监听
    inst:ListenForEvent("ms_respawnedfromghost", OnBecameRobot)
    inst:ListenForEvent("ms_becameghost", OnBecameGhost)
    inst:ListenForEvent("death", OnDeath)
    inst:ListenForEvent("ms_playerreroll", OnDeath)
    inst:ListenForEvent("moisturedelta", OnWetnessChanged)
    inst:ListenForEvent("startstarving", OnStartStarving)
    inst:ListenForEvent("stopstarving", OnStopStarving)
    inst:ListenForEvent("timerdone", OnTimerFinished)
	inst:ListenForEvent("knockedout",onknockedout)
	inst:ListenForEvent("cometo",oncometo)
	inst:ListenForEvent("sanitydelta",onsanitydelta)

    inst:ListenForEvent("onhitother", AttackOrAttacked)
    inst:ListenForEvent("attacked", AttackOrAttacked)
    inst:ListenForEvent("lightswordshot", AttackOrAttacked)
    inst:ListenForEvent("onitemstolen", OnItemStolen)

    inst.components.playerlightningtarget:SetHitChance(TUNING.WX78_LIGHTNING_TARGET_CHANCE)
    inst.components.playerlightningtarget:SetOnStrikeFn(OnLightningStrike)

    OnBecameRobot(inst)
    
	inst.als_ring = SpawnPrefab("alice_ring_light")
	inst.als_ring.entity:SetParent(inst.entity)

    inst.AddTemperatureModuleLeaning = AddTemperatureModuleLeaning
    inst.SetForcedNightVision = SetForcedNightVision

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
end

return MakePlayerCharacter("alice", prefabs, assets, common_postinit, master_postinit)