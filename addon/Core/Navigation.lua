-- Questwarden - waypoints: built-in arrow, world map pin and minimap pin
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- This program is free software: you can redistribute it and/or modify it under the terms of the
-- GNU General Public License as published by the Free Software Foundation, version 3.
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
-- even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details. The complete license text is in LICENSE.
--
-- Coordinates in guides/database are zone-map percentages keyed by AreaTable id. They are
-- converted to uiMapIDs (Zones.lua) and then to world coordinates with C_Map so distance and
-- direction can be computed. If any of those APIs are missing the arrow hides itself and the
-- step text still shows plain coordinates - navigation is an aid, never a requirement.
--
-- Ownership (Nav.owner): "step" (the current guide step, FromStep), "route" (a roaming hunting route,
-- Core/Roam.lua), "patrol" (the path of a patrolling NPC, Core/Patrol.lua), "manual" (a waypoint the player asked for, such as /cg train waypoint) or
-- "corpse" (Core/Corpse.lua, while you run back as a ghost). Routes and the periodic retargeting never
-- replace a manual waypoint; a new guide step does. While the corpse owns the arrow, steps and routes
-- cannot replace it (Nav:Held); a manual waypoint can, and that dismisses the corpse arrow.

local _, ns = ...

local Nav = { target = nil, owner = nil }
ns.Nav = Nav

local C = ns.Compat
local ARRIVE_YARDS = 12

-- Target -----------------------------------------------------------------------------------------

-- Whether the corpse arrow is active and `owner` may not replace it.
function Nav:Held(owner)
    return self.owner == "corpse" and ns.Corpse and ns.Corpse:Active() and owner ~= "corpse" and owner ~= "manual"
end

function Nav:SetTarget(areaId, x, y, label, owner)
    owner = owner or "manual"
    if self:Held(owner) then return end
    local mapId = ns.DB.ZoneUiMap(areaId)
    if not mapId then
        self:Clear()
        return
    end
    self:SetMapTarget(mapId, x, y, label, owner, areaId)
end

-- Same as SetTarget for a uiMapID (the corpse position comes as one).
function Nav:SetMapTarget(mapId, x, y, label, owner, areaId)
    owner = owner or "manual"
    if self:Held(owner) then return end
    if owner == "manual" and self.owner == "corpse" and ns.Corpse then ns.Corpse:OnManual() end
    self.owner = owner
    local t = self.target
    if t and t.mapId == mapId and t.x == x and t.y == y then t.label = label or "" return end
    self.target = { area = areaId, mapId = mapId, x = x, y = y, label = label or "" }
    self:UpdateMapPin()
    self:UpdateMinimapPin()
    if self.arrow then self.arrow:SetShown(ns.db.profile.showArrow and ns.Assist:FramesAllowed()) end
end

function Nav:Clear()
    self.target, self.owner = nil, nil
    self:UpdateMapPin()
    self:UpdateMinimapPin()
    if self.arrow then self.arrow:Hide() end
end

function Nav:FromStep(step)
    if self:Held("step") then return end
    if not step then return self:Clear() end
    local z, x, y, label = ns.Patrol:TargetFor(step)
    if z then return self:SetTarget(z, x, y, label, "patrol") end
    z, x, y, label = ns.Roam:TargetFor(step)
    if z then return self:SetTarget(z, x, y, label, "route") end
    z, x, y, label = ns.StepText:Target(step)
    if z and x and y then self:SetTarget(z, x, y, label, "step") else self:Clear() end
end

-- Distance (yards) and relative angle (radians, 0 = straight ahead, + = to the left).
function Nav:Vector()
    local t = self.target
    if not t then return nil end
    local pMap, px, py = C.GetPlayerMapPosition()
    if not px then return nil end
    local c1, x1, y1 = C.MapToWorld(pMap, px, py)
    local c2, x2, y2 = C.MapToWorld(t.mapId, t.x, t.y)
    if not c1 or not c2 or c1 ~= c2 then return nil, "different continent" end
    local dx, dy = x2 - x1, y2 - y1 -- world X = north, world Y = west
    local dist = math.sqrt(dx * dx + dy * dy)
    local facing = C.GetPlayerFacing()
    if not facing then return dist end
    local angle = math.atan2(dy, dx) - facing
    return dist, angle
end

-- Minimap pin ---------------------------------------------------------------------------------
-- The minimap shows a fixed number of yards across per zoom level (fewer indoors). These are the Classic
-- client's sizes, the same ones map-pin libraries use; the pin is placed from the player's and the target's
-- world positions, turned with the player when the minimap rotates, and kept on the edge when out of range.

local MINIMAP_YARDS = {
    outdoor = { [0] = 466 + 2 / 3, 400, 333 + 1 / 3, 266 + 2 / 3, 200, 133 + 1 / 3 },
    indoor = { [0] = 300, 240, 180, 120, 80, 50 },
}

