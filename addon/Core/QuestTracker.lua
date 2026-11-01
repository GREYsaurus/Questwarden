-- Questwarden - live quest log tracking
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- This program is free software: you can redistribute it and/or modify it under the terms of the
-- GNU General Public License as published by the Free Software Foundation, version 3.
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
-- even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details. The complete license text is in LICENSE.
--
-- The bundled database says what quests EXIST; this module says what the character actually
-- HAS (quest log) and HAS DONE (completion flags + turn-ins seen this session).

local _, ns = ...

local Tracker = { log = {}, turnedIn = {}, lastScan = 0 }
ns.Tracker = Tracker

function Tracker:Scan()
    local ok, result = pcall(ns.Compat.ScanQuestLog)
    if ok and result then
        self.log = result
    else
        ns:Error("quest log scan failed: " .. tostring(result))
    end
    self.lastScan = GetTime()
    ns:Fire("QUESTS_CHANGED")
end

function Tracker:InLog(questId)
    return questId and self.log[questId] ~= nil
end

function Tracker:IsComplete(questId)
    local e = questId and self.log[questId]
    return e and e.complete or false
end

function Tracker:ObjectiveDone(questId, objIndex)
    local e = questId and self.log[questId]
    if not e then return false end
    local o = e.objectives[objIndex]
    return o and o.done or false
end

-- The objective NPCs of a quest in your log (DB.ObjectiveNpcIds) without those of objectives the log shows done: a kill
-- objective by its creature's name ("Rockjaw Trogg slain: 6/6"), an item objective by the item's name (its droppers,
-- unless they also drop an item or are a kill you still need). Text that names neither (kill credit, another client
-- language) keeps its NPCs. nil when the quest is not in your log; an empty table when nothing is left to kill.
function Tracker:OpenObjectiveNpcIds(questId, zone)
    local e = questId and self.log[questId]
    if not e then return nil end
    local ids = ns.DB.ObjectiveNpcIds(questId, zone) or {}
    local doneText = {}
    for _, o in ipairs(e.objectives or {}) do
        if o.done and type(o.text) == "string" then doneText[#doneText + 1] = o.text end
    end
    local q = ns.DB.GetQuestByID(questId)
    if #doneText == 0 or not q then return ids end
    local function done(name)
        if not name then return false end
        for _, t in ipairs(doneText) do
            if string.sub(t, 1, #name + 1) == name .. ":" or string.sub(t, 1, #name + 6) == name .. " slain" then return true end
        end
        return false
    end
    local drop, keep = {}, {}
    for _, id in ipairs(q.objectives.creatures) do
        if done(ns.DB.GetNPCName(id)) then drop[id] = true else keep[id] = true end
    end
    for _, itemId in ipairs(q.objectives.items) do
        local it = ns.DB.GetItemByID(itemId)
        local finished = done(ns.DB.GetItemName(itemId))
        for _, n in ipairs(it and it.npcDrops or {}) do
            if finished then drop[n] = true else keep[n] = true end
        end
    end
    local out = {}
    for id in pairs(ids) do
        if keep[id] or not drop[id] then out[id] = true end
    end
    return out
end

function Tracker:IsTurnedIn(questId)
    if not questId then return false end
    if self.turnedIn[questId] then return true end
    return ns.Compat.IsQuestCompleted(questId)
end

function Tracker:GetEntry(questId) return questId and self.log[questId] end

function Tracker:Count()
    local n = 0
    for _ in pairs(self.log) do n = n + 1 end
    return n
end

-- Context used by DB.IsQuestAvailable
function Tracker:Context()
    local info = ns.Compat.PlayerInfo()
    info.isCompleted = function(id) return Tracker:IsTurnedIn(id) end
    info.inLog = function(id) return Tracker:InLog(id) end
    return info
end

local function rescan() Tracker:Scan() end

function Tracker:Init()
    ns:On("QUEST_LOG_UPDATE", function() ns:Throttle("questscan", 0.3, rescan) end)
    ns:On("UNIT_QUEST_LOG_CHANGED", function(_, unit)
        if unit == "player" then ns:Throttle("questscan", 0.3, rescan) end
    end)
    ns:On("QUEST_ACCEPTED", function(_, a, b)
        -- Classic: (questLogIndex, questId); some builds: (questId)
        local questId = b or a
        ns:Debug("accepted " .. tostring(questId))
        ns:Throttle("questscan", 0.1, rescan)
    end)
    ns:On("QUEST_TURNED_IN", function(_, questId)
        if questId then Tracker.turnedIn[questId] = true end
        ns:Debug("turned in " .. tostring(questId))
        ns:Throttle("questscan", 0.1, rescan)
    end)
    ns:On("QUEST_REMOVED", function() ns:Throttle("questscan", 0.2, rescan) end)
    self:Scan()
end
