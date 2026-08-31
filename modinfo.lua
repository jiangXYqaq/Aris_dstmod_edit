name = "天童爱丽丝 - Tendou Aris"
description = [[
千禧年学园的机械少女降临永恒大陆！
她以游戏视角解析蛮荒——篝火是存档点，巨鹿即副本Boss，疯狂的低语不过是剧情台词。
女仆扫把快速收割作物 挥动扫把瞬间归拢散落物资
扫地机器人「Alpha」：嘲讽拉怪+挨打时触发灵魂蹲起！
光之剑「超新星」：蓄能激光炮和高频粒子刃等多种模式
精神值系统：高精神值→爱丽丝；低精神值→凯伊
【副本目标更新：用扫把整理混沌，以光炮重写生存法则】

v1.5.0更新：
兼容WX-78技能树升级的电路系统

能制作并使用WX-78的新电路

调整模组电路的线路模式

调整模组电路的数值使匹配WX-78的电路技能树强化效果

]]

author = "jiangXY"
version = "1.5.0" -- Updated version to reflect the latest release

forumthread = "beta"

api_version = 10

dont_starve_compatible = false --不兼容单机
reign_of_giants_compatible = false
shipwrecked_compatible = false

dst_compatible = true --兼容联机
all_clients_require_mod = true
client_only_mod = false

icon_atlas = "modicon.xml"
icon = "modicon.tex"

server_filter_tags = {"character", "alice", "aris", "爱丽丝", "天童爱丽丝"}

priority = 10

local key_list = {"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","0","1","2","3","4","5","6","7","8","9","F1","F2","F3","F4","F5","F6","F7","F8","F9","F10","F11","F12","TAB","CAPSLOCK","LSHIFT","RSHIFT","LCTRL","RCTRL","LALT","RALT","ALT","CTRL","SHIFT","SPACE","ENTER","ESCAPE","MINUS","EQUALS","BACKSPACE","PERIOD","SLASH","LEFTBRACKET","BACKSLASH","RIGHTBRACKET","TILDE","PRINT","SCROLLOCK","PAUSE","INSERT","HOME","DELETE","END","PAGEUP","PAGEDOWN","UP","DOWN","LEFT","RIGHT","KP_DIVIDE","KP_MULTIPLY","KP_PLUS","KP_MINUS","KP_ENTER","KP_PERIOD","KP_EQUALS"}
local key_options = {}

-- 创建带禁用选项的按键列表
for i = 1, #key_list do
    key_options[i] = { description = key_list[i], data = "KEY_"..key_list[i] }
end
key_options[#key_options + 1] = {description = "禁用", data = false}  -- 添加禁用选项

local function en_zh(en, zh)
	return (locale == "zh" or locale == "zhr" or locale == "zht") and zh or en
end

configuration_options =
{
    {
		name = "LIGHTSWORD_KEY",
		label = en_zh("Information Key", "信息面板按键"),
		hover = en_zh("Set the shortcut key for the lightsword information", "设置光之剑信息面板快捷键"),
        options = key_options,
		default = "KEY_E",
        is_keylist = true
	},
	{
        name = "EX_MODE_KEY",
        label = en_zh("EX Mode Key", "EX模式快捷键"),
        hover = en_zh("Set the shortcut key for EX attack mode", "设置EX攻击模式快捷键"),
        options = key_options,
        default = "KEY_R",
        is_keylist = true
    },
    {
        name = "lightsword_damage_mul",
        label = "光之剑威力等级",
        options = {
            {description = "小杯 (34)", data = 0.5},
            {description = "中杯 (68/默认)", data = 1},
            {description = "大杯 (2x)", data = 2},
            {description = "超大杯 (4x)", data = 4}
        },
        default = 1,
    },
    {
		name = "ALC_LANGUAGE",
		label = en_zh("Language", "语言"),
		hover = en_zh("Set game language", "设置游戏语言"),
        options =
        {
            {description = en_zh("Chinese", "中文"), data = "ch"},
            {description = en_zh("English", "英文"), data = "en"},
        },
		default = "ch",
	},
	{
        name = "ALICE_GIFT_KEY",
        label = en_zh("Gift Key", "礼物快捷键"),
        hover = en_zh("Set the shortcut key for Alice's gift feature", "设置爱丽丝礼物功能快捷键"),
        options = key_options,
        default = "KEY_U",
        is_keylist = true
    },
    {
        name = "GIFT_WEIGHT_PREFERENCE",
        label = "礼物类型偏好",
        options = {
            {description = "平衡", data = "balanced"},
            {description = "材料优先", data = "materials"},
            {description = "装备优先", data = "equipments"},
            {description = "食物优先", data = "foods"}
        },
        default = "balanced"
    }
}

-- 标记所有按键配置项
for i = 1, #configuration_options do
    local opt = configuration_options[i]
    if opt.options == key_options then
        opt.is_keylist = true
    end
end
