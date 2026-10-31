-- Questwarden - gear scoring profiles for WoW Classic Era (data only; no logic)
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- SPDX-License-Identifier: GPL-3.0-only
--
-- Every priority below is taken from a source recorded in docs/GEAR_RESEARCH_CLASSIC.md (read 2026-10-31):
--   S1 = Icy Veins WoW Classic spec leveling pages ("Leveling Stats" section)
--   S2 = Icy Veins WoW Classic class leveling guides ("Gear Options" / "Preferred Gear and Stats Options")
--   S3 = Icy Veins WoW Classic Hardcore class overviews ("Stat Priority")
--   S4 = Icy Veins WoW Classic PvE stat priority pages (level 60)
-- No Classic Era source we may use publishes numeric weights, so every profile is priority-only
-- (`priority`, best first; `weights = nil`). Stats the scorer has no key for (weapon damage and speed,
-- weapon skill, resistances, spell penetration) are named in `assumptions` only. Rogue and Hunter have no
-- leveling profile: no source gives a leveling priority for them (GEAR_RESEARCH_CLASSIC.md).
--
-- Stat keys: str agi sta int spi ap rap feralap sp heal hit spellhit crit spellcrit mp5 def dodge parry
-- block blockvalue armor. On Classic items hit and crit are percentages ("Improves your chance to hit by 1%").

local _, ns = ...

