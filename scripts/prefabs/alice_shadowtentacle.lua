local assets =
{
    Asset("ANIM", "anim/tentacle_arm.zip"),
    Asset("ANIM", "anim/tentacle_arm_black_build.zip"),
    Asset("SOUND", "sound/tentacle.fsb"),
}

local function shouldKeepTarget()
    return true
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.entity:AddPhysics()
    inst.Physics:SetCylinder(0.25, 2)

    inst.Transform:SetScale(0.5, 0.5, 0.5)

    inst.AnimState:SetMultColour(1, 1, 1, 0.5)

    inst.AnimState:SetBank("tentacle_arm")
    inst.AnimState:SetBuild("tentacle_arm_black_build")
    inst.AnimState:PlayAnimation("idle", true)
    inst.scrapbook_anim = "atk_idle"

    inst:AddTag("shadow")
    inst:AddTag("notarget")
    inst:AddTag("shadow_aligned")

    inst.scrapbook_inspectonseen = true

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	--inst.owner is set when spawned from ruins_bat, slingshotammo

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.TENTACLE_HEALTH)

    inst:AddComponent("combat")
    inst.components.combat:SetRange(2)
    inst.components.combat:SetDefaultDamage(TUNING.TENTACLE_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.TENTACLE_ATTACK_PERIOD)
    inst.components.combat:SetKeepTargetFunction(shouldKeepTarget)

    -- 添加位面伤害组件（核心修改）
    inst:AddComponent("planardamage")
    inst.components.planardamage:SetBaseDamage(15)  -- 15点位面伤害

    -- 添加生命回复功能
    inst:ListenForEvent("onhitother", function(inst, data)
    -- 检查是否有有效的主人
        if inst.owner and inst.owner:IsValid() and inst.owner.components.health then
            -- 为主人回复5点生命值
            inst.owner.components.health:DoDelta(5, false, "tentacle_heal")
        end
    end)

    MakeLargeFreezableCharacter(inst)

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_MED

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot({})

    inst:SetStateGraph("SGshadowtentacle")

    inst:DoTaskInTime(9, inst.Remove)
    inst.persists = false

    return inst
end

return Prefab("alice_shadowtentacle", fn, assets)