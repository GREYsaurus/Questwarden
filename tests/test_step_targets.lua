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

-- Hearthstone step: the innkeeper is marked and targeted, like quest NPCs.
local bind = { "bind", npc = "Innkeeper Belm", npcId = 1247, place = "Kharanos", z = 1, x = 47.4, y = 52.5 }
check(M:NamedNpcs(bind) and M:NamedNpcs(bind)[1247], "a bind step names its innkeeper")
check(A:AddStepNpcs(bind, {})[1247], "the innkeeper is in the target list")
local byName = M:NamedNpcs({ "bind", npc = "Innkeeper Belm", z = 1 })
check(byName and byName[1247], "an innkeeper found by name when the step has no id")
check(M:NamedNpcs({ "accept", q = 179, npc = "Sten Stoutarm" }) == nil, "quest steps keep their own NPC lookup")

G:Register({ id = "T_Bind", name = "Bind test", faction = "Alliance", minLevel = 1, maxLevel = 10, steps = { bind, { "note", text = "after" } } })
local p = ns.db.profile
local old = { p.markEnabled, p.autoMark, p.markFriendly }
p.markEnabled, p.autoMark, p.markFriendly = true, true, true
E:Load("T_Bind", { reset = true })
local rule = M:BuildRule()
check(E.current == 1 and rule and rule.types[1247], "the current bind step's innkeeper gets a raid marker")
p.markEnabled, p.autoMark, p.markFriendly = old[1], old[2], old[3]
E:Load("A_Human_Elwynn", { reset = true })
