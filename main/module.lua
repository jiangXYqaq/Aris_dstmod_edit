GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})
--Aris 的专属3个电路的配置。加起来刚好占用6个槽位。目前改为一共3槽位，但多个装备可能导致bug
local wx78_moduledefs = require("wx78_moduledefs")
local module_definitions = wx78_moduledefs.module_definitions
local AddCreatureScanDataDefinition = wx78_moduledefs.AddCreatureScanDataDefinition
local GetModuleDefinitionFromNetID = wx78_moduledefs.GetModuleDefinitionFromNetID
local AddNewModuleDefinition = wx78_moduledefs.AddNewModuleDefinition
local getprefab = require("alice_utils/getprefab")

---------------------------------------------
-------------------强化魔法-------------------
---------------------------------------------

local function magic_activate(inst, wx)
    if wx.alc_baojilv then
        wx.alc_baojilv = wx.alc_baojilv + 0.2 --暴击率提升20%
    end
end

local function magic_deactivate(inst, wx)
    if wx.alc_baojilv then
        wx.alc_baojilv = wx.alc_baojilv - 0.2
    end
end

local MAGIC_MODULE_DATA =
{
    name = "alc_magic",
    slots = 1,
    activatefn = magic_activate,
    deactivatefn = magic_deactivate,
}

table.insert(module_definitions, MAGIC_MODULE_DATA)
AddNewModuleDefinition(MAGIC_MODULE_DATA)
AddCreatureScanDataDefinition("rocky", "alc_magic", 5)

-------------------------------------------------
-------------------战斗分析模块-------------------
-------------------------------------------------
local function nightvision_onworldstateupdate(wx)
    wx:SetForcedNightVision(TheWorld.state.isnight and not TheWorld.state.isfullmoon, true)
end

local function battle_activate(inst, wx)
    wx:DoTaskInTime(0, function()
        wx.alc_goggles:set(true)
        wx.alc_night:set(true)
        wx.battle_activate = true
        if TheWorld and TheWorld:HasTag("cave") then
            wx:SetForcedNightVision(true)
        else
            wx:WatchWorldState("isnight", nightvision_onworldstateupdate)
            wx:WatchWorldState("isfullmoon", nightvision_onworldstateupdate)
            nightvision_onworldstateupdate(wx)
        end
    end)
end

local function battle_deactivate(inst, wx)
    wx:DoTaskInTime(0, function()
        wx.alc_goggles:set(false)
        wx.alc_night:set(false)
        wx.battle_activate = false

        wx:SetForcedNightVision(false)
        if not (TheWorld and TheWorld:HasTag("cave")) then
            wx:StopWatchingWorldState("isnight", nightvision_onworldstateupdate)
            wx:StopWatchingWorldState("isfullmoon", nightvision_onworldstateupdate)
        end
    end)
end

local BATTLE_MODULE_DATA =
{
    name = "alc_battle",
    slots = 1,
    activatefn = battle_activate,
    deactivatefn = battle_deactivate,
}

table.insert(module_definitions, BATTLE_MODULE_DATA)
AddNewModuleDefinition(BATTLE_MODULE_DATA)
AddCreatureScanDataDefinition("rocky", "alc_battle", 5)

---------------------------------------------
-------------------充电模块-------------------
---------------------------------------------
--加快了充电速度
local function charge_activate(inst, wx)
    inst:AddTag("FX")
    inst:AddTag("CLASSIFIED")
    getprefab.Hide(inst)
    if inst.chargetask ~= nil then
        inst.chargetask:Cancel()
        inst.chargetask = nil
    end

    inst.chargetask = inst:DoPeriodicTask(3, function()
        local batterys = inst.components.container:GetAllItems()
        for k, v in ipairs(batterys) do -- 遍历容器
            if v:HasTag("alice_battery") and v.components.finiteuses then
                local use = v.components.finiteuses:GetUses() + 10
                use = math.min(1000, use)
                v.components.finiteuses:SetUses(use)
            end

            if v:HasTag("alice_remote") and v.components.fueled then
                local use = v.components.fueled:GetPercent() + 0.1
                use = math.min(1, use) 
                v.components.fueled:SetPercent(use)
            end
        end
    end)
end

