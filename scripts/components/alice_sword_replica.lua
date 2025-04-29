local SwordReplica = Class(function(self, inst)
    self.inst = inst

    self._mode = net_byte(inst.GUID, "sword.mode", "swordmodedirty")
    self._level_1 = net_shortint(inst.GUID, "sword.level_1", "swordleveldirty")
    self._level_2 = net_shortint(inst.GUID, "sword.level_2", "swordleveldirty")
    self._level_3 = net_shortint(inst.GUID, "sword.level_3", "swordleveldirty")
    self._level_4 = net_shortint(inst.GUID, "sword.level_4", "swordleveldirty")

    self.level = {0, -1, 0, -1,}
end)

function SwordReplica:SetMode(mode)
    self._mode:set(mode)
end

function SwordReplica:UpdateClientLevels(level)
    self._level_1:set(level[1])
    self._level_2:set(level[2])
    self._level_3:set(level[3])
    self._level_4:set(level[4])
end

function SwordReplica:GetCurrentMode()
    return self._mode:value()
end

function SwordReplica:GeLevel(mode)
    mode = mode or self:GetCurrentMode()
    return self["_level_" .. mode]:value()
end

return SwordReplica