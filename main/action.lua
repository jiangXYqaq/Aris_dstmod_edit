GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})

local Utils = require("alice_utils/utils")

TUNING.INVENTORYFNS_CUSTOM = {} -- 管理INVENTORY动作的表格
TUNING.USEITEMFNS_CUSTOM = {} 	-- 管理USEITEM动作的表格
TUNING.POINTFNS_CUSTOM = {} 	-- 管理POINT动作的表格
 
AddComponentAction("INVENTORY", "inventoryitem", function(inst, doer, actions, right)
    for _, fn in ipairs(TUNING.INVENTORYFNS_CUSTOM) do
        fn(inst, doer, actions, right)
    end
end)

AddComponentAction("USEITEM", "inventoryitem", function(inst, doer, target, actions)
    for _, fn in ipairs(TUNING.USEITEMFNS_CUSTOM) do
        fn(inst, doer, target, actions)
    end
end)

AddComponentAction("POINT", "inventoryitem", function(inst, doer, pos, actions, right, target)
    for _, fn in ipairs(TUNING.POINTFNS_CUSTOM) do
        fn(inst, doer, pos, actions, right, target)
    end
end)

-------------------------------------------------------
--------------------  快捷装备物品  --------------------
-------------------------------------------------------
local takele_action = Action({priority = 10})
takele_action.id = "ALICE_TACKLE"

takele_action.str = {
    REMOVE = STRINGS.ACTIONS.ALICE_TACKLE.REMOVE,
    GENERIC = STRINGS.ACTIONS.ALICE_TACKLE.GENERIC,
}

takele_action.strfn = function(act)
    local equipment_slot = act.invobject ~= nil and act.invobject.targetslot or nil
    local equipped = act.doer.replica.inventory and act.doer.replica.inventory:GetEquippedItem(equipment_slot) 
    if equipped and equipped.replica.container and equipped.replica.container:IsHolding(act.invobject) then
        return "REMOVE"
    end
    return "GENERIC"
end

takele_action.fn = function(act)
    local equipment_slot = act.invobject ~= nil and act.invobject.targetslot or nil
	local equipped = act.doer.components.inventory:GetEquippedItem(equipment_slot)
	if act.invobject == nil or equipped == nil or equipped.components.container == nil then
		return false
	end

	if act.invobject.components.inventoryitem:IsHeldBy(equipped) then
		local item = equipped.components.container:RemoveItem(act.invobject, true, nil, true)

		if item ~= nil then
	        item.prevcontainer = nil
	        item.prevslot = nil

			act.doer.components.inventory:GiveItem(item, nil, equipped:GetPosition())
			return true
		end
	else
		local targetslot = equipped.components.container:GetSpecificSlotForItem(act.invobject)
		if targetslot == nil then
			return false
		end

		local cur_item = equipped.components.container:GetItemInSlot(targetslot)
		if cur_item == nil then
			local item = act.invobject.components.inventoryitem:RemoveFromOwner(equipped.components.container.acceptsstacks, true)
			equipped.components.container:GiveItem(item, targetslot, nil, false)
            return true
		elseif equipped.components.container.acceptsstacks and act.invobject.prefab == cur_item.prefab and act.invobject.skinname == cur_item.skinname
			and not (cur_item.components.stackable and cur_item.components.stackable:IsFull()) then
			local item = act.invobject.components.inventoryitem:RemoveFromOwner(equipped.components.container.acceptsstacks, true)
			if not equipped.components.container:GiveItem(act.invobject, targetslot, nil, false) then
				if item.prevcontainer then
					item.prevcontainer.inst.components.container:GiveItem(item, item.prevslot)
				else
					act.doer.components.inventory:GiveItem(item, item.prevslot)
				end
            end
			return true
		elseif (act.invobject.prefab ~= cur_item.prefab ) or cur_item.components.perishable or cur_item.components.finiteuses then
			local item = act.invobject.components.inventoryitem:RemoveFromOwner(equipped.components.container.acceptsstacks, true)
			local old_item = equipped.components.container:RemoveItemBySlot(targetslot)
			if not equipped.components.container:GiveItem(item, targetslot, nil, false) then
				act.doer.components.inventory:GiveItem(item, nil, act.doer:GetPosition())
			end
			if old_item then
				act.doer.components.inventory:GiveItem(old_item, nil, act.doer:GetPosition())
			end
			return true
		end
	end
    return false
end

local function check_takele_action(inst, doer, actions, right)
    if doer.replica.inventory and doer.replica.inventory:EquipHasTag("lightsword") and inst:HasTag("alice_battery") then
        table.insert(actions, ACTIONS.ALICE_TACKLE)
    end
    if doer.replica.inventory and doer.replica.inventory:EquipHasTag("alice_coat") and inst:HasTag("alice_shield") then
        table.insert(actions, ACTIONS.ALICE_TACKLE)
    end
