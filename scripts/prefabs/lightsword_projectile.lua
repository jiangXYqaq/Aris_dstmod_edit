<<<<<<< HEAD
local assets =
{
    Asset("ANIM", "anim/cannonball_rock.zip"),
    Asset("ANIM", "anim/_metal_hulk_projectile.zip"),
}

local prefabs =
{
    "bullkelp_root",
    "cannonball_used",
    "crab_king_waterspout",
}

local Utils = require("alice_utils/utils")
local PROJECTILE_MUST_ONE_OF_TAGS = { "_combat", "_health", "blocker" }
local PROJECTILE_EXCLUDE_TAGS = { "INLIMBO", "notarget", "noattack", "invisible", "playerghost", "player" }

local ONHIT_MUST_ONE_OF_TAGS = { "oceanfishable", "kelp", "_inventoryitem", "wave", "_workable" }

local COLLAPSIBLE_WORK_ACTIONS =
{
    CHOP = true,
    HAMMER = true,
    MINE = true,
    NPC = true,
    DIG = true,
}

for k, v in pairs(COLLAPSIBLE_WORK_ACTIONS) do
    table.insert(ONHIT_MUST_ONE_OF_TAGS, k .. "_workable")
end

local ONHIT_EXCLUDE_TAGS = { "INLIMBO", "noattack", "flight", "invisible", "playerghost", "player" }
local AOE_TARGET_TAGS = { "_combat" }
local AREAATTACK_EXCLUDE_TAGS = { "INLIMBO", "notarget", "noattack", "flight", "invisible", "playerghost", "player", "companion" }

local INITIAL_LAUNCH_HEIGHT = 0.1
local SPEED_XZ = 4
local SPEED_Y = 16
local ANGLE_VARIANCE = 20
local function launch_away(inst, position, use_variant_angle)
    if inst.Physics == nil then
        return
    end

    -- 从碰撞点向外发射。根据位置计算角度，并加入一些偏差
    local ix, iy, iz = inst.Transform:GetWorldPosition()
    inst.Physics:Teleport(ix, iy + INITIAL_LAUNCH_HEIGHT, iz)
    inst.Physics:SetFriction(0.2)

    local px, py, pz = position:Get()
    local random = use_variant_angle and math.random() * ANGLE_VARIANCE * - ANGLE_VARIANCE / 2 or 0
    local angle = ((180 - inst:GetAngleToPoint(px, py, pz)) + random) * DEGREES
    local sina, cosa = math.sin(angle), math.cos(angle)
    inst.Physics:SetVel(SPEED_XZ * cosa, SPEED_Y, SPEED_XZ * sina)

    if inst.components.inventoryitem ~= nil then
        inst.components.inventoryitem:SetLanded(false, true)
    end
end

local function LaunchSound(inst)
    inst.SoundEmitter:PlaySound("monkeyisland/cannon/shoot")
end

