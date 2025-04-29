<<<<<<< HEAD
GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})

--蓄力移动
local function IsDirectWalking(inst)
	if inst.components.playercontroller then
		if inst.components.playercontroller.directwalking then
			return true
		elseif inst.components.playercontroller:GetRemoteDirectVector() ~= nil then
			return true
		end
	end
	return false
end

local function RunOrStop(inst)
    if not inst.sg:HasStateTag("alice_shot") then
		return
	end

	if inst.sg.statemem.directwalking then
		inst.sg:AddStateTag("moving")
		inst.sg:AddStateTag("running")
		inst.components.locomotor:RunForward()
        if not inst.AnimState:IsCurrentAnimation("alice_powershot_loop") then
			inst.AnimState:PlayAnimation("alice_powershot_loop", true)
        end
	else
		inst.sg:RemoveStateTag("moving")
		inst.sg:RemoveStateTag("running")
		inst.sg.mem.footsteps = 0
		inst.components.locomotor:Stop()
        if not inst.AnimState:IsCurrentAnimation("alice_powershot_loop1") then
			inst.AnimState:PlayAnimation("alice_powershot_loop1", true)
        end
	end
end

local function CommonUpdate(inst, dt)
	inst.sg.statemem.directwalking = IsDirectWalking(inst)
	RunOrStop(inst)
end

local function WalkPostInit(self)
	local locomote = self.events["locomote"]
	local old_fn = locomote.fn
	function locomote.fn(inst, data)
		if inst.sg:HasStateTag("alice_shot") then
			return
		end
		return old_fn(inst, data)
	end
end

AddStategraphPostInit("wilson", WalkPostInit)
AddStategraphPostInit("wilson_client", WalkPostInit)

local old_CASTAOE = ACTIONS.CASTAOE.fn
ACTIONS.CASTAOE.fn = function(act)
    if act.invobject ~= nil and act.invobject:HasTag("lightsword") then
        return true
    end
    return old_CASTAOE(act)
end

--Hooksg
local VAILDMODE = {
    FAST = {1, 2,},
    CHARGE = {3, 4},
}

local function Hooklightsword(sg)
    local old_caseaoe = sg.actionhandlers[ACTIONS.CASTAOE].deststate
    sg.actionhandlers[ACTIONS.CASTAOE].deststate = function(inst, action)
        local invobject = action.invobject
        local doer = action.doer
        if invobject and invobject:HasTag("lightsword") and invobject.components.alice_sword then
            local mode = invobject.components.alice_sword:GetCurrentMode() or 0
            if not invobject.components.alice_sword:Checkfiniteuses() then
                if doer and doer.components.talker then
                    doer.components.talker:Say(STRINGS.ACTIONS.LIGHTSWORD.NOFINITINESS)
                end
                return false
            end
            -- 蓄力还在CD
            if mode == 3 and invobject:HasTag("charging") then
                if doer and doer.components.talker then
                    doer.components.talker:Say(STRINGS.ACTIONS.LIGHTSWORD.CHARGECD)
                end
                return false
            end
            -- 电池耐久不足
            if mode == 0 then
                if doer and doer.components.talker then
                    doer.components.talker:Say(STRINGS.ACTIONS.LIGHTSWORD.NO_ENABLE)
                end
                return false
            elseif table.contains(VAILDMODE.FAST, mode) then
                if doer then
                    doer.firstshot = true
                end
                return "alice_shot_fast" 
            elseif table.contains(VAILDMODE.CHARGE, mode) then
                return "alice_charge_pre"
            end
        end
        return old_caseaoe(inst, action)
    end
end

local function Hooklightsword_clinet(sg)
    local old_caseaoe = sg.actionhandlers[ACTIONS.CASTAOE].deststate
    sg.actionhandlers[ACTIONS.CASTAOE].deststate = function(inst, action)
        local invobject = action.invobject
        local doer = action.doer
        if invobject and invobject:HasTag("lightsword") and invobject.replica.alice_sword then
            local mode = invobject.replica.alice_sword:GetCurrentMode() or 0

            if mode == 0 then
                return false
            elseif table.contains(VAILDMODE.FAST, mode) then
                if doer then
                    doer.firstshot = true
                end
                return "alice_shot_fast" 
            elseif table.contains(VAILDMODE.CHARGE, mode) then
                return "alice_charge_pre"
            end
        end
        return old_caseaoe(inst, action)
    end
end

AddStategraphPostInit("wilson", Hooklightsword)
AddStategraphPostInit("wilson_client", Hooklightsword_clinet)

--RPC
ALC_UpdateAOETargeting = function(player, cancel)
    local controller = player and player.components.playercontroller
    if controller and cancel then
        controller:CancelAOETargeting()
    end
end

AddClientModRPCHandler("alice", "UpdateAOETargeting", function(cancel)
    ALC_UpdateAOETargeting(ThePlayer, cancel)
end)

local function CancelAOETargeting(inst)
    ALC_UpdateAOETargeting(inst, true)
    SendModRPCToClient(CLIENT_MOD_RPC["alice"]["UpdateAOETargeting"], inst.userid, true)
end

local function SetAOETargetingScale(inst)
    ALC_UpdateAOETargeting(inst, nil)
    SendModRPCToClient(CLIENT_MOD_RPC["alice"]["UpdateAOETargeting"], inst.userid, nil)
end

local function GetWeapon_Master(inst)
    return inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
end

local function GetWeapon_Client(inst)
    return inst.replica.inventory and inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
end

-----------------------------------------------------
-------------------alice_charge_pre------------------
-----------------------------------------------------

