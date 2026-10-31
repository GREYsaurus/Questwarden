-- ClassicGuide - hand-kept notes on class trainer spells for WoW Classic Era (priorities, quest spells)
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- SPDX-License-Identifier: GPL-3.0-only
--
-- The spell ids, levels and ranks come from the client (Classes/TrainingData.lua, generated). The client
-- tables do not say which spells a class QUEST gives instead of the trainer, or which spells matter most
-- while leveling; both are kept here by hand (docs/TRAINER.md).
--
-- quest: spell id -> what to do. Shown as "from a class quest", never as a reason to visit the trainer.
-- Each id is checked against the generated data by the tests. The 1.15.9 client backs them with its own
-- teaching spells (SpellEffect "learn spell"): Path of Defense teaches Defensive Stance, Taunt and Sunder
-- Armor together; Path of the Berserker teaches Berserker Stance and Intercept; Tame Beast and Beast
-- Training teach the pet spells; Bear Form teaches Maul and Growl; "Teach Summon ..." the demons. The
-- quest names and levels are general game knowledge (status: unverified in game).
--
-- important / optional: spell names (English, matched against TrainingData names; the add-on still shows
-- the localized name). Anything not listed is "useful". These are ClassicGuide's own leveling judgement,
-- carried over from the TBC lists and limited to spells the Classic Era trainers teach.

local _, ns = ...

