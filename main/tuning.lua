GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})

local function GetKeyFromConfig(configName, defaultKey)
    local configValue = GetModConfigData(configName)
    
    -- 如果用户选择了"禁用"，直接返回 false
    if configValue == false then
        return false
    end
    
    -- 如果返回的是字符串（如 "KEY_Q"），转换为实际的键值常量
    if type(configValue) == "string" then
        return _G[configValue] or defaultKey
    end
    
    -- 其他情况返回默认键
    return defaultKey
end

-- 三维 175 200 175
TUNING.ALICE_HUNGER = TUNING.WX78_HUNGER + 75
TUNING.ALICE_SANITY = TUNING.WX78_SANITY + 100
TUNING.ALICE_HEALTH = TUNING.WX78_HEALTH + 75 
-- 强化魔法模块提升三维
TUNING.MAGIC_MAXHEALTH_BOOST = 240
TUNING.MAGIC_MAXHUNGER_BOOST = 100
TUNING.MAGIC_MAXSANITY_BOOST = 200

TUNING.MAGIC_HUNGER_BURN_SLOW_PERCENT = 0.5
--新增疯狂光环效果 25%
TUNING.MAGIC_SANITY_AURA_MOD_PERCENT = 0.25   -- 25%
--新增装备物品的理智值回复增益 50%
TUNING.MAGIC_SANITY_REGEN_BONUS_PERCENT = 0.5 -- 50%
TUNING.MAGIC_HEALTH_REGEN = 10
TUNING.MAGIC_SANITY_REGEN = 20
--护盾回复
TUNING.MAGIC_SHIELD_REGEN = 0.5
--满血时护盾恢复值
TUNING.MAGIC_FULLHEALTH_SHIELD_REGEN = 10
TUNING.MAGIC_REGEN_INTERVAL = 5

--护盾上限增加最大生命值的50%
TUNING.MAGIC_SHIELD_CAP_BONUS_PERCENT = 0.5   -- 50%
--新增物理伤害减免30%
TUNING.MAGIC_PHYSICAL_DAMAGE_REDUCTION_PERCENT = 0.3  -- 30%

-- 初始物品，需要这里添加才能在选人界面显示
TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.ALICE = {
    "alice_battlecoat",
}

TUNING.STARTING_ITEM_IMAGE_OVERRIDE["alice_lightsword"] = {
    atlas = "images/inventoryimages/alice_lightsword.xml",
    image = "alice_lightsword.tex"
}

TUNING.STARTING_ITEM_IMAGE_OVERRIDE["alice_ring"] = {
    atlas = "images/inventoryimages/alice_ring.xml",
    image = "alice_ring.tex"
}

TUNING.STARTING_ITEM_IMAGE_OVERRIDE["alice_broom"] = {
    atlas = "images/inventoryimages/alice_broom.xml",
    image = "alice_broom.tex"
}

TUNING.STARTING_ITEM_IMAGE_OVERRIDE["alice_battlecoat"] = {
    atlas = "images/inventoryimages/alice_coat.xml",
    image = "alice_coat.tex"
}

-- 专属物品
TUNING.MODE_NORMAL1_MAXUSE = 100
TUNING.MODE_NORMAL2_MAXUSE = 200
TUNING.MODE_NORMAL3_MAXUSE = 20
TUNING.MODE_CHARGE1_MAXUSE = 10
TUNING.MODE_CHARGE2_MAXUSE = 50

TUNING.ALICE_BROOM_SPEED_MULT = 1.25 --1.25
TUNING.ALICE_BROOM_PICKUP_RADIUS = 20

TUNING.ALICE_BATTLE_SPEED_MULT = 1.25
TUNING.ALICE_MAID_SPEED_MULT = 1.5

TUNING.ALICE_LIGHTSWORD_SPEED_MULT = 1.25 --0.5 虽然实际又受大力士属性影响，等价1
TUNING.ALICE_LIGHTSWORD_DAMAGE_RATE = GetModConfigData("lightsword_damage_mul") or 1
TUNING.ALICE_LIGHTSWORD_DAMAGE = TUNING.ALICE_LIGHTSWORD_DAMAGE_RATE * 68

--此处的值可能没有实际使用，如果需要调整武器伤害倍率，到
--scripts\components\alice_sword.lua GetDamage
--[[ TUNING.ALICE_MODEDAMAGE = {
    SHOT1 = TUNING.ALICE_LIGHTSWORD_DAMAGE * 0.5,
    SHOT2 = TUNING.ALICE_LIGHTSWORD_DAMAGE * 0.5,
    SHOT3 = math.floor(TUNING.ALICE_LIGHTSWORD_DAMAGE * 2.94),
    SHOT4 = math.floor(TUNING.ALICE_LIGHTSWORD_DAMAGE * 7.35),
} ]]

TUNING.ALICECOAT_PERISHTIME = 4800 --似乎没有使用

TUNING.LIGHTSWORD_KEY = GetKeyFromConfig("LIGHTSWORD_KEY", KEY_E)
TUNING.EX_MODE_KEY = GetKeyFromConfig("EX_MODE_KEY", KEY_R)

