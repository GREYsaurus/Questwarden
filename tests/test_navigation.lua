-- Questwarden - headless tests: built-in minimap pin (Core/Navigation.lua); TomTom support removed
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- SPDX-License-Identifier: GPL-3.0-only
-- Loaded by tests/run_tests.lua after boot; uses TEST.check and TEST.ns. World positions are stubbed:
-- a map point (x, y) is world (north = x, west = y) on continent 0, so offsets read directly in yards.

local check, ns = TEST.check, TEST.ns
local Nav, C = ns.Nav, ns.Compat

local keep = { pos = C.GetPlayerMapPosition, world = C.MapToWorld, facing = C.GetPlayerFacing,
               cvar = GetCVar, indoors = IsIndoors, target = Nav.target, owner = Nav.owner,
               pinSetting = ns.db.profile.showMinimapPin }
C.GetPlayerMapPosition = function() return 1, 500, 500 end
C.MapToWorld = function(mapId, x, y) if mapId == 99 then return 1, x, y end return 0, x, y end
C.GetPlayerFacing = function() return 0 end
GetCVar = function() return "0" end
IsIndoors = nil

local function aim(dx, dy, mapId) Nav.target = { mapId = mapId or 1, x = 500 + dx, y = 500 + dy, label = "test" } end
local function near(a, b) return a and math.abs(a - b) < 0.01 end
-- Minimap is 140 px wide in the mock; zoom 0 outdoors shows 466.67 yards across (0.3 px per yard).
aim(100, 0)
local rx, ry, edge = Nav:MinimapOffset()
check(near(rx, 0) and near(ry, 30) and not edge, "a target 100 yards north is 30 px above the centre (" .. tostring(rx) .. ", " .. tostring(ry) .. ")")
aim(0, -100)
rx, ry = Nav:MinimapOffset()
check(near(rx, 30) and near(ry, 0), "a target 100 yards east is 30 px to the right")
aim(1000, 0)
rx, ry, edge = Nav:MinimapOffset()
check(edge and near(ry, 64) and near(rx, 0), "an out-of-range target sits on the minimap edge, in its direction")
IsIndoors = function() return true end
aim(100, 0)
rx, ry = Nav:MinimapOffset()
check(near(ry, 140 / 300 * 100), "indoors the minimap shows fewer yards, so the pin is further out")
IsIndoors = nil
GetCVar = function(k) return k == "rotateMinimap" and "1" or "0" end
C.GetPlayerFacing = function() return math.pi / 2 end -- facing west
rx, ry = Nav:MinimapOffset()
check(near(rx, 30) and near(ry, 0), "with a rotating minimap, north is to the right while you face west")
GetCVar = function() return "0" end
aim(100, 0, 99)
check(Nav:MinimapOffset() == nil, "a target on another continent has no minimap pin")

-- The pin follows the setting and the target
aim(100, 0)
ns.db.profile.showMinimapPin = true
Nav:UpdateMinimapPin()
check(Nav.mpin and Nav.mpin:IsShown(), "the minimap pin shows for the current waypoint")
ns.db.profile.showMinimapPin = false
Nav:UpdateMinimapPin()
check(not Nav.mpin:IsShown(), "switching the setting off hides it")
ns.db.profile.showMinimapPin = true
Nav.target = nil
Nav:UpdateMinimapPin()
check(not Nav.mpin:IsShown(), "no waypoint, no pin")

-- Time to arrival from the closing speed
Nav.target, Nav.eta = { mapId = 1, x = 1, y = 1 }, nil
check(Nav:Eta(140, 0) == nil, "no estimate from a single sample")
local eta = Nav:Eta(133, 1) -- 7 yards per second, like running
check(eta and math.abs(eta - 19) < 0.01, "running at 7 yd/s with 133 yd to go: 19 s (" .. tostring(eta) .. ")")
check(math.abs(Nav:Eta(133, 1.25) - 18.75) < 0.01, "between samples the countdown keeps running")
Nav:Eta(126, 2)
check(Nav:Eta(126, 3) == nil or Nav.eta.rate < 7, "standing still: the speed estimate drops")
Nav:Eta(126, 4)
Nav:Eta(126, 5)
check(Nav:Eta(130, 6) == nil, "moving away: no estimate")
Nav:Eta(130, 7)
check(Nav:Eta(2000, 8) == nil and Nav.eta.rate == nil, "a jump (teleport, loading screen) resets the estimate")
Nav.target = { mapId = 1, x = 2, y = 2 }
check(Nav:Eta(100, 9) == nil, "a new target starts a new estimate")
check(Nav.FormatEta(42) == "0:42" and Nav.FormatEta(725) == "12:05" and Nav.FormatEta(3723) == "1:02:03", "times read m:ss, or h:mm:ss over an hour")
Nav.target, Nav.eta = nil, nil

