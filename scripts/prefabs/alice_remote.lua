require("components/deployhelper") -- TriggerDeployHelpers lives here

local assets =
{
	Asset("ANIM", "anim/alice_remote.zip"),
	Asset("ANIM", "anim/spell_icons_winona.zip"),
    Asset("ATLAS", "images/inventoryimages/alice_remote.xml"),
}

local prefabs =
{
	"alice_robot",
}

local function onremovelight(inst, skip)
	if inst.light then
		inst.light:Remove()
		inst.light = nil
	end

	if not skip and inst.robot ~= nil then
		inst:RemoveEventCallback("onremove", inst._robot_onremove)
		inst.robot:Remove()
	end
end

local ICON_SCALE = .6
local SPELLBOOK_RADIUS = 100
local SPELLBOOK_FOCUS_RADIUS = SPELLBOOK_RADIUS + 2
local MUSIC_BUFF_RANGE = 12


local function ShouldRepeatCast(inst, doer)
	return not inst:HasTag("usesdepleted")
end

local function ElementalVolleySpellFn(inst, doer, pos)
	if inst.components.fueled:IsEmpty() then
		return false, "NO_BATTERY"
	end

	return true
end

local function robotfn(inst)
	local robot = inst.robot
	if robot ~= nil then
		if robot._taunttask then
			robot:EndTaunt()
		else
			robot:StartTaunt()
		end
	end
end

local function lightfn(inst)
	if not inst.light_active then
		inst.light_active = true
		if inst.light == nil then
			inst.light = SpawnPrefab("alice_remote_light")
			inst.light.entity:SetParent(inst.entity)
		end
	else
		inst.light_active = false
		onremovelight(inst, true)
	end
end

local function musicfn(inst)
	if ThePlayer and ThePlayer.musicui then
		ThePlayer.musicui:Open()
	end
end

local function FindPlayer(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
    return FindPlayersInRange(x, y, z, MUSIC_BUFF_RANGE, true)
end

local function SayBuffString(v, str)
	if v.alice_bufftalker ~= nil then
		v.alice_bufftalker:Cancel()
		v.alice_bufftalker = nil
	end

	v.alice_bufftalker = v:DoTaskInTime(3, function() 
		v.components.talker:Say(str)
	end)
end

local function RemoveBuff(inst, key)
	if not inst then
		return
	end

	if key == "combat" and inst.components.combat then
		inst.components.combat.externaldamagemultipliers:RemoveModifier(inst, "alice_music")
	end

	if key == "locomotor" and inst.components.locomotor then
		inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "alice_music")
	end

	if key == "health" and inst.components.health then
		inst.components.health.externalabsorbmodifiers:RemoveModifier(inst, "alice_music")
	end
	inst:RemoveTag("alice_bati")
end

local function DoPlayerDamageBuff(inst)
    local players = FindPlayer(inst)
    if players ~= nil then
        for k, v in pairs(players) do
            if v:IsValid() and v.components.health ~= nil and not v.components.health:IsDead() and not v:HasTag("playerghost") and v.components.combat then
                v.components.combat.externaldamagemultipliers:SetModifier(v, TUNING.ALICE_MUSIC_DAMAGEMULT, "alice_music")

				SayBuffString(v, STRINGS.ALICE_MUSICBUFF.DAMAGE)

				if inst.canceltask1 ~= nil then
					inst.canceltask1:Cancel()
					inst.canceltask1 = nil
				end

				inst.canceltask1 = inst:DoTaskInTime(TUNING.ALICE_MUSIC_DURATION, function()
					RemoveBuff(v, "combat")
				end)
            end
        end
    end
end

local function DoPlayerSpeedBuff(inst)
    local players = FindPlayer(inst)
    if players ~= nil then
        for k, v in pairs(players) do
            if v:IsValid() and v.components.health ~= nil and not v.components.health:IsDead() and not v:HasTag("playerghost") and v.components.locomotor then
                v.components.locomotor:SetExternalSpeedMultiplier(v, "alice_music", TUNING.ALICE_MUSIC_SPEEDMULT)

				SayBuffString(v, STRINGS.ALICE_MUSICBUFF.SPEED)

				if inst.canceltask2 ~= nil then
					inst.canceltask2:Cancel()
					inst.canceltask2 = nil
				end

				inst.canceltask2 = inst:DoTaskInTime(TUNING.ALICE_MUSIC_DURATION, function()
					RemoveBuff(v, "locomotor")
				end)
            end
        end
    end