end

table.insert(TUNING.INVENTORYFNS_CUSTOM, check_takele_action)
AddAction(takele_action)
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.ALICE_TACKLE, "doshortaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.ALICE_TACKLE, "doshortaction"))

-- hook充能电路插入方式
local COMPONENT_ACTIONS = Utils.ChainFindUpvalue(EntityScript.CollectActions, "COMPONENT_ACTIONS") or Utils.ChainFindUpvalue(EntityScript.IsActionValid, "COMPONENT_ACTIONS")
if COMPONENT_ACTIONS then
    Utils.FnDecorator(COMPONENT_ACTIONS.INVENTORY, "upgrademodule", function(inst, doer, actions, right)
		local container = inst.replica.container
		if container  then
            return nil, true
		end
    end)
end

-------------------------------------------------------
-------------------  升级光之剑模块  -------------------
-------------------------------------------------------

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

local levelup_action = Action({priority = 100})
levelup_action.id = "ALICE_LEVELUP"
levelup_action.str = STRINGS.ACTIONS.ALICE_LEVELUP
levelup_action.fn = function(act)
	if act.target and act.doer and act.invobject then
		if AcceptTest(act.target, act.invobject) then
			OnAccept(act.target, act.doer, act.invobject)
			return true
		else
			OnRefuseItem(act.target, act.doer, act.invobject)
		end
	end
	return false
end

local function check_levelup_action(inst, doer, target, actions)
    if target:HasTag("lightsword") and inst:HasTag("swordmode") then
        table.insert(actions, ACTIONS.ALICE_LEVELUP)
    end
end

table.insert(TUNING.USEITEMFNS_CUSTOM, check_levelup_action)
AddAction(levelup_action)
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.ALICE_LEVELUP, "dolongaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.ALICE_LEVELUP, "dolongaction"))

-------------------------------------------------------
--------------------  学习蓝图地图  --------------------
-------------------------------------------------------

local function AcceptTest(item)
    return (item.components.teacher and item.components.teacher.onteach) or (item.components.maprecorder and item.components.maprecorder.onteachfn)
end

local function GetReason_blueprint(self, target)
	if self.recipe == nil then
		return false
	elseif target.components.builder == nil then
		return false
	elseif target.components.builder:KnowsRecipe(self.recipe, true) then
		return false, "KNOWN"
	elseif not target.components.builder:CanLearn(self.recipe) then
		return false, "CANTLEARN"
	end
end

local function GetMapExplorer(target)
    return target ~= nil and target.player_classified ~= nil and target.player_classified.MapExplorer or nil
end

local function GetReason_mapscroll(self, target)
	if not self:HasData() then
		return false
	elseif not self:IsCurrentWorld() then
		return false, "WRONGWORLD"
	end
	local MapExplorer = GetMapExplorer(target)
	if MapExplorer == nil then
		return false
	end
	if not MapExplorer:LearnRecordedMap(self.mapdata) then
		return false
	end
end

local function OnAccept(giver, item)
	if item.prefab == "blueprint" then
		local self = item.components.teacher
		local result, reason = GetReason_blueprint(self, giver)
		if result == false then
			if reason ~= nil then
				giver:DoTaskInTime(0, function()
					giver.components.talker:Say(STRINGS.CHARACTERS.GENERIC.ACTIONFAIL.TEACH[reason])
				end)
			end
			return false
		end
		
		giver.components.builder:UnlockRecipe(self.recipe)
		self.onteach(item, giver)
		return true
	elseif item.prefab == "mapscroll" then
		local self = item.components.maprecorder
		local result, reason = GetReason_mapscroll(self, giver)

		if result == false then
			if reason ~= nil then
				giver:DoTaskInTime(0, function()
					giver.components.talker:Say(STRINGS.CHARACTERS.GENERIC.ACTIONFAIL.TEACH[reason])
				end)
			end
			return false
		end

		if self.onteachfn ~= nil then
			self.onteachfn(item, giver)
		end
		return true
	end
end

local remote_action = Action({priority = 100})
remote_action.id = "ALICE_REMOTE_LEARN"
remote_action.str = STRINGS.ACTIONS.ALICE_REMOTE_LEARN
remote_action.fn = function(act)
	if AcceptTest(act.invobject) and OnAccept(act.doer, act.invobject) then
		return true
	end
	return false
end

local testfn = function(inst, doer, target, actions)
    if target:HasTag("alice_remote") and (inst.prefab == "blueprint" or inst.prefab == "mapscroll") then
        table.insert(actions, ACTIONS.ALICE_REMOTE_LEARN)
    end
end

table.insert(TUNING.USEITEMFNS_CUSTOM, testfn)
AddAction(remote_action)
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.ALICE_REMOTE_LEARN, "dolongaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.ALICE_REMOTE_LEARN, "dolongaction"))


