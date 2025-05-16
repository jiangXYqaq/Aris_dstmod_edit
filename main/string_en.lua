GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})

---------- 人物相关 ----------
STRINGS.CHARACTER_TITLES.alice = "Tendo Alice"
STRINGS.CHARACTER_NAMES.alice = "Robot"
STRINGS.CHARACTER_DESCRIPTIONS.alice = [[
* A robot
* Can carry heavy objects with ease
* Wields a powerful Lightsword
]]
STRINGS.CHARACTER_QUOTES.alice = "\"Bang Bang Kabang\""
STRINGS.CHARACTER_SURVIVABILITY.alice = "Grim"

STRINGS.CHARACTERS.ALICE = require "speech_alice"

STRINGS.NAMES.ALICE = "Alice"
STRINGS.SKIN_NAMES.alice_none = "Alice"

---------- 专属物品 ----------
STRINGS.NAMES.ALICE_LIGHTSWORD = "Light Sword"
STRINGS.RECIPE_DESC.ALICE_LIGHTSWORD = "Its weight and firepower are extraordinary, even carrying it is a challenge for most students."
STRINGS.CHARACTERS.ALICE.DESCRIBE.ALICE_LIGHTSWORD = "Yes! Alice is ready for the adventure!"
STRINGS.CHARACTERS.WOLFGANG.DESCRIBE.ALICE_LIGHTSWORD = "This sword looks incredibly powerful."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.ALICE_LIGHTSWORD = "This sword looks extremely powerful, but it seems too heavy for me."

STRINGS.NAMES.ALICE_RING = "Alice's Halo"
STRINGS.RECIPE_DESC.ALICE_RING = "An energy source that continuously provides strange powers."
STRINGS.CHARACTERS.ALICE.DESCRIBE.ALICE_RING = "Brave one, may light be with you."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.ALICE_RING = "A mysterious energy seems to flow from it, truly amazing."

STRINGS.NAMES.ALICE_BROOM = "Maid Hero's Broom"
STRINGS.RECIPE_DESC.ALICE_BROOM = "…Where should I start cleaning?"
STRINGS.CHARACTERS.ALICE.DESCRIBE.ALICE_BROOM = "Alice is here to clean up!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.ALICE_BROOM = "This broom seems very practical, maybe it's for more than just cleaning."

STRINGS.NAMES.ALICE_MODE1 = "Rapid Fire Module"
STRINGS.RECIPE_DESC.ALICE_MODE1 = "Increases fire rate, turning you into a rapid-fire machine."
STRINGS.CHARACTERS.ALICE.DESCRIBE.ALICE_MODE1 = "Full power, Alice can be as swift as the wind!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.ALICE_MODE1 = "Equipping this, I should be able to attack enemies faster."

STRINGS.NAMES.ALICE_MODE2 = "Energy Shell Module"
STRINGS.RECIPE_DESC.ALICE_MODE2 = "Charge it up to fire a powerful energy shell."
STRINGS.CHARACTERS.ALICE.DESCRIBE.ALICE_MODE2 = "Energy full, ready for the impact!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.ALICE_MODE2 = "This looks like a powerful burst weapon."

STRINGS.NAMES.ALICE_MODE3 = "Supernova Module"
STRINGS.RECIPE_DESC.ALICE_MODE3 = "Release a power as strong as a star explosion."
STRINGS.CHARACTERS.ALICE.DESCRIBE.ALICE_MODE3 = "With unwavering will, light, arise!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.ALICE_MODE3 = "It sounds like it can unleash a devastating power, I'm excited to see it in action."

STRINGS.NAMES.ALICE_MODE4 = "High-Energy Laser Blade Module"
STRINGS.RECIPE_DESC.ALICE_MODE4 = "Transform the laser into a close-range melee weapon."
STRINGS.CHARACTERS.ALICE.DESCRIBE.ALICE_MODE4 = "This laser blade will clear all obstacles for Alice!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.ALICE_MODE4 = "The light is blinding, I better be careful not to get too close."

