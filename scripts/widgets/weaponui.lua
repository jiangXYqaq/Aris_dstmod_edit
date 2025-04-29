<<<<<<< HEAD
local Screen = require "widgets/screen"
local Button = require "widgets/button"
local AnimButton = require "widgets/animbutton"
local Menu = require "widgets/menu"
local Text = require "widgets/text"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local UIAnim = require "widgets/uianim"
local Widget = require "widgets/widget"
local TEMPLATES = require "widgets/templates"
local ItemSlot = require("widgets/itemslot")
local Utils = require("alice_utils/utils")

local WeaponUI = Class(Widget, function(self, owner)
	Widget._ctor(self, "WeaponUI")

    self.owner = owner

    self.black = self:AddChild(ImageButton("images/global.xml", "square.tex"))
    self.black.image:SetVRegPoint(ANCHOR_MIDDLE)
    self.black.image:SetHRegPoint(ANCHOR_MIDDLE)
    self.black.image:SetVAnchor(ANCHOR_MIDDLE)
    self.black.image:SetHAnchor(ANCHOR_MIDDLE)
    self.black.image:SetScaleMode(SCALEMODE_FILLSCREEN)
    self.black.image:SetTint(0, 0, 0, 0)
    self.black:SetOnClick(function() self:Close() end)

    self.proot = self:AddChild(Widget("ROOT"))
    self.proot:SetVAnchor(ANCHOR_MIDDLE)
    self.proot:SetHAnchor(ANCHOR_MIDDLE)
    self.proot:SetPosition(0, 0, 0)
    self.proot:SetScaleMode(SCALEMODE_PROPORTIONAL)

    self.skillback = self.proot:AddChild(Image("images/ui/skillback.xml", "skillback.tex"))
    self.skillback:Hide()
    self.skillback:MoveToFront()
    self.skillback:SetScale(.5, .5, .5)

    self.skillback.levelbtn = self.skillback:AddChild(ImageButton("images/ui/levelup.xml", "levelup.tex"))
    self.skillback.levelbtn:SetPosition(550, -400, 0)
    self.skillback.levelbtn.focus_scale = {1.05, 1.05, 1.05}

    local backimage = TUNING.ALC_LANGUAGE == "en" and "back_en" or "back"
    self.back = self.proot:AddChild(Image("images/ui/" .. backimage .. ".xml", backimage .. ".tex"))
    self.back:SetScale(1, 1, 1)

    self:Initdata()

    self.text1 = self.back:AddChild(Text(BODYTEXTFONT, 24, TUNING.ALICE_LIGHTSWORD_DAMAGE))
    self.text1:SetColour(UICOLOURS.BLUE)
    self.text1:SetPosition(-60, 93, 0)
    
    self.text2 = self.back:AddChild(Text(BODYTEXTFONT, 24, "50%"))
    self.text2:SetColour(UICOLOURS.BLUE)
    self.text2:SetPosition(100, 93, 0)

    self.text3 = self.back:AddChild(Text(BODYTEXTFONT, 24, self.data.power))
    self.text3:SetColour(UICOLOURS.BLUE)
    self.text3:SetPosition(-60, 66, 0)

    self.text4 = self.back:AddChild(Text(BODYTEXTFONT, 24, self.data.key))
    self.text4:SetColour(UICOLOURS.BLUE)
    self.text4:SetPosition(100, 66, 0)

    self.skillup = self.back:AddChild(ImageButton("images/ui/skillup.xml", "skillup.tex"))
    self.skillup:SetScale(.95, .95, .95)
    self.skillup:SetPosition(152, 0, 0)
    self.skillup:SetOnClick(function()
        self.skillback:Show()
        self.back:Hide()
    end)

    self.buttons = {}
    self.skillup_buttons = {}
    self.skillup.cureent  = 1

    self:AddButton()

    self.inst:DoPeriodicTask(0.2, function()
        if self.opening then
            self:Update()
        end
    end)
end)

