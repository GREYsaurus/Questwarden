-- Questwarden - the way to the next zone for "travel <zone>" steps: walking, zeppelins, boats and known flights
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- This program is free software: you can redistribute it and/or modify it under the terms of the
-- GNU General Public License as published by the Free Software Foundation, version 3.
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
-- even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details. The complete license text is in LICENSE.
--
-- A travel step without a position or directions of its own gets a route from the zone you are in to its zone, worked out again
-- each time you change zone. The legs:
--   * walk: between zones that border each other (Database/Travel.lua, hand-written from the world map);
--   * zeppelin or boat: between the stops in the client's transport paths (Database/Travel.lua), for your faction;
--   * fly: between flight paths you know (Core/FlightPaths.lua, your capital's included) that are linked.
-- Each leg is costed in seconds (straight-line yards at RUN yards a second on foot, FLY in the air, RIDE for a
-- zeppelin or boat with its wait) and the cheapest route wins. Distances are rough (zone maps are rectangles), so
-- the route is a suggestion. The arrow points to the first place you need to reach: a zeppelin tower or dock, a
-- flight master, or the destination. On the way it names flight paths of your faction you don't have yet next to a
-- stop or in a zone you cross.

local _, ns = ...

local TR = {}
ns.Travel = TR

TR.RUN = 7              -- yards a second on foot
TR.FLY = 30             -- yards a second on a flight
TR.FLY_EXTRA = 30       -- seconds to take off and land
TR.RIDE = 240           -- seconds for a zeppelin or boat, with the wait
TR.FP_NEAR = 800        -- yards from a stop: a flight path "next to" it
TR.LOOKAHEAD = 20       -- steps after the travel step searched for where you are headed
local DIRS = { "north", "north-west", "west", "south-west", "south", "south-east", "east", "north-east" }

local function geo() return ns.ZoneGeo or {} end
local function data() return ns.TravelData or { transports = {}, borders = {} } end

-- World position { c, x, y } of a zone-percent point, or nil.
function TR.World(z, x, y)
    local g = geo()[z]
    if not g then return nil end
    return { c = g[1], x = g[4] - (y or 50) / 100 * (g[4] - g[2]), y = g[5] - (x or 50) / 100 * (g[5] - g[3]) }
end

local function dist(a, b)
    if not (a and b) or a.c ~= b.c then return math.huge end
    return math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2)
end

-- The point of zone `z`'s map nearest to `p` (where you enter it, roughly).
local function entry(z, p)
    local g = geo()[z]
    if not (g and p and g[1] == p.c) then return TR.World(z, 50, 50) end
    return { c = g[1], x = math.min(math.max(p.x, g[2]), g[4]), y = math.min(math.max(p.y, g[3]), g[5]) }
end

-- "north", "south-west", ... from `a` to `b` (world x runs north, y west), or nil when they are close.
function TR.Direction(a, b)
    if dist(a, b) < 300 then return nil end
    local ang = math.deg(math.atan2(b.y - a.y, b.x - a.x)) -- 0 north, 90 west
    return DIRS[(math.floor((ang + 22.5) / 45) % 8) + 1]
end

local zoneIds
-- Zone id for a zone name ("The Barrens"), among zones with geography.
function TR.ZoneId(name)
    if not zoneIds then
        zoneIds = {}
        local names = ns.QDB and ns.QDB.zones and ns.QDB.zones.names or {}
        for id, n in pairs(names) do
            local k = string.lower(n)
            if geo()[id] and (not zoneIds[k] or id < zoneIds[k]) then zoneIds[k] = id end
        end
    end
    return type(name) == "string" and zoneIds[string.lower(name)] or nil
end

-- Whether flight path `n` serves faction `tag` ("A", "H").
local function serves(n, tag) return tag ~= nil and string.find(n.faction or "", tag, 1, true) ~= nil end

local function factionTag()
    local f = ns.Compat.PlayerInfo().faction
    return f == "Alliance" and "A" or f == "Horde" and "H" or nil
end

