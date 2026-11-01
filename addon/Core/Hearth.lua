-- Questwarden - suggesting the hearthstone when it beats walking back to town (setting: hearthSuggest)
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- This program is free software: you can redistribute it and/or modify it under the terms of the
-- GNU General Public License as published by the Free Software Foundation, version 3.
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
-- even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details. The complete license text is in LICENSE.
--
-- A line in the step window only; it never uses the hearthstone. Shown when all of these hold:
--   * the hearthstone is in your bags and off cooldown, you are not on a flight, not in an instance;
--   * the current step and the steps right after it are in the town your hearthstone is set to (within
--     TOWN_YARDS of the inn), and at least one of them turns in a quest that is in your log;
--   * hearthing saves enough time for those turn-ins: WORTH_SECONDS divided by the number of turn-ins,
--     never under MIN_SAVED_SECONDS (one turn-in: 5 minutes saved; two: 2.5; three: 100 seconds; ...).
--     The hearthstone has a long cooldown, so a single turn-in has to save a lot to be worth it.
-- Time to walk: the straight line to the first town step x PATH_FACTOR at your run speed (mounted if
-- you are). Time to hearth: the cast and a loading screen, then the walk from the inn. On another
-- continent walking is not compared: the hearthstone is always the shorter trip.
--
-- Where the inn is: the place you last set the hearthstone (saved when it is set and after you
-- hearth), else the innkeeper of a guide "bind" step for that town. Checked every CHECK seconds.

local _, ns = ...

local H = { current = nil }
ns.Hearth = H

local C = ns.Compat
local HEARTHSTONE = 6948
local HEARTH_SPELL = 8690
local CAST_SECONDS, LOAD_SECONDS = 10, 5
local RUN_SPEED = 7          -- yards per second on foot
local PATH_FACTOR = 1.25     -- roads and hills: walking is longer than the straight line
local TOWN_YARDS = 250       -- a step this close to the inn is "in town"
local WORTH_SECONDS = 300
local MIN_SAVED_SECONDS = 60
local LOOKAHEAD = 15         -- steps checked after the current one
local CHECK = 5

local function prof() return ns.db.profile end
local function dbg(msg) ns:Debug("hearth: " .. msg) end
local function lower(s) return type(s) == "string" and string.lower(s) or nil end

local function inInstance()
    if not IsInInstance then return false end
    local inside, kind = IsInInstance()
    return inside and kind ~= "none"
end

-- Whether the hearthstone is in your bags and ready to use.
function H:Ready()
    local have = false
    for bag = 0, C.NUM_BAGS do
        for slot = 1, C.GetContainerNumSlots(bag) do
            local it = C.GetContainerItem(bag, slot)
            if it and it.itemID == HEARTHSTONE then have = true break end
        end
        if have then break end
    end
    if not have then return false end
    local f = C.Has("C_Container.GetItemCooldown") or C.Has("GetItemCooldown")
    if not f then return false end
    local start, dur = f(HEARTHSTONE)
    if not start then return false end
    return start == 0 or (dur or 0) == 0 or start + dur - GetTime() <= 0
end

-- The inn: uiMapID, x, y (0-100) and the place name, or nil when unknown.
function H:Inn()
    local loc = ns.Compat.GetBindLocation()
    if not loc or loc == "" then return nil end
    local saved = ns.char and ns.char.bindPos
    if type(saved) == "table" and saved.loc == lower(loc) and saved.map and saved.x and saved.y then
        return saved.map, saved.x, saved.y, loc
    end
    for _, g in ipairs(ns.Guides and ns.Guides.list or {}) do
        for _, s in ipairs(g.steps) do
            if s[1] == "bind" and s.z and s.x and s.y and ns.Bind:Names(s)[lower(loc)] then
                local map = ns.DB.ZoneUiMap(s.z)
                if map then return map, s.x, s.y, loc end
            end
        end
    end
end

-- Saves where you are as the inn of the place the hearthstone is set to.
function H:Record(why)
    local loc = ns.Compat.GetBindLocation()
    local map, x, y = C.GetPlayerMapPosition()
    if not (loc and loc ~= "" and x and ns.char) or inInstance() then return end
    ns.char.bindPos = { loc = lower(loc), map = map, x = x, y = y }
    dbg(why .. ": inn of " .. loc .. " at " .. string.format("%s %.1f, %.1f", tostring(map), x, y))
end

local function world(map, x, y)
    local c, wx, wy = C.MapToWorld(map, x, y)
    if c then return { c = c, x = wx, y = wy } end
end

local function yards(a, b)
    if not (a and b) or a.c ~= b.c then return nil end
    return math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2)
end

