GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})

local containers = require("containers")
local params = containers.params

params.alice_lightsword = {
    widget = {
        slotpos =
        {
            Vector3(0,   32 + 4,  0),
        },
        animbank = "ui_cookpot_1x2",
        animbuild = "ui_cookpot_1x2",
        pos = Vector3(0, 15, 0),
    },
    acceptsstacks = false,
    usespecificslotsforitems = true,
    type = "hand_inv",
    excludefromcrafting = true,
    itemtestfn = function(inst, item, slot)
        return item:HasTag("alice_battery")
    end
}

-- 基础护甲（战斗外套）：2×4 = 8 格，最后一格为插板槽
params.alice_battlecoat = {
    widget = {
        slotpos = {},
        animbank = "ui_backpack_2x4",
        animbuild = "ui_backpack_2x4",
        pos = Vector3(-5, -80, 0),
    },
    issidewidget = true,
    type = "pack",
    openlimit = 1,
    usespecificslotsforitems = true,
    itemtestfn = function(inst, item, slot)
        local num_slots = 8
        if slot == num_slots then
            return item:HasTag("alice_shield")
        end
        if item:HasTag("alice_shield") then
            return false
        end
        return true
    end,
}
-- 填充 slotpos（2列4行）
for y = 0, 3 do
    table.insert(params.alice_battlecoat.widget.slotpos, Vector3(-162, -75 * y + 114, 0))
    table.insert(params.alice_battlecoat.widget.slotpos, Vector3(-162 + 75, -75 * y + 114, 0))
end

-- 进阶护甲（女仆外套）：2×7 = 14 格，最后一格为插板槽
params.alice_maidcoat = {
    widget = {
        slotpos = {},
        animbank = "ui_krampusbag_2x8",
        animbuild = "ui_krampusbag_2x8",
        pos = Vector3(-5, -130, 0),
    },
    issidewidget = true,
    type = "pack",
    openlimit = 1,
    usespecificslotsforitems = true,
    itemtestfn = function(inst, item, slot)
        local num_slots = 14
        if slot == num_slots then
            return item:HasTag("alice_shield")
        end
        if item:HasTag("alice_shield") then
            return false
        end
        return true
    end,
}
-- 填充 slotpos（2列7行）
for y = 0, 6 do
    table.insert(params.alice_maidcoat.widget.slotpos, Vector3(-162, -75 * y + 240, 0))
    table.insert(params.alice_maidcoat.widget.slotpos, Vector3(-162 + 75, -75 * y + 240, 0))
end
    
params.alice_robot =
{
    widget =
    {
        slotpos = {},
        animbank = "ui_boat_ancient_4x4",
        animbuild = "ui_boat_ancient_4x4",
        pos = Vector3(0, 200, 0),
        side_align_tip = 160,
    },
    type = "chest",
}

for y = 3, 0, -1 do
    for x = 0, 3 do
        table.insert(params.alice_robot.widget.slotpos, Vector3(80 * x - 80 * 2.5 + 80, 80 * y - 80 * 2.5 + 80, 0))
    end
end