local function OnHit(inst, attacker, target)
    if not (attacker or attacker.components.combat) then
        return
    end
    local weapon = Utils.FindEquipWithTag(attacker, "lightsword")
    if weapon then
        local pos = inst:GetPosition()
        local ents = TheSim:FindEntities(pos.x, 0, pos.z, TUNING.ALICE_SHOT2_SPLASH_RADIUS, AOE_TARGET_TAGS, AREAATTACK_EXCLUDE_TAGS)
		for _, target in ipairs(ents) do    
			if target ~= attacker and target:IsValid() and not target:IsInLimbo() and not (target.components.health and target.components.health:IsDead()) then
                local damage = weapon.components.alice_sword:GeDamage(false)
                local stimuli = nil
                if attacker.components.electricattacks ~= nil then
                    stimuli = "electric"
                end
                local _weapon_cmp = weapon ~= nil and weapon.components.weapon or nil
                if  (stimuli == "electric" or (_weapon_cmp ~= nil and _weapon_cmp.stimuli == "electric")) and 
                        not (target:HasTag("electricdamageimmune") or (target.components.inventory ~= nil and target.components.inventory:IsInsulated()))
                then
                    local electric_damage_mult = _weapon_cmp ~= nil and _weapon_cmp.electric_damage_mult or TUNING.ELECTRIC_DAMAGE_MULT
                    local electric_wet_damage_mult = _weapon_cmp ~= nil and _weapon_cmp.electric_wet_damage_mult or TUNING.ELECTRIC_WET_DAMAGE_MULT

                    local mult = electric_damage_mult + electric_wet_damage_mult * (target.components.moisture ~= nil and target.components.moisture:GetMoisturePercent() or (target:GetIsWet() and 1 or 0))
                    damage = damage * mult
                end
                target.components.combat:GetAttacked(attacker, damage, weapon, stimuli)
			end
		end
    end

    -- 检查炮弹是否落在船上
    if target == nil then
        local hitpos = inst:GetPosition()
        target = TheWorld.Map:GetPlatformAtPoint(hitpos.x, hitpos.z)
    end

    -- 目标是船则造成泄漏，扣除100点生命
    if target and target:HasTag("boat") then
        local hitpos = inst:GetPosition()
        target:PushEvent("spawnnewboatleak", { pt = hitpos, leak_size = "med_leak", playsoundfx = true, cause ="cannonball" })
        target.components.health:DoDelta(-TUNING.ALICE_SHOT2_DAMAGE/2)
    end

    -- 寻找海洋/地面上的物体并将它们抛起
    local x, y, z = inst.Transform:GetWorldPosition()
    local position = inst:GetPosition()

    local affected_entities = TheSim:FindEntities(x, 0, z, TUNING.ALICE_SHOT2_SPLASH_RADIUS, nil, ONHIT_EXCLUDE_TAGS, ONHIT_MUST_ONE_OF_TAGS) -- Set y to zero to look for objects floating on the ocean
    for i, affected_entity in ipairs(affected_entities) do
        -- 查找溅射半径内的鱼，被击中后杀死并生成它们的战利品
        if affected_entity.components.oceanfishable ~= nil then
            if affected_entity.fish_def and affected_entity.fish_def.loot then
                local loot_table = affected_entity.fish_def.loot
                for i, product in ipairs(loot_table) do
                    local loot = SpawnPrefab(product)
                    if loot ~= nil then
                        local ae_x, ae_y, ae_z = affected_entity.Transform:GetWorldPosition()
                        loot.Transform:SetPosition(ae_x, ae_y, ae_z)
                        launch_away(loot, position, true)
                    end
                end
                affected_entity:Remove()
            end
        -- 如果击中了海带，则生成海带根和掉落物
        elseif affected_entity.prefab == "bullkelp_plant" then
            local ae_x, ae_y, ae_z = affected_entity.Transform:GetWorldPosition()
            if affected_entity.components.pickable and affected_entity.components.pickable:CanBePicked() then
                local product = affected_entity.components.pickable.product
                local loot = SpawnPrefab(product)
                if loot ~= nil then
                    loot.Transform:SetPosition(ae_x, ae_y, ae_z)
                    if loot.components.inventoryitem ~= nil then
                        loot.components.inventoryitem:MakeMoistureAtLeast(TUNING.OCEAN_WETNESS)
                    end
                    if loot.components.stackable ~= nil
                            and affected_entity.components.pickable.numtoharvest > 1 then
                        loot.components.stackable:SetStackSize(affected_entity.components.pickable.numtoharvest)
                    end
                    launch_away(loot, position)
                end
            end
            local uprooted_kelp_plant = SpawnPrefab("bullkelp_root")
            if uprooted_kelp_plant ~= nil then
                uprooted_kelp_plant.Transform:SetPosition(ae_x, ae_y, ae_z)
                launch_away(uprooted_kelp_plant, position + Vector3(0.5*math.random(), 0, 0.5*math.random()))
            end
            affected_entity:Remove()
        -- 击飞可拾取物品
        elseif affected_entity.components.inventoryitem ~= nil then
            launch_away(affected_entity, position)
        elseif affected_entity.waveactive then
            affected_entity:DoSplash()
        elseif affected_entity.components.workable then -- 破坏建筑
            affected_entity.components.workable:Destroy(inst)
        end
    end

    local fx = SpawnPrefab("alice_energybomb")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx.AnimState:SetScale(2, 2, 2)
    if TheWorld.components.dockmanager ~= nil then -- 破坏码头
        TheWorld.components.dockmanager:DamageDockAtPoint(x, y, z, TUNING.ALICE_SHOT2_DAMAGE)
    end

    inst:Remove()
end