local function charge_deactivate(inst, wx)
    if inst.chargetask ~= nil then
        inst.chargetask:Cancel()
        inst.chargetask = nil
    end

    inst:DoTaskInTime(0, function()
        if wx and wx.components.freezable and wx.components.freezable:IsFrozen() then
            return
        end

        inst:RemoveTag("FX")
        inst:RemoveTag("CLASSIFIED")
        getprefab.Show(inst)
        if inst.components.container ~= nil then
            inst.components.container:Open(wx)
        end
    end)
end

local CHARGE_MODULE_DATA =
{
    name = "alc_charge",
    slots = 1,
    activatefn = charge_activate,
    deactivatefn = charge_deactivate,
}

table.insert(module_definitions, CHARGE_MODULE_DATA)
AddNewModuleDefinition(CHARGE_MODULE_DATA)
AddCreatureScanDataDefinition("rocky", "alc_charge", 5)

-------------------添加新模块-------------------

local modmodule = {
    "alc_charge",
    "alc_magic", 
    "alc_battle", 
}

local dianlu = {
    alc_battle = "music_chip",
    alc_magic = "maxhealth2_chip",
    alc_charge = "maxsanity1_chip",
}


local ImageButton = require "widgets/imagebutton"

AddClassPostConstruct("widgets/upgrademodulesdisplay", function(self)
	local oldOnModuleAdded = self.OnModuleAdded
	self.OnModuleAdded = function(self, moduledefinition_index, ...)
        if oldOnModuleAdded then
		    oldOnModuleAdded(self, moduledefinition_index, ...)
        end
		local module_def = GetModuleDefinitionFromNetID(moduledefinition_index)
        if module_def == nil then
            return
        end

		local modname = module_def.name
		for k, v in pairs(modmodule) do
            if modname == v then
                local new_chip = self.chip_objectpool[self.chip_poolindex - 1]
                new_chip:GetAnimState():OverrideSymbol("movespeed2_chip", "status_alice", dianlu[modname])
                if modname == "alc_charge" then
                    local num = self.chip_poolindex - 1
                    self.chipbutton = self.chipbutton or {}
                    if self.chipbutton[num] == nil then
                        self.chipbutton[num] = new_chip:AddChild(ImageButton("images/ui/select.xml", "select.tex"))
                        self.chipbutton[num]:SetScale(.5, .5, .5)
                        self.chipbutton[num]:SetPosition(-80, 0, 0)
                        self.chipbutton[num]:SetOnClick(function()
                            SendModRPCToServer(MOD_RPC["alice"]["alic_charge"], num)
                            self.chipbutton[num]:OnSelect()
                        end)
                    end
                end
            end
		end
	end

    if self.owner and self.owner:HasTag("alice") then
        self.battery_frame:GetAnimState():SetBank("status_alice")
        self.battery_frame:GetAnimState():SetBuild("status_alice")
        self.battery_frame:GetAnimState():PlayAnimation("aliceframe")
    end
end)

for k, v in pairs(modmodule) do
    AddPrefabPostInit("wx78module_" .. v, function(inst)
        if inst.components.inventoryitem then
            inst.components.inventoryitem.atlasname = "images/inventoryimages/alice_moudle.xml"
            inst.components.inventoryitem.imagename = v
        end
        
		inst:DoTaskInTime(0, function()
            inst.AnimState:SetBank("alice_moudle")
            inst.AnimState:SetBuild("alice_moudle")
            inst.AnimState:PlayAnimation("alice_moudle" .. k)
		end)
    end)
end

local function OnShieldLoaded(inst, data)
end

local function OnShieldUnloaded(inst, data)
end

AddPrefabPostInit("wx78module_alc_charge", function(inst)
    if not TheWorld.ismastersim then
        return inst
    end
    
    inst:AddComponent("container")
    inst.components.container:WidgetSetup("wx78module_alc_charge")
	inst.components.container.canbeopened = true
    inst.components.container.stay_open_on_hide = true
    inst:ListenForEvent("itemget", OnShieldLoaded)
    inst:ListenForEvent("itemlose", OnShieldUnloaded)


    local olfn = inst.components.finiteuses.onfinished
    inst.components.finiteuses.onfinished = function(self, fn, ...)
        for k = 1, 2 do
            inst.components.container:DropItemBySlot(k)
        end
        if olfn then
            olfn(self, fn, ...)
        end
    end
end)