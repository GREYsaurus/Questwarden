-- Questwarden - following a patrolling quest NPC along its path (setting: patrolPaths; data: Database/Questie/Patrols.lua)
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- This program is free software: you can redistribute it and/or modify it under the terms of the
-- GNU General Public License as published by the Free Software Foundation, version 3.
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
-- even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details. The complete license text is in LICENSE.
--
-- Navigation only. When the current step needs an NPC that walks a path QuestieDB knows (a quest giver,
-- a turn-in NPC or a mob to kill), the arrow goes to the nearer end of that path, then from point to
-- point along it until the step is done: back along the path at its far end, round again on a loop.
-- The path is dotted on the world map and the minimap.
--
--   * Which NPC: accept steps use the quest's start NPCs, turn-in steps its end NPCs, complete steps
--     the NPCs its objectives are about (kills, kill credit, droppers of its items). Only NPCs with at
--     most MAX_SPAWNS known spawns: a named NPC on its rounds, not a kind of mob that patrols in many
--     places. On complete steps an NPC whose objective is already done (English clients: the log text
--     names it) is not followed.
--   * Arrival: within ARRIVE_YARDS of a point the arrow moves to the next one. Being near the NPC
--     does not stop it; the step changing does (accepted, turned in, objective done).
--   * Not in instances, and not while the setting is off. Nothing is saved: after a reload the arrow
--     starts again from the nearer end.

local _, ns = ...

local P = { active = nil }
ns.Patrol = P

local C = ns.Compat
local TICK = 0.5            -- seconds between position checks
local ARRIVE_YARDS = 15     -- a path point counts as reached this close
local MAX_SPAWNS = 2        -- NPCs with more known spawns are not followed
local LOOP_GAP = 1.5        -- map percent: a path whose ends are this close is a loop
local MAP_DOT_GAP = 0.6     -- map percent between dots on the world map
local MINI_DOT_YARDS = 12   -- yards between dots on the minimap
local MAX_DOTS = 400
local DOT_COLOR = { 0.8, 0.5, 1 }

local function prof() return ns.db.profile end
local function dbg(msg) ns:Debug("patrol: " .. msg) end

local function inInstance()
    if not IsInInstance then return false end
    local inside, kind = IsInInstance()
    return inside and kind ~= "none"
end

local function englishClient()
    local l = GetLocale and GetLocale()
    return l == "enUS" or l == "enGB"
end

-- Paths of an NPC in a zone: { {x1, y1, x2, y2, ...}, ... }, or nil.
function P.Paths(npcId, zone)
    local t = ns.QDB.patrols and ns.QDB.patrols[npcId]
    return t and zone and t[zone]
end

local function spawnCount(npcId)
    local r = ns.DB.GetNPCByID(npcId)
    if not r then return 0 end
    local n = 0
    for _, pts in pairs(r.spawns) do n = n + #pts end
    return n
end

