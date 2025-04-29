local assets=
{ 
	Asset("ANIM", "anim/alice_lightsword.zip"), 
	Asset("ANIM", "anim/swap_backpack_light.zip"), 
    Asset("ATLAS", "images/inventoryimages/alice_lightsword.xml"),
}

local prefabs =  {}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("wepon", "alice_action", "wepon")
    owner.AnimState:OverrideSymbol("swap_object", "alice_action", "wepon")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    if inst.components.container ~= nil then
        inst.components.container:Open(owner)
    end

    if owner:HasTag("player") then
        owner.AnimState:ClearOverrideSymbol("swap_body_tall")
    end
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    
    if inst.components.container ~= nil then
        inst.components.container:Close()
    end

    if owner:HasTag("player") then
        owner.AnimState:OverrideSymbol("swap_body_tall", "swap_backpack_light", "swap_body")
    end

    inst:RemoveTag("fireatk")
end

local function OnAttack(inst, attacker, target, skipsanity)
	if not target:IsValid() then
		return
	end

	if target.components.sleeper ~= nil and target.components.sleeper:IsAsleep() then
		target.components.sleeper:WakeUp()
	end

	if target.components.combat ~= nil then
		target.components.combat:SuggestTarget(attacker)
	end

	target:PushEvent("attacked", { attacker = attacker, damage = 0, weapon = inst })
end

--装备模块
local function OnAmmoLoaded(inst, data)

end

--卸下模块
local function OnAmmoUnloaded(inst, data)
    --inst.components.alice_sword:ChangeMode(0)
end

--携带数量限制
local function topocket(inst, owner) 
    if not owner then return end
    inst.owner = owner
    if owner:HasTag("player") then
        owner.AnimState:OverrideSymbol("swap_body_tall", "swap_backpack_light", "swap_body")
    end
    if owner.components.inventory then
        local inventory = owner.components.inventory
        local talker = owner.components.talker
        for k, item in pairs(inventory.itemslots) do -- 检查物品栏中是否已经有相同的武器
            if item ~= inst and item.prefab == inst.prefab then
                inventory:DropItem(item, true, true)
                if talker then
                    talker:Say(STRINGS.TOOMANYLIGHTSWORD)
                end
                break
            end
        end

        local equipped_item = inventory:GetEquippedItem(EQUIPSLOTS.HANDS) -- 检查手部装备栏中是否有武器
        if equipped_item and equipped_item.prefab == inst.prefab then
            owner:DoTaskInTime(0, function()
                inventory:DropItem(equipped_item, true, true)
                inventory:Equip(inst)
            end)
        end
    end
end

--圆圈准星
local function reticule_target_function(inst)
	local player = ThePlayer
	local ground = TheWorld.Map
	local pos = Vector3()
	for r = 7, 0, -.25 do
		pos.x, pos.y, pos.z = player.entity:LocalToWorldSpace(r, 0, 0)
		if ground:IsPassableAtPoint(pos.x, 0, pos.z, true) and not ground:IsGroundTargetBlocked(pos) then
			return pos
		end
	end
	return pos
end

local function CircleReticuleMouseTargetFn(inst, mousepos)
    if mousepos ~= nil then
        local x, y, z = inst.Transform:GetWorldPosition()
        local dx = mousepos.x - x
        local dz = mousepos.z - z
        local distance = math.sqrt(dx * dx + dz * dz)
        local max_range = 16

        if distance > max_range then
            dx = dx / distance * max_range
            dz = dz / distance * max_range
        end

        return Vector3(x + dx, 0, z + dz)
    end
    return Vector3(x, y, z)
end

local function reticule_update_position_function(inst, pos, reticule, ease, smoothing, dt)
    reticule.Transform:SetPosition(pos:Get())
    reticule.Transform:SetRotation(inst:GetAngleToPoint(pos))

    local inst_x, inst_y, inst_z = inst.Transform:GetWorldPosition()
    local pos_x, pos_y, pos_z = pos.x, pos.y, pos.z
    local dx = pos_x - inst_x
    local dz = pos_z - inst_z
    local distance = math.sqrt(dx * dx + dz * dz)
    local size = distance / 8
	reticule.AnimState:SetScale(size, size)
end

--直线准星
local function ReticuleTargetFn()
    return Vector3(ThePlayer.entity:LocalToWorldSpace(6.5, 0, 0))
end

local function ReticuleMouseTargetFn(inst, mousepos)
    if mousepos ~= nil then
        local x, y, z = inst.Transform:GetWorldPosition()
        local dx = mousepos.x - x
        local dz = mousepos.z - z
        local l = dx * dx + dz * dz
        if l <= 0 then
            return inst.components.reticule.targetpos
        end
        l = 6.5 / math.sqrt(l)
        return Vector3(x + dx * l, 0, z + dz * l)
    end
end

local function ReticuleUpdatePositionFn(inst, pos, reticule, ease, smoothing, dt)
    local x, y, z = inst.Transform:GetWorldPosition()
    reticule.Transform:SetPosition(x, 0, z)
    local rot = -math.atan2(pos.z - z, pos.x - x) / DEGREES
    if ease and dt ~= nil then
        local rot0 = reticule.Transform:GetRotation()
        local drot = rot - rot0
        rot = Lerp((drot > 180 and rot0 + 360) or (drot < -180 and rot0 - 360) or rot0, rot, dt * smoothing)
    end
    reticule.Transform:SetRotation(rot)