local button_data = {
    { 
        icon = "icon1", 
        item = "alice_mode1",
        position = {-145, 8, 0}, 
        position2 = {-700, 270, 0}, 
        level_key = "shotlevel", 
        mode = 1 ,
        text = STRINGS.LIGHTSWORD_MODE[1],
        xml = "images/inventoryimages/alice_mode.xml",
        tex = "alice_mode1.tex",
    },
    { 
        icon = "icon2", 
        item = "alice_mode2",
        position = {-70, 8, 0}, 
        position2 = {-700, 60, 0}, 
        level_key = "powerlevel", 
        mode = 2,
        text = STRINGS.LIGHTSWORD_MODE[2],
        xml = "images/inventoryimages/alice_mode.xml",
        tex = "alice_mode2.tex",
    },
    { 
        icon = "icon3", 
        item = "alice_mode3",
        position = {5, 8, 0}, 
        position2 = {-700, -150, 0}, 
        level_key = "exlevel", 
        mode = 3,
        text = STRINGS.LIGHTSWORD_MODE[3],
        xml = "images/inventoryimages/alice_mode.xml",
        tex = "alice_mode3.tex",
    },
    { 
        icon = "icon4", 
        item = "alice_mode4",
        position = {80, 8, 0}, 
        position2 = {-700, -360, 0}, 
        level_key = "swordlevel", 
        mode = 4,
        text = STRINGS.LIGHTSWORD_MODE[4],
        xml = "images/inventoryimages/alice_mode.xml",
        tex = "alice_mode4.tex",
    },
}

function WeaponUI:Initdata()
    local key = _G[TUNING.LIGHTSWORD_KEY]
    self.data = {
        key = STRINGS.UI.CONTROLSSCREEN.INPUTS[1][key],
        shotlevel = 0,
        powerlevel = 0,
        exlevel = 0,
        swordlevel = 0,
        mode = 0,
        power = 0,
    }
end

local function GetSkillString(damage, flydamage, mode)
    local stringdata = {
        {
            string = "\n" .. STRINGS.ALICEUI.WEAPON.STRING1 .. " " .. damage .. " " .. STRINGS.ALICEUI.WEAPON.STRING6,
        },
        {
            string = "\n" .. STRINGS.ALICEUI.WEAPON.STRING2 .. " " .. flydamage .. " " .. STRINGS.ALICEUI.WEAPON.STRING6 .. ", " .. STRINGS.ALICEUI.WEAPON.STRING3 .. " " .. damage .." " ..  STRINGS.ALICEUI.WEAPON.STRING8,
        },
        {
            string = "\n" .. STRINGS.ALICEUI.WEAPON.STRING4 .. " " .. damage .. " " .. STRINGS.ALICEUI.WEAPON.STRING6,
        },
        {
            string = "\n" .. STRINGS.ALICEUI.WEAPON.STRING5 .. " " .. damage .. " " .. STRINGS.ALICEUI.WEAPON.STRING7,
        },
    }
    return stringdata[mode]["string"]
end

local maxlevel = {10, 4, 5, 5}

local function GetString(level, mode)
    if mode then
        level = math.min(maxlevel[mode], level)
    end
    local damagedata = {
        {
            damage = TUNING.ALICE_LIGHTSWORD_DAMAGE * (0.5 + level * 0.1) / 68 * 100,
        },
        {
            flydamage = TUNING.ALICE_LIGHTSWORD_DAMAGE * (1 + level * 0.5) / 68 * 100,
            damage = TUNING.ALICE_LIGHTSWORD_DAMAGE * (1 + level * 0.25) / 68 * 100,
        },
        {
            damage = TUNING.ALICE_LIGHTSWORD_DAMAGE * (2.5 + level * 0.5) / 68 * 100,
        },
        {
            damage = TUNING.ALICE_LASERTHROW_PLANAR_DAMAGE_MIN + TUNING.ALICE_LASERTHROW_PLANAR_DAMAGE_UP * level,
        },
    }
    local damage = damagedata[mode]["damage"]
    local flydamage = damagedata[mode]["flydamage"] or ""
    local stringdata = GetSkillString(damage, flydamage, mode)
    return stringdata or ""
end

local function IsMaxLevel(level, mode)
    return level == maxlevel[mode]
end

local function GetLevel(level, mode, max)
    if mode then
        level = math.min(maxlevel[mode], level)
    end

    if IsMaxLevel(level, mode) then
        return "Max"
    end
    
    local str = level == -1 and "Unlock" or "Lv." .. level
    return str
