-- Questwarden - headless tests for following patrolling NPCs (loaded by run_tests.lua)
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- SPDX-License-Identifier: GPL-3.0-only

local check, ns = TEST.check, TEST.ns
local P, R, E, Nav = ns.Patrol, ns.Roam, ns.Engine, ns.Nav
local prof = ns.db.profile
local QDB = ns.QDB

-- Real map size in yards (UiMapAssignment), so arrival distances mean what they mean in the game.
local SIZE = { [1429] = { 3470.8, 2314.6 } }
local pos = { map = 1429, x = 0.55, y = 0.40 }
local real = { best = C_Map.GetBestMapForUnit, ppos = C_Map.GetPlayerMapPosition, world = C_Map.GetWorldPosFromMapPos,
    inst = IsInInstance, log = MOCK.questLog, setting = prof.patrolPaths, locale = GetLocale,
    mapId = WorldMapFrame.GetMapID, canvas = WorldMapFrame.GetCanvas }
C_Map.GetBestMapForUnit = function() return pos.map end
C_Map.GetPlayerMapPosition = function()
    if not pos.x then return nil end
    return { GetXY = function() return pos.x, pos.y end }
end
C_Map.GetWorldPosFromMapPos = function(map, v)
    local s = SIZE[map]
    if not s then return nil end
    return map, { GetXY = function() return v.x * s[1], v.y * s[2] end }
end
local instance = false
IsInInstance = function() if instance then return true, "party" end return false, "none" end
GetLocale = function() return "enUS" end
local function at(x, y) pos.x, pos.y = x / 100, y / 100 end
local function tick(n) for _ = 1, n or 1 do MOCK.tick(0.55) end end
local function quest(id, objs) MOCK.questLog = { { id = id, title = "Q" .. id, objectives = objs } } ns.Tracker:Scan() end
local function goTo(i)
    for j = 1, #E.guide.steps do E.progress.done[j], E.progress.skipped[j] = j < i or nil, nil end
    E:Refresh()
    Nav:FromStep(E:CurrentStep()) -- STEP_CHANGED only fires when the step changes
end
local function shownDots(pool)
    local n = 0
    for _, t in ipairs(pool.tex) do if t:IsShown() then n = n + 1 end end
    return n
end
prof.patrolPaths = true
MOCK.questLog = {} ns.Tracker:Scan()

