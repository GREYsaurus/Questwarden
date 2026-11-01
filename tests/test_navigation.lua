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

-- TomTom is gone
check(Nav.UpdateTomTom == nil and ns.db.profile.useTomTom == nil and ns.Target.integrations.TomTom == nil, "no TomTom code, setting or integration flag is left")
local old = { useTomTom = true }
ns.FixProfile(old)
check(old.useTomTom == nil and old.showMinimapPin == true, "a saved profile loses its old TomTom setting and gets the minimap pin")

C.GetPlayerMapPosition, C.MapToWorld, C.GetPlayerFacing = keep.pos, keep.world, keep.facing
GetCVar, IsIndoors = keep.cvar, keep.indoors
Nav.target, Nav.owner, ns.db.profile.showMinimapPin = keep.target, keep.owner, keep.pinSetting
Nav:UpdateMinimapPin()
check(#ns.errors == 0, "no captured errors after navigation tests: " .. table.concat(ns.errors, " | "))
