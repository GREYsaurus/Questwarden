-- Questwarden - roaming hunting routes for kill objectives (setting: roamRoutes; data: Guides/Compiled/Routes.lua)
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- This program is free software: you can redistribute it and/or modify it under the terms of the
-- GNU General Public License as published by the Free Software Foundation, version 3.
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
-- even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details. The complete license text is in LICENSE.
--
-- Navigation only: the arrow walks a verified loop of points through the known spawn area of the
-- current complete step's objective, instead of one static spot. It never moves the character,
-- targets anything or completes a step; reaching a point only moves the arrow to the next one.
--
--   * Which route: the current step is a complete step whose quest has routes (ns.RoamRoutes), the
--     quest is in the log and every objective the route serves is in the log with the expected type
--     ("monster" for kills, "item" for drops). A route runs while one of its objectives is unfinished;
--     the active route is kept until then (no switching after each kill), then the next in data order.
--   * Arrival: distance in yards from C_Map world positions. A point counts as reached only after the
--     player was seen outside 1.3 x its radius and then inside its radius; the compiler keeps points
--     2 x radius + 10 yards apart, so standing still never advances twice. No timers advance it.
--   * It pauses (no advance) without a player position, and stops in instances, when the setting is
--     off, when the step or quest changes, or after "/cg route off" for this step. Nothing is saved:
--     after a reload the route is rebuilt from the quest log and the nearest point.

local _, ns = ...

local R = { active = nil, suspended = {} }
ns.Roam = R

local C = ns.Compat
local TICK = 0.5          -- seconds between position checks while a route runs
local REARM = 1.3         -- must be seen beyond this many radii before a point can count as reached

local function prof() return ns.db.profile end
local function dbg(msg) ns:Debug("route: " .. msg) end
local OBJ_TYPE = { kill = "monster", drop = "item" }

local function inInstance()
    if not IsInInstance then return false end
    local inside, kind = IsInInstance()
    return inside and kind ~= "none"
end

-- Yards between the player and a route point, or nil when the position or map data is missing.
function R:Distance(route, p)
    local pMap, px, py = C.GetPlayerMapPosition()
    if not px then return nil end
    local mapId = ns.DB.ZoneUiMap(route.zone)
    local c1, x1, y1 = C.MapToWorld(pMap, px, py)
    local c2, x2, y2 = C.MapToWorld(mapId, p[1], p[2])
    if not (c1 and c2) or c1 ~= c2 then return nil end
    return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
end

local function radius(route, p) return p.r or route.r end

local function englishClient()
    local l = GetLocale and GetLocale()
    return l == "enUS" or l == "enGB"
end

