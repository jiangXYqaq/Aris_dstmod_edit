local assets= {}

local prefabs = {}


local function commonfn(data)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst:AddTag("FX")

    inst.Light:SetFalloff(data.Falloff)
    inst.Light:SetIntensity(data.Intensity)
    inst.Light:SetRadius(data.Radius)
    inst.Light:SetColour(50 / 255, 100 / 255, 200 / 255)
    inst.Light:SetColour(data.Colour[1], data.Colour[2], data.Colour[3])
    
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

local function fn_ring()
    local data = {
        Falloff = 0.4,
        Intensity = .9,
        Radius = 2.5,
        Colour = {50 / 255, 100 / 255, 200 / 255},
    }
    return commonfn(data)
end

local function fn_remote()
    local data = {
        Falloff = 0.6,
        Intensity = .9,
        Radius = 5,
        Colour = {255 / 255, 224 / 255, 130 / 255},
    }
    return commonfn(data)
end

return Prefab("alice_ring_light", fn_ring, assets, prefabs),
    Prefab("alice_remote_light", fn_remote, assets, prefabs)