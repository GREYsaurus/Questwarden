-- Questwarden - first mount costs for TBC (Core/MountGoal.lua)
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- SPDX-License-Identifier: GPL-3.0-only
-- Source: Warcraft Tavern, "TBC Classic Mount & Riding Guide" (https://www.warcrafttavern.com/tbc/guides/riding/,
-- read 2026-11-01): Apprentice Riding at level 30 costs 35 gold, the starter mount 10 gold, 45 gold in all; 36
-- gold with exalted reputation. Approved as a source by the project owner on 2026-11-01. Prices in copper.
-- Class mounts: the trainer spells in Classes/TrainingData.lua (client tables); their price is in
-- Classes/WhatsTrainingData.lua. ridingSpell: Apprentice Riding, the spell the riding trainer teaches.
local _, ns = ...

ns.Riding = {
    level = 30,
    training = 350000,
    mount = 100000,
    discountText = "Exalted reputation with the mount's faction lowers both prices (36 gold in all).",
    -- Paladins and Warlocks learn their first mount from the class trainer; they still need Apprentice Riding.
    classMounts = { PALADIN = 13819, WARLOCK = 5784 },
    classMountNeedsRiding = true,
    ridingSpell = 33388,
    source = "Warcraft Tavern, TBC Classic Mount & Riding Guide (read 2026-11-01)",
}
