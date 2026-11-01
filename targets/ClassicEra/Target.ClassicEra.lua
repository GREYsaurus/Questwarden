-- Questwarden - target client and ruleset: WoW Classic Era (staged as Config/Target.lua)
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- This program is free software: you can redistribute it and/or modify it under the terms of the
-- GNU General Public License as published by the Free Software Foundation, version 3.
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
-- even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details. The complete license text is in LICENSE.
--
-- Everything that depends on WHICH client / realm ruleset we run on lives here. The table holds
-- literals only: tools/build.ps1 reads the same file (route checks use questLogMax and maxLevel).
-- See docs/COMPATIBILITY.md for how each value was established.

local _, ns = ...

ns.Target = {
    id = "ClassicEra",
    name = "WoW Classic Era",
    -- Verified 2026-10-29: wago.tools lists product wow_classic_era at 1.15.9.70576 (2026-10-26);
    -- Questie bundle v12.3.1 release.json lists flavor "classic" at interfaces 11508 and 11509;
    -- Blizzard's UI source (Gethe/wow-ui-source, branch classic_era) is 1.15.9 (70576).
    interface = 11509,
    clientBuild = "1.15.9.70576",
    -- Detection (Core/TargetCheck.lua): a client outside this interface range is a different game
    -- version, and no guides are loaded there. 0 (unknown) only warns.
    minInterface = 11500,
    maxInterface = 11599,
    versionPrefix = "1.15.",
    -- false would mean the data has not been checked in this client: guides are then refused.
    verified = true,

    -- Ruleset ------------------------------------------------------------------------------
    maxLevel = 60,
    -- First talent point at 10, one per level => 51 points at 60.
    firstTalentLevel = 10,
    -- Quest log capacity. Blizzard_FrameXMLBase/Vanilla/Constants.lua: MAX_QUESTLOG_QUESTS = 20.
    -- Used by the route checks, and in the add-on only if the client does not report it.
    questLogMax = 20,
    -- Riding (first mount) at 40 in Classic Era.
    mountLevel = 40,
    flying = false,
    -- Guide chapters shown in the guide browser. Classic Era has only the original continents.
    chapters = { "Azeroth" },
    -- Hardcore realms exist on this client (Blizzard UI calls C_GameRules.IsHardcoreActive).
    -- The Hardcore route flavor (docs/GUIDE_FORMAT.md) is chosen in Settings -> General.
    hardcore = true,
    -- Setting defaults for this target (Core/SavedVars.lua). Elite/group quests and dungeon quests are
    -- opt-in on Classic Era: the default route is one a solo player can do. Both are in Settings.
    contentDefaults = { showElite = false, showDungeonSteps = false },
    -- Default XP multiplier (1 = Blizzard rates). Used only for advisory "grind" notes.
    xpRate = 1,
    -- Races/classes are generated from client tables into Database/RaceClass.lua.

    -- Optional integrations (all optional; the guide works without any of them) ----------------
    integrations = {
        Questie = false,     -- we never require Questie; set true to read its map icons (not implemented)
    },
}

-- Private servers / custom rulesets can override values before PLAYER_LOGIN, e.g. from a
-- separate add-on:  Questwarden.Target.xpRate = 3
