-- Questwarden - headless tests for the death-skip suggestion (loaded by run_tests.lua)
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- SPDX-License-Identifier: GPL-3.0-only

local check, ns = TEST.check, TEST.ns
local D, H, E = ns.DeathSkip, ns.Hearth, ns.Engine
local prof = ns.db.profile

local SIZE = { [1429] = { 3470.8, 2314.6 } }
local pos = { map = 1429, x = 0.5, y = 0.5 }
local real = { best = C_Map.GetBestMapForUnit, ppos = C_Map.GetPlayerMapPosition, world = C_Map.GetWorldPosFromMapPos,
    speed = GetUnitSpeed, setting = prof.deathSkip, hearth = prof.hearthSuggest, level = MOCK.player.level,
    healers = ns.QDB.spiritHealers[12], hc = ns.IsHardcore, dead = UnitIsDeadOrGhost }
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
GetUnitSpeed = function() return 0, 7, 14, 4.7 end
local function at(x, y) pos.x, pos.y = x / 100, y / 100 end
local function goTo(i)
    for j = 1, #E.guide.steps do E.progress.done[j], E.progress.skipped[j] = j < i or nil, nil end
    E:Refresh()
end
prof.deathSkip, prof.hearthSuggest = true, false

check(D.Needed(9) == 60 and D.Needed(10) == 300 and D.Needed(30) == 300,
    "below level 10 a death skip must save a minute, from level 10 five minutes")

-- An Elwynn turn-in step, a graveyard next to it and one far away in the corner
E:Load("A_Human_Elwynn", { reset = true })
local iT, tx, ty
for i, s in ipairs(E.guide.steps) do
    if s[1] == "turnin" and s.q then
        local z, x, y = ns.StepText:Target(s)
        if z and ns.DB.ZoneUiMap(z) == 1429 then iT, tx, ty = i, x, y break end
    end
end
check(iT ~= nil, "an Elwynn turn-in step with a position")
local cx, cy = tx > 50 and 2 or 98, ty > 50 and 2 or 98 -- the far corner
local midX, midY = (tx + cx) / 2, (ty + cy) / 2
ns.QDB.spiritHealers[12] = { { tx, ty + 1 }, { cx, cy } }
goTo(iT)
check(E.current == iT, "the turn-in step is current")

MOCK.player.level = 5
at(midX + (tx - midX) * 0.1, midY + (ty - midY) * 0.1) -- a little nearer the town graveyard than the corner one
D:Check()
check(D.current and not D.current.sickness and D.current.saved >= 60, "level 5, far from town, the town graveyard nearest: death skip suggested")
local details = table.concat(ns.StepText:Details(E.guide.steps[iT]), "\n")
check(string.find(details, "Death skip:", 1, true) and string.find(details, "no resurrection sickness", 1, true),
    "the step says so, and that there is no resurrection sickness below level 10")

at(midX - (tx - midX) * 0.1, midY - (ty - midY) * 0.1) -- now the corner graveyard is nearest
D:Check()
check(D.current == nil and D.why and string.find(D.why, "saves", 1, true), "the graveyard you would land at is the far one: no suggestion")

at(tx + 3, ty) -- about 100 yards from the step
D:Check()
check(D.current == nil, "close to the step: walking is quicker")

-- From level 10: only for 5 minutes or more
at(midX + (tx - midX) * 0.1, midY + (ty - midY) * 0.1)
local savedLow = (D:Suggest() or {}).saved
MOCK.player.level = 12
D:Check()
if savedLow and savedLow >= 300 then
    check(D.current and D.current.sickness, "level 12, saves 5 min or more: suggested with resurrection sickness")
    check(string.find(table.concat(ns.StepText:Details(E.guide.steps[iT]), "\n"), "resurrection sickness and costs gear durability", 1, true),
        "the step warns about resurrection sickness")
else
    check(D.current == nil, "level 12, saves under 5 min: no suggestion")
end
at(cx < 50 and cx + 1 or cx - 1, cy < 50 and cy + 1 or cy - 1)
ns.QDB.spiritHealers[12] = { { tx, ty + 1 } }
D:Check()
check(D.current and D.current.sickness and D.current.saved >= 300, "level 12, across the zone with only the town graveyard: suggested")

-- Never on Hardcore, dead, with the setting off, or when the hearthstone is suggested
ns.IsHardcore = function() return true end
D:Check()
check(D.current == nil and D.why == "Hardcore", "Hardcore character: never suggested")
ns.IsHardcore = real.hc
UnitIsDeadOrGhost = function() return true end
D:Check()
check(D.current == nil and D.why == "dead", "already dead: no suggestion")
UnitIsDeadOrGhost = real.dead
H.current = { place = "Testtown", saved = 600, turnIns = 1 }
D:Check()
check(D.current == nil and D.why == "hearthstone suggested", "the hearthstone is suggested: no death skip")
H.current = nil
prof.deathSkip = false
D:Check()
check(D.current == nil and not string.find(table.concat(ns.StepText:Details(E.guide.steps[iT]), "\n"), "Death skip", 1, true),
    "setting off: no suggestion")
prof.deathSkip = true
for i, s in ipairs(E.guide.steps) do
    if s[1] == "complete" then goTo(i) break end
end
D:Check()
check(D.current == nil and D.why == "not a town step", "a kill or collect step: no suggestion")

C_Map.GetBestMapForUnit, C_Map.GetPlayerMapPosition, C_Map.GetWorldPosFromMapPos = real.best, real.ppos, real.world
GetUnitSpeed, prof.deathSkip, prof.hearthSuggest, MOCK.player.level = real.speed, real.setting, real.hearth, real.level
ns.QDB.spiritHealers[12] = real.healers
D:Check()
E:Load("A_Human_Elwynn", { reset = true })
