-- Questwarden - human-readable step text and navigation targets
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- This program is free software: you can redistribute it and/or modify it under the terms of the
-- GNU General Public License as published by the Free Software Foundation, version 3.
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
-- even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details. The complete license text is in LICENSE.

local _, ns = ...

local StepText = {}
ns.StepText = StepText

local DIM = "|cff999999%s|r"
-- Colours are profile settings (Look and Feel > Text); these wrap a string in them.
local function hex(c, def)
    c = type(c) == "table" and c or def
    return string.format("|cff%02x%02x%02x%%s|r", math.floor(c.r * 255 + 0.5), math.floor(c.g * 255 + 0.5), math.floor(c.b * 255 + 0.5))
end
local QUEST, NPC, WARN
local function refreshColours()
    local p = ns.db and ns.db.profile or {}
    QUEST = hex(p.colorQuest, { r = 1, g = 0.82, b = 0 })
    NPC = hex(p.colorFriendly, { r = 0.4, g = 0.8, b = 1 })
    WARN = hex(p.colorWarning, { r = 1, g = 0.47, b = 0.27 })
end
refreshColours()

local function questName(s)
    return (s.q and ns.DB.GetQuestName(s.q)) or s.title or ("quest " .. tostring(s.q))
end

local function fmtCoords(s)
    if s.x and s.y then
        local zn = s.z and ns.DB.ZoneName(s.z)
        return string.format("%.1f, %.1f%s", s.x, s.y, zn and (" " .. zn) or "")
    end
    return nil
end

-- Main line of a step.
function StepText:Title(s)
    refreshColours()
    local k = s[1]
    if k == "accept" and s.starter and ns.ItemStarts then
        local t = ns.ItemStarts:Title(s, function(x) return string.format(QUEST, x) end, function(x) return "[" .. x .. "]" end)
        if t then return t end
    end
    if k == "accept" then
        local who = s.npc and (" from " .. string.format(NPC, s.npc)) or ""
        return "Accept " .. string.format(QUEST, questName(s)) .. who
    elseif k == "turnin" then
        local who = s.npc and (" to " .. string.format(NPC, s.npc)) or ""
        return "Turn in " .. string.format(QUEST, questName(s)) .. who
    elseif k == "complete" then
        if ns.DungeonRun:RunPhase(s) then return ns.DungeonRun:Title(s.dungeon) end
        return "Complete " .. string.format(QUEST, questName(s))
    elseif k == "dungeon" then
        return ns.DungeonRun:Title(s.dungeon)
    elseif k == "goto" then
        return s.text or ("Go to " .. (fmtCoords(s) or "the marked location"))
    elseif k == "train" then
        local npc, plan = s.npc, nil
        if ns.Trainer then
            local _, _, _, name, p = ns.Trainer:TrainerFor(s)
            npc, plan = name or npc, p
        end
        if plan then
            return "Train new skills at " .. string.format(NPC, tostring(plan.trainer)) .. ": fly to " .. ns.Flights.nodes[plan.to].name
        end
        return "Train new skills" .. (npc and (" at " .. string.format(NPC, npc)) or " at your class trainer")
    elseif k == "fp" then
        return "Get the flight path" .. (s.place and (" at " .. s.place) or "") .. (s.npc and (" (" .. string.format(NPC, s.npc) .. ")") or "")
    elseif k == "fly" then
        return "Fly to " .. (s.dest or "?")
    elseif k == "hs" then
        return "Use your Hearthstone" .. (s.dest and (" to " .. s.dest) or "")
    elseif k == "bind" then
        return "Set your Hearthstone at " .. (s.place or "the inn") .. (s.npc and (" (" .. string.format(NPC, s.npc) .. ")") or "")
    elseif k == "level" then
        return "Reach level " .. tostring(s.level)
    elseif k == "grind" then
        local mobs = type(s.mobs) == "table" and #s.mobs > 0 and table.concat(s.mobs, ", ") or "mobs"
        return "Grind " .. mobs .. (s.location and (" at " .. s.location) or "") .. " until level " .. tostring(s.level)
            .. (s.pct and (" (" .. s.pct .. "% through)") or "")
    elseif k == "talk" then
        return "Talk to " .. string.format(NPC, s.npc or "?")
    elseif k == "guide" then
        local g = ns.Guides:Get(s.guide)
        return "Continue with: " .. (g and g.name or tostring(s.guide))
    end
    return s.text or k
