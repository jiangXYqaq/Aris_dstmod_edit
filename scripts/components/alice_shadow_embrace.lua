--[[ 要求：当玩家的装备alice_coat内部物品栏的防护板为暗影防护板时，
监听sanitymodechanged，当处于启蒙SANITY_MODE_LUNACY时,启动Activate()，否则关闭Deactivate()。
其他关闭条件：alice_coat内部物品栏的防护板被取出；
玩家取消装备alice_coat。
目前遇到的问题：检测玩家的装备的内部物品栏的物品实际上过于复杂了，并且该装备的equip函数有两套，其防护板有多种，只有一个叫暗影防护板
- 被动激活：需要满足（装备alice_coat，内部有暗影防护板，且处于启蒙理智模式）

- 主动激活：需要满足（装备alice_coat，内部有暗影防护板，且在5秒内完成卸下-装回操作），持续60秒。 ]]

local AliceShadowEmbrace = Class(function(self, inst)
    self.inst = inst
    self.active = false
    -- 新增快速更换相关字段
    self.last_plate_remove_time = nil  -- 记录上次卸下防护板的时间
    self.quick_swap_timer = nil       -- 5秒计时器
    self.manual_active = false        -- 手动激活状态
    self.manual_timer = nil           -- 60秒激活计时器

    self.coat_listener = nil
    self.plate_listener = nil
    self.sanity_listener = nil

     -- 影之支配相关字段
    self.shadow_dominance = false
    self.induced_insanity = false

    print("[AliceShadowEmbrace] Component initialized for:", inst)
end)

function AliceShadowEmbrace:OnRemoveFromEntity()
    print("[AliceShadowEmbrace] OnRemoveFromEntity called")
    self:RemoveListeners()
    -- 清理所有计时器
    if self.quick_swap_timer then
        self.quick_swap_timer:Cancel()
        self.quick_swap_timer = nil
    end
    if self.manual_timer then
        self.manual_timer:Cancel()
        self.manual_timer = nil
    end
end

-- 统一移除所有监听器
function AliceShadowEmbrace:RemoveListeners()
    print("[AliceShadowEmbrace] Removing all listeners")
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

-- 核心状态检查函数
function AliceShadowEmbrace:CheckConditions()
    print("[AliceShadowEmbrace] Checking conditions")
    -- 获取当前装备的alice_coat
    local coat = self.inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
    
    -- 检查是否装备了alice_coat且内部有暗影防护板
    if coat and coat:HasTag("alice_coat") then
        print("[AliceShadowEmbrace] Alice coat equipped")
        local container = coat.components.container
        if container then
            for slot = 1, container:GetNumSlots() do
                local item = container:GetItemInSlot(slot)
                if item and item.prefab == "shadow_shield" then
                    print("[AliceShadowEmbrace] Shadow shield found in slot:", slot)
                    return true
                end
            end
        end
    end
    print("[AliceShadowEmbrace] Conditions not met")
    return false
end

-- 核心状态更新
function AliceShadowEmbrace:UpdateState()
    print("[AliceShadowEmbrace] Updating state")
    -- 手动激活期间忽略理智检查
    if self.manual_active then
        print("Manual active - forcing activation")
        if not self.active then
            self:Activate()
        end
        return
    end
    
    -- 被动激活逻辑
    local shouldActive = self:CheckConditions() and 
                        self.inst.components.sanity and
                        self.inst.components.sanity:GetSanityMode() == SANITY_MODE_LUNACY
    
    if shouldActive then
        print("[AliceShadowEmbrace] Activating")
        self:Activate()
    else
        print("[AliceShadowEmbrace] Deactivating")
        self:Deactivate()
    end
end