end

local function AddWorkAttach(inst, target)
    if target.components.workmultiplier == nil then
        target:AddComponent("workmultiplier")
    end
    target.components.workmultiplier:AddMultiplier(ACTIONS.CHOP, TUNING.ALICE_MUSIC_WORKMULT, inst)
    target.components.workmultiplier:AddMultiplier(ACTIONS.MINE, TUNING.ALICE_MUSIC_WORKMULT, inst)
    target.components.workmultiplier:AddMultiplier(ACTIONS.HAMMER, TUNING.ALICE_MUSIC_WORKMULT, inst)
end

local function RemoveWorkAttach(inst, target)
    if target.components.workmultiplier ~= nil then
		target.components.workmultiplier:RemoveMultiplier(ACTIONS.CHOP, inst)
		target.components.workmultiplier:RemoveMultiplier(ACTIONS.MINE, inst)
		target.components.workmultiplier:RemoveMultiplier(ACTIONS.HAMMER, inst)
    end
end

local function DoPlayerWorkBuff(inst)
    local players = FindPlayer(inst)
    if players ~= nil then
        for k, v in pairs(players) do
            if v:IsValid() and v.components.health ~= nil and not v.components.health:IsDead() and not v:HasTag("playerghost") then
                AddWorkAttach(inst, v)

				SayBuffString(v, STRINGS.ALICE_MUSICBUFF.WORK)

				if inst.canceltask3 ~= nil then
					inst.canceltask3:Cancel()
					inst.canceltask3 = nil
				end

				inst.canceltask3 = inst:DoTaskInTime(TUNING.ALICE_MUSIC_DURATION, RemoveWorkAttach, v)
            end
        end
    end
end

local function DoPlayerDenfeceBuff(inst)
    local players = FindPlayer(inst)
    if players ~= nil then
        for k, v in pairs(players) do
            if v:IsValid() and v.components.health ~= nil and not v.components.health:IsDead() and not v:HasTag("playerghost") then
                v.components.health.externalabsorbmodifiers:SetModifier(v, TUNING.ALICE_MUSIC_DEFEMULT, "alice_music")
				v:AddTag("alice_bati")
				SayBuffString(v, STRINGS.ALICE_MUSICBUFF.DEF)

				if inst.canceltask4 ~= nil then
					inst.canceltask4:Cancel()
					inst.canceltask4 = nil
				end

				inst.canceltask4 = inst:DoTaskInTime(TUNING.ALICE_MUSIC_DURATION, function()
					RemoveBuff(v, "health")
				end)
            end
        end
    end
end

local function song_update(inst)
	if inst.playing_sound and inst.playing_sound == TUNING.GROUP_NAME[1] then
		DoPlayerDamageBuff(inst)
	elseif inst.playing_sound and inst.playing_sound == TUNING.GROUP_NAME[2] then
		DoPlayerSpeedBuff(inst)
	elseif inst.playing_sound and inst.playing_sound == TUNING.GROUP_NAME[3] then
		DoPlayerDenfeceBuff(inst)
	elseif inst.playing_sound and inst.playing_sound == TUNING.GROUP_NAME[4] then
		DoPlayerWorkBuff(inst)
	end
end

local function StopPlayingRecord(inst)
	if inst.soundtask then
		inst.soundtask:Cancel()
		inst.soundtask = nil
	end

    if inst._play_song_task then
        inst._play_song_task:Cancel()
        inst._play_song_task = nil
    end

    inst.playing_sound = nil

    if inst._tend_update_task then
        inst._tend_update_task:Cancel()
        inst._tend_update_task = nil
    end

    inst.localsounds.SoundEmitter:KillSound("ragtime")
    inst.localsounds.SoundEmitter:PlaySound("dontstarve/music/gramaphone_end")
end