-- Bundled data: every path is a flat list of x, y pairs inside the map ---------------------------------
local nNpcs, bad = 0, {}
for id, zones in pairs(QDB.patrols) do
    nNpcs = nNpcs + 1
    for z, paths in pairs(zones) do
        for _, flat in ipairs(paths) do
            local ok = #flat >= 4 and #flat % 2 == 0
            for _, v in ipairs(flat) do ok = ok and v >= 0 and v <= 100 end
            if not ok then bad[#bad + 1] = id .. "@" .. z end
        end
    end
end
check(nNpcs >= 100, "patrol paths loaded: " .. nNpcs .. " NPCs")
check(#bad == 0, "every patrol path is 2+ points inside its map " .. table.concat(bad, ", "))
local loaded = 0
for id in pairs(QDB.patrols) do if QDB.npcs[id] then loaded = loaded + 1 end end
check(loaded == nNpcs, "patrol paths only for NPCs in the bundled data")

-- An accept step whose quest giver walks a path (test data) -------------------------------------------
E:Load("A_Human_Elwynn", { reset = true })
local iAcc, giver
for i, s in ipairs(E.guide.steps) do
    if s[1] == "accept" and s.q then
        local id = ns.DB.GetQuestStartNPCs(s.q)[1]
        local r = id and ns.DB.GetNPCByID(id)
        local n = 0
        for _, pts in pairs(r and r.spawns or {}) do n = n + #pts end
        if n == 1 and not QDB.patrols[id] then iAcc, giver = i, id break end
    end
end
check(iAcc ~= nil, "an Elwynn accept step with a single-spawn quest giver")
QDB.patrols[giver] = { [12] = { { 48, 40, 50, 40, 52, 40 } } } -- 2% apart = about 69 yards
at(55, 40)
goTo(iAcc)
local a = P.active
check(a and a.npc == giver and Nav.owner == "patrol", "the quest giver patrols: the patrol owns the arrow")
check(a.idx == 3 and a.dir == -1 and Nav.target.x == 52, "starts at the nearer end of the path")
check(string.find(Nav.target.label, "(patrols) - point 3 of 3", 1, true), "the label names the NPC and the point")
local details = table.concat(ns.StepText:Details(E.guide.steps[iAcc]), "\n")
check(string.find(details, "patrols: the arrow follows its path", 1, true), "the step says the NPC patrols")
check(string.find(details, "Patrol point 3 of 3", 1, true), "and where the arrow is on the path")
tick(4)
check(a.idx == 3, "far from the point: no advance")
at(52, 40)
tick()
check(a.idx == 2 and Nav.target.x == 50, "at the end: on along the path")
at(50, 40.2)
tick()
check(a.idx == 1 and Nav.target.x == 48, "next point")
at(48, 40)
tick()
check(a.idx == 2 and a.dir == 1 and Nav.target.x == 50, "at the far end: back along the path")
tick(3)
check(a.idx == 2, "staying put does not run through the path")
pos.x = nil
tick(2)
check(a.idx == 2 and a.paused, "no player position: holds the point")
at(48, 40)
tick()

-- Dots on the minimap and world map
check(P.miniLayer:IsShown() and shownDots(P.miniPool) >= 5, "the path is dotted on the minimap")
prof.showMinimapPin = false
P:UpdateMinimap()
check(not P.miniLayer:IsShown(), "minimap pin off: no minimap dots")
prof.showMinimapPin = true
local canvas = CreateFrame("Frame")
local shownMap = 1429
WorldMapFrame.GetMapID = function() return shownMap end
WorldMapFrame.GetCanvas = function() return canvas end
WorldMapFrame:Show()
P:UpdateMap()
check(P.mapLayer:IsShown() and shownDots(P.mapPool) >= 6, "the path is dotted on the world map")
shownMap = 1453
P:UpdateMap()
check(not P.mapLayer:IsShown(), "another map shown: no dots")
shownMap = 1429

-- A manual waypoint is respected; the next step ends the patrol
Nav:SetTarget(12, 41.1, 65.7, "Trainer")
at(50, 40)
tick()
check(Nav.owner == "manual" and Nav.target.x == 41.1, "a waypoint you chose is not replaced by the patrol")
goTo(iAcc)
check(Nav.owner == "patrol", "back on the step: the patrol")
goTo(iAcc + 1)
check(P.active == nil and Nav.owner ~= "patrol", "quest accepted (next step): the patrol ends")
check(not P.mapLayer:IsShown() and not P.miniLayer:IsShown(), "and the dots go")

-- Setting off: the normal waypoint, and a note that the NPC patrols
goTo(iAcc)
prof.patrolPaths = false
P:Refresh()
check(P.active == nil and Nav.owner == "step", "setting off: normal waypoint")
details = table.concat(ns.StepText:Details(E.guide.steps[iAcc]), "\n")
check(string.find(details, "patrols: it may not be where the waypoint is", 1, true) and not string.find(details, "the arrow follows", 1, true),
    "setting off: the step still says the NPC patrols")
prof.patrolPaths = true
P:Refresh()
check(P.active ~= nil and Nav.owner == "patrol", "setting on: the patrol again")
instance = true
tick()
check(P.active == nil, "inside an instance: no patrol")
instance = false
P:Refresh()
check(P.active ~= nil, "back outside: resumes")

-- A loop: starts at the nearest point and goes round
QDB.patrols[giver] = { [12] = { { 48, 40, 50, 40, 50, 42, 48.5, 41 } } }
at(50, 42.5)
P:Refresh()
a = P.active
check(a and a.loop and a.idx == 3, "a loop starts at the nearest point")
at(50, 42)
tick()
check(a.idx == 4, "round the loop")
at(48.5, 41)
tick()
check(a.idx == 1, "after the last point the first")

-- Several paths: the one nearest to the player
QDB.patrols[giver] = { [12] = { { 20, 20, 25, 20 }, { 60, 60, 65, 60 } } }
at(62, 59)
P:Refresh()
check(P.active and P.active.path == 2, "two paths in the zone: the one passing nearest")
QDB.patrols[giver] = nil
P:Refresh()
check(P.active == nil and Nav.owner ~= "patrol", "no path data: normal navigation")

-- Kill steps: only a named NPC with few spawns, until its objective is done ----------------------------
local i7
for i, s in ipairs(E.guide.steps) do if s[1] == "complete" and s.q == 7 then i7 = i break end end
local vermin = ns.DB.GetQuestByID(7).objectives.creatures[1]
local rec = QDB.npcs[vermin]
local spawns = rec[QDB.NPC.SPAWNS]
QDB.patrols[vermin] = { [12] = { { 47, 35, 50, 35 } } }
quest(7, { { text = "Kobold Vermin slain: 0/10", done = false } })
at(47.6, 35.8)
goTo(i7)
check(P.active == nil and R.active ~= nil, "a mob with many spawns: no patrol, the hunting route runs")
rec[QDB.NPC.SPAWNS] = { [12] = { { 47, 35 } } }
P:Refresh() R:Refresh()
check(P.active and P.active.npc == vermin and Nav.owner == "patrol", "a single-spawn kill target patrols: the arrow follows it")
check(R:Pick(E.guide.steps[i7]) == nil and select(2, R:Pick(E.guide.steps[i7])) == "a patrolling NPC leads", "the hunting route gives way")
quest(7, { { text = "Kobold Vermin slain: 1/1", done = true } })
check(P.active == nil and Nav.owner ~= "patrol", "objective done: the patrol ends")
quest(7, { { text = "Kobold Vermin slain: 0/1", done = false } })
check(P.active ~= nil, "objective open again: follows")
MOCK.questLog = {} ns.Tracker:Scan()
check(P.active == nil, "quest not in the log: no patrol")
rec[QDB.NPC.SPAWNS] = spawns
QDB.patrols[vermin] = nil

-- Guide change clears everything
quest(7, { { text = "Kobold Vermin slain: 0/10", done = false } })
E:Load("A_NightElf_Teldrassil", { reset = true })
check(P.active == nil, "guide change: no patrol")

C_Map.GetBestMapForUnit, C_Map.GetPlayerMapPosition, C_Map.GetWorldPosFromMapPos = real.best, real.ppos, real.world
IsInInstance, MOCK.questLog, prof.patrolPaths, GetLocale = real.inst, real.log, real.setting, real.locale
WorldMapFrame.GetMapID, WorldMapFrame.GetCanvas = real.mapId, real.canvas
WorldMapFrame:Hide()
ns.Tracker:Scan()
P:Stop("test end")
R:Stop("test end")
E:Load("A_Human_Elwynn", { reset = true })
