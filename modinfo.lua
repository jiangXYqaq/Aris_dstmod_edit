name = "天童爱丽丝 - Tendou Aris"
description = [[
天童爱丽丝，千年科学学园的神秘少女，因意外来到了永恒大陆。
在这个充满未知的世界中，她凭借对游戏的热情和超凡的程序测试能力。
迅速适应并掌握了新的生存技能。无论是面对危险的生物，
还是解决复杂的机械难题，她都表现得游刃有余。
面对永恒大陆的无尽挑战，爱丽丝以冷静的头脑和无尽的智慧，始终引领着团队走向胜利
]]

author = "Arisu"
version = "1.024"

forumthread = ""

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

for i = 1, #key_list do
    key_options[i] = { description = key_list[i], data = "KEY_"..key_list[i] }
end

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
	},
	{
        name = "EX_MODE_KEY",
        label = en_zh("EX Mode Key", "EX模式快捷键"),
        hover = en_zh("Set the shortcut key for EX attack mode", "设置EX攻击模式快捷键"),
        options = key_options,
        default = "KEY_R",
    },
    {
        name = "lightsword_damage",
        label = "光之剑威力等级",  -- 游戏内显示名称
        options = {
            {description = "小杯 (34)", data = 34},  -- 基础值1x
            {description = "中杯 (68/默认)", data = 68},  -- 基准配置
            {description = "大杯 (2x)", data = 136},  -- 68*2
            {description = "超大杯 (4x)", data = 272}  -- 68*4
        },
        default = 68,  -- 默认选中杯
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
}
