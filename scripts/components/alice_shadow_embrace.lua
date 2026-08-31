--[[ 要求：当玩家的装备alice_coat内部物品栏的防护板为暗影防护板时，
监听sanitymodechanged，当处于启蒙SANITY_MODE_LUNACY时,启动Activate()，否则关闭Deactivate()。
其他关闭条件：alice_coat内部物品栏的防护板被取出；
玩家取消装备alice_coat。
目前遇到的问题：检测玩家的装备的内部物品栏的物品实际上过于复杂了，并且该装备的equip函数有两套，其防护板有多种，只有一个叫暗影防护板
- 被动激活：需要满足（装备alice_coat，内部有暗影防护板，且处于启蒙理智模式）]]

local AliceShadowEmbrace = Class(function(self, inst)
    self.inst = inst
    self.active = false

    self.coat_listener = nil
    self.plate_listener = nil
    self.sanity_listener = nil

    -- 影之支配相关字段
    self.shadow_dominance = false
    self.induced_insanity = false
end)

function AliceShadowEmbrace:OnRemoveFromEntity()
    self:RemoveListeners()
end

-- 统一移除所有监听器
function AliceShadowEmbrace:RemoveListeners()
    if self.coat_listener then
        self.inst:RemoveEventCallback("equip", self.coat_listener)
        self.inst:RemoveEventCallback("unequip", self.coat_listener)
        self.coat_listener = nil
    end
    
    if self.plate_listener then
        self.inst:RemoveEventCallback("itemget", self.plate_listener)
        self.inst:RemoveEventCallback("itemlose", self.plate_listener)
        self.plate_listener = nil
    end
    
    if self.sanity_listener then
        self.inst:RemoveEventCallback("sanitymodechanged", self.sanity_listener)
        self.sanity_listener = nil
    end
end

function AliceShadowEmbrace:CheckConditions()
    local inventory = self.inst.components.inventory
    if not inventory then return false end
    
    -- 遍历所有装备槽位
    for slot, item in pairs(inventory.equipslots) do
        -- 跳过手部和头部装备（仅检查身体相关装备）
        if slot ~= EQUIPSLOTS.HANDS and slot ~= EQUIPSLOTS.HEAD then
            if item and item:HasTag("alice_coat") then
                local container = item.components.container
                if container then
                    -- 获取容器总格数，检查倒数第一格
                    local num_slots = container:GetNumSlots()
                    if num_slots and num_slots > 0 then
                        local innerItem = container:GetItemInSlot(num_slots)
                        if innerItem and innerItem.prefab == "shadow_shield" then
                            return true
                        end
                    end
                end
            end
        end
    end
    
    return false
end

-- 核心状态更新
function AliceShadowEmbrace:UpdateState()
    local shouldActive = self:CheckConditions() and 
                        self.inst.components.sanity and
                        self.inst.components.sanity:GetSanityMode() == SANITY_MODE_LUNACY
    
    if shouldActive then
        self:Activate()
    else
        self:Deactivate()
    end
end

-- 初始化装备监听
function AliceShadowEmbrace:SetupListeners()
    self:RemoveListeners()
    
    -- 装备/卸下监听
    self.coat_listener = function(inst, data)
        if data.item and data.item:HasTag("alice_coat") then
            self:UpdateState()
        end
    end
    self.inst:ListenForEvent("equip", self.coat_listener)
    self.inst:ListenForEvent("unequip", self.coat_listener)
    
    -- 监听自定义防护板事件
    self.shield_loaded_listener = function(inst, data)
        if data.item and data.item.prefab == "shadow_shield" then
            self:UpdateState()
        end
    end
    
    self.shield_unloaded_listener = function(inst, data)
        if data.prefab and data.prefab == "shadow_shield" then
            self:UpdateState()
        end
    end
    self.inst:ListenForEvent("alice_coat_shield_loaded", self.shield_loaded_listener)
    self.inst:ListenForEvent("alice_coat_shield_unloaded", self.shield_unloaded_listener)
    
    -- 理智模式监听
    self.sanity_listener = function(inst)
        self:UpdateState()
    end
    self.inst:ListenForEvent("sanitymodechanged", self.sanity_listener)
    
    -- 初始状态检查
    self:UpdateState()
end

-- 添加影之支配效果
function AliceShadowEmbrace:ApplyShadowDominance()
    if self.shadow_dominance then
        return  -- 效果已存在
    end
    
    self.shadow_dominance = true
    
    -- 添加标签使影怪不会攻击玩家
    self.inst:AddTag("shadowdominance")
    
    -- 设置诱导疯狂（使理智值显示为0但实际不变）
    if self.inst.components.sanity then
        self.inst.components.sanity:SetInducedInsanity(self.inst, true)
        self.induced_insanity = true
    end
end

-- 移除影之支配效果
function AliceShadowEmbrace:RemoveShadowDominance()
    if not self.shadow_dominance then
        return  -- 效果不存在
    end
    
    self.shadow_dominance = false
    
    -- 移除标签
    if self.inst:HasTag("shadowdominance") then
        self.inst:RemoveTag("shadowdominance")
    end
    
    -- 取消诱导疯狂
    if self.induced_insanity and self.inst.components.sanity then
        self.inst.components.sanity:SetInducedInsanity(self.inst, false)
        self.induced_insanity = false
    end
