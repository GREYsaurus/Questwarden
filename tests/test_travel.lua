-- Questwarden - headless tests for the routes of "travel <zone>" steps (loaded by run_tests.lua)
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- SPDX-License-Identifier: GPL-3.0-only

local check, ns = TEST.check, TEST.ns
local TR, E = ns.Travel, ns.Engine

local real = { best = C_Map.GetBestMapForUnit, ppos = C_Map.GetPlayerMapPosition, player = {}, known = ns.char.knownFlights }
for k, v in pairs(MOCK.player) do real.player[k] = v end
local pos = { map = 1458, x = 0.5, y = 0.5 }
C_Map.GetBestMapForUnit = function() return pos.map end
C_Map.GetPlayerMapPosition = function() return { GetXY = function() return pos.x, pos.y end } end
local function reset() TR.cacheKey = nil end

-- The data
check(ns.TravelData and #ns.TravelData.transports >= 7 and #ns.TravelData.borders >= 40, "zeppelins, boats and borders loaded")
local zep
for _, t in ipairs(ns.TravelData.transports) do
    if t[1] == "zeppelin" and t[3][1] == 14 and t[4][1] == 85 or t[4][1] == 14 and t[3][1] == 85 then zep = t end
end
check(zep and zep[2] == "H", "a Horde zeppelin between Durotar and Tirisfal Glades")
check(TR.ZoneId("The Barrens") == 17 and TR.ZoneForMap(1458) == 1497, "zone lookups by name and by map")
check(TR.Direction({ c = 0, x = 0, y = 0 }, { c = 0, x = -1000, y = 0 }) == "south"
    and TR.Direction({ c = 0, x = 0, y = 0 }, { c = 0, x = 0, y = -1000 }) == "east", "compass directions")

-- An Undead in the Undercity, setting off for the Barrens
E:Load("H_10_Barrens", { reset = true })
local s = { "travel", dest = "The Barrens", index = 0 }
MOCK.player.race, MOCK.player.faction = "Scourge", "Horde"
ns.char.knownFlights = {}
reset()
local r = TR:Route(s)
local kinds = {}
for _, l in ipairs(r and r.legs or {}) do kinds[#kinds + 1] = l.kind end
check(table.concat(kinds, ",") == "walk,zeppelin,walk", "Undercity to the Barrens: walk, zeppelin, walk (" .. table.concat(kinds, ",") .. ")")
local text = table.concat(r and r.lines or {}, " ")
check(string.find(text, "Take the zeppelin from the zeppelin tower near Undercity to Durotar, near Orgrimmar.", 1, true), "the zeppelin leg: " .. text)
check(string.find(text, "into The Barrens", 1, true), "...then into the Barrens")
check(r.target[1] == 85 and string.find(r.target[4], "tower", 1, true), "the arrow points to the zeppelin tower in Tirisfal")
check(#r.flightPaths == 1 and r.flightPaths[1] == "Orgrimmar", "the Orgrimmar flight path is next to where the zeppelin lands")
local z, x, y = ns.StepText:Target(s)
check(z == 85 and x == r.target[2], "the step's arrow target is the tower")
local details = table.concat(ns.StepText:Details(s), "\n")
check(string.find(details, "On the way, get the Orgrimmar flight path", 1, true), "the step says to get it: " .. details)

-- Off the zeppelin in Durotar: only the walk is left
pos.map = 1411
reset()
r = TR:Route(s)
check(r and #r.legs == 1 and r.legs[1].kind == "walk" and r.target[1] == 17, "in Durotar: run into the Barrens, the arrow in the Barrens")

-- An orc knows Orgrimmar from the start: no flight path hint
MOCK.player.race = "Orc"
pos.map = 1458
reset()
r = TR:Route(s)
check(r and #r.flightPaths == 0, "an orc already has the Orgrimmar flight path")

-- A human in Stormwind going to Darkshore: no flight paths but Stormwind, so walk to Menethil and take the boat
MOCK.player.race, MOCK.player.faction = "Human", "Alliance"
pos.map = 1453
local dark = { "travel", dest = "Darkshore", index = 1 }
reset()
r = TR:Route(dark)
local last = r and r.legs[#r.legs]
check(last and last.kind == "boat" and last.to == 148, "Stormwind to Darkshore ends with a boat to Darkshore")
for _, l in ipairs(r and r.legs or {}) do check(l.kind ~= "zeppelin", "no Horde zeppelins for the Alliance") end

-- No route: already there, a step with its own position, an unknown zone
check(TR:Route({ "travel", dest = "Stormwind City" }) == nil, "already in the zone: no route")
check(TR:Route({ "travel", dest = "Darkshore", z = 148, x = 1, y = 1 }) == nil, "a travel step with a position keeps it")
check(TR:Route({ "travel", dest = "Nowhere" }) == nil, "an unknown zone: no route")
check(TR:Route({ "travel", dest = "Darkshore", text = "Take the boat from Menethil." }) == nil, "the guide's own directions win")

C_Map.GetBestMapForUnit, C_Map.GetPlayerMapPosition = real.best, real.ppos
for k, v in pairs(real.player) do MOCK.player[k] = v end
ns.char.knownFlights = real.known
reset()
