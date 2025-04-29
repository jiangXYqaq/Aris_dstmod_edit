<<<<<<< HEAD
local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local ImageButton = require "widgets/imagebutton"
local PopupDialogScreen = require "screens/redux/popupdialog"
local TEMPLATES = require "widgets/redux/templates"
local ScrollableList = require "widgets/scrollablelist"
local Spinner = require "widgets/spinner"
local Utils = require("alice_utils/utils")

local button_x = -361
local button_width = 250
local button_height = 48
local action_label_width = 350
local action_btn_width = 250
local spacing = 15
local group_width = action_label_width + spacing + action_btn_width

local normal_list_item_bg_tint = { 1,1,1,0.5 }

local buff_data = {
    [1] = {
        icon = "images/ui/alice_buff.xml",
        tex = "Buff_Damage.tex",
        text = STRINGS.ALICEUI.BUFF.DAMAGE,
    },
    [2] = {
        icon = "images/ui/alice_buff.xml",
        tex = "Buff_MoveSpeed.tex",
        text = STRINGS.ALICEUI.BUFF.SPEED,
    },
    [3] = {
        icon = "images/ui/alice_buff.xml",
        tex = "Buff_DEF.tex",
        text = STRINGS.ALICEUI.BUFF.DEF,
    },
    [4] = {
        icon = "images/ui/alice_buff.xml",
        tex = "Buff_Mind.tex",
        text = STRINGS.ALICEUI.BUFF.WORK,
    },
}

local function BuildControlGroup(screen, label, value)
    local group = Widget("control" .. value)

    group.back = group:AddChild(Image("images/ui/Background01.xml", "Background01.tex"))
    group.back:SetPosition(-60, 0)
    group.back:SetSize(group_width + 20, button_height - 7)
    group.back:SetTint(unpack(normal_list_item_bg_tint))

    group:SetScale(1, 1, 0.75)

    group.musicname = label

    local x = button_x

    group.label = group:AddChild(Text(BODYTEXTFONT, 28))
    group.label:SetString(label)
    group.label:SetHAlign(ANCHOR_LEFT)
    group.label:SetColour(UICOLOURS.GOLD_UNIMPORTANT)

    group.label:SetRegionSize(action_label_width, 50)
    x = x + action_label_width / 2
    group.label:SetPosition(x, 0)
    x = x + action_label_width / 2 + spacing
    group.label:SetClickable(false)

    x = x + button_width / 2

    group.play_btn = group:AddChild(ImageButton("images/ui/bofang.xml", "bofang.tex"))
    group.play_btn:SetPosition(x, 0)
    group.play_btn:SetScale(0.3, 0.3)
    group.play_btn:SetOnClick(function()
        screen:KillMusic()
        screen:PlayMusic(label)
    end)

    group.stop_btn = group:AddChild(ImageButton("images/ui/stop.xml", "stop.tex"))
    group.stop_btn:SetScale(0.3, 0.3)
    group.stop_btn:SetPosition(x, 0)
    group.stop_btn:Hide()
    group.stop_btn:SetOnClick(function()
        screen:KillMusic()
    end)

    if buff_data[value] then
        local buff_info = buff_data[value]

        group.buff_btn = group:AddChild(ImageButton(buff_info.icon, buff_info.tex))
        group.buff_btn:SetPosition(x - 40, 0)
        group.buff_btn:SetScale(0.8, 0.8)
        group.buff_btn:SetHoverText(buff_info.text)
    end

    return group
end