end

-- 应用免疫效果
function AliceShadowEmbrace:ApplyImmunityEffects()
    if self.immunity_applied then
        return
    end
    
    self.immunity_applied = true
    
    -- 1. 防冰冻：修改freezable组件行为
    if self.inst.components.freezable then
        self.original_AddColdness = self.inst.components.freezable.AddColdness
        self.inst.components.freezable.AddColdness = function(_, coldness, ...)
            if coldness > 0 then
                return
            end
            self.original_AddColdness(self.inst.components.freezable, coldness, ...)
        end
        if self.inst.components.freezable:IsFrozen() then
            self.inst.components.freezable:Unfreeze()
        end
        self.inst.components.freezable.coldness = 0
        self.inst.components.freezable:UpdateTint()
    end

    -- 2. 防催眠：修改grogginess组件行为
    if self.inst.components.grogginess then
        self.original_AddGrogginess = self.inst.components.grogginess.AddGrogginess
        self.inst.components.grogginess.AddGrogginess = function(_, grogginess, ...)
            if grogginess > 0 then
                return
            end
            self.original_AddGrogginess(self.inst.components.grogginess, grogginess, ...)
        end
        if self.inst.components.grogginess.grog_amount > 0 then
            self.inst.components.grogginess:ResetGrogginess()
        end
    end

    -- 3. 免疫环境减速
    if self.inst.components.sandstormwatcher then
        self.inst.components.sandstormwatcher:SetSandstormSpeedMultiplier(1)
    end
    if self.inst.components.moonstormwatcher then
        self.inst.components.moonstormwatcher:SetMoonstormSpeedMultiplier(1)
    end
    if self.inst.components.miasmawatcher then
        self.inst.components.miasmawatcher:SetMiasmaSpeedMultiplier(1)
    end
    if self.inst.components.carefulwalker then
        self.inst.components.carefulwalker:SetCarefulWalkingSpeedMultiplier(1)
    end
    
    if self.inst and not self.inst:HasTag("alice_bati") then
        self.inst:AddTag("alice_bati")
    end
end

-- 移除免疫效果
function AliceShadowEmbrace:RemoveImmunityEffects()
    if not self.immunity_applied then
        return
    end
    
    self.immunity_applied = false
    
    if self.inst.components.freezable and self.original_AddColdness then
        self.inst.components.freezable.AddColdness = self.original_AddColdness
        self.original_AddColdness = nil
    end
    
    if self.inst.components.grogginess and self.original_AddGrogginess then
        self.inst.components.grogginess.AddGrogginess = self.original_AddGrogginess
        self.original_AddGrogginess = nil
    end

    if self.inst and self.inst:HasTag("alice_bati") then
        self.inst:RemoveTag("alice_bati")
    end
end

local function NoHoles(pt)
    return not TheWorld.Map:IsPointNearHole(pt)
end

function AliceShadowEmbrace:SetupTentacleAttack()
    if self.ontentacleattack then return end
    
    self.ontentacleattack = function(inst, data)
        if data.target and data.target:IsValid() and math.random() < 0.3 then
            local pt = data.target:GetPosition()
            local offset = FindWalkableOffset(pt, math.random() * TWOPI, 2, 3, false, true, NoHoles, false, true)
            if offset then
                local tentacle = SpawnPrefab("alice_shadowtentacle")
                if tentacle then
                    tentacle.Transform:SetPosition(pt.x + offset.x, 0, pt.z + offset.z)
                    tentacle.components.combat:SetTarget(data.target)
                    tentacle.owner = self.inst
                end
            end
        end
    end
end

function AliceShadowEmbrace:EnableTentacleAttack()
    if not self.ontentacleattack then
        self:SetupTentacleAttack()
    end
    self.inst:ListenForEvent("onattackother", self.ontentacleattack)
end

function AliceShadowEmbrace:DisableTentacleAttack()
    if self.ontentacleattack then
        self.inst:RemoveEventCallback("onattackother", self.ontentacleattack)
    end
end

function AliceShadowEmbrace:Activate()
    if self.active then
        return
    end
    
    self.active = true
    
    self:ApplyShadowDominance()
    
    if self.inst.components.combat then
        self.inst.components.combat.externaldamagetakenmultipliers:SetModifier("alice_shadow_embrace", 0.1)
    end

    self:ApplyImmunityEffects()
    self:EnableTentacleAttack()
end

function AliceShadowEmbrace:Deactivate()
    if not self.active then
        return
    end
    
    self.active = false
    
    self:RemoveShadowDominance()
    
    if self.inst.components.combat then
        self.inst.components.combat.externaldamagetakenmultipliers:RemoveModifier("alice_shadow_embrace")
    end

    self:RemoveImmunityEffects()
    self:DisableTentacleAttack()
end

return AliceShadowEmbrace