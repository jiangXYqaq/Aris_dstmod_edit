GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})

-- BOSS掉落人物专属蓝图
local function AddRandomDrop(inst, prefab, chance)
    if inst.components.lootdropper ~= nil then
        inst.components.lootdropper:AddChanceLoot(prefab, chance)
    end
end

AddPrefabPostInit("beequeen", function(inst)
    if not TheWorld.ismastersim then
        return
    end
    AddRandomDrop(inst, "thorn_shield_blueprint", 1)
    AddRandomDrop(inst, "giftwrap_blueprint", 1)
end)
--新增犀牛掉落蓝图，猴子女王还是可以掉落。
AddPrefabPostInit("minotaur", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    -- 保留原有掉落逻辑
    local old_lootsetup = inst.components.lootdropper and inst.components.lootdropper.lootsetupfn
    
    -- 重写掉落函数
    inst.components.lootdropper:SetLootSetupFn(function(lootdropper)
        -- 执行原始掉落逻辑
        if old_lootsetup then
            old_lootsetup(lootdropper)
        end
        
        -- 添加新模式蓝图（100%掉落）
        lootdropper:AddChanceLoot("alice_mode2_blueprint", 1) -- 1=100%概率
    end)
end)

AddPrefabPostInit("stalker_atrium", function(inst)
    if not TheWorld.ismastersim then
        return
    end
    local oldfn = inst.components.lootdropper.lootsetupfn
    inst.components.lootdropper:SetLootSetupFn(function(lootdropper)
        if oldfn then
            oldfn(lootdropper)
        end
        if not lootdropper.inst.atriumdecay then
            lootdropper:AddChanceLoot("shadow_shield_blueprint", 1)
        end
    end)
end)

AddPrefabPostInit("dragonfly", function(inst)
    if not TheWorld.ismastersim then
        return
    end
    AddRandomDrop(inst, "alice_remote_blueprint", 1)
end)