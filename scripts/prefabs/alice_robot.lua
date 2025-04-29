local assets=
{ 
	Asset("ANIM", "anim/jiqiren.zip"), 
	Asset("ANIM", "anim/alice_robottfx.zip"), 
}

local brain = require "brains/alice_robotbrain"

local prefabs = {}

local sounds =
{
    hurt = "dontstarve/creatures/knight/hurt",
    death = "dontstarve/creatures/knight/death",
    pant = "dontstarve/creatures/chester/pant",
    open = "dontstarve/creatures/chester/open",
    close = "dontstarve/creatures/chester/close",
    pop = "dontstarve/creatures/chester/pop",
}

local ChesterStateNames =
{
	"NORMAL",
	"SNOW",
}

local TAUNT_DIST = 24   -- 嘲讽距离有改动
local TAUNT_PERIOD = 1  -- 嘲讽间隔

local ChesterState = table.invert(ChesterStateNames)

local function ShouldKeepTarget()
    return false -- chester can't attack, and won't sleep if he has a target
end

local function OnOpen(inst)
    -- do nothing
end

local function OnClose(inst)
    -- do nothing
end

local function MorphSnowChester(inst)
    inst.components.preserver:SetPerishRateMultiplier(TUNING.FISH_BOX_PRESERVER_RATE)--改为反鲜

	inst.sg.mem.isshadow = nil
	inst._chesterstate:set(ChesterState.SNOW)
end

local function OnUpgrade(inst, performer, upgraded_from_item)
    local numupgrades = inst.components.upgradeable.numupgrades
    if numupgrades == 1 then
        inst._chestupgrade_stacksize = true
        if inst.components.container ~= nil then -- NOTES(JBK): The container component goes away in the burnt load but we still want to apply builds.
            inst.components.container:Close()
            inst.components.container:EnableInfiniteStackSize(true)
        end
        if upgraded_from_item then
            local x, y, z = inst.Transform:GetWorldPosition()
            local fx = SpawnPrefab("chestupgrade_stacksize_fx")
            fx.Transform:SetPosition(x, y, z)
        end
    end
    inst.components.upgradeable.upgradetype = nil
end

local function ondeath(inst, data)
    if inst.components.upgradeable ~= nil and inst.components.upgradeable.numupgrades > 0 then
        if inst.components.lootdropper ~= nil then
            --inst.components.lootdropper:SpawnLootPrefab("chestupgrade_stacksize") -- 死亡返还套件
        end
    end
end

local function CanMorph(inst)
    if inst._chesterstate:value() ~= ChesterState.NORMAL then
        return false
    end

    local container = inst.components.container
    if container == nil or container:IsOpen() then
        return false
    end

    local canSnow = true

    for i = 1, container:GetNumSlots() do
        local item = container:GetItemInSlot(i)
        if item == nil then
            return false
        end

        canSnow = canSnow and item.prefab == "ice"--改为冰，因为要的蓝宝石太多了

        if not canSnow then
            return false
        end
    end

    return canSnow
end

local function CheckForMorph(inst)
    local canSnow = CanMorph(inst)
    if canSnow then
        inst.sg:GoToState("transition")
    end
end

local function DoMorph(inst, fn)
    inst.MorphChester = nil
    inst:RemoveEventCallback("onclose", CheckForMorph)
    fn(inst)
end

local function MorphChester(inst)
    local canSnow = CanMorph(inst)
    if not canSnow then
        return
    end

    local container = inst.components.container
    for i = 1, container:GetNumSlots() do
        container:RemoveItem(container:GetItemInSlot(i)):Remove()
    end

    DoMorph(inst, MorphSnowChester)
end

local function IsTauntable(inst, target)
    return not (target.components.health ~= nil and target.components.health:IsDead())
        and target.components.combat ~= nil
        and not target.components.combat:TargetIs(inst)
        and target.components.combat:CanTarget(inst)
        and (   
                (   
                    target:HasTag("shadowcreature")  or target:HasTag("monster") or
                    (
                        target:HasTag("hostile") and
                        (
                            target:HasTag("brightmare") or 
                            target:HasTag("lunar_aligned") or 
                            target:HasTag("shadow_aligned")
                        ) 
                    )   
                ) or
                (   target.components.combat:HasTarget() and
                    (   target.components.combat.target:HasTag("player") or
                        (target.components.combat.target:HasTag("companion") and target.components.combat.target.prefab ~= inst.prefab)
                    )
                )
            )
end

local TAUNT_MUST_TAGS = { "_combat" }
local TAUNT_CANT_TAGS = { "INLIMBO", "player", "companion", "notaunt"}
local TAUNT_ONEOF_TAGS = { "locomotor", "lunarthrall_plant" }
local function TauntCreatures(inst)
    if inst:IsValid() and not inst.components.health:IsDead() then
        local x, y, z = inst.Transform:GetWorldPosition()
        for i, v in ipairs(TheSim:FindEntities(x, y, z, TAUNT_DIST, TAUNT_MUST_TAGS, TAUNT_CANT_TAGS, TAUNT_ONEOF_TAGS)) do
            if IsTauntable(inst, v) then
                v.components.combat:SetTarget(inst)
            end
        end
    end
