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

-- Quest-item droppers: ordinary mobs near the quest's level, not rares, elites or much higher mobs.
-- The Grizzled Den (313, level 7): Wendigo Mane from Young Wendigo and Wendigo, not Edan the Howler, Old Icebeard or Vagash.
local d = {}
for _, id in ipairs(DB.QuestItemDroppers(2671, 7)) do d[id] = true end
check(d[1134] and d[1135] and not d[1137] and not d[1271] and not d[1388], "Wendigo Mane: only the level-fitting wendigos")
local obj = DB.ObjectiveNpcIds(313, 1) or {}
check(obj[1134] and not obj[1137] and not obj[1271], "The Grizzled Den: targets and marks leave out Edan the Howler and the elites")
local _, _, _, wl = DB.GetObjectiveLocation(313, 1, 39, 47.5)
check(wl == "Young Wendigo" or wl == "Wendigo", "The Grizzled Den: the arrow goes to a wendigo, not Edan the Howler")

-- Quests from an object, not an NPC: the step says what to right-click (Core/StepText.lua)
local ST = ns.StepText
local poster = ST.ObjectGiverLine({ "accept", q = 398, npc = "Wanted!" })
check(poster and poster:find("is not an NPC but a wanted poster", 1, true) and poster:find("Right-click it to read the quest", 1, true),
    "Wanted: Maggot Eye: the pick-up says it is a wanted poster to right-click (" .. tostring(poster) .. ")")
check(ST.ObjectGiverLine({ "accept", q = 6395, npc = "Novice Elreth" }) == nil, "an NPC giver: no note")
check(ST.ObjectGiverLine({ "turnin", q = 398 }) == nil, "turned in to an NPC: no note")
local details = table.concat(ST:Details({ "accept", q = 398, npc = "Wanted!" }), "\n")
check(details:find("wanted poster", 1, true), "the note is in the step's details")

-- A fly step without the flight path: run there instead.
do
    local node
    for id, n in pairs(ns.Flights.nodes) do if n.name == "Ratchet" then node = id end end
    local fly = { "fly", dest = "Ratchet", node = node, z = 17, x = 51.5, y = 30.3 }
    local savedKnown = ns.char.knownFlights
    ns.char.knownFlights = {}
    local text = table.concat(ns.StepText:Details(fly), "\n")
    check(node and string.find(text, "No flight path to Ratchet yet? Run there instead", 1, true), "fly step, flight map never seen: run-instead hint")
    check(select(3, ns.StepText:Target(fly)) == 30.3, "...the arrow stays on the step")
    ns.char.knownFlights = { [next(ns.Flights.nodes)] = true }
    ns.char.knownFlights[node] = nil
    text = table.concat(ns.StepText:Details(fly), "\n")
    local z, x, y = ns.StepText:Target(fly)
    check(string.find(text, "You don't have the flight path to Ratchet yet: run there instead", 1, true)
        and z == ns.Flights.nodes[node].zone and x == ns.Flights.nodes[node].x, "flight path not known: run there, the arrow points to Ratchet")
    ns.char.knownFlights[node] = true
    text = table.concat(ns.StepText:Details(fly), "\n")
    check(not string.find(text, "run there", 1, true), "flight path known: no hint")
    -- Your race's capital city: known from the start.
    ns.char.knownFlights = {}
    local savedRace = MOCK.player.race
    MOCK.player.race = "Scourge"
    local uc = { "fly", dest = "Undercity", node = 11, z = 85, x = 61.9, y = 65.0 }
    check(ns.StepText.FlightUnknown(uc) == false and ns.FlightPaths:Has(11), "Undead: the Undercity flight path counts as known with no flight map seen")
    check(ns.StepText.FlightUnknown(fly) == nil, "...other flight paths are still unknown")
    MOCK.player.race = "Orc"
    check(ns.FlightPaths:Capital() == 23 and not ns.FlightPaths:Has(11), "Orc: Orgrimmar, not Undercity")
    MOCK.player.race = savedRace
    ns.char.knownFlights = savedKnown
end
