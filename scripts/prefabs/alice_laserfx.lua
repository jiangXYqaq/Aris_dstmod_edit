local assets =
{
	Asset("ANIM", "anim/jiguang2.zip"),
}

local prefabs =
{
}

--------------------------------------------------------------------------

local AOE_RANGE = 1
local AOE_LENTH = 8
local AOE_TARGET_TAGS = { "_combat" }
local AOE_TARGET_CANT_TAGS_PVE = { "INLIMBO", "flight", "invisible", "player", "wall", "companion" }
local AOE_TARGET_CANT_TAGS_PVP = { "INLIMBO", "flight", "invisible", "playerghost", "wall" }
local MULTIHIT_FRAMES = 3

local function UpdatePosition(inst)
	local offset = Vector3(1, 0.5, 0)
	local pos = inst.attacker:GetPosition()
	local facing_angle = inst.attacker.Transform:GetRotation() * DEGREES
	local new_x = offset.x * math.cos(facing_angle)
	local new_z = offset.x * math.sin(facing_angle)
	inst.Transform:SetPosition(pos.x + new_x, pos.y + offset.y, pos.z - new_z)
end

local function OnUpdateHitbox(inst)
	if not (inst.attacker and inst.attacker.components.combat and inst.attacker:IsValid()) then
		return
	end

	local weapon = inst.owner

	local cant_tags = (TheNet:GetPVPEnabled() and AOE_TARGET_CANT_TAGS_PVP) or  AOE_TARGET_CANT_TAGS_PVE

	inst.attacker.components.combat.ignorehitrange = true
	inst.attacker.components.combat.ignoredamagereflect = true

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
			if v ~= inst.attacker and v:IsValid() and not v:IsInLimbo() and not (v.components.health and v.components.health:IsDead()) then
				if not skip[v] then        
					local range = AOE_RANGE + v:GetPhysicsRadius(0)
					skip[v] = true
					if v:GetDistanceSqToPoint(step_position.x, 0, step_position.z) < range * range then
						inst.attacker.components.combat:DoAttack(v, weapon)
						SpawnPrefab("alterguardian_laserhit"):SetTarget(v)
					end
				end
			end
		end
	end

	inst.attacker.components.combat.ignorehitrange = false
	inst.attacker.components.combat.ignoredamagereflect = false
end

local function SetFXOwner(inst, attacker, owner)
	inst.owner = owner
	inst.attacker = attacker
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
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

	inst.lasertask = inst:DoPeriodicTask(0.1, OnUpdateHitbox)
	--inst.lasertask = inst:DoPeriodicTask(0.01, UpdatePosition)
	inst.persists = false
	inst.SetFXOwner = SetFXOwner

	return inst
end

return Prefab("alice_laserfx", fn, assets, prefabs)