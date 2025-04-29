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