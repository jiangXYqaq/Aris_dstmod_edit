local assets=
{ 
	Asset("ANIM", "anim/alice_coat.zip"), 
	Asset("ANIM", "anim/alice_battlecoat.zip"), 
    Asset("ATLAS", "images/inventoryimages/alice_coat.xml"),
    Asset("ATLAS", "images/inventoryimages/alice_maidcoat.xml"),
}

--local getprefab = require("alice_utils/getprefab")

local prefabs = {}

local SHIELD_DURATION = 10 * FRAMES
local SHIELD_VARIATIONS = 3
local MAIN_SHIELD_CD = 1.2

local RESISTANCES =
{
    "_combat",
    "explosive",
    "quakedebris",
    "lunarhaildebris",
    "caveindebris",
    "trapdamage",
}

local function OnTakeDamage(inst, amount)
    local item = inst.components.container:GetItemInSlot(1)
    if item then
        item.components.finiteuses:Use(amount)
    end
    if inst.bramble then
        local owner = inst.components.inventoryitem and inst.components.inventoryitem.owner or nil
        SpawnPrefab("bramblefx_armor"):SetFXOwner(owner)
    end
end

local function PickShield(inst)
    local t = GetTime()
    local flipoffset = math.random() < .5 and SHIELD_VARIATIONS or 0

    --variation 3 is the main shield
    local dt = t - inst.lastmainshield
    if dt >= MAIN_SHIELD_CD then
        inst.lastmainshield = t
        return flipoffset + 3
    end

    local rnd = math.random()
    if rnd < dt / MAIN_SHIELD_CD then
        inst.lastmainshield = t
        return flipoffset + 3
    end

    return flipoffset + (rnd < dt / (MAIN_SHIELD_CD * 2) + .5 and 2 or 1)
end

local function OnShieldOver(inst, OnResistDamage)
    inst.task = nil
    for i, v in ipairs(RESISTANCES) do
        inst.components.resistance:RemoveResistance(v)
    end
    inst.components.resistance:SetOnResistDamageFn(OnResistDamage)
end

local function OnResistDamage(inst)--, damage)
    local owner = inst.components.inventoryitem:GetGrandOwner() or inst
    local fx = SpawnPrefab("shadow_shield"..tostring(PickShield(inst)))
    fx.entity:SetParent(owner.entity)

    if inst.task ~= nil then
        inst.task:Cancel()
    end
    inst.task = inst:DoTaskInTime(SHIELD_DURATION, OnShieldOver, OnResistDamage)
    inst.components.resistance:SetOnResistDamageFn(nil)

    local slotitem = inst.components.container:GetItemInSlot(1)
    if slotitem then
        slotitem.components.finiteuses:Use(1)
    end
        
    if inst.components.cooldown.onchargedfn ~= nil then
        inst.components.cooldown:StartCharging()
    end
end

local function ShouldResistFn(inst) -- 判断是否应该触发无敌
    if not (inst.components.equippable:IsEquipped() or inst.shield) then
        return false
    end
    local owner = inst.components.inventoryitem.owner
    return owner ~= nil and not (owner.components.inventory ~= nil and owner.components.inventory:EquipHasTag("forcefield"))  -- 优先级低于铥头立场
end

local function OnChargedFn(inst)
    if inst.task ~= nil then
        inst.task:Cancel()
        inst.task = nil
        inst.components.resistance:SetOnResistDamageFn(OnResistDamage)
    end
    for i, v in ipairs(RESISTANCES) do
        inst.components.resistance:AddResistance(v)
    end
end

local function CLIENT_PlayFuelSound(inst)
	local parent = inst.entity:GetParent()
	local container = parent ~= nil and (parent.replica.inventory or parent.replica.container) or nil
	if container ~= nil and container:IsOpenedBy(ThePlayer) then
		TheFocalPoint.SoundEmitter:PlaySound("dontstarve/common/nightmareAddFuel")
	end
end

local function SERVER_PlayFuelSound(inst)
	local owner = inst.components.inventoryitem.owner
	if owner == nil then
		inst.SoundEmitter:PlaySound("dontstarve/common/nightmareAddFuel")
	elseif inst.components.equippable:IsEquipped() and owner.SoundEmitter ~= nil then
		owner.SoundEmitter:PlaySound("dontstarve/common/nightmareAddFuel")
	else
		inst.playfuelsound:push()
		if not TheNet:IsDedicated() then
			CLIENT_PlayFuelSound(inst)
		end
	end
end

