<<<<<<< HEAD
local assets =
{
	Asset("ANIM", "anim/jiguang2.zip"),
}

local prefabs =
{
}

local AOE_RANGE = 1
local AOE_LENTH = 8
local AOE_TARGET_TAGS = { "_combat" }
local AOE_TARGET_CANT_TAGS_PVE = { "INLIMBO", "flight", "invisible", "player", "wall", "companion", "playerghost", "DECOR", "FX" }
local AOE_TARGET_CANT_TAGS_PVP = { "INLIMBO", "flight", "invisible", "playerghost", "wall", "DECOR", "FX"}
local MULTIHIT_FRAMES = 3

local function UpdatePosition(inst)
	if not inst.attacker then
		return
	end
	local offset = Vector3(1, 0.5, 0)
	local pos = inst.attacker:GetPosition()
	local facing_angle = inst.attacker.Transform:GetRotation() * DEGREES
	local new_x = offset.x * math.cos(facing_angle)
	local new_z = offset.x * math.sin(facing_angle)
	inst.Transform:SetPosition(pos.x + new_x, pos.y + offset.y, pos.z - new_z)
    inst.Transform:SetRotation(inst.attacker.Transform:GetRotation())
end

local function OnUpdateHitbox(inst)
	if not (inst.attacker and inst.attacker.components.combat and inst.attacker:IsValid()) then
		return
	end

	local cant_tags = (TheNet:GetPVPEnabled() and AOE_TARGET_CANT_TAGS_PVP) or  AOE_TARGET_CANT_TAGS_PVE
	local startingpos = inst:GetPosition()
	local targetpos = inst:GetPosition()
	local offset = Vector3(5, 0, 0)
	local facing_angle = inst.attacker.Transform:GetRotation() * DEGREES
	local new_x = offset.x * math.cos(facing_angle)
	local new_z = offset.x * math.sin(facing_angle)
	targetpos.x = targetpos.x + new_x
	targetpos.z = targetpos.z - new_z
	
	local skip = {}
	local direction = targetpos - startingpos

	for i = 0, AOE_LENTH, AOE_RANGE do
		local step_position = startingpos + direction:GetNormalized() * (i * AOE_RANGE)
		local ents = TheSim:FindEntities(step_position.x, 0, step_position.z, AOE_RANGE, AOE_TARGET_TAGS, cant_tags)
		for _, v in ipairs(ents) do    
			if v ~= inst.attacker and v:IsValid() and not v:IsInLimbo() and v.components.combat and not (v.components.health and v.components.health:IsDead()) 
				and v.AnimState ~= nil then
				if not skip[v] then        
					local range = AOE_RANGE + v:GetPhysicsRadius(0)
					skip[v] = true
					if v:GetDistanceSqToPoint(step_position.x, 0, step_position.z) < range * range then
						inst.attacker.components.combat:DoAttack(v, inst)
						SpawnPrefab("alterguardian_laserhit"):SetTarget(v)
					end
				end
			end
		end
	end
end

local function SpawnBreathFX(inst, dist)
	inst.SoundEmitter:PlaySound("alicesound/alicesound/electric3", "loop")
end

local function SetFlamethrowerAttacker(inst, attacker)
	inst.attacker = attacker
end

local function InitDamage(inst, damage)
	inst.components.weapon:SetDamage(damage)
end

local function KillFX(inst)
	inst.SoundEmitter:KillSound("loop")

	inst:DoTaskInTime(0, inst.Remove)
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst.AnimState:SetBank("jiguang2")
	inst.AnimState:SetBuild("jiguang2")
	inst.AnimState:PlayAnimation("jiguang", true)
	inst.AnimState:SetScale(2, 2)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	
	inst:AddTag("FX")
	inst:AddTag("NOCLICK")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	local delay = 10 * FRAMES
	inst:DoTaskInTime(delay, SpawnBreathFX, 0 * FRAMES, 3)

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(10)

	inst.SetFlamethrowerAttacker = SetFlamethrowerAttacker
	inst.KillFX = KillFX
	inst.InitDamage = InitDamage
	inst.UpdatePosition = UpdatePosition

	inst.lasertask = inst:DoPeriodicTask(0.1, OnUpdateHitbox)
	inst:DoPeriodicTask(0.01, inst.UpdatePosition)

	inst.persists = false

	return inst
end

return Prefab("laserthrower_fx", fn, assets, prefabs)
=======
local assets =
{
	Asset("ANIM", "anim/jiguang2.zip"),
}

