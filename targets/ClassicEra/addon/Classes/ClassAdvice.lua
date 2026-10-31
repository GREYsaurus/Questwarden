-- ClassicGuide - class leveling advice for WoW Classic Era
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- SPDX-License-Identifier: GPL-3.0-only
--
-- Written for this project in our own words from general Classic Era game knowledge (status = "unverified"
-- until play-tested). Every trainer level quoted below was checked against Classes/TrainingData.lua (the
-- client's tables) on 2026-10-31; class-quest levels match Classes/TrainingNotes.lua; talents are named as
-- talents, without a level. trainingLevels: every level at which the Classic trainer data has a new rank
-- (the same even levels 4-60 for all nine classes).

local _, ns = ...

local Advice = {}
ns.ClassAdvice = Advice

Advice.status = "unverified"

local EVEN = {}
for l = 4, 60, 2 do EVEN[#EVEN + 1] = l end

Advice.data = {
    WARRIOR = {
        summary = "The most gear-dependent class and the one with the most downtime. Level as Arms with the best two-handed weapon you can get, and eat between pulls.",
        tips = {
            "Open with Charge, then Rend and Heroic Strike with spare rage. Thunder Clap (6) and Hamstring (8) deal with packs and runners.",
            "Use Overpower (12) every time a target dodges. Tactical Mastery (Arms talent) keeps some rage when you switch stance for it.",
            "Defensive Stance, Taunt and Sunder Armor come from the class quest at 10. Berserker Stance and Intercept come from the quest at 30.",
            "Your weapon matters more than any other item. Take two-handed quest rewards and look at the auction house at 20, 30 and 40.",
            "Learn Whirlwind at 36 for groups of mobs. Mortal Strike (Arms talent, from 40) is the main leveling ability after that.",
            "Keep First Aid trained and bandages in your bags. Spirit helps early, but from about 30 food is faster.",
            "Warriors tank dungeons well from the low 20s, and dungeon weapons speed up solo questing a lot.",
        },
        trainingLevels = EVEN,
    },
    PALADIN = {
        summary = "Very hard to kill and able to heal itself, but slow-killing. Level as Retribution with a slow two-handed weapon: a Seal, its Judgement and your swings do the damage.",
        tips = {
            "Keep a Seal up and Judge it when it is ready, then Seal again. Seal of the Crusader (6) early; Seal of Command (Retribution talent) later.",
            "Blessing of Might, or Blessing of Wisdom (14) if mana runs short, plus Retribution Aura (16) are the usual questing buffs.",
            "Exorcism (20) hits undead and demons hard. Hammer of Justice (8) stops a healer or a mob running for help.",
            "Redemption comes from a class quest at 12. Divine Shield (34) is the escape when a pull goes wrong.",
            "Spirit and Intellect cut downtime: you heal yourself between fights instead of eating.",
            "Protection with Consecration (Holy talent) can tank dungeons in the 40s, and paladins are always welcome as healers.",
        },
        trainingLevels = EVEN,
    },
    HUNTER = {
        summary = "The safest and quickest solo leveler. Beast Mastery lets the pet hold the mob while you shoot. Look after your pet's level, happiness and food.",
        tips = {
            "At 10 your trainer starts the pet quests. They teach Tame Beast and the pet spells, and you leave with your first pet.",
            "Carry plenty of arrows or bullets and pet food; running out is the most common hunter delay. A quiver or ammo pouch makes shots faster.",
            "Hunter's Mark, then Serpent Sting and Arcane Shot (6) while the pet holds the mob. Stay out of the short dead zone between melee and shooting range.",
            "Aspect of the Monkey early, Aspect of the Hawk from 10 for damage, Aspect of the Cheetah (20) for travel. Cheetah dazes you when you are hit.",
            "Feign Death (30) drops a fight. Freezing Trap (20) and Concussive Shot (8) handle a second mob.",
            "Tame beasts in the wild to learn new pet abilities, and spend the pet's training points on them. Keep the pet close to your level.",
        },
        trainingLevels = EVEN,
    },
    ROGUE = {
        summary = "Combat with swords is the steady leveling choice: Sinister Strike, Slice and Dice and Eviscerate. Pick your fights and use Stealth to skip what you do not need.",
        tips = {
            "Keep Slice and Dice (10) up on longer fights and finish weak mobs with Eviscerate.",
            "Poisons come from a class quest at 20. Instant Poison on the main hand is a big damage gain.",
            "Evasion (8), Sprint (10), Gouge (6) and Vanish (22) are your emergency buttons. Blind (34) takes a second mob out of the fight.",
            "Keep both weapons upgraded, the main hand most of all. A slow main hand makes Sinister Strike hit harder.",
            "Pick Lock opens the lockboxes you loot, for extra money while you level.",
            "Cheap Shot (26) and Kidney Shot (30) lock down dangerous targets. Use them on casters and elites.",
        },
        trainingLevels = EVEN,
    },
    PRIEST = {
        summary = "Shadow is the leveling spec. Let the wand finish kills to save mana, and keep Power Word: Shield up before you take damage.",
        tips = {
            "Power Word: Shield (6), Shadow Word: Pain and Mind Blast (10), then wand. Spirit Tap (Shadow talent) refills mana after kills.",
            "Get a wand as early as you can, from a quest, the auction house or an enchanter. It does most of your damage until your 30s.",
            "Mind Flay and Shadowform are Shadow talents. Shadowform (from 40) is a big jump in damage and safety.",
            "Your trainer has extra priest spells for your race. Check which ones you have.",
            "Psychic Scream (14) and Fade (8) get you out of trouble. Inner Fire (12) adds armor.",
            "Healers are welcome in every dungeon group, so dungeons are an easy way to gear up.",
        },
        trainingLevels = EVEN,
    },
    SHAMAN = {
        summary = "Enhancement with a slow two-handed weapon levels smoothly. Shamans have no Dual Wield in Classic. Each totem element comes from a class quest.",
        tips = {
            "Your trainer starts a totem quest for each element: Earth around 4, Fire around 10, Water around 20 and Air around 30.",
            "Rockbiter Weapon (8) early, Flametongue Weapon (10) on slow weapons, Windfury Weapon (30) once you have it. Keep Lightning Shield (8) up.",
            "Earth Shock (4) interrupts casters. Purge (12) strips buffs from enemy casters.",
            "Searing Totem (10) and Stoneskin or Strength of Earth Totem pay off on long fights; skip totems on quick kills to save mana.",
            "Ghost Wolf (20) speeds up travel until your mount. Stormstrike (Enhancement talent, from 40) hits hard with slow weapons.",
            "Keep mana for Healing Wave between fights; Spirit and Intellect cut your downtime.",
        },
        trainingLevels = EVEN,
    },
    MAGE = {
        summary = "Frost is the safest leveling spec: Frostbolt, Frost Nova and kiting. From the 20s, Blizzard with the right talents lets you grind whole packs at once.",
        tips = {
            "Conjure your own food and water. You will rarely need a vendor.",
            "Single target: Frostbolt as it comes in, Frost Nova (10), step back, and Frostbolt or Fire Blast to finish. Use the wand to save mana.",
            "AoE grinding: Blizzard (20) with Improved Blizzard (Frost talent). Gather a pack, Frost Nova, Blizzard, and Cone of Cold (26) when they get close.",
            "Blink (20) and Polymorph (8) are your escapes. Ice Barrier and Ice Block are Frost talents and make AoE much safer.",
            "Evocation (20) refills mana. Teleports from 20 and portals from 40 save travel time.",
            "Intellect matters most while leveling; spell damage only pays off near 60.",
        },
        trainingLevels = EVEN,
    },
    WARLOCK = {
        summary = "Very little downtime: Life Tap for mana, Drain Life and the Voidwalker for health. Affliction levels well, with DoTs on one mob while your pet holds another.",
        tips = {
            "Pet quests: Voidwalker at 10, Succubus at 20, Felhunter at 30. Your trainer starts each one.",
            "Corruption, Curse of Agony and Immolate, then Fear (8) a second mob and Drain Life (14) to keep your health up.",
            "Life Tap (6) for mana and heal it back with Drain Life or bandages instead of drinking. Keep soul shards for Soulstones and Healthstones.",
            "Siphon Life and Dark Pact (Affliction talents) make solo play smoother. Health Funnel (12) keeps the Voidwalker alive on big pulls.",
            "Your mount, Summon Felsteed, is trained at 40. The epic Dreadsteed comes from a long class quest at 60.",
            "Stamina is your main leveling stat; Demon Skin and Demon Armor add more.",
        },
        trainingLevels = EVEN,
    },
    DRUID = {
        summary = "Feral levels fastest: Bear Form from 10, Cat Form from 20, Travel Form from 30. Shifting breaks slows, and you heal yourself between fights.",
        tips = {
            "Bear Form comes from a class quest at 10 and Aquatic Form from a quest at 16. Cat Form is trained at 20.",
            "Cat: Prowl, open with Ravage (32) or Pounce (36), build combo points with Claw or Shred (22), finish with Rip or Ferocious Bite (32). Bear is safer for two or more mobs.",
            "Out of combat, shift out and heal with Rejuvenation or Regrowth (12). Furor (Restoration talent) gives free rage and energy when you shift.",
            "Travel Form (30) is a big speed gain before your mount. Teleport: Moonglade (10) takes you to a trainer at any time.",
            "Leader of the Pack (Feral talent) and good Feral gear make you a strong dungeon tank as well.",
            "Balance and Restoration are good at 60, but Feral, or a Feral and Restoration mix, is the leveling choice.",
        },
        trainingLevels = EVEN,
    },
}
