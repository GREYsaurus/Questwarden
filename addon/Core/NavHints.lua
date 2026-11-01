-- Questwarden - navigation hints: cities, buildings and caves the straight-line arrow does not know about
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- This program is free software: you can redistribute it and/or modify it under the terms of the
-- GNU General Public License as published by the Free Software Foundation, version 3.
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
-- even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details. The complete license text is in LICENSE.
--
-- The arrow points in a straight line. Questwarden has no paths through cities or into buildings (no such data
-- in its sources), so instead of guessing a route it says when the straight line will mislead you:
--   * the target is in a capital city: follow the streets;
--   * you are in a capital and the target is outside it: leave the city first;
--   * you are indoors (the game's IsIndoors) and the target is not right here: "find the way out" when the target is
--     known to be outside (you stood at it outdoors before); otherwise only that the arrow shows the direction, since
--     the target may be outside or in another room;
--   * the target is inside a building, cave or mine: look for the entrance. Known from the guide's own step text
--     (words like "cave", "inside", "upstairs", or "in the inn"), or learned: standing within OBSERVE_YARDS of a
--     target records whether you are indoors there (QuestwardenDB.indoorSpots, all characters). A spot ever seen
--     outdoors (a doorway, say) never counts as inside, so an NPC by a door is not called indoors.
-- Capitals are found by name in the zone data, so ids are never typed by hand.

local _, ns = ...

local NH = {}
ns.NavHints = NH

local CAPITAL_NAMES = { "Stormwind City", "Ironforge", "Darnassus", "Orgrimmar", "Thunder Bluff", "Undercity",
                        "Shattrath City", "Silvermoon City", "The Exodar" }
-- Words that mean "indoors" wherever they appear, and building words that do only after "in the" / "top of the".
-- Words that put the target indoors on their own, and places that do so only after "in"/"into" (within three
-- words: "in the bear cave", "in the inn") or "top of"/"back of" ("top of the abbey bell tower", "at the back of
-- the troll cave"). A
-- place merely named ("Echo Ridge Mine is north of the abbey", "at the Silver Stream Mine") says nothing: such
-- mobs are often outside the entrance as well.
local INDOOR_WORDS = { "inside", "upstairs", "downstairs", "basement", "cellar", "indoors" }
local PLACE_WORDS = { "cave", "caves", "cavern", "caverns", "mine", "mines", "crypt", "crypts", "barrow", "barrows",
                      "grotto", "burrow", "burrows", "inn", "tower", "keep", "house", "hut", "abbey", "cathedral", "lair",
                      "den", "building", "hall", "bunker", "barracks", "chapel", "church", "castle", "fortress", "tavern",
                      "library", "tomb" }
local NEAR_YARDS = 15 -- indoors closer than this to the target: you are probably in the right room already
local OBSERVE_YARDS = 5 -- only this close to a target does indoors/outdoors say where the target is

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

local set
local function wordSet()
    if not set then
        set = { always = {}, building = {} }
        for _, w in ipairs(INDOOR_WORDS) do set.always[w] = true end
        for _, w in ipairs(PLACE_WORDS) do set.building[w] = true end
    end
    return set
end

-- Whether a step's own text says its target is indoors (not just where it is).
function NH:TextSaysIndoors(s)
    local text = string.lower(table.concat({ s.text or "", s.location or "" }, " "))
    if text == " " then return false end
    local w = wordSet()
    -- Sentences split at punctuation, so a place word never reaches across into the next clause.
    for clause in string.gmatch(text, "[^%.,;:!%?%(%)]+") do
        local words = {}
        for word in string.gmatch(clause, "[%a']+") do words[#words + 1] = word end
        for i, word in ipairs(words) do
            if w.always[word] then return true end
            local from
            -- "turned in" / "handed in" is about quests, not places
            if (word == "in" or word == "into") and words[i - 1] ~= "turned" and words[i - 1] ~= "handed" then from = i + 1
            elseif (word == "top" or word == "back") and words[i + 1] == "of" then from = i + 2 end
            if from then
                for j = from, math.min(from + 3, #words) do
                    if w.building[words[j]] then return true end
                end
            end
        end
    end
    return false
end

-- Learned indoor spots ------------------------------------------------------------------------------------------
local function spotKey(area, x, y)
    return string.format("%d:%d:%d", area, math.floor(x + 0.5), math.floor(y + 0.5))
end

local function spots()
    local db = ns.db
    if type(db.indoorSpots) ~= "table" then db.indoorSpots = {} end
    return db.indoorSpots
end

-- Indoors when a spot or a neighbour was seen indoors and none was ever seen outdoors (true/false per spot).
function NH:IsLearnedIndoor(area, x, y)
    if not (area and x and y) then return false end
    local s = spots()
    local cx, cy = math.floor(x + 0.5), math.floor(y + 0.5)
    local indoor = false
    for dx = -1, 1 do
        for dy = -1, 1 do
            local v = s[string.format("%d:%d:%d", area, cx + dx, cy + dy)]
            if v == false then return false end
            if v == true then indoor = true end
        end
    end
    return indoor
end

-- Whether a spot (or a neighbour) was seen outdoors while standing at it: the target is outside.
function NH:IsLearnedOutdoor(area, x, y)
    if not (area and x and y) then return false end
    local s = spots()
    local cx, cy = math.floor(x + 0.5), math.floor(y + 0.5)
    for dx = -1, 1 do
        for dy = -1, 1 do
            if s[string.format("%d:%d:%d", area, cx + dx, cy + dy)] == false then return true end
        end
    end
    return false
end

-- Called while the arrow is at the target: within OBSERVE_YARDS, records indoors or outdoors for the spot.
-- Outdoors is kept for good: a target reachable outdoors is never "inside".
function NH:Observe(target, dist)
    if not (target and target.area and target.x and target.y and dist and dist <= OBSERVE_YARDS and IsIndoors) then return end
    local key, s = spotKey(target.area, target.x, target.y), spots()
    if s[key] == false then return end
    s[key] = IsIndoors() and true or false
end

-- Hints ---------------------------------------------------------------------------------------------------------

-- Whether a step's target is indoors: its text says so, or you were indoors there before.
function NH:TargetIndoors(s, area, x, y)
    return self:TextSaysIndoors(s) or self:IsLearnedIndoor(area, x, y)
end

-- Lines for a step. Hints about where you are (in a city, indoors) only for the step being navigated (`current`).
-- `here` = { zone, x, y } and `dist` (yards to the target) are passed in by the caller, or worked out.
function NH:Lines(s, current, here, dist)
    local out = {}
    if not s then return out end
    local area, x, y, label = ns.StepText:Target(s)
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
    local learned = self:IsLearnedIndoor(area, x, y)
    local inside = learned or self:TextSaysIndoors(s)
    -- You indoors: "find the way out" only when the target is known to be outside (seen there before); otherwise it
    -- may be outside or in another room of the same building, so the hint stays neutral.
    if current and IsIndoors and IsIndoors() and not inside then
        if dist == nil then dist = ns.Nav.target and ns.Nav:Vector() end
        if not dist or dist > NEAR_YARDS then
            out[#out + 1] = self:IsLearnedOutdoor(area, x, y)
                and "You are indoors and the target is outside: find the way out of the building or cave first."
                or "You are indoors: the arrow shows only the direction. If it points through a wall, the target may be outside or in another room."
        end
    end
    if inside then
        out[#out + 1] = learned and string.format("%s is inside a building, cave or mine: look for the entrance near the arrow.", label)
            or string.format("%s may be inside (the step says so): look for the entrance near the arrow.", label)
    end
    return out
end

-- One short line under the arrow for the current waypoint (the most pressing hint), or nil.
function NH:ArrowLine()
    local s = ns.Engine and ns.Engine:CurrentStep()
    local t = ns.Nav.target
    if not (s and t) then return nil end
    local hz = ns.Completionist:Here()
    local inCity = self:CapitalOf(hz)
    local city = self:CapitalOf(t.area)
    if inCity and inCity ~= city then return "Leave " .. inCity .. " first" end
    local inside = t.area and self:TargetIndoors(s, t.area, t.x, t.y)
    if IsIndoors and IsIndoors() and not inside then
        local dist = ns.Nav:Vector()
        if not dist or dist > NEAR_YARDS then
            return self:IsLearnedOutdoor(t.area, t.x, t.y) and "Indoors: find the way out first" or "Indoors: arrow shows direction only"
        end
    end
    if inside then
        return self:IsLearnedIndoor(t.area, t.x, t.y) and "Target is inside: find the entrance" or "Target may be inside: find the entrance"
    end
    if city then return "In " .. city .. ": follow the streets" end
    return nil
end