local function UpdateInsulationMode(inst)--改为冬暖夏凉，240点。
    local current_temp = TheWorld.state.temperature
    if current_temp <= 20 then  -- 寒冷模式
        inst.components.insulator:SetWinter()
    else  -- 酷热模式
        inst.components.insulator:SetSummer()
    end
end

local function onunequip(inst, owner)
    if inst.components.container ~= nil then
        inst.components.container:Close()
    end
    
    if inst.components.fueled ~= nil then
        inst.components.fueled:StopConsuming()
    end
	
	-- 新增：卸下时停止检测并重置
    if inst.UpdateInsulationTask ~= nil then
        inst.UpdateInsulationTask:Cancel()
        inst.UpdateInsulationTask = nil
    end
    
    if owner:HasTag("alice") then
        owner.AnimState:ClearOverrideSymbol("arm_lower")
        owner.AnimState:ClearOverrideSymbol("arm_upper")
        owner.AnimState:ClearOverrideSymbol("arm_upper_skin")
        owner.AnimState:ClearOverrideSymbol("torso")
        if inst.setSkin then
            inst:RemoveEventCallback("alice_update_state", inst.setSkin, owner)
            inst.setSkin = nil
        end
    end
end

local function onequip(inst, owner)
    if inst.components.container ~= nil then
        inst.components.container:Open(owner)
    end 
    
    if inst.components.fueled ~= nil then
        inst.components.fueled:StartConsuming()
    end
    -- 新增：装备时激活温度检测
    if inst.UpdateInsulationTask == nil then
        inst.UpdateInsulationTask = inst:DoPeriodicTask(2, function()
            UpdateInsulationMode(inst)
        end)
    end
    UpdateInsulationMode(inst)  -- 立即生效
	
    if owner:HasTag("alice") then
        if inst.setSkin == nil then
            inst.setSkin = function(owner)
                owner.AnimState:OverrideSymbol("arm_lower", "alice_battlecoat", "arm_lower")
                owner.AnimState:OverrideSymbol("arm_upper", "alice_battlecoat", "arm_upper")
                owner.AnimState:OverrideSymbol("arm_upper_skin", "alice_battlecoat", "arm_upper_skin")
                owner.AnimState:OverrideSymbol("torso", "alice_battlecoat", "torso")
            end
            inst.setSkin(owner)
            inst:ListenForEvent("alice_update_state", inst.setSkin, owner)
        end
    end
end

local function onunequip_maid(inst, owner)
	-- 新增：卸下时停止检测并重置
    if inst.UpdateInsulationTask ~= nil then
        inst.UpdateInsulationTask:Cancel()
        inst.UpdateInsulationTask = nil
    end
	
    if owner:HasTag("alice") and owner.components.sanity then
        local oldskin = owner.components.skinner.skin_name
        local sanity = owner.components.sanity:GetPercent()
        local newskin = sanity > .5 and "alice" or "alice_red"
        
		owner.AnimState:ClearOverrideBuild(oldskin)
        owner.components.skinner:SetSkinName(newskin)
        owner.AnimState:AddOverrideBuild(newskin)
        owner.is_maid = false
    end
    owner.planarbouns = 0
end

local function onequip_maid(inst, owner)
	-- 新增：装备时激活温度检测
    if inst.UpdateInsulationTask == nil then
        inst.UpdateInsulationTask = inst:DoPeriodicTask(2, function()
            UpdateInsulationMode(inst)
        end)
    end
    UpdateInsulationMode(inst)  -- 立即生效
	
    if owner:HasTag("alice") and owner.components.sanity then
        local oldskin = owner.components.skinner.skin_name
        local sanity = owner.components.sanity:GetPercent()
        local newskin = sanity > .5 and "alice_maid" or "alice_red_maid"
        
		owner.AnimState:ClearOverrideBuild(oldskin)
        owner.components.skinner:SetSkinName(newskin)
        owner.AnimState:AddOverrideBuild(newskin)
        owner.is_maid = true
    end
    owner.planarbouns = 20
end