STRINGS.NAMES.WX78MODULE_ALC_MAGIC = "Magic Enhancement"
STRINGS.RECIPE_DESC.WX78MODULE_ALC_MAGIC = "Grants even stronger magical powers."
STRINGS.CHARACTERS.ALICE.DESCRIBE.WX78MODULE_ALC_MAGIC = "Alice will illuminate the path ahead with the radiance of magic!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.WX78MODULE_ALC_MAGIC = "This makes me feel closer to the power of a wizard."

STRINGS.NAMES.WX78MODULE_ALC_BATTLE = "Light Warrior"
STRINGS.RECIPE_DESC.WX78MODULE_ALC_BATTLE = "Analyzes the battle situation and enhances combat abilities."
STRINGS.CHARACTERS.ALICE.DESCRIBE.WX78MODULE_ALC_BATTLE = "Battle analysis complete, victory is within grasp!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.WX78MODULE_ALC_BATTLE = "This module will likely make me more agile in battle."

STRINGS.NAMES.WX78MODULE_ALC_CHARGE = "Charging Circuit"
STRINGS.RECIPE_DESC.WX78MODULE_ALC_CHARGE = "Provides continuous power, keeping you energized."
STRINGS.CHARACTERS.ALICE.DESCRIBE.WX78MODULE_ALC_CHARGE = "Full of energy, always ready for battle!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.WX78MODULE_ALC_CHARGE = "I feel completely energized!"

STRINGS.NAMES.ALICE_REMOTE = "Alice's Remote"
STRINGS.RECIPE_DESC.ALICE_REMOTE = "A portable device to control the entire situation."
STRINGS.CHARACTERS.ALICE.DESCRIBE.ALICE_REMOTE = "Remote activated, adventure starts now!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.ALICE_REMOTE = "This is a control device, but I’m not sure how to use it."

STRINGS.NAMES.ALICE_BATTERY = "Battery"
STRINGS.RECIPE_DESC.ALICE_BATTERY = "An essential item for storing energy."
STRINGS.CHARACTERS.ALICE.DESCRIBE.ALICE_BATTERY = "Alice's power source, this is what keeps me going!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.ALICE_BATTERY = "A simple but very practical item."

STRINGS.NAMES.WOODEN_SHIELD = "Wooden Shield"
STRINGS.RECIPE_DESC.WOODEN_SHIELD = "Basic protective gear, lightweight and easy to use."
STRINGS.CHARACTERS.ALICE.DESCRIBE.WOODEN_SHIELD = "Simple but reliable, Alice is ready!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.WOODEN_SHIELD = "This should provide basic protection."

STRINGS.NAMES.METAL_SHIELD = "Metal Shield"
STRINGS.RECIPE_DESC.METAL_SHIELD = "Provides moderate protection."
STRINGS.CHARACTERS.ALICE.DESCRIBE.METAL_SHIELD = "The weight of metal makes me feel more confident!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.METAL_SHIELD = "Looks much sturdier than the wooden one."

STRINGS.NAMES.DREAD_SHIELD = "Composite Shield"
STRINGS.RECIPE_DESC.DREAD_SHIELD = "A deep, unsettling darkness that gives a sense of unease."
STRINGS.CHARACTERS.ALICE.DESCRIBE.DREAD_SHIELD = "Even in despair, nothing can stop Alice."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.DREAD_SHIELD = "This shield gives off a chilling aura, but it must be incredibly sturdy."

STRINGS.NAMES.COMPOSITE_SHIELD = "Dimensional Material Shield"
STRINGS.RECIPE_DESC.COMPOSITE_SHIELD = "A powerful protective shield made from a fusion of materials."
STRINGS.CHARACTERS.ALICE.DESCRIBE.COMPOSITE_SHIELD = "Multi-layered protection, offering Alice greater peace of mind!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.COMPOSITE_SHIELD = "The design is ingenious, it looks very reliable."

STRINGS.NAMES.THORN_SHIELD = "Thorn Shield"
STRINGS.RECIPE_DESC.THORN_SHIELD = "A defensive shield that strikes back when attacked."
STRINGS.CHARACTERS.ALICE.DESCRIBE.THORN_SHIELD = "Attacking Alice? Get ready to feel the sting of retaliation!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.THORN_SHIELD = "Anyone who attacks me will regret it, this shield fights back."

