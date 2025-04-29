GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})

Assets = {
    -- 人物资源
    Asset( "ATLAS", "images/saveslot_portraits/alice.xml" ),

    Asset( "ATLAS", "bigportraits/alice.xml" ),

	Asset( "ATLAS", "images/map_icons/alice.xml" ),

    Asset( "ATLAS", "images/avatars/avatar_alice.xml" ),

    Asset( "ATLAS", "images/avatars/self_inspect_alice.xml" ),

    Asset( "ATLAS", "images/avatars/avatar_ghost_alice.xml" ),

    Asset( "ATLAS", "images/names_alice.xml" ),

    Asset( "ATLAS", "images/remote/zhaoming.xml" ),
    
    Asset( "ATLAS", "images/remote/chaofeng.xml" ),

    Asset( "ATLAS", "images/remote/yinyue.xml" ),

	Asset ("ANIM", "anim/alice.zip"),

    Asset( "ANIM", "anim/alice_action.zip"),
    
    Asset( "ANIM", "anim/alice_shot_fx.zip"),

    Asset( "ANIM", "anim/alice_remote.zip"),
    Asset( "ANIM", "anim/swap_remote.zip"),
    Asset( "ANIM", "anim/action_remote.zip"),

    -- 音频
    Asset("SOUNDPACKAGE", "sound/alicesound.fev"),
	Asset("SOUND", "sound/alicesound.fsb"),
    Asset("SOUNDPACKAGE", "sound/alicemusic.fev"),
	Asset("SOUND", "sound/alicemusic.fsb"),

    -- UI
    Asset("ATLAS", "images/ui/back.xml" ),
    Asset("ATLAS", "images/ui/back_en.xml" ),
    Asset("ATLAS", "images/ui/select.xml" ),
    Asset("ATLAS", "images/ui/skillback.xml" ),
    Asset("ATLAS", "images/ui/skillup.xml" ),
    
    Asset("ATLAS", "images/ui/icon1.xml" ),
    Asset("ATLAS", "images/ui/icon2.xml" ),
    Asset("ATLAS", "images/ui/icon3.xml" ),
    Asset("ATLAS", "images/ui/icon4.xml" ),
    
    Asset("ATLAS", "images/ui/bg.xml" ),
    Asset("ATLAS", "images/ui/Background01.xml" ),

    Asset("IMAGE", "images/ui/alice_buff.tex"),
    Asset("ATLAS", "images/ui/alice_buff.xml" ),
    
    Asset("ATLAS", "images/ui/shang.xml" ),
    Asset("ATLAS", "images/ui/xia.xml" ),
    Asset("ATLAS", "images/ui/bofang.xml" ),
    Asset("ATLAS", "images/ui/stop.xml" ),

    Asset("ATLAS", "images/ui/levelup.xml" ),

    -- 电路
    Asset( "ANIM", "anim/status_alice.zip"),
    Asset( "ANIM", "anim/alice_moudle.zip"),
    
    Asset("ATLAS", "images/inventoryimages/alice_moudle.xml"),
    Asset("IMAGE", "images/inventoryimages/alice_moudle.tex"),

}

-- 小地图图标
AddMinimapAtlas("images/map_icons/alice.xml")

-- 客机组件
AddReplicableComponent("alice_sword")

modimport("scripts/components/alice_critical.lua")

-- new为启迪之冠添加墨镜暴击率和暴击伤害
local function AlterGuardianHatPostInit(inst)
    -- 仅在服务端操作（重要！）
    if not TheWorld.ismastersim then
        return
    end

    -- 安全检查：避免重复添加
    if inst.components.alice_critical == nil then
        inst:AddComponent("alice_critical")
        inst.components.alice_critical:Setchance(TUNING.ALICE_GLASSES_CHANCE)
        inst.components.alice_critical:Setvalue(TUNING.ALICE_GLASSES_VALUE)
    end
end

AddPrefabPostInit("alterguardianhat", AlterGuardianHatPostInit)

PrefabFiles = {
	"alice",
	"alice_none",
	"alice_lightsword",
	"lightsword_projectile",
	"alice_ring",
	"alice_broom",
	"alice_mode",
	"alice_fx",
	"alice_remote",
	"alice_battery",
	"alice_shield",
	"alice_coat",
	"alice_buff",
	"alice_blueprint",
	"laserthrower_fx",
	"alice_robot",
	"alice_chester",
	"alice_glasses",
}
						
local skin_modes = {
    { 
        type = "ghost_skin",
        anim_bank = "ghost",
        idle_anim = "idle", 
        scale = 0.75, 
        offset = { 0, -25 } 
    },
}

AddModCharacter("alice", "FEMALE", skin_modes)

local language = GetModConfigData("ALC_LANGUAGE")
if language == "en" then
    modimport("main/string_en.lua")
    TUNING.ALC_LANGUAGE = "en"
else
    modimport("main/string_zh.lua")
end

modimport("main/tuning.lua")

modimport("main/sg.lua")

modimport("main/rpc.lua")

modimport("main/hook.lua")

modimport("main/postint.lua")

modimport("main/recipe.lua")

modimport("main/action.lua")

modimport("scripts/alice_container.lua")

modimport("main/ui.lua")

modimport("main/module.lua")

modimport("main/loot.lua")

modimport("scripts/alice_utils/skinapi.lua")