local function OnUpdateProjectile(inst)
    local selfboat = inst.shooter and inst.shooter:IsValid() and inst.shooter:GetCurrentPlatform() or nil
    local x, y, z = inst.Transform:GetWorldPosition()
    local targets = TheSim:FindEntities(x, 0, z, TUNING.ALICE_SHOT2_RADIUS, nil, PROJECTILE_EXCLUDE_TAGS, PROJECTILE_MUST_ONE_OF_TAGS) -- Set y to zero to look for objects on the ground
    for i, target in ipairs(targets) do
        if target ~= nil and target ~= inst and target ~= inst.components.complexprojectile.attacker and not target:HasTag("boatbumper") then
            -- 如果东西在其他船上，它们应该被击中和伤害，但在同一船上时要有条件地处理。
            local on_other_boat = selfboat == nil or target:GetCurrentPlatform() ~= selfboat
            local is_wall = target:HasTag("wall")

            -- 对有健康值的实体造成伤害
            if target.components.combat and GetTime() - target.components.combat.lastwasattackedtime > TUNING.CANNONBALL_PASS_THROUGH_TIME_BUFFER then
                if not is_wall or is_wall and on_other_boat then
                    local attacker = inst.components.complexprojectile.attacker or inst
                    local weapon = Utils.FindEquipWithTag(attacker, "lightsword")
                    local damage = 68
                    if weapon then
                        damage = weapon.components.alice_sword:GeDamage(true)
                    end
                    local stimuli = nil
                    if attacker.components.electricattacks ~= nil then
                        stimuli = "electric"
                    end

                    local _weapon_cmp = weapon ~= nil and weapon.components.weapon or nil
                    if  (stimuli == "electric" or (_weapon_cmp ~= nil and _weapon_cmp.stimuli == "electric")) and 
                            not (target:HasTag("electricdamageimmune") or (target.components.inventory ~= nil and target.components.inventory:IsInsulated()))
                    then
                        local electric_damage_mult = _weapon_cmp ~= nil and _weapon_cmp.electric_damage_mult or TUNING.ELECTRIC_DAMAGE_MULT
                        local electric_wet_damage_mult = _weapon_cmp ~= nil and _weapon_cmp.electric_wet_damage_mult or TUNING.ELECTRIC_WET_DAMAGE_MULT

                        local mult = electric_damage_mult + electric_wet_damage_mult * (target.components.moisture ~= nil and target.components.moisture:GetMoisturePercent() or (target:GetIsWet() and 1 or 0))
                        damage = damage * mult
                    end
                    target.components.combat:GetAttacked(attacker, damage, weapon, stimuli)
                end
            end

            if on_other_boat then
                -- 命中墙壁造成溅射伤害
                if is_wall and target.components.health then
                    if not target.components.health:IsDead() then
                        inst.components.combat:DoAreaAttack(inst, TUNING.ALICE_SHOT2_SPLASH_RADIUS, nil, nil, nil, AREAATTACK_EXCLUDE_TAGS)
                        SpawnPrefab("cannonball_used").Transform:SetPosition(inst.Transform:GetWorldPosition())
                        inst:Remove()
                        return
                    end
                -- 破坏可工作对象
                elseif target.components.workable then
                    target.components.workable:Destroy(inst)
                end
            end
        end
    end
end


local function cannonball_common(inst)
    inst.entity:AddPhysics()
    inst.Physics:SetMass(1)
    inst.Physics:SetFriction(0)
    inst.Physics:SetDamping(0)
    inst.Physics:SetRestitution(0)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.GROUND)
    inst.Physics:SetSphere(TUNING.ALICE_SHOT2_RADIUS)
    inst.Physics:SetCollides(false) -- 炮弹击中目标将由 OnUpdateProjectile() 使用 FindEntities() 处理

    if not TheNet:IsDedicated() then
        -- 延迟添加地面阴影以防止其暂时出现在 (0,0,0) 位置
        inst:DoTaskInTime(0, function(inst)
            inst:AddComponent("groundshadowhandler")
            local x, y, z = inst.Transform:GetWorldPosition()
            inst.components.groundshadowhandler.ground_shadow.Transform:SetPosition(x, 0, z)
            inst.components.groundshadowhandler:SetSize(1, 0.5)
        end)
    end
end

local function cannonball_maseter(inst)
    inst.persists = false

    inst:AddComponent("complexprojectile")

    inst.components.complexprojectile:SetHorizontalSpeed(25) --水平速度
    inst.components.complexprojectile:SetGravity(-40) --重力加速度
    inst.components.complexprojectile.usehigharc = false --高弧线
    inst.components.complexprojectile:SetOnHit(OnHit)
    inst.components.complexprojectile:SetOnUpdate(OnUpdateProjectile)
    inst.components.complexprojectile:SetOnLaunch(LaunchSound)
    inst.components.complexprojectile:SetLaunchOffset(Vector3(1.5, 1, 0))

    inst:AddComponent("locomotor")

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.ALICE_SHOT2_DAMAGE)
    inst.components.combat:SetAreaDamage(TUNING.ALICE_SHOT2_SPLASH_RADIUS, TUNING.CANNONBALL_SPLASH_DAMAGE_PERCENT)

    return inst
end

-- 击中效果
local function OnHit_laser(target)
    if target and target:IsValid() then
        SpawnPrefab("alterguardian_laserhit"):SetTarget(target)
    end
end

local function OnHit_shot2(target)
    if target and target:IsValid() then
        SpawnPrefab("electricchargedfx"):SetTarget(target)
    end
end

local function OnHit_shot1(target, inst)
    inst:Remove()
end

-- 客户端
local function commonfn(inst)
    inst._status = net_tinybyte(inst.GUID, "status", "status")
    inst._status:set_local(0)

    inst.AnimState:SetLightOverride(0.5)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
end

local function shot2_common(inst)
    commonfn(inst)
    inst.AnimState:SetLightOverride(2)
end