local alice_charge_pre = State{
        name = "alice_charge_pre",
        tags = { "moving", "running", "alice_shot", "busy"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("alice_powershot_pre")
        end,
        
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.alc_mousepos = nil
                    local equip = GetWeapon_Master(inst)
                    if equip and equip.components.alice_sword:GetCurrentMode() == 3 then
                        inst.sg:GoToState("alice_charge_loop")
                    else
                        inst.sg:GoToState("alice_shot_fire")
                    end
                end
            end),
        },
        
        onexit = function(inst)
            inst:ClearBufferedAction()
        end,
    }
----------------client----------------
local alice_charge_pre_client = State{
        name = "alice_charge_pre",
        tags = { "moving", "running", "alice_shot", "busy"},
		server_states = { "alice_charge_pre"},

        onenter = function(inst)
            local action = inst:GetBufferedAction()

            if action ~= nil then
                inst:PerformPreviewBufferedAction()
            end

            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("alice_powershot_pre")
			inst.sg:SetTimeout(2)
        end,
        
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.alc_mousepos = nil
                    local equip = GetWeapon_Client(inst)
                    if equip and equip.replica.alice_sword:GetCurrentMode() == 3 then
                        inst.sg:GoToState("alice_charge_loop")
                    else
                        inst.sg:GoToState("alice_shot_fire")
                    end
                end
            end),

            EventHandler("lightsword_nofinitiness", function(inst)
                inst.sg:GoToState("idle")
            end),
        },

        ontimeout = function(inst)
			inst:ClearBufferedAction()
			inst.sg:GoToState("idle", true)
		end,

        onexit = function(inst)
            inst:ClearBufferedAction()
        end,
    }

AddStategraphState("wilson", alice_charge_pre)
AddStategraphState("wilson_client", alice_charge_pre_client)

-----------------------------------------------------
-------------------alice_shot_fire-------------------
-----------------------------------------------------

