GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})

-- 三维
TUNING.ALICE_HEALTH = TUNING.WX78_HEALTH + 50 --加50
TUNING.ALICE_HUNGER = TUNING.WX78_HUNGER + 50
TUNING.ALICE_SANITY = TUNING.WX78_SANITY + 50

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

TUNING.ALICE_BROOM_SPEED_MULT = 1.5 --1.25

TUNING.ALICE_LIGHTSWORD_SPEED_MULT = 1.25 --0.5 虽然实际又受大力士属性影响，等价1
TUNING.ALICE_LIGHTSWORD_DAMAGE = GetModConfigData("lightsword_damage") or 68

TUNING.ALICE_MODEDAMAGE = {
    SHOT1 = TUNING.ALICE_LIGHTSWORD_DAMAGE * 0.5,
    SHOT2 = TUNING.ALICE_LIGHTSWORD_DAMAGE * 0.5,
    SHOT3 = math.floor(TUNING.ALICE_LIGHTSWORD_DAMAGE * 2.94),
    SHOT4 = math.floor(TUNING.ALICE_LIGHTSWORD_DAMAGE * 7.35),
}

TUNING.ALICECOAT_PERISHTIME = 4800 --似乎没有使用

TUNING.LIGHTSWORD_KEY = GetModConfigData("LIGHTSWORD_KEY") or KEY_E
TUNING.EX_MODE_KEY = GetModConfigData("EX_MODE_KEY") or KEY_R -- New

TUNING.LIGHTSWORDCD = 15 --old 20

TUNING.ALICE_LASERTHROW_DAMAGE = 0
TUNING.ALICE_LASERTHROW_PLANAR_DAMAGE_MIN = 10
TUNING.ALICE_LASERTHROW_PLANAR_DAMAGE_UP = 5
--此处多有改动，懒得备注了
TUNING.ALICE_ROBOT_HEALTH = 10000
TUNING.ALICE_ROBOT_HEALTH_REGEN_AMOUNT = 50
TUNING.ALICE_ROBOT_HEALTH_REGEN_PERIOD = 1
TUNING.ALICE_ROBOT_RESPAWN = 60

TUNING.ALICE_MUSIC_WORKMULT = 2
TUNING.ALICE_MUSIC_SPEEDMULT = 1.25
TUNING.ALICE_MUSIC_DAMAGEMULT = 1.3
TUNING.ALICE_MUSIC_DEFEMULT = -0.1
TUNING.ALICE_MUSIC_DURATION = 60

TUNING.ALICE_REMOTE_FUEL = 480
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

TUNING.ALICE_GLASSES_CHANCE = 0.5
TUNING.ALICE_GLASSES_VALUE = 1.0