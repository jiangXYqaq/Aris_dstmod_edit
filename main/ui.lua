GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})

local Utils = require("alice_utils/utils")
local weaponui = require("widgets/weaponui")
local musicui = require("widgets/musicui")

local key = _G[TUNING.LIGHTSWORD_KEY]

TheInput:AddKeyUpHandler(key, function()
    if not (ThePlayer or Utils.IsDefaultScreen()) then
        return
    end

    local weapon = Utils.FindEquipWithTag(ThePlayer, "lightsword")
    if not weapon then
        --ThePlayer.components.talker:Say(STRINGS.ACTIONS.LIGHTSWORD.NO_LIGHTSWORD)
        return
    end

    if ThePlayer.weaponui then
        if ThePlayer.weaponui.opening then
            ThePlayer.weaponui:Close()
        else
            ThePlayer.weaponui:Open()
        end
    end
end)


local function AddUI(self)
	if self.owner then
		self.weaponui = self:AddChild(weaponui(self.owner, {}))
		self.owner.weaponui = self.weaponui
		self.owner.weaponui:Hide()
		--self.owner.weaponui:Disable()
        
		self.musicui = self:AddChild(musicui(self.owner, {}))
		self.owner.musicui = self.musicui
		self.owner.musicui:Hide()
		--self.owner.musicui:Disable()
	end
end

AddClassPostConstruct("widgets/controls", AddUI)