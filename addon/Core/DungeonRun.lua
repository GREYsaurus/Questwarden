-- Questwarden - dungeon runs: "time to run a dungeon" notes, the entrance waypoint and entering detection
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- This program is free software: you can redistribute it and/or modify it under the terms of the
-- GNU General Public License as published by the Free Software Foundation, version 3.
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
-- even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details. The complete license text is in LICENSE.
--
-- A dungeon quest's objective step ("complete", tagged [dungeon=...]) has two stages, worked out from where you
-- are, so saved step progress never changes:
--   * outside the dungeon: a note that it is time to run it and find a group, with the arrow on the entrance;
--   * inside it: the quest's objectives, as before.
-- Completionist's run step (step type "dungeon") ends when you enter. A ghost who died inside a dungeon gets the
-- arrow on its entrance (Core/Corpse.lua). Entrances: Database/DungeonEntrances.lua (QuestieDB); a dungeon
-- without one gets the note and no arrow, never a guessed position.
--
-- Inside which dungeon: IsInInstance, then the map you are on (C_Map) -> its area id -> the dungeon whose
-- instance areas include it. That works in every client language. If the client gives no map inside an
-- instance, the dungeon of the step you were sent there for counts.

local _, ns = ...

local DR = { inside = nil }
ns.DungeonRun = DR

local byArea
local function areaIndex()
    if not byArea then
        byArea = {}
        for name, e in pairs(ns.DungeonEntrances or {}) do
            for _, a in ipairs(e.areas or {}) do byArea[a] = name end
        end
    end
    return byArea
end
-- Forget the area index (data swapped in tests).
function DR:ResetCache() byArea = nil end

function DR:HasEntrance(name)
    local e = name and ns.DungeonEntrances and ns.DungeonEntrances[name]
    return e and e.points and #e.points > 0 or false
end

-- The entrance nearest to you: zone, x, y, label; nil when the data has none. Several entrances (Blackrock
-- Mountain from two zones, Dire Maul's wings, Stratholme's gates): the nearest by world distance.
function DR:Entrance(name)
    if not self:HasEntrance(name) then return nil end
    local pts = ns.DungeonEntrances[name].points
    local best, bestD = pts[1], math.huge
    if #pts > 1 and ns.Completionist then
        local hz, hx, hy = ns.Completionist:Here()
        if hz then
            for _, p in ipairs(pts) do
                local d = ns.Completionist:Distance(hz, hx, hy, p[1], p[2], p[3])
                if d < bestD then best, bestD = p, d end
            end
        end
    end
    return best[1], best[2], best[3], name .. " entrance"
end

-- The dungeon of a guide step that sends you into one, if any.
local function stepDungeon(s)
    if not s then return nil end
    if s[1] == "dungeon" then return s.dungeon end
    if s[1] == "complete" and s.dungeon then return s.dungeon end
end

-- The listed dungeon you are in, or nil.
function DR:Current()
    if not IsInInstance then return nil end
    local inside = IsInInstance()
    if not inside then return nil end
    local mapId = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    local area = mapId and ns.DB.AreaForUiMap(mapId)
    local idx = areaIndex()
    local name = area and (idx[area] or idx[ns.DB.ParentZone(area) or -1])
    if name then return name end
    if area then return nil end -- a known map that is not a listed dungeon (raid, battleground)
    return stepDungeon(ns.Engine and ns.Engine:CurrentStep())
end

-- A quest objective step of a dungeon you are not in yet: shown as the "time to run it" note.
function DR:RunPhase(s)
    if not (s and s[1] == "complete" and s.dungeon and s.q) then return false end
    local T = ns.Tracker
    if not T:InLog(s.q) or T:IsComplete(s.q) or T:IsTurnedIn(s.q) then return false end
    return self.inside ~= s.dungeon
end

function DR:Title(name)
    return "Run " .. tostring(name) .. ": find a group"
end

-- The note under the title.
function DR:Note(name)
    local where = self:HasEntrance(name) and "then follow the arrow to the entrance"
        or "then go to the entrance (" .. ns.name .. " has no position for it)"
    return "Time to run " .. tostring(name) .. ". Find a group (Looking for Group channel, your guild, or the meeting stone near it), "
        .. where .. ". This moves on when you enter the dungeon."
end

-- Called on zone changes: tells the engine and Completionist when you enter or leave a dungeon.
function DR:Update()
    local now = self:Current()
    if now == self.inside then return end
    local was = self.inside
    self.inside = now
    ns:Debug("dungeon: " .. tostring(was) .. " -> " .. tostring(now))
    ns:Fire("DUNGEON_CHANGED", now, was)
end

function DR:Init()
    local function update() DR:Update() end
    ns:On("PLAYER_ENTERING_WORLD", function() C_Timer.After(1, update) end)
    ns:On("ZONE_CHANGED_NEW_AREA", update)
    ns:On("ZONE_CHANGED_INDOORS", update)
    ns:Listen("DUNGEON_CHANGED", function()
        if ns.Engine.guide then
            ns.Engine:Refresh()
            ns.Nav:FromStep(ns.Engine:CurrentStep())
        end
    end)
end