-- 修改手动激活函数 - 直接激活效果
function AliceShadowEmbrace:TriggerManualActivate()
    print("[TriggerManualActivate] Starting manual activation")
    
    -- 清除快速更换计时器
    if self.quick_swap_timer then
        self.quick_swap_timer:Cancel()
        self.quick_swap_timer = nil
    end
    self.last_plate_remove_time = nil
    
    -- 设置手动激活状态
    self.manual_active = true
    print("Manual active set to true")
    
    -- 刷新或启动60秒计时器
    if self.manual_timer then
        print("Canceling existing manual timer")
        self.manual_timer:Cancel()
    end
    
    print("Starting 60-second timer")
    self.manual_timer = self.inst:DoTaskInTime(60, function()
        print("Manual activation period ended")
        self.manual_active = false
        self:UpdateState()  -- 回退到被动检查
    end)
    
    -- 直接激活效果，不通过UpdateState
    self:Activate()
    
    print("Manual activation complete")
end

-- 初始化装备监听
function AliceShadowEmbrace:SetupListeners()
    print("[AliceShadowEmbrace] Setting up listeners")
    self:RemoveListeners()
    
    -- 装备/卸下监听
    self.coat_listener = function(inst, data)
        print("[AliceShadowEmbrace] Coat listener triggered:", data.item and data.item.prefab)
        if data.item and data.item:HasTag("alice_coat") then
            self:UpdateState()
        end
    end
    self.inst:ListenForEvent("equip", self.coat_listener)
    self.inst:ListenForEvent("unequip", self.coat_listener)
    
    -- 监听自定义防护板事件
    self.shield_loaded_listener = function(inst, data)
        print("[AliceShadowEmbrace] Shield loaded listener triggered")
        print("Data contents:", data) -- Debug information
        if data.item and data.item.prefab == "shadow_shield" then
            print("Shadow shield loaded into alice_coat")
            
            -- 检查是否在5秒内重新装备
            if self.last_plate_remove_time then
                local time_diff = GetTime() - self.last_plate_remove_time
                print(string.format("Time since removal: %.2f seconds", time_diff))
                
                if time_diff <= 5 then
                    print("Quick swap detected - triggering manual activation")
                    self:TriggerManualActivate()
                else
                    print("Normal equipment - updating state")
                    self:UpdateState()
                end
            else
                print("No previous removal time - updating state")
                self:UpdateState()
            end
        end
    end
    
    self.shield_unloaded_listener = function(inst, data)
        print("[AliceShadowEmbrace] Shield unloaded listener triggered")
        print("Data contents:", data) -- Debug information
        if data.prefab and data.prefab == "shadow_shield" then
            print("Shadow shield unloaded from alice_coat")
            
            self.last_plate_remove_time = GetTime()
            
            -- 启动5秒计时器
            if self.quick_swap_timer then
                self.quick_swap_timer:Cancel()
            end
            self.quick_swap_timer = self.inst:DoTaskInTime(5, function()
                print("Quick swap window expired")
                self.last_plate_remove_time = nil
                self.quick_swap_timer = nil
            end)
            
            -- 更新状态
            self:UpdateState()
        end
    end
    self.inst:ListenForEvent("alice_coat_shield_loaded", self.shield_loaded_listener)
    self.inst:ListenForEvent("alice_coat_shield_unloaded", self.shield_unloaded_listener)
    
    -- 理智模式监听
    self.sanity_listener = function(inst)
        print("[AliceShadowEmbrace] Sanity mode changed")
        self:UpdateState()
    end
    self.inst:ListenForEvent("sanitymodechanged", self.sanity_listener)
    
    -- 初始状态检查
    self:UpdateState()
end

-- 新增：添加影之支配效果
function AliceShadowEmbrace:ApplyShadowDominance()
    print("[AliceShadowEmbrace] Applying shadow dominance")
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

-- 移除影之支配效果（修复缺失的方法）
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
    
    print("[AliceShadowEmbrace] Shadow dominance removed")
end