-- A function from a world position (continent, x, y) to its pixel offset from the minimap centre (right, up),
-- whether that is past the edge and how far out it is; nil for another continent. Nil without a player position.
-- Also returns the minimap radius in pixels.
function Nav:MinimapProjection()
    if not Minimap then return nil end
    local pMap, px, py = C.GetPlayerMapPosition()
    if not px then return nil end
    local c1, x1, y1 = C.MapToWorld(pMap, px, py)
    if not c1 then return nil end
    local f
    if GetCVar and GetCVar("rotateMinimap") == "1" then
        f = C.GetPlayerFacing()
        if not f then return nil end
    end
    local sizes = (IsIndoors and IsIndoors()) and MINIMAP_YARDS.indoor or MINIMAP_YARDS.outdoor
    local zoom = Minimap.GetZoom and Minimap:GetZoom() or 0
    local radius = (Minimap:GetWidth() or 140) / 2
    local scale = radius * 2 / (sizes[zoom] or sizes[0])
    return function(c2, x2, y2)
        if not c2 or c2 ~= c1 then return nil end
        local north, east = x2 - x1, -(y2 - y1) -- world X = north, world Y = west
        if f then
            north, east = -east * math.sin(f) + north * math.cos(f), east * math.cos(f) + north * math.sin(f)
        end
        local rx, ry = east * scale, north * scale
        local d = math.sqrt(rx * rx + ry * ry)
        return rx, ry, d > radius - 6, d
    end, radius
end

-- Pixel offset of the target from the minimap centre (right, up) and whether it is on the edge; nil when
-- either position is unknown or the target is on another continent.
function Nav:MinimapOffset()
    local t = self.target
    if not t then return nil end
    local proj, radius = self:MinimapProjection()
    if not proj then return nil end
    local rx, ry, edge, d = proj(C.MapToWorld(t.mapId, t.x, t.y))
    if not rx then return nil end
    if edge and d > 0 then rx, ry = rx / d * (radius - 6), ry / d * (radius - 6) end
    return rx, ry, edge
end

function Nav:UpdateMinimapPin()
    local pin = self.mpin
    if not pin then return end
    if not self.target or not ns.db.profile.showMinimapPin then pin:Hide() return end
    local rx, ry, edge = self:MinimapOffset()
    if not rx then pin:Hide() return end
    pin:ClearAllPoints()
    pin:SetPoint("CENTER", Minimap, "CENTER", rx, ry)
    pin:SetAlpha(edge and 0.6 or 1)
    pin:Show()
end

-- The waypoint look, shared by the minimap and world map pins: a purple raid-target diamond on a soft glow, so it
-- stands apart from quest-giver "!" and "?" icons (ours, the game's or another add-on's). Stock client textures.
local function waypointPin(name, parent, size)
    local pin = CreateFrame("Frame", name, parent)
    pin:SetSize(size, size)
    local glow = pin:CreateTexture(nil, "BACKGROUND")
    glow:SetPoint("CENTER")
    glow:SetSize(size * 1.9, size * 1.9)
    glow:SetTexture("Interface\\WorldMap\\UI-QuestPoi-IconGlow")
    -- The glow texture is made for additive blending (its background is black): drawn normally it shows as a
    -- black square over the map.
    glow:SetBlendMode("ADD")
    glow:SetVertexColor(0.8, 0.5, 1)
    local tex = pin:CreateTexture(nil, "OVERLAY")
    tex:SetAllPoints()
    tex:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
    tex:SetTexCoord(0.5, 0.75, 0, 0.25) -- the diamond
    pin.tex, pin.glow = tex, glow
    pin:EnableMouse(true)
    pin:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(ns.name)
        GameTooltip:AddLine(Nav.target and Nav.target.label or "", 1, 1, 1)
        GameTooltip:Show()
    end)
    pin:SetScript("OnLeave", function() GameTooltip:Hide() end)
    pin:Hide()
    return pin
end

local function createMinimapPin()
    local pin = waypointPin(ns.name .. "MinimapPin", Minimap, 16)
    pin:SetFrameLevel((Minimap:GetFrameLevel() or 1) + 10)
    -- Repositioned as the player moves and turns (on a separate frame, so it keeps running while hidden).
    local acc = 0
    local ticker = CreateFrame("Frame")
    ticker:SetScript("OnUpdate", function(_, elapsed)
        acc = acc + elapsed
        if acc < (ns.db.profile.lowQuality and 0.3 or 0.1) then return end
        acc = 0
        Nav:UpdateMinimapPin()
    end)
    return pin
end

-- World map pin --------------------------------------------------------------------------------