end

function WeaponUI:AddButton() 
    for _, btn in ipairs(button_data) do
        local button = self.back:AddChild(ImageButton("images/ui/" .. btn.icon .. ".xml", btn.icon .. ".tex"))
        button:SetPosition(unpack(btn.position))
        
        button:SetTextSize(20)
        button:SetTextColour(UICOLOURS.BLUE)
        button.text:SetPosition(0, -35, 0)
        button:SetOnClick(function() 
            self:Change(btn.mode)
        end)
    
        button.circle = button:AddChild(Image("images/ui/select.xml", "select.tex"))
    
        self.buttons[btn.mode] = button
    end

    for _, btn in ipairs(button_data) do
        local button = self.skillback:AddChild(ImageButton("images/ui/" .. btn.icon .. ".xml", btn.icon .. ".tex"))
        button:SetPosition(unpack(btn.position2))
        button:SetScale(2.5, 2.5, 2.5)

        button.circle = button:AddChild(Image("images/ui/select.xml", "select.tex"))
        button.circle:SetScale(1.5, 1.5, 1.5)

        button.clickoffset = Vector3(0, 0, 0)
        button:SetTextSize(16)
        button:SetTextColour(UICOLOURS.BLUE)
        button.text:SetPosition(0, -28, 0)
        button:SetOnClick(function() 
            self.skillup.cureent = btn.mode
            self:UpdateButton()
        end)
    
        self.skillup_buttons[btn.mode] = button

        local offset_y = btn.mode * 84
        button.replica = button:AddChild(Image("images/ui/" .. btn.icon .. ".xml", btn.icon .. ".tex"))
        button.replica:SetPosition(80, -56 + offset_y, 0)
        button.replica:SetScale(0.8, 0.8, 0.8)
        button.replica:SetClickable(false)

        button.replica.str = button.replica:AddChild(Text(BODYTEXTFONT, 24, btn.text))
        local w1, h1 = button.replica.str:GetRegionSize()
        button.replica.str:SetPosition(30 + w1 / 2, 15 - h1 / 2)

        local level = self.data[btn.level_key]

        button.curlevel = button:AddChild(Text(BODYTEXTFONT, 24, GetLevel(level, btn.mode)))
        local w2, h2 = button.curlevel:GetRegionSize()
        button.curlevel:SetPosition(90 + w2 / 2, -86 + offset_y, 0)

        button.nextlevel = button:AddChild(Text(BODYTEXTFONT, 24, GetLevel(level + 1, btn.mode)))
        local w3, h3 = button.nextlevel:GetRegionSize()
        button.nextlevel:SetPosition(350 + w3 / 2, -86 + offset_y, 0)
        
        local curstr = GetString(level, btn.mode)
        button.curlevel.text = button.curlevel:AddChild(Text(BODYTEXTFONT, 24, curstr))
        button.curlevel.text:SetSize(18)
	    button.curlevel.text:SetMultilineTruncatedString(curstr, 28, 250)
        local w4, h4 = button.curlevel.text:GetRegionSize()
        button.curlevel.text:SetPosition(-10 + w4 / 2 - w2 / 2, -20 - h4 / 2, 0)
        button.curlevel.text:SetHAlign(ANCHOR_LEFT)
        
        local nextstr = GetString(level + 1, btn.mode)
        button.nextlevel.text = button.nextlevel:AddChild(Text(BODYTEXTFONT, 24, nextstr))
        button.nextlevel.text:SetSize(18)
	    button.nextlevel.text:SetMultilineTruncatedString(nextstr, 28, 250)
        local w5, h5 = button.nextlevel.text:GetRegionSize()
        button.nextlevel.text:SetPosition(0 + w5 / 2 - w3 / 2, -20 - h5 / 2, 0)
        button.nextlevel.text:SetHAlign(ANCHOR_LEFT)

        button.item = button:AddChild(Image(btn.xml, btn.tex))
        button.item:SetPosition(125, -270 + offset_y, 0)
        button.item.text = button.item:AddChild(Text(BODYTEXTFONT, 24, ""))
        button.item.text:SetPosition(0, -30, 0)
    end
