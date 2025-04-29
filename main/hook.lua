GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})

local UserDataHook = require("alice_utils/userdatahook")

local function NotRiding(inst)
    return not (inst.replica.rider and inst.replica.rider:IsRiding())
end

local function EquipLight(inst)
    return inst.replica.inventory and inst.replica.inventory:EquipHasTag("lightsword")
end

local function notbusy(inst)
    return not inst.sg.statemem.riding
        and not inst.sg.statemem.sandstorm
        and not inst.sg.statemem.groggy
        and not inst.sg.statemem.careful
end

-- 光之剑闲置动作
local hookidle
hookidle = UserDataHook.MakeHook("AnimState","PlayAnimation", function(inst)
    local args = hookidle.args
    if args and args[1] and args[1] == "idle_loop" and NotRiding(inst) and EquipLight(inst) then
        args[1] = "alice_idle"
    end
    return false
end)

local hookidle2
hookidle2 = UserDataHook.MakeHook("AnimState","PushAnimation", function(inst)
    local args = hookidle2.args
    if args and args[1] and args[1] == "idle_loop" and NotRiding(inst) and EquipLight(inst) then
        args[1] = "alice_idle"
    end
    return false
end)

-- 禁用其他闲置动作
local valid_idle_anims = {
    "idle_inaction", "dial_loop", "idle_inaction_sanity", "idle_inaction_lunacy", "hungry",
    "idle_groggy_pre", "sand_idle_loop", "sand_idle_pre", "idle_sanity_pre", "idle_sanity_loop",
    "idle_lunacy_pre", "idle_lunacy_loop", "idle_shiver_pre", "idle_shiver_loop", "idle_hot_pre",
    "idle_hot_loop"
}

local function idleanim(args)
    return table.contains(valid_idle_anims, args)
end

local hookidle3
hookidle3 = UserDataHook.MakeHook("AnimState","PlayAnimation", function(inst)
    local args = hookidle3.args
    if args and args[1] and idleanim(args[1]) and NotRiding(inst) and EquipLight(inst) then
        args[1] = "alice_idle"
    end
    return false
end)

-- 掏枪动作
local hookitem_out
hookitem_out = UserDataHook.MakeHook("AnimState","PlayAnimation", function(inst)
    local args = hookitem_out.args
    if args and args[1] and args[1] == "item_out" and NotRiding(inst) and EquipLight(inst) then
        args[1] = "alice_taoqiang"
    end
    return false
end)

-- 普通射击动作
local hookatk
hookatk = UserDataHook.MakeHook("AnimState","PlayAnimation", function(inst)
    local args = hookatk.args
    if args and args[1] and args[1] == "atk_pre" and NotRiding(inst) and EquipLight(inst) then
        args[1] = ""
    end
    return false
end)

-- 普通射击动作
local hookatk2
hookatk2 = UserDataHook.MakeHook("AnimState","PushAnimation", function(inst)
    local args = hookatk2.args
    if args and args[1] and args[1] == "atk" and NotRiding(inst) and EquipLight(inst) then
        args[1] = "alice_atk"
    end
    return false
end)

-- 受击动作
local hookhit
hookhit = UserDataHook.MakeHook("AnimState","PlayAnimation", function(inst)
    local args = hookhit.args
    if args and args[1] and args[1] == "hit" and NotRiding(inst) and EquipLight(inst) then
        args[1] = "alice_hit"
    end
    return false
end)

-- 跑步动作
local hookrunpre
hookrunpre = UserDataHook.MakeHook("AnimState","PlayAnimation", function(inst)
    local args = hookrunpre.args
    if args and args[1] and args[1] == "run_pre" and NotRiding(inst) and EquipLight(inst) then
        args[1] = "alice_run_pre"
    end
    return false
end)

-- 跑步动作
local hookrunpst
hookrunpst = UserDataHook.MakeHook("AnimState","PlayAnimation", function(inst)
    local args = hookrunpst.args
    if args and args[1] and args[1] == "run_pst" and NotRiding(inst) and EquipLight(inst) then
        args[1] = "alice_run_pst"
    end
    return false
end)

AddPlayerPostInit(function(inst)
    UserDataHook.Hook(inst, hookidle)
    UserDataHook.Hook(inst, hookidle2)
    UserDataHook.Hook(inst, hookidle3)

    UserDataHook.Hook(inst, hookitem_out)
    UserDataHook.Hook(inst, hookatk)
    UserDataHook.Hook(inst, hookatk2)
    UserDataHook.Hook(inst, hookhit)
    UserDataHook.Hook(inst, hookrunpre)
    UserDataHook.Hook(inst, hookrunpst)
end)

local function hookrunsg(self, ismaster)
    local run = self.states.run
    if run then
        local old_enter = run.onenter
        function run.onenter(inst, ...)
            if old_enter then
                old_enter(inst, ...)
            end
            if --[[inst:HasTag("alice") and]] notbusy(inst) then
                local hands_inv
                if ismaster then
                    hands_inv = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                else
                    hands_inv = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                end
                if hands_inv and hands_inv:HasTag("lightsword") then
                    local anim = "alice_run_loop"
                    if not inst.AnimState:IsCurrentAnimation(anim) then
                        inst.AnimState:PlayAnimation(anim, true)
                    end
                end
                inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength() + 0.01)
            end
        end
    end
end

AddStategraphPostInit("wilson", function(sg)
    hookrunsg(sg, true)
end)

AddStategraphPostInit("wilson_client", function(sg)
    hookrunsg(sg)
end)