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
        if is_rare then
            inst.components.named:SetName(subfmt(STRINGS.NAMES.BLUEPRINT_RARE, { item = STRINGS.NAMES[string.upper(inst.recipetouse)] }))
        else
            inst.components.named:SetName(STRINGS.NAMES[string.upper(inst.recipetouse)].." "..STRINGS.NAMES.BLUEPRINT)
        end
        return inst
    end
end



if fn then
    table.insert(prefabs, Prefab("thorn_shield_blueprint", MakeSpecificBlueprint("thorn_shield"), assets))
    table.insert(prefabs, Prefab("shadow_shield_blueprint", MakeSpecificBlueprint("shadow_shield"), assets))
    table.insert(prefabs, Prefab("alice_mode2_blueprint", MakeSpecificBlueprint("alice_mode2"), assets))
    table.insert(prefabs, Prefab("alice_remote_blueprint", MakeSpecificBlueprint("alice_remote"), assets))
else
    print"cant find MakeSpecificBlueprint"
end

return unpack(prefabs)