ns.GearProfiles = {
    researched = "2026-10-31",
    game = "WoW Classic Era 1.15",
    list = {
        -- Leveling (1-59) ------------------------------------------------------------------------------
        { id = "warrior_leveling_early", class = "WARRIOR", role = "Melee DPS", context = "leveling", levelMin = 1, levelMax = 29,
          confidence = "low", priority = { "str", "agi", "spi", "sta", "armor" },
          assumptions = "The weapon matters most (high damage; slower is better for Whirlwind and Mortal Strike). Spirit has a large effect on regeneration early; by 30 food, bandages and potions take over.",
          sources = { "S2 icy-veins.com/wow-classic/classic-warrior-leveling-guide (Gear Options)" } },
        { id = "warrior_leveling", class = "WARRIOR", role = "Melee DPS", context = "leveling", levelMin = 30, levelMax = 59,
          confidence = "low", priority = { "str", "agi", "sta", "armor" },
          assumptions = "The weapon matters most (high damage; slower is better).",
          sources = { "S2 icy-veins.com/wow-classic/classic-warrior-leveling-guide (Gear Options)" } },

        { id = "paladin_holy_leveling", class = "PALADIN", spec = "Holy", role = "Melee DPS", context = "leveling", levelMin = 1, levelMax = 59,
          confidence = "medium", priority = { "sp", "spi", "int", "sta", "str" }, schools = { "Holy" },
          assumptions = "Spell damage means +Holy damage. +Healing pieces are only for dungeons.",
          sources = { "S1 icy-veins.com/wow-classic/holy-paladin-leveling-talent-build-from-1-to-60" } },
        { id = "paladin_retribution_leveling", class = "PALADIN", spec = "Retribution", role = "Melee DPS", context = "leveling", levelMin = 1, levelMax = 59,
          confidence = "medium", priority = { "str", "spi", "agi", "int", "sta" },
          assumptions = "Agility is worth much less until Vengeance. +Holy damage is also good but rare.",
          sources = { "S1 icy-veins.com/wow-classic/retribution-paladin-leveling-talent-build-from-1-to-60" } },
        { id = "paladin_protection_leveling", class = "PALADIN", spec = "Protection", role = "Melee DPS", context = "leveling", levelMin = 1, levelMax = 59,
          confidence = "medium", priority = { "str", "spi", "int", "sta", "agi" },
          sources = { "S1 icy-veins.com/wow-classic/protection-paladin-leveling-talent-build-from-1-to-60" } },

        { id = "mage_leveling", class = "MAGE", role = "Ranged DPS", context = "leveling", levelMin = 1, levelMax = 59,
          confidence = "low", priority = { "int", "spi", "sp", "sta" },
          assumptions = "Spell damage helps little while leveling and not at all with the wand.",
          sources = { "S2 icy-veins.com/wow-classic/classic-mage-leveling-guide (Gear Options)" } },

        { id = "priest_shadow_leveling", class = "PRIEST", spec = "Shadow", role = "Ranged DPS", context = "leveling", levelMin = 1, levelMax = 59,
          confidence = "low", priority = { "sp", "mp5", "int", "spi" }, schools = { "Shadow" },
          assumptions = "The wand matters most for every spec.",
          sources = { "S2 icy-veins.com/wow-classic/classic-priest-leveling-guide (Preferred Gear and Stats Options)" } },
        { id = "priest_leveling", class = "PRIEST", role = "Ranged DPS", context = "leveling", levelMin = 1, levelMax = 59,
          confidence = "low", priority = { "int", "spi", "mp5" },
          assumptions = "Holy and Discipline. The wand matters most.",
          sources = { "S2 icy-veins.com/wow-classic/classic-priest-leveling-guide (Preferred Gear and Stats Options)" } },

        { id = "shaman_enhancement_leveling", class = "SHAMAN", spec = "Enhancement", role = "Melee DPS", context = "leveling", levelMin = 1, levelMax = 59,
          confidence = "low", priority = { "agi", "crit", "str", "sta", "int" },
          assumptions = "The weapon matters most (high damage; slower is better for Stormstrike).",
          sources = { "S2 icy-veins.com/wow-classic/classic-shaman-leveling-guide (Preferred Gear and Stats Options)" } },
        { id = "shaman_leveling", class = "SHAMAN", role = "Ranged DPS", context = "leveling", levelMin = 1, levelMax = 59,
          confidence = "low", priority = { "int" },
          assumptions = "Elemental and Restoration: Intellect first and foremost; the source ranks nothing else.",
          sources = { "S2 icy-veins.com/wow-classic/classic-shaman-leveling-guide (Preferred Gear and Stats Options)" } },

        { id = "warlock_leveling", class = "WARLOCK", role = "Ranged DPS", context = "leveling", levelMin = 1, levelMax = 59,
          confidence = "low", priority = { "sta", "int", "spi" },
          assumptions = "From the Hardcore overview (Demonic Embrace and Soul Link scale with Stamina); no Classic leveling page ranks Warlock stats.",
          sources = { "S3 icy-veins.com/wow-classic/hardcore-warlock-class-overview" } },

        { id = "druid_feral_leveling", class = "DRUID", spec = "Feral", role = "Melee DPS", context = "leveling", levelMin = 1, levelMax = 59,
          confidence = "medium", priority = { "agi", "str", "spi", "sta", "int" },
          sources = { "S1 icy-veins.com/wow-classic/feral-druid-leveling-talent-build-from-1-to-60" } },
        { id = "druid_balance_leveling", class = "DRUID", spec = "Balance", role = "Ranged DPS", context = "leveling", levelMin = 1, levelMax = 59,
          confidence = "medium", priority = { "sp", "int", "spi", "sta" }, schools = { "Nature", "Arcane" },
          sources = { "S1 icy-veins.com/wow-classic/balance-druid-leveling-talent-build-from-1-to-60" } },
        { id = "druid_restoration_leveling", class = "DRUID", spec = "Restoration", role = "Ranged DPS", context = "leveling", levelMin = 1, levelMax = 59,
          confidence = "medium", priority = { "sp", "int", "spi", "sta" }, schools = { "Nature" },
          sources = { "S1 icy-veins.com/wow-classic/restoration-druid-leveling-talent-build-from-1-to-60" } },

        -- Level 60 PvE ---------------------------------------------------------------------------------
        { id = "warrior_arms_60", class = "WARRIOR", spec = "Arms", role = "Melee DPS", context = "pve-raid", levelMin = 60, levelMax = 60,
          confidence = "medium", priority = { "hit", "crit", "str", "ap", "agi" },
          assumptions = "Weapon damage and speed come first, then weapon skill to 308; hit is soft-capped at about 6% with 305 skill, 9% without.",
          sources = { "S4 icy-veins.com/wow-classic/warrior-dps-pve-stat-priority" } },
        { id = "warrior_fury_60", class = "WARRIOR", spec = "Fury", role = "Melee DPS", context = "pve-raid", levelMin = 60, levelMax = 60,
          confidence = "medium", priority = { "hit", "crit", "str", "ap", "agi" },
          assumptions = "Same DPS page as Arms: weapon first, weapon skill to 308, hit about 6% with 305 skill (9% without).",
          sources = { "S4 icy-veins.com/wow-classic/warrior-dps-pve-stat-priority" } },
        { id = "warrior_protection_60", class = "WARRIOR", spec = "Protection", role = "Tank", context = "pve-raid", levelMin = 60, levelMax = 60,
          confidence = "medium", priority = { "sta", "armor", "parry", "dodge", "def", "agi", "str", "blockvalue", "block" },
          assumptions = "Survival list; the threat list (weapon, weapon skill, hit) is separate on the page.",
          sources = { "S4 icy-veins.com/wow-classic/warrior-tank-pve-stat-priority" } },

        { id = "paladin_holy_60", class = "PALADIN", spec = "Holy", role = "Healer", context = "pve-raid", levelMin = 60, levelMax = 60,
          confidence = "medium", priority = { "heal", "int", "spellcrit", "mp5", "sta", "spi" },
          sources = { "S4 icy-veins.com/wow-classic/holy-paladin-healer-pve-stat-priority" } },
        { id = "paladin_protection_60", class = "PALADIN", spec = "Protection", role = "Tank", context = "pve-raid", levelMin = 60, levelMax = 60,
          confidence = "medium", priority = { "sta", "def", "str", "agi", "armor", "int" },
          assumptions = "Defensive list; the threat list (hit, spell damage, Strength, Intellect) is separate on the page.",
          sources = { "S4 icy-veins.com/wow-classic/protection-paladin-tank-pve-stat-priority" } },
        { id = "paladin_retribution_60", class = "PALADIN", spec = "Retribution", role = "Melee DPS", context = "pve-raid", levelMin = 60, levelMax = 60,
          confidence = "medium", priority = { "hit", "str", "agi", "crit", "ap", "sp", "sta", "int" },
          assumptions = "Hit to 9%.", schools = { "Holy" },
          sources = { "S4 icy-veins.com/wow-classic/retribution-paladin-dps-pve-stat-priority" } },

        { id = "hunter_60", class = "HUNTER", role = "Ranged DPS", context = "pve-raid", levelMin = 60, levelMax = 60,
          confidence = "medium", priority = { "hit", "crit", "agi", "rap", "ap", "sta", "int", "spi", "str" },
          assumptions = "Hit to 9%. The page names Attack Power; ranged attack power is listed with it.",
          sources = { "S4 icy-veins.com/wow-classic/hunter-dps-pve-stat-priority" } },

        { id = "rogue_60", class = "ROGUE", role = "Melee DPS", context = "pve-raid", levelMin = 60, levelMax = 60,
          confidence = "medium", priority = { "hit", "agi", "str", "ap", "crit" },
          assumptions = "Hit to 9%; weapon skill is also strong but rare. Seal Fate builds may rank crit higher.",
          sources = { "S4 icy-veins.com/wow-classic/rogue-dps-pve-stat-priority",
                      "S5 wowhead.com/classic/guide/classes/rogue/dps-stat-priority-attributes-pve agrees on order" } },

        { id = "priest_shadow_60", class = "PRIEST", spec = "Shadow", role = "Ranged DPS", context = "pve-raid", levelMin = 60, levelMax = 60,
          confidence = "medium", priority = { "spellhit", "sp", "mp5", "int", "spellcrit", "spi", "sta" }, schools = { "Shadow" },
          assumptions = "6% spell hit from gear with Shadow Focus (16% without).",
          sources = { "S4 icy-veins.com/wow-classic/shadow-priest-dps-pve-stat-priority" } },
        { id = "priest_healer_60", class = "PRIEST", role = "Healer", context = "pve-raid", levelMin = 60, levelMax = 60,
          confidence = "medium", priority = { "heal", "mp5", "spi", "int", "spellcrit", "sta" },
          sources = { "S4 icy-veins.com/wow-classic/priest-healer-pve-stat-priority" } },

        { id = "shaman_elemental_60", class = "SHAMAN", spec = "Elemental", role = "Ranged DPS", context = "pve-raid", levelMin = 60, levelMax = 60,
          confidence = "medium", priority = { "spellhit", "sp", "spellcrit", "mp5", "int", "sta", "spi" },
          assumptions = "Spell hit to 16% before talents.",
          sources = { "S4 icy-veins.com/wow-classic/elemental-shaman-dps-pve-stat-priority" } },
        { id = "shaman_enhancement_60", class = "SHAMAN", spec = "Enhancement", role = "Melee DPS", context = "pve-raid", levelMin = 60, levelMax = 60,
          confidence = "medium", priority = { "hit", "crit", "str", "ap", "agi", "mp5", "int" },
          assumptions = "Weapon damage and speed first, then weapon skill to 308; hit about 6% with 305 skill (9% without).",
          sources = { "S4 icy-veins.com/wow-classic/enhancement-shaman-dps-pve-stat-priority" } },
        { id = "shaman_restoration_60", class = "SHAMAN", spec = "Restoration", role = "Healer", context = "pve-raid", levelMin = 60, levelMax = 60,
          confidence = "medium", priority = { "mp5", "int", "heal", "spellcrit", "spi", "sta" },
          sources = { "S4 icy-veins.com/wow-classic/restoration-shaman-healer-pve-stat-priority" } },

        { id = "mage_60", class = "MAGE", role = "Ranged DPS", context = "pve-raid", levelMin = 60, levelMax = 60,
          confidence = "medium", priority = { "spellhit", "spellcrit", "sp", "int", "sta", "mp5", "spi", "agi", "armor" },
          assumptions = "Spell hit to about 10% against bosses (with talents).",
          sources = { "S4 icy-veins.com/wow-classic/mage-dps-pve-stat-priority" } },

        { id = "warlock_60", class = "WARLOCK", role = "Ranged DPS", context = "pve-raid", levelMin = 60, levelMax = 60,
          confidence = "medium", priority = { "sp", "spellcrit", "spellhit", "int", "sta", "spi" }, schools = { "Shadow" },
          assumptions = "Hit up to 16%; spell penetration sits between hit and Intellect but has no stat key.",
          sources = { "S4 icy-veins.com/wow-classic/warlock-dps-pve-stat-priority" } },

        { id = "druid_balance_60", class = "DRUID", spec = "Balance", role = "Ranged DPS", context = "pve-raid", levelMin = 60, levelMax = 60,
          confidence = "medium", priority = { "spellhit", "spellcrit", "sp", "int", "spi", "sta" }, schools = { "Arcane" },
          assumptions = "Spell hit to 16%.",
          sources = { "S4 icy-veins.com/wow-classic/balance-druid-ranged-dps-pve-stat-priority" } },
        { id = "druid_feral_60", class = "DRUID", spec = "Feral", role = "Melee DPS", context = "pve-raid", levelMin = 60, levelMax = 60,
          confidence = "medium", priority = { "hit", "agi", "str", "crit", "ap", "feralap", "int", "sta", "spi" },
          assumptions = "Hit to 9%. Feral attack power on weapons is listed with Attack Power.",
          sources = { "S4 icy-veins.com/wow-classic/feral-druid-melee-dps-pve-stat-priority" } },
        { id = "druid_feral_tank_60", class = "DRUID", spec = "Feral", role = "Tank", context = "pve-raid", levelMin = 60, levelMax = 60,
          confidence = "medium", priority = { "armor", "sta", "def", "agi", "dodge", "hit", "str", "ap", "crit" },
          sources = { "S4 icy-veins.com/wow-classic/feral-druid-tank-pve-stat-priority" } },
        { id = "druid_restoration_60", class = "DRUID", spec = "Restoration", role = "Healer", context = "pve-raid", levelMin = 60, levelMax = 60,
          confidence = "medium", priority = { "heal", "mp5", "int", "spi", "spellcrit", "sta" },
          sources = { "S4 icy-veins.com/wow-classic/restoration-druid-healer-pve-stat-priority" } },
    },

    -- Heuristic layer for AUTOMATIC UPGRADES ONLY (Gear/Upgrade.lua). NOT from any source: these are
    -- Questwarden's own estimates, shown as "estimated" wherever they are used (docs/AUTO_EQUIP.md).
    -- Tooltips and quest rewards keep using the sourced priorities above unchanged.
    heuristic = {
        -- Priority-only profiles: weight = budget[stat] x rank factor. The first listed stat gets
        -- rankTop, the last rankBottom, linear in between; stats not listed count 0.
        rankTop = 1.0, rankBottom = 0.4,
        -- Approximate cost of one point of each stat relative to one point of a primary stat. Classic
        -- items give hit and crit in whole percents, so one point of those is valued like ten primary
        -- points (our estimate, unverified).
        budget = { str = 1, agi = 1, sta = 1, int = 1, spi = 1, ap = 0.5, rap = 0.4, feralap = 0.4, sp = 0.86, heal = 0.45,
                   hit = 10, spellhit = 10, crit = 10, spellcrit = 10, mp5 = 2.5, def = 1, dodge = 10, parry = 10,
                   block = 10, blockvalue = 0.65, armor = 0.02 },
        -- Weapon DPS: 1 DPS adds 14 attack power worth of white damage on that hand (AP / 14 = DPS;
        -- the Classic warrior page states the same rule). Valued at the profile's AP weight.
        weaponDpsPerAp = 14, offHandFactor = 0.5,
    },
}