-- 服务端
local function masterfn(inst)
    inst.components.projectile:SetLaunchOffset(Vector3(1.5, 0, 0))
    inst:AddComponent("lightsword_projectile")
end

local function laser_master(inst)
    masterfn(inst)
	inst.components.lightsword_projectile:SetOnHitFn(OnHit_laser)
end

local function shot1_master(inst)
    masterfn(inst)
	inst.components.lightsword_projectile:SetOnHitFn(OnHit_shot1)
end

local function shot2_master(inst)
    masterfn(inst)
	inst.components.lightsword_projectile:SetOnHitFn(OnHit_shot2)
end

local function MakeProjectile(prefab, data)
	local bank = data.anim.bank
	local build = data.anim.build
	local animation = data.anim.anim
	local onground = data.anim.onground == true

	local function fn()
	    local inst = CreateEntity()
	    local trans = inst.entity:AddTransform()
	    local anim = inst.entity:AddAnimState()
	    local sound = inst.entity:AddSoundEmitter()
	    local net = inst.entity:AddNetwork()

	    inst.prefabname = prefab

	    MakeProjectilePhysics(inst)
	    inst.Physics:SetFriction(0)
		inst.Physics:SetDamping(10)
		inst.Physics:SetRestitution(0)
    
	    anim:SetBank(bank)
	    anim:SetBuild(build)
	    anim:PlayAnimation(animation, true)
	    if onground then
	        anim:SetOrientation(ANIM_ORIENTATION.OnGround)
	    end
    
        if prefab == "alice_shot1"  then
            --inst.AnimState:SetScale(0.5, 0.5, 0.5)
            --inst.AnimState:SetMultColour(0.5, 0.7, 1, .8)
        end
        if prefab == "alice_shot2" then
            inst.AnimState:SetScale(0.5, 0.5, 0.5)
            inst.glow = inst.entity:AddLight()    
            inst.glow:SetIntensity(.6)
            inst.glow:SetRadius(5)
            inst.glow:SetFalloff(3)
            inst.glow:SetColour(1, 0.3, 0.3)
            inst.glow:Enable(false)
        end

        if prefab ~= "alice_shot2" then
	        inst:AddTag("projectile")
        end

	    inst.persists = false
    
	    if data.commonfn then
	        data.commonfn(inst)
	    end

	    inst.entity:SetPristine()

	    if not TheWorld.ismastersim then
	        return inst
	    end

        if prefab ~= "alice_shot2" then
            inst:AddComponent("projectile")
            inst.components.projectile:SetSpeed(10)
            inst.components.projectile:SetHoming(false)
            inst.components.projectile:SetHitDist(10)
            inst.components.projectile:SetOnHitFn(inst.Remove)
            inst.components.projectile:SetOnMissFn(inst.Remove)
        end

	    if data.masterfn then
	        data.masterfn(inst)
	    end

        if data.sound then
            inst.SoundEmitter:PlaySound(data.sound, nil, 0.5)
        end

        if inst.components.lightsword_projectile then
            inst.components.lightsword_projectile.damage1 = data.damage
            inst.components.lightsword_projectile.maxhits = data.maxhits or 1
            inst.components.lightsword_projectile.lightatk = data.lightatk
            inst.components.lightsword_projectile.width = data.width or 3
            if data.range then
                inst.components.lightsword_projectile.range = data.range
            end

            if data.speed then
                inst.components.lightsword_projectile.speed = data.speed
            end

            if data.plannardamage then
                inst.components.lightsword_projectile.spdamage = {
                    planar = data.plannardamage
                }
            end

            if data.noremoveonhit then
                inst.components.lightsword_projectile.removeonhit = false
            end
        end

	    return inst
	end

    return Prefab(prefab, fn, data.assets) 
end

