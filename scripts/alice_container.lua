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

params.wx78module_alc_charge = {
    widget = {
        slotpos =
        {
            Vector3(0,   32 + 4,  0),
            Vector3(0, -(32 + 4), 0),
        },
        animbank = "ui_cookpot_1x2",
        animbuild = "ui_cookpot_1x2",
        pos = Vector3(0, 160, 0),
        buttoninfo =
        {
            text = "充电",
            position = Vector3(0, -93, 0),
        },
    },
    acceptsstacks = false,
    usespecificslotsforitems = true,
    type = "chest",
    excludefromcrafting = true,
    itemtestfn = function(inst, item, slot)
        return item:HasTag("alice_battery") or item:HasTag("alice_remote") 
    end
}

function params.wx78module_alc_charge.widget.buttoninfo.fn(inst, doer)
    if inst.chargetask ~= nil then
        return
    end

    if inst.components.container ~= nil then
        inst.chargetest = true
        local action = BufferedAction(doer, inst, ACTIONS.APPLYMODULE, inst)
        doer.components.locomotor:PushAction(action)
        inst.wx = doer
        if inst.components.container ~= nil then
            inst.components.container:Close()
        end
    elseif inst.replica.container ~= nil and not inst.replica.container:IsBusy() then
        SendRPCToServer(RPC.DoWidgetButtonAction, ACTIONS.APPLYMODULE.code, inst, ACTIONS.APPLYMODULE.mod_name)
    end
end

function params.wx78module_alc_charge.widget.buttoninfo.validfn(inst)
    return inst.replica.container ~= nil and not inst.replica.container:IsEmpty() and not inst.charging:value()
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