return {
    MAJOR = 1,
    MINOR = 3,
    PATCH = 3, -- Updated patch version for the latest release
    SUFFIX = "dev" -- Stable release
    --[[ 如果同时装备暗影防护板和有5枚lunar_seed的启迪之冠
    此时状态为启蒙0，不会有影怪也不会有月灵。
    1、玩家不会被查理攻击（目前设置为永久效果）
    2、额外的补偿：如果在洞穴世界，获得夜视效果。
    3、攻击附加效果：生成小触手（铥矿棒攻击），
        参考小虚影的设置，让小触手的攻击也能附带位面伤害。 ]]
}