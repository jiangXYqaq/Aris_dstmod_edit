local assets =
{
    Asset("ANIM", "anim/jiguang.zip"),
    Asset("ANIM", "anim/_laser_explode_sm.zip"),
}

local prefabs = {}

local function Dosound(inst)
    inst.SoundEmitter:PlaySound("alicesound/alicesound/bomb2", nil, .5)
end

local function spawnjiguang(inst)
	local px, py, pz = inst.Transform:GetWorldPosition()
    local laser = SpawnPrefab("alice_laser")
    laser.Transform:SetPosition(px, py, pz)
    laser.Transform:SetRotation(inst.Transform:GetRotation())
end

local function common(bank, build, anim)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
	inst.entity:AddSoundEmitter()

    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild(build)
    inst.AnimState:PlayAnimation(anim)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetSortOrder(3)

    inst.entity:SetPristine()

    inst:AddTag("NOCLICK")
    inst:AddTag("FX")

    return inst
end

local function laser()
    local inst = common("dandao", "jiguang", "dandao_000")

    inst.Transform:SetScale(2, 2, 2)

    if not TheWorld.ismastersim then
        return inst
    end

    inst:DoTaskInTime(2, inst.Remove)
    return inst
end

local function energy()
    local inst = common("laser_explode_sm", "laser_explode_sm", "anim")

    if not TheWorld.ismastersim then
        return inst
    end

    inst:DoTaskInTime(2, inst.Remove)
    inst:DoTaskInTime(0, Dosound)
    return inst
end

local function firefx()
    local inst = common("dandao", "jiguang", "dandao")

    if not TheWorld.ismastersim then
        return inst
    end

    inst:DoTaskInTime(0, spawnjiguang)
    inst:DoTaskInTime(2, inst.Remove)

    return inst
end

local function SpawnShine(proxy)
    local inst = CreateEntity()

    inst:AddTag("FX")
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()

    inst.Transform:SetFromProxy(proxy.GUID)
    inst.Transform:SetScale(0.5, 0.5, 0.5)

    inst.AnimState:SetBank("crab_king_shine")
    inst.AnimState:SetBuild("crab_king_shine")
    inst.AnimState:PlayAnimation("shine", true)
    inst.AnimState:HideSymbol("sparkle")
    inst.AnimState:SetTime(0.1)

    inst.AnimState:SetLightOverride(1)
    inst.AnimState:SetMultColour(1, 1, 1, 1)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetFinalOffset(1)

    inst:DoTaskInTime(1.2, inst.Remove)

end

local function shinefx()
    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    local net   = inst.entity:AddNetwork()

    inst:AddTag("FX")
    inst:AddTag("NOBLOCK")

    if not TheNet:IsDedicated() then
        inst:DoTaskInTime(0, SpawnShine)
    end

    inst:DoTaskInTime(1, inst.Remove)
 
    inst.entity:SetPristine()
    return inst
end

return Prefab("alice_laser", laser, assets, prefabs),
    Prefab("alice_laser_firefx", firefx, assets, prefabs),
    Prefab("alice_energybomb", energy, assets, prefabs),
    Prefab("alice_charge_fx", shinefx, assets)