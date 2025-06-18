GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})

--- 光之剑
AddCharacterRecipe("alice_lightsword",
    {
        Ingredient("wagpunk_bits", 4),
        Ingredient("transistor", 4),
        Ingredient("thulecite", 10),
    },
    TECH.NONE,
    {
        builder_tag = "alice",
    },
    {"MODS", "WEAPONS"}
)

--- 扫把
AddCharacterRecipe("alice_broom",
    {
        Ingredient("cutreeds", 10),
        --Ingredient("orangestaff", 1),  -- 懒人魔杖
        Ingredient("reskin_tool", 1),
        Ingredient("poop", 4),       -- 新增体现农业属性的材料
    },
    TECH.NONE,
    {
        builder_tag = "alice",
    },
    {"MODS"}
)

--- 电池
AddCharacterRecipe("alice_battery",
    {
        Ingredient("transistor", 4),
    },
    TECH.NONE,
    {
        builder_tag = "alice",
    },
    {"MODS"}
)

--- 外套
AddCharacterRecipe("alice_battlecoat",
    {
        Ingredient("raincoat", 1),
        Ingredient("trunk_summer", 1),
        Ingredient("silk", 6),
    },
    TECH.NONE,
    {
        builder_tag = "alice",
        atlas = "images/inventoryimages/alice_coat.xml",
        image = "alice_coat.tex",
    },
    {"MODS"}
)

--- 女仆装
AddCharacterRecipe("alice_maidcoat",
    {
        Ingredient("dreadstonehat", 1),
        Ingredient("sweatervest", 1),
        Ingredient("manrabbit_tail", 3),
    },
    TECH.NONE,
    {
        builder_tag = "alice",
    },
    {"MODS"}
)

-- 连射模式
AddCharacterRecipe("alice_mode1",
    {
        Ingredient("deerclops_eyeball", 1),
        Ingredient("gears", 1),
        Ingredient("transistor", 2),
    },
    TECH.NONE,
    {
        builder_tag = "alice",
    },
    {"MODS", "WEAPONS"}
)

-- 能量炮弹模块
AddCharacterRecipe("alice_mode2",
    {
        Ingredient("trinket_5", 1),
        Ingredient("gears", 1),
        Ingredient("transistor", 4),
    },
    TECH.LOST,
    {
        builder_tag = "alice",
    },
    {"MODS", "WEAPONS"}
)

-- 超新星模块
AddCharacterRecipe("alice_mode3",
    {
        Ingredient("opalpreciousgem", 1),
        Ingredient("gears", 1),
        Ingredient("transistor", 4),
    },
    TECH.NONE,
    {
        builder_tag = "alice",
    },
    {"MODS", "WEAPONS"}
)

-- 高能激光刀刃模块（启迪碎片配方）
AddRecipe2(
    "alice_mode4_shard", -- Unique recipe name
    {
        Ingredient("alterguardianhatshard", 1),
        Ingredient("gears", 1),
        Ingredient("transistor", 4),
    },
    TECH.NONE,
    {product = "alice_mode4", numtogive = 1}, -- Produces the prefab "alice_mode4"
    {"MODS", "WEAPONS","CHARACTER"}
)

-- 高能激光刀刃模块（骷髅盔甲配方）
AddRecipe2(
    "alice_mode4_skeleton", -- Unique recipe name
    {
        Ingredient("armorskeleton", 1),
        Ingredient("gears", 1),
        Ingredient("transistor", 4),
    },
    TECH.NONE,
    {product = "alice_mode4", numtogive = 1}, -- Produces the prefab "alice_mode4"
    {"MODS", "WEAPONS", "CHARACTER"}
)

-- 木制防护板
AddCharacterRecipe("wooden_shield",
    {
        Ingredient("boards", 1),
    },
    TECH.NONE,
    {
        builder_tag = "alice",
    },
    {"MODS", "WEAPONS"}
)

-- 金属防护板
AddCharacterRecipe("metal_shield",
    {
        Ingredient("goldnugget", 4),
    },
    TECH.NONE,
    {
        builder_tag = "alice",
    },
    {"MODS", "WEAPONS"}
)

-- 位面材料防护板
AddCharacterRecipe("dread_shield",
    {
        Ingredient("armordreadstone", 1),
        Ingredient("thulecite", 10),
        Ingredient("moonrocknugget", 10),
        Ingredient("greengem", 2),
    },
    TECH.NONE,
    {
        builder_tag = "alice",
    },
    {"MODS", "WEAPONS"}
)

-- 复合材料防护板
AddCharacterRecipe("composite_shield",
    {
        Ingredient("lunarplant_husk", 1),
        Ingredient("voidcloth", 1),
    },
    TECH.NONE,
    {
        builder_tag = "alice",
    },
    {"MODS", "WEAPONS"}
)

-- 针刺防护板
AddCharacterRecipe("thorn_shield",
    {
        Ingredient("transistor", 1),
        Ingredient("stinger", 2),
    },
    TECH.NONE,
    {
        builder_tag = "alice",
    },
    {"MODS", "WEAPONS"}
)

-- 暗影防护板
AddCharacterRecipe("shadow_shield",
    {
        Ingredient("nightmarefuel", 12),
        Ingredient("skeletonhat", 1),
    },
    TECH.NONE,
    {
        builder_tag = "alice",
    },
    {"MODS", "WEAPONS"}
)