end

function WeaponUI:UpdateButton()
    self.skillback.levelbtn:SetOnClick(function()
        local weapon = Utils.FindEquipWithTag(self.owner, "lightsword")
        if not weapon then
            return
        end
        SendModRPCToServer(MOD_RPC["alice"]["levelup"], weapon, self.skillup.cureent)
    end)

    for k, btn in ipairs(button_data) do
        local button = self.buttons[btn.mode]
        if self.data.mode == btn.mode then
            button["circle"]:Show()
        else
            button["circle"]:Hide()
        end
        local level = self.data[btn.level_key]
        local str = GetLevel(level, btn.mode)
        button:SetText(str)
        if level ~= -1 then
            local str = GetString(level, btn.mode) or ""
            button:SetHoverText(btn.text .. "     " .. GetLevel(level, btn.mode) .. str, {
                offset_y = 100,
                bg_atlas = "images/ui/Background01.xml",
                bg_texture = "Background01.tex",
            })
        end
    end

    for k, btn in ipairs(button_data) do
        local button = self.skillup_buttons[btn.mode]
        local screenkey = {"circle", "replica", "nextlevel", "curlevel", "item"}
        if self.skillup.cureent == btn.mode then
            for k, v in pairs(screenkey) do
                button[v]:Show()
            end
        else
            for k, v in pairs(screenkey) do
                button[v]:Hide()
            end
        end
        local level = self.data[btn.level_key]
        local str = GetLevel(level, btn.mode)
        local str2 = GetLevel(level + 1, btn.mode, true)
        button:SetText(str)
        button.curlevel:SetString(str)
        button.nextlevel:SetString(str2)
        
        button.curlevel.text:SetMultilineTruncatedString(GetString(level, btn.mode), 28, 250)
        
        local nextstr = IsMaxLevel(level, btn.mode) and "" or GetString(level + 1, btn.mode)
        button.nextlevel.text:SetMultilineTruncatedString(nextstr, 28, 250)

        local neednum = 1
        local hasitem, curnum = self.owner.replica.inventory:Has(btn.item, neednum)
        local color = curnum >= neednum and { .25, .75, .25, 1 } or { .7, .7, .7, 1 }
        button.item.text:SetColour(unpack(color))
        button.item.text:SetString(curnum .. "/" .. neednum)
    end
end

function WeaponUI:Update()
    if not self.owner then
        return
    end

    local weapon = Utils.FindEquipWithTag(self.owner, "lightsword")
    if not weapon then
        return
    end

    local mode = weapon.replica.alice_sword:GetCurrentMode()
    local leveldata = {
        shotlevel = weapon.replica.alice_sword:GeLevel(1),
        powerlevel = weapon.replica.alice_sword:GeLevel(2),
        exlevel = weapon.replica.alice_sword:GeLevel(3),
        swordlevel = weapon.replica.alice_sword:GeLevel(4),
    }
    local power = ""
    local battery = weapon.replica.container:GetItemInSlot(1)
    if battery and battery:HasTag("alice_battery") then
        power = Utils.GetPercent(battery)
    end
    
    self.data.shotlevel = leveldata["shotlevel"]
    self.data.exlevel = leveldata["exlevel"]
    self.data.powerlevel = leveldata["powerlevel"]
    self.data.swordlevel = leveldata["swordlevel"]
    self.data.mode = mode
    self.data.power = power

    if self.data.powerlevel == -1 then
        self.buttons[2]:Disable()
    else
        self.buttons[2]:Enable()
    end
    if self.data.swordlevel == -1 then
        self.buttons[4]:Disable()
    else
        self.buttons[4]:Enable()
    end
    self.text3:SetString(self.data.power)
    self.text4:SetString(self.data.key)
    self:UpdateButton()
end

function WeaponUI:Change(num)
    SendModRPCToServer(MOD_RPC["alice"]["lightsword_changemode"], num)
    self:Close()
end

function WeaponUI:Open()
	self:Show()
    self.opening = true
    self:Update()
end

function WeaponUI:Close()
    self.back:Show()
    self.skillback:Hide()
	self:Hide()
    self.opening = false