-------------------------------------------------------
----------------------  使用手机  ----------------------
-------------------------------------------------------

local remote_action = Action({priority = 100})
remote_action.id = "ALICE_REMOTE"
remote_action.str = "UNUSE"
remote_action.fn = function(act)
	if not (act.doer or act.target) then
		return false
	end
	
	local remote = act.target
	if not remote or remote.prefab ~= "alice_remote" then
		return false
	end

	return true
end

local function check_remote_action(inst, doer, pos, actions, right, target)
    if doer:HasTag("remote_action") then
        table.insert(actions, ACTIONS.ALICE_REMOTE)
    end
end

table.insert(TUNING.POINTFNS_CUSTOM, check_remote_action)
AddAction(remote_action)
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.ALICE_REMOTE, "alice_remote"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.ALICE_REMOTE, "alice_remote"))

-------------------------------------------------------
--------------------  扫帚拾取功能  --------------------
-------------------------------------------------------
--[[ -- 统一动作定义（动态处理所有交互）
local broom_action = Action({ priority = 5 })
broom_action.id = "ALICE_BROOM_ACTION"
broom_action.strfn = function(act)
    -- 动态获取目标类型
    if act.target then
        if safe_can_cast(act.doer, act.target) then
            return STRINGS.ACTIONS.ALICE_BROOM_RESKIN
        elseif act.target.components.pickable and act.target.components.pickable:CanBePicked() then
            return STRINGS.ACTIONS.ALICE_BROOM_HARVEST
        elseif act.target.components.inventoryitem then
            return STRINGS.ACTIONS.ALICE_BROOM_PICKUP
        end
    end
    return STRINGS.ACTIONS.ALICE_BROOM_DEFAULT -- 默认文本
end

broom_action.fn = function(act)
    if act.target and act.doer then
        -- 复用你的现有条件判断
        if safe_can_cast(act.doer, act.target) then
            return ReskinTarget(act.invobject, act.doer, act.target)
        elseif act.target.components.pickable and act.target.components.pickable:CanBePicked() then
            return HarvestItems(act.invobject, act.doer, act.target)
        elseif act.target.components.inventoryitem then
            return PickUpItems(act.invobject, act.doer, act.target)
        end
    end
    return false
end

AddAction(broom_action)

-- 通用检测函数
local function CheckBroomAction(inst, doer, target, actions)
    if doer and doer.components.inventory then
        local tool = doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if tool and tool.prefab == "alice_broom" then
            -- 基于你的现有条件判断
            if safe_can_cast(doer, target) or 
               (target.components.pickable and target.components.pickable:CanBePicked()) or 
               target.components.inventoryitem then
                table.insert(actions, ACTIONS.ALICE_BROOM_ACTION)
            end
        end
    end
end

-- 注册到所有可能的目标类型
AddComponentAction("SCENE", "inventoryitem", CheckBroomAction)
AddComponentAction("POINT", "pickable", CheckBroomAction)
AddComponentAction("SCENE", "reskinable", CheckBroomAction) -- 如果原版有reskinable组件

-- 状态图处理
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.ALICE_BROOM_ACTION, "doshortaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.ALICE_BROOM_ACTION, "doshortaction")) ]]

-- 换肤动作（覆盖原版RESKIN）
local reskin_action = Action({ priority = 5 })
reskin_action.id = "ALICE_BROOM_RESKIN"
reskin_action.str = STRINGS.ACTIONS.ALICE_BROOM_RESKIN -- 使用原版文本

reskin_action.fn = function(act)
    if act.target == nil then
       -- print("[Debug] ReskinAction: Target is nil. Doer:", act.doer and act.doer.prefab or "nil")
        return false
    end

    -- 修复：添加安全检查，确保 doer 是玩家实体
    if not act.doer or not act.doer.components or not act.doer.components.inventory then
        --print("[Debug] ReskinAction: Invalid doer. Doer:", act.doer and act.doer.prefab or "nil")
        return false
    end

    local tool = act.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    if tool and tool.prefab == "alice_broom" then
        --print("[Debug] ReskinAction: Attempting to reskin target:", act.target.prefab)
        return ReskinTarget(tool, act.doer, act.target)
    end

    --print("[Debug] ReskinAction: No valid tool or target")
    return false
end

-- 换肤动作检测
local function CheckReskinAction(inst, doer, target, actions)
    if target == nil then
        --print("[Debug] CheckReskinAction: Target is nil")
        return
    end

    local tool = doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    if tool and tool.prefab == "alice_broom" then
        if safe_can_cast(doer, target, nil) then
            --print("[Debug] CheckReskinAction: Adding reskin action for target:", target.prefab)
            table.insert(actions, ACTIONS.ALICE_BROOM_RESKIN)
        --else
            --print("[Debug] CheckReskinAction: Target not valid for reskin:", target.prefab)
        end
    --else
        --print("[Debug] CheckReskinAction: No valid tool equipped")
    end
end

-- 拾取动作（独立注册）
local pickup_action = Action({ priority = 6 }) -- 优先级低于换肤
pickup_action.id = "ALICE_BROOM_PICKUP"
pickup_action.str = STRINGS.ACTIONS.ALICE_BROOM_PICKUP -- 确保已定义

pickup_action.fn = function(act)
    if act.target == nil then
        --print("[Debug] PickupAction: Target is nil. Doer:", act.doer.prefab)
        return false
    end

	-- 修复：添加安全检查，确保 doer 是玩家实体
    if not act.doer or not act.doer.components or not act.doer.components.inventory then
        --print("[Debug] ReskinAction: Invalid doer. Doer:", act.doer and act.doer.prefab or "nil")
        return false
    end

    local tool = act.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    if tool and tool.prefab == "alice_broom" then
        --print("[Debug] PickupAction: Attempting to pick up target:", act.target.prefab)
        return PickUpItems(tool, act.doer, act.target)
    end

    --print("[Debug] PickupAction: No valid tool or target")
    return false
end

-- 拾取动作检测
local function CheckPickupAction(inst, doer, target, actions)
    if target == nil then
        --print("[Debug] CheckPickupAction: Target is nil")
        return
    end

	-- 修复：添加安全检查，确保 doer 是玩家实体
    if not doer or not doer.components or not doer.components.inventory then
        --print("[Debug] ReskinAction: Invalid doer. Doer:", doer and doer.prefab or "nil")
        return false
    end

	--qu
    local tool = doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    if tool and tool.prefab == "alice_broom" then
        local inventoryitem = target.components.inventoryitem
        if inventoryitem 
            and inventoryitem.canbepickedup 
            and not target:HasOneOfTags({"heavy", "irreplaceable", "FX"})
        then
            --print("[Debug] CheckPickupAction: Adding pickup action for target:", target.prefab)
            table.insert(actions, ACTIONS.ALICE_BROOM_PICKUP)
        else
            --print("[Debug] CheckPickupAction: Target not valid for pickup:", target.prefab)
        end
    else
        --print("[Debug] CheckPickupAction: No valid tool equipped")
    end
end

-- 注册到POINT类型检测（在现有注册代码后添加）
table.insert(TUNING.POINTFNS_CUSTOM, CheckBroomPickupAction)
AddAction(reskin_action)
AddAction(pickup_action)
-- 注册到组件检测
AddComponentAction("USEITEM", "inventoryitem", CheckReskinAction)
AddComponentAction("USEITEM", "inventoryitem", CheckPickupAction)

-- 添加动作状态处理（在文件底部添加）
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.ALICE_BROOM_RESKIN, "doshortaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.ALICE_BROOM_RESKIN, "doshortaction"))
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.ALICE_BROOM_PICKUP, "doshortaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.ALICE_BROOM_PICKUP, "doshortaction"))
-------------------------------------------------------
--------------------  扫帚地图传送  --------------------
-------------------------------------------------------
local teleport_action = Action({
    priority = 10,                    -- 确保高于其他地图动作
    mount_valid = true,
    rmb = true,                       -- 右键触发
    map_action = true,                -- 关键属性：标记为地图点击动作
    do_not_locomote = true,           -- 禁止自动移动
    instant = true,                   -- 即时动作
    range = 999,                      -- 确保地图点击有效
})
teleport_action.id = "ALICE_BROOM_MAPTELE"
teleport_action.str = STRINGS.ACTIONS.ALICE_BROOM_MAPTELE -- 绑定文本

-- 动作逻辑（保持你的验证逻辑不变）
teleport_action.fn = function(act)
    if not TheWorld.ismastersim then
        return false -- 客户端直接返回
    end

    local doer = act.doer
    local pos = act:GetActionPoint()

    if not (doer and pos and doer.components.inventory) then
        return false
    end

    local item = doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    if not (item and item.prefab == "alice_broom") then
        return false
    end

    if not TheWorld.Map:IsPassableAtPoint(pos.x, 0, pos.z) then
        return false
    end

    doer:PushEvent("performaction", { action = act })
    doer.Transform:SetPosition(pos.x, 0, pos.z)
    
    return true
end

-- ▼ 注册到全局动作系统（必须在状态图注册之前）
AddAction(teleport_action)

-- 状态图处理（保持你的动画逻辑）
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.ALICE_BROOM_MAPTELE, "quicktele"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.ALICE_BROOM_MAPTELE, function(inst)
    inst:PerformPreviewBufferedAction()
    return "quicktele"
end))