return
    MakeProjectile("alice_shot1", {
        anim = {bank = "alice_shot_fx", build = "alice_shot_fx", anim = "idle", onground = false},
        assets = assets,
        masterfn = shot1_master,
        commonfn = commonfn,
        range = 20,
        speed = 20,
        noremoveonhit = true,
        sound = "alicesound/alicesound/alice_shot1",
    }),
    MakeProjectile("alice_shot2", {
        anim = {bank = "metal_hulk_projectile", build = "metal_hulk_projectile", anim = "spin_loop", onground = false},
        assets = assets,
        masterfn = cannonball_maseter,
        commonfn = cannonball_common,
    }),
    MakeProjectile("alice_shot3", {
        anim = {bank = "alice_shot_fx", build = "alice_shot_fx", anim = "idle", onground = false},
        assets = assets,
        masterfn = laser_master,
        commonfn = commonfn,
        maxhits = math.huge,
        speed = 200,
        width = 3,
        range = 58,
        sound = "alicesound/alicesound/alice_chargeshot",
    }),
    MakeProjectile("alice_shot4", {
        anim = {bank = "", build = "", anim = "", onground = false},
        assets = assets,
        commonfn = commonfn,
=======
local assets =
{
    Asset("ANIM", "anim/cannonball_rock.zip"),
    Asset("ANIM", "anim/_metal_hulk_projectile.zip"),
}

local prefabs =
{
    "bullkelp_root",
    "cannonball_used",
    "crab_king_waterspout",
}

local Utils = require("alice_utils/utils")
local PROJECTILE_MUST_ONE_OF_TAGS = { "_combat", "_health", "blocker" }
local PROJECTILE_EXCLUDE_TAGS = { "INLIMBO", "notarget", "noattack", "invisible", "playerghost", "player" }

local ONHIT_MUST_ONE_OF_TAGS = { "oceanfishable", "kelp", "_inventoryitem", "wave", "_workable" }

local COLLAPSIBLE_WORK_ACTIONS =
{
    CHOP = true,
    HAMMER = true,
    MINE = true,
    NPC = true,
    DIG = true,
}

for k, v in pairs(COLLAPSIBLE_WORK_ACTIONS) do
    table.insert(ONHIT_MUST_ONE_OF_TAGS, k .. "_workable")
end

local ONHIT_EXCLUDE_TAGS = { "INLIMBO", "noattack", "flight", "invisible", "playerghost", "player" }
local AOE_TARGET_TAGS = { "_combat" }
local AREAATTACK_EXCLUDE_TAGS = { "INLIMBO", "notarget", "noattack", "flight", "invisible", "playerghost", "player", "companion" }

local INITIAL_LAUNCH_HEIGHT = 0.1
local SPEED_XZ = 4
local SPEED_Y = 16
local ANGLE_VARIANCE = 20
local function launch_away(inst, position, use_variant_angle)
    if inst.Physics == nil then
        return
    end

    -- 从碰撞点向外发射。根据位置计算角度，并加入一些偏差
    local ix, iy, iz = inst.Transform:GetWorldPosition()
    inst.Physics:Teleport(ix, iy + INITIAL_LAUNCH_HEIGHT, iz)
    inst.Physics:SetFriction(0.2)

    local px, py, pz = position:Get()
    local random = use_variant_angle and math.random() * ANGLE_VARIANCE * - ANGLE_VARIANCE / 2 or 0
    local angle = ((180 - inst:GetAngleToPoint(px, py, pz)) + random) * DEGREES
    local sina, cosa = math.sin(angle), math.cos(angle)
    inst.Physics:SetVel(SPEED_XZ * cosa, SPEED_Y, SPEED_XZ * sina)

    if inst.components.inventoryitem ~= nil then
        inst.components.inventoryitem:SetLanded(false, true)
    end
end

local function LaunchSound(inst)
    inst.SoundEmitter:PlaySound("monkeyisland/cannon/shoot")
end

local function OnHit(inst, attacker, target)
    if not (attacker or attacker.components.combat) then
        return
    end
    local weapon = Utils.FindEquipWithTag(attacker, "lightsword")
    if weapon then
        local pos = inst:GetPosition()
        local ents = TheSim:FindEntities(pos.x, 0, pos.z, TUNING.ALICE_SHOT2_SPLASH_RADIUS, AOE_TARGET_TAGS, AREAATTACK_EXCLUDE_TAGS)
		for _, target in ipairs(ents) do    
			if target ~= attacker and target:IsValid() and not target:IsInLimbo() and not (target.components.health and target.components.health:IsDead()) then
                local damage = weapon.components.alice_sword:GeDamage(false)
                local stimuli = nil
                if attacker.components.electricattacks ~= nil then
                    stimuli = "electric"
                end
                local _weapon_cmp = weapon ~= nil and weapon.components.weapon or nil
                if  (stimuli == "electric" or (_weapon_cmp ~= nil and _weapon_cmp.stimuli == "electric")) and 
                        not (target:HasTag("electricdamageimmune") or (target.components.inventory ~= nil and target.components.inventory:IsInsulated()))
                then
                    local electric_damage_mult = _weapon_cmp ~= nil and _weapon_cmp.electric_damage_mult or TUNING.ELECTRIC_DAMAGE_MULT
                    local electric_wet_damage_mult = _weapon_cmp ~= nil and _weapon_cmp.electric_wet_damage_mult or TUNING.ELECTRIC_WET_DAMAGE_MULT

                    local mult = electric_damage_mult + electric_wet_damage_mult * (target.components.moisture ~= nil and target.components.moisture:GetMoisturePercent() or (target:GetIsWet() and 1 or 0))
                    damage = damage * mult
                end
                target.components.combat:GetAttacked(attacker, damage, weapon, stimuli)
			end
		end
    end

    -- 检查炮弹是否落在船上
    if target == nil then
        local hitpos = inst:GetPosition()
        target = TheWorld.Map:GetPlatformAtPoint(hitpos.x, hitpos.z)
    end

    -- 目标是船则造成泄漏，扣除100点生命
    if target and target:HasTag("boat") then
        local hitpos = inst:GetPosition()
        target:PushEvent("spawnnewboatleak", { pt = hitpos, leak_size = "med_leak", playsoundfx = true, cause ="cannonball" })
        target.components.health:DoDelta(-TUNING.ALICE_SHOT2_DAMAGE/2)
    end

    -- 寻找海洋/地面上的物体并将它们抛起
    local x, y, z = inst.Transform:GetWorldPosition()
    local position = inst:GetPosition()

    local affected_entities = TheSim:FindEntities(x, 0, z, TUNING.ALICE_SHOT2_SPLASH_RADIUS, nil, ONHIT_EXCLUDE_TAGS, ONHIT_MUST_ONE_OF_TAGS) -- Set y to zero to look for objects floating on the ocean
    for i, affected_entity in ipairs(affected_entities) do
        -- 查找溅射半径内的鱼，被击中后杀死并生成它们的战利品
        if affected_entity.components.oceanfishable ~= nil then
            if affected_entity.fish_def and affected_entity.fish_def.loot then
                local loot_table = affected_entity.fish_def.loot
                for i, product in ipairs(loot_table) do
                    local loot = SpawnPrefab(product)
                    if loot ~= nil then
                        local ae_x, ae_y, ae_z = affected_entity.Transform:GetWorldPosition()
                        loot.Transform:SetPosition(ae_x, ae_y, ae_z)
                        launch_away(loot, position, true)
                    end
                end
                affected_entity:Remove()
            end
        -- 如果击中了海带，则生成海带根和掉落物
        elseif affected_entity.prefab == "bullkelp_plant" then
            local ae_x, ae_y, ae_z = affected_entity.Transform:GetWorldPosition()
            if affected_entity.components.pickable and affected_entity.components.pickable:CanBePicked() then
                local product = affected_entity.components.pickable.product
                local loot = SpawnPrefab(product)
                if loot ~= nil then
                    loot.Transform:SetPosition(ae_x, ae_y, ae_z)
                    if loot.components.inventoryitem ~= nil then
                        loot.components.inventoryitem:MakeMoistureAtLeast(TUNING.OCEAN_WETNESS)
                    end
                    if loot.components.stackable ~= nil
                            and affected_entity.components.pickable.numtoharvest > 1 then
                        loot.components.stackable:SetStackSize(affected_entity.components.pickable.numtoharvest)
                    end
                    launch_away(loot, position)
                end
            end
            local uprooted_kelp_plant = SpawnPrefab("bullkelp_root")
            if uprooted_kelp_plant ~= nil then
                uprooted_kelp_plant.Transform:SetPosition(ae_x, ae_y, ae_z)
                launch_away(uprooted_kelp_plant, position + Vector3(0.5*math.random(), 0, 0.5*math.random()))
            end
            affected_entity:Remove()
        -- 击飞可拾取物品
        elseif affected_entity.components.inventoryitem ~= nil then
            launch_away(affected_entity, position)
        elseif affected_entity.waveactive then
            affected_entity:DoSplash()
        elseif affected_entity.components.workable then -- 破坏建筑
            affected_entity.components.workable:Destroy(inst)
        end
    end

    local fx = SpawnPrefab("alice_energybomb")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx.AnimState:SetScale(2, 2, 2)
    if TheWorld.components.dockmanager ~= nil then -- 破坏码头
        TheWorld.components.dockmanager:DamageDockAtPoint(x, y, z, TUNING.ALICE_SHOT2_DAMAGE)
    end

    inst:Remove()
end

local function OnUpdateProjectile(inst)
    local selfboat = inst.shooter and inst.shooter:IsValid() and inst.shooter:GetCurrentPlatform() or nil
    local x, y, z = inst.Transform:GetWorldPosition()
    local targets = TheSim:FindEntities(x, 0, z, TUNING.ALICE_SHOT2_RADIUS, nil, PROJECTILE_EXCLUDE_TAGS, PROJECTILE_MUST_ONE_OF_TAGS) -- Set y to zero to look for objects on the ground
    for i, target in ipairs(targets) do
        if target ~= nil and target ~= inst and target ~= inst.components.complexprojectile.attacker and not target:HasTag("boatbumper") then
            -- 如果东西在其他船上，它们应该被击中和伤害，但在同一船上时要有条件地处理。
            local on_other_boat = selfboat == nil or target:GetCurrentPlatform() ~= selfboat
            local is_wall = target:HasTag("wall")

            -- 对有健康值的实体造成伤害
            if target.components.combat and GetTime() - target.components.combat.lastwasattackedtime > TUNING.CANNONBALL_PASS_THROUGH_TIME_BUFFER then
                if not is_wall or is_wall and on_other_boat then
                    local attacker = inst.components.complexprojectile.attacker or inst
                    local weapon = Utils.FindEquipWithTag(attacker, "lightsword")
                    local damage = 68
                    if weapon then
                        damage = weapon.components.alice_sword:GeDamage(true)
                    end
                    local stimuli = nil
                    if attacker.components.electricattacks ~= nil then
                        stimuli = "electric"
                    end

                    local _weapon_cmp = weapon ~= nil and weapon.components.weapon or nil
                    if  (stimuli == "electric" or (_weapon_cmp ~= nil and _weapon_cmp.stimuli == "electric")) and 
                            not (target:HasTag("electricdamageimmune") or (target.components.inventory ~= nil and target.components.inventory:IsInsulated()))
                    then
                        local electric_damage_mult = _weapon_cmp ~= nil and _weapon_cmp.electric_damage_mult or TUNING.ELECTRIC_DAMAGE_MULT
                        local electric_wet_damage_mult = _weapon_cmp ~= nil and _weapon_cmp.electric_wet_damage_mult or TUNING.ELECTRIC_WET_DAMAGE_MULT

                        local mult = electric_damage_mult + electric_wet_damage_mult * (target.components.moisture ~= nil and target.components.moisture:GetMoisturePercent() or (target:GetIsWet() and 1 or 0))
                        damage = damage * mult
                    end
                    target.components.combat:GetAttacked(attacker, damage, weapon, stimuli)
                end
            end

            if on_other_boat then
                -- 命中墙壁造成溅射伤害
                if is_wall and target.components.health then
                    if not target.components.health:IsDead() then
                        inst.components.combat:DoAreaAttack(inst, TUNING.ALICE_SHOT2_SPLASH_RADIUS, nil, nil, nil, AREAATTACK_EXCLUDE_TAGS)
                        SpawnPrefab("cannonball_used").Transform:SetPosition(inst.Transform:GetWorldPosition())
                        inst:Remove()
                        return
                    end
                -- 破坏可工作对象
                elseif target.components.workable then
                    target.components.workable:Destroy(inst)
                end
            end
        end
    end
end


local function cannonball_common(inst)
    inst.entity:AddPhysics()
    inst.Physics:SetMass(1)
    inst.Physics:SetFriction(0)
    inst.Physics:SetDamping(0)
    inst.Physics:SetRestitution(0)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.GROUND)
    inst.Physics:SetSphere(TUNING.ALICE_SHOT2_RADIUS)
    inst.Physics:SetCollides(false) -- 炮弹击中目标将由 OnUpdateProjectile() 使用 FindEntities() 处理

    if not TheNet:IsDedicated() then
        -- 延迟添加地面阴影以防止其暂时出现在 (0,0,0) 位置
        inst:DoTaskInTime(0, function(inst)
            inst:AddComponent("groundshadowhandler")
            local x, y, z = inst.Transform:GetWorldPosition()
            inst.components.groundshadowhandler.ground_shadow.Transform:SetPosition(x, 0, z)
            inst.components.groundshadowhandler:SetSize(1, 0.5)
        end)
    end
end

local function cannonball_maseter(inst)
    inst.persists = false

    inst:AddComponent("complexprojectile")

    inst.components.complexprojectile:SetHorizontalSpeed(25) --水平速度
    inst.components.complexprojectile:SetGravity(-40) --重力加速度
    inst.components.complexprojectile.usehigharc = false --高弧线
    inst.components.complexprojectile:SetOnHit(OnHit)
    inst.components.complexprojectile:SetOnUpdate(OnUpdateProjectile)
    inst.components.complexprojectile:SetOnLaunch(LaunchSound)
    inst.components.complexprojectile:SetLaunchOffset(Vector3(1.5, 1, 0))

    inst:AddComponent("locomotor")

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.ALICE_SHOT2_DAMAGE)
    inst.components.combat:SetAreaDamage(TUNING.ALICE_SHOT2_SPLASH_RADIUS, TUNING.CANNONBALL_SPLASH_DAMAGE_PERCENT)

    return inst
