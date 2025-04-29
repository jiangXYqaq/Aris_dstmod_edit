GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})

-- 处理蓄力移动
local function ComponentPostInit(inst)
	if inst.components.locomotor ~= nil and inst.components.locomotor.alc_hook == nil then
		inst.components.locomotor.alc_hook = true
		local old_run = inst.components.locomotor.RunForward
		inst.components.locomotor.RunForward = function(self, direct, ...)
			old_run(self, direct, ...)
			if self.inst:IsValid() and self.inst.sg ~= nil and self.inst.sg:HasStateTag("alice_shot") then
				local rotation = self.inst.Transform:GetRotation()
				local speed = self.inst.Physics:GetMotorVel() * 0.9 --移动蓄力速度有改动，原为0.5
				local direction = self.alc_run_direction
				if direction ~= nil then
					local a = (rotation - direction)* DEGREES
					local x, z = math.cos(a)*speed, math.sin(a)*speed
					self.inst.Physics:SetMotorVel(x, 0, z)
				end
			end
		end

		local old_run_in_dir = inst.components.locomotor.RunInDirection
		function inst.components.locomotor:RunInDirection(direction, throttle, ...)
			self.alc_run_direction = direction
			return old_run_in_dir(self, direction, throttle, ...)
		end
	end
end

local function ChangeRun(inst)
	inst:DoTaskInTime(0, ComponentPostInit)
end

AddPlayerPostInit(function(inst)
	ChangeRun(inst)
	
	inst:ListenForEvent("enablemovementprediction", ChangeRun) --监听延迟补偿开关，重新调用
end)

-- 禁用光之剑左键攻击
AddClassPostConstruct("components/combat_replica", function(self)
    local OldCanTarget = self.CanTarget
    function self:CanTarget(target, ...)
		local weapon = self:GetWeapon()
		if weapon and weapon:HasTag("lightsword") and not weapon:HasTag("fireatk") then
        	return false
		end
		return OldCanTarget(self, target, ...)
    end
end)

-- 炮弹修复炮击模组
MATERIALS.PAODAN = "paodan"
AddPrefabPostInit("cannonball_rock_item", function(inst)
	if not TheWorld.ismastersim then
        return
    end
	inst:AddComponent("repairer")
	inst.components.repairer.repairmaterial = MATERIALS.PAODAN
	inst.components.repairer.finiteusesrepairvalue = 5
end)

local gem = {
	"redgem",
	"bluegem",
}

for k, v in pairs(gem) do
	AddPrefabPostInit(v, function(inst)
		if not TheWorld.ismastersim then
			return
		end
		if not inst.components.repairer then
			inst:AddComponent("repairer")
			inst.components.repairer.repairmaterial = MATERIALS.GEM
		end
		inst.components.repairer.finiteusesrepairvalue = 50
	end)
end

-- 修改炮弹有效发射距离
local bufferaction_constructor = BufferedAction._ctor
BufferedAction._ctor = function(self, doer, target, action, invobject, ...)
    bufferaction_constructor(self, doer, target, action, invobject, ...)
    if action == ACTIONS.CASTAOE then
        if invobject ~= nil and invobject:HasTag("lightsword") then
            self.distance = 18 --原版8
        end
    end
end

local oldstrfn = ACTIONS.USESPELLBOOK.strfn
ACTIONS.USESPELLBOOK.strfn = function(act, ...)
	if act.doer:HasTag("alice") then
		return "ALICEREMOTE"
	end
	return oldstrfn(act, ...)
end

local oldstrfn = ACTIONS.CLOSESPELLBOOK.strfn
ACTIONS.CLOSESPELLBOOK.strfn = function(act, ...)
	if act.doer:HasTag("alice") then
		return "ALICEREMOTE"
	end
	return oldstrfn(act, ...)
end

-- 防沙尘暴
local function GogglesVision(inst)
    local self = inst.components.playervision
    if self.gogglevision == not (inst.replica.inventory and inst.replica.inventory:EquipHasTag("goggles")) then
        self.gogglevision = not self.gogglevision
        if not self.forcegogglevision then
            inst:PushEvent("gogglevision", {enabled = self.gogglevision})
        end
    end
end

AddClassPostConstruct("components/inventory_replica", function(self)
    local oldEquipHasTag = self.EquipHasTag
    self.EquipHasTag = function(self, tag,...)
        if self.inst and tag == "goggles"then
            return self.inst.alc_goggles and self.inst.alc_goggles:value() or oldEquipHasTag(self, tag,...)
        end
        return oldEquipHasTag(self, tag,...)
    end
end)

local function NightVision(inst)
    if inst ~= nil and inst.components.playervision ~= nil then
        if inst.alc_night:value() then
            inst.components.playervision:PushForcedNightVision(inst, 1, nil, true)
        else
            inst.components.playervision:PopForcedNightVision(inst)
        end
    end
