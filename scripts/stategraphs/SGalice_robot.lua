require("stategraphs/commonstates")

local function SetContainerCanBeOpened(inst, canbeopened)
	if canbeopened then
		if inst.components.container ~= nil then
			inst.components.container.canbeopened = true
		elseif inst.components.container_proxy ~= nil and inst.components.container_proxy:GetMaster() ~= nil then
			inst.components.container_proxy:SetCanBeOpened(true)
		end
	elseif inst.components.container ~= nil then
		inst.components.container:Close()
		inst.components.container.canbeopened = false
	elseif inst.components.container_proxy ~= nil then
		inst.components.container_proxy:Close()
		inst.components.container_proxy:SetCanBeOpened(false)
	end
end

local actionhandlers =
{
}

local events=
{
    CommonHandlers.OnStep(),
    CommonHandlers.OnSleep(),
    CommonHandlers.OnLocomote(false,true),
    CommonHandlers.OnHop(),
	CommonHandlers.OnSink(),
    CommonHandlers.OnFallInVoid(),
    EventHandler("attacked", function(inst)
        if inst.components.health and not inst.components.health:IsDead() and not inst.sg:HasStateTag("devoured") then
            --inst.sg:GoToState("hit")
            inst.SoundEmitter:PlaySound(inst.sounds.hurt)
        end
    end),
    EventHandler("death", function(inst) inst.sg:GoToState("death") end),
}

local states=
{
    State{
        name = "idle",
        tags = {"idle", "canrotate"},

        onenter = function(inst, pushanim)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("idle", true)
        end,

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
   },

   State{
        name = "transition",
        tags = {"busy"},
        onenter = function(inst)
            inst.Physics:Stop()

            SetContainerCanBeOpened(inst, false)

            --Create light shaft
            inst.sg.statemem.light = SpawnPrefab("chesterlight")
            inst.sg.statemem.light.Transform:SetPosition(inst:GetPosition():Get())
            inst.sg.statemem.light:TurnOn()

            inst.SoundEmitter:PlaySound("dontstarve/creatures/chester/raise")
        end,

        onexit = function(inst)
            --Add ability to open chester again.
            SetContainerCanBeOpened(inst, true)
            --Remove light shaft
            if inst.sg.statemem.light then
                inst.sg.statemem.light:TurnOff()
            end
        end,

        timeline =
        {
            TimeEvent(56*FRAMES, function(inst)
                local x, y, z = inst.Transform:GetWorldPosition()
                SpawnPrefab("chester_transform_fx").Transform:SetPosition(x, y + 1, z)
            end),
            TimeEvent(60*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound( inst.sounds.pop )
                if inst.MorphChester ~= nil then
                    inst:MorphChester()
                    SetContainerCanBeOpened(inst, false)
                end
                inst.sg:GoToState("idle") 
            end),
        },
    },
    State{
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
			SetContainerCanBeOpened(inst, false)
			if inst.components.container ~= nil then
				inst.components.container:DropEverything()
			end

            inst.SoundEmitter:PlaySound(inst.sounds.death)

            --inst.AnimState:PlayAnimation("death")
            inst.Physics:Stop()
            RemovePhysicsColliders(inst)
        end,
    },
    State{
		name = "restart",
        tags = {"busy", "nointerrupt"},

        onenter = function(inst, cb)
            inst.AnimState:PlayAnimation("restar")
		end,

        events=
        {
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
        },
    },
}

local walkanims = {
    startwalk = "run_pre",
    walk = "run_loop",
    stopwalk = "run_loop",
}

CommonStates.AddWalkStates(states, {
    walktimeline =
    {
        TimeEvent(1*FRAMES, function(inst)
            --inst.SoundEmitter:PlaySound( inst.sounds.boing )
            inst.components.locomotor:RunForward()
        end),

        TimeEvent(14*FRAMES, function(inst)
            PlayFootstep(inst)
            inst.components.locomotor:WalkForward()
        end),
    },


}, walkanims, true)

-- TODO
local hopanim = { 
    pre = "jump_pre",
    loop = "junp_loop",
    pst = "junp_pst",
}

CommonStates.AddHopStates(states, true, hopanim,
{

    hop_pre =
    {
        TimeEvent(0, function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/common/dropGeneric")
        end),
    }
})
CommonStates.AddSinkAndWashAshoreStates(states)
CommonStates.AddVoidFallStates(states)

return StateGraph("chester", states, events, "idle", actionhandlers)