STRINGS.NAMES.SHADOW_SHIELD = "Shadow Shield"
STRINGS.RECIPE_DESC.SHADOW_SHIELD = "A mysterious defense from the shadows, filled with unknown power."
STRINGS.CHARACTERS.ALICE.DESCRIBE.SHADOW_SHIELD = "Even in darkness, there is hope—this is its meaning."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.SHADOW_SHIELD = "This shield seems to protect me quietly."

STRINGS.NAMES.ALICE_BATTLECOAT = "Assault Coat"
STRINGS.RECIPE_DESC.ALICE_BATTLECOAT = "A practical coat that is both warm and suited for battle."
STRINGS.CHARACTERS.ALICE.DESCRIBE.ALICE_BATTLECOAT = "Alice feels incredibly comfortable wearing this!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.ALICE_BATTLECOAT = "This coat is perfect for an adventure."

STRINGS.NAMES.ALICE_MAIDCOAT = "Maid Hero Coat"
STRINGS.RECIPE_DESC.ALICE_MAIDCOAT = "A unique coat that combines maid style with the spirit of a hero."
STRINGS.CHARACTERS.ALICE.DESCRIBE.ALICE_MAIDCOAT = "Heh, Alice can be a battle maid too!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.ALICE_MAIDCOAT = "This coat blends elegance with combat prowess."

STRINGS.NAMES.ALICE_GLASSES = "Sunglasses"
STRINGS.RECIPE_DESC.ALICE_GLASSES = "Wear them, and you’ll be the coolest warrior!"
STRINGS.CHARACTERS.ALICE.DESCRIBE.ALICE_GLASSES = "These sunglasses aren’t just cool—they boost Alice’s combat power!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.ALICE_GLASSES = "These sunglasses aren’t just cool—they enhance combat power!"

STRINGS.NAMES.ALICE_ROBOT = "Cleaning Robot"
STRINGS.RECIPE_DESC.ALICE_ROBOT = "A cute little assistant."
STRINGS.CHARACTERS.ALICE.DESCRIBE.ALICE_ROBOT = "This is Alice’s little helper."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.ALICE_ROBOT = "It looks a bit like Alice, full of futuristic technology."

STRINGS.ALICE_REMOTE = {
    LIGHT = "Lighting",
    MUSIC = "Play Music",
    TAUNT = "Holographic Taunt",
}

---------- 机器人专属台词 ----------
STRINGS.CHARACTERS.ALICE.ACTIONFAIL = {
    COOLDOWN = "You'll have to wait a bit longer, the system is still adjusting.",  -- Module cooling down, unable to apply a new one

    APPLYMODULE = {
        NOTENOUGHSLOTS = "Hmm, looks like there's no more space for new modules.", -- Not enough module slots available
    },
    CHARGE_FROM = {
        CHARGE_FULL = "Charging is already full, no need for more.",  -- Charging failed due to full battery
        NOT_ENOUGH_CHARGE = "Just a little short... Alice isn't mad, just a little disappointed."  -- Charging failed, insufficient power
    },

    REMOVEMODULES = {
        NO_MODULES = "Huh? Seems like there's nothing to remove.", -- Attempting to remove modules when none are installed
    },
}

STRINGS.CHARACTERS.ALICE.ANNOUNCE_CHARGE = "Feeling much better now, fully restored!"  -- System fully charged, returning to normal
STRINGS.CHARACTERS.ALICE.ANNOUNCE_DISCHARGE = "Everything is running smoothly, no problems at all."  -- System discharged normally
STRINGS.CHARACTERS.ALICE.ANNOUNCE_NOSLEEPHASPERMANENTLIGHT = "Ah, it's too bright... I can't sleep with this light on."  -- Lighting system prevents the character from sleeping
STRINGS.CHARACTERS.ALICE.ANNOUNCE_WX_SCANNER_FOUND_NO_DATA = "Looks like there's nothing particularly noteworthy here."  -- Scanner detects no new data nearby
STRINGS.CHARACTERS.ALICE.ANNOUNCE_WX_SCANNER_NEW_FOUND = "Alice found something interesting!"  -- New scannable creature detected
---------- 碧蓝档案角色 --------------
STRINGS.CHARACTERS.ALICE.DESCRIBE.YUZU = "Yuzu-senpai! What new game are you working on today?"