end

AddPlayerPostInit(function (inst)
	if inst:HasTag("upgrademoduleowner") then
		inst.alc_goggles = net_bool(inst.GUID, "alc_goggles", "alc_gogglesdirty")
		inst:ListenForEvent("alc_gogglesdirty", GogglesVision)

		inst.alc_night = net_bool(inst.GUID, "alc_night", "alc_enableddirty")
		inst:ListenForEvent("alc_enableddirty", NightVision)
	end
end)

-- 不同耐久度物品堆叠
AddComponentPostInit("stackable", function(self, inst)
    local oldPut = self.Put
    self.Put = function(self, item, source_pos, ...)
		if item.prefab == self.inst.prefab and item.skinname == self.inst.skinname and self.inst.components.finiteuses then
			local num_to_add = item.components.stackable.stacksize
			local newtotal = self.stacksize + num_to_add
	
			local oldsize = self.stacksize
			local newsize = math.min(self.maxsize, newtotal)
			local numberadded = newsize - oldsize
			if self.inst.components.finiteuses.Dilute then
				self.inst.components.finiteuses:Dilute(numberadded, item.components.finiteuses.current)
			end
		end

        return oldPut(self, item, source_pos, ...)
    end

    local oldGet = self.Get
    self.Get = function(self, num, ...)
		local num_to_get = num or 1
		if self.stacksize > num_to_get and self.inst.components.finiteuses then
			local instance = SpawnPrefab( self.inst.prefab, self.inst.skinname, self.inst.skin_id, nil )
			self:SetStackSize(self.stacksize - num_to_get)
			instance.components.stackable:SetStackSize(num_to_get)

			if self.ondestack ~= nil then
				self.ondestack(instance, self.inst)
			end

			if instance.components.finiteuses ~= nil then
				instance.components.finiteuses.current = self.inst.components.finiteuses.current
			end

			return instance
		end

        return oldGet(self, num, ...)
    end
end)

AddComponentPostInit("finiteuses", function(self, inst)
	function self:Dilute(number, timeleft)
		if self.inst.components.finiteuses then
            local perishtime = self.current
            self.current = (self.inst.components.stackable.stacksize * perishtime + number * timeleft) / ( number + self.inst.components.stackable.stacksize )
			self.inst:PushEvent("percentusedchange", {percent = self:GetPercent()})
		end
	end
end)

-- 克劳斯包掉火箭
AddPrefabPostInit("klaus_sack", function(inst)
	if not TheWorld.ismastersim then
        return
    end
	local old = inst.components.klaussacklock.onusekeyfn
	inst.components.klaussacklock.onusekeyfn = function(inst, key, doer, ...)
		if key.components.klaussackkey and key.components.klaussackkey.truekey then
			LaunchAt(SpawnPrefab("trinket_5"), inst, doer, .2, 1, 1)
		end

		if old then
			return old(inst, key, doer, ...)
		end
	end
end)

AddPrefabPostInit("wx78module_alc_charge", function(inst)
	if inst.charging == nil then
		inst.charging = net_bool(inst.GUID, "inst.charging", "charging")
	end
end)

AddComponentPostInit("upgrademodule", function(self)
	local OldTryActivate = self.TryActivate
	self.TryActivate = function(self, ...)
		if OldTryActivate then
			OldTryActivate(self, ...)
		end
		if self.inst and self.inst.charging then
			self.inst.charging:set(true)
		end
	end

	local OldTryDeactivate = self.TryDeactivate
	self.TryDeactivate = function(self, ...)
		if OldTryDeactivate then
			OldTryDeactivate(self, ...)
		end
		if self.inst and self.inst.charging then
			self.inst.charging:set(false)
		end
	end
end)

-- 位面伤害加成
local tempattacker = nil
local Combat = require("components/combat")
local oldGetAttacked = Combat.GetAttacked
function Combat:GetAttacked(attacker, damage, weapon, stimuli, spdamage, ...)
	spdamage = spdamage or {}
    tempattacker = attacker
    local result = { oldGetAttacked(self, attacker, damage, weapon, stimuli, spdamage, ...) }
    tempattacker = nil
    return unpack(result)
end

local SpDamageUtil = require("components/spdamageutil")
local oldCalcTotalDamage = SpDamageUtil.CalcTotalDamage
SpDamageUtil.CalcTotalDamage = function(tbl)
    local damage = oldCalcTotalDamage(tbl)
    local bouns = 0
    if tempattacker and tempattacker.planarbouns then
        bouns = tempattacker.planarbouns
    end
    return damage + bouns
end

AddComponentPostInit("upgrademoduleowner", function(self, inst)
	local OldPushModule = self.PushModule
	self.PushModule = function(self, module, ...)
		if module == nil then
			return
		end
		if OldPushModule then
			OldPushModule(self, module, ...)
		end
	end
end)