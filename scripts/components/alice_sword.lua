local Sword = Class(function(self, inst)
	self.inst = inst

	self.mode = 1 -- 1~连射模式 2~能量炮弹 3~EX技能 4~高能激光刀刃
    self.shotmode = 1
	self.changefn = nil
    self.container = inst.components.container
    
    self.level = {0, -1, 0, -1}
    self.maxlevel = {10, 4, 5, 5}

    self.uses = {1, 2, 5, 0.1}
    
    self.lastmode = nil

    local replica = self.inst.replica.alice_sword
    if replica then
        replica:UpdateClientLevels(self.level)
    end
end)

function Sword:ChangeMode(num, talk)
    self.lastmode = self.mode
	self.mode = num

	if self.changefn then
		self.changefn(self.inst, num, talk)
	end

    local replica = self.inst.replica.alice_sword
    if replica then
        replica:SetMode(self.mode)
    end
end

function Sword:SetChangeFn(fn)
	self.changefn = fn
end

function Sword:GetCurrentMode()
	return self.mode
end

function Sword:IsMaxLevel(mode)
    if self.level[mode] >= self.maxlevel[mode] then
        return true
    end
    return false
end

function Sword:LevelUp(mode)
    if self:IsMaxLevel(mode) then
        return false, "Max Level"
    end
    self.level[mode] = self.level[mode] + 1

    local replica = self.inst.replica.alice_sword
    if replica then
        replica:UpdateClientLevels(self.level)
    end

    return true, self.level[mode]
end

function Sword:GetModeString()
	return STRINGS.LIGHTSWORD_MODE[self.mode] or ""
end

function Sword:GeLevel(mode)
    mode = mode or self:GetCurrentMode()
    return self.level[mode]
end

function Sword:GeDamage(fly)
    local mode = self.shotmode
    local level = self:GeLevel()
    local damage = 0
    
    if mode == 1 then --此处更改了成长后的伤害，因此升级后提升更大，约200%
        damage = TUNING.ALICE_LIGHTSWORD_DAMAGE * (1 + level * 0.8)
    elseif mode == 2 then
        damage = fly and (TUNING.ALICE_LIGHTSWORD_DAMAGE * (2 + level * 4)) or (TUNING.ALICE_LIGHTSWORD_DAMAGE * (2 + level * 1))
    elseif mode == 3 then
        damage = TUNING.ALICE_LIGHTSWORD_DAMAGE * (10 + level * 5)
    elseif mode == 4 then
        damage = TUNING.ALICE_LASERTHROW_PLANAR_DAMAGE_MIN + TUNING.ALICE_LASERTHROW_PLANAR_DAMAGE_UP * level
    end
    --print("mode:", mode, "level: ", level, "damage: ", damage)
    return damage
end

function Sword:OnSave()
    return
    {
        mode = self.mode,
        level = self.level,
        lastmode = self.lastmode,
    }
end

function Sword:OnLoad(data)
    if data then
        self.mode = data.mode
        self.level = data.level
        self.lastmode = data.lastmode
        if self.changefn then
            self.changefn(self.inst, self.mode)
        end
    end
    
    if TheWorld.ismastersim then
        self.inst:DoTaskInTime(0, function()
            local replica = self.inst.replica.alice_sword
            if replica then
                replica:SetMode(self.mode)
                replica:UpdateClientLevels(self.level)
            end
        end)
    end
end

function Sword:Sword_GetCurrentItem()
    if not self.container then return nil end
    local item = self.container:GetItemInSlot(1)
    return item
end

function Sword:DoItemUse()
    local item = self:Sword_GetCurrentItem()
    local use = self.uses[self.mode]
    local owner = self.inst.components.inventoryitem and self.inst.components.inventoryitem.owner

    if item and item.components.finiteuses then
        item.components.finiteuses:Use(use)
    end

    if owner and owner.weaponui then
		owner.weaponui:Update()
	end
end

function Sword:Checkfiniteuses()
    local item = self:Sword_GetCurrentItem()
    local min = self.uses[self.mode] / 100
    if item and item.components.finiteuses then
        if item.components.finiteuses:GetPercent() > 0 then
            return true
        else
            local owner = self.inst.components.inventoryitem and self.inst.components.inventoryitem.owner
            if owner and owner.components.talker then
                SendModRPCToClient(CLIENT_MOD_RPC["alice"]["lightsword_nofinitiness"], owner.userid, nil)
                owner.components.talker:Say(STRINGS.ACTIONS.LIGHTSWORD.NOFINITINESS)
            end
        end
    end
    return false
end

local function CreateTargetInPos(pos)
    local target = CreateEntity()
    target.entity:AddTransform()
    target.Transform:SetPosition(pos.x, pos.y, pos.z)
    target:DoTaskInTime(0, target.Remove)
    return target
end

function Sword:LaunchLaser(user, pos)
    self.shotmode = self:GetCurrentMode()
    if self:Checkfiniteuses() then
        local rotation = user.Transform:GetRotation()
        local px, py, pz = user.Transform:GetWorldPosition()
        local offset = Vector3(1.5, 0.5, 0)
        
        local laser = SpawnPrefab("alice_laser_firefx")
        local facing_angle = user.Transform:GetRotation() * DEGREES
        laser.Transform:SetPosition(px + offset.x * math.cos(facing_angle), py + offset.y, pz - offset.x * math.sin(facing_angle))
        laser.Transform:SetRotation(rotation)

        if pos then
            user:DoTaskInTime(.3, function()
                local target = CreateTargetInPos(pos)
                self.inst.components.weapon:LaunchProjectile(user, target)
            end)
        end
        self:DoItemUse()
    end
end

function Sword:Launch(user, pos)
    self.shotmode = self:GetCurrentMode()
    if pos and self:Checkfiniteuses() then
        local target = CreateTargetInPos(pos)
        self.inst.components.weapon:LaunchProjectile(user, target)
        self:DoItemUse()
    end
end

AddModRPCHandler("alice", "switch_to_ex_mode", function(player)
    local sword = player.components.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HANDS)
	print("sword=", sword)
    -- 直接通过Prefab名称判断武器类型
    if sword and sword.prefab == "alice_lightsword" then
		print("hand=alice_sword")
        local sword_component = sword.components.alice_sword
        if sword_component.mode ~= 3 then
            -- 切换到EX模式
            sword_component:ChangeMode(3)
            -- 显示提示
            if player.components.talker then
                player.components.talker:Say(sword_component:GetModeString())
            end
        end
    end
end)

return Sword