--光之剑模式3的使用cd
TUNING.LIGHTSWORDCD = 15 --old 20

--光之剑模式4：激光攻击
TUNING.ALICE_LIGHTSWORD_MODE4_PLANAR_DAMAGE_BASE = math.floor(TUNING.ALICE_LIGHTSWORD_DAMAGE_RATE * 10.2)
TUNING.ALICE_LIGHTSWORD_MODE4_PLANAR_DAMAGE_PER_LEVEL = math.floor(TUNING.ALICE_LIGHTSWORD_DAMAGE_RATE * 17)
--热量槽机制
TUNING.ALICE_LIGHTSWORD_MODE4_HEAT_MAX = 100                    -- 热量最大值
TUNING.ALICE_LIGHTSWORD_MODE4_HEAT_GAIN_PER_SECOND = 20        -- 射击时每秒热量增加量

-- 各季节散热速率（不射击时每秒减少的热量）
TUNING.ALICE_LIGHTSWORD_MODE4_COOL_RATE_SPRING = 15            -- 春天
TUNING.ALICE_LIGHTSWORD_MODE4_COOL_RATE_SUMMER = 8             -- 夏天（散热最慢）
TUNING.ALICE_LIGHTSWORD_MODE4_COOL_RATE_AUTUMN = 15            -- 秋天
TUNING.ALICE_LIGHTSWORD_MODE4_COOL_RATE_WINTER = 25            -- 冬天（散热最快）


-- ===== 光之剑各模式每次射击消耗的电池电量 =====
TUNING.ALICE_LIGHTSWORD_USE_MODE1 = 1      -- 连射模式
TUNING.ALICE_LIGHTSWORD_USE_MODE2 = 2      -- 能量炮弹
TUNING.ALICE_LIGHTSWORD_USE_MODE3 = 5      -- EX技能
TUNING.ALICE_LIGHTSWORD_USE_MODE4 = 0.1    -- 高能激光刀刃

--充电模块数据
TUNING.ALICE_CHARGE_INTERVAL = 3          -- 充电间隔（秒）
TUNING.ALICE_CHARGE_PER_TICK = 1          -- 每次产生的电荷量
TUNING.ALICE_CHARGE_MAX = 10              -- 最大存储电量
--缺少一个存储电量值
--感觉初始电量属于多余值，默认为0就行
-- ===== 电池 =====
TUNING.ALICE_BATTERY_FUEL = 1000      -- 电池电量
TUNING.ALICE_BATTERY_FUEL_ADD = 200
-- ===== 遥控器 =====
TUNING.ALICE_REMOTE_FUEL = 500            -- 遥控器电量
TUNING.ALICE_REMOTE_FUEL_ADD = 200     -- 每次充电恢复量
--扫地机器人
TUNING.ALICE_ROBOT_HEALTH = 10000
TUNING.ALICE_ROBOT_HEALTH_REGEN_AMOUNT = 50
TUNING.ALICE_ROBOT_HEALTH_REGEN_PERIOD = 1
TUNING.ALICE_ROBOT_RESPAWN = 60

TUNING.ALICE_MUSIC_WORKMULT = 3
TUNING.ALICE_MUSIC_SPEEDMULT = 1.25
TUNING.ALICE_MUSIC_DAMAGEMULT = 1.5
TUNING.ALICE_MUSIC_DEFMULT = 0.5
TUNING.ALICE_MUSIC_DURATION = 60

TUNING.ALICE_SHOT2_DAMAGE = 200
TUNING.ALICE_SHOT2_RADIUS = 0.5
TUNING.ALICE_SHOT2_SPLASH_RADIUS = 3

TUNING.GROUP_NAME = {
    "Usagi Flap", 
    "Operation Dotabata", 
    "Unwelcome school", 
    "Pixel Time", 
    "Constant Moderato", 
    "TaYiR_BeG", 
    "Endless Carnival", 
    "Connected Sky", 
    "Aoharu Band Arrange",
    "Na Na Natsu!", 
    "WAS IT A CAT I SAW!", 
    "Aice room - Fearful Utopia", 
    "Undefined Behavior", 
    "Library of Omen", 
    "Out of Control", 
    "Gregorius", 
}

TUNING.ALICE_GLASSES_CHANCE = 0.2
TUNING.ALICE_GLASSES_VALUE = 1.5

TUNING.ALICE_BASIC_CHANCE = 0.2
TUNING.ALICE_BASIC_VALUE = 1.5

TUNING.ALICE_MAGIC_CHANCE = 0.2
TUNING.ALICE_MAGIC_VALUE = 2.0

TUNING.ALICE_SWORD_CHANCE = 0.3
TUNING.ALICE_SWORD_VALUE = 2.0

TUNING.ALICE_GIFT_COUNT = 3 -- 每次使用获得的礼物数量
TUNING.ALICE_GIFT_KEY = GetKeyFromConfig("ALICE_GIFT_KEY", KEY_U)
TUNING.GIFT_WEIGHT_PREFERENCE = GetModConfigData("GIFT_WEIGHT_PREFERENCE") or "balanced"

TUNING.ALICE_SHADOW_SHIELD_COOLDOWN = 1