function Nav:UpdateMapPin()
    local pin = self.pin
    if not pin then return end
    local t = self.target
    if not t or not ns.db.profile.showMapPins or not WorldMapFrame or not WorldMapFrame:IsShown() then
        pin:Hide()
        return
    end
    local shownMap = WorldMapFrame.GetMapID and WorldMapFrame:GetMapID()
    local canvas = WorldMapFrame.GetCanvas and WorldMapFrame:GetCanvas()
    if not canvas or shownMap ~= t.mapId then pin:Hide() return end
    -- A child of the map canvas, in the canvas's own strata (the world map draws into a frame buffer, so a
    -- frame in another strata may not show), above the map's own pins.
    if pin:GetParent() ~= canvas then pin:SetParent(canvas) end
    pin:SetFrameStrata(canvas:GetFrameStrata())
    pin:SetFrameLevel((canvas:GetFrameLevel() or 1) + 2000)
    local w, h = canvas:GetWidth(), canvas:GetHeight()
    pin:ClearAllPoints()
    pin:SetPoint("CENTER", canvas, "TOPLEFT", w * t.x / 100, -h * t.y / 100)
    local scale = 1 / (canvas:GetEffectiveScale() / UIParent:GetEffectiveScale())
    pin:SetScale(math.max(scale, 0.6))
    pin:Show()
end

local function createPin()
    return waypointPin(ns.name .. "MapPin", UIParent, 22)
end

-- Time to arrival ------------------------------------------------------------------------------
-- From how fast the distance to the target has been shrinking (your speed toward it, smoothed), so it follows
-- running, mounts, flights and detours alike. Nothing while standing still or moving away, right after the
-- target changes, or after a jump (teleport, loading screen).

local ETA_SAMPLE, ETA_MIN_RATE, ETA_MAX_RATE = 0.5, 1, 80 -- seconds between samples; yards per second

-- Seconds to arrival for distance `dist` (yards) at time `now`, or nil.
function Nav:Eta(dist, now)
    local e = self.eta
    if not e or e.target ~= self.target then
        self.eta = { target = self.target, d = dist, t = now }
        return nil
    end
    local dt = now - e.t
    if dt < ETA_SAMPLE then return e.secs and math.max(0, e.secs - dt) end
    local rate = (e.d - dist) / dt
    e.d, e.t = dist, now
    if math.abs(rate) > ETA_MAX_RATE then e.rate, e.secs = nil, nil return nil end
    e.rate = e.rate and (e.rate * 0.6 + rate * 0.4) or rate
    e.secs = e.rate >= ETA_MIN_RATE and dist / e.rate or nil
    return e.secs
end

-- "0:42", "12:05", "1:02:03".
function Nav.FormatEta(secs)
    secs = math.floor(secs + 0.5)
    local h, m, sec = math.floor(secs / 3600), math.floor(secs / 60) % 60, secs % 60
    if h > 0 then return string.format("%d:%02d:%02d", h, m, sec) end
    return string.format("%d:%02d", m, sec)
end

-- Arrow ---------------------------------------------------------------------------------------

local function createArrow()
    local f = CreateFrame("Button", ns.name .. "Arrow", UIParent)
    f:SetSize(72, 92)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetClampedToScreen(true)
    f:SetScript("OnDragStart", function(self) if not ns.db.profile.locked then self:StartMoving() end end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint()
        ns.db.frames.arrow = { point = point, x = x, y = y }
    end)
    local pos = ns.db.frames.arrow
    f:SetPoint(pos.point or "TOP", UIParent, pos.point or "TOP", pos.x or 0, pos.y or -120)

    local tex = f:CreateTexture(nil, "ARTWORK")
    tex:SetSize(56, 56)
    tex:SetPoint("TOP")
    -- Stock client texture (no custom art shipped). Rotated with SetRotation.
    tex:SetTexture("Interface\\Minimap\\MinimapArrow")
    f.tex = tex

    local label = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("TOP", tex, "BOTTOM", 0, -2)
    f.label = label

    f:SetScript("OnClick", function(_, button)
        if button == "RightButton" then ns.db.profile.showArrow = false; f:Hide() end
    end)
    f:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    local acc = 0
    local hint, hintAt, hintFor -- the arrow's city/building hint, worked out once a second
    f:SetScript("OnUpdate", function(self, elapsed)
        acc = acc + elapsed
        local ms = ns.db.profile.arrowUpdateMs or 50
        if ns.db.profile.lowQuality then ms = math.max(ms, 150) end -- Low Quality Settings
        if acc < ms / 1000 then return end
        acc = 0
        local dist, angle = Nav:Vector()
        if not dist then
            self.tex:SetVertexColor(0.6, 0.6, 0.6)
            self.tex:SetRotation(0)
            local t = Nav.target
            self.label:SetText(t and string.format("%.1f, %.1f", t.x, t.y) or "")
            return
        end
        local corpse = Nav.owner == "corpse"
        if dist < ARRIVE_YARDS then
            self.tex:SetVertexColor(0.3, 1, 0.3)
            self.label:SetText(corpse and "Corpse" or "Arrived")
            local s = ns.Engine:CurrentStep()
            if Nav.owner == "step" and s and s[1] == "goto" then ns.Engine:MarkDone() end
            return
        end
        if angle then
            self.tex:SetRotation(angle)
            local a = math.abs(((angle + math.pi) % (2 * math.pi)) - math.pi)
            local g = 1 - math.min(a / math.pi, 1)
            self.tex:SetVertexColor(1 - g * 0.7, 0.4 + g * 0.6, 0.2)
        end
        local text = string.format(corpse and "Corpse %d yd" or "%d yd", math.floor(dist + 0.5))
        local eta = Nav:Eta(dist, GetTime())
        if eta then text = text .. "  " .. Nav.FormatEta(eta) end
        -- A hint about cities and buildings (Core/NavHints.lua), worked out once a second.
        local t = GetTime()
        if not hintAt or t - hintAt > 1 or hintFor ~= Nav.target then
            hintAt, hintFor = t, Nav.target
            hint = not corpse and ns.NavHints:ArrowLine() or nil
        end
        if hint then text = text .. "\n|cffff9944" .. hint .. "|r" end
        self.label:SetText(text)
    end)
    f:Hide()
    return f
