-- ClassicGuide - world map pins for dangerous mobs (elites and rares), treasure chests and spirit healers
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- This program is free software: you can redistribute it and/or modify it under the terms of the
-- GNU General Public License as published by the Free Software Foundation, version 3.
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
-- even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details. The complete license text is in LICENSE.
--
-- Positions come from the bundled QuestieDB-derived data. Its NPC table is the quest/service subset
-- plus the mobs quests involve; targets with questie.allDangerousMobs (Classic Era) also keep every
-- hostile elite and rare with spawns. The chest list is every object named "... Chest" with spawns
-- in the shown zone. Spirit healers come from Database/Questie/SpiritHealers.lua (one per graveyard;
-- empty on targets without it).

local _, ns = ...

local MX = { pins = {}, byZone = nil }
ns.MapExtras = MX

local function prof() return ns.db.profile end

MX.MAX_PINS = 80
MX.MAX_PINS_LOW = 25

-- Builds zone -> { {kind, name, x, y, level, rank} } once, from the bundled tables.
function MX:Index()
    if self.byZone then return self.byZone end
    local QDB, N, O = ns.QDB, ns.QDB.NPC, ns.QDB.OBJECT
    local z = {}
    local function add(zone, e) z[zone] = z[zone] or {} table.insert(z[zone], e) end
    for id, r in pairs(QDB.npcs) do
        local rank = r[N.RANK] or 0
        if (rank == 1 or rank == 2 or rank == 4) and not r[N.FRIENDLY] then
            for zone, pts in pairs(r[N.SPAWNS] or {}) do
                for i, p in ipairs(pts) do
                    if i > 3 then break end -- a few points per mob type are enough on a map
                    add(zone, { kind = (rank == 1) and "elite" or "rare", name = r[N.NAME], id = id, x = p[1], y = p[2],
                                level = r[N.MAX_LEVEL] or r[N.MIN_LEVEL], rank = rank, patrols = r[N.PATROLS] and true or nil })
                end
            end
        end
    end
    for id, r in pairs(QDB.objects) do
        local name = r[O.NAME]
        if type(name) == "string" and string.find(name, "Chest$") then
            for zone, pts in pairs(r[O.SPAWNS] or {}) do
                for _, p in ipairs(pts) do add(zone, { kind = "treasure", name = name, id = id, x = p[1], y = p[2] }) end
            end
        end
    end
    for zone, pts in pairs(QDB.spiritHealers or {}) do
        for _, p in ipairs(pts) do add(zone, { kind = "spirit", name = "Spirit Healer", x = p[1], y = p[2] }) end
    end
    -- Spirit healers (a few per zone) and rares first, then elites, then chests, so the pin cap never
    -- hides them; by name within a kind.
    local order = { spirit = 0, rare = 1, elite = 2, treasure = 3 }
    for _, l in pairs(z) do
        table.sort(l, function(a, b)
            if order[a.kind] ~= order[b.kind] then return order[a.kind] < order[b.kind] end
            if a.name ~= b.name then return tostring(a.name) < tostring(b.name) end
            if a.x ~= b.x then return a.x < b.x end
            return a.y < b.y
        end)
    end
    self.byZone = z
    return z
end

-- Entries to show on uiMap `mapId` with the current settings.
function MX:Entries(mapId)
    local p = prof()
    if not (p.tipsEnabled and (p.trackMobsMap or p.trackTreasures or p.trackSpiritHealers)) then return {} end
    local area = mapId and ns.DB.AreaForUiMap(mapId)
    local list = area and self:Index()[area] or {}
    local out = {}
    local cap = p.lowQuality and self.MAX_PINS_LOW or self.MAX_PINS
    for _, e in ipairs(list) do
        local want
        if e.kind == "treasure" then want = p.trackTreasures
        elseif e.kind == "spirit" then want = p.trackSpiritHealers
        else want = p.trackMobsMap end
        if want and not (e.kind == "rare" and p.skipKilledRares and ns.char.killedRares[e.id]) then
            out[#out + 1] = e
            if #out >= cap then break end
        end
    end
    return out
end

local TEX = {
    elite = "Interface\\TargetingFrame\\UI-TargetingFrame-Skull",
    rare = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1",
    treasure = "Interface\\Icons\\INV_Box_02",
    spirit = "Interface\\Icons\\Spell_Holy_Resurrection",
}

function MX:Pin(i)
    local pin = self.pins[i]
    if pin then return pin end
    pin = CreateFrame("Frame", nil, UIParent)
    pin:SetSize(14, 14)
    local t = pin:CreateTexture(nil, "OVERLAY")
    t:SetAllPoints()
    pin.tex = t
    pin:EnableMouse(true)
    pin:SetScript("OnEnter", function(s)
        local e = s.entry
        if not e then return end
        GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
        GameTooltip:AddLine(e.name)
        if e.kind == "treasure" then GameTooltip:AddLine("Treasure", 1, 0.82, 0)
        elseif e.kind == "spirit" then GameTooltip:AddLine("Graveyard: you appear here as a ghost.", 0.6, 0.8, 1)
        else
            GameTooltip:AddLine((e.kind == "rare" and "Rare" or "Elite") .. (e.level and (", level " .. e.level) or ""), 1, 0.4, 0.3)
            if e.patrols then GameTooltip:AddLine("Patrols: it may not be where the pin is.", 1, 0.82, 0) end
        end
        GameTooltip:Show()
    end)
    pin:SetScript("OnLeave", function() GameTooltip:Hide() end)
    pin:Hide()
    self.pins[i] = pin
    return pin
end

function MX:Update()
    if not ns.db then return end
    local list = {}
    local canvas
    if WorldMapFrame and WorldMapFrame:IsShown() and WorldMapFrame.GetCanvas then
        canvas = WorldMapFrame:GetCanvas()
        list = self:Entries(WorldMapFrame.GetMapID and WorldMapFrame:GetMapID())
    end
    local w, h = canvas and canvas:GetWidth() or 0, canvas and canvas:GetHeight() or 0
    for i, e in ipairs(list) do
        local pin = self:Pin(i)
        if pin:GetParent() ~= canvas then pin:SetParent(canvas) end
        pin.entry = e
        pin.tex:SetTexture(TEX[e.kind])
        pin:ClearAllPoints()
        pin:SetPoint("CENTER", canvas, "TOPLEFT", w * e.x / 100, -h * e.y / 100)
        pin:SetFrameStrata("HIGH")
        pin:Show()
    end
    for i = #list + 1, #self.pins do self.pins[i]:Hide() self.pins[i].entry = nil end
end

function MX:Init()
    if not WorldMapFrame then return end
    WorldMapFrame:HookScript("OnShow", function() MX:Update() end)
    WorldMapFrame:HookScript("OnHide", function() MX:Update() end)
    if WorldMapFrame.OnMapChanged and hooksecurefunc then
        hooksecurefunc(WorldMapFrame, "OnMapChanged", function() MX:Update() end)
    end
end
