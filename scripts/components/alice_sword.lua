--[[ 1~连射模式 2~能量炮弹 3~EX技能 4~高能激光刀刃
连射模式：攻速1.25次每秒，范围中等的光波攻击，光波飞行速度较慢，一般只会命中单个目标
能量炮弹：攻速1.25次每秒，范围中等的炮弹攻击，炮弹飞行时经过的单位会造成1次伤害，落地爆炸后造成第二次伤害
    ，两次伤害均为无衰减的AOE。且可以破坏可工作物品，如砍树或挖矿。
EX技能：冷却时间15秒，需要蓄力3秒释放，单次的大范围激光炮攻击，无衰减AOE
高能激光刀刃：需要蓄力3秒，开始攻击后每0.1秒造成1次伤害，为范围中等的激光攻击，无衰减AOE，释放期间可以移动。
解锁条件：
1初始0级，需要巨鹿眼球升级；
2初始没有解锁，需要击败克劳斯或远古守护者犀牛解锁0级，后续击败克劳斯或远古守护者可以升1级；
3初始0级，需要彩虹宝石升级。
4初始没有解锁，需要击败天体英雄或织影者解锁，后续每次击败可升1级。
最大等级 = {5, 5, 5, 1} 注意，-1级代表没有解锁，0级为实际上的1级]]
local Sword = Class(function(self, inst)
	self.inst = inst

	self.mode = 1 
    self.shotmode = 1
	self.changefn = nil
    self.container = inst.components.container
    
    self.level = {0, -1, -1, -1}
    self.maxlevel = {5, 5, 5, 1}
    
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

function Sword:GetDamage(hit_type)
    local mode = self.shotmode
    local level = self:GeLevel()
    local damage = 0 
    --1~连射模式 2~能量炮弹 3~EX技能 4~高能激光刀刃
    if mode == 1 then --此处更改了成长后的伤害，因此升级后提升更大，约200%
        damage = TUNING.ALICE_LIGHTSWORD_DAMAGE * (2.0 + level * 1.5)
    elseif mode == 2 then
        -- 更清晰的命中类型区分
        if hit_type == "direct" then
            -- 直接命中伤害（飞行中）
            damage = TUNING.ALICE_LIGHTSWORD_DAMAGE * (1.0 + level * 1.2)
        else
            -- 爆炸范围伤害（落地后）
            damage = TUNING.ALICE_LIGHTSWORD_DAMAGE * (1.5 + level * 2.0)
        end
    elseif mode == 3 then
        damage = TUNING.ALICE_LIGHTSWORD_DAMAGE * (25 + level * 15)
    elseif mode == 4 then
        damage = TUNING.ALICE_LIGHTSWORD_MODE4_PLANAR_DAMAGE_BASE + TUNING.ALICE_LIGHTSWORD_MODE4_PLANAR_DAMAGE_PER_LEVEL * level
    end
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
    -- 从 TUNING 读取当前模式的消耗值
    local mode_uses = {
        [1] = TUNING.ALICE_LIGHTSWORD_USE_MODE1,
        [2] = TUNING.ALICE_LIGHTSWORD_USE_MODE2,
        [3] = TUNING.ALICE_LIGHTSWORD_USE_MODE3,
        [4] = TUNING.ALICE_LIGHTSWORD_USE_MODE4,
    }
    local use = mode_uses[self.mode] or 1

    if item and item.components.fueled then  -- 改为 fueled
        item.components.fueled:DoDelta(-use)
    end

    local owner = self.inst.components.inventoryitem and self.inst.components.inventoryitem.owner
    if owner and owner.weaponui then
        owner.weaponui:Update()
    end
end

function Sword:CheckFuelUses()
    local item = self:Sword_GetCurrentItem()
    local mode_uses = {
        [1] = TUNING.ALICE_LIGHTSWORD_USE_MODE1,
        [2] = TUNING.ALICE_LIGHTSWORD_USE_MODE2,
        [3] = TUNING.ALICE_LIGHTSWORD_USE_MODE3,
        [4] = TUNING.ALICE_LIGHTSWORD_USE_MODE4,
    }
    local min = (mode_uses[self.mode] or 1) / 100
    if item and item.components.fueled then
        if item.components.fueled:GetPercent() > 0 then
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
    if self:CheckFuelUses() then
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
    if pos and self:CheckFuelUses() then
        local target = CreateTargetInPos(pos)
        self.inst.components.weapon:LaunchProjectile(user, target)
        self:DoItemUse()
    end
end

AddModRPCHandler("alice", "switch_to_ex_mode", function(player)
    local sword = player.components.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HANDS)
	--print("sword=", sword)
    -- 直接通过Prefab名称判断武器类型
    if sword and sword.prefab == "alice_lightsword" then
		--print("hand=alice_sword")
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