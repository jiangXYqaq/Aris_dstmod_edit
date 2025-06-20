GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})

local Utils = require("alice_utils/utils")

AddModRPCHandler("alice", "alc_sendkey", function(player, down)
    player.alc_lmb = down and "down" or "up"
end)

AddModRPCHandler("alice", "alc_sendmousepos", function(player, x, y, z)
    if checknumber(x) and checknumber(y) and checknumber(z) then
        player.alc_mousepos = Vector3(x, y, z)
    end
end)

AddClassPostConstruct("widgets/controls", function(self)
    if self.owner --[[and self.owner:HasTag("alice")]] then
        if self.alc_sendkey == nil then
            self.alc_sendkey = TheInput:AddControlHandler(CONTROL_PRIMARY, function(down)
                if TheNet:IsServerPaused() or not ThePlayer then
                    return
                end
                if not TheWorld.ismastersim then
                    ThePlayer.alc_lmb = down and "down" or "up"
                end
                SendModRPCToServer(MOD_RPC["alice"]["alc_sendkey"], down)
            end)
        end
        if self.alc_sendmousepos == nil then
            self.alc_sendmousepos = self.owner:DoPeriodicTask(0.03, function()
                if not TheNet:IsServerPaused() and ThePlayer and ThePlayer:HasTag("alice_shot") then
                    local x, y, z = TheInput:GetWorldPosition():Get()
                    if not TheWorld.ismastersim then
                        ThePlayer.alc_mousepos = Vector3(x, y, z)
                    end
                    SendModRPCToServer(MOD_RPC["alice"]["alc_sendmousepos"], x, y, z)
                end
            end)
        end
    end
    
end)


local ex_key = TUNING.EX_MODE_KEY
local gift_key = TUNING.ALICE_GIFT_KEY

--更换武器准星
AddClientModRPCHandler("alice", "updataaoereticule", function(num)
    if not ThePlayer then
        return
    end
    local equip = Utils.FindEquipWithTag(ThePlayer, "lightsword")
    if equip then
        if num == 2 then
            equip:alc_change_circle()
        else
            equip:alc_change_zhixian()
        end
    end
end)

AddClientModRPCHandler("alice", "lightsword_nofinitiness", function()
    if ThePlayer then
        ThePlayer:PushEvent("lightsword_nofinitiness")
    end
end)

AddModRPCHandler("alice", "lightsword_changemode", function(player, mode)
    if player ~= nil then
        local equip = Utils.FindEquipWithTag(player, "lightsword")
        if equip and equip.components.alice_sword then
            equip.components.alice_sword:ChangeMode(mode)
        end
    end
end)

AddModRPCHandler("alice", "alic_charge", function(player, num)
    if not (player or player.components.upgrademoduleowner) then
        return
    end
    local item = player.components.upgrademoduleowner:GetModuleInSlot(num)
    if item and item.components.container then
        if item.components.container:IsOpen() then
            item:RemoveFromScene()
            item.components.container:Close(player)
        else
            item:ReturnToScene()
            item:Hide()
            item.components.container:Open(player)
        end
    end
end)

AddModRPCHandler("alice", "remote_light", function(doer, inst)
    if not (remote or doer) then
        return
    end
	if (doer.sg:HasStateTag("busy") or doer.sg:HasStateTag("doing") or doer.sg.statemem.heavy) then 
		return 
	end
	if not doer:HasTag("playerghost") and doer:HasTag("alice") then
		inst.fns = "remote_light"
		doer.sg:GoToState("alice_remote", inst)
	end
end)

AddModRPCHandler("alice", "remote_music", function(doer, inst)
    if not (remote or doer) then
        return
    end
	if (doer.sg:HasStateTag("busy") or doer.sg:HasStateTag("doing") or doer.sg.statemem.heavy) then 
		return 
	end
	if not doer:HasTag("playerghost") and doer:HasTag("alice") then
		inst.fns = "remote_music"
		doer.sg:GoToState("alice_remote", inst)
	end
end)

AddModRPCHandler("alice", "remote_taunt", function(doer, inst)
    if not (remote or doer) then
        return
    end
	if (doer.sg:HasStateTag("busy") or doer.sg:HasStateTag("doing") or doer.sg.statemem.heavy) then 
		return 
	end
	if not doer:HasTag("playerghost") and doer:HasTag("alice") then
		inst.fns = "remote_taunt"
		doer.sg:GoToState("alice_remote", inst)
	end
end)

AddModRPCHandler("alice", "playmusic", function(player, remote, music)
    if not remote then
        return
    end

    remote:TryToPlayRecord(music)
end)