-- Unfinished objectives of `route` in quest log entry e; nil when the log does not match the route.
-- On English clients the objective text must also name the route's target or item (o.name), which
-- catches a quest whose log order differs from the data; other clients rely on order and type.
local function openObjectives(route, e)
    local open = {}
    local english = englishClient()
    for _, o in ipairs(route.objs) do
        local lo = e.objectives[o.i]
        if not lo or lo.type ~= OBJ_TYPE[o.kind] then return nil end
        if english and o.name and o.name ~= "" and lo.text
            and not string.find(string.lower(lo.text), string.lower(o.name), 1, true) then return nil end
        if not lo.done then open[#open + 1] = { o = o, text = lo.text } end
    end
    return open
end

local function serves(route, objIndex)
    for _, o in ipairs(route.objs) do if o.i == objIndex then return true end end
    return false
end

-- Kill packs ----------------------------------------------------------------------------------------
-- The steps of a kill pack (Engine:PackSteps) are done together, so the arrow goes where the mobs of all of
-- them spawn: the known spawn with mobs of the most open steps within PACK_SPOT map percent, then the most of
-- the step with the fewest there, then the most in all. Example: Stocking Jetsteam and The Grizzled Den in Dun
-- Morogh meet by the wendigo cave (about 43, 56.5), not at the boars far west. The spot stays put until a step
-- or objective of the pack finishes.
-- A hunting route of a pack step is used only when it passes within PACK_NEAR map percent of the spot where
-- all the pack's steps meet; otherwise the arrow points at that spot (several open steps) or the nearest
-- spawn (one).
local PACK_SPOT = 4
local PACK_NEAR = 8   -- the compiler's PackRadius

-- Score of each spawn in `lists` (one spawn list per step): { p, steps with spawns near it, fewest of those, total }.
local function packScores(lists)
    local grid, cells = {}, PACK_SPOT
    local function key(x, y) return math.floor(x / cells) * 1000 + math.floor(y / cells) end
    for li, l in ipairs(lists) do
        for _, p in ipairs(l) do
            local k = key(p[1], p[2])
            grid[k] = grid[k] or {}
            grid[k][#grid[k] + 1] = { p, li }
        end
    end
    local out, r2 = {}, PACK_SPOT * PACK_SPOT
    for _, l in ipairs(lists) do
        for _, c in ipairs(l) do
            local n = {}
            local gx, gy = math.floor(c[1] / cells), math.floor(c[2] / cells)
            for dx = -1, 1 do
                for dy = -1, 1 do
                    for _, e in ipairs(grid[(gx + dx) * 1000 + gy + dy] or {}) do
                        local p = e[1]
                        if (p[1] - c[1]) ^ 2 + (p[2] - c[2]) ^ 2 <= r2 then n[e[2]] = (n[e[2]] or 0) + 1 end
                    end
                end
            end
            local steps, fewest, total = 0, math.huge, 0
            for li = 1, #lists do
                if n[li] then
                    steps, fewest, total = steps + 1, math.min(fewest, n[li]), total + n[li]
                end
            end
            out[#out + 1] = { c, steps, fewest, total }
        end
    end
    return out
end

local function better(a, b)
    if a[2] ~= b[2] then return a[2] > b[2] end
    if a[3] ~= b[3] then return a[3] > b[3] end
    return a[4] > b[4]
end

-- The best spot for these spawn lists (one list per step), or nil when no spawn has mobs of two steps near it.
function R.PackSpot(lists)
    if #lists < 2 then return nil end
    local best
    for _, s in ipairs(packScores(lists)) do if not best or better(s, best) then best = s end end
    if not best or best[2] < 2 then return nil end
    return best[1][1], best[1][2]
end

-- Where all the steps of step s's kill pack meet in `zone` (all their objectives, done or not): x, y or nil.
local areaCache = {}
function R:PackArea(s, zone)
    local E = ns.Engine
    if not (s and s.pack and E.guide and zone) then return nil end
    local key = E.guide.id .. ":" .. s.pack .. ":" .. zone
    local hit = areaCache[key]
    if hit == nil then
        local lists = {}
        for i = s.pack, #E.guide.steps do
            local st = E.guide.steps[i]
            if st.pack ~= s.pack then break end
            if st[1] == "complete" and st.q then
                local l = ns.DB.ObjectiveSpawns(st.q, zone)
                if #l > 0 then lists[#lists + 1] = l end
            end
        end
        local x, y = R.PackSpot(lists)
        hit = x and { x, y } or false
        areaCache[key] = hit
    end
    if hit then return hit[1], hit[2] end
end

local function routeNear(route, x, y)
    for _, p in ipairs(route.pts) do
        if (p[1] - x) ^ 2 + (p[2] - y) ^ 2 <= PACK_NEAR * PACK_NEAR then return true end
    end
    return false
end

-- Arrow target while two or more steps of the current kill pack are open: zone, x, y, label; nil otherwise.
-- Spawns in the zone you are in (the guide's quests there), open objectives only.
function R:PackTarget(s)
    local E = ns.Engine
    if not (s and s.pack and E.guide and s == E:CurrentStep()) then return nil end
    local mapId = C.GetPlayerMapPosition()
    local zone = mapId and ns.DB.AreaForUiMap(mapId)
    if not zone then return nil end
    local lists, titles, sig = {}, {}, { E.guide.id, s.pack, zone }
    for _, i in ipairs(E:PackSteps()) do
        local st = E.guide.steps[i]
        local e = st[1] == "complete" and st.q and ns.Tracker:GetEntry(st.q)
        if e and not e.complete then
            local l = ns.DB.ObjectiveSpawns(st.q, zone, function(name) return ns.Tracker:ObjectiveNameDone(st.q, name) end)
            if #l > 0 then
                lists[#lists + 1] = l
                titles[#titles + 1] = st.title or ns.DB.GetQuestName(st.q) or ("quest " .. st.q)
                sig[#sig + 1] = st.q .. "/" .. #l
            end
        end
    end
    if #lists < 2 then self.pack = nil return nil end
    sig = table.concat(sig, ":")
    local p = self.pack
    if not (p and p.sig == sig) then
        local x, y = R.PackSpot(lists)
        if not x then self.pack = nil return nil end
        p = { sig = sig, zone = zone, x = x, y = y, label = table.concat(titles, " + ") }
        self.pack = p
        dbg(string.format("kill pack spot %.1f, %.1f", x, y))
    end
    return p.zone, p.x, p.y, p.label
end

-- The route for step s now, with its unfinished objectives; nil and a reason otherwise.
function R:Pick(s)
    if not prof().roamRoutes then return nil, "setting off" end
    if not (s and s[1] == "complete" and s.q) then return nil, "not a kill step" end
    local list = ns.RoamRoutes and ns.RoamRoutes[s.q]
    if not list then return nil, "no verified route" end
    local e = ns.Tracker:GetEntry(s.q)
    if not e then return nil, "quest not in the log" end
    if e.complete then return nil, "quest complete" end
    if inInstance() then return nil, "in an instance" end
    if ns.Patrol and ns.Patrol:Pick(s) then return nil, "a patrolling NPC leads" end
    if self:PackTarget(s) then return nil, "kill pack: the arrow shows where its mobs meet" end
    local cands, far = {}, false
    for _, route in ipairs(list) do
        local ax, ay = self:PackArea(s, route.zone)
        if ax and not routeNear(route, ax, ay) then
            far = true
        elseif not s.obj or serves(route, s.obj) then
            local open = openObjectives(route, e)
            if open == nil then return nil, "quest log does not match route data" end
            if #open > 0 then cands[#cands + 1] = { route = route, open = open } end
        end
    end
    if #cands == 0 then return nil, far and "route far from the kill pack" or "route objectives complete" end
    local a = self.active
    if a and a.q == s.q then
        for _, c in ipairs(cands) do if c.route == a.route then return c.route, c.open end end
    end
    return cands[1].route, cands[1].open
end

local function stepKey(s)
    local E = ns.Engine
    return (E.guide and E.guide.id or "?") .. ":" .. tostring(E.current) .. ":" .. tostring(s and s.q)
end

-- Point to start from: the nearest one; if already inside it, the one after.
function R:Entry(route)
    local best, bestD
    for i, p in ipairs(route.pts) do
        local d = self:Distance(route, p)
        if d and (not bestD or d < bestD) then best, bestD = i, d end
    end
    if not best then return 1 end
    if bestD <= radius(route, route.pts[best]) then best = best % #route.pts + 1 end
    return best
end

-- Navigation target for step s while a route owns it: zone, x, y, label. Nil = normal navigation.
function R:TargetFor(s)
    local cur = ns.Engine and ns.Engine:CurrentStep()
    if s ~= cur then return nil end
    local key = stepKey(s)
    if self.suspended[key] then self:Stop("suspended") return nil end
    local route, open = self:Pick(s)
    if not route then
        if self.active then self:Stop(open) end
        return nil
    end
    local a = self.active
    if not (a and a.key == key and a.route == route) then
        a = { key = key, q = s.q, route = route, idx = self:Entry(route), armed = false }
        self.active = a
        dbg("start " .. route.name .. " at point " .. a.idx)
        self:StartTicker()
    end
    a.open = open
    local p = route.pts[a.idx]
    return route.zone, p[1], p[2], self:Label()
end

function R:Label()
    local a = self.active
    if not a then return "" end
    local what = a.open and a.open[1] and a.open[1].text or a.route.name
    return string.format("%s - point %d of %d", what, a.idx, #a.route.pts)
end

-- Moves the arrow to the active point unless the player chose another destination.
function R:Point()
    local a = self.active
    local nav = ns.Nav
    if not (a and nav) or nav.owner == "manual" then return end
    local p = a.route.pts[a.idx]
    nav:SetTarget(a.route.zone, p[1], p[2], self:Label(), "route")
end

function R:Advance(why)
    local a = self.active
    if not a then return false end
    a.idx = a.idx % #a.route.pts + 1
    a.armed = false
    dbg(why .. ": point " .. a.idx .. " of " .. #a.route.pts)
    self:Point()
    ns:Fire("ROUTE_CHANGED")
    return true
end

-- One position check (the ticker calls this every TICK seconds while a route runs).
function R:Check()
    local a = self.active
    if not a then return end
    if not prof().roamRoutes or inInstance() then self:Refresh() return end
    local p = a.route.pts[a.idx]
    local d = self:Distance(a.route, p)
    if not d then a.paused = true return end -- no position: hold the current point
    a.paused = nil
    local r = radius(a.route, p)
    if d > r * REARM then a.armed = true
    elseif a.armed and d <= r then self:Advance("arrived") end
end

function R:StartTicker()
    if not self.ticker then
        self.ticker = CreateFrame("Frame")
        local acc = 0
        self.ticker:SetScript("OnUpdate", function(f, elapsed)
            acc = acc + elapsed
            if acc < TICK then return end
            acc = 0
            if not R.active then f:Hide() return end
            R:Check()
        end)
    end
    self.ticker:Show()
end

function R:Stop(why)
    if not self.active then return end
    dbg("stop (" .. tostring(why) .. ")")
    self.active = nil
    if self.ticker then self.ticker:Hide() end
    local nav = ns.Nav
    if nav and nav.owner == "route" then nav:FromStep(ns.Engine:CurrentStep()) end
    ns:Fire("ROUTE_CHANGED")
end

-- Re-evaluates the route for the current step (quest updates, setting changes, zone changes).
function R:Refresh()
    local s = ns.Engine and ns.Engine:CurrentStep()
    if self:TargetFor(s) then self:Point() end
end

-- Player controls ---------------------------------------------------------------------------------

function R:Next()
    if not self.active then ns:Print("No hunting route is running.") return false end
    return self:Advance("skipped")
end

-- Back to the normal objective waypoint for this step ("/cg route on" or a new step undoes it).
function R:Suspend()
    local s = ns.Engine and ns.Engine:CurrentStep()
    if not self.active then ns:Print("No hunting route is running.") return false end
    self.suspended[stepKey(s)] = true
    self:Stop("suspended")
    ns:Print("Hunting route off for this step; the arrow shows the normal objective waypoint.")
    return true
end

function R:Resume()
    wipe(self.suspended)
    if ns.Nav and ns.Nav.owner == "manual" then ns.Nav.owner = "step" end
    self:Refresh()
    if not self.active then ns:Print("No verified hunting route for the current step.") end
end

-- One line for the step window, or nil.
function R:StatusLine()
    local a = self.active
    if not a then return nil end
    return string.format("Hunting route: point %d of %d%s. Known spawn area, not live mob positions.",
        a.idx, #a.route.pts, a.paused and " (no position, paused)" or "")
end

function R:Init()
    ns:Listen("QUESTS_CHANGED", function() R:Refresh() end)
    ns:Listen("STEP_CHANGED", function() wipe(R.suspended) end)
    ns:Listen("GUIDE_CHANGED", function() wipe(R.suspended) R:Stop("guide changed") end)
    ns:On("ZONE_CHANGED_NEW_AREA", function() R:Refresh() end)
    ns:On("PLAYER_ENTERING_WORLD", function() R:Refresh() end)
end

-- Key binding target (Bindings.xml).
_G[ns.name .. "_RouteNext"] = function() R:Next() end
