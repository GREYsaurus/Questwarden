-- Questwarden - quests started by an item that mobs drop (accept steps with starter=)
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- This program is free software: you can redistribute it and/or modify it under the terms of the
-- GNU General Public License as published by the Free Software Foundation, version 3.
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
-- even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details. The complete license text is in LICENSE.
--
-- The guide compiler gives such an accept step the item (starter=), the NPCs that drop it in the guide's
-- zone (drops=, from the bundled QuestieDB data) and the later steps of the guide that kill one of them
-- (via=). One state per step, from the quest log and your bags only:
--   done      the quest is turned in;
--   accepted  the quest is in your log (the item in your bags or an open quest window is not acceptance);
--   have      the item is in your bags, the quest is not taken: use the item and accept the quest;
--   waiting   the item is not in your bags and a via step is still ahead: the engine lets those steps go
--             first (Core/Engine.lua), since the item may drop there, and the pickup comes back when the
--             item turns up or when they are behind you;
--   farm      the item is not in your bags and no kill step is left: get it from the droppers, or skip.
-- Not available (race, class, level, an exclusive quest) is the engine's auto-skip, as for any pickup.
-- Bags are read on BAG_UPDATE_DELAYED only; the engine refreshes when a starter item comes or goes.

local _, ns = ...

local IS = { bags = {}, sig = nil }
ns.ItemStarts = IS

local C = ns.Compat
local T -- tracker

local function itemName(id) return (id and ns.DB.GetItemName(id)) or ("item " .. tostring(id)) end
local function questName(s) return (s.q and ns.DB.GetQuestName(s.q)) or s.title or ("quest " .. tostring(s.q)) end

-- Item ids in your bags (backpack and the four bag slots).
function IS:Scan()
    local bags = {}
    for bag = 0, C.NUM_BAGS do
        for slot = 1, C.GetContainerNumSlots(bag) do
            local it = C.GetContainerItem(bag, slot)
            if it and it.itemID then bags[it.itemID] = true end
        end
    end
    self.bags = bags
    return bags
end

function IS:Has(id) return id ~= nil and self.bags[id] == true end