end

=======
local Screen = require "widgets/screen"
local Button = require "widgets/button"
local AnimButton = require "widgets/animbutton"
local Menu = require "widgets/menu"
local Text = require "widgets/text"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local UIAnim = require "widgets/uianim"
local Widget = require "widgets/widget"
local TEMPLATES = require "widgets/templates"
local ItemSlot = require("widgets/itemslot")
local Utils = require("alice_utils/utils")

local WeaponUI = Class(Widget, function(self, owner)
	Widget._ctor(self, "WeaponUI")

    self.owner = owner

    self.black = self:AddChild(ImageButton("images/global.xml", "square.tex"))
    self.black.image:SetVRegPoint(ANCHOR_MIDDLE)
    self.black.image:SetHRegPoint(ANCHOR_MIDDLE)
    self.black.image:SetVAnchor(ANCHOR_MIDDLE)
    self.black.image:SetHAnchor(ANCHOR_MIDDLE)
    self.black.image:SetScaleMode(SCALEMODE_FILLSCREEN)
    self.black.image:SetTint(0, 0, 0, 0)
    self.black:SetOnClick(function() self:Close() end)

    self.proot = self:AddChild(Widget("ROOT"))
    self.proot:SetVAnchor(ANCHOR_MIDDLE)
    self.proot:SetHAnchor(ANCHOR_MIDDLE)
    self.proot:SetPosition(0, 0, 0)
    self.proot:SetScaleMode(SCALEMODE_PROPORTIONAL)

    self.skillback = self.proot:AddChild(Image("images/ui/skillback.xml", "skillback.tex"))
    self.skillback:Hide()
    self.skillback:MoveToFront()
    self.skillback:SetScale(.5, .5, .5)

    self.skillback.levelbtn = self.skillback:AddChild(ImageButton("images/ui/levelup.xml", "levelup.tex"))
    self.skillback.levelbtn:SetPosition(550, -400, 0)
    self.skillback.levelbtn.focus_scale = {1.05, 1.05, 1.05}

    local backimage = TUNING.ALC_LANGUAGE == "en" and "back_en" or "back"
    self.back = self.proot:AddChild(Image("images/ui/" .. backimage .. ".xml", backimage .. ".tex"))
    self.back:SetScale(1, 1, 1)

    self:Initdata()

    self.text1 = self.back:AddChild(Text(BODYTEXTFONT, 24, TUNING.ALICE_LIGHTSWORD_DAMAGE))
    self.text1:SetColour(UICOLOURS.BLUE)
    self.text1:SetPosition(-60, 93, 0)
    
    self.text2 = self.back:AddChild(Text(BODYTEXTFONT, 24, "50%"))
    self.text2:SetColour(UICOLOURS.BLUE)
    self.text2:SetPosition(100, 93, 0)

    self.text3 = self.back:AddChild(Text(BODYTEXTFONT, 24, self.data.power))
    self.text3:SetColour(UICOLOURS.BLUE)
    self.text3:SetPosition(-60, 66, 0)

    self.text4 = self.back:AddChild(Text(BODYTEXTFONT, 24, self.data.key))
    self.text4:SetColour(UICOLOURS.BLUE)
    self.text4:SetPosition(100, 66, 0)

    self.skillup = self.back:AddChild(ImageButton("images/ui/skillup.xml", "skillup.tex"))
    self.skillup:SetScale(.95, .95, .95)
    self.skillup:SetPosition(152, 0, 0)
    self.skillup:SetOnClick(function()
        self.skillback:Show()
        self.back:Hide()
    end)

    self.buttons = {}
    self.skillup_buttons = {}
    self.skillup.cureent  = 1

    self:AddButton()

    self.inst:DoPeriodicTask(0.2, function()
        if self.opening then
            self:Update()
        end
    end)
end)