ns.TrainingNotes = {
    quest = {
        WARRIOR = {
            [71] = "Defensive Stance: warrior class quest at level 10",
            [355] = "Taunt: warrior class quest at level 10 (with Defensive Stance)",
            [7386] = "Sunder Armor: warrior class quest at level 10 (with Defensive Stance)",
            [2458] = "Berserker Stance: warrior class quest at level 30",
            [20252] = "Intercept: warrior class quest at level 30 (with Berserker Stance)",
        },
        HUNTER = {
            [1515] = "Tame Beast: hunter pet quests at level 10",
            [883] = "Call Pet: hunter pet quests at level 10",
            [2641] = "Dismiss Pet: hunter pet quests at level 10",
            [982] = "Revive Pet: hunter pet quests at level 10",
            [6991] = "Feed Pet: hunter pet quests at level 10",
        },
        DRUID = {
            [5487] = "Bear Form: druid class quest at level 10",
            [6807] = "Maul: druid class quest at level 10 (with Bear Form)",
            [6795] = "Growl: druid class quest at level 10 (with Bear Form)",
            [1066] = "Aquatic Form: druid class quest at level 16",
        },
        WARLOCK = {
            [697] = "Summon Voidwalker: warlock class quest at level 10",
            [712] = "Summon Succubus: warlock class quest at level 20",
            [713] = "Summon Incubus: warlock class quest at level 20 (same quest as the Succubus)",
            [691] = "Summon Felhunter: warlock class quest at level 30",
            [1122] = "Inferno: warlock class quest at level 50",
            [18540] = "Ritual of Doom: warlock class quest at level 60",
        },
        PALADIN = {
            [7328] = "Redemption: paladin class quest at level 12",
        },
        ROGUE = {
            [2842] = "Poisons: rogue class quest at level 20",
        },
    },

    important = {
        WARRIOR = { "Rend", "Thunder Clap", "Hamstring", "Heroic Strike", "Charge", "Battle Shout", "Overpower", "Execute",
            "Sunder Armor", "Revenge", "Cleave", "Slam", "Whirlwind", "Pummel", "Bloodrage", "Shield Block",
            "Mortal Strike", "Bloodthirst", "Shield Slam", "Intercept" },
        PALADIN = { "Holy Light", "Seal of Righteousness", "Judgement", "Blessing of Might", "Devotion Aura", "Hammer of Justice",
            "Lay on Hands", "Divine Protection", "Seal of the Crusader", "Flash of Light", "Consecration", "Retribution Aura",
            "Blessing of Wisdom", "Exorcism", "Divine Shield", "Seal of Command", "Hammer of Wrath",
            "Holy Shield", "Holy Shock", "Righteous Fury", "Purify", "Cleanse" },
        HUNTER = { "Serpent Sting", "Arcane Shot", "Hunter's Mark", "Aspect of the Hawk", "Mend Pet", "Raptor Strike",
            "Concussive Shot", "Multi-Shot", "Aspect of the Cheetah", "Feign Death", "Freezing Trap", "Wing Clip", "Aimed Shot",
            "Mongoose Bite", "Counterattack" },
        ROGUE = { "Sinister Strike", "Eviscerate", "Backstab", "Slice and Dice", "Gouge", "Evasion", "Kick", "Sprint",
            "Rupture", "Ambush", "Garrote", "Cheap Shot", "Kidney Shot", "Vanish", "Hemorrhage" },
        PRIEST = { "Smite", "Lesser Heal", "Shadow Word: Pain", "Power Word: Shield", "Renew", "Mind Blast", "Power Word: Fortitude",
            "Inner Fire", "Heal", "Flash Heal", "Mind Flay", "Psychic Scream", "Greater Heal",
            "Fade", "Holy Fire", "Devouring Plague" },
        SHAMAN = { "Lightning Bolt", "Healing Wave", "Earth Shock", "Rockbiter Weapon", "Lightning Shield", "Flame Shock",
            "Flametongue Weapon", "Searing Totem", "Strength of Earth Totem", "Lesser Healing Wave", "Ghost Wolf", "Frost Shock",
            "Windfury Weapon", "Chain Lightning", "Chain Heal", "Grace of Air Totem",
            "Mana Spring Totem", "Healing Stream Totem" },
        MAGE = { "Fireball", "Frostbolt", "Frost Armor", "Arcane Intellect", "Arcane Missiles", "Fire Blast", "Frost Nova",
            "Polymorph", "Conjure Water", "Conjure Food", "Arcane Explosion", "Blizzard", "Flamestrike", "Scorch", "Counterspell",
            "Cone of Cold", "Ice Armor", "Mage Armor", "Blink", "Ice Barrier", "Pyroblast", "Evocation" },
        WARLOCK = { "Shadow Bolt", "Immolate", "Corruption", "Curse of Agony", "Life Tap", "Demon Skin", "Demon Armor", "Fear",
            "Drain Life", "Drain Soul", "Health Funnel", "Searing Pain", "Siphon Life", "Create Healthstone", "Death Coil",
            "Soul Fire", "Howl of Terror", "Summon Felsteed" },
        DRUID = { "Wrath", "Moonfire", "Healing Touch", "Rejuvenation", "Mark of the Wild", "Thorns", "Entangling Roots",
            "Regrowth", "Cat Form", "Claw", "Rip", "Shred", "Rake", "Ferocious Bite", "Maul", "Swipe", "Demoralizing Roar",
            "Faerie Fire", "Faerie Fire (Feral)", "Travel Form", "Dire Bear Form", "Starfire", "Insect Swarm", "Innervate" },
    },

    optional = {
        WARRIOR = { "Mocking Blow", "Challenging Shout", "Disarm", "Intimidating Shout", "Shield Bash", "Shield Wall", "Retaliation",
            "Recklessness" },
        PALADIN = { "Sense Undead", "Turn Undead", "Blessing of Salvation", "Blessing of Sacrifice",
            "Shadow Resistance Aura", "Frost Resistance Aura", "Fire Resistance Aura", "Divine Intervention", "Seal of Justice",
            "Greater Blessing of Salvation", "Greater Blessing of Sanctuary", "Greater Blessing of Light" },
        HUNTER = { "Track Undead", "Track Hidden", "Track Elementals", "Track Demons", "Track Giants", "Track Dragonkin",
            "Beast Lore", "Eyes of the Beast", "Eagle Eye", "Scare Beast", "Flare", "Distracting Shot", "Tranquilizing Shot",
            "Aspect of the Wild", "Aspect of the Beast" },
        ROGUE = { "Pick Pocket", "Distract", "Detect Traps", "Disarm Trap", "Safe Fall", "Mind-numbing Poison",
            "Mind-numbing Poison II", "Mind-numbing Poison III" },
        PRIEST = { "Mind Soothe", "Mind Vision", "Levitate", "Shackle Undead", "Mana Burn", "Mind Control", "Shadow Protection",
            "Prayer of Shadow Protection" },
        SHAMAN = { "Water Breathing", "Water Walking", "Far Sight", "Sentry Totem", "Frost Resistance Totem", "Fire Resistance Totem",
            "Nature Resistance Totem", "Windwall Totem", "Astral Recall", "Disease Cleansing Totem" },
        MAGE = { "Slow Fall", "Dampen Magic", "Amplify Magic", "Fire Ward", "Frost Ward", "Remove Lesser Curse",
            "Conjure Mana Agate", "Conjure Mana Jade", "Conjure Mana Citrine", "Conjure Mana Ruby" },
        WARLOCK = { "Unending Breath", "Detect Invisibility", "Sense Demons", "Eye of Kilrogg", "Ritual of Summoning",
            "Subjugate Demon", "Create Firestone", "Create Spellstone", "Curse of Tongues", "Curse of Idiocy", "Curse of Doom",
            "Banish", "Summon Dreadsteed" },
        DRUID = { "Soothe Animal", "Track Humanoids", "Hibernate", "Challenging Roar", "Cower", "Tranquility", "Hurricane",
            "Teleport: Moonglade" },
    },
}

-- Mage teleports and portals are optional for every class that has them.
ns.TrainingNotes.optionalPattern = { "^Teleport: ", "^Portal: ", "^Greater Blessing of ", "^Track " }