end

-- Detail lines (objectives, notes, warnings) under the title.
function StepText:Details(s)
    refreshColours()
    local lines = {}
    -- Outside the dungeon a dungeon quest's objective step is the "time to run it" note (Core/DungeonRun.lua).
    if (s[1] == "complete" and ns.DungeonRun:RunPhase(s)) or s[1] == "dungeon" then
        lines[#lines + 1] = ns.DungeonRun:Note(s.dungeon)
        if s.q then lines[#lines + 1] = string.format(DIM, "For " .. questName(s) .. ".") end
    end
    if s[1] == "complete" and s.q then
        local e = ns.Tracker:GetEntry(s.q)
        if e and #e.objectives > 0 then
            for i, o in ipairs(e.objectives) do
                if not s.obj or s.obj == i then
                    lines[#lines + 1] = (o.done and "|cff55ff55- " or "|cffffffff- ") .. (o.text or "?") .. "|r"
                end
            end
            local route = ns.Roam and ns.Roam.active and ns.Roam:StatusLine()
            if route then lines[#lines + 1] = string.format(DIM, route) end
        else
            local _, text = ns.DB.GetQuestObjectives(s.q)
            if text and text ~= "" then lines[#lines + 1] = string.format(DIM, text) end
            if not e and not ns.Tracker:IsTurnedIn(s.q) then
                lines[#lines + 1] = string.format(WARN, "Quest is not in your log.")
            end
        end
    elseif s[1] == "turnin" and s.q and not ns.Tracker:InLog(s.q) and not ns.Tracker:IsTurnedIn(s.q) then
        lines[#lines + 1] = string.format(WARN, "Quest is not in your log - skip this step if you did not take it.")
    elseif s[1] == "train" and ns.Trainer then
        local plan = select(5, ns.Trainer:TrainerFor(s))
        if plan then lines[#lines + 1] = string.format(WARN, ns.Trainer.FlightText(plan)) end
        for _, l in ipairs(ns.Trainer:Lines(6)) do lines[#lines + 1] = l end
    elseif s[1] == "level" or s[1] == "grind" then
        local xp, maxXp = UnitXP("player"), UnitXPMax("player")
        if maxXp and maxXp > 0 then
            lines[#lines + 1] = string.format(DIM, string.format("Level %d, %d%% through", UnitLevel("player"), math.floor(xp / maxXp * 100)))
        end
    end
    -- A fly step: what to do without the flight path.
    if s[1] == "fly" and s.node then
        local unknown = StepText.FlightUnknown(s)
        if unknown == true then
            lines[#lines + 1] = string.format(WARN, "You don't have the flight path to " .. (s.dest or "?") .. " yet: run there instead. The arrow points to it.")
        elseif unknown == nil then
            lines[#lines + 1] = string.format(DIM, "No flight path to " .. (s.dest or "?") .. " yet? Run there instead; the step completes when you arrive.")
        end
    end
    -- A quest given or taken by an object (a wanted poster, a grave, a book), not an NPC.
    local giver = StepText.ObjectGiverLine(s)
    if giver then lines[#lines + 1] = giver end
    -- Quests that start from a dropped item (Core/ItemStarts.lua).
    if ns.ItemStarts then
        for _, l in ipairs(ns.ItemStarts:Lines(s, s.index, ns.Engine:CurrentStep() == s)) do
            lines[#lines + 1] = string.format(l.warn and WARN or DIM, l.text)
        end
    end
    -- Timed quests (Core/QuestTimer.lua): the warning before you accept, then the time left.
    if s.q and ns.QuestTimer and ns.QuestTimer:Limit(s.q) and not ns.Tracker:IsTurnedIn(s.q) then
        local l = (s[1] == "accept" and not ns.Tracker:InLog(s.q) and ns.QuestTimer:WarningText(s.q))
            or ((s[1] == "complete" or s[1] == "turnin") and ns.QuestTimer:StepLine(s.q))
        if l then lines[#lines + 1] = string.format(WARN, l) end
    end
    -- Hearthing to town beats walking (Core/Hearth.lua).
    local current = ns.Engine:CurrentStep() == s
    local hearth = ns.Hearth and current and ns.Hearth:Line()
    if hearth then lines[#lines + 1] = string.format(WARN, hearth) end
    -- Dying and the spirit healer beat walking (Core/DeathSkip.lua).
    local skip = ns.DeathSkip and current and ns.DeathSkip:Line()
    if skip then lines[#lines + 1] = string.format(WARN, skip) end
    -- Food, drink and ammo before you leave town (Core/Supplies.lua).
    local supplies = ns.Supplies and current and ns.Supplies:Line()
    if supplies then lines[#lines + 1] = string.format(WARN, supplies) end
    -- Party members' steps (Core/PlayTogether.lua) and the mount savings goal (Core/MountGoal.lua).
    if current and ns.PlayTogether then
        for _, l in ipairs(ns.PlayTogether:Lines()) do lines[#lines + 1] = string.format(l.warn and WARN or DIM, l.text) end
    end
    local goal = current and ns.MountGoal and ns.MountGoal:Line()
    if goal then lines[#lines + 1] = string.format(DIM, goal) end
    -- A quest NPC that walks a path (Core/Patrol.lua).
    if ns.Patrol then
        for i, l in ipairs(ns.Patrol:Lines(s)) do lines[#lines + 1] = string.format(i == 1 and WARN or DIM, l) end
    end
    if s.text and s[1] ~= "goto" and s[1] ~= "note" and s[1] ~= "travel" then
        lines[#lines + 1] = s.text
    end
    local tags = {}
    if s.elite then tags[#tags + 1] = "Elite" end
    if s.group then tags[#tags + 1] = "Group quest" .. (type(s.group) == "number" and (" (" .. s.group .. ")") or "") end
    if s.dungeon then tags[#tags + 1] = "Dungeon: " .. tostring(s.dungeon) end
    if #tags > 0 then lines[#lines + 1] = string.format(WARN, table.concat(tags, " - ")) end
    if s.optional then
        lines[#lines + 1] = string.format(WARN, "Optional: the route works without this quest. Do it for the extra experience and reward, or right-click the step to skip it.")
    end
    -- Cities, buildings and caves the straight-line arrow does not know about (Core/NavHints.lua).
    if ns.NavHints then
        for _, h in ipairs(ns.NavHints:Lines(s, ns.Engine:CurrentStep() == s)) do lines[#lines + 1] = string.format(WARN, h) end
    end
    local c = fmtCoords(s)
    if c and s[1] ~= "goto" then lines[#lines + 1] = string.format(DIM, c) end
    return lines
end

-- Objective progress of a kill/collect step from 0 to 1, or nil when there is nothing to count. Each
-- objective counts as its own share: "Wolf Meat: 3/8" as 3/8, a done objective as 1, others as 0.
-- What an object quest giver is, from its name: a wanted poster, a notice board, else any object.
local function objectKind(name)
    local n = string.lower(name or "")
    if n:find("wanted", 1, true) or n:find("bounty", 1, true) then return "a wanted poster, on a post or board" end
    if n:find("board", 1, true) or n:find("notice", 1, true) then return "a notice board" end
    return "an object in the world"
end

-- For an accept or turn-in step whose quest has no NPC giver (or taker) but an object: how to use it. Nil otherwise.
function StepText.ObjectGiverLine(s)
    if not (s and s.q and (s[1] == "accept" or s[1] == "turnin")) then return nil end
    local npcs, objs
    if s[1] == "accept" then npcs, objs = ns.DB.GetQuestStartNPCs(s.q) else npcs, objs = ns.DB.GetQuestEndNPCs(s.q) end
    if (npcs and npcs[1]) or not (objs and objs[1]) then return nil end
    local name = ns.DB.GetObjectName(objs[1]) or s.npc or "It"
    if s[1] == "accept" then
        return string.format("%s is not an NPC but %s. Right-click it to read the quest, then press Accept.", name, objectKind(name))
    end
    return string.format("%s is not an NPC but %s. Right-click it to hand in the quest.", name, objectKind(name))
end

function StepText:Progress(s)
    if not (s and s[1] == "complete" and s.q) then return nil end
    local e = ns.Tracker:GetEntry(s.q)
    if not (e and #e.objectives > 0) then return nil end
    local sum, n = 0, 0
    for i, o in ipairs(e.objectives) do
        if not s.obj or s.obj == i then
            local have, need = string.match(o.text or "", "(%d+)%s*/%s*(%d+)")
            have, need = tonumber(have), tonumber(need)
            sum = sum + ((o.done and 1) or (need and need > 0 and math.min(1, have / need)) or 0)
            n = n + 1
        end
    end
    return n > 0 and sum / n or nil
end

-- Navigation target for a step: zoneAreaId, x, y, label. Uses compiled coordinates first and
-- falls back to live database lookups for quest steps.
-- Whether a fly step's flight path is one you do not have: true or false once a flight map has shown the paths you
-- know (Core/FlightPaths.lua), nil before that.
function StepText.FlightUnknown(s)
    local n = s.node and ns.Flights and ns.Flights.nodes[s.node]
    if not (n and ns.FlightPaths and ns.char) then return nil end
    local known = ns.FlightPaths:Known()
    if next(known) == nil then return nil end
    return not known[s.node]
end

function StepText:Target(s)
    -- Train steps: the class trainer nearest to you, else the one the guide names (Classes/Trainer.lua).
    if s[1] == "train" and ns.Trainer then
        local z, x, y, name = ns.Trainer:TrainerFor(s)
        if z then return z, x, y, name end
    end
    -- An item-started pickup: the nearest NPC that drops the item, while you still need it.
    if s.starter and ns.ItemStarts then
        local st = ns.ItemStarts:State(s)
        if st == "have" or st == "accepted" or st == "done" then return nil end
        local z, x, y, label = ns.ItemStarts:Target(s)
        if z then return z, x, y, label end
    end
    -- A flight you do not have yet: run to its destination instead.
    if s[1] == "fly" and StepText.FlightUnknown(s) == true then
        local n = ns.Flights.nodes[s.node]
        return n.zone, n.x, n.y, n.name
    end
    if s.x and s.y and s.z then
        if s[1] == "grind" then return s.z, s.x, s.y, s.location or (s.mobs and s.mobs[1]) end
        return s.z, s.x, s.y, s.npc or s.text
    end
    -- A dungeon run you are not in yet: its nearest entrance (none when the data has no entrance).
    if s[1] == "dungeon" or (s[1] == "complete" and ns.DungeonRun:RunPhase(s)) then return ns.DungeonRun:Entrance(s.dungeon) end
    if not s.q then return nil end
    if s[1] == "accept" then
        local npcs = ns.DB.GetQuestStartNPCs(s.q)
        if npcs[1] then
            local z, x, y = ns.DB.GetNPCPosition(npcs[1])
            if z then return z, x, y, ns.DB.GetNPCName(npcs[1]) end
        end
    elseif s[1] == "turnin" then
        local npcs, objs = ns.DB.GetQuestEndNPCs(s.q)
        if npcs[1] then
            local z, x, y = ns.DB.GetNPCPosition(npcs[1])
            if z then return z, x, y, ns.DB.GetNPCName(npcs[1]) end
        end
        if objs[1] then
            local z, x, y = ns.DB.GetObjectPosition(objs[1])
            if z then return z, x, y, ns.DB.GetObjectName(objs[1]) end
        end
    elseif s[1] == "complete" then
        -- Two or more open steps of the current kill pack: where their mobs meet (Core/Roam.lua).
        local pz, pkx, pky, plabel = ns.Roam:PackTarget(s)
        if pz then return pz, pkx, pky, plabel end
        local px, py
        local mapId, mx, my = ns.Compat.GetPlayerMapPosition()
        local area = mapId and ns.DB.AreaForUiMap(mapId)
        if mx then px, py = mx, my end
        -- Objectives your log shows done are left out: the arrow moves on to the next one.
        -- An item the objectives need that is not in the bags: where it drops first (Marla's Last Wish).
        local z, x, y, label = ns.DB.GetObjectiveLocation(s.q, area, px, py, function(name) return ns.Tracker:ObjectiveNameDone(s.q, name) end,
            function(itemId) return ns.Compat.BagItemCount(itemId) > 0 end)
        if z then return z, x, y, label end
    end
end