-- NPC ids the step is about, in a fixed order.
local function stepNpcs(s)
    if not (s and s.q) then return {} end
    if s[1] == "accept" then return ns.DB.GetQuestStartNPCs(s.q) or {} end
    if s[1] == "turnin" then return (ns.DB.GetQuestEndNPCs(s.q)) or {} end
    if s[1] ~= "complete" then return {} end
    local area = ns.Patrol.PlayerArea()
    local set = ns.DB.ObjectiveNpcIds(s.q, area)
    local ids = {}
    for id in pairs(set or {}) do ids[#ids + 1] = id end
    table.sort(ids)
    return ids
end

function P.PlayerArea()
    local mapId, x, y = C.GetPlayerMapPosition()
    return mapId and ns.DB.AreaForUiMap(mapId), x, y
end

-- Whether quest log entry e shows the objective naming `name` as done (English clients only).
local function objectiveDone(e, name, objIndex)
    if not (e and name and englishClient()) then return false end
    local lname = string.lower(name)
    for i, o in ipairs(e.objectives) do
        if (not objIndex or objIndex == i) and o.text and string.find(string.lower(o.text), lname, 1, true) then
            return o.done and true or false
        end
    end
    return false
end

-- The zone of an NPC's patrols to use: the player's zone, its parent, the step's zone, else the lowest id.
local function pickZone(npcId, s, area)
    local t = ns.QDB.patrols and ns.QDB.patrols[npcId]
    if not t then return nil end
    for _, z in ipairs({ area, area and ns.DB.ParentZone(area), s.z }) do
        if z and t[z] then return z end
    end
    local best
    for z in pairs(t) do if not best or z < best then best = z end end
    return best
end

-- Flat path -> list of {x, y}.
local function points(flat)
    local pts = {}
    for i = 1, #flat - 1, 2 do pts[#pts + 1] = { flat[i], flat[i + 1] } end
    return pts
end

-- The path to follow for step s: { npc, name, zone, pts, loop, path, flat }, or nil and a reason. No side effects.
function P:Pick(s)
    if not prof().patrolPaths then return nil, "setting off" end
    if not (s and s.q) then return nil, "not a quest step" end
    if inInstance() then return nil, "in an instance" end
    local e
    if s[1] == "complete" then
        e = ns.Tracker:GetEntry(s.q)
        if not e then return nil, "quest not in the log" end
        if e.complete then return nil, "quest complete" end
    end
    local area, px, py = self.PlayerArea()
    for _, id in ipairs(stepNpcs(s)) do
        local zone = pickZone(id, s, area)
        local paths = zone and self.Paths(id, zone)
        local name = ns.DB.GetNPCName(id)
        if paths and spawnCount(id) <= MAX_SPAWNS and not (e and objectiveDone(e, name, s.obj)) then
            -- Several paths in one zone: the one passing nearest to the player.
            local pick, which = paths[1], 1
            if #paths > 1 and px and area and (area == zone or ns.DB.ParentZone(area) == zone) then
                local bestD
                for i, flat in ipairs(paths) do
                    for j = 1, #flat - 1, 2 do
                        local d = (flat[j] - px) ^ 2 + (flat[j + 1] - py) ^ 2
                        if not bestD or d < bestD then bestD, pick, which = d, flat, i end
                    end
                end
            end
            local pts = points(pick)
            local a, b = pts[1], pts[#pts]
            local loop = #pts > 2 and math.abs(a[1] - b[1]) <= LOOP_GAP and math.abs(a[2] - b[2]) <= LOOP_GAP
            return { npc = id, name = name or ("NPC " .. id), zone = zone, pts = pts, loop = loop, path = which, flat = pick }
        end
    end
    return nil, "no patrolling NPC"
end

local function stepKey(s)
    local E = ns.Engine
    return (E.guide and E.guide.id or "?") .. ":" .. tostring(E.current) .. ":" .. tostring(s and s.q)
end

-- Yards between the player and a path point, or nil when the position or map data is missing.
function P:Distance(zone, p)
    local pMap, px, py = C.GetPlayerMapPosition()
    if not px then return nil end
    local c1, x1, y1 = C.MapToWorld(pMap, px, py)
    local c2, x2, y2 = C.MapToWorld(ns.DB.ZoneUiMap(zone), p[1], p[2])
    if not (c1 and c2) or c1 ~= c2 then return nil end
    return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
end

-- Where to start: on a loop the nearest point, otherwise the nearer end (walking toward the other one).
function P:Entry(a)
    local pts, n = a.pts, #a.pts
    if a.loop then
        local best, bestD = 1, nil
        for i, p in ipairs(pts) do
            local d = self:Distance(a.zone, p)
            if d and (not bestD or d < bestD) then best, bestD = i, d end
        end
        return best, 1
    end
    local d1, dn = self:Distance(a.zone, pts[1]), self:Distance(a.zone, pts[n])
    if d1 and dn and dn < d1 then return n, -1 end
    return 1, 1
end

-- Navigation target for step s while a patrol owns it: zone, x, y, label. Nil = normal navigation.
-- Starts, keeps or ends the active patrol (the caller points the arrow).
function P:TargetFor(s)
    local cur = ns.Engine and ns.Engine:CurrentStep()
    local pick = s == cur and self:Pick(s)
    if not pick then
        if self.active then self:Deactivate("no patrol for this step") end
        return nil
    end
    local key = stepKey(s)
    local a = self.active
    if not (a and a.key == key and a.npc == pick.npc and a.zone == pick.zone and a.flat == pick.flat) then
        a = pick
        a.key = key
        a.idx, a.dir = self:Entry(a)
        self.active = a
        dbg("follow " .. a.name .. " from point " .. a.idx .. " of " .. #a.pts .. (a.loop and " (loop)" or ""))
        self:StartTicker()
        self:Draw()
        ns:Fire("ROUTE_CHANGED")
    end
    local p = a.pts[a.idx]
    return a.zone, p[1], p[2], self:Label()
end

function P:Label()
    local a = self.active
    if not a then return "" end
    return string.format("%s (patrols) - point %d of %d", a.name, a.idx, #a.pts)
end

-- Moves the arrow to the active point unless the player chose another destination.
function P:Point()
    local a = self.active
    local nav = ns.Nav
    if not (a and nav) or nav.owner == "manual" then return end
    local p = a.pts[a.idx]
    nav:SetTarget(a.zone, p[1], p[2], self:Label(), "patrol")
end

-- The next point: along the path, back at its ends, round on a loop.
function P:Advance()
    local a = self.active
    if not a then return end
    local n = #a.pts
    if a.loop then
        a.idx = a.idx % n + 1
    else
        local nxt = a.idx + a.dir
        if nxt < 1 or nxt > n then a.dir = -a.dir nxt = a.idx + a.dir end
        a.idx = math.max(1, math.min(n, nxt))
    end
end

-- One position check (every TICK seconds while a patrol is followed).
function P:Check()
    local a = self.active
    if not a then return end
    if not prof().patrolPaths or inInstance() then self:Refresh() return end
    local moved = false
    for _ = 1, #a.pts do
        local d = self:Distance(a.zone, a.pts[a.idx])
        if not d then a.paused = true return end -- no position: hold the current point
        a.paused = nil
        if d > ARRIVE_YARDS then break end
        self:Advance()
        moved = true
    end
    if moved then
        dbg("point " .. a.idx .. " of " .. #a.pts)
        self:Point()
        ns:Fire("ROUTE_CHANGED")
    end
end

function P:StartTicker()
    if not self.ticker then
        self.ticker = CreateFrame("Frame")
        local acc, macc = 0, 0
        self.ticker:SetScript("OnUpdate", function(f, elapsed)
            if not P.active then f:Hide() return end
            acc, macc = acc + elapsed, macc + elapsed
            if macc >= (prof().lowQuality and 0.3 or 0.1) then
                macc = 0
                P:UpdateMinimap()
            end
            if acc < TICK then return end
            acc = 0
            P:Check()
        end)
    end
    self.ticker:Show()
end

-- Ends the patrol without touching the arrow.
function P:Deactivate(why)
    if not self.active then return end
    dbg("stop (" .. tostring(why) .. ")")
    self.active = nil
    if self.ticker then self.ticker:Hide() end
    self:Draw()
    ns:Fire("ROUTE_CHANGED")
end

-- Ends the patrol; the arrow goes back to the step's normal target.
function P:Stop(why)
    if not self.active then return end
    self:Deactivate(why)
    local nav = ns.Nav
    if nav and nav.owner == "patrol" then nav:FromStep(ns.Engine:CurrentStep()) end
end

-- Re-evaluates the patrol for the current step (quest updates, setting and zone changes).
function P:Refresh()
    local s = ns.Engine and ns.Engine:CurrentStep()
    local was = self.active
    if self:TargetFor(s) then
        self:Point()
    elseif was and ns.Nav and ns.Nav.owner == "patrol" then
        ns.Nav:FromStep(s)
    end
end

-- Step window lines: the note that the NPC patrols, and where the arrow is on its path.
function P:Lines(s)
    local a = self.active
    if a and s == (ns.Engine and ns.Engine:CurrentStep()) then
        return {
            string.format("%s patrols: the arrow follows its path (dotted on the map and minimap).", a.name),
            string.format("Patrol point %d of %d%s.", a.idx, #a.pts, a.paused and " (no position, paused)" or ""),
        }
    end
    if not (s and s.q) then return {} end
    for _, id in ipairs(stepNpcs(s)) do
        local r = ns.DB.GetNPCByID(id)
        if r and (r.patrols or (ns.QDB.patrols and ns.QDB.patrols[id])) and spawnCount(id) <= MAX_SPAWNS then
            return { string.format("%s patrols: it may not be where the waypoint is.", r.name or "This NPC") }
        end
    end
    return {}
end

-- Path dots ---------------------------------------------------------------------------------------

local function dotPool(parent, layer)
    return { parent = parent, layer = layer or "OVERLAY", tex = {}, used = 0 }
end

local function dot(pool, size, alpha)
    pool.used = pool.used + 1
    local t = pool.tex[pool.used]
    if not t then
        t = pool.parent:CreateTexture(nil, pool.layer)
        t:SetTexture("Interface\\Buttons\\WHITE8X8")
        pool.tex[pool.used] = t
    end
    t:SetSize(size, size)
    t:SetVertexColor(DOT_COLOR[1], DOT_COLOR[2], DOT_COLOR[3], alpha)
    t:ClearAllPoints()
    t:Show()
    return t
end

local function finish(pool)
    for i = pool.used + 1, #pool.tex do pool.tex[i]:Hide() end
    pool.used = 0
end

-- Points spaced about `gap` apart along a polyline of {x, y} (closed when loop), at most MAX_DOTS.
local function spaced(pts, gap, loop)
    local segs, total = {}, 0
    local n = #pts
    for i = 1, loop and n or n - 1 do
        local a, b = pts[i], pts[i % n + 1]
        local len = math.sqrt((b[1] - a[1]) ^ 2 + (b[2] - a[2]) ^ 2)
        segs[#segs + 1] = { a, b, len }
        total = total + len
    end
    gap = math.max(gap, total / MAX_DOTS)
    local out, carry = { { pts[1][1], pts[1][2] } }, 0
    for _, sg in ipairs(segs) do
        local a, b, len = sg[1], sg[2], sg[3]
        local d = gap - carry
        while d <= len do
            local f = len > 0 and d / len or 0
            out[#out + 1] = { a[1] + (b[1] - a[1]) * f, a[2] + (b[2] - a[2]) * f }
            d = d + gap
        end
        carry = len - (d - gap)
    end
    return out
end

-- Rebuilds the dot positions for the active patrol and redraws.
function P:Draw()
    local a = self.active
    if a and not a.mapDots then
        a.mapId = ns.DB.ZoneUiMap(a.zone)
        a.mapDots = spaced(a.pts, MAP_DOT_GAP, a.loop)
        local world = {}
        for _, p in ipairs(a.pts) do
            local c, wx, wy = C.MapToWorld(a.mapId, p[1], p[2])
            if not c then world = nil break end
            a.continent = c
            world[#world + 1] = { wx, wy }
        end
        a.miniDots = world and #world > 1 and spaced(world, MINI_DOT_YARDS, a.loop) or {}
    end
    self.mapState = nil
    self:UpdateMap()
    self:UpdateMinimap()
end

function P:UpdateMap()
    local layer = self.mapLayer
    if not layer then return end
    local a = self.active
    local canvas = WorldMapFrame and WorldMapFrame.GetCanvas and WorldMapFrame:GetCanvas()
    local shown = canvas and WorldMapFrame:IsShown() and WorldMapFrame.GetMapID and WorldMapFrame:GetMapID()
    if not (a and a.mapId and prof().showMapPins and shown == a.mapId) then
        layer:Hide()
        self.mapState = nil
        return
    end
    local w, h = canvas:GetWidth(), canvas:GetHeight()
    local scale = 1 / (canvas:GetEffectiveScale() / UIParent:GetEffectiveScale())
    local state = table.concat({ tostring(a), w, h, scale }, ":")
    if self.mapState == state and layer:IsShown() then return end
    self.mapState = state
    if layer:GetParent() ~= canvas then layer:SetParent(canvas) end
    layer:SetFrameStrata(canvas:GetFrameStrata())
    layer:SetFrameLevel((canvas:GetFrameLevel() or 1) + 1990) -- under the waypoint pin
    layer:ClearAllPoints()
    layer:SetAllPoints(canvas)
    local size = 5 * math.max(scale, 0.6)
    for _, p in ipairs(a.mapDots) do
        dot(self.mapPool, size, 0.85):SetPoint("CENTER", layer, "TOPLEFT", w * p[1] / 100, -h * p[2] / 100)
    end
    finish(self.mapPool)
    layer:Show()
end

function P:UpdateMinimap()
    local layer = self.miniLayer
    if not layer then return end
    local a = self.active
    local proj, radius = a and prof().showMinimapPin and ns.Nav:MinimapProjection()
    if not proj then layer:Hide() return end
    for _, p in ipairs(a.miniDots) do
        local rx, ry, edge = proj(a.continent, p[1], p[2])
        if rx and not edge then dot(self.miniPool, 3, 0.9):SetPoint("CENTER", Minimap, "CENTER", rx, ry) end
    end
    finish(self.miniPool)
    layer:Show()
end

function P:Init()
    if WorldMapFrame then
        self.mapLayer = CreateFrame("Frame", nil, UIParent)
        self.mapLayer:Hide()
        self.mapPool = dotPool(self.mapLayer)
        WorldMapFrame:HookScript("OnShow", function() P:UpdateMap() end)
        WorldMapFrame:HookScript("OnHide", function() P.mapLayer:Hide() P.mapState = nil end)
        local macc = 0
        WorldMapFrame:HookScript("OnUpdate", function(_, elapsed)
            macc = macc + elapsed
            if macc < 0.2 then return end
            macc = 0
            P:UpdateMap()
        end)
    end
    if Minimap then
        self.miniLayer = CreateFrame("Frame", nil, Minimap)
        self.miniLayer:SetAllPoints(Minimap)
        self.miniLayer:SetFrameLevel((Minimap:GetFrameLevel() or 1) + 5) -- under the waypoint pin
        self.miniLayer:Hide()
        self.miniPool = dotPool(self.miniLayer)
    end
    ns:Listen("QUESTS_CHANGED", function() P:Refresh() end)
    ns:Listen("GUIDE_CHANGED", function() P:Stop("guide changed") end)
    ns:On("ZONE_CHANGED_NEW_AREA", function() P:Refresh() end)
    ns:On("PLAYER_ENTERING_WORLD", function() P:Refresh() end)
end
