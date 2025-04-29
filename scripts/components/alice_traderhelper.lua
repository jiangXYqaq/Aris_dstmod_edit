--- 主客机通用组件，用于辅助trader组件
local TraderHelper = Class(function(self, inst)
    self.inst = inst

    self.test = nil  --nil|function(inst, item, giver)，客机校验函数，如果有值并且结果为false则拦截ACTIONS.GIVE
    self.str = nil   --nil|string|function(inst, item, giver)，用于ACTION.GIVE的str函数返回值
    --self.state = nil --nil|string|function(inst, item, giver)，使用的状态，需要注意延迟补偿下客机调用的情况

    if not TheWorld.ismastersim then return end

    --self.extra_arrive_dist = nil --nil|function(inst, item, giver)，动作执行的额外距离
end)

return TraderHelper