end

function Nav:Init()
    self.arrow = createArrow()
    self.pin = createPin()
    if Minimap then self.mpin = createMinimapPin() end
    if WorldMapFrame then
        WorldMapFrame:HookScript("OnShow", function() Nav:UpdateMapPin() end)
        if WorldMapFrame.OnMapChanged then
            hooksecurefunc(WorldMapFrame, "OnMapChanged", function() Nav:UpdateMapPin() end)
        end
        WorldMapFrame:HookScript("OnHide", function() if Nav.pin then Nav.pin:Hide() end end)
        -- The map can change zone or zoom without OnMapChanged reaching us (or open before its map id is set),
        -- so the pin is placed again a few times a second while the map is open.
        local macc = 0
        WorldMapFrame:HookScript("OnUpdate", function(_, elapsed)
            macc = macc + elapsed
            if macc < 0.2 then return end
            macc = 0
            Nav:UpdateMapPin()
        end)
    end
    ns:Listen("STEP_CHANGED", function() Nav:FromStep(ns.Engine:CurrentStep()) end)
    ns:Listen("GUIDE_CHANGED", function() Nav:FromStep(ns.Engine:CurrentStep()) end)
    -- An objective finished (looted, killed): the arrow moves on to the next one right away.
    ns:Listen("QUESTS_CHANGED", function()
        local s = ns.Engine:CurrentStep()
        if s and s[1] == "complete" and not s.x and Nav.owner == "step" then Nav:FromStep(s) end
    end)
    -- Complete steps track the nearest objective, so retarget as the player moves.
    local t = 0
    local ticker = CreateFrame("Frame")
    ticker:SetScript("OnUpdate", function(_, elapsed)
        t = t + elapsed
        if t < 3 then return end
        t = 0
        local s = ns.Engine:CurrentStep()
        if s and s[1] == "complete" and not s.x and Nav.owner ~= "manual" and not ns.Roam.active and not ns.Patrol.active then Nav:FromStep(s) end
    end)
end

-- /qw debug nav: what the waypoint pins see (for reports when a pin does not show).
function Nav:DebugLines()
    local t, out = self.target, {}
    out[#out + 1] = t and string.format("target: %s (map %s, %.1f, %.1f), owner %s", tostring(t.label), tostring(t.mapId), t.x, t.y, tostring(self.owner)) or "target: none"
    local pMap, px, py = C.GetPlayerMapPosition()
    out[#out + 1] = string.format("player: map %s %s", tostring(pMap), px and string.format("%.1f, %.1f", px, py) or "no position")
    local rx, ry, edge = self:MinimapOffset()
    out[#out + 1] = string.format("minimap pin: setting %s, offset %s, %s", tostring(ns.db.profile.showMinimapPin),
        rx and string.format("%.0f, %.0f%s", rx, ry, edge and " (edge)" or "") or "none", self.mpin and (self.mpin:IsShown() and "shown" or "hidden") or "not created")
    local shown = WorldMapFrame and WorldMapFrame:IsShown()
    out[#out + 1] = string.format("world map pin: setting %s, map open %s, map shown %s, %s", tostring(ns.db.profile.showMapPins), tostring(shown),
        tostring(shown and WorldMapFrame.GetMapID and WorldMapFrame:GetMapID()), self.pin and (self.pin:IsShown() and "shown" or "hidden") or "not created")
    return out
end
