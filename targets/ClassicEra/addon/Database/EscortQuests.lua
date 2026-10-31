-- ClassicGuide - escort / scripted-event quest safeguard list for WoW Classic Era
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- SPDX-License-Identifier: GPL-3.0-only
--
-- Quests that must NEVER be accepted automatically. This list is one of several independent signals
-- (DB.GetEscortStatus); a quest is manual-only if ANY signal fires: this list (plus /cg escort add <id>),
-- the PARTY_ACCEPT quest flag in the bundled data, escort wording in the database or offer-panel text, or
-- the quest not being in the bundled database at all (docs/AUTOMATION.md).
--
-- Contents, from the bundled Classic Era QuestieDB data (pinned commit, tools/upstream.json): every quest
-- whose objective or trigger text says "escort", every quest with the PARTY_ACCEPT flag and escort wording
-- (tools/research/qdb.py escort()), plus escorts found by review whose data carries neither: 2078
-- (the Threshwackonator follows you) and 4122. Built by tools/research/escort_notes.py --list. Add, never
-- remove.

local _, ns = ...

ns.EscortQuests = {
    [155] = true, -- The Defias Brotherhood
    [219] = true, -- Missing In Action
    [309] = true, -- Protecting the Shipment
    [435] = true, -- Escorting Erland
    [648] = true, -- Rescue OOX-17/TN!
    [660] = true, -- Hints of a New Plague?
    [665] = true, -- Sunken Treasure
    [667] = true, -- Death From Below
    [731] = true, -- The Absent Minded Prospector
    [836] = true, -- Rescue OOX-09/HL!
    [863] = true, -- The Escape
    [898] = true, -- Free From the Hold
    [938] = true, -- Mist
    [945] = true, -- Therylune's Escape
    [976] = true, -- Supplies to Auberdine
    [994] = true, -- Escape Through Force
    [1144] = true, -- Willix the Importer
    [1222] = true, -- Stinky's Escape
    [1270] = true, -- Stinky's Escape
    [1393] = true, -- Galen's Escape
    [1440] = true, -- Return to Vahlarriel
    [1560] = true, -- Tooga's Quest
    [2078] = true, -- Gyromast's Revenge
    [2742] = true, -- Rin'ji is Trapped!
    [2767] = true, -- Rescue OOX-22/FE!
    [2904] = true, -- A Fine Mess
    [2969] = true, -- Freedom for All Creatures
    [3367] = true, -- Suntara Stones
    [3382] = true, -- A Crew Under Fire
    [3525] = true, -- Extinguishing the Idol
    [4121] = true, -- Precarious Predicament
    [4122] = true, -- Grark Lorkrub
    [4245] = true, -- Chasing A-Me 01
    [4261] = true, -- Ancient Spirit
    [4491] = true, -- A Little Help From My Friends
    [4492] = true, -- Lost!
    [4770] = true, -- Homeward Bound
    [4901] = true, -- Guardians of the Altar
    [4904] = true, -- Free at Last
    [4966] = true, -- Protect Kanati Greycloud
    [5203] = true, -- Rescue From Jaedenar
    [5321] = true, -- The Sleeper Has Awakened
    [5713] = true, -- One Shot. One Kill.
    [5821] = true, -- Bodyguard for Hire
    [5943] = true, -- Gizelton Caravan
    [5944] = true, -- In Dreams
    [6132] = true, -- Get Me Out of Here!
    [6403] = true, -- The Great Masquerade
    [6482] = true, -- Freedom to Ruul
    [6523] = true, -- Protect Kaya
    [6544] = true, -- Torek's Assault
    [6641] = true, -- Vorsha the Lasher
}