local MusicPlaylistScreen = Class(Widget,function(self, owner)
        Widget._ctor(self, "MusicPlaylistScreens")
        self.owner = owner

        self:SetScaleMode(SCALEMODE_PROPORTIONAL)
        self:SetMaxPropUpscale(MAX_HUD_SCALE)
        self:SetPosition(0, 0, 0)
        self:SetVAnchor(ANCHOR_MIDDLE)
        self:SetHAnchor(ANCHOR_MIDDLE)

        self.proot = self:AddChild(Widget("ROOT"))
        self.proot:SetVAnchor(ANCHOR_MIDDLE)
        self.proot:SetHAnchor(ANCHOR_MIDDLE)
        self.proot:SetPosition(0,0,0)
        self.proot:SetScaleMode(SCALEMODE_PROPORTIONAL)
        
        self.black = self.proot:AddChild(ImageButton("images/global.xml", "square.tex"))
        self.black.image:SetVRegPoint(ANCHOR_MIDDLE)
        self.black.image:SetHRegPoint(ANCHOR_MIDDLE)
        self.black.image:SetVAnchor(ANCHOR_MIDDLE)
        self.black.image:SetHAnchor(ANCHOR_MIDDLE)
        self.black.image:SetScaleMode(SCALEMODE_FILLSCREEN)
        self.black.image:SetTint(0,0,0,0)
        self.black:SetOnClick(function() 
            self:Close() 
        end)

        self.groups = {}

        for i, name in ipairs(TUNING.GROUP_NAME) do
            table.insert(self.groups, BuildControlGroup(self, name, i))
        end

        self.scroll_list = self.proot:AddChild(ScrollableList(
            self.groups,         -- items
            180,                 -- listwidth
            300,                 -- listheight
            30,                  -- itemheight
            10,                  -- itempadding
            nil,                 -- updatefn
            nil,                 -- widgetstoupdate
            nil,                 -- widgetXOffset
            nil,                 -- always_show_static
            nil,                 -- starting_offset
            10,                  -- yInit
            nil,                 -- bar_width_scale_factor
            nil,                 -- bar_height_scale_factor
            "GOLD"               -- scrollbar_style
        ))
	    self.scroll_list:SetPosition(100, 0)
        self.scroll_list.bg:Hide()

        self:LoadButton()
    end
)


function MusicPlaylistScreen:KillMusic()
    SendModRPCToServer(MOD_RPC["alice"]["stopmusic"], self.source)
    self:UpdateButtons(nil)
end

function MusicPlaylistScreen:PlayMusic(musicname)
    SendModRPCToServer(MOD_RPC["alice"]["playmusic"], self.source, musicname)
    self:UpdateButtons(musicname)
end

function MusicPlaylistScreen:UpdateButtons(current_musicname)
    for _, group in ipairs(self.groups) do
        if group.musicname == current_musicname then
            group.play_btn:Hide()
            group.stop_btn:Show()
        else
            group.play_btn:Show()
            group.stop_btn:Hide()
        end
    end
end

local str_volume = STRINGS.ALICEUI.VOICE
local button_data = {
    spinner_data = {
        spinnerdata = {
            { text = str_volume .. " 0", data = 0 },
            { text = str_volume .. " 10%", data = 0.1 },
            { text = str_volume .. " 20%", data = 0.2 },
            { text = str_volume .. " 30%", data = 0.3 },
            { text = str_volume .. " 40%", data = 0.4 },
            { text = str_volume .. " 50%", data = 0.5 },
            { text = str_volume .. " 60%", data = 0.6 },
            { text = str_volume .. " 70%", data = 0.7 },
            { text = str_volume .. " 80%", data = 0.8 },
            { text = str_volume .. " 90%", data = 0.9 },
            { text = str_volume .. " 100%", data = 1.0 },
        },
        onchanged_fn = function(spinner_data, source)
            SendModRPCToServer(MOD_RPC["alice"]["setvolume"], source, spinner_data)
        end,
        selected_fn = function(spinner)
            spinner:SetPosition(-35, 0)
        end,
    },
}

function MusicPlaylistScreen:LoadButton()
    self.volumebtnback = self.proot:AddChild(Image("images/ui/Background01.xml", "Background01.tex"))
    self.volumebtnback:SetSize(group_width + 20, button_height - 7)
    self.volumebtnback:SetTint(1,1,1,0.5)
    self.volumebtnback:SetPosition(-50, -180)

    self.volumebtn = self.proot:AddChild(
        TEMPLATES.LabelSpinner(
            nil,
            button_data.spinner_data.spinnerdata,
            150,
            150,
            button_data.spinner_data.height,
            button_data.spinner_data.spacing,
            BODYTEXTFONT,
            24,
            button_data.spinner_data.horiz_offset,
            function(spinner_data)
                button_data.spinner_data.onchanged_fn(spinner_data, self.source)
            end,
            button_data.spinner_data.colour,
            button_data.spinner_data.tooltip_text
        )
    )
    button_data.spinner_data.selected_fn(self.volumebtn.spinner)

    self.volumebtn:SetPosition(10, -180)
end


function MusicPlaylistScreen:Update()
    if not self.owner then
        return
    end

    local source = Utils.FindEquipWithTag(self.owner, "alice_remote")
    if not source then
        return
    end

    self.source = source
    self.volume = self.source.volume

    self.volumebtn.spinner:SetSelected(self.source.volume)
end

function MusicPlaylistScreen:Open()
    self:Show()
    self:Update()
end

function MusicPlaylistScreen:Close()
    self:Hide()
end