local button_data = {
    { 
        icon = "icon1", 
        item = "alice_mode1",
        position = {-145, 8, 0}, 
        position2 = {-700, 270, 0}, 
        level_key = "shotlevel", 
        mode = 1 ,
        text = STRINGS.LIGHTSWORD_MODE[1],
        xml = "images/inventoryimages/alice_mode.xml",
        tex = "alice_mode1.tex",
    },
    { 
        icon = "icon2", 
        item = "alice_mode2",
        position = {-70, 8, 0}, 
        position2 = {-700, 60, 0}, 
        level_key = "powerlevel", 
        mode = 2,
        text = STRINGS.LIGHTSWORD_MODE[2],
        xml = "images/inventoryimages/alice_mode.xml",
        tex = "alice_mode2.tex",
    },
    { 
        icon = "icon3", 
        item = "alice_mode3",
        position = {5, 8, 0}, 
        position2 = {-700, -150, 0}, 
        level_key = "exlevel", 
        mode = 3,
        text = STRINGS.LIGHTSWORD_MODE[3],
        xml = "images/inventoryimages/alice_mode.xml",
        tex = "alice_mode3.tex",
    },
    { 
        icon = "icon4", 
        item = "alice_mode4",
        position = {80, 8, 0}, 
        position2 = {-700, -360, 0}, 
        level_key = "swordlevel", 
        mode = 4,
        text = STRINGS.LIGHTSWORD_MODE[4],
        xml = "images/inventoryimages/alice_mode.xml",
        tex = "alice_mode4.tex",
    },
}

function WeaponUI:Initdata()
    local key = _G[TUNING.LIGHTSWORD_KEY]
    self.data = {
        key = STRINGS.UI.CONTROLSSCREEN.INPUTS[1][key],
        shotlevel = 0,
        powerlevel = 0,
        exlevel = 0,
        swordlevel = 0,
        mode = 0,
        power = 0,
    }
end

local function GetSkillString(damage, flydamage, mode)
    local stringdata = {
        {
            string = "\n" .. STRINGS.ALICEUI.WEAPON.STRING1 .. " " .. damage .. " " .. STRINGS.ALICEUI.WEAPON.STRING6,
        },
        {
            string = "\n" .. STRINGS.ALICEUI.WEAPON.STRING2 .. " " .. flydamage .. " " .. STRINGS.ALICEUI.WEAPON.STRING6 .. ", " .. STRINGS.ALICEUI.WEAPON.STRING3 .. " " .. damage .." " ..  STRINGS.ALICEUI.WEAPON.STRING8,
        },
        {
            string = "\n" .. STRINGS.ALICEUI.WEAPON.STRING4 .. " " .. damage .. " " .. STRINGS.ALICEUI.WEAPON.STRING6,
        },
        {
            string = "\n" .. STRINGS.ALICEUI.WEAPON.STRING5 .. " " .. damage .. " " .. STRINGS.ALICEUI.WEAPON.STRING7,
        },
    }
    return stringdata[mode]["string"]
end

local maxlevel = {10, 4, 5, 5}

local function GetString(level, mode)
    if mode then
        level = math.min(maxlevel[mode], level)
    end
    local damagedata = {
        {
            damage = TUNING.ALICE_LIGHTSWORD_DAMAGE * (0.5 + level * 0.1) / 68 * 100,
        },
        {
            flydamage = TUNING.ALICE_LIGHTSWORD_DAMAGE * (1 + level * 0.5) / 68 * 100,
            damage = TUNING.ALICE_LIGHTSWORD_DAMAGE * (1 + level * 0.25) / 68 * 100,
        },
        {
            damage = TUNING.ALICE_LIGHTSWORD_DAMAGE * (2.5 + level * 0.5) / 68 * 100,
        },
        {
            damage = TUNING.ALICE_LASERTHROW_PLANAR_DAMAGE_MIN + TUNING.ALICE_LASERTHROW_PLANAR_DAMAGE_UP * level,
        },
    }
    local damage = damagedata[mode]["damage"]
    local flydamage = damagedata[mode]["flydamage"] or ""
    local stringdata = GetSkillString(damage, flydamage, mode)
    return stringdata or ""
end

local function IsMaxLevel(level, mode)
    return level == maxlevel[mode]
end

local function GetLevel(level, mode, max)
    if mode then
        level = math.min(maxlevel[mode], level)
    end

    if IsMaxLevel(level, mode) then
        return "Max"
    end
    
    local str = level == -1 and "Unlock" or "Lv." .. level
    return str
