-- Questwarden - headless tests for step targets (Database/QuestDB.lua, Core/Marker.lua; loaded by run_tests.lua)
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- SPDX-License-Identifier: GPL-3.0-only
--
-- The objective waypoint moves on once your log shows an objective done (A Refugee's Quandary: three of Felix's
-- things in different places), and the NPC a hearthstone step names (an innkeeper) is marked and targeted.

local check, ns = TEST.check, TEST.ns
local DB, M, A, G, E = ns.DB, ns.Marker, ns.Assist, ns.Guides, ns.Engine

-- A Refugee's Quandary (3361): Felix's Box, Felix's Chest, Felix's Bucket of Bolts, each from its own object.
local Q = 3361
local boxItem = 10438
local boxObj = DB.GetItemByID(boxItem).objectDrops[1]
local bz, bx, by = DB.GetObjectPosition(boxObj)
check(bz ~= nil, "Felix's Box has a position in the data")
local _, _, _, label = DB.GetObjectiveLocation(Q, bz, bx, by)
check(label == DB.GetObjectName(boxObj), "standing at the box, the nearest objective is the box")
local done = function(name) return name == DB.GetItemName(boxItem) end
local z2, x2, y2, label2 = DB.GetObjectiveLocation(Q, bz, bx, by, done)
check(z2 and label2 ~= DB.GetObjectName(boxObj) and (x2 ~= bx or y2 ~= by), "with the box looted, the waypoint moves on to the next thing")

-- The same through the guide step and the quest log text.
MOCK.questLog = { { id = Q, title = "A Refugee's Quandary", objectives = {
    { text = "Felix's Box: 1/1", type = "item", done = true },
    { text = "Felix's Chest: 0/1", type = "item", done = false },
    { text = "Felix's Bucket of Bolts: 0/1", type = "item", done = false } } } }
ns.Tracker:Scan()
check(ns.Tracker:ObjectiveNameDone(Q, "Felix's Box") and not ns.Tracker:ObjectiveNameDone(Q, "Felix's Chest"), "log text: which objective is done")
local _, _, _, stepLabel = ns.StepText:Target({ "complete", q = Q })
check(stepLabel and stepLabel ~= DB.GetObjectName(boxObj), "the complete step's waypoint leaves out the looted box")
MOCK.questLog = {}
ns.Tracker:Scan()
