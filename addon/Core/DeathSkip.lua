-- Questwarden - suggesting a death skip: dying on purpose and taking the spirit healer's resurrection when its
-- graveyard is much nearer the next town step than you are (setting: deathSkip)
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- This program is free software: you can redistribute it and/or modify it under the terms of the
-- GNU General Public License as published by the Free Software Foundation, version 3.
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
-- even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details. The complete license text is in LICENSE.
--
-- A line in the step window only; it never does anything for you. Shown when all of these hold:
--   * not a Hardcore character (ns:IsHardcore: a death there is permanent), alive, not on a flight, not in an
--     instance, and the hearthstone suggestion (Core/Hearth.lua) is not showing (hearthing costs nothing);
--   * the current step is a town step (TOWN_KINDS: turn-ins, pick-ups, trainers, vendors ...) with a position;
--   * a spirit healer of the zone you are in (Database/Questie/SpiritHealers.lua) is the one nearest to you,
--     which is where the game sends your ghost, and it is nearer that step than you are;
--   * dying saves enough time: MIN_SAVED_LOW seconds below level LOW_LEVEL, where the spirit healer gives no
--     resurrection sickness; MIN_SAVED (5 minutes) from that level on, where it does.
-- Time saved: the walk to the step, minus DEATH_SECONDS (finding a mob, dying, the resurrection) and the walk
-- from the graveyard to the step. Walks are the straight line x PATH_FACTOR at your run speed, as for the
-- hearthstone. Both deaths and the spirit healer cost gear durability; the line says so.
-- Facts: no resurrection sickness up to level 10 (https://warcraft.wiki.gg/wiki/Resurrection_sickness, v=0).

local _, ns = ...

local D = { current = nil }
ns.DeathSkip = D

local C = ns.Compat
local LOW_LEVEL = 10         -- below this level: no resurrection sickness
local MIN_SAVED_LOW = 60     -- seconds a death skip must save below LOW_LEVEL
local MIN_SAVED = 300        -- ...and from LOW_LEVEL on
local DEATH_SECONDS = 45     -- finding a mob to die to, releasing, the resurrection
local CHECK = 5
local TOWN_KINDS = { turnin = true, accept = true, train = true, buy = true, bind = true, fp = true, talk = true }

local function prof() return ns.db.profile end
local function dbg(msg) ns:Debug("death skip: " .. msg) end

local function inInstance()
    if not IsInInstance then return false end
    local inside, kind = IsInInstance()
    return inside and kind ~= "none"
end

-- The spirit healer of `area` nearest to `me` (world position), and how far it is.
local function nearestHealer(area, me)
    local best, bestD
    local map = ns.DB.ZoneUiMap(area)
    for _, p in ipairs(map and ns.QDB.spiritHealers and ns.QDB.spiritHealers[area] or {}) do
        local w = ns.Hearth.World(map, p[1], p[2])
        local d = ns.Hearth.Yards(me, w)
        if d and (not bestD or d < bestD) then best, bestD = w, d end
    end
    return best, bestD
end

-- Seconds a death skip must save at this level.
function D.Needed(level)
    return (level or 0) < LOW_LEVEL and MIN_SAVED_LOW or MIN_SAVED
end

-- The suggestion for the current step: { saved (seconds), sickness (bool) }, or nil and a reason. No side effects.
function D:Suggest()
    if not prof().deathSkip then return nil, "setting off" end
    if ns:IsHardcore() then return nil, "Hardcore" end
    local s = ns.Engine and ns.Engine:CurrentStep()
    if not (s and TOWN_KINDS[s[1]]) then return nil, "not a town step" end
    if UnitIsDeadOrGhost and UnitIsDeadOrGhost("player") then return nil, "dead" end
    if inInstance() then return nil, "in an instance" end
    if UnitOnTaxi and UnitOnTaxi("player") then return nil, "on a flight" end
    if ns.Hearth and ns.Hearth.current then return nil, "hearthstone suggested" end
    local z, x, y = ns.StepText:Target(s)
    local m = z and ns.DB.ZoneUiMap(z)
    local target = m and ns.Hearth.World(m, x, y)
    if not target then return nil, "the step has no position" end
    local pMap, px, py = C.GetPlayerMapPosition()
    if not px then return nil, "no player position" end
    local me = ns.Hearth.World(pMap, px, py)
    local walk = ns.Hearth.Yards(me, target)
    if not walk then return nil, "the step is on another continent" end
    local area = ns.DB.AreaForUiMap(pMap)
    local healer = area and nearestHealer(area, me)
    if not healer then return nil, "no spirit healer in this zone" end
    local speed = ns.Hearth.RunSpeed()
    local saved = (walk - (ns.Hearth.Yards(healer, target) or math.huge)) * ns.Hearth.PATH_FACTOR / speed - DEATH_SECONDS
    local level = UnitLevel and UnitLevel("player") or 1
    if saved < self.Needed(level) then
        return nil, string.format("saves %d s, level %d needs %d s", math.floor(saved), level, self.Needed(level))
    end
    return { saved = saved, sickness = level >= LOW_LEVEL }
end

-- The step window line, or nil.
function D:Line()
    local d = self.current
    if not d then return nil end
    local m = math.floor(d.saved / 60 + 0.5)
    local saves = m <= 1 and "about a minute" or ("about " .. m .. " min")
    return string.format("Death skip: the graveyard is near this step. Dying to a mob and taking the spirit healer's resurrection saves %s of walking. %s",
        saves, d.sickness and "It gives resurrection sickness and costs gear durability."
            or "Below level 10 there is no resurrection sickness; your gear still loses durability.")
end

-- Re-checks the suggestion; redraws the guide window when the line changes.
function D:Check()
    local d, why = self:Suggest()
    local before = self:Line()
    self.current = d
    self.why = why
    if self:Line() ~= before then
        dbg(d and ("suggest, saves " .. math.floor(d.saved) .. " s") or ("none: " .. tostring(why)))
        ns:Fire("REFRESH")
    end
end

function D:Init()
    ns:Listen("STEP_CHANGED", function() D:Check() end)
    local acc = 0
    local f = CreateFrame("Frame")
    f:SetScript("OnUpdate", function(_, elapsed)
        acc = acc + elapsed
        if acc < CHECK then return end
        acc = 0
        D:Check()
    end)
end
