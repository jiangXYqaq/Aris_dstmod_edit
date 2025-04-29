local assets =
{
	Asset( "ANIM", "anim/alice.zip" ),
	Asset( "ANIM", "anim/alice_maid.zip" ),
	Asset( "ANIM", "anim/ghost_alice_build.zip" ),
}

local skindata = {
	------------------默认--------------
	CreatePrefabSkin("alice_none",
	{
		base_prefab = "alice",
		type = "base",
		assets = assets,
		skins = {
			normal_skin = "alice",
			ghost_skin = "ghost_alice_build",
		}, 
		rarity = "Character",
		skin_tags = {"ALICE", "CHARACTER", "BASE"},
		build_name_override = "alice",
		rarity = "Character",
	}),
	------------------女仆装--------------
	CreatePrefabSkin("alice_maid",
	{ 
		base_prefab = "alice",
		skins = {
				normal_skin = "alice_maid",
				ghost_skin = "ghost_alice_build",
		}, 								
		assets = assets,
		skin_tags = {"ALICE", "CHARACTER", "MAID"},
		build_name_override = "alice_maid",
		rarity = "Character",
	}),
	------------------Kei--------------
	CreatePrefabSkin("alice_red",
	{ 
		base_prefab = "alice",
		skins = {
				normal_skin = "alice_red",
				ghost_skin = "ghost_alice_build",
		}, 								
		assets = assets,
		skin_tags = {"ALICE", "CHARACTER", "RED"},
		build_name_override = "alice_red",
		rarity = "Character",
	}),
	------------------Kei女仆--------------
	CreatePrefabSkin("alice_maid_red",
	{ 
		base_prefab = "alice",
		skins = {
				normal_skin = "alice_maid_red",
				ghost_skin = "ghost_alice_build",
		}, 								
		assets = assets,
		skin_tags = {"ALICE", "CHARACTER", "RED", "MAID"},
		build_name_override = "alice_maid_red",
		rarity = "Character",
	}),
}

return unpack(skindata)