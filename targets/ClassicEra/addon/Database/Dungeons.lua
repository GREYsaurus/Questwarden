-- ClassicGuide - dungeon list for WoW Classic Era
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- SPDX-License-Identifier: GPL-3.0-only
--
-- Names match the [dungeon=...] tags in the guides (the instance names in the bundled zone table).
-- Ranges are the commonly quoted "level to run it" bands, approximate (TBCGuide's list, Classic dungeons
-- only); they only decide which dungeons "Select Recommended" turns on. Faction-only dungeons say so.
-- Dungeon quests are off by default on Classic Era (Settings -> Include Dungeon Quests).
local _, ns = ...

ns.Dungeons = {
    { name = "Ragefire Chasm", min = 13, max = 18, faction = "Horde" },
    { name = "Wailing Caverns", min = 17, max = 24 },
    { name = "The Deadmines", min = 17, max = 26, faction = "Alliance" },
    { name = "Shadowfang Keep", min = 22, max = 30 },
    { name = "Blackfathom Deeps", min = 24, max = 32 },
    { name = "The Stockade", min = 24, max = 32, faction = "Alliance" },
    { name = "Gnomeregan", min = 29, max = 38 },
    { name = "Razorfen Kraul", min = 29, max = 38 },
    { name = "Scarlet Monastery", min = 34, max = 45 },
    { name = "Razorfen Downs", min = 37, max = 46 },
    { name = "Uldaman", min = 41, max = 51 },
    { name = "Zul'Farrak", min = 42, max = 46 },
    { name = "Maraudon", min = 46, max = 55 },
    { name = "The Temple of Atal'Hakkar", min = 50, max = 56 },
    { name = "Blackrock Depths", min = 52, max = 60 },
    { name = "Dire Maul", min = 55, max = 60 },
    { name = "Blackrock Spire", min = 55, max = 60 },
    { name = "Scholomance", min = 58, max = 60 },
    { name = "Stratholme", min = 58, max = 60 },
}