local function TryToPlayRecord(inst, song)
	if inst.soundtask then
		inst.soundtask:Cancel()
		inst.soundtask = nil
	end

	inst.soundtask = inst:DoTaskInTime(0, function()
		inst.localsounds.SoundEmitter:PlaySound("alicemusic/alicemusic/" .. song, "ragtime", inst.volume)
	end)

    inst.playing_sound = song

    if inst._stop_song_task then
        inst._stop_song_task:Cancel()
        inst._stop_song_task = nil
    end

    inst._tend_update_task = inst:DoPeriodicTask(1, song_update, 3)
end

local function ReticuleTargetAllowWaterFn()
    local player = ThePlayer
    local ground = TheWorld.Map
    local pos = Vector3()
    --Cast range is 30, leave room for error
    --15 is the aoe range
    for r = 10, 0, -.25 do
        pos.x, pos.y, pos.z = player.entity:LocalToWorldSpace(r, 0, 0)
        if ground:IsPassableAtPoint(pos.x, 0, pos.z, true) and not ground:IsGroundTargetBlocked(pos) then
            return pos
        end
    end
    return pos
end

local function StartAOETargeting(inst)
    local playercontroller = ThePlayer.components.playercontroller
    if playercontroller ~= nil then
        playercontroller:StartAOETargetingUsing(inst)
    end
end



local SPELLS =
{
	{
		label = STRINGS.ALICE_REMOTE.LIGHT,
		execute = function() end,
		onselect = function(inst)
			SendModRPCToServer(MOD_RPC["alice"]["remote_light"], inst)
		end,
		atlas = "images/remote/zhaoming.xml",
		normal = "zhaoming.tex",
		clicksound = "meta4/winona_UI/select",
		widget_scale = ICON_SCALE,
	},
	{
		label = STRINGS.ALICE_REMOTE.MUSIC,
		execute = function() end,
		onselect = function(inst)
			SendModRPCToServer(MOD_RPC["alice"]["remote_music"], inst)
		end,
		atlas = "images/remote/yinyue.xml",
		normal = "yinyue.tex",
		clicksound = "meta4/winona_UI/select",
		widget_scale = ICON_SCALE,
	},
	{
		label = STRINGS.ALICE_REMOTE.TAUNT,
		execute = function() end,
		onselect = function(inst)
			SendModRPCToServer(MOD_RPC["alice"]["remote_taunt"], inst)
		end,
		atlas = "images/remote/chaofeng.xml",
		normal = "chaofeng.tex",
		clicksound = "meta4/winona_UI/select",
		widget_scale = ICON_SCALE,
	},
}

local SPELLBOOK_BG =
{
	bank = "spell_icons_winona",
	build = "spell_icons_winona",
	anim = "dpad",
	widget_scale = ICON_SCALE,
}

--------------------------------------------------------------------------
local function SetLedEnabled(inst, enabled)
	if enabled then
		inst.AnimState:OverrideSymbol("led_off", "winona_remote", "led_on")
		inst.AnimState:SetSymbolBloom("led_off")
		inst.AnimState:SetSymbolLightOverride("led_off", 0.5)
		inst.AnimState:SetSymbolLightOverride("winona_remote_parts", 0.14)
	else
		inst.AnimState:ClearOverrideSymbol("led_off")
		inst.AnimState:ClearSymbolBloom("led_off")
		inst.AnimState:SetSymbolLightOverride("led_off", 0)
		inst.AnimState:SetSymbolLightOverride("winona_remote_parts", 0)
	end
end

--------------------------------------------------------------------------
local function HeatFn(inst, observer)
    if inst.light_active then
		inst.components.heater:SetThermics(true, false)
    	return 40
	end

	inst.components.heater:SetThermics(false, false)
	return 0
end
--------------------------------------------------------------------------
local SPAWN_DIST = 30

local function OpenEye(inst)
    if not inst.isOpenEye then
        inst.isOpenEye = true
    end
end

local function CloseEye(inst)
    if inst.isOpenEye then
        inst.isOpenEye = nil
    end
end

local function RefreshEye(inst)
    local inv_img = inst.isOpenEye and inst.openEye or inst.closedEye
end