-- City, building and cave hints (Core/NavHints.lua) --------------------------------------------------------------
local NH, E = ns.NavHints, ns.Engine
check(NH:CapitalOf(1519) == "Stormwind City" and NH:CapitalOf(1637) == "Orgrimmar" and NH:CapitalOf(12) == nil, "capitals come from the zone data")
local keepHere, keepIndoors, keepCur = ns.Completionist.Here, IsIndoors, E.CurrentStep
local here = { 12, 50, 50 }
ns.Completionist.Here = function() return here[1], here[2], here[3] end
IsIndoors = function() return false end
local cityStep = { "turnin", z = 1519, x = 40, y = 60, npc = "Some Trainer" }
local lines = table.concat(NH:Lines(cityStep, false), " | ")
check(string.find(lines, "is in Stormwind City: follow the streets", 1, true), "a target in a capital says to follow the streets (" .. lines .. ")")
here = { 1519, 50, 50 }
local outStep = { "turnin", z = 12, x = 40, y = 60, npc = "Farmer" }
lines = table.concat(NH:Lines(outStep, true, nil, 500), " | ")
check(string.find(lines, "Leave Stormwind City first", 1, true), "in a capital with the target outside: leave the city first")
check(not string.find(table.concat(NH:Lines(outStep, false, nil, 500), " "), "Leave", 1, true), "where you are only matters for the current step")
-- the arrow line
E.CurrentStep = function() return outStep end
Nav.target = { area = 12, mapId = 1, x = 40, y = 60 }
here = { 1519, 50, 50 }
check(NH:ArrowLine() == "Leave Stormwind City first", "the arrow line: leave the city first")
IsIndoors = function() return true end
here = { 12, 50, 50 }
check(NH:ArrowLine() == nil and not string.find(table.concat(NH:Lines(outStep, true), " "), "indoors", 1, true),
    "no indoors or outdoors hints, even indoors")
check(NH.Observe == nil and NH.TextSaysIndoors == nil, "the indoor-spot learning is gone")
ns.Completionist.Here, IsIndoors, E.CurrentStep = keepHere, keepIndoors, keepCur
Nav.target = nil

-- Indoor spots saved by older versions are dropped
_G[ns.svAccount].indoorSpots = { ["12:48:43"] = true }
ns:InitSavedVariables()
check(_G[ns.svAccount].indoorSpots == nil, "old indoor spots are dropped")

-- TomTom is gone
check(Nav.UpdateTomTom == nil and ns.db.profile.useTomTom == nil and ns.Target.integrations.TomTom == nil, "no TomTom code, setting or integration flag is left")
local old = { useTomTom = true }
ns.FixProfile(old)
check(old.useTomTom == nil and old.showMinimapPin == true, "a saved profile loses its old TomTom setting and gets the minimap pin")

C.GetPlayerMapPosition, C.MapToWorld, C.GetPlayerFacing = keep.pos, keep.world, keep.facing
GetCVar, IsIndoors = keep.cvar, keep.indoors
Nav.target, Nav.owner, ns.db.profile.showMinimapPin = keep.target, keep.owner, keep.pinSetting
Nav:UpdateMinimapPin()
-- An item the objectives need comes first: Marla's Last Wish (6395) buries Samuel's Remains (16333, dropped by
-- Samuel Fipps) at Marla's Grave, so the arrow goes to Samuel Fipps until the remains are in the bags.
local DB = ns.DB
local z, x, y, label = DB.GetObjectiveLocation(6395, 85, 31, 65, nil, function() return false end)
check(label == "Samuel Fipps" and z == 85 and math.abs(x - 36.7) < 0.1, "without the remains, the arrow points at Samuel Fipps (" .. tostring(label) .. ")")
z, x, y, label = DB.GetObjectiveLocation(6395, 85, 31, 65, nil, function(id) return id == 16333 end)
check(label == "Marla's Grave", "with the remains in the bags, the arrow points at the grave (" .. tostring(label) .. ")")
z, x, y, label = DB.GetObjectiveLocation(6395, 85, 31, 65)
check(label == "Marla's Grave", "without a bag check, the objective itself as before")
z, x, y, label = DB.GetObjectiveLocation(6395, 85, 31, 65, function() return true end, function() return false end)
check(label == nil, "with the objective done, no detour for the item")
local items = {}
for _, id in ipairs(DB.GetQuestItems(6395)) do items[id] = true end
check(items[16333], "items a quest's objectives need count as its quest items")

-- A named NPC the follow-up quest needs is not a target: Meven Korgal (1667) drops Scarlet Armbands (The Scarlet
-- Crusade, 381), but The Red Messenger (382) is to kill him; common mobs a follow-up kills stay targets.
local spared = DB.FollowUpNpcs(381)
check(spared[1667], "Meven Korgal is spared for The Red Messenger")
local d = {}
for _, id in ipairs(DB.QuestItemDroppers(3266, 4, 381)) do d[id] = true end
check(d[1506] and d[1507] and not d[1667], "Scarlet Armband targets: Converts and Initiates, not Meven Korgal")
d = {}
for _, id in ipairs(DB.QuestItemDroppers(3266, 4)) do d[id] = true end
check(d[1667], "without the quest, every dropper as before")
local ids = DB.ObjectiveNpcIds(381, 85) or {}
check(ids[1506] and not ids[1667], "the quest's target NPCs leave Meven Korgal out")
local routes = ns.RoamRoutes and ns.RoamRoutes[381]
if routes then
    local hasMeven = false
    for _, o in ipairs(routes[1].objs) do for _, n in ipairs(o.npcs) do if n == 1667 then hasMeven = true end end end
    check(not hasMeven, "the hunting route for The Scarlet Crusade leaves Meven Korgal out")
end

check(#ns.errors == 0, "no captured errors after navigation tests: " .. table.concat(ns.errors, " | "))