=======
local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local ImageButton = require "widgets/imagebutton"
local PopupDialogScreen = require "screens/redux/popupdialog"
local TEMPLATES = require "widgets/redux/templates"
local ScrollableList = require "widgets/scrollablelist"
local Spinner = require "widgets/spinner"
local Utils = require("alice_utils/utils")

local button_x = -361
local button_width = 250
local button_height = 48
local action_label_width = 350
local action_btn_width = 250
local spacing = 15
local group_width = action_label_width + spacing + action_btn_width

local normal_list_item_bg_tint = { 1,1,1,0.5 }

local buff_data = {
    [1] = {
        icon = "images/ui/alice_buff.xml",
        tex = "Buff_Damage.tex",
        text = STRINGS.ALICEUI.BUFF.DAMAGE,
    },
    [2] = {
        icon = "images/ui/alice_buff.xml",
        tex = "Buff_MoveSpeed.tex",
        text = STRINGS.ALICEUI.BUFF.SPEED,
    },
    [3] = {
        icon = "images/ui/alice_buff.xml",
        tex = "Buff_DEF.tex",
        text = STRINGS.ALICEUI.BUFF.DEF,
    },
    [4] = {
        icon = "images/ui/alice_buff.xml",
        tex = "Buff_Mind.tex",
        text = STRINGS.ALICEUI.BUFF.WORK,
    },
}

local function BuildControlGroup(screen, label, value)
    local group = Widget("control" .. value)

    group.back = group:AddChild(Image("images/ui/Background01.xml", "Background01.tex"))
    group.back:SetPosition(-60, 0)
    group.back:SetSize(group_width + 20, button_height - 7)
    group.back:SetTint(unpack(normal_list_item_bg_tint))

    group:SetScale(1, 1, 0.75)

    group.musicname = label

    local x = button_x

    group.label = group:AddChild(Text(BODYTEXTFONT, 28))
    group.label:SetString(label)
    group.label:SetHAlign(ANCHOR_LEFT)
    group.label:SetColour(UICOLOURS.GOLD_UNIMPORTANT)

    group.label:SetRegionSize(action_label_width, 50)
    x = x + action_label_width / 2
    group.label:SetPosition(x, 0)
    x = x + action_label_width / 2 + spacing
    group.label:SetClickable(false)

    x = x + button_width / 2

    group.play_btn = group:AddChild(ImageButton("images/ui/bofang.xml", "bofang.tex"))
    group.play_btn:SetPosition(x, 0)
    group.play_btn:SetScale(0.3, 0.3)
    group.play_btn:SetOnClick(function()
        screen:KillMusic()
        screen:PlayMusic(label)
    end)

    group.stop_btn = group:AddChild(ImageButton("images/ui/stop.xml", "stop.tex"))
    group.stop_btn:SetScale(0.3, 0.3)
    group.stop_btn:SetPosition(x, 0)
    group.stop_btn:Hide()
    group.stop_btn:SetOnClick(function()
        screen:KillMusic()
    end)

    if buff_data[value] then
        local buff_info = buff_data[value]

        group.buff_btn = group:AddChild(ImageButton(buff_info.icon, buff_info.tex))
        group.buff_btn:SetPosition(x - 40, 0)
        group.buff_btn:SetScale(0.8, 0.8)
        group.buff_btn:SetHoverText(buff_info.text)
    end

    return group
end

local MusicPlaylistScreen = Class(Widget,function(self, owner)
        Widget._ctor(self, "MusicPlaylistScreens")
        self.owner = owner

        self:SetScaleMode(SCALEMODE_PROPORTIONAL)
        self:SetMaxPropUpscale(MAX_HUD_SCALE)
        self:SetPosition(0, 0, 0)
        self:SetVAnchor(ANCHOR_MIDDLE)
        self:SetHAnchor(ANCHOR_MIDDLE)

        self.proot = self:AddChild(Widget("ROOT"))
        self.proot:SetVAnchor(ANCHOR_MIDDLE)
        self.proot:SetHAnchor(ANCHOR_MIDDLE)
        self.proot:SetPosition(0,0,0)
        self.proot:SetScaleMode(SCALEMODE_PROPORTIONAL)
        
        self.black = self.proot:AddChild(ImageButton("images/global.xml", "square.tex"))
        self.black.image:SetVRegPoint(ANCHOR_MIDDLE)
        self.black.image:SetHRegPoint(ANCHOR_MIDDLE)
        self.black.image:SetVAnchor(ANCHOR_MIDDLE)
        self.black.image:SetHAnchor(ANCHOR_MIDDLE)
        self.black.image:SetScaleMode(SCALEMODE_FILLSCREEN)
        self.black.image:SetTint(0,0,0,0)
        self.black:SetOnClick(function() 
            self:Close() 
        end)

        self.groups = {}

        for i, name in ipairs(TUNING.GROUP_NAME) do
            table.insert(self.groups, BuildControlGroup(self, name, i))
        end

        self.scroll_list = self.proot:AddChild(ScrollableList(
            self.groups,         -- items
            180,                 -- listwidth
            300,                 -- listheight
            30,                  -- itemheight
            10,                  -- itempadding
            nil,                 -- updatefn
            nil,                 -- widgetstoupdate
            nil,                 -- widgetXOffset
            nil,                 -- always_show_static
            nil,                 -- starting_offset
            10,                  -- yInit
            nil,                 -- bar_width_scale_factor
            nil,                 -- bar_height_scale_factor
            "GOLD"               -- scrollbar_style
        ))
	    self.scroll_list:SetPosition(100, 0)
        self.scroll_list.bg:Hide()

        self:LoadButton()
    end
)


