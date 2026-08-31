local assets =
{
    Asset("ANIM", "anim/alice_battery.zip"),
    Asset("ATLAS", "images/inventoryimages/alice_battery.xml"),
}

-- 计算需要多少电荷才能充满
local function CalcChargeMult(inst, battery)
    local pct = inst.components.fueled:GetPercent()
    local needed_pct = 1 - pct
    -- 每个电荷恢复的百分比
    local add_percent = TUNING.ALICE_BATTERY_FUEL_ADD / TUNING.ALICE_BATTERY_FUEL
    local needed_charge = needed_pct / add_percent
    return needed_charge
end

-- 接收电荷并充电
local function OnBatteryUsed(inst, battery, mult)
    if mult <= 0 or inst.components.fueled:IsFull() then
        return false, "CHARGE_FULL"
    end
    local add_percent = TUNING.ALICE_BATTERY_FUEL_ADD / TUNING.ALICE_BATTERY_FUEL
    local new_pct = math.min(1, inst.components.fueled:GetPercent() + mult * add_percent)
    inst.components.fueled:SetPercent(new_pct)
    return true
end

local function tool_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst:AddTag("alice_battery")
    inst:AddTag("batteryuser")          -- 标记为可被充电

    inst.AnimState:SetBank("alice_battery")
    inst.AnimState:SetBuild("alice_battery")
    inst.AnimState:PlayAnimation("alice_battery")

    inst.entity:SetPristine()

    inst.targetslot = EQUIPSLOTS.HANDS

    if not TheWorld.ismastersim then
        return inst
    end
    
    inst:AddComponent("fueled")
    inst.components.fueled:InitializeFuelLevel(TUNING.ALICE_BATTERY_FUEL)

    inst:AddComponent("inspectable")
    
    inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/alice_battery.xml"

    -- ===== 用电器（接受充电）=====
    inst:AddComponent("batteryuser")
    inst.components.batteryuser:SetChargeMultFn(CalcChargeMult)
    inst.components.batteryuser:SetOnBatteryUsedFn(OnBatteryUsed)
    inst.components.batteryuser:SetAllowPartialCharge(true)

    MakeHauntableLaunch(inst)
    
    return inst
end

return Prefab("alice_battery", tool_fn, assets, prefabs)