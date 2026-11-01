-- Questwarden - headless tests for the kill-pack arrow spot (Core/Roam.lua; loaded by run_tests.lua)
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- SPDX-License-Identifier: GPL-3.0-only
--
-- While two or more steps of the current kill pack are open, the arrow points where their mobs meet, and a
-- hunting route of a pack step that runs away from that spot is not used. Example: Stocking Jetsteam (boars)
-- and The Grizzled Den (wendigos) in Dun Morogh meet by the wendigo cave, not at the boars far west.

local check, ns = TEST.check, TEST.ns
local G, E, R, Nav, ST = ns.Guides, ns.Engine, ns.Roam, ns.Nav, ns.StepText
local prof = ns.db.profile

local SIZE = { [1426] = { 4924.7, 3283.3 } }
local pos = { map = 1426, x = 0.24, y = 0.69 }
local real = { best = C_Map.GetBestMapForUnit, ppos = C_Map.GetPlayerMapPosition, world = C_Map.GetWorldPosFromMapPos,
    log = MOCK.questLog, roam = prof.roamRoutes, routes = ns.RoamRoutes[317] }
C_Map.GetBestMapForUnit = function() return pos.map end
C_Map.GetPlayerMapPosition = function() return { GetXY = function() return pos.x, pos.y end } end
C_Map.GetWorldPosFromMapPos = function(map, v)
    local s = SIZE[map]
    if not s then return nil end
    return map, { GetXY = function() return v.x * s[1], v.y * s[2] end }
end
prof.roamRoutes = true

local function d(x1, y1, x2, y2) return math.sqrt((x1 - x2) ^ 2 + (y1 - y2) ^ 2) end

-- The spot itself: the spawn with mobs of the most lists near it, then the most of the scarcer list.
local x, y = R.PackSpot({ { { 10, 10 }, { 50, 50 }, { 51, 50 } }, { { 90, 90 }, { 52, 51 } } })
check(x and d(x, y, 51, 50.5) < 2, "PackSpot: where the two lists' spawns meet")
check(R.PackSpot({ { { 10, 10 } }, { { 90, 90 } } }) == nil, "PackSpot: nil when no spawns of two lists are near each other")
check(R.PackSpot({ { { 10, 10 } } }) == nil, "PackSpot: nil for one list")
check(#ns.DB.ObjectiveSpawns(313, 1) > 10, "ObjectiveSpawns: Wendigo Mane droppers spawn in Dun Morogh")
check(#ns.DB.ObjectiveSpawns(313, 1, function(name) return name == "Wendigo Mane" end) == 0, "ObjectiveSpawns: a done objective adds none")

-- A route for Stocking Jetsteam at the boars far west of the pack (like the shipped one).
local FAR = { name = "Stocking Jetsteam: far", zone = 1, r = 20, loop = true,
    objs = { { i = 1, kind = "drop", name = "Chunk of Boar Meat", npcs = { 708 } } },
    pts = { { 24.0, 68.7 }, { 22.0, 72.0 }, { 20.0, 75.0 } } }
ns.RoamRoutes[317] = { FAR }

G:Register({ id = "T_PackSpot", name = "Pack spot test", faction = "Alliance", minLevel = 1, maxLevel = 10, steps = {
    { "complete", q = 317, title = "Stocking Jetsteam", pack = 1 },
    { "complete", q = 313, title = "The Grizzled Den", pack = 1 },
    { "note", text = "after" },
} })
local function log(den)
    MOCK.questLog = {
        { id = 317, title = "Stocking Jetsteam", objectives = { { text = "Chunk of Boar Meat: 0/4", type = "item", done = false } } },
    }
    if den then
        MOCK.questLog[2] = { id = 313, title = "The Grizzled Den", objectives = { { text = "Wendigo Mane: 0/8", type = "item", done = false } } }
    end
    ns.Tracker:Scan()
end
log(true)
E:Load("T_PackSpot", { reset = true })
check(E.current == 1 and E.status[2] == "active", "both pack steps are current")

local z, px, py, label = ST:Target(E:CurrentStep())
local sx, sy = R:PackArea(E:CurrentStep(), 1)
check(z == 1 and px and d(px, py, sx, sy) < 0.01, "two open pack steps: the arrow goes to the pack's spot")
check(d(px, py, 24, 69) > 15 and d(px, py, 42.5, 54) < 8, "the spot is by the wendigo cave, not at the far boars")
check(string.find(label, "Stocking Jetsteam", 1, true) and string.find(label, "The Grizzled Den", 1, true), "the label names both quests")
Nav:FromStep(E:CurrentStep())
check(R.active == nil and Nav.owner == "step" and Nav.target and Nav.target.x == px, "the far hunting route does not take over the arrow")
local route, why = R:Pick(E:CurrentStep())
check(route == nil and string.find(why, "kill pack", 1, true), "Roam: a kill pack leads")

-- The Grizzled Den done: one open step. The far route is still not used; the arrow shows the nearest boar.
log(false)
E:MarkDone(2)
route, why = R:Pick(E:CurrentStep())
check(route == nil and why == "route far from the kill pack", "one open pack step: a route far from the pack's spot is not used")
pos.x, pos.y = sx / 100, sy / 100
z, px, py = ST:Target(E:CurrentStep())
check(z == 1 and px and d(px, py, sx, sy) < 6, "the arrow shows a boar near you instead")

-- A route that passes near the spot is used.
local NEAR = { name = "Stocking Jetsteam: near", zone = 1, r = 20, loop = true,
    objs = FAR.objs, pts = { { sx + 1, sy }, { sx + 3, sy + 3 }, { sx - 2, sy + 4 } } }
ns.RoamRoutes[317] = { FAR, NEAR }
route = R:Pick(E:CurrentStep())
check(route == NEAR, "a route near the pack's spot is used")

-- Outside a pack, routes are unchanged.
local plain = { "complete", q = 317, title = "Stocking Jetsteam" }
check(R:PackArea(plain, 1) == nil, "a step outside a pack has no pack area")

R:Stop("test")
ns.RoamRoutes[317] = real.routes
C_Map.GetBestMapForUnit, C_Map.GetPlayerMapPosition, C_Map.GetWorldPosFromMapPos = real.best, real.ppos, real.world
MOCK.questLog, prof.roamRoutes = real.log, real.roam
ns.Tracker:Scan()
E:Load("A_Human_Elwynn", { reset = true })
