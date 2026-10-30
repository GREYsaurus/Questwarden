-- ClassicGuide - target client and ruleset: World of Warcraft: Forever (staged as Config/Target.lua)
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- This program is free software: you can redistribute it and/or modify it under the terms of the
-- GNU General Public License as published by the Free Software Foundation, version 3.
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
-- even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details. The complete license text is in LICENSE.
--
-- SKELETON. Forever launches 2026-11-04. Every value below is UNVERIFIED until checked in the live
-- client; nothing from Classic Era is assumed to hold here. docs/FOREVER_PLAN.md lists what must be
-- captured. The table holds literals only (tools/build.ps1 reads this file too).

local _, ns = ...

ns.Target = {
    id = "Forever",
    name = "World of Warcraft: Forever",
    -- UNVERIFIED (checked 2026-10-29): Questie bundle v12.3.1 release.json lists flavor "forever" at
    -- interface 16001; wago.tools lists a product "wowf" at 1.60.1.70685 (assumed to be Forever);
    -- Blizzard's UI source (Gethe/wow-ui-source, branch forever) is 1.60.1 (70532).
    interface = 16001,
    clientBuild = "1.60.1",
    minInterface = 16000,
    maxInterface = 16099,
    versionPrefix = "1.60.",
    -- Not verified in the live client: Core/TargetCheck.lua refuses to load guides.
    verified = false,

    -- Ruleset (announced, UNVERIFIED) -----------------------------------------------------------
    maxLevel = 60,
    -- UNVERIFIED: Forever announces new talents; whether points still start at 10 is unknown.
    firstTalentLevel = 10,
    -- UNVERIFIED: the Forever UI source takes MAX_QUESTLOG_QUESTS from the modern client constant
    -- QuestLogConsts.MAXIMUM_NUM_QUESTS_LOG_CAN_ACCEPT (40 in its generated API docs). Check in game.
    questLogMax = 40,
    mountLevel = 40,
    flying = false,
    chapters = { "Azeroth" },
    -- Announced as arriving after launch; UNVERIFIED.
    hardcore = true,
    xpRate = 1,

    integrations = {
        TomTom = true,
        Questie = false,
    },
}