end

local function StartTaunt(inst)
    if inst._taunttask == nil then
        inst._taunttask = inst:DoPeriodicTask(TAUNT_PERIOD, TauntCreatures, 0)
    end
    
    if inst.tauntfx == nil then
        inst.tauntfx = SpawnPrefab("alice_robotfx")
        inst.tauntfx.entity:SetParent(inst.entity)
        inst.tauntfx.Transform:SetPosition(0, 0.7, 0)
    end
end

local function EndTaunt(inst)
    if inst._taunttask ~= nil then
        inst._taunttask:Cancel()
        inst._taunttask = nil
    end

    if inst.tauntfx ~= nil then
        inst.tauntfx:Remove()
        inst.tauntfx = nil
    end
end

local function LinkToPlayer(inst, player)
    inst._playerlink = player
    inst.components.follower:SetLeader(player)

    inst:ListenForEvent("onremove", inst._onlostplayerlink, player)
end

local function OnSave(inst, data)
	data.ChesterState = ChesterStateNames[inst._chesterstate:value()]

	data._taunttask = inst._taunttask ~= nil
end

local function OnLoad(inst, data)
    -- 箱子升级记录
	local chester_state = data ~= nil and ChesterState[data.ChesterState] or nil
	if chester_state == ChesterState.SNOW then
        DoMorph(inst, MorphSnowChester)
    end
    if inst.components.upgradeable ~= nil and inst.components.upgradeable.numupgrades > 0 then
        OnUpgrade(inst)
    end

    -- 嘲讽记录
    if data._taunttask then
        inst:StartTaunt()
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

	inst:AddTag("alice_robot")
	inst:AddTag("companion")
	inst:AddTag("noauradamage")
	inst:AddTag("notraptrigger")

    MakeCharacterPhysics(inst, 75, .5)
    inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.WORLD)
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)

    inst.AnimState:SetBank("jiqiren")
    inst.AnimState:SetBuild("jiqiren")
    inst.AnimState:PlayAnimation("idle", true)

    inst.DynamicShadow:SetSize(2, 1.5)

    inst.Transform:SetSixFaced()

    inst.entity:SetPristine()

	inst._chesterstate = net_tinybyte(inst.GUID, "chester._chesterstate", "chesterstatedirty")
	inst._chesterstate:set(ChesterState.NORMAL)

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "chester_body"
    inst.components.combat:SetKeepTargetFunction(ShouldKeepTarget)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.ALICE_ROBOT_HEALTH)
    inst.components.health:StartRegen(TUNING.ALICE_ROBOT_HEALTH_REGEN_AMOUNT, TUNING.ALICE_ROBOT_HEALTH_REGEN_PERIOD)

    inst:AddComponent("inspectable")
    
    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = 8
    inst.components.locomotor.runspeed = 16
    inst.components.locomotor:SetAllowPlatformHopping(true)
    
    inst:AddComponent("embarker")
    inst:AddComponent("drownable")

    inst:AddComponent("lootdropper")

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("alice_robot")
    inst.components.container.onopenfn = OnOpen
    inst.components.container.onclosefn = OnClose
    inst.components.container.skipclosesnd = true
    inst.components.container.skipopensnd = true

    inst:AddComponent("preserver")--new
    inst.components.preserver:SetPerishRateMultiplier(1)


    inst:AddComponent("upgradeable")
    inst.components.upgradeable.upgradetype = UPGRADETYPES.CHEST
    inst.components.upgradeable:SetOnUpgradeFn(OnUpgrade)

    inst:SetStateGraph("SGalice_robot")
    inst.sg:GoToState("idle")

    inst:SetBrain(brain)

    inst:AddComponent("follower")
    
    inst:AddComponent("knownlocations")

    MakeHauntableLaunch(inst)

    inst:ListenForEvent("death", ondeath)
    inst:ListenForEvent("onclose", CheckForMorph)

	inst.OnLoad = OnLoad
	inst.OnSave = OnSave
    inst.sounds = sounds
    inst.MorphChester = MorphChester
    inst.StartTaunt = StartTaunt
    inst.EndTaunt = EndTaunt

    inst.LinkToPlayer = LinkToPlayer
	inst._onlostplayerlink = function(player) inst._playerlink = nil end
    
    inst.persists = false

    return inst
end

----------------------------------
--------------- fx ---------------
----------------------------------

local function fxfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
	inst.entity:AddSoundEmitter()

    inst.AnimState:SetBank("alice_robottfx")
    inst.AnimState:SetBuild("alice_robottfx")
    inst.AnimState:PlayAnimation("taunt", true)

    inst.entity:SetPristine()

    inst:AddTag("NOCLICK")
    inst:AddTag("FX")

    return inst
end

return  Prefab("alice_robot", fn, assets, prefabs),
    Prefab("alice_robotfx", fxfn, assets, prefabs)