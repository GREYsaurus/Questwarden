-- Questwarden - known flight paths and their prices
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- This program is free software: you can redistribute it and/or modify it under the terms of the
-- GNU General Public License as published by the Free Software Foundation, version 3.
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
-- even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details. The complete license text is in LICENSE.
--
-- The game tells which flight paths you know, and what a flight costs, only while a flight map is open. Each
-- time it opens, the known nodes (current and reachable) and the price to every reachable one are saved for
-- this character (prices differ with reputation). Nodes are matched to the flight graph (Database/Flights.lua)
-- by the client's full name ("Sentinel Hill, Westfall"). No price ships with Questwarden: a flight you have not
-- seen on a flight map has no price, and the plan says so.
-- Your race's capital city flight path (CAPITAL) is taken as known even before a flight map has shown it.

local _, ns = ...

local FP = {}
ns.FlightPaths = FP

-- Race (UnitRace file name) -> the flight node of its capital city (Database/Flights.lua ids).
FP.CAPITAL = { Human = 2, Dwarf = 6, Gnome = 6, NightElf = 27, Draenei = 94,
    Orc = 23, Troll = 23, Tauren = 22, Scourge = 11, BloodElf = 82 }

-- The flight paths seen on a flight map (saved per character).
function FP:Known()
    if type(ns.char.knownFlights) ~= "table" then ns.char.knownFlights = {} end
    return ns.char.knownFlights
end

-- Your race's capital city flight node, or nil.
function FP:Capital()
    local id = self.CAPITAL[ns.Compat.PlayerInfo().race or ""]
    return id and ns.Flights and ns.Flights.nodes[id] and id or nil
end

-- Whether you know the flight path to `id`: seen on a flight map, or your capital's.
function FP:Has(id)
    return self:Known()[id] == true or (id ~= nil and id == self:Capital())
end

-- The flight paths you know, your capital's included (a new table).
function FP:KnownWithCapital()
    local out = {}
    for id, v in pairs(self:Known()) do out[id] = v end
    local cap = self:Capital()
    if cap then out[cap] = true end
    return out
end

function FP:Costs()
    if type(ns.char.flightCosts) ~= "table" then ns.char.flightCosts = {} end
    return ns.char.flightCosts
end

function FP.Key(from, to) return tostring(from) .. ">" .. tostring(to) end

local byFull
local function nodeByName(name)
    local F = ns.Flights
    if not (F and type(name) == "string") then return nil end
    if not byFull then
        byFull = {}
        for id, n in pairs(F.nodes) do byFull[string.lower(n.full)] = id end
    end
    return byFull[string.lower(name)]
end

-- Flight map open: save the nodes you know and the prices from here.
function FP:Record()
    if not (NumTaxiNodes and TaxiNodeName and TaxiNodeGetType) then return end
    local known, origin, reach = self:Known(), nil, {}
    for i = 1, NumTaxiNodes() or 0 do
        local kind = TaxiNodeGetType(i)
        local id = nodeByName(TaxiNodeName(i))
        if id and (kind == "CURRENT" or kind == "REACHABLE") then
            known[id] = true
            if kind == "CURRENT" then origin = id else reach[id] = i end
        end
    end
    if origin and TaxiNodeCost then
        local costs = self:Costs()
        for id, i in pairs(reach) do
            local c = TaxiNodeCost(i)
            if type(c) == "number" and c >= 0 then costs[FP.Key(origin, id)] = c end
        end
    end
end

-- Fewest flights from one known node to another, over known nodes only (you cannot fly through a flight path you
-- do not know); nil when there is no such route.
function FP:Hops(from, to)
    local F, known = ns.Flights, self:KnownWithCapital()
    if not (F and known[from] and known[to]) then return nil end
    local dist, queue, head = { [from] = 0 }, { from }, 1
    while queue[head] do
        local cur = queue[head]
        head = head + 1
        if cur == to then return dist[cur] end
        for _, nxt in ipairs(F.links[cur] or {}) do
            if known[nxt] and not dist[nxt] then
                dist[nxt] = dist[cur] + 1
                queue[#queue + 1] = nxt
            end
        end
    end
end

-- The cheapest known flight from the zone you are in to a zone where `ok(zone)` holds: { from, to (node ids),
-- cost (copper, or nil when not seen yet), hops }. You start at the known flight path nearest to you in your zone.
-- Flights with a seen price come first, cheapest first; the others by fewest flights. nil when your zone has no
-- known flight path or no known destination passes.
function FP:CheapestTo(ok)
    local F = ns.Flights
    if not F then return nil end
    local mapId, px, py = ns.Compat.GetPlayerMapPosition()
    local here = mapId and ns.DB.AreaForUiMap(mapId)
    if not here then return nil end
    local known, origin, bestD = self:KnownWithCapital(), nil, nil
    for id in pairs(known) do
        local n = F.nodes[id]
        if n and n.zone == here then
            local d = (px and py) and ((n.x - px) ^ 2 + (n.y - py) ^ 2) or 0
            if not bestD or d < bestD or (d == bestD and id < origin) then origin, bestD = id, d end
        end
    end
    if not origin then return nil end
    local costs, best = self:Costs(), nil
    for id in pairs(known) do
        local n = F.nodes[id]
        if id ~= origin and n and n.zone ~= here and ok(n.zone) then
            local hops = self:Hops(origin, id)
            if hops then
                local c = { from = origin, to = id, cost = costs[FP.Key(origin, id)], hops = hops }
                local better = not best
                if best then
                    if c.cost and best.cost then better = c.cost < best.cost or (c.cost == best.cost and id < best.to)
                    elseif c.cost or best.cost then better = c.cost ~= nil
                    else better = hops < best.hops or (hops == best.hops and id < best.to) end
                end
                if better then best = c end
            end
        end
    end
    return best
end

function FP:Init()
    ns:On("TAXIMAP_OPENED", function() FP:Record() end)
end
