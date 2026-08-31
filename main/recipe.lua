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
    {"MODS", "WEAPONS", "TOOLS"}
)

--- 扫把
AddCharacterRecipe("alice_broom",
    {
        Ingredient("cutreeds", 10),
        Ingredient("reskin_tool", 1),
        Ingredient("poop", 4),
    },
    TECH.NONE,
    {
        builder_tag = "alice",
    },
    {"MODS", "TOOLS", "SURVIVAL"}
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
    {"MODS", "REFINE", "PROTOTYPERS"}
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
    {"MODS", "ARMOUR", "CLOTHING"}
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
    {"MODS", "ARMOUR", "CLOTHING"}
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
AddRecipe2("alice_mode2",
    {
        Ingredient("trinket_5", 1),
        Ingredient("gears", 1),
        Ingredient("transistor", 4),
        Ingredient("alice_lightsword", 0),
    },
    TECH.LOST,
    {
        product = "alice_mode2",
        numtogive = 1,
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
AddCharacterRecipe("alice_mode4_shard",
    {
        Ingredient("alterguardianhatshard", 1),
        Ingredient("gears", 1),
        Ingredient("transistor", 4),
    },
    TECH.NONE,
    {
        builder_tag = "alice",
        product = "alice_mode4",
        numtogive = 1,
    },
    {"MODS", "WEAPONS"}
)

-- 高能激光刀刃模块（骷髅盔甲配方）
AddCharacterRecipe("alice_mode4_skeleton",
    {
        Ingredient("armorskeleton", 1),
        Ingredient("gears", 1),
        Ingredient("transistor", 4),
    },
    TECH.NONE,
    {
        builder_tag = "alice",
        product = "alice_mode4",
        numtogive = 1,
    },
    {"MODS", "WEAPONS"}
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
    {"MODS", "ARMOUR"}
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
    {"MODS", "ARMOUR"}
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
    {"MODS", "ARMOUR"}
)

-- 复合材料防护板
AddCharacterRecipe("dimensional_shield",
    {
        Ingredient("lunarplant_husk", 1),
        Ingredient("voidcloth", 1),
    },
    TECH.NONE,
    {
        builder_tag = "alice",
    },
    {"MODS", "ARMOUR"}
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
    {"MODS", "ARMOUR"}
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
    {"MODS", "ARMOUR"}
)

-- 烂电线配方
AddCharacterRecipe("alice_trinket_6",
    {
        Ingredient("goldnugget", 4),
        Ingredient("twigs", 8),
    },
    TECH.NONE,
    {
        builder_tag = "alice",
        no_deconstruction = true,
        product = "trinket_6",
        numtogive = 4,
    },
    {"MODS", "REFINE"}
)

-- 废料配方
AddCharacterRecipe("alice_wagpunk_bits",
    {
        Ingredient("trinket_6", 3),
        Ingredient("flint", 5),
    },
    TECH.NONE,
    {
        builder_tag = "alice",
        no_deconstruction = true,
        product = "wagpunk_bits",
        numtogive = 4,
    },
    {"MODS", "REFINE"}
)

-- 电子元件配方
AddCharacterRecipe("alice_transistor",
    {
        Ingredient("trinket_6", 2),
        Ingredient("rocks", 6),
    },
    TECH.NONE,
    {
        builder_tag = "alice",
        no_deconstruction = true,
        product = "transistor",
        numtogive = 4,
    },
    {"MODS", "REFINE"}
)

-- 齿轮配方
AddCharacterRecipe("alice_gears",
    {
        Ingredient("wagpunk_bits", 2),
        Ingredient("rocks", 4),
    },
    TECH.NONE,
    {
        builder_tag = "alice",
        no_deconstruction = true,
        product = "gears",
        numtogive = 1,
    },
    {"MODS", "REFINE"}
)

-- 启迪之冠碎片配方
AddRecipe2("alice_alterguardianhatshard",
    {
        Ingredient("purebrilliance", 2),
        Ingredient("bluegem", 1),
        Ingredient("moonrocknugget", 3),
        Ingredient("alice_lightsword", 0),
    },
    TECH.LOST,
    {
        product = "alterguardianhatshard",
        numtogive = 1,
    },
    {"MODS", "REFINE"}
)

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
    {"MODS", "PROTOTYPERS", "MAGIC"}
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
    {"MODS", "MAGIC"}
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
    {"MODS", "WEAPONS", "ARMOUR"}
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
    {"MODS", "TOOLS", "PROTOTYPERS"}
)

-- 墨镜
AddCharacterRecipe("alice_glasses",
    {
        Ingredient("moonglass", 6),
        Ingredient("nightmarefuel", 6),
        Ingredient("twigs", 4),
        Ingredient("greengem", 1),
    },
    TECH.NONE,
    {
        builder_tag = "alice",
        atlas = "images/inventoryimages/alice_glasses.xml",
        image = "alice_glasses.tex",
    },
    {"MODS", "CLOTHING"}
)

-- 注册贴图（保持不变）
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
    "dimensional_shield",
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