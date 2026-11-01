-- Questwarden - first mount costs for ClassicEra (Core/MountGoal.lua)
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- SPDX-License-Identifier: GPL-3.0-only
-- Source: Warcraft Tavern, "WoW Classic Mount Guide" (https://warcrafttavern.com/wow-classic/guides/mounts/,
-- read 2026-11-01): riding at level 40 costs 20 gold to train and 80 gold for the mount, 100 gold in all; honored
-- reputation with the mount's faction and PvP rank 3 take 10% off each. Approved as a source by the project owner
-- on 2026-11-01. Prices in copper. Class mounts: the trainer spells in Classes/TrainingData.lua (client tables).
local _, ns = ...

ns.Riding = {
    level = 40,
    training = 200000,
    mount = 800000,
    discountText = "Honored reputation with the mount's faction and PvP rank 3 take 10% off each.",
    -- Paladins and Warlocks learn their first mount from the class trainer instead of buying riding and a mount.
    classMounts = { PALADIN = 13819, WARLOCK = 5784 },
    classMountNeedsRiding = false,
    source = "Warcraft Tavern, WoW Classic Mount Guide (read 2026-11-01)",
}