end

-- 击中效果
local function OnHit_laser(target)
    if target and target:IsValid() then
        SpawnPrefab("alterguardian_laserhit"):SetTarget(target)
    end
end

local function OnHit_shot2(target)
    if target and target:IsValid() then
        SpawnPrefab("electricchargedfx"):SetTarget(target)
    end
end

local function OnHit_shot1(target, inst)
    inst:Remove()
end

-- 客户端
local function commonfn(inst)
    inst._status = net_tinybyte(inst.GUID, "status", "status")
    inst._status:set_local(0)

    inst.AnimState:SetLightOverride(0.5)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
end

local function shot2_common(inst)
    commonfn(inst)
    inst.AnimState:SetLightOverride(2)
end

-- 服务端
local function masterfn(inst)
    inst.components.projectile:SetLaunchOffset(Vector3(1.5, 0, 0))
    inst:AddComponent("lightsword_projectile")
end

local function laser_master(inst)
    masterfn(inst)
	inst.components.lightsword_projectile:SetOnHitFn(OnHit_laser)
end

local function shot1_master(inst)
    masterfn(inst)
	inst.components.lightsword_projectile:SetOnHitFn(OnHit_shot1)
end

local function shot2_master(inst)
    masterfn(inst)
	inst.components.lightsword_projectile:SetOnHitFn(OnHit_shot2)