local prefabs =
{
}

local AOE_RANGE = 1
local AOE_LENTH = 8
local AOE_TARGET_TAGS = { "_combat" }
local AOE_TARGET_CANT_TAGS_PVE = { "INLIMBO", "flight", "invisible", "player", "wall", "companion", "playerghost", "DECOR", "FX" }
local AOE_TARGET_CANT_TAGS_PVP = { "INLIMBO", "flight", "invisible", "playerghost", "wall", "DECOR", "FX"}
local MULTIHIT_FRAMES = 3

local function UpdatePosition(inst)
	if not inst.attacker then
		return
	end
	local offset = Vector3(1, 0.5, 0)
	local pos = inst.attacker:GetPosition()
	local facing_angle = inst.attacker.Transform:GetRotation() * DEGREES
	local new_x = offset.x * math.cos(facing_angle)
	local new_z = offset.x * math.sin(facing_angle)
	inst.Transform:SetPosition(pos.x + new_x, pos.y + offset.y, pos.z - new_z)
    inst.Transform:SetRotation(inst.attacker.Transform:GetRotation())
end

local function OnUpdateHitbox(inst)
	if not (inst.attacker and inst.attacker.components.combat and inst.attacker:IsValid()) then
		return
	end

	local cant_tags = (TheNet:GetPVPEnabled() and AOE_TARGET_CANT_TAGS_PVP) or  AOE_TARGET_CANT_TAGS_PVE
	local startingpos = inst:GetPosition()
	local targetpos = inst:GetPosition()
	local offset = Vector3(5, 0, 0)
	local facing_angle = inst.attacker.Transform:GetRotation() * DEGREES
	local new_x = offset.x * math.cos(facing_angle)
	local new_z = offset.x * math.sin(facing_angle)
	targetpos.x = targetpos.x + new_x
	targetpos.z = targetpos.z - new_z
	
	local skip = {}
	local direction = targetpos - startingpos

	for i = 0, AOE_LENTH, AOE_RANGE do
		local step_position = startingpos + direction:GetNormalized() * (i * AOE_RANGE)
		local ents = TheSim:FindEntities(step_position.x, 0, step_position.z, AOE_RANGE, AOE_TARGET_TAGS, cant_tags)
		for _, v in ipairs(ents) do    
			if v ~= inst.attacker and v:IsValid() and not v:IsInLimbo() and v.components.combat and not (v.components.health and v.components.health:IsDead()) 
				and v.AnimState ~= nil then
				if not skip[v] then        
					local range = AOE_RANGE + v:GetPhysicsRadius(0)
					skip[v] = true
					if v:GetDistanceSqToPoint(step_position.x, 0, step_position.z) < range * range then
						inst.attacker.components.combat:DoAttack(v, inst)
						SpawnPrefab("alterguardian_laserhit"):SetTarget(v)
					end
				end
			end
		end
	end
end

local function SpawnBreathFX(inst, dist)
	inst.SoundEmitter:PlaySound("alicesound/alicesound/electric3", "loop")
end

local function SetFlamethrowerAttacker(inst, attacker)
	inst.attacker = attacker
end

local function InitDamage(inst, damage)
	inst.components.weapon:SetDamage(damage)
end

local function KillFX(inst)
	inst.SoundEmitter:KillSound("loop")

	inst:DoTaskInTime(0, inst.Remove)
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst.AnimState:SetBank("jiguang2")
	inst.AnimState:SetBuild("jiguang2")
	inst.AnimState:PlayAnimation("jiguang", true)
	inst.AnimState:SetScale(2, 2)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	
	inst:AddTag("FX")
	inst:AddTag("NOCLICK")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	local delay = 10 * FRAMES
	inst:DoTaskInTime(delay, SpawnBreathFX, 0 * FRAMES, 3)

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(10)

	inst.SetFlamethrowerAttacker = SetFlamethrowerAttacker
	inst.KillFX = KillFX
	inst.InitDamage = InitDamage
	inst.UpdatePosition = UpdatePosition

	inst.lasertask = inst:DoPeriodicTask(0.1, OnUpdateHitbox)
	inst:DoPeriodicTask(0.01, inst.UpdatePosition)

	inst.persists = false

	return inst
end

return Prefab("laserthrower_fx", fn, assets, prefabs)
>>>>>>> 23121469d84d981b602c8a05fcc5a165255f6831
