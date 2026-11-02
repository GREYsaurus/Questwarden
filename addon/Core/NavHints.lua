-- Questwarden - navigation hints: cities, buildings and caves the straight-line arrow does not know about
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- This program is free software: you can redistribute it and/or modify it under the terms of the
-- GNU General Public License as published by the Free Software Foundation, version 3.
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
-- even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details. The complete license text is in LICENSE.
--
-- The arrow points in a straight line. Questwarden has no paths through cities (no such data in its sources), so
-- instead of guessing a route it says when the straight line will mislead you:
--   * the target is in a capital city: follow the streets;
--   * you are in a capital and the target is outside it: leave the city first.
-- Capitals are found by name in the zone data, so ids are never typed by hand. (Hints about being indoors or a
-- target inside a building were removed in 0.1.0-alpha.32: the game's indoor flag did not tell them apart well.)

local _, ns = ...

local NH = {}
ns.NavHints = NH

local CAPITAL_NAMES = { "Stormwind City", "Ironforge", "Darnassus", "Orgrimmar", "Thunder Bluff", "Undercity",
                        "Shattrath City", "Silvermoon City", "The Exodar" }

local capitals
function NH:Capitals()
    if not capitals then
        capitals = {}
        local wanted = {}
        for _, n in ipairs(CAPITAL_NAMES) do wanted[n] = true end
        for id, name in pairs(ns.QDB.zones.names or {}) do
            if wanted[name] then capitals[id] = name end
        end
    end
    return capitals
end
function NH:ResetCache() capitals = nil end

-- The capital an area id belongs to (itself or a parent), or nil.
function NH:CapitalOf(area)
    if not area then return nil end
    local caps = self:Capitals()
    return caps[area] or caps[ns.DB.ParentZone(area) or -1]
end

-- Lines for a step. Hints about where you are (in a city) only for the step being navigated (`current`).
-- `here` = { zone, x, y } is passed in by the caller, or worked out.
function NH:Lines(s, current, here)
    local out = {}
    if not s then return out end
    local area, _, _, label = ns.StepText:Target(s)
    if not area then return out end
    label = label or "the target"
    local city = self:CapitalOf(area)
    local hz = here and here[1]
    if current and hz == nil then
        local z = ns.Completionist:Here()
        hz = z
    end
    local inCity = current and self:CapitalOf(hz)
    if current and inCity and inCity ~= city then
        out[#out + 1] = string.format("Leave %s first: the arrow points straight at %s, not along the streets to the city exit.", inCity, label)
    elseif city then
        out[#out + 1] = string.format("%s is in %s: follow the streets and bridges; the arrow only shows the direction.", label, city)
    end
    return out
end

-- One short line under the arrow for the current waypoint, or nil.
function NH:ArrowLine()
    local s = ns.Engine and ns.Engine:CurrentStep()
    local t = ns.Nav.target
    if not (s and t) then return nil end
    local inCity = self:CapitalOf(ns.Completionist:Here())
    local city = self:CapitalOf(t.area)
    if inCity and inCity ~= city then return "Leave " .. inCity .. " first" end
    if city then return "In " .. city .. ": follow the streets" end
    return nil
end
