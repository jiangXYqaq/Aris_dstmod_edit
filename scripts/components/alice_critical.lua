local Alice_Critical = Class(function(self, inst)
	self.inst = inst

	self.chance = 0
	self.value = 0
end)

function Alice_Critical:Setchance(num)
    self.chance = num
end

function Alice_Critical:Setvalue(num)
    self.value = num
end

function Alice_Critical:Getvalue()
    return self.value
end

function Alice_Critical:Getchance()
    return self.chance
end

function Alice_Critical:Get()
    return self.chance, self.value
end

return Alice_Critical