function MusicPlaylistScreen:KillMusic()
    SendModRPCToServer(MOD_RPC["alice"]["stopmusic"], self.source)
    self:UpdateButtons(nil)
end

function MusicPlaylistScreen:PlayMusic(musicname)
    SendModRPCToServer(MOD_RPC["alice"]["playmusic"], self.source, musicname)
    self:UpdateButtons(musicname)
end

function MusicPlaylistScreen:UpdateButtons(current_musicname)
    for _, group in ipairs(self.groups) do
        if group.musicname == current_musicname then
            group.play_btn:Hide()
            group.stop_btn:Show()
        else
            group.play_btn:Show()
            group.stop_btn:Hide()
        end
    end
end

local str_volume = STRINGS.ALICEUI.VOICE
local button_data = {
    spinner_data = {
        spinnerdata = {
            { text = str_volume .. " 0", data = 0 },
            { text = str_volume .. " 10%", data = 0.1 },
            { text = str_volume .. " 20%", data = 0.2 },
            { text = str_volume .. " 30%", data = 0.3 },
            { text = str_volume .. " 40%", data = 0.4 },
            { text = str_volume .. " 50%", data = 0.5 },
            { text = str_volume .. " 60%", data = 0.6 },
            { text = str_volume .. " 70%", data = 0.7 },
            { text = str_volume .. " 80%", data = 0.8 },
            { text = str_volume .. " 90%", data = 0.9 },
            { text = str_volume .. " 100%", data = 1.0 },
        },
        onchanged_fn = function(spinner_data, source)
            SendModRPCToServer(MOD_RPC["alice"]["setvolume"], source, spinner_data)
        end,
        selected_fn = function(spinner)
            spinner:SetPosition(-35, 0)
        end,
    },
}

function MusicPlaylistScreen:LoadButton()
    self.volumebtnback = self.proot:AddChild(Image("images/ui/Background01.xml", "Background01.tex"))
    self.volumebtnback:SetSize(group_width + 20, button_height - 7)
    self.volumebtnback:SetTint(1,1,1,0.5)
    self.volumebtnback:SetPosition(-50, -180)

    self.volumebtn = self.proot:AddChild(
        TEMPLATES.LabelSpinner(
            nil,
            button_data.spinner_data.spinnerdata,
            150,
            150,
            button_data.spinner_data.height,
            button_data.spinner_data.spacing,
            BODYTEXTFONT,
            24,
            button_data.spinner_data.horiz_offset,
            function(spinner_data)
                button_data.spinner_data.onchanged_fn(spinner_data, self.source)
            end,
            button_data.spinner_data.colour,
            button_data.spinner_data.tooltip_text
        )
    )
    button_data.spinner_data.selected_fn(self.volumebtn.spinner)

    self.volumebtn:SetPosition(10, -180)
end


function MusicPlaylistScreen:Update()
    if not self.owner then
        return
    end

    local source = Utils.FindEquipWithTag(self.owner, "alice_remote")
    if not source then
        return
    end

    self.source = source
    self.volume = self.source.volume

    self.volumebtn.spinner:SetSelected(self.source.volume)
end

function MusicPlaylistScreen:Open()
    self:Show()
    self:Update()
end

function MusicPlaylistScreen:Close()
    self:Hide()
end

>>>>>>> 23121469d84d981b602c8a05fcc5a165255f6831
return MusicPlaylistScreen