-- The edges out of each zone: { to, kind, from = {zone,x,y,name}, at = {zone,x,y,name} | node ids }.
local function edges(tag)
    local out = {}
    local function add(a, e) out[a] = out[a] or {} table.insert(out[a], e) end
    for _, b in ipairs(data().borders) do
        add(b[1], { to = b[2], kind = "walk" })
        add(b[2], { to = b[1], kind = "walk" })
    end
    for _, t in ipairs(data().transports) do
        if tag and string.find(t[2], tag, 1, true) then
            add(t[3][1], { to = t[4][1], kind = t[1], from = t[3], at = t[4] })
            add(t[4][1], { to = t[3][1], kind = t[1], from = t[4], at = t[3] })
        end
    end
    local F, FP = ns.Flights, ns.FlightPaths
    if F and FP and ns.char then
        local known = FP:KnownWithCapital()
        for a in pairs(known) do
            for b in pairs(known) do
                local na, nb = F.nodes[a], F.nodes[b]
                if a ~= b and na and nb and na.zone ~= nb.zone and serves(na, tag) and serves(nb, tag) and FP:Hops(a, b) then
                    add(na.zone, { to = nb.zone, kind = "fly", from = { na.zone, na.x, na.y, na.name },
                        at = { nb.zone, nb.x, nb.y, nb.name } })
                end
            end
        end
    end
    return out
end