end


local function on_dropped(inst)
    if inst.owner then
        inst.owner.AnimState:ClearOverrideSymbol("swap_body_tall")
    end
end

local function Shot(inst, doer, pos)
end

local function alc_change_zhixian(inst)
    inst.components.aoetargeting.reticule.reticuleprefab = "reticulelong"
    inst.components.aoetargeting.reticule.targetfn = ReticuleTargetFn
    inst.components.aoetargeting.reticule.mousetargetfn = ReticuleMouseTargetFn
    inst.components.aoetargeting.reticule.updatepositionfn = ReticuleUpdatePositionFn
    inst.components.aoetargeting.reticule.ispassableatallpoints = false
end

local function alc_change_circle(inst)
    inst.components.aoetargeting.reticule.reticuleprefab = "cannon_reticule_fx"
    inst.components.aoetargeting.reticule.ispassableatallpoints = true
    inst.components.aoetargeting.reticule.targetfn = reticule_target_function
    inst.components.aoetargeting.reticule.mousetargetfn = CircleReticuleMouseTargetFn
    inst.components.aoetargeting.reticule.updatepositionfn = reticule_update_position_function
end
---------------------------------

local function Changefn(inst, mode, notalk)
    mode = mode or inst.components.alice_sword:GetCurrentMode() or 1
    local owner = inst.components.inventoryitem.owner
    if owner then
        SendModRPCToClient(CLIENT_MOD_RPC["alice"]["updataaoereticule"], owner.userid, mode)
        if owner.components.talker and not notalk then
            local talkstring = inst.components.alice_sword:GetModeString()
            owner.components.talker:Say(STRINGS.ACTIONS.LIGHTSWORD.MODE_CHANGE .. talkstring)
        end
    end
    inst.components.weapon:SetProjectile("alice_shot" .. mode)
end

local function equippedFn(inst)
    inst:DoTaskInTime(0, Changefn, nil, true)
end

local function OnCharged(inst)
    inst:RemoveTag("charging")
end

local function OnDischarged(inst)
    inst:AddTag("charging")
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
	inst.entity:AddSoundEmitter()

    MakeInventoryPhysics(inst)
    
    inst.AnimState:SetBank("alice_lightsword")
    inst.AnimState:SetBuild("alice_lightsword")
    inst.AnimState:PlayAnimation("dimian")

	inst:AddTag("weapon")
	inst:AddTag("lightsword")
    inst:AddTag('trader')
    inst:AddTag("rechargeable")

    inst:AddComponent("aoetargeting")
    inst.components.aoetargeting.shouldrepeatcastfn = function() return true end
    inst.components.aoetargeting.reticule.validcolour = { 1, .75, 0, 1 } --有效范围颜色
    inst.components.aoetargeting.reticule.invalidcolour = { .5, 0, 0, 1 } --无效范围颜色
    inst.components.aoetargeting.reticule.ease = true
    inst.components.aoetargeting.reticule.mouseenabled = true
    inst.components.aoetargeting:SetAlwaysValid(true)
    
    inst:AddComponent("alice_traderhelper")
    inst.components.alice_traderhelper.str = function(inst, item, giver)
        return "TRADE_LIGHTSWORD"
    end
    
    inst.alc_change_zhixian = alc_change_zhixian
    inst.alc_change_circle = alc_change_circle
    
    if not TheWorld.ismastersim then
        return inst
    end
	
    inst:AddComponent("inspectable")

    inst:AddComponent("aoespell")
    inst.components.aoespell:SetSpellFn(Shot)

    inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(0)
	inst.components.weapon:SetRange(8, 10)
	inst.components.weapon:SetOnAttack(OnAttack)
    
    inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/alice_lightsword.xml"
    inst.components.inventoryitem.canonlygoinpocket = true
    inst:ListenForEvent("onputininventory", topocket)
    inst:ListenForEvent("ondropped", on_dropped)
    
    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip( onequip )
    inst.components.equippable:SetOnUnequip( onunequip )
    inst.components.equippable.walkspeedmult = TUNING.ALICE_LIGHTSWORD_SPEED_MULT

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("alice_lightsword")
	inst.components.container.canbeopened = true
    inst.components.container.stay_open_on_hide = true
    inst:ListenForEvent("itemget", OnAmmoLoaded)
    inst:ListenForEvent("itemlose", OnAmmoUnloaded)

    inst:AddComponent("alice_sword")
    inst.components.alice_sword:SetChangeFn(Changefn)

    inst:AddComponent("rechargeable")
    inst.components.rechargeable:SetOnDischargedFn(OnDischarged)
    inst.components.rechargeable:SetOnChargedFn(OnCharged)

    inst:ListenForEvent("equipped", equippedFn)
    equippedFn(inst)

    MakeHauntableLaunch(inst)

    return inst
end

return  Prefab("alice_lightsword", fn, assets, prefabs)
