local prefabs = {}

local assets =
{
    Asset("ANIM", "anim/blueprint.zip"),
    Asset("ANIM", "anim/blueprint_rare.zip"),
    Asset("INV_IMAGE", "blueprint"),
    Asset("INV_IMAGE", "blueprint_rare"),
}

local UpvalueHacker = require("alice_utils/utils") 

local fn = UpvalueHacker.FindUpvalue(Prefabs["blueprint"].fn, "fn")

local function MakeSpecificBlueprint(specific_item)
    return function()
        local is_rare = false

        local r = GetValidRecipe(specific_item)
        if r ~= nil then
            for k, v in pairs(r.level) do
                if v >= 10 then
                    is_rare = true
                    break
                end
            end
        end

        local inst = fn(is_rare)

        if not TheWorld.ismastersim then
            return inst
        end

        local r = GetValidRecipe(specific_item)
        inst.recipetouse = r ~= nil and not r.nounlock and r.name or "unknown"
        inst.components.teacher:SetRecipe(inst.recipetouse)
        
        -- 获取配方产出物品的名称
        local product_name = r and r.product and STRINGS.NAMES[string.upper(r.product)] or STRINGS.NAMES.UNKNOWN
        if is_rare then
            inst.components.named:SetName(subfmt(STRINGS.NAMES.BLUEPRINT_RARE, { item = product_name }))
        else
            inst.components.named:SetName(product_name .. " " .. STRINGS.NAMES.BLUEPRINT)
        end
        return inst
    end
end

if fn then
    -- 只添加启迪之冠碎片蓝图，删除其他蓝图
    table.insert(prefabs, Prefab("alterguardianhatshard_blueprint", MakeSpecificBlueprint("alice_alterguardianhatshard"), assets))
else
    print("cant find MakeSpecificBlueprint")
end

return unpack(prefabs)