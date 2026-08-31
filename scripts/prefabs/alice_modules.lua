local module_definitions = require("wx78_moduledefs").module_definitions

local assets =
{
    Asset("ANIM", "anim/wx_chips.zip"),

    Asset("SCRIPT", "scripts/wx78_moduledefs.lua"),
}

-- 更新 on_module_removed：增加 owner 参数，检查是否正在交换
local function on_module_removed(inst, owner)
    if inst.components.finiteuses ~= nil and not owner.components.upgrademoduleowner:IsSwapping() then
        -- 如果有技能树且激活了“更好拔插”，消耗减半，否则正常消耗
        local leader = owner.components.follower and owner.components.follower:GetLeader() or owner
        local use = leader.components.skilltreeupdater ~= nil and leader.components.skilltreeupdater:IsActivated("wx78_circuitry_betterunplug")
            and TUNING.SKILLS.WX78.HALF_MODULE_CONSUMPTION
            or TUNING.WX78_MODULE_CONSUMPTION
        inst.components.finiteuses:Use(use)
    end
end

local function MakeModule(data)
    local prefabs = {}
    if data.extra_prefabs ~= nil then
        for _, extra_prefab in ipairs(data.extra_prefabs) do
            table.insert(prefabs, extra_prefab)
        end
    end

    -- 您可以保留自己的 bank/build，也可以使用默认的 chips/wx_chips
    local CHIP_BANK = data.overridebank or "chips"
    local CHIP_BUILD = data.overridebuild or "wx_chips"
    local FLOATER_SCALE = (data.slots == 1 and 0.75) or 1.0

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank(CHIP_BANK)
        inst.AnimState:SetBuild(CHIP_BUILD)
        inst.AnimState:PlayAnimation(data.name)
        inst.scrapbook_anim = data.name

        if data.slots > 4 then
            MakeInventoryFloatable(inst, "med", 0.1, 0.75)
        else
            MakeInventoryFloatable(inst, nil, 0.1, FLOATER_SCALE)
        end

        --------------------------------------------------------------------------
        -- 新版需要存储 _netid, _slots, _type（类型用于UI分组）
        inst._netid = data.module_netid
        inst._slots = data.slots
        inst._type = data.type  -- 新增

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        --------------------------------------------------------------------------
        inst:AddComponent("inspectable")

        --------------------------------------------------------------------------
        inst:AddComponent("inventoryitem")

        --------------------------------------------------------------------------
        inst:AddComponent("upgrademodule")
        inst.components.upgrademodule:SetRequiredSlots(data.slots)
        inst.components.upgrademodule:SetType(data.type)  -- 新增
        inst.components.upgrademodule.onactivatedfn = data.activatefn
        inst.components.upgrademodule.ondeactivatedfn = data.deactivatefn
        inst.components.upgrademodule.onaddedtoownerfn = data.addedtoownerfn  -- 新增（可为nil）
        inst.components.upgrademodule.onremovedfromownerfn =
            data.removedfromownerfn and
            function(inst, wx)
                data.removedfromownerfn(inst, wx)
                on_module_removed(inst, wx)
            end or
            on_module_removed

        --------------------------------------------------------------------------
        inst:AddComponent("finiteuses")
        inst.components.finiteuses:SetMaxUses(TUNING.WX78_MODULE_USES)
        inst.components.finiteuses:SetUses(TUNING.WX78_MODULE_USES)
        inst.components.finiteuses:SetOnFinished(inst.Remove)

        -- 添加幽灵互动（可选，但新版有）
        MakeHauntableLaunch(inst)

        return inst
    end

    return Prefab("wx78module_"..data.name, fn, assets, prefabs)
end

local module_prefabs = {}
for _, def in ipairs(module_definitions) do
    table.insert(module_prefabs, MakeModule(def))
end

return unpack(module_prefabs)