-- The starter items of the active guide that are in your bags, as a string: refresh only when it changes.
function IS:Signature()
    local g = ns.Engine and ns.Engine.guide
    if not g then return "" end
    local ids = {}
    for _, s in ipairs(g.steps) do
        if s.starter and self:Has(s.starter) then ids[#ids + 1] = s.starter end
    end
    table.sort(ids)
    return table.concat(ids, ",")
end

function IS:OnBags()
    self:Scan()
    local sig = self:Signature()
    if sig ~= self.sig then
        self.sig = sig
        if ns.Engine.guide then ns.Engine:Refresh() end
    end
end

function IS:Init()
    T = ns.Tracker
    self:Scan()
    ns:On("BAG_UPDATE_DELAYED", function() IS:OnBags() end)
    ns:Listen("GUIDE_CHANGED", function() IS.sig = IS:Signature() end)
end

-- State of a starter accept step (see the top of the file); nil for any other step.
function IS:State(s, i)
    if not (s and s[1] == "accept" and s.starter and s.q) then return nil end
    T = T or ns.Tracker
    if T:IsTurnedIn(s.q) then return "done" end
    if T:InLog(s.q) then return "accepted" end
    if self:Has(s.starter) then return "have" end
    local E = ns.Engine
    i = i or s.index
    if E.waiting and i and E.waiting[i] then return "waiting" end
    return "farm"
end

-- Whether the step should wait for its later kill steps: the item is not in your bags, the quest is not in
-- your log, and one of the via steps is still open. (Engine:Refresh asks this for pending accept steps.)
function IS:Waits(s, status)
    if not (s.starter and s.via and s.q) then return false end
    T = T or ns.Tracker
    if self:Has(s.starter) or T:InLog(s.q) or T:IsTurnedIn(s.q) then return false end
    for _, j in ipairs(s.via) do
        local st = status[j]
        if st == "pending" or st == "active" then return true end
    end
    return false
end

-- Names of the step's droppers, at most n.
local function dropperNames(s, n)
    local out = {}
    for _, id in ipairs(s.drops or {}) do
        local name = ns.DB.GetNPCName(id)
        if name then
            local dup = false
            for _, o in ipairs(out) do if o == name then dup = true break end end
            if not dup then out[#out + 1] = name end
        end
        if #out >= n then break end
    end
    return out
end

-- Main line of a starter accept step (nil: use the ordinary "Accept ..." line).
function IS:Title(s, quest, item)
    local st = self:State(s)
    if st == "have" then
        return "Use " .. item(itemName(s.starter)) .. " to accept " .. quest(questName(s))
    elseif st == "farm" or st == "waiting" then
        local who = dropperNames(s, 2)
        return "Get " .. item(itemName(s.starter)) .. (who[1] and (" from " .. table.concat(who, " or ")) or "")
            .. " to accept " .. quest(questName(s))
    end
    return nil
end

-- Detail lines for a starter accept step, and for any other step: a later pickup whose item is in your bags,
-- and the kill steps whose mobs drop a starter item you do not have yet.
function IS:Lines(s, i, current)
    local out = {}
    local st = self:State(s, i)
    if st == "have" then
        out[#out + 1] = { warn = true, text = itemName(s.starter) .. " is in your bags: right-click it, then click Accept." }
    elseif st == "farm" or st == "waiting" then
        local who = dropperNames(s, 6)
        if who[1] then
            out[#out + 1] = { text = "Dropped by: " .. table.concat(who, ", ") .. "." }
        end
        out[#out + 1] = { text = "Skip this step to go on without the quest. If the item turns up later, the guide brings you back to it." }
    end
    local E = ns.Engine
    local g = E.guide
    if current and g and i and g.steps[i] == s then
        for j = i + 1, #g.steps do
            local a = g.steps[j]
            local ast = E.status[j]
            if a.starter and (ast == "pending" or ast == "active") and self:State(a, j) == "have" then
                out[#out + 1] = { warn = true, text = "You have " .. itemName(a.starter) .. ": it starts " .. questName(a) .. " (a later step)." }
            end
        end
    end
    if g and i and E.waiting then
        for j, w in pairs(E.waiting) do
            local a = g.steps[j]
            if w and a and a[1] == "accept" and a.via then
                for _, v in ipairs(a.via) do
                    if v == i then
                        out[#out + 1] = { text = "These mobs can drop " .. itemName(a.starter) .. ", which starts " .. questName(a) .. "." }
                        break
                    end
                end
            end
        end
    end
    return out
end

-- Nearest dropper while you still need the item; nil otherwise (no waypoint for using an item in your bags).
function IS:Target(s)
    local st = self:State(s)
    if not (st == "farm" or st == "waiting") or not s.drops then return nil end
    local mapId, mx, my = C.GetPlayerMapPosition()
    local area = mapId and ns.DB.AreaForUiMap(mapId)
    local best
    for _, id in ipairs(s.drops) do
        local z, x, y = ns.DB.GetNPCPosition(id, area, mx, my)
        if z then
            local d = (z == area and mx) and ((x - mx) ^ 2 + (y - my) ^ 2) or math.huge
            if not best or d < best.d then best = { z = z, x = x, y = y, name = ns.DB.GetNPCName(id), d = d } end
        end
    end
    if best then return best.z, best.x, best.y, best.name end
end

-- NPC ids to target or mark for the step: its droppers while you still need the item.
function IS:Npcs(s)
    local st = self:State(s)
    if not (st == "farm" or st == "waiting") or not s.drops then return nil end
    local ids = {}
    for _, id in ipairs(s.drops) do ids[id] = true end
    return next(ids) and ids or nil
end
