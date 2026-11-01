-- Questwarden - guide registry
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- This program is free software: you can redistribute it and/or modify it under the terms of the
-- GNU General Public License as published by the Free Software Foundation, version 3.
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
-- even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details. The complete license text is in LICENSE.
--
-- Compiled guide files (Guides/Compiled/*.lua, generated from guides-src/*.guide) call
-- ns.Guides:Register{...}. A malformed guide is reported and skipped; it never breaks loading.

local _, ns = ...

-- refused: guides not loaded because this client is not the build's target (Core/TargetCheck.lua).
local Guides = { list = {}, byId = {}, rejected = {}, refused = 0 }
ns.Guides = Guides

local VALID_STEP = {
    accept = true, turnin = true, complete = true, ["goto"] = true, note = true, train = true,
    fp = true, fly = true, hs = true, bind = true, level = true, travel = true, guide = true,
    talk = true, buy = true, use = true, collect = true, grind = true,
    dungeon = true, -- generated only (Completionist's run step, Core/DungeonRun.lua); guide sources have no such step
}

-- Guide text may say {name} and {slash} (docs/GUIDE_FORMAT.md) so it never spells the add-on's name.
local function expand(text)
    if type(text) ~= "string" or not string.find(text, "{", 1, true) then return text end
    return (string.gsub(string.gsub(text, "{name}", ns.name), "{slash}", ns.slash))
end

local function reject(id, why)
    Guides.rejected[#Guides.rejected + 1] = tostring(id) .. ": " .. why
    if ns.Error then ns:Error("guide rejected " .. tostring(id) .. ": " .. why) end
end

function Guides:Register(g)
    if ns.TargetCheck and not ns.TargetCheck.ok then self.refused = self.refused + 1; return end
    if type(g) ~= "table" or type(g.id) ~= "string" then return reject(g and g.id, "missing id") end
    if self.byId[g.id] then return reject(g.id, "duplicate id") end
    if g.faction ~= "Alliance" and g.faction ~= "Horde" and g.faction ~= "Both" then return reject(g.id, "bad faction") end
    if type(g.steps) ~= "table" or #g.steps == 0 then return reject(g.id, "no steps") end
    for i, s in ipairs(g.steps) do
        if type(s) ~= "table" or not VALID_STEP[s[1]] then return reject(g.id, "bad step " .. i) end
        -- A grind step without a target level would count as done at once.
        if s[1] == "grind" and type(s.level) ~= "number" then return reject(g.id, "grind step " .. i .. " needs a level") end
        if s[1] == "grind" and s.pct ~= nil and (type(s.pct) ~= "number" or s.pct <= 0 or s.pct >= 100) then return reject(g.id, "grind step " .. i .. " has a bad pct") end
        if s[1] == "dungeon" and type(s.dungeon) ~= "string" then return reject(g.id, "dungeon step " .. i .. " needs a dungeon") end
        s.index = i
        s.text = expand(s.text)
    end
    g.name = g.name or g.id
    g.minLevel = g.minLevel or 1
    g.maxLevel = g.maxLevel or g.minLevel
    self.byId[g.id] = g
    self.list[#self.list + 1] = g
    g.order = #self.list
end

-- A guide generated at runtime (Core/Completionist.lua) replaces its previous version under the same id.
-- Generated guides are kept out of the guide browser and first-login choices (g.dynamic).
function Guides:RegisterDynamic(g)
    local old = type(g) == "table" and self.byId[g.id]
    if old then
        self.byId[g.id] = nil
        for i = #self.list, 1, -1 do if self.list[i] == old then table.remove(self.list, i) end end
    end
    local before = #self.list
    self:Register(g)
    return #self.list > before
end

function Guides:Get(id) return id and self.byId[id] end

-- Does guide `g` apply to a character (race/class/faction)?
function Guides:AppliesTo(g, info)
    if g.faction ~= "Both" and info.faction and g.faction ~= info.faction then return false end
    if g.races and info.race and not ns.Contains(g.races, info.race) then return false end
    if g.classes and info.class and not ns.Contains(g.classes, info.class) then return false end
    return true
end

-- Does step `s` apply to a character?
function Guides:StepApplies(s, info)
    if s.races and info.race and not ns.Contains(s.races, info.race) then return false end
    if s.classes and info.class and not ns.Contains(s.classes, info.class) then return false end
    if s.faction and info.faction and s.faction ~= info.faction then return false end
    return true
end

-- Resolves the next guide in the route for a character (first matching `next` entry).
function Guides:NextFor(g, info)
    if not g or not g.next then return nil end
    for _, n in ipairs(g.next) do
        local ok = true
        if n.races and not ns.Contains(n.races, info.race) then ok = false end
        if n.classes and not ns.Contains(n.classes, info.class) then ok = false end
        if n.faction and n.faction ~= info.faction then ok = false end
        if ok and self.byId[n.id] then return self.byId[n.id] end
    end
end

-- Filtered, sorted list for the browser.
function Guides:Filter(f)
    local out = {}
    for _, g in ipairs(self.list) do
        local ok = not g.dynamic -- generated Completionist segments are not browsable guides
        if f.faction and g.faction ~= "Both" and g.faction ~= f.faction then ok = false end
        if ok and f.race and g.races and not ns.Contains(g.races, f.race) then ok = false end
        if ok and f.class and g.classes and not ns.Contains(g.classes, f.class) then ok = false end
        if ok and f.chapter and g.chapter ~= f.chapter then ok = false end
        if ok and f.level and (f.level < g.minLevel - 2 or f.level > g.maxLevel + 1) then ok = false end
        if ok and f.text and f.text ~= "" then
            local t = string.lower(f.text)
            if not (string.find(string.lower(g.name), t, 1, true) or string.find(string.lower(g.zoneName or ""), t, 1, true)) then ok = false end
        end
        if ok then out[#out + 1] = g end
    end
    table.sort(out, function(a, b)
        if a.minLevel ~= b.minLevel then return a.minLevel < b.minLevel end
        return a.order < b.order
    end)
    return out
end
