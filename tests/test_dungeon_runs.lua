-- Questwarden - headless tests: dungeon runs (Core/DungeonRun.lua): the "time to run it" note, the entrance
-- arrow, entering detection, the ghost arrow after a death inside, and Completionist's dungeon steps.
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- SPDX-License-Identifier: GPL-3.0-only
-- Loaded by tests/run_tests.lua after boot (TBC fixture); uses TEST.check and TEST.ns. Uses the shipped
-- Horde Ashenvale guide's Blackfathom Deeps quest (6921) and the real entrance data.

local check, ns = TEST.check, TEST.ns
local DR, E, T, ST, Nav, CP, CM = ns.DungeonRun, ns.Engine, ns.Tracker, ns.StepText, ns.Nav, ns.Corpse, ns.Completionist
local prof = ns.db.profile

local state = { inside = false, map = 1429, ghost = false }
local keep = { inst = IsInInstance, best = C_Map.GetBestMapForUnit, ghost = UnitIsGhost, area = ns.DB.AreaForUiMap,
               player = {}, routing = ns.char.routing, log = MOCK.questLog, completed = MOCK.completed, corpseNav = prof.corpseNav }
for k, v in pairs(MOCK.player) do keep.player[k] = v end
IsInInstance = function() if state.inside then return true, "party" end return false, "none" end
C_Map.GetBestMapForUnit = function() return state.map end
UnitIsGhost = function() return state.ghost end
-- A made-up uiMap id for the inside of Blackfathom Deeps (area 719); everything else as the data says.
ns.DB.AreaForUiMap = function(m) if m == 99719 then return 719 end if m == 99000 then return nil end return keep.area(m) end
local function at(inside, map) state.inside, state.map = inside, map DR:Update() end

