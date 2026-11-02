-- Questwarden - headless tests for the hearthstone suggestion (loaded by run_tests.lua)
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- SPDX-License-Identifier: GPL-3.0-only

local check, ns = TEST.check, TEST.ns
local H, E = ns.Hearth, ns.Engine
local prof = ns.db.profile

local SIZE = { [1429] = { 3470.8, 2314.6 } }
local pos = { map = 1429, x = 0.5, y = 0.5 }
local real = { best = C_Map.GetBestMapForUnit, ppos = C_Map.GetPlayerMapPosition, world = C_Map.GetWorldPosFromMapPos,
    log = MOCK.questLog, bind = MOCK.bind, cd = GetItemCooldown, ccd = C_Container.GetItemCooldown, speed = GetUnitSpeed,
    setting = prof.hearthSuggest, bindPos = ns.char.bindPos, bag = MOCK.bags[0][16] }
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
local cdStart, cdDur = 0, 0
C_Container.GetItemCooldown = function() return cdStart, cdDur, 1 end
local runSpeed = 7
GetUnitSpeed = function() return 0, runSpeed, 14, 4.7 end
local function at(x, y) pos.x, pos.y = x / 100, y / 100 end
local function goTo(i)
    for j = 1, #E.guide.steps do E.progress.done[j], E.progress.skipped[j] = j < i or nil, nil end
    E:Refresh()
end
prof.hearthSuggest = true

-- How much a hearth must save
check(H.Needed(1) == 180 and H.Needed(2) == 90 and H.Needed(3) == 60 and H.Needed(5) == 60 and H.Needed(10) == 60,
    "one turn-in needs 3 min saved, two 90 s, never under a minute")
check(H.Needed(0) == math.huge, "no turn-ins: never worth it")

-- A turn-in step in town, the hearthstone set there
E:Load("A_Human_Elwynn", { reset = true })
local iT, tz, tx, ty
for i, s in ipairs(E.guide.steps) do
    if s[1] == "turnin" and s.q then
        local z, x, y = ns.StepText:Target(s)
        if z and ns.DB.ZoneUiMap(z) == 1429 then iT, tz, tx, ty = i, z, x, y break end
    end
end
check(iT ~= nil, "an Elwynn turn-in step with a position")
local q = E.guide.steps[iT].q
MOCK.questLog = { { id = q, title = "Q", objectives = {} } } ns.Tracker:Scan()
MOCK.bind = "Testtown"
MOCK.bags[0][16] = { itemID = 6948, count = 1 }
at(tx, ty)
H:Record("set")
check(ns.char.bindPos and ns.char.bindPos.loc == "testtown" and ns.char.bindPos.x == tx, "the inn is saved where the hearthstone is set")
goTo(iT)
check(E.current == iT, "the turn-in step is current")

at(tx, ty)
H:Check()
check(H.current == nil, "already in town: no suggestion")
at(tx > 50 and 2 or 98, ty > 50 and 2 or 98) -- the far corner of the zone
local far = { pos.x, pos.y }
H:Check()
check(H.current and H.current.turnIns >= 1 and H.current.saved >= H.Needed(H.current.turnIns), "far from town with turn-ins there: hearth suggested")
local details = table.concat(ns.StepText:Details(E.guide.steps[iT]), "\n")
check(string.find(details, "Hearthstone ready: hearth to Testtown", 1, true) and string.find(details, "saves about", 1, true),
    "the step names the town and the time saved")
check(string.find(details, "turn-in", 1, true), "and the turn-ins waiting there")

-- Not worth it, not ready, not wanted
at(tx + 10, ty) -- about 350 yards: hearthing saves far less than 5 minutes
H:Check()
check(H.current == nil and string.find(H.why or "", "need", 1, true), "close enough to walk: no suggestion")
pos.x, pos.y = far[1], far[2]
runSpeed = 60
H:Check()
check(H.current == nil, "fast enough (a mount) that walking costs little: no suggestion")
runSpeed = 7
cdStart, cdDur = GetTime() - 60, 3600
H:Check()
check(H.current == nil and H.why == "hearthstone not ready", "hearthstone on cooldown: no suggestion")
cdStart, cdDur = GetTime() - 3601, 3600
H:Check()
check(H.current ~= nil, "cooldown over: suggested again")
cdStart, cdDur = 0, 0
MOCK.bags[0][16] = nil
H:Check()
check(H.current == nil, "no hearthstone in the bags: no suggestion")
MOCK.bags[0][16] = { itemID = 6948, count = 1 }
MOCK.questLog = {} ns.Tracker:Scan()
H:Check()
check(H.current == nil, "the quest is not in your log: nothing to turn in, no suggestion")
MOCK.questLog = { { id = q, title = "Q", objectives = {} } } ns.Tracker:Scan()
prof.hearthSuggest = false
H:Check()
check(H.current == nil and not string.find(table.concat(ns.StepText:Details(E.guide.steps[iT]), "\n"), "Hearthstone ready", 1, true),
    "setting off: no suggestion")
prof.hearthSuggest = true
MOCK.bind = "Elsewhere"
H:Check()
check(H.current == nil, "hearthstone set somewhere else: no suggestion")
MOCK.bind = "Testtown"
H:Check()
check(H.current ~= nil, "back to the town with the turn-ins: suggested")

-- The inn after hearthing: saved a moment after the cast
ns.char.bindPos = nil
at(30, 30)
MOCK.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-x", 8690)
MOCK.tick(3.2)
check(ns.char.bindPos and ns.char.bindPos.x == 30, "after hearthing, where you land is saved as the inn")
MOCK.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-y", 133)
ns.char.bindPos.x = 31
MOCK.tick(3.2)
check(ns.char.bindPos.x == 31, "other spells do not move the inn")

C_Map.GetBestMapForUnit, C_Map.GetPlayerMapPosition, C_Map.GetWorldPosFromMapPos = real.best, real.ppos, real.world
MOCK.questLog, MOCK.bind, GetItemCooldown, C_Container.GetItemCooldown, GetUnitSpeed = real.log, real.bind, real.cd, real.ccd, real.speed
prof.hearthSuggest, ns.char.bindPos, MOCK.bags[0][16] = real.setting, real.bindPos, real.bag
ns.Tracker:Scan()
H:Check()
E:Load("A_Human_Elwynn", { reset = true })
