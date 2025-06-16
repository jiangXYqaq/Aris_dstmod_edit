--[[ 要求：当玩家的装备alice_coat内部物品栏的防护板为暗影防护板时，
监听sanitymodechanged，当处于启蒙SANITY_MODE_LUNACY时,启动Activate()，否则关闭Deactivate()。
其他关闭条件：alice_coat内部物品栏的防护板被取出；
玩家取消装备alice_coat。
目前遇到的问题：检测玩家的装备的内部物品栏的物品实际上过于复杂了，并且该装备的equip函数有两套，其防护板有多种，只有一个叫暗影防护板 ]]

local AliceShadowEmbrace = Class(function(self, inst)
    self.inst = inst
    self.active = false
    self.sanity_listener = nil
end)

function AliceShadowEmbrace:OnRemoveFromEntity()
    if self.sanity_listener then
        self.inst:RemoveEventCallback("sanitymodechanged", self.sanity_listener)
    end
end

function AliceShadowEmbrace:CheckSanityMode()
    if self.inst.components.sanity then
        if self.inst.components.sanity:GetSanityMode() == SANITY_MODE_LUNACY then
            self:Activate()
        else
            self:Deactivate()
        end
    else
        self:Deactivate()
    end
end

function AliceShadowEmbrace:Activate()
    if not self.active then
        self.active = true
        
        -- 锁定理智为0
        if self.inst.components.sanity then
            self.inst.components.sanity:SetPercent(0)
            
            -- 监听理智变化事件
            self.sanity_listener = self.inst:ListenForEvent("sanitydelta", function(inst, data)
                if data.newpercent > 0 then
                    inst.components.sanity:SetPercent(0)
                end
            end)
        end
        
        -- 添加90%减伤效果
        if self.inst.components.combat then
            self.inst.components.combat.externaldamagetakenmultipliers:SetModifier("alice_shadow_embrace", 0.1)
        end
    end
end

function AliceShadowEmbrace:Deactivate()
    if self.active then
        self.active = false
        
        -- 移除减伤效果
        if self.inst.components.combat then
            self.inst.components.combat.externaldamagetakenmultipliers:RemoveModifier("alice_shadow_embrace")
        end
        
        -- 移除理智变化监听
        if self.sanity_listener then
            self.inst:RemoveEventCallback("sanitydelta", self.sanity_listener)
            self.sanity_listener = nil
        end
    end
end

return AliceShadowEmbrace