local function OnShieldLoaded(inst, data)
    if data and data.item then
        inst.components.armor:InitIndestructible(data.item.abs_percent)
        if data.item.planar then
            inst.components.planardefense:SetBaseDefense(data.item.planar)
        end

        if data.item.bramble then
            inst.bramble = true
        end

        if data.item.shield then
            inst.shield = true
            inst.components.cooldown.onchargedfn = OnChargedFn
            inst.lastmainshield = 0
            inst.components.cooldown:StartCharging(math.max(TUNING.ARMOR_SKELETON_FIRST_COOLDOWN, inst.components.cooldown:GetTimeToCharged()))
        end

        if data.item.prefab == "dread_shield" then
            if data.item.restoretask ~= nil then -- should not happen
                data.item.restoretask:Cancel()
                data.item.restoretask = nil
            end

            if data.item.restoretask == nil then
                data.item.restoretask = data.item:DoPeriodicTask(1,function()
                    local owner = inst.components.inventoryitem and inst.components.inventoryitem.owner or nil
                    if owner and owner.components.sanity then
                        local old = data.item.components.finiteuses:GetUses()
                        local max = data.item.components.finiteuses.total
                        local sanity = owner.components.sanity:GetPercent()
                        local new = old + max / (900 + 600 * sanity)
                        new = math.min(new, max)
                        --print(old, new)
                        data.item.components.finiteuses:SetUses(new)
                    end
                end)
            end
        end
    end
end

local function OnShieldUnloaded(inst, data)
    if data.item and data.item.restoretask ~= nil then
        data.item.restoretask:Cancel()
        data.item.restoretask = nil
    end

    inst.components.armor:InitIndestructible(0)
    inst.components.planardefense:SetBaseDefense(0)
    inst.bramble = false
    inst.shield = false
    
    inst.components.cooldown.onchargedfn = nil
    if inst.task ~= nil then
        inst.task:Cancel()
        inst.task = nil
        inst.components.resistance:SetOnResistDamageFn(OnResistDamage)
    end

    for i, v in ipairs(RESISTANCES) do
        inst.components.resistance:RemoveResistance(v)
    end
end

local function nofuel(inst)
    inst:RemoveComponent("armor")
end

local function TakeFuelFn(inst)
    if not inst.components.armor then
        inst:AddComponent("armor")
        inst.components.armor:InitIndestructible(0)
        inst.components.armor.ontakedamage = OnTakeDamage
    end
end

local function common()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("alice_coat")
    inst.AnimState:SetBuild("alice_coat")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("waterproofer")
    inst:AddTag("alice_coat")
    inst:AddTag("hide_percentage")

    inst.foleysound = "dontstarve/movement/foley/bone"

	inst.playfuelsound = net_event(inst.GUID, "armorskeleton.playfuelsound")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
		inst:DoTaskInTime(0, inst.ListenForEvent, "armorskeleton.playfuelsound", CLIENT_PlayFuelSound)
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(1)
    
    inst:AddComponent("resistance")
    inst.components.resistance:SetShouldResistFn(ShouldResistFn)
    inst.components.resistance:SetOnResistDamageFn(OnResistDamage)
    
    inst:AddComponent("cooldown")
    inst.components.cooldown.cooldown_duration = TUNING.ARMOR_SKELETON_COOLDOWN

    inst:AddComponent("armor")
    inst.components.armor:InitIndestructible(0)
	inst.components.armor.ontakedamage = OnTakeDamage
	inst.components.armor.keeponfinished = true
	--getprefab.RemoveEventCallback(inst, "percentusedchange")

	inst:AddComponent("planardefense")
	inst.components.planardefense:SetBaseDefense(0)

    inst:AddComponent("insulator")
    inst.components.insulator:SetInsulation(TUNING.INSULATION_LARGE)

    inst:AddComponent("container")
	inst.components.container.canbeopened = true
    inst.components.container.stay_open_on_hide = true
    inst:ListenForEvent("itemget", OnShieldLoaded)
    inst:ListenForEvent("itemlose", OnShieldUnloaded)

    MakeHauntableLaunch(inst)

    inst:DoPeriodicTask(2, UpdateInsulationMode)  -- 每2秒检测温度
    UpdateInsulationMode(inst)  -- 初始设置
	inst.UpdateInsulationTask = nil
    inst.lastmainshield = 0

    return inst
end

local function battle()
    local inst = common()
    
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst.components.inventoryitem.atlasname = "images/inventoryimages/alice_coat.xml"
    inst.components.inventoryitem.imagename = "alice_coat"

    inst.components.container:WidgetSetup("alice_battlecoat")

    return inst
end

local function maid()
    local inst = common()
    
    if not TheWorld.ismastersim then
        return inst
    end
    
    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(onequip_maid)
    inst.components.equippable:SetOnUnequip(onunequip_maid)

    inst.components.inventoryitem.atlasname = "images/inventoryimages/alice_maidcoat.xml"
    inst.components.inventoryitem.imagename = "alice_maidcoat"

    inst.components.container:WidgetSetup("alice_maidcoat")

    return inst
end

return  Prefab("alice_battlecoat", battle, assets, prefabs),
    Prefab("alice_maidcoat", maid, assets, prefabs)