-- 添加烂电线配方 (金块+树枝)
AddRecipe2(
    "alice_trinket_6",  -- 配方名称添加前缀
    {
        Ingredient("goldnugget", 1),
        Ingredient("twigs", 1)
    },
    TECH.NONE,
    {
        product = "trinket_6",  -- 输出物品
        numtogive = 1           -- 产出数量
    },
    {"MODS", "CHARACTER"}  -- 标签
)

-- 添加废料配方 (烂电线+燧石)
AddRecipe2(
    "alice_wagpunk_bits",
    {
        Ingredient("trinket_6", 1),
        Ingredient("flint", 1)
    },
    TECH.NONE,
    {
        product = "wagpunk_bits",
        numtogive = 1
    },
    {"MODS", "CHARACTER"}
)

-- 添加电子元件配方 (烂电线+石砖)
AddRecipe2(
    "alice_transistor",
    {
        Ingredient("trinket_6", 1),
        Ingredient("cutstone", 1)
    },
    TECH.NONE,
    {
        product = "transistor",
        numtogive = 1
    },
    {"MODS", "CHARACTER"}
)

-- 添加齿轮配方 (2废料+2石砖)
AddRecipe2(
    "alice_gears",  -- 配方名称添加前缀
    {
        Ingredient("wagpunk_bits", 2),
        Ingredient("cutstone", 2)
    },
    TECH.NONE,
    {
        product = "gears",
        numtogive = 1
    },
    {"MODS", "CHARACTER"}
)

--[[ AddCharacterRecipe("wx78module_alc_charge",
{
    Ingredient("nightmarefuel", 4),
},
TECH.LOST,
{
    builder_tag = "alice",
},
{"MODS", "WEAPONS"}
) ]]

-- 充能电路
AddCharacterRecipe("wx78module_alc_charge",
    {
        Ingredient("transistor", 2),
    },
    TECH.NONE,
    {
        builder_tag = "alice",
        atlas = "images/inventoryimages/alice_moudle.xml",
        image = "alc_charge.tex",
    },
    {"MODS"}
)

-- 强化魔法
AddCharacterRecipe("wx78module_alc_magic",
    {
        Ingredient("bluemooneye", 2),
        Ingredient("moonbutterflywings", 4),
        Ingredient("trinket_6", 4),
    },
    TECH.CELESTIAL_ONE,
    {
        builder_tag = "alice",
        nounlock = true,
        atlas = "images/inventoryimages/alice_moudle.xml",
        image = "alc_magic.tex",
    },
    {"MODS", "CRAFTING_STATION"}
)

-- 光之勇者
AddCharacterRecipe("wx78module_alc_battle",
    {
        Ingredient("nightmarefuel", 4),
        Ingredient("yellowamulet", 1),
        Ingredient("yellowstaff", 1),
    },
    TECH.ANCIENT_TWO,
    {
        builder_tag = "alice",
        nounlock = true,
        atlas = "images/inventoryimages/alice_moudle.xml",
        image = "alc_battle.tex",
    },
    {"MODS", "CRAFTING_STATION"}
)

-- 手机
AddCharacterRecipe("alice_remote",
    {
        Ingredient("purplegem", 1),
        Ingredient("wagpunk_bits", 1),
        Ingredient("transistor", 4),
    },
    TECH.NONE,
    {
        builder_tag = "alice",
        atlas = "images/inventoryimages/alice_remote.xml",
        image = "alice_remote_on.tex",
    },
    {"MODS"}
)

-- 墨镜
AddCharacterRecipe("alice_glasses",
    {
        Ingredient("moonglass", 6),
        Ingredient("nightmarefuel", 6),
        Ingredient("twigs", 4),
        Ingredient("glommerfuel", 2),
    },
    TECH.NONE,
    {
        builder_tag = "alice",
        atlas = "images/inventoryimages/alice_glasses.xml",
        image = "alice_glasses.tex",
    },
    {"MODS", "CLOTHING"}
)

-- 注册贴图
local function registerItemAtlas(itemList, xmlFile)
    for _, item in ipairs(itemList) do
        RegisterInventoryItemAtlas(resolvefilepath("images/inventoryimages/" .. xmlFile), item .. ".tex")
    end
end

local orgin_list = {
    "alice_lightsword",
    "alice_coat",
    "alice_broom",
    "alice_battery",
    "alice_maidcoat",
}

for k, v in pairs(orgin_list) do
    RegisterInventoryItemAtlas(resolvefilepath("images/inventoryimages/" .. v .. ".xml"), v .. ".tex")
end

local xmlpack1 = {
    "alice_mode1",
    "alice_mode2",
    "alice_mode3",
    "alice_mode4",
}

local xmlpack2 = {
    "wooden_shield",
    "metal_shield",
    "dread_shield",
    "composite_shield",
    "thorn_shield",
    "shadow_shield",
}

local xmlpack3 = {
    "alice_remote_off",
    "alice_remote_on",
}

local xmlpack4 = {
    "alc_charge",
    "alc_battle",
    "alc_magic",
}


registerItemAtlas(xmlpack1, "alice_mode.xml")
registerItemAtlas(xmlpack2, "alice_shield.xml")
registerItemAtlas(xmlpack3, "alice_remote.xml")
registerItemAtlas(xmlpack4, "alice_moudle.xml")