end

local function MakeProjectile(prefab, data)
	local bank = data.anim.bank
	local build = data.anim.build
	local animation = data.anim.anim
	local onground = data.anim.onground == true

	local function fn()
	    local inst = CreateEntity()
	    local trans = inst.entity:AddTransform()
	    local anim = inst.entity:AddAnimState()
	    local sound = inst.entity:AddSoundEmitter()
	    local net = inst.entity:AddNetwork()

	    inst.prefabname = prefab

	    MakeProjectilePhysics(inst)
	    inst.Physics:SetFriction(0)
		inst.Physics:SetDamping(10)
		inst.Physics:SetRestitution(0)
    
	    anim:SetBank(bank)
	    anim:SetBuild(build)
	    anim:PlayAnimation(animation, true)
	    if onground then
	        anim:SetOrientation(ANIM_ORIENTATION.OnGround)
	    end
    
        if prefab == "alice_shot1"  then
            --inst.AnimState:SetScale(0.5, 0.5, 0.5)
            --inst.AnimState:SetMultColour(0.5, 0.7, 1, .8)
        end
        if prefab == "alice_shot2" then
            inst.AnimState:SetScale(0.5, 0.5, 0.5)
            inst.glow = inst.entity:AddLight()    
            inst.glow:SetIntensity(.6)
            inst.glow:SetRadius(5)
            inst.glow:SetFalloff(3)
            inst.glow:SetColour(1, 0.3, 0.3)
            inst.glow:Enable(false)
        end

        if prefab ~= "alice_shot2" then
	        inst:AddTag("projectile")
        end

	    inst.persists = false
    
	    if data.commonfn then
	        data.commonfn(inst)
	    end

	    inst.entity:SetPristine()

	    if not TheWorld.ismastersim then
	        return inst
	    end

        if prefab ~= "alice_shot2" then
            inst:AddComponent("projectile")
            inst.components.projectile:SetSpeed(10)
            inst.components.projectile:SetHoming(false)
            inst.components.projectile:SetHitDist(10)
            inst.components.projectile:SetOnHitFn(inst.Remove)
            inst.components.projectile:SetOnMissFn(inst.Remove)
        end

	    if data.masterfn then
	        data.masterfn(inst)
	    end

        if data.sound then
            inst.SoundEmitter:PlaySound(data.sound, nil, 0.5)
        end

        if inst.components.lightsword_projectile then
            inst.components.lightsword_projectile.damage1 = data.damage
            inst.components.lightsword_projectile.maxhits = data.maxhits or 1
            inst.components.lightsword_projectile.lightatk = data.lightatk
            inst.components.lightsword_projectile.width = data.width or 3
            if data.range then
                inst.components.lightsword_projectile.range = data.range
            end

            if data.speed then
                inst.components.lightsword_projectile.speed = data.speed
            end

            if data.plannardamage then
                inst.components.lightsword_projectile.spdamage = {
                    planar = data.plannardamage
                }
            end

            if data.noremoveonhit then
                inst.components.lightsword_projectile.removeonhit = false
            end
        end

	    return inst
	end

    return Prefab(prefab, fn, data.assets) 