STRINGS.CHARACTERS.ALICE.DESCRIBE.HINA = "Chairwoman Hina! Thanks for your hard work with today's disciplinary check."

---------- 其他台词 ----------
STRINGS.ACTIONS.GIVE.TRADE_LIGHTSWORD = "Upgrade"
STRINGS.ACTIONS.ALICE_LEVELUP = "Level Up"
STRINGS.ACTIONS.ALICE_REMOTE_LEARN = "Learn"
STRINGS.ACTIONS.USESPELLBOOK.ALICEREMOTE = "Use"
STRINGS.ACTIONS.CLOSESPELLBOOK.ALICEREMOTE = "Stop"
STRINGS.ACTIONS.CASTAOE.ALICE_LIGHTSWORD = "Launch"
--STRINGS.ACTIONS.ALICE_PICKUP = "Sweep Pickup" not used

STRINGS.ACTIONS.ALICE_TACKLE = 
{
    REMOVE = "Unequip",
    GENERIC = "Equip",
}

STRINGS.TOOMANYLIGHTSWORD = "Alice can't carry more lightswords."

STRINGS.ACTIONS.LIGHTSWORD = {
    NO_MODE_TOCHANGE = "No modules available to switch",
    NO_MODE = "Battery not equipped",
    NOFINITINESS = "Battery durability is too low",
    MODE_CHANGE = "Lightsword mode changed to",
    NO_ENABLE = "Lightsword has no battery equipped",
    CHARGECD = "Supernova is cooling down",
    NO_LIGHTSWORD = "No lightsword found, cannot open info panel",
    UI_TITLE = "Lightsword Information Panel",
    NEED_MODE = "Modules required to upgrade",
    MAX_LEVEL = "Already at maximum level",
}

STRINGS.LIGHTSWORD_MODE = {
    "Rapid Fire Mode",
    "Energy Shell",
    "EX Skill",
    "High-Energy Laser Blade",
}

STRINGS.ALICEUI = {
    VOICE = "Volume",

    WEAPON = {
        ATK = "Base Attack Power",
        SPEED = "Handling Speed",
        BATTERY = "Battery Charge",
        KEY = "Hotkey",
        TEX1 = "Base\nAbilities",
        TEX2 = "Skill\nGrowth",
        TEX3 = "Weapon\nGrowth",
        STRING1 = "Deals attack power to 1 enemy",
        STRING2 = "Deals attack power to enemies during flight",
        STRING3 = "Deals attack power upon landing",
        STRING4 = "Deals attack power to all enemies in a straight line",
        STRING5 = "Deals high-frequency damage to targets hit by the laser",
        STRING6 = "% damage",
        STRING7 = "damage points",
        STRING8 = "% area damage",
    },

    BUFF = {
        DAMAGE = "BUFF Effect: Nearby players gain a 10% attack boost",
        SPEED = "BUFF Effect: Nearby players gain a 25% movement speed boost",
        DEF = "BUFF Effect: Nearby players gain super armor but take 20% more damage",
        WORK = "BUFF Effect: Nearby players' work efficiency increases by 100%",
    },
}

STRINGS.ALICE_MUSICBUFF = {
    DAMAGE = "This melody sparks my fighting spirit, increasing my attack power!",
    SPEED = "With the rhythm of the music, my steps become swifter!",
    DEF = "This melody makes me as firm as a rock, no attack can shake me!",
    WORK = "This music energizes me, boosting my work efficiency!",
}
STRINGS.ACTIONS.ALICE_BROOM_BEEKEEPING_WARNING = "Beekeeping resource protocol detected. Forced harvesting violates Ecological Protection Act 7.3—request terminated."
STRINGS.ACTIONS.ALICE_BROOM_MAPTELE = "Teleport"
STRINGS.ACTIONS.ALICE_BROOM_RESKIN = "Clean"
STRINGS.ACTIONS.ALICE_BROOM_PICKUP = "Pick Up"
STRINGS.ACTIONS.ALICE_BROOM_HARVEST = "Harvest"
STRINGS.ACTIONS.ALICE_BROOM_DEFAULT = "Use Broom" -- Default text