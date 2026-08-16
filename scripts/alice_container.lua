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

params.alice_battlecoat = {
    widget = {
        slotpos =
        {
            Vector3(0,   32 + 4,  0),
        },
        animbank = "ui_cookpot_1x2",
        animbuild = "ui_cookpot_1x2",
        pos = Vector3(50, 15, 0),
    },
    acceptsstacks = false,
    usespecificslotsforitems = true,
    type = "hand_inv",
    excludefromcrafting = true,
    itemtestfn = function(inst, item, slot)
        return item:HasTag("alice_shield")
    end
}

params.alice_maidcoat = params.alice_battlecoat
    
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