end

return
    MakeProjectile("alice_shot1", {
        anim = {bank = "alice_shot_fx", build = "alice_shot_fx", anim = "idle", onground = false},
        assets = assets,
        masterfn = shot1_master,
        commonfn = commonfn,
        range = 20,
        speed = 20,
        noremoveonhit = true,
        sound = "alicesound/alicesound/alice_shot1",
    }),
    MakeProjectile("alice_shot2", {
        anim = {bank = "metal_hulk_projectile", build = "metal_hulk_projectile", anim = "spin_loop", onground = false},
        assets = assets,
        masterfn = cannonball_maseter,
        commonfn = cannonball_common,
    }),
    MakeProjectile("alice_shot3", {
        anim = {bank = "alice_shot_fx", build = "alice_shot_fx", anim = "idle", onground = false},
        assets = assets,
        masterfn = laser_master,
        commonfn = commonfn,
        maxhits = math.huge,
        speed = 200,
        width = 3,
        range = 58,
        sound = "alicesound/alicesound/alice_chargeshot",
    }),
    MakeProjectile("alice_shot4", {
        anim = {bank = "", build = "", anim = "", onground = false},
        assets = assets,
        commonfn = commonfn,
>>>>>>> 23121469d84d981b602c8a05fcc5a165255f6831
    })