-- Where in zone `z` the route ends: the first later step of the guide with a position in that zone, else a flight
-- path of your faction there, else the middle of the zone. Returns zone, x, y, name.
function TR.Anchor(z, s, tag)
    local E = ns.Engine
    local steps = E and E.guide and E.guide.steps
    if steps and s and s.index then
        for i = s.index + 1, math.min(#steps, s.index + TR.LOOKAHEAD) do
            local st = steps[i]
            if st and st.z == z and st.x and st.y then return z, st.x, st.y, st.npc or st.text end
        end
    end
    local F = ns.Flights
    local best
    for id, n in pairs(F and F.nodes or {}) do
        if n.zone == z and serves(n, tag) and (not best or id < best) then best = id end
    end
    if best then local n = F.nodes[best] return z, n.x, n.y, n.name end
    return z, 50, 50, ns.DB.ZoneName(z)
end

-- The cheapest route from zone `from` (at world position `pos`) to zone `to`, ending at `anchor` (world position):
-- a list of legs { kind, to (zone), from, at }, or nil when there is none.
function TR.Plan(from, pos, to, anchor, tag)
    if not (from and to and geo()[from] and geo()[to]) or from == to then return nil end
    local out = edges(tag)
    local cost, prev, here, done = { [from] = 0 }, {}, { [from] = pos or TR.World(from, 50, 50) }, {}
    while true do
        local z, best
        for k, c in pairs(cost) do if not done[k] and (not best or c < best) then z, best = k, c end end
        if not z or z == to then break end
        done[z] = true
        for _, e in ipairs(out[z] or {}) do
            if not done[e.to] and geo()[e.to] then
                local p, c, arrive = here[z], nil, nil
                if e.kind == "walk" then
                    arrive = e.to == to and anchor or entry(e.to, p)
                    c = dist(p, arrive) / TR.RUN
                else
                    local a, b = TR.World(e.from[1], e.from[2], e.from[3]), TR.World(e.at[1], e.at[2], e.at[3])
                    arrive = b
                    c = dist(p, a) / TR.RUN + (e.kind == "fly" and (dist(a, b) / TR.FLY + TR.FLY_EXTRA) or TR.RIDE)
                    if e.to == to and anchor then c = c + dist(b, anchor) / TR.RUN end
                end
                if c < math.huge and (not cost[e.to] or best + c < cost[e.to]) then
                    cost[e.to], prev[e.to], here[e.to] = best + c, { z = z, e = e }, arrive
                end
            end
        end
    end
    if not prev[to] then return nil end
    local legs, z = {}, to
    while z ~= from do
        local p = prev[z]
        table.insert(legs, 1, { kind = p.e.kind, to = z, fromZone = p.z, from = p.e.from, at = p.e.at, pos = here[p.z], arrive = here[z] })
        z = p.z
    end
    return legs
end

-- Unknown flight paths of your faction on the way: next to a zeppelin or boat stop you arrive at, or in a zone you
-- walk through (not the destination, where the guide says when). Names, sorted.
function TR.FlightPathsOnTheWay(legs, tag)
    local F, FP = ns.Flights, ns.FlightPaths
    if not (F and FP and ns.char) then return {} end
    local found = {}
    for i, l in ipairs(legs) do
        for id, n in pairs(F.nodes) do
            if serves(n, tag) and not FP:Has(id) then
                local near = (l.kind == "zeppelin" or l.kind == "boat")
                    and dist(TR.World(n.zone, n.x, n.y), TR.World(l.at[1], l.at[2], l.at[3])) <= TR.FP_NEAR
                local crossed = l.kind == "walk" and i < #legs and n.zone == l.to
                if near or crossed then found[n.name] = true end
            end
        end
    end
    local out = {}
    for name in pairs(found) do out[#out + 1] = name end
    table.sort(out)
    return out
end

-- How a stop is named: "Ratchet", "the tower near Undercity".
local function stopName(kind, stop)
    local name = stop[4] or "?"
    if string.sub(name, 1, 5) == "near " then
        return (kind == "zeppelin" and "the zeppelin tower " or "the dock ") .. name
    end
    return name
end

local function arrivalName(stop)
    local zone, name = ns.DB.ZoneName(stop[1]), stop[4] or ""
    if name == zone or name == "" then return zone end
    if string.sub(name, 1, 5) == "near " then return zone .. ", " .. name end
    return name .. " (" .. zone .. ")"
end

-- The route as sentences, one per leg (walks in a row joined).
function TR.Describe(legs)
    local lines, walk = {}, {}
    local function flush()
        if #walk == 0 then return end
        local parts = {}
        for _, l in ipairs(walk) do
            local d = TR.Direction(l.pos, l.arrive)
            parts[#parts + 1] = (d and (d .. " ") or "") .. "into " .. ns.DB.ZoneName(l.to)
        end
        lines[#lines + 1] = "Run " .. table.concat(parts, ", then ") .. "."
        walk = {}
    end
    for _, l in ipairs(legs) do
        if l.kind == "walk" then
            walk[#walk + 1] = l
        else
            flush()
            if l.kind == "fly" then
                lines[#lines + 1] = "Fly from " .. l.from[4] .. " to " .. l.at[4] .. "."
            else
                lines[#lines + 1] = "Take the " .. l.kind .. " from " .. stopName(l.kind, l.from) .. " to " .. arrivalName(l.at) .. "."
            end
        end
    end
    flush()
    return lines
end

local zoneOfMap
-- The zone (with geography) a zone map shows.
function TR.ZoneForMap(map)
    if not zoneOfMap then
        zoneOfMap = {}
        local ui = ns.QDB and ns.QDB.zones and ns.QDB.zones.uiMap or {}
        for z, m in pairs(ui) do
            if geo()[z] and (not zoneOfMap[m] or z < zoneOfMap[m]) then zoneOfMap[m] = z end
        end
    end
    return map and zoneOfMap[map]
end

-- Your zone and world position, or nil.
local function whereAmI()
    local map, x, y = ns.Compat.GetPlayerMapPosition()
    local z = TR.ZoneForMap(map)
    if not z then return nil end
    return z, x and TR.World(z, x, y) or TR.World(z, 50, 50)
end

-- The route for travel step `s` from where you are: { legs, lines, target = {zone,x,y,name}, flightPaths }, or nil.
-- Worked out again when you change zone, learn a flight path or move on to another step.
function TR:Route(s)
    if not (s and s[1] == "travel" and s.dest) or s.x then return nil end
    -- The guide's own directions ("Take the Deeprun Tram ...") win over a planned route.
    if s.text and s.text ~= "Travel to " .. s.dest then return nil end
    local to = TR.ZoneId(s.dest)
    local from, pos = whereAmI()
    if not (to and from) or from == to then return nil end
    local nKnown = 0
    if ns.FlightPaths and ns.char then for _ in pairs(ns.FlightPaths:Known()) do nKnown = nKnown + 1 end end
    local key = table.concat({ from, to, nKnown, tostring(s.index), tostring(ns.Compat.PlayerInfo().race) }, ":")
    if self.cacheKey == key then return self.cacheRoute end
    self.cacheKey, self.cacheRoute = key, self:Compute(s, from, pos, to)
    return self.cacheRoute
end

function TR:Compute(s, from, pos, to)
    local tag = factionTag()
    local az, ax, ay, aname = TR.Anchor(to, s, tag)
    local legs = TR.Plan(from, pos, to, TR.World(az, ax, ay), tag)
    if not legs then return nil end
    local target = { az, ax, ay, aname }
    for _, l in ipairs(legs) do
        if l.kind ~= "walk" then target = { l.from[1], l.from[2], l.from[3], l.kind == "fly" and (l.from[4] .. " flight master") or stopName(l.kind, l.from) } break end
    end
    return { legs = legs, lines = TR.Describe(legs), target = target, flightPaths = TR.FlightPathsOnTheWay(legs, tag) }
end