-- Run speed with your current auras (a mount, travel form), at least the speed on foot.
local function runSpeed()
    local run = GetUnitSpeed and select(2, GetUnitSpeed("player"))
    return math.max(RUN_SPEED, tonumber(run) or 0)
end

-- Seconds hearthing must save for `turnIns` turn-ins to be worth it.
function H.Needed(turnIns)
    if turnIns < 1 then return math.huge end
    return math.max(MIN_SAVED_SECONDS, WORTH_SECONDS / turnIns)
end

-- The suggestion for the current step: { place, saved (seconds, math.huge for another continent),
-- turnIns }, or nil and a reason. No side effects.
function H:Suggest()
    if not prof().hearthSuggest then return nil, "setting off" end
    local E = ns.Engine
    local s = E and E:CurrentStep()
    if not (s and E.current) then return nil, "no step" end
    if s[1] == "hs" or s[1] == "bind" then return nil, "the guide handles the hearthstone here" end
    if inInstance() then return nil, "in an instance" end
    if UnitOnTaxi and UnitOnTaxi("player") then return nil, "on a flight" end
    local map, ix, iy, place = self:Inn()
    if not map then return nil, "inn unknown" end
    local inn = world(map, ix, iy)
    if not inn then return nil, "no map data for the inn" end
    -- The current step and the ones after it that are in town.
    local first, turnIns, n = nil, 0, 0
    for i = E.current, math.min(#E.guide.steps, E.current + LOOKAHEAD) do
        local st = E.status[i]
        if st == "active" or st == "pending" then
            local step = E.guide.steps[i]
            if step[1] == "hs" then break end
            local z, x, y = ns.StepText:Target(step)
            local m = z and ns.DB.ZoneUiMap(z)
            local p = m and world(m, x, y)
            local d = yards(p, inn)
            if not d or d > TOWN_YARDS then break end
            first = first or p
            n = n + 1
            if step[1] == "turnin" and step.q and ns.Tracker:InLog(step.q) then turnIns = turnIns + 1 end
        end
    end
    if not first then return nil, "the current step is not in " .. place end
    if turnIns == 0 then return nil, "no turn-ins in " .. place end
    local pMap, px, py = C.GetPlayerMapPosition()
    if not px then return nil, "no player position" end
    local me = world(pMap, px, py)
    if not me then return nil, "no map data here" end
    local speed = runSpeed()
    local hearth = CAST_SECONDS + LOAD_SECONDS + (yards(inn, first) or 0) * PATH_FACTOR / speed
    local walkYards = yards(me, first)
    local saved = walkYards and (walkYards * PATH_FACTOR / speed - hearth) or math.huge
    if saved < self.Needed(turnIns) then
        return nil, string.format("saves %d s, %d turn-in(s) need %d s", math.floor(saved), turnIns, self.Needed(turnIns))
    end
    if not self:Ready() then return nil, "hearthstone not ready" end
    return { place = place, saved = saved, turnIns = turnIns, steps = n }
end

-- "about 4 min"
local function minutes(secs)
    local m = math.floor(secs / 60 + 0.5)
    return m <= 1 and "about a minute" or ("about " .. m .. " min")
end

-- The step window line, or nil.
function H:Line()
    local h = self.current
    if not h then return nil end
    local quests = h.turnIns == 1 and "1 turn-in" or (h.turnIns .. " turn-ins")
    if h.saved == math.huge then
        return string.format("Hearthstone ready: hearth to %s for %s there instead of the long trip.", h.place, quests)
    end
    return string.format("Hearthstone ready: hearth to %s for %s there; saves %s over walking.", h.place, quests, minutes(h.saved))
end

-- Re-checks the suggestion; redraws the guide window when the line changes.
function H:Check()
    local h, why = self:Suggest()
    local before = self:Line()
    self.current = h
    self.why = why
    if self:Line() ~= before then
        dbg(h and ("suggest " .. h.place .. ", saves " .. math.floor(h.saved) .. " s") or ("none: " .. tostring(why)))
        ns:Fire("REFRESH")
    end
end

function H:Init()
    ns:On("HEARTHSTONE_BOUND", function() C_Timer.After(1, function() H:Record("set") end) end)
    ns:On("UNIT_SPELLCAST_SUCCEEDED", function(_, unit, _, spellId)
        if unit == "player" and spellId == HEARTH_SPELL then C_Timer.After(3, function() H:Record("arrived") H:Check() end) end
    end)
    ns:Listen("STEP_CHANGED", function() H:Check() end)
    ns:Listen("QUESTS_CHANGED", function() H:Check() end)
    local acc = 0
    local f = CreateFrame("Frame")
    f:SetScript("OnUpdate", function(_, elapsed)
        acc = acc + elapsed
        if acc < CHECK then return end
        acc = 0
        H:Check()
    end)
end