local alice_shot_fire = State{
        name = "alice_shot_fire",
        tags = { "doing", "alice_shot", "moving", "running"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("alice_powershot_loop", true)
            inst:AddTag("alice_shot")

            local equip = GetWeapon_Master(inst)
            local damage = 0
            if equip and equip:HasTag("lightsword") then
                equip:AddTag("fireatk")
                equip.components.alice_sword.shotmode = 4
                damage = equip.components.alice_sword:GeDamage()
            end

            if inst.alc_firefx == nil then
                inst.alc_firefx = SpawnPrefab("laserthrower_fx")
                inst.alc_firefx:InitDamage(damage)
                inst.alc_firefx:SetFlamethrowerAttacker(inst)
                inst.alc_firefx:UpdatePosition()
            end
            RunOrStop(inst)
        end,

        onexit = function(inst)
            inst:ClearBufferedAction()
            inst.alc_lmb = nil
            inst:RemoveTag("alice_shot")
            if inst.alc_firefx ~= nil then
                inst.alc_firefx:KillFX()
                inst.alc_firefx = nil
            end
            local equip = GetWeapon_Master(inst)
            if equip then
                equip:RemoveTag("fireatk")
            end
        end,

        onupdate = function(inst)
			CommonUpdate(inst, dt)
            local equip = GetWeapon_Master(inst)
            if equip and equip.components.alice_sword then
                equip.components.alice_sword:DoItemUse()
            end
            if inst.alc_lmb == "up" or not (equip and equip.components.alice_sword and equip.components.alice_sword:GetCurrentMode() == 4 
                and equip.components.alice_sword:Checkfiniteuses()) then
                inst.sg:GoToState("idle")
            end
            if inst.alc_mousepos ~= nil then
                inst:ForceFacePoint(inst.alc_mousepos)
            end
            SetAOETargetingScale(inst)
        end,
    }

----------------client----------------

local alice_shot_fire_client = State{
        name = "alice_shot_fire",
        tags = { "doing", "alice_shot", "moving", "running"},
		server_states = { "alice_shot_fire"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("alice_powershot_loop", true)

            RunOrStop(inst)
        end,

        onexit = function(inst)
            inst.alc_lmb = nil
        end,

        onupdate = function(inst)
			CommonUpdate(inst, dt)

            if inst.alc_mousepos ~= nil then
                inst:ForceFacePoint(inst.alc_mousepos)
            end

			if inst.alc_lmb == "up" then
                inst.sg:GoToState("idle")
            end
        end,

        events =
        {
            EventHandler("lightsword_nofinitiness", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    }

AddStategraphState("wilson", alice_shot_fire)
AddStategraphState("wilson_client", alice_shot_fire_client)

-----------------------------------------------------
------------------alice_charge_loop------------------
-----------------------------------------------------

local alice_charge_loop = State{
        name = "alice_charge_loop",
        tags = {"alice_shot", "moving", "running"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("alice_powershot_loop", true)
            inst:AddTag("alice_shot")
            if inst:HasTag("alice") then
                inst.SoundEmitter:PlaySound("alicesound/alicesound/yosi", "alc_chargevoice", .5)
            end
            
            RunOrStop(inst)
        end,

        onexit = function(inst)
            inst.alc_lmb = nil
            inst.alc_canshot = nil
            inst:RemoveTag("alice_shot")
            if inst:HasTag("alice") then
                inst.SoundEmitter:KillSound("alc_chargevoice")
                inst.SoundEmitter:KillSound("alice_charge2")
            end
        end,

        onupdate = function(inst)
			CommonUpdate(inst, dt)
            local equip = GetWeapon_Master(inst)
            if inst.alc_lmb == "up" or not (equip and equip.components.alice_sword and equip.components.alice_sword:GetCurrentMode() == 3) then
                if inst.alc_canshot then
                    inst.alc_lmb = nil
                    inst.alc_canshot = nil
                    inst.sg:GoToState("alice_charge_pst")
                else
                    inst.sg:GoToState("idle")
                end
            end
            if inst.alc_mousepos ~= nil then
                inst:ForceFacePoint(inst.alc_mousepos)
            end
            SetAOETargetingScale(inst)
        end,

        timeline=
        {
            TimeEvent(15 * FRAMES, function(inst) 
                inst.SoundEmitter:PlaySound("alicesound/alicesound/alice_charge2", "alice_charge2", .5)
            end),
            TimeEvent(55 * FRAMES, function(inst) 
                inst.alice_charge_fx = SpawnPrefab("alice_charge_fx")
                inst.alice_charge_fx.entity:AddFollower()
                inst.alice_charge_fx.Follower:FollowSymbol(inst.GUID, "wepon", 250, 0, 0)
            end),
            TimeEvent(60 * FRAMES, function(inst) 
                inst.alc_canshot = true 
            end),
        },
    }

----------------client----------------

local alice_charge_loop_client = State{
        name = "alice_charge_loop",
        tags = {"alice_shot", "moving", "running"},
		server_states = { "alice_charge_loop"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("alice_powershot_loop", true)
            
            RunOrStop(inst)
        end,

        onexit = function(inst)
            inst.alc_lmb = nil
        end,

        onupdate = function(inst)
			CommonUpdate(inst, dt)

            local equip = GetWeapon_Client(inst)
            if inst.alc_lmb == "up" or not (equip and equip.replica.alice_sword and equip.replica.alice_sword:GetCurrentMode() == 3) then
                if inst.alc_canshot then
                    inst.alc_lmb = nil
                    inst.alc_canshot = nil
                    inst.sg:GoToState("alice_charge_pst")
                else
                    inst.sg:GoToState("idle")
                end
            end
            if inst.alc_mousepos ~= nil then
                inst:ForceFacePoint(inst.alc_mousepos)
            end
        end,

        timeline=
        {
            TimeEvent(60 * FRAMES, function(inst) 
                inst.alc_canshot = true 
            end),
        },
    }

AddStategraphState("wilson", alice_charge_loop)
AddStategraphState("wilson_client", alice_charge_loop_client)

-----------------------------------------------------
-------------------alice_charge_pst------------------
-----------------------------------------------------

local alice_charge_pst = State{
        name = "alice_charge_pst",
        tags = { "moving", "running", "busy", "alice_shot"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("alice_powershot")
            CancelAOETargeting(inst)
            inst:AddTag("alice_shot")
            
            if inst:HasTag("alice") then
                inst.SoundEmitter:PlaySound("alicesound/alicesound/hikari", "alc_shotvoice", .5)
            end
        end,

        onexit = function(inst)
            inst:RemoveTag("alice_shot")
            if inst:HasTag("alice") then
                inst.SoundEmitter:KillSound("alc_shotvoice")
            end
        end,

        timeline=
        {
            TimeEvent(2*FRAMES, function(inst) 
                local equip = GetWeapon_Master(inst)
                if equip ~= nil and equip.components.alice_sword and equip.components.rechargeable then
                    equip.components.alice_sword:LaunchLaser(inst, inst.alc_mousepos)
                    equip.components.rechargeable:Discharge(TUNING.LIGHTSWORDCD)
                end 
            end),
        },

        events=
        {
            EventHandler("animover", function(inst) 
                inst.sg:GoToState("idle")
            end),
        },
    }

----------------client----------------

local alice_charge_pst_client = State{
        name = "alice_charge_pst",
        tags = { "moving", "running", "busy", "alice_shot"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("alice_powershot")
        end,

        events=
        {
            EventHandler("animover", function(inst) 
                inst.sg:GoToState("idle")
            end),
        },
    }

AddStategraphState("wilson", alice_charge_pst)
AddStategraphState("wilson_client", alice_charge_pst_client)

-----------------------------------------------------
-------------------alice_shot_fast-------------------
-----------------------------------------------------

local alice_shot_fast = State{
        name = "alice_shot_fast",
        tags = { "doing", "busy", "alice_shot"},

        onenter = function(inst)
            inst:PerformBufferedAction()
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("alice_atk")
            inst:AddTag("alice_shot")
        end,

        onexit = function(inst)
            inst:ClearBufferedAction()
            inst.firstshot = false
        end,
  
        onupdate = function(inst)
            if inst.alc_mousepos ~= nil then
                inst:ForceFacePoint(inst.alc_mousepos)
            end

            local equip = GetWeapon_Master(inst)
            if (not inst.firstshot and inst.alc_lmb == "up") or 
                not (equip and equip.components.alice_sword and table.contains(VAILDMODE.FAST, equip.components.alice_sword:GetCurrentMode())) then
                inst.alc_lmb = nil
                inst.sg:GoToState("idle")
            end
        end,

        timeline=
        {
            TimeEvent(9 * FRAMES, function(inst) 
                local equip = GetWeapon_Master(inst)
                if equip ~= nil and equip.components.alice_sword ~= nil then
                    equip.components.alice_sword:Launch(inst, inst.alc_mousepos)
                end
                inst:RemoveTag("alice_shot")
            end),
        },

        events=
        {
            EventHandler("animover", function(inst)  --21FRAMES
                inst.sg:GoToState("alice_shot_fast")
            end ),
        },

    }
    
----------------client----------------

local alice_shot_fast_client = State{
        name = "alice_shot_fast",
        tags = { "doing", "busy", "alice_shot"},
		server_states = { "alice_shot_fast" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst:PerformPreviewBufferedAction()
            inst.AnimState:PlayAnimation("alice_atk")
        end,

        onexit = function(inst)
            inst:ClearBufferedAction()
            inst.firstshot = false
        end,
  
        onupdate = function(inst)
            if inst.alc_mousepos ~= nil then
                inst:ForceFacePoint(inst.alc_mousepos)
            end

            local equip = GetWeapon_Client(inst)
            if (not inst.firstshot and inst.alc_lmb == "up") or 
                not (equip and equip.replica.alice_sword and table.contains(VAILDMODE.FAST, equip.replica.alice_sword:GetCurrentMode())) then
                inst.alc_lmb = nil
                inst.sg:GoToState("idle")
            end
        end,
        
        events=
        {
            EventHandler("animover", function(inst)  --21FRAMES
                inst.sg:GoToState("alice_shot_fast")
            end ),
            
            EventHandler("lightsword_nofinitiness", function(inst)
                inst.sg:GoToState("idle")
            end),
        },

    }

AddStategraphState("wilson", alice_shot_fast)
AddStategraphState("wilson_client", alice_shot_fast_client)

-----------------------------------------------------
--------------------猴子女王给蓝图--------------------
-----------------------------------------------------
AddStategraphPostInit("monkeyqueen", function(sg)
    local state = sg.states["getitem"]
    local old_onenter = state.onenter
    
    state.onenter = function(inst, data, ...)
        if old_onenter then
            old_onenter(inst, data, ...)
        end
        if data and data.item and data.giver and data.giver.prefab == "alice" then
            local function spawnloot(inst)
                local loot = SpawnPrefab("alice_mode2_blueprint")
                inst.components.lootdropper:FlingItem(loot)
                inst:RemoveEventCallback("animover", spawnloot)
            end
            inst:ListenForEvent("animover", spawnloot)
        end
    end
end)


-----------------------------------------------------
--------------------alice_remote---------------------
-----------------------------------------------------
local alice_remote = State{
    name = "alice_remote",
	tags = {"doing", "busy", "canrotate", "nointerrupt", "nomorph", "nopredict"},

    onenter = function(inst, remote)
		inst.components.locomotor:Stop()
		inst.components.locomotor:Clear()
        inst.AnimState:PlayAnimation("remote_guge")

        inst.sg.statemem.action = inst.bufferedaction
        inst.sg.statemem.remote = remote
    end,

    timeline =
    {
        TimeEvent(15 * FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("meta4/winona_remote/click")
        end),

        TimeEvent(25 * FRAMES, function(inst)
            inst:PerformBufferedAction()
        end),

        TimeEvent(30 * FRAMES, function(inst)
            inst.sg:RemoveStateTag("busy")
            local remote = inst.sg.statemem.remote
            if remote then
                if remote.fns == "remote_taunt" then
                    remote:robotfn()
                end
                if remote.fns == "remote_music" then
		            remote.musicevent:push()
                end
                if remote.fns == "remote_light" then
		            remote:lightfn()
                end
            end
        end),
    },

    events =
    {
        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg:GoToState("idle", true)
            end
        end),
    },

    onexit = function(inst)
        if inst.bufferedaction == inst.sg.statemem.action and
        (inst.components.playercontroller == nil or inst.components.playercontroller.lastheldaction ~= inst.bufferedaction) then
            inst:ClearBufferedAction()
        end
    end,
}

local alice_remote_client = State{
    name = "alice_remote",
	tags = {"doing", "busy", "canrotate", "nointerrupt", "nomorph", "nopredict"},
    server_states = { "alice_remote" },

    onenter = function(inst)
		inst.components.locomotor:Stop()
		inst.components.locomotor:Clear()
        inst.AnimState:PlayAnimation("remote_guge")
        inst:PerformPreviewBufferedAction()
        inst.sg:SetTimeout(TIMEOUT)
		if inst.components.playercontroller ~= nil then
			inst.components.playercontroller:Enable(false)
		end
    end,

    timeline =
    {
        TimeEvent(15 * FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("meta4/winona_remote/click")
        end),
    },

    events =
    {
        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg:GoToState("idle", true)
            end
        end),
    },
    
    onupdate = function(inst)
        if inst.sg:ServerStateMatches() then
            if inst.entity:FlattenMovementPrediction() then
                inst.sg:GoToState("idle", "noanim")
            end
        elseif inst.bufferedaction == nil then
            inst.sg:GoToState("idle", true)
        end
    end,

    ontimeout = function(inst)
        inst:ClearBufferedAction()
        inst.sg:GoToState("idle", true)
    end,
}

AddStategraphState("wilson", alice_remote)
AddStategraphState("wilson_client", alice_remote_client)

-----------------------------------------------------
------------------------bati-------------------------
-----------------------------------------------------
local controltable = {
    ["knockback"] = true,
    ["mindcontrolled"] = true,
    ["devoured"] = true,
    ["repelled"] = true,
    ["startled"] = true,
    ["snared"] = true,
    ["attacked"] = true,
    ["suspended"] = true,
    ["feetslipped"] = true,
    ["consumehealthcost"] = true,
    ["onfallinvoid"] = true,
    ["toolbroke"] = true,
    ["armorbroke"] = true,
    ["knockedout"] = true,
}

local oldPushEvent = EntityScript.PushEvent
EntityScript.PushEvent = function(self, event, data, ...)
    if controltable[event] then
        if self and self:HasTag("alice_bati") then
            return
        end
    end
    return oldPushEvent(self, event, data, ...)
end

local oldHandleEvent = State.HandleEvent
State.HandleEvent = function(self, sg, eventname, data, ...)
    if controltable[sg] then
        if self.inst and self.inst:HasTag("alice_bati") then
            return
        end
    end
    return oldHandleEvent(self, sg, eventname, data, ...)
=======
GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})

--蓄力移动
local function IsDirectWalking(inst)
	if inst.components.playercontroller then
		if inst.components.playercontroller.directwalking then
			return true
		elseif inst.components.playercontroller:GetRemoteDirectVector() ~= nil then
			return true
		end
	end
	return false
end

local function RunOrStop(inst)
    if not inst.sg:HasStateTag("alice_shot") then
		return
	end

	if inst.sg.statemem.directwalking then
		inst.sg:AddStateTag("moving")
		inst.sg:AddStateTag("running")
		inst.components.locomotor:RunForward()
        if not inst.AnimState:IsCurrentAnimation("alice_powershot_loop") then
			inst.AnimState:PlayAnimation("alice_powershot_loop", true)
        end
	else
		inst.sg:RemoveStateTag("moving")
		inst.sg:RemoveStateTag("running")
		inst.sg.mem.footsteps = 0
		inst.components.locomotor:Stop()
        if not inst.AnimState:IsCurrentAnimation("alice_powershot_loop1") then
			inst.AnimState:PlayAnimation("alice_powershot_loop1", true)
        end
	end
end

local function CommonUpdate(inst, dt)
	inst.sg.statemem.directwalking = IsDirectWalking(inst)
	RunOrStop(inst)
end

local function WalkPostInit(self)
	local locomote = self.events["locomote"]
	local old_fn = locomote.fn
	function locomote.fn(inst, data)
		if inst.sg:HasStateTag("alice_shot") then
			return
		end
		return old_fn(inst, data)
	end
end

AddStategraphPostInit("wilson", WalkPostInit)
AddStategraphPostInit("wilson_client", WalkPostInit)

local old_CASTAOE = ACTIONS.CASTAOE.fn
ACTIONS.CASTAOE.fn = function(act)
    if act.invobject ~= nil and act.invobject:HasTag("lightsword") then
        return true
    end
    return old_CASTAOE(act)
end

--Hooksg
local VAILDMODE = {
    FAST = {1, 2,},
    CHARGE = {3, 4},
}

local function Hooklightsword(sg)
    local old_caseaoe = sg.actionhandlers[ACTIONS.CASTAOE].deststate
    sg.actionhandlers[ACTIONS.CASTAOE].deststate = function(inst, action)
        local invobject = action.invobject
        local doer = action.doer
        if invobject and invobject:HasTag("lightsword") and invobject.components.alice_sword then
            local mode = invobject.components.alice_sword:GetCurrentMode() or 0
            if not invobject.components.alice_sword:Checkfiniteuses() then
                if doer and doer.components.talker then
                    doer.components.talker:Say(STRINGS.ACTIONS.LIGHTSWORD.NOFINITINESS)
                end
                return false
            end
            -- 蓄力还在CD
            if mode == 3 and invobject:HasTag("charging") then
                if doer and doer.components.talker then
                    doer.components.talker:Say(STRINGS.ACTIONS.LIGHTSWORD.CHARGECD)
                end
                return false
            end
            -- 电池耐久不足
            if mode == 0 then
                if doer and doer.components.talker then
                    doer.components.talker:Say(STRINGS.ACTIONS.LIGHTSWORD.NO_ENABLE)
                end
                return false
            elseif table.contains(VAILDMODE.FAST, mode) then
                if doer then
                    doer.firstshot = true
                end
                return "alice_shot_fast" 
            elseif table.contains(VAILDMODE.CHARGE, mode) then
                return "alice_charge_pre"
            end
        end
        return old_caseaoe(inst, action)
    end
end

local function Hooklightsword_clinet(sg)
    local old_caseaoe = sg.actionhandlers[ACTIONS.CASTAOE].deststate
    sg.actionhandlers[ACTIONS.CASTAOE].deststate = function(inst, action)
        local invobject = action.invobject
        local doer = action.doer
        if invobject and invobject:HasTag("lightsword") and invobject.replica.alice_sword then
            local mode = invobject.replica.alice_sword:GetCurrentMode() or 0

            if mode == 0 then
                return false
            elseif table.contains(VAILDMODE.FAST, mode) then
                if doer then
                    doer.firstshot = true
                end
                return "alice_shot_fast" 
            elseif table.contains(VAILDMODE.CHARGE, mode) then
                return "alice_charge_pre"
            end
        end
        return old_caseaoe(inst, action)
    end
end

AddStategraphPostInit("wilson", Hooklightsword)
AddStategraphPostInit("wilson_client", Hooklightsword_clinet)

--RPC
ALC_UpdateAOETargeting = function(player, cancel)
    local controller = player and player.components.playercontroller
    if controller and cancel then
        controller:CancelAOETargeting()
    end
end

AddClientModRPCHandler("alice", "UpdateAOETargeting", function(cancel)
    ALC_UpdateAOETargeting(ThePlayer, cancel)
end)

local function CancelAOETargeting(inst)
    ALC_UpdateAOETargeting(inst, true)
    SendModRPCToClient(CLIENT_MOD_RPC["alice"]["UpdateAOETargeting"], inst.userid, true)
end

local function SetAOETargetingScale(inst)
    ALC_UpdateAOETargeting(inst, nil)
    SendModRPCToClient(CLIENT_MOD_RPC["alice"]["UpdateAOETargeting"], inst.userid, nil)
end

local function GetWeapon_Master(inst)
    return inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
end

local function GetWeapon_Client(inst)
    return inst.replica.inventory and inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
end

-----------------------------------------------------
-------------------alice_charge_pre------------------
-----------------------------------------------------

local alice_charge_pre = State{
        name = "alice_charge_pre",
        tags = { "moving", "running", "alice_shot", "busy"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("alice_powershot_pre")
        end,
        
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.alc_mousepos = nil
                    local equip = GetWeapon_Master(inst)
                    if equip and equip.components.alice_sword:GetCurrentMode() == 3 then
                        inst.sg:GoToState("alice_charge_loop")
                    else
                        inst.sg:GoToState("alice_shot_fire")
                    end
                end
            end),
        },
        
        onexit = function(inst)
            inst:ClearBufferedAction()
        end,
    }
----------------client----------------
local alice_charge_pre_client = State{
        name = "alice_charge_pre",
        tags = { "moving", "running", "alice_shot", "busy"},
		server_states = { "alice_charge_pre"},

        onenter = function(inst)
            local action = inst:GetBufferedAction()

            if action ~= nil then
                inst:PerformPreviewBufferedAction()
            end

            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("alice_powershot_pre")
			inst.sg:SetTimeout(2)
        end,
        
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.alc_mousepos = nil
                    local equip = GetWeapon_Client(inst)
                    if equip and equip.replica.alice_sword:GetCurrentMode() == 3 then
                        inst.sg:GoToState("alice_charge_loop")
                    else
                        inst.sg:GoToState("alice_shot_fire")
                    end
                end
            end),

            EventHandler("lightsword_nofinitiness", function(inst)
                inst.sg:GoToState("idle")
            end),
        },

        ontimeout = function(inst)
			inst:ClearBufferedAction()
			inst.sg:GoToState("idle", true)
		end,

        onexit = function(inst)
            inst:ClearBufferedAction()
        end,
    }

AddStategraphState("wilson", alice_charge_pre)
AddStategraphState("wilson_client", alice_charge_pre_client)

-----------------------------------------------------
-------------------alice_shot_fire-------------------
-----------------------------------------------------

local alice_shot_fire = State{
        name = "alice_shot_fire",
        tags = { "doing", "alice_shot", "moving", "running"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("alice_powershot_loop", true)
            inst:AddTag("alice_shot")

            local equip = GetWeapon_Master(inst)
            local damage = 0
            if equip and equip:HasTag("lightsword") then
                equip:AddTag("fireatk")
                equip.components.alice_sword.shotmode = 4
                damage = equip.components.alice_sword:GeDamage()
            end

            if inst.alc_firefx == nil then
                inst.alc_firefx = SpawnPrefab("laserthrower_fx")
                inst.alc_firefx:InitDamage(damage)
                inst.alc_firefx:SetFlamethrowerAttacker(inst)
                inst.alc_firefx:UpdatePosition()
            end
            RunOrStop(inst)
        end,

        onexit = function(inst)
            inst:ClearBufferedAction()
            inst.alc_lmb = nil
            inst:RemoveTag("alice_shot")
            if inst.alc_firefx ~= nil then
                inst.alc_firefx:KillFX()
                inst.alc_firefx = nil
            end
            local equip = GetWeapon_Master(inst)
            if equip then
                equip:RemoveTag("fireatk")
            end
        end,

        onupdate = function(inst)
			CommonUpdate(inst, dt)
            local equip = GetWeapon_Master(inst)
            if equip and equip.components.alice_sword then
                equip.components.alice_sword:DoItemUse()
            end
            if inst.alc_lmb == "up" or not (equip and equip.components.alice_sword and equip.components.alice_sword:GetCurrentMode() == 4 
                and equip.components.alice_sword:Checkfiniteuses()) then
                inst.sg:GoToState("idle")
            end
            if inst.alc_mousepos ~= nil then
                inst:ForceFacePoint(inst.alc_mousepos)
            end
            SetAOETargetingScale(inst)
        end,
    }

----------------client----------------

local alice_shot_fire_client = State{
        name = "alice_shot_fire",
        tags = { "doing", "alice_shot", "moving", "running"},
		server_states = { "alice_shot_fire"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("alice_powershot_loop", true)

            RunOrStop(inst)
        end,

        onexit = function(inst)
            inst.alc_lmb = nil
        end,

        onupdate = function(inst)
			CommonUpdate(inst, dt)

            if inst.alc_mousepos ~= nil then
                inst:ForceFacePoint(inst.alc_mousepos)
            end

			if inst.alc_lmb == "up" then
                inst.sg:GoToState("idle")
            end
        end,

        events =
        {
            EventHandler("lightsword_nofinitiness", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    }

AddStategraphState("wilson", alice_shot_fire)
AddStategraphState("wilson_client", alice_shot_fire_client)

-----------------------------------------------------
------------------alice_charge_loop------------------
-----------------------------------------------------

local alice_charge_loop = State{
        name = "alice_charge_loop",
        tags = {"alice_shot", "moving", "running"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("alice_powershot_loop", true)
            inst:AddTag("alice_shot")
            if inst:HasTag("alice") then
                inst.SoundEmitter:PlaySound("alicesound/alicesound/yosi", "alc_chargevoice", .5)
            end
            
            RunOrStop(inst)
        end,

        onexit = function(inst)
            inst.alc_lmb = nil
            inst.alc_canshot = nil
            inst:RemoveTag("alice_shot")
            if inst:HasTag("alice") then
                inst.SoundEmitter:KillSound("alc_chargevoice")
                inst.SoundEmitter:KillSound("alice_charge2")
            end
        end,

        onupdate = function(inst)
			CommonUpdate(inst, dt)
            local equip = GetWeapon_Master(inst)
            if inst.alc_lmb == "up" or not (equip and equip.components.alice_sword and equip.components.alice_sword:GetCurrentMode() == 3) then
                if inst.alc_canshot then
                    inst.alc_lmb = nil
                    inst.alc_canshot = nil
                    inst.sg:GoToState("alice_charge_pst")
                else
                    inst.sg:GoToState("idle")
                end
            end
            if inst.alc_mousepos ~= nil then
                inst:ForceFacePoint(inst.alc_mousepos)
            end
            SetAOETargetingScale(inst)
        end,

        timeline=
        {
            TimeEvent(15 * FRAMES, function(inst) 
                inst.SoundEmitter:PlaySound("alicesound/alicesound/alice_charge2", "alice_charge2", .5)
            end),
            TimeEvent(55 * FRAMES, function(inst) 
                inst.alice_charge_fx = SpawnPrefab("alice_charge_fx")
                inst.alice_charge_fx.entity:AddFollower()
                inst.alice_charge_fx.Follower:FollowSymbol(inst.GUID, "wepon", 250, 0, 0)
            end),
            TimeEvent(60 * FRAMES, function(inst) 
                inst.alc_canshot = true 
            end),
        },
    }

----------------client----------------

local alice_charge_loop_client = State{
        name = "alice_charge_loop",
        tags = {"alice_shot", "moving", "running"},
		server_states = { "alice_charge_loop"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("alice_powershot_loop", true)
            
            RunOrStop(inst)
        end,

        onexit = function(inst)
            inst.alc_lmb = nil
        end,

        onupdate = function(inst)
			CommonUpdate(inst, dt)

            local equip = GetWeapon_Client(inst)
            if inst.alc_lmb == "up" or not (equip and equip.replica.alice_sword and equip.replica.alice_sword:GetCurrentMode() == 3) then
                if inst.alc_canshot then
                    inst.alc_lmb = nil
                    inst.alc_canshot = nil
                    inst.sg:GoToState("alice_charge_pst")
                else
                    inst.sg:GoToState("idle")
                end
            end
            if inst.alc_mousepos ~= nil then
                inst:ForceFacePoint(inst.alc_mousepos)
            end
        end,

        timeline=
        {
            TimeEvent(60 * FRAMES, function(inst) 
                inst.alc_canshot = true 
            end),
        },
    }

AddStategraphState("wilson", alice_charge_loop)
AddStategraphState("wilson_client", alice_charge_loop_client)

-----------------------------------------------------
-------------------alice_charge_pst------------------
-----------------------------------------------------

local alice_charge_pst = State{
        name = "alice_charge_pst",
        tags = { "moving", "running", "busy", "alice_shot"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("alice_powershot")
            CancelAOETargeting(inst)
            inst:AddTag("alice_shot")
            
            if inst:HasTag("alice") then
                inst.SoundEmitter:PlaySound("alicesound/alicesound/hikari", "alc_shotvoice", .5)
            end
        end,

        onexit = function(inst)
            inst:RemoveTag("alice_shot")
            if inst:HasTag("alice") then
                inst.SoundEmitter:KillSound("alc_shotvoice")
            end
        end,

        timeline=
        {
            TimeEvent(2*FRAMES, function(inst) 
                local equip = GetWeapon_Master(inst)
                if equip ~= nil and equip.components.alice_sword and equip.components.rechargeable then
                    equip.components.alice_sword:LaunchLaser(inst, inst.alc_mousepos)
                    equip.components.rechargeable:Discharge(TUNING.LIGHTSWORDCD)
                end 
            end),
        },

        events=
        {
            EventHandler("animover", function(inst) 
                inst.sg:GoToState("idle")
            end),
        },
    }

----------------client----------------

local alice_charge_pst_client = State{
        name = "alice_charge_pst",
        tags = { "moving", "running", "busy", "alice_shot"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("alice_powershot")
        end,

        events=
        {
            EventHandler("animover", function(inst) 
                inst.sg:GoToState("idle")
            end),
        },
    }

AddStategraphState("wilson", alice_charge_pst)
AddStategraphState("wilson_client", alice_charge_pst_client)

-----------------------------------------------------
-------------------alice_shot_fast-------------------
-----------------------------------------------------

local alice_shot_fast = State{
        name = "alice_shot_fast",
        tags = { "doing", "busy", "alice_shot"},

        onenter = function(inst)
            inst:PerformBufferedAction()
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("alice_atk")
            inst:AddTag("alice_shot")
        end,

        onexit = function(inst)
            inst:ClearBufferedAction()
            inst.firstshot = false
        end,
  
        onupdate = function(inst)
            if inst.alc_mousepos ~= nil then
                inst:ForceFacePoint(inst.alc_mousepos)
            end

            local equip = GetWeapon_Master(inst)
            if (not inst.firstshot and inst.alc_lmb == "up") or 
                not (equip and equip.components.alice_sword and table.contains(VAILDMODE.FAST, equip.components.alice_sword:GetCurrentMode())) then
                inst.alc_lmb = nil
                inst.sg:GoToState("idle")
            end
        end,

        timeline=
        {
            TimeEvent(9 * FRAMES, function(inst) 
                local equip = GetWeapon_Master(inst)
                if equip ~= nil and equip.components.alice_sword ~= nil then
                    equip.components.alice_sword:Launch(inst, inst.alc_mousepos)
                end
                inst:RemoveTag("alice_shot")
            end),
        },

        events=
        {
            EventHandler("animover", function(inst)  --21FRAMES
                inst.sg:GoToState("alice_shot_fast")
            end ),
        },

    }
    
----------------client----------------

local alice_shot_fast_client = State{
        name = "alice_shot_fast",
        tags = { "doing", "busy", "alice_shot"},
		server_states = { "alice_shot_fast" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst:PerformPreviewBufferedAction()
            inst.AnimState:PlayAnimation("alice_atk")
        end,

        onexit = function(inst)
            inst:ClearBufferedAction()
            inst.firstshot = false
        end,
  
        onupdate = function(inst)
            if inst.alc_mousepos ~= nil then
                inst:ForceFacePoint(inst.alc_mousepos)
            end

            local equip = GetWeapon_Client(inst)
            if (not inst.firstshot and inst.alc_lmb == "up") or 
                not (equip and equip.replica.alice_sword and table.contains(VAILDMODE.FAST, equip.replica.alice_sword:GetCurrentMode())) then
                inst.alc_lmb = nil
                inst.sg:GoToState("idle")
            end
        end,
        
        events=
        {
            EventHandler("animover", function(inst)  --21FRAMES
                inst.sg:GoToState("alice_shot_fast")
            end ),
            
            EventHandler("lightsword_nofinitiness", function(inst)
                inst.sg:GoToState("idle")
            end),
        },

    }

AddStategraphState("wilson", alice_shot_fast)
AddStategraphState("wilson_client", alice_shot_fast_client)

-----------------------------------------------------
--------------------猴子女王给蓝图--------------------
-----------------------------------------------------
AddStategraphPostInit("monkeyqueen", function(sg)
    local state = sg.states["getitem"]
    local old_onenter = state.onenter
    
    state.onenter = function(inst, data, ...)
        if old_onenter then
            old_onenter(inst, data, ...)
        end
        if data and data.item and data.giver and data.giver.prefab == "alice" then
            local function spawnloot(inst)
                local loot = SpawnPrefab("alice_mode2_blueprint")
                inst.components.lootdropper:FlingItem(loot)
                inst:RemoveEventCallback("animover", spawnloot)
            end
            inst:ListenForEvent("animover", spawnloot)
        end
    end
end)


-----------------------------------------------------
--------------------alice_remote---------------------
-----------------------------------------------------
local alice_remote = State{
    name = "alice_remote",
	tags = {"doing", "busy", "canrotate", "nointerrupt", "nomorph", "nopredict"},

    onenter = function(inst, remote)
		inst.components.locomotor:Stop()
		inst.components.locomotor:Clear()
        inst.AnimState:PlayAnimation("remote_guge")

        inst.sg.statemem.action = inst.bufferedaction
        inst.sg.statemem.remote = remote
    end,

    timeline =
    {
        TimeEvent(15 * FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("meta4/winona_remote/click")
        end),

        TimeEvent(25 * FRAMES, function(inst)
            inst:PerformBufferedAction()
        end),

        TimeEvent(30 * FRAMES, function(inst)
            inst.sg:RemoveStateTag("busy")
            local remote = inst.sg.statemem.remote
            if remote then
                if remote.fns == "remote_taunt" then
                    remote:robotfn()
                end
                if remote.fns == "remote_music" then
		            remote.musicevent:push()
                end
                if remote.fns == "remote_light" then
		            remote:lightfn()
                end
            end
        end),
    },

    events =
    {
        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg:GoToState("idle", true)
            end
        end),
    },

    onexit = function(inst)
        if inst.bufferedaction == inst.sg.statemem.action and
        (inst.components.playercontroller == nil or inst.components.playercontroller.lastheldaction ~= inst.bufferedaction) then
            inst:ClearBufferedAction()
        end
    end,
}

local alice_remote_client = State{
    name = "alice_remote",
	tags = {"doing", "busy", "canrotate", "nointerrupt", "nomorph", "nopredict"},
    server_states = { "alice_remote" },

    onenter = function(inst)
		inst.components.locomotor:Stop()
		inst.components.locomotor:Clear()
        inst.AnimState:PlayAnimation("remote_guge")
        inst:PerformPreviewBufferedAction()
        inst.sg:SetTimeout(TIMEOUT)
		if inst.components.playercontroller ~= nil then
			inst.components.playercontroller:Enable(false)
		end
    end,

    timeline =
    {
        TimeEvent(15 * FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("meta4/winona_remote/click")
        end),
    },

    events =
    {
        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg:GoToState("idle", true)
            end
        end),
    },
    
    onupdate = function(inst)
        if inst.sg:ServerStateMatches() then
            if inst.entity:FlattenMovementPrediction() then
                inst.sg:GoToState("idle", "noanim")
            end
        elseif inst.bufferedaction == nil then
            inst.sg:GoToState("idle", true)
        end
    end,

    ontimeout = function(inst)
        inst:ClearBufferedAction()
        inst.sg:GoToState("idle", true)
    end,
}

AddStategraphState("wilson", alice_remote)
AddStategraphState("wilson_client", alice_remote_client)

-----------------------------------------------------
------------------------bati-------------------------
-----------------------------------------------------
local controltable = {
    ["knockback"] = true,
    ["mindcontrolled"] = true,
    ["devoured"] = true,
    ["repelled"] = true,
    ["startled"] = true,
    ["snared"] = true,
    ["attacked"] = true,
    ["suspended"] = true,
    ["feetslipped"] = true,
    ["consumehealthcost"] = true,
    ["onfallinvoid"] = true,
    ["toolbroke"] = true,
    ["armorbroke"] = true,
    ["knockedout"] = true,
}

local oldPushEvent = EntityScript.PushEvent
EntityScript.PushEvent = function(self, event, data, ...)
    if controltable[event] then
        if self and self:HasTag("alice_bati") then
            return
        end
    end
    return oldPushEvent(self, event, data, ...)
end

local oldHandleEvent = State.HandleEvent
State.HandleEvent = function(self, sg, eventname, data, ...)
    if controltable[sg] then
        if self.inst and self.inst:HasTag("alice_bati") then
            return
        end
    end
    return oldHandleEvent(self, sg, eventname, data, ...)
>>>>>>> 23121469d84d981b602c8a05fcc5a165255f6831
end