end

function WeaponUI:AddButton() 
    for _, btn in ipairs(button_data) do
        local button = self.back:AddChild(ImageButton("images/ui/" .. btn.icon .. ".xml", btn.icon .. ".tex"))
        button:SetPosition(unpack(btn.position))
        
        button:SetTextSize(20)
        button:SetTextColour(UICOLOURS.BLUE)
        button.text:SetPosition(0, -35, 0)
        button:SetOnClick(function() 
            self:Change(btn.mode)
        end)
    
        button.circle = button:AddChild(Image("images/ui/select.xml", "select.tex"))
    
        self.buttons[btn.mode] = button
    end

    for _, btn in ipairs(button_data) do
        local button = self.skillback:AddChild(ImageButton("images/ui/" .. btn.icon .. ".xml", btn.icon .. ".tex"))
        button:SetPosition(unpack(btn.position2))
        button:SetScale(2.5, 2.5, 2.5)

        button.circle = button:AddChild(Image("images/ui/select.xml", "select.tex"))
        button.circle:SetScale(1.5, 1.5, 1.5)

        button.clickoffset = Vector3(0, 0, 0)
        button:SetTextSize(16)
        button:SetTextColour(UICOLOURS.BLUE)
        button.text:SetPosition(0, -28, 0)
        button:SetOnClick(function() 
            self.skillup.cureent = btn.mode
            self:UpdateButton()
        end)
    
        self.skillup_buttons[btn.mode] = button

        local offset_y = btn.mode * 84
        button.replica = button:AddChild(Image("images/ui/" .. btn.icon .. ".xml", btn.icon .. ".tex"))
        button.replica:SetPosition(80, -56 + offset_y, 0)
        button.replica:SetScale(0.8, 0.8, 0.8)
        button.replica:SetClickable(false)

        button.replica.str = button.replica:AddChild(Text(BODYTEXTFONT, 24, btn.text))
        local w1, h1 = button.replica.str:GetRegionSize()
        button.replica.str:SetPosition(30 + w1 / 2, 15 - h1 / 2)

        local level = self.data[btn.level_key]

        button.curlevel = button:AddChild(Text(BODYTEXTFONT, 24, GetLevel(level, btn.mode)))
        local w2, h2 = button.curlevel:GetRegionSize()
        button.curlevel:SetPosition(90 + w2 / 2, -86 + offset_y, 0)

        button.nextlevel = button:AddChild(Text(BODYTEXTFONT, 24, GetLevel(level + 1, btn.mode)))
        local w3, h3 = button.nextlevel:GetRegionSize()
        button.nextlevel:SetPosition(350 + w3 / 2, -86 + offset_y, 0)
        
        local curstr = GetString(level, btn.mode)
        button.curlevel.text = button.curlevel:AddChild(Text(BODYTEXTFONT, 24, curstr))
        button.curlevel.text:SetSize(18)
	    button.curlevel.text:SetMultilineTruncatedString(curstr, 28, 250)
        local w4, h4 = button.curlevel.text:GetRegionSize()
        button.curlevel.text:SetPosition(-10 + w4 / 2 - w2 / 2, -20 - h4 / 2, 0)
        button.curlevel.text:SetHAlign(ANCHOR_LEFT)
        
        local nextstr = GetString(level + 1, btn.mode)
        button.nextlevel.text = button.nextlevel:AddChild(Text(BODYTEXTFONT, 24, nextstr))
        button.nextlevel.text:SetSize(18)
	    button.nextlevel.text:SetMultilineTruncatedString(nextstr, 28, 250)
        local w5, h5 = button.nextlevel.text:GetRegionSize()
        button.nextlevel.text:SetPosition(0 + w5 / 2 - w3 / 2, -20 - h5 / 2, 0)
        button.nextlevel.text:SetHAlign(ANCHOR_LEFT)

        button.item = button:AddChild(Image(btn.xml, btn.tex))
        button.item:SetPosition(125, -270 + offset_y, 0)
        button.item.text = button.item:AddChild(Text(BODYTEXTFONT, 24, ""))
        button.item.text:SetPosition(0, -30, 0)
    end
end