-- Data ------------------------------------------------------------------------------------------------
local z, x, y, label = DR:Entrance("Blackfathom Deeps")
check(z == 331 and x and y and label == "Blackfathom Deeps entrance", "Blackfathom Deeps has an entrance in Ashenvale (" .. tostring(z) .. ")")
local n = 0
for _, d in ipairs(ns.Dungeons) do if DR:HasEntrance(d.name) then n = n + 1 end end
check(n == #ns.Dungeons, "every listed dungeon has an entrance (" .. n .. "/" .. #ns.Dungeons .. ")")
check(DR:Entrance("No Such Dungeon") == nil and string.find(DR:Note("No Such Dungeon"), "no position", 1, true), "no entrance: a note and no guessed position")

-- Speed guide: the note, the arrow, entering ------------------------------------------------------------
MOCK.player.race, MOCK.player.class, MOCK.player.faction, MOCK.player.level = "Orc", "WARRIOR", "Horde", 24
ns.char.routing = { dungeons = "selected", selected = { ["Blackfathom Deeps"] = true }, elite = false }
MOCK.questLog, MOCK.completed = { { id = 6921, title = "Amongst the Ruins", complete = false, objectives = { { text = "Sapphire of Aku'Mai", done = false } } } }, {}
T.turnedIn = {}
T:Scan()
at(false, 1429)
E:Load("H_Ashenvale", { reset = true })
local comp
for i, s in ipairs(E.guide.steps) do if s.q == 6921 and s[1] == "complete" then comp = i end end
for i = 1, comp - 1 do E.progress.done[i] = true end
E:Refresh()
Nav:FromStep(E:CurrentStep())
local s = E.guide.steps[comp]
check(E.current == comp and DR:RunPhase(s), "outside the dungeon the run step is current and in its note stage")
check(string.find(ST:Title(s), "Run Blackfathom Deeps: find a group", 1, true), "title: time to run it, find a group (" .. ST:Title(s) .. ")")
local details = table.concat(ST:Details(s), " ")
check(string.find(details, "Find a group", 1, true) and string.find(details, "moves on when you enter", 1, true), "the note says to find a group and that entering moves on")
check(Nav.target and Nav.target.area == 331 and Nav.target.label == "Blackfathom Deeps entrance", "the arrow points to the dungeon entrance")

at(true, 99719)
check(DR.inside == "Blackfathom Deeps" and not DR:RunPhase(s), "entering the dungeon is detected from the map")
check(string.find(ST:Title(s), "Complete", 1, true) and (Nav.target == nil or Nav.target.area ~= 331), "inside: the step moves on to the quest objectives, no entrance arrow")
check(E.status[comp] ~= "done" and not T:IsTurnedIn(6921), "entering never marks the quest complete")
at(true, 99000)
check(DR:Current() == "Blackfathom Deeps", "a client with no map inside an instance: the step's dungeon counts")
at(false, 1429)
check(DR:RunPhase(s) and Nav.target and Nav.target.area == 331, "leaving with the quest unfinished: the note and the entrance arrow come back")

-- Dying inside: the ghost goes back to the entrance ------------------------------------------------------
prof.corpseNav = true
at(true, 99719)
CP:OnDead()
check(ns.char.deathDungeon == "Blackfathom Deeps", "a death inside is remembered with its dungeon")
state.inside, state.map, state.ghost = false, 1429, true
DR:Update()
CP:OnAliveOrWorld()
check(Nav.owner == "corpse" and Nav.target and Nav.target.area == 331 and Nav.target.label == "Blackfathom Deeps entrance", "released: the arrow points to the dungeon entrance")
CP.active, CP.instanceDeath, CP.deathDungeon = false, nil, nil
Nav.owner, Nav.target = nil, nil
CP:OnAliveOrWorld()
check(Nav.owner == "corpse" and Nav.target and Nav.target.area == 331, "after a reload as a ghost the entrance arrow comes back")
state.ghost = false
CP:OnAliveOrWorld()
check(ns.char.deathDungeon == nil and not CP:Active(), "alive again: the death and the arrow are forgotten")

-- Completionist ------------------------------------------------------------------------------------------
local ctx = { race = "Orc", class = "WARRIOR", faction = "Horde", level = 24,
              completed = function() return false end, inLog = function(id) return id == 6921 end }
local seg = CM:Plan(ctx, { 331, 20, 20 })
local run
for _, st in ipairs(seg.steps) do if st[1] == "dungeon" and st.dungeon == "Blackfathom Deeps" then run = st end end
check(run ~= nil, "Completionist adds a dungeon step for an open dungeon quest")
check(ST:Title(run) == DR:Title("Blackfathom Deeps") and select(1, ST:Target(run)) == 331, "it says to find a group and points to the entrance")
ctx.inside = "Blackfathom Deeps"
seg = CM:Plan(ctx, { 331, 20, 20 })
check(seg.kind == "dungeon" and seg.steps[2] and seg.steps[2][1] == "complete" and seg.steps[2].q == 6921, "inside: a dungeon segment with the quest's objectives")
local again = false
for _, st in ipairs(seg.steps) do if st[1] == "dungeon" then again = true end end
check(not again, "inside: no run step for the dungeon you are in")
-- The run step ends when you enter
at(false, 1429)
ns.Guides:RegisterDynamic({ id = CM.GUIDE_ID, name = "Completionist", faction = "Horde", minLevel = 24, maxLevel = 24, dynamic = true,
    steps = { { "dungeon", dungeon = "Blackfathom Deeps" }, { "note", text = "after" } } })
ns:ResetProgress(CM.GUIDE_ID)
E:Load(CM.GUIDE_ID)
check(E.current == 1, "the run step waits outside")
at(true, 99719)
E:Refresh()
check(E.status[1] == "done" and E.current == 2, "entering completes the run step and the guide moves past it")

-- restore
at(false, 1429)
IsInInstance, C_Map.GetBestMapForUnit, UnitIsGhost, ns.DB.AreaForUiMap = keep.inst, keep.best, keep.ghost, keep.area
DR:Update()
for k, v in pairs(keep.player) do MOCK.player[k] = v end
ns.char.routing, MOCK.questLog, MOCK.completed, prof.corpseNav = keep.routing, keep.log, keep.completed, keep.corpseNav
ns.char.deathDungeon, Nav.owner, Nav.target = nil, nil, nil
T.turnedIn = {}
T:Scan()
E:Load("A_Human_Elwynn", { reset = true })
check(#ns.errors == 0, "no captured errors after dungeon run tests: " .. table.concat(ns.errors, " | "))