-- 在ApplyImmunityEffects中添加防冰冻实现
function AliceShadowEmbrace:ApplyImmunityEffects()
    print("[AliceShadowEmbrace] Applying immunity effects")
    if self.immunity_applied then
        return
    end
    
    self.immunity_applied = true
    
    -- 1. 防冰冻：修改freezable组件行为
    if self.inst.components.freezable then
        -- 保存原始函数
        self.original_AddColdness = self.inst.components.freezable.AddColdness
        
        -- 覆盖AddColdness方法
        self.inst.components.freezable.AddColdness = function(_, coldness, ...)
            if coldness > 0 then
                -- 阻止任何增加冰冻值的操作
                return
            end
            -- 允许减少冰冻值的操作
            self.original_AddColdness(self.inst.components.freezable, coldness, ...)
        end
        
        -- 立即清除现有冰冻状态
        if self.inst.components.freezable:IsFrozen() then
            self.inst.components.freezable:Unfreeze()
        end
        self.inst.components.freezable.coldness = 0
        self.inst.components.freezable:UpdateTint()
    end

    -- 2. 防催眠：修改grogginess组件行为
    if self.inst.components.grogginess then
        -- 保存原始函数
        self.original_AddGrogginess = self.inst.components.grogginess.AddGrogginess
        
        -- 覆盖AddGrogginess方法
        self.inst.components.grogginess.AddGrogginess = function(_, grogginess, ...)
            if grogginess > 0 then
                -- 阻止任何增加催眠值的操作
                return
            end
            -- 允许减少催眠值的操作
            self.original_AddGrogginess(self.inst.components.grogginess, grogginess, ...)
        end
        
        -- 立即清除现有催眠状态
        if self.inst.components.grogginess.grog_amount > 0 then
            self.inst.components.grogginess:SetGrogginess(0)
        end
    end

    -- 3. 免疫环境减速（保留）
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
    
    -- ... 其他免疫效果 ...
end

-- 在RemoveImmunityEffects中恢复原始行为
function AliceShadowEmbrace:RemoveImmunityEffects()
    print("[AliceShadowEmbrace] Removing immunity effects")
    if not self.immunity_applied then
        return
    end
    
    self.immunity_applied = false
    
    -- 1. 恢复freezable组件原始行为
    if self.inst.components.freezable and self.original_AddColdness then
        self.inst.components.freezable.AddColdness = self.original_AddColdness
        self.original_AddColdness = nil
    end
    
    -- 2、恢复grogginess组件原始行为
    if self.inst.components.grogginess and self.original_AddGrogginess then
        self.inst.components.grogginess.AddGrogginess = self.original_AddGrogginess
        self.original_AddGrogginess = nil
    end
    -- ... 其他免疫效果的恢复 ...
end

function AliceShadowEmbrace:Activate()
    -- 手动激活期间总是允许激活
    print("manual_active:", self.manual_active, "active:", self.active)
    if self.manual_active and not self.active then
        print("Manual activation - activating effects")
        self.active = true
        
        -- 统一应用影之支配效果（不再区分主动/被动）
        self:ApplyShadowDominance()
        
        -- 添加90%减伤效果
        if self.inst.components.combat then
            self.inst.components.combat.externaldamagetakenmultipliers:SetModifier("alice_shadow_embrace", 0.1)
        end

        -- 添加免疫效果：防冰冻、防催眠、免疫减速
        self:ApplyImmunityEffects()
    end

    -- 非手动激活的正常检查
    if not self.active then
        print("Manual activation - activating effects")
        self.active = true
        
        -- 统一应用影之支配效果（不再区分主动/被动）
        self:ApplyShadowDominance()
        
        -- 添加90%减伤效果
        if self.inst.components.combat then
            self.inst.components.combat.externaldamagetakenmultipliers:SetModifier("alice_shadow_embrace", 0.1)
        end

        -- 添加免疫效果：防冰冻、防催眠、免疫减速
        self:ApplyImmunityEffects()
    end
end



function AliceShadowEmbrace:Deactivate()
    -- 手动激活期间不执行停用
    if self.manual_active then
        print("Manual active - skipping deactivation")
        return
    end

    if self.active then
        print("[AliceShadowEmbrace] Deactivating effects")
        self.active = false
        
        -- 统一移除影之支配效果
        self:RemoveShadowDominance()
        -- 移除减伤效果
        if self.inst.components.combat then
            self.inst.components.combat.externaldamagetakenmultipliers:RemoveModifier("alice_shadow_embrace")
        end

        -- 移除免疫效果
        self:RemoveImmunityEffects()
    end
end

return AliceShadowEmbrace