function WeaponUI:UpdateButton()
    self.skillback.levelbtn:SetOnClick(function()
        local weapon = Utils.FindEquipWithTag(self.owner, "lightsword")
        if not weapon then
            return
        end
        SendModRPCToServer(MOD_RPC["alice"]["levelup"], weapon, self.skillup.cureent)
    end)

    for k, btn in ipairs(button_data) do
        local button = self.buttons[btn.mode]
        if self.data.mode == btn.mode then
            button["circle"]:Show()
        else
            button["circle"]:Hide()
        end
        local level = self.data[btn.level_key]
        local str = GetLevel(level, btn.mode)
        button:SetText(str)
        if level ~= -1 then
            local str = GetString(level, btn.mode) or ""
            button:SetHoverText(btn.text .. "     " .. GetLevel(level, btn.mode) .. str, {
                offset_y = 100,
                bg_atlas = "images/ui/Background01.xml",
                bg_texture = "Background01.tex",
            })
        end
    end

    for k, btn in ipairs(button_data) do
        local button = self.skillup_buttons[btn.mode]
        local screenkey = {"circle", "replica", "nextlevel", "curlevel", "item"}
        if self.skillup.cureent == btn.mode then
            for k, v in pairs(screenkey) do
                button[v]:Show()
            end
        else
            for k, v in pairs(screenkey) do
                button[v]:Hide()
            end
        end
        local level = self.data[btn.level_key]
        local str = GetLevel(level, btn.mode)
        local str2 = GetLevel(level + 1, btn.mode, true)
        button:SetText(str)
        button.curlevel:SetString(str)
        button.nextlevel:SetString(str2)
        
        button.curlevel.text:SetMultilineTruncatedString(GetString(level, btn.mode), 28, 250)
        
        local nextstr = IsMaxLevel(level, btn.mode) and "" or GetString(level + 1, btn.mode)
        button.nextlevel.text:SetMultilineTruncatedString(nextstr, 28, 250)

        local neednum = 1
        local hasitem, curnum = self.owner.replica.inventory:Has(btn.item, neednum)
        local color = curnum >= neednum and { .25, .75, .25, 1 } or { .7, .7, .7, 1 }
        button.item.text:SetColour(unpack(color))
        button.item.text:SetString(curnum .. "/" .. neednum)
    end
end

function WeaponUI:Update()
    if not self.owner then
        return
    end

    local weapon = Utils.FindEquipWithTag(self.owner, "lightsword")
    if not weapon then
        return
    end

    local mode = weapon.replica.alice_sword:GetCurrentMode()
    local leveldata = {
        shotlevel = weapon.replica.alice_sword:GeLevel(1),
        powerlevel = weapon.replica.alice_sword:GeLevel(2),
        exlevel = weapon.replica.alice_sword:GeLevel(3),
        swordlevel = weapon.replica.alice_sword:GeLevel(4),
    }
    local power = ""
    local battery = weapon.replica.container:GetItemInSlot(1)
    if battery and battery:HasTag("alice_battery") then
        power = Utils.GetPercent(battery)
    end
    
    self.data.shotlevel = leveldata["shotlevel"]
    self.data.exlevel = leveldata["exlevel"]
    self.data.powerlevel = leveldata["powerlevel"]
    self.data.swordlevel = leveldata["swordlevel"]
    self.data.mode = mode
    self.data.power = power

    if self.data.powerlevel == -1 then
        self.buttons[2]:Disable()
    else
        self.buttons[2]:Enable()
    end
    if self.data.swordlevel == -1 then
        self.buttons[4]:Disable()
    else
        self.buttons[4]:Enable()
    end
    self.text3:SetString(self.data.power)
    self.text4:SetString(self.data.key)
    self:UpdateButton()
end

function WeaponUI:Change(num)
    SendModRPCToServer(MOD_RPC["alice"]["lightsword_changemode"], num)
    self:Close()
end

function WeaponUI:Open()
	self:Show()
    self.opening = true
    self:Update()
end

function WeaponUI:Close()
    self.back:Show()
    self.skillback:Hide()
	self:Hide()
    self.opening = false
end

>>>>>>> 23121469d84d981b602c8a05fcc5a165255f6831
return WeaponUI