local function GetSpawnPoint(pt)
    local theta = math.random() * TWOPI
    local radius = SPAWN_DIST
    local offset = FindWalkableOffset(pt, theta, radius, 12, true)
    return offset ~= nil and (pt + offset) or nil
end

local function SpawnChester(inst)
    local pt = inst:GetPosition()

    local spawn_pt = GetSpawnPoint(pt)
    if spawn_pt ~= nil then
        local robot = SpawnPrefab("alice_robot")
        if robot ~= nil then
			robot.sg:GoToState("restart")
            robot.Physics:Teleport(spawn_pt:Get())
            robot:FacePoint(pt:Get())
			inst.robot = robot
			robot:LinkToPlayer(inst)
			
			robot:ListenForEvent("onremove", inst._robot_onremove)
            return robot
        end
    end
end

local StartRespawn

local function StopRespawn(inst)
    if inst.respawntask ~= nil then
        inst.respawntask:Cancel()
        inst.respawntask = nil
        inst.respawntime = nil
    end
end

local function RebindChester(inst, chester)
    chester = chester or inst.robot or nil
    if chester ~= nil then
        OpenEye(inst)
        inst:ListenForEvent("death", function() 
			inst.robot = nil
			StartRespawn(inst, TUNING.ALICE_ROBOT_RESPAWN)
		end, chester)

        if chester.components.follower.leader and chester.components.follower.leader ~= inst then
            chester.components.follower:SetLeader(inst)
        end
        return true
    end
	return false
end

local function RespawnChester(inst)
    StopRespawn(inst)
    RebindChester(inst, inst.robot or SpawnChester(inst))
end

StartRespawn = function(inst, time)
    StopRespawn(inst)

    time = time or 0
    inst.respawntask = inst:DoTaskInTime(time, RespawnChester)
    inst.respawntime = GetTime() + time
    CloseEye(inst)
end

local function FixChester(inst)
    inst.fixtask = nil
    --take an existing chester if there is one
    if not RebindChester(inst) then
        CloseEye(inst)

        if inst.components.inventoryitem.owner ~= nil then
            local time_remaining = inst.respawntime ~= nil and math.max(0, inst.respawntime - GetTime()) or 0
            StartRespawn(inst, time_remaining)
        end
    end
end

local function CheckFixTask(inst)
    if inst.fixtask == nil then
        inst.fixtask = inst:DoTaskInTime(1, FixChester)
    end
end

local function OnSave(inst, data)
	data.robot = inst.robot ~= nil and inst.robot:GetSaveRecord() or nil
	data.volume = inst.volume

    data.EyeboneState = inst.EyeboneState
    if inst.respawntime ~= nil then
        local time = GetTime()
        if inst.respawntime > time then
            data.respawntimeremaining = inst.respawntime - time
        end
    end
end

local function OnLoad(inst, data)
    if data == nil then
        return
    end

	inst.volume = data.volume

	if data.robot ~= nil then
		local robot = SpawnSaveRecord(data.robot)
		inst.robot = robot
		if robot ~= nil then
			robot:LinkToPlayer(inst)
		end
		
		inst:ListenForEvent("onremove", inst._robot_onremove)
	end

    if data.respawntimeremaining ~= nil then
        inst.respawntime = data.respawntimeremaining + GetTime()
    else
        OpenEye(inst)
    end
end

local function OnTakeFuel(inst)
	inst.AnimState:PlayAnimation("idle_on", true)
end

local function OnDepleted(inst)
	inst:StopPlayingRecord()

	local robot = inst.robot
	robot:EndTaunt()

	inst.light_active = false
	onremovelight(inst, true)
	inst.AnimState:PlayAnimation("idle_off", true)
end

local function FueledTask(inst)
	if not inst.components.fueled then
		return
	end
	local fuelamount = 
        (inst.playing_sound and 0.1 or 0) + 
        (inst.light_active and 0.1 or 0) + 
        ((inst.robot and inst.robot._taunttask) and 0.1 or 0)

	inst.components.fueled:DoDelta(-fuelamount)
end

