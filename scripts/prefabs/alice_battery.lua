local assets =
{
    Asset("ANIM", "anim/alice_battery.zip"),
    Asset("ATLAS", "images/inventoryimages/alice_battery.xml"),
}

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
    inst.components.fueled:InitializeFuelLevel(TUNING.ALICE_BATTERY_INITIAL_USES)
    inst.components.fueled:SetMaxFuel(TUNING.ALICE_BATTERY_MAX_USES)

    inst:AddComponent("inspectable")
    
    inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/alice_battery.xml"

    -- ===== 用电器（接受充电）=====
    inst:AddComponent("batteryuser")
    inst.components.batteryuser:SetOnBatteryUsedFn(function(inst, charger, charge_amount)
        if charge_amount <= 0 or inst.components.fueled:IsFull() then
            return false, "CHARGE_FULL"
        end
        local new_pct = math.min(1, inst.components.fueled:GetPercent() + charge_amount)
        inst.components.fueled:SetPercent(new_pct)
        return true
    end)
    inst.components.batteryuser:SetAllowPartialCharge(true)

    MakeHauntableLaunch(inst)
    
    return inst
end

return Prefab("alice_battery", tool_fn, assets, prefabs)