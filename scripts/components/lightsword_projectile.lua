local MATH = require "alice_utils.math"
local Polygon = MATH.Polygon

local function OnThrown(inst, owner, target)
    inst:StopUpdatingComponent(inst.components.projectile)
    inst.components.lightsword_projectile:OnTrow(inst, owner, target)
end

local LightSword_projectile = Class(function(self, inst)
    self.inst = inst

    self.hits = {} --记录命中的对象
    self.hitcount = 0 --当前命中次数
    self.maxhits = 1 --最大命中次数
    self.lightatk = false --闪电攻击

    self.range = 15
    self.width = 6 --碰撞宽度

    self.onthrown = nil 
    self.onhit = nil

    self.removeonhit = true

    self.spdamage = nil
    assert(inst.components.projectile ~= nil)

    inst.components.projectile.onthrown = OnThrown
end)

local function SortByDist(origin)
    local origin = Vector3(origin.x, 0, origin.z)
    return function(a, b)
        return a:GetDistanceSqToPoint(origin) < b:GetDistanceSqToPoint(origin)
    end
end

function LightSword_projectile:SetOnHitFn(fn)
    self.onhit = fn
end

function LightSword_projectile:OnUpdate(dt)
    if self.stopupdating then
        self.inst:StopUpdatingComponent(self)
        return
    end

    local lastpos = self.lastpos
    local currentpos = self.inst:GetPosition()
    local firstframe = self.startpos == self.lastpos

    --检查是否超过最大射程
    if self.totaldist > self.range then
        self:Miss()
        return
    end

    -- Search and hit
    if lastpos ~= nil then
        if currentpos.x ~= lastpos.x or currentpos.z ~= lastpos.z then
            local offset = currentpos - lastpos
            offset.y = 0
            local dir, len = offset:GetNormalizedAndLength()
            self.totaldist = self.totaldist + len

            currentpos = currentpos + dir * 0.50

            local center = (currentpos + lastpos)/2
            local offset = Vector3(dir.z, 0, -dir.x)*(self.width / 2)
            local rect = Polygon{
                currentpos + offset, currentpos - offset, 
                lastpos - offset, lastpos + offset,
            }

            local ents = TheSim:FindEntities(center.x, 0, center.z, len + self.width + 2,
                nil, {"INLIMBO", "FX", "companion", "abigail", "wall"}, {"_combat", "_workable", "cattoy"})--增加对墙和阿比盖尔的豁免
            table.sort(ents, SortByDist(lastpos))
            for i,v in ipairs(ents)do
                
                if rect:IsEntityIn(v) then
                    if self.hitcount < self.maxhits then 
                        self:Hit(v)
                    end
                end
            end
        end

        self.lastpos = self.inst:GetPosition()
    end
end

function LightSword_projectile:Hit(target)
    if self.hits[target] == true then
        return
    else
        self.hits[target] = true
    end

    if target ~= self.player and 
        target.components.health and 
        target.components.combat and
        not target.components.health:IsDead() and
        not (target.components.domesticatable and target.components.domesticatable:IsDomesticated())
        and target.components.combat:CanBeAttacked(self.player) then 

        local numhits = math.ceil(target:GetPhysicsRadius(0))
        numhits = math.min(numhits, self.maxhits - self.hitcount)
        numhits = math.max(1, numhits)

        for i = 1, numhits do
            self:Attack(target)
            self.hitcount = self.hitcount + 1
        end
    end

    if self.hitcount == self.maxhits then
        self:OnMaxHits()
    end
end

local function IsNotDead(inst)
    return inst.components.health and not inst.components.health:IsDead()
end

function LightSword_projectile:Attack(target)
    local attacker = self.player or CreateEntity()
    local isplayer = target:HasTag("player")
    local externaldamagemultipliers = (self.player and self.player.components.combat and self.player.components.combat.externaldamagemultipliers:Get()) or 1

    if IsNotDead(target) then
        local weapon = self.owner
        local defaultdamage = weapon.components.alice_sword:GeDamage()
        local damage = defaultdamage * externaldamagemultipliers

        if self.player.components.combat and self.player.components.combat.customdamagemultfn then
            damage = damage * self.player.components.combat.customdamagemultfn(self.player, target)
        end
        local stimuli = nil
        if self.lightatk or self.player.components.electricattacks ~= nil then
            stimuli = "electric"
        end

        local _weapon_cmp = weapon ~= nil and weapon.components.weapon or nil
        if  (stimuli == "electric" or (_weapon_cmp ~= nil and _weapon_cmp.stimuli == "electric")) and 
                not (target:HasTag("electricdamageimmune") or (target.components.inventory ~= nil and target.components.inventory:IsInsulated()))
        then
            local electric_damage_mult = _weapon_cmp ~= nil and _weapon_cmp.electric_damage_mult or TUNING.ELECTRIC_DAMAGE_MULT
            local electric_wet_damage_mult = _weapon_cmp ~= nil and _weapon_cmp.electric_wet_damage_mult or TUNING.ELECTRIC_WET_DAMAGE_MULT

            local mult = electric_damage_mult + electric_wet_damage_mult * (target.components.moisture ~= nil and target.components.moisture:GetMoisturePercent() or (target:GetIsWet() and 1 or 0))
            damage = damage * mult
        end


        target.components.combat:GetAttacked(self.player, damage, weapon, stimuli, self.spdamage or nil)
        self.player:PushEvent("lightswordshot")

        if self.onhit then
            self.onhit(target, self.inst)
        end
        
        weapon:DoTaskInTime(0, function()
            local mode = weapon.components.alice_sword.mode -- 使用EX后更换为上一次模式
            local oldmode = weapon.components.alice_sword.lastmode
            if mode == 3 and oldmode then
                weapon.components.alice_sword:ChangeMode(oldmode, true)
            end
        end)
    end
end

--未命中
function LightSword_projectile:Miss()
    if self.onmissfn then
        self.onmissfn(self.inst, self.player, self.target)
    end

    self.inst:Remove()
end

--达到最大攻击次数
function LightSword_projectile:OnMaxHits()
    if not self.inst:IsValid() then
        return
    end

    if self.onmaxhitsfn then
        self.onmaxhitsfn(self.inst, self.player, self.target)
    end

    if self.removeonhit then
        self.inst:Remove()
    end
end

--记录目标位置
function LightSword_projectile:RecordTargetPosition()
    if self.target ~= nil and self.target:IsValid() and self.target.Transform ~= nil then
        self.targetpos = self.target:GetPosition()
        self.targetpos.y = 0
    end
    return self.targetpos
end

function LightSword_projectile:OnTrow(inst, owner, target)
    local projectile = inst.components.projectile
    local target = projectile.target

    self.target = target
    self:RecordTargetPosition()
    self.owner = owner  -- Gun

    if owner.components.combat == nil and owner.components.weapon ~= nil and owner.components.inventoryitem ~= nil then
        self.player = owner.components.inventoryitem.owner
    end


    --重设速度
    if self.speed then
        inst.Physics:SetMotorVel(self.speed, 0, 0)
    end
    
    --重设距离
    if self.infinite_range then
        self.range = math.huge 
        self.inst:DoTaskInTime(10, function() self:Miss() end)
    end

    if self.onthrown ~= nil then
        self.onthrown(inst, owner, target, player)
    end

    self.lastpos = self.player and self.player:GetPosition() or self.inst:GetPosition()
    self.startpos = self.lastpos
    self.totaldist = 0
    
    self:OnUpdate(FRAMES) -- First hit / reflect
    self.inst:StartUpdatingComponent(self)
end

return LightSword_projectile