AddModRPCHandler("alice", "stopmusic", function(player, remote)
    if not remote then
        return
    end

    remote:StopPlayingRecord(music)
end)

AddModRPCHandler("alice", "setvolume", function(player, remote, volume)
    if not remote then
        return
    end
    
    remote.volume = volume
    remote.localsounds.SoundEmitter:SetVolume("ragtime", remote.volume)
end)

AddModRPCHandler("alice", "teleport", function(player, x, z)
    if player and player.Transform then
        --print("[Debug] RPC: Teleporting player to", x, z) -- Debug log
        player.Transform:SetPosition(x, 0, z)
    else
        --print("[Debug] RPC: Failed to teleport player. Invalid player or position.") -- Debug log
    end
end)

local function AcceptTest(inst, item)
    return not inst.components.alice_sword:IsMaxLevel(item.mode)
end

local function OnRefuseItem(inst, giver, item)
    if inst.components.alice_sword:IsMaxLevel(item.mode) then
		giver:DoTaskInTime(0, function()
       		giver.components.talker:Say(STRINGS.ACTIONS.LIGHTSWORD.MAX_LEVEL)
		end)
        return
    end
end

-- EX模式切换监听
AddClassPostConstruct("widgets/controls", function(self)
    if self.owner then
        -- 只在功能启用时添加监听器
        if self.ex_mode_handler == nil and ex_key ~= false then
            self.ex_mode_handler = TheInput:AddKeyHandler(function(key, down)
                if down and key == ex_key then
                    if ThePlayer and not ThePlayer:HasTag("playerghost") then
                        local equip = Utils.FindEquipWithTag(ThePlayer, "lightsword")
                        if equip then
                            SendModRPCToServer(MOD_RPC["alice"]["lightsword_changemode"], 3)
                        end
                    end
                end
            end)
        end
    end
end)

local function OnAccept(inst, giver, item)
    if inst.components.alice_sword:IsMaxLevel(item.mode) then
		giver.components.talker:Say("已经升到最高级了")
        return
    end
    local result, level = inst.components.alice_sword:LevelUp(item.mode)
    if result then
		local say = level == 0 and item.name .. "已解锁" or item.name .. "升级至Lv" .. level
        giver.components.talker:Say(say)
		item:Remove()
    end

	SendModRPCToClient(CLIENT_MOD_RPC["alice"]["updatesound"], giver.userid)
end

AddModRPCHandler("alice", "levelup", function(player, weapon, mode)
    if not player then
        return
    end
    local mode = next(player.components.inventory:GetItemByName("alice_mode" .. mode, 1)) 
    if mode and weapon:HasTag("lightsword") then
        if AcceptTest(weapon, mode) then
            OnAccept(weapon, player, mode)
            return true
        else
            OnRefuseItem(weapon, player, mode)
        end
    end
end)

AddClientModRPCHandler("alice", "updatesound", function()
    if not ThePlayer then
        return
    end

    if TheFrontEnd then
        TheFrontEnd:GetSound():PlaySound("alicesound/alicesound/UI_LevelUp")
    end
end)

if TheNet and TheNet:GetIsServer() then
    -- 延迟到世界准备好
    AddSimPostInit(function()
        -- 初始化玩家组件
        AddPlayerPostInit(function(inst)
            -- 确保不是客户端控制的玩家实体
            if inst ~= ThePlayer then
                if not inst.components.alice_gift then
                    inst:AddComponent("alice_gift")
                end
                
                -- 按键处理事件监听
                inst:ListenForEvent("alice_gift_trigger", function()
                    if inst.components.alice_gift and inst.components.alice_gift:CheckCooldown() then
                        inst.components.alice_gift:GiveGifts()
                        inst.components.alice_gift:UpdateCooldown()
                    end
                end)
            end
        end)
    end)
end

-- 礼物功能按键监听
local key_handler_added = false

AddClassPostConstruct("widgets/controls", function(self)
    -- 只在功能启用且未添加过监听器时执行
    if not key_handler_added and self.owner == ThePlayer and gift_key ~= false then
        self.gift_key_handler = TheInput:AddKeyHandler(function(key, down)
            if down and key == gift_key then
                SendModRPCToServer(MOD_RPC["alice_gift"]["request_gift"])
            end
        end)
        key_handler_added = true
    end
end)

AddModRPCHandler("alice_gift", "request_gift", function(player)
    if player and player:IsValid() and player.components.alice_gift then
        player:PushEvent("alice_gift_trigger")
    end
end)