local function music()
	local inst = CreateEntity()
	
	inst.entity:AddTransform()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst:AddTag("FX")
	inst:Hide()

	inst.persists = false
	
	return inst
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst:AddTag("remotecontrol")
	inst:AddTag("engineering")
	inst:AddTag("engineeringbatterypowered")
	inst:AddTag("alice_remote")
    inst:AddTag('trader')

	inst.AnimState:SetBank("alice_remote")
	inst.AnimState:SetBuild("alice_remote")
	inst.AnimState:PlayAnimation("idle_on", true)
	inst.AnimState:OverrideSymbol("wire", "winona_remote", "dummy")

	inst:AddComponent("spellbook")
	inst.components.spellbook:SetRequiredTag("alice")
	inst.components.spellbook:SetRadius(SPELLBOOK_RADIUS)
	inst.components.spellbook:SetFocusRadius(SPELLBOOK_FOCUS_RADIUS)
	inst.components.spellbook:SetItems(SPELLS)
	inst.components.spellbook.opensound = "meta4/winona_UI/open"
	inst.components.spellbook.closesound = "meta4/winona_UI/close"
	inst.components.spellbook.focussound = "meta4/winona_UI/hover"		--item UIAnimButton don't have hover sound

    inst:AddComponent("aoetargeting")
	inst.components.aoetargeting.reticule.targetfn = ReticuleTargetAllowWaterFn
	inst.components.aoetargeting.reticule.validcolour = { 1, .75, 0, 1 }
	inst.components.aoetargeting.reticule.invalidcolour = { .5, 0, 0, 1 }
	inst.components.aoetargeting.reticule.ease = true
	inst.components.aoetargeting.reticule.mouseenabled = true
	inst.components.aoetargeting.reticule.twinstickmode = 1
	inst.components.aoetargeting.reticule.twinstickrange = 8

	inst.entity:SetPristine()

	inst.musicfn = musicfn
	inst.volume = 1

	inst.musicevent = net_event(inst.GUID, "remote.musicevent")

	inst:DoTaskInTime(0, inst.ListenForEvent, "remote.musicevent", musicfn)
	
	if not TheWorld.ismastersim then
		return inst
	end

	inst.localsounds = SpawnPrefab("alice_musicfx")
	inst.localsounds.entity:SetParent(inst.entity)

	inst.EyeboneState = "NORMAL"
    inst.openEye = "chester_eyebone"
    inst.closedEye = "chester_eyebone_closed"
    inst.isOpenEye = nil
	inst.swap_build = "winona_remote"
	
	inst:AddComponent("aoespell")

    inst:AddComponent("heater")
    inst.components.heater.heatfn = HeatFn
    inst.components.heater.carriedheatfn = HeatFn

	inst:AddComponent("updatelooper")
	inst:AddComponent("colouradder")

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/alice_remote.xml"
	inst.components.inventoryitem.imagename = "alice_remote_on"
	inst:DoPeriodicTask(1, CheckFixTask)

	inst:AddComponent("fueled")
	inst.components.fueled.fueltype = FUELTYPE.MAGIC
	inst.components.fueled.rate = 0
	inst.components.fueled:InitializeFuelLevel(TUNING.ALICE_REMOTE_FUEL)
	inst.components.fueled:SetDepletedFn(OnDepleted)
	inst.components.fueled:SetTakeFuelFn(OnTakeFuel)

    inst:AddComponent("leader")

	MakeHauntableLaunch(inst)

	inst.musictask = inst:DoPeriodicTask(1, FueledTask)

    inst.StopRespawn = StopRespawn

    inst.OnLoad = OnLoad
    inst.OnSave = OnSave

	inst.lightfn = lightfn
	inst.robotfn = robotfn
	inst.TryToPlayRecord = TryToPlayRecord
	inst.StopPlayingRecord = StopPlayingRecord

    inst.fixtask = inst:DoTaskInTime(1, FixChester)
	inst._robot_onremove = function() inst.robot = nil end

    inst.RefreshEye = RefreshEye

	inst:ListenForEvent("onremove", onremovelight)
	
	inst._wired = nil

	return inst
end

return Prefab("alice_remote", fn, assets, prefabs),
	Prefab("alice_musicfx", music, assets, prefabs)