-- Questwarden - supply reminders before you leave town (setting: supplyReminders)
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- This program is free software: you can redistribute it and/or modify it under the terms of the
-- GNU General Public License as published by the Free Software Foundation, version 3.
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
-- even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details. The complete license text is in LICENSE.
--
-- A line in the step window only; it never buys anything. Shown when all of these hold:
--   * the current step is a town step (TOWN_KINDS) with a position, and you are within NEAR_YARDS of it;
--   * from level MIN_LEVEL, your bags hold less than LOW of something you need:
--       food (everyone; only food you are high enough to eat), drink (classes with mana),
--       arrows or bullets for a hunter's bow, crossbow or gun (the ranged slot decides which);
--   * a vendor of your faction that sells it stands within TOWN_YARDS of the step (Database/Supplies.lua, from the
--     CMaNGOS vendor lists). Needs with no such vendor are left out.
-- Warlocks from level SHARD_LEVEL also hear when they carry fewer than LOW.shard Soul Shards; no vendor sells
-- those, so that part needs no vendor.

local _, ns = ...

local S = { current = nil }
ns.Supplies = S

local C = ns.Compat
local MIN_LEVEL = 5
local SHARD_LEVEL = 10
local SOUL_SHARD = 6265
local LOW = { food = 10, drink = 10, arrow = 400, bullet = 400, shard = 3 }
local NEAR_YARDS = 200     -- you are in town: this close to the step
local TOWN_YARDS = 150     -- a vendor "here": this close to the step
local CHECK = 5
local TOWN_KINDS = { turnin = true, accept = true, train = true, buy = true, bind = true, fp = true, talk = true }
local SELLS = { food = 1, drink = 2, arrow = 4, bullet = 8 }
local NO_MANA = { WARRIOR = true, ROGUE = true }
local WORDS = { food = "food", drink = "drinks", arrow = "arrows", bullet = "bullets" }
-- Ranged weapon subclass (item class 2) -> the ammo it fires.
local AMMO_FOR = { [2] = "arrow", [18] = "arrow", [3] = "bullet" }

local function prof() return ns.db.profile end
local function data() return ns.SupplyData end

-- What your bags hold: food, drink (usable at `level`), arrows, bullets and Soul Shards.
function S.Counts(level)
    local d = data() or {}
    local n = { food = 0, drink = 0, arrow = 0, bullet = 0, shard = 0 }
    for bag = 0, C.NUM_BAGS do
        for slot = 1, C.GetContainerNumSlots(bag) do
            local it = C.GetContainerItem(bag, slot)
            local id, count = it and it.itemID, it and it.count or 1
            if id then
                local f, dr, a = d.food and d.food[id], d.drink and d.drink[id], d.ammo and d.ammo[id]
                if f and f <= level then n.food = n.food + count end
                if dr and dr <= level then n.drink = n.drink + count end
                if a then n[a] = n[a] + count end
                if id == SOUL_SHARD then n.shard = n.shard + count end
            end
        end
    end
    return n
end

-- The ammo your equipped ranged weapon fires, or nil.
function S.AmmoKind()
    local id = GetInventoryItemID and GetInventoryItemID("player", 18)
    local d = id and ns.Gear and ns.Gear:ItemData(id)
    return d and d.classID == 2 and AMMO_FOR[d.subclassID] or nil
end

-- What you are short of: { {kind=, have=}, ... } in a fixed order. No side effects.
function S.Needs(info, counts)
    local out = {}
    if info.level < MIN_LEVEL then return out end
    local function want(kind) if counts[kind] < LOW[kind] then out[#out + 1] = { kind = kind, have = counts[kind] } end end
    want("food")
    if not NO_MANA[info.class] then want("drink") end
    local ammo = info.class == "HUNTER" and S.AmmoKind()
    if ammo then want(ammo) end
    return out
end

-- Vendors of your faction within TOWN_YARDS of `target` (a world position): { {id, rec, yards}, ... }, nearest first.
function S.VendorsNear(target, faction)
    local out = {}
    local tag = faction == "Alliance" and "A" or faction == "Horde" and "H" or nil
    for id, v in pairs(data() and data().vendors or {}) do
        if tag and string.find(v[3], tag, 1, true) then
            local map = ns.DB.ZoneUiMap(v[5])
            local best
            for k = 6, #v do
                local yd = map and ns.Hearth.Yards(target, ns.Hearth.World(map, v[k][1], v[k][2]))
                if yd and (not best or yd < best) then best = yd end
            end
            if best and best <= TOWN_YARDS then out[#out + 1] = { id = id, rec = v, yards = best } end
        end
    end
    table.sort(out, function(a, b) if a.yards ~= b.yards then return a.yards < b.yards end return a.id < b.id end)
    return out
end

local function joinWords(t)
    if #t <= 1 then return t[1] or "" end
    return table.concat(t, ", ", 1, #t - 1) .. " and " .. t[#t]
end

-- The reminder for the current step: { needs = {...}, sellers = { {name=, kinds={...}}, ... }, shards = n|nil },
-- or nil and a reason. No side effects.
function S:Suggest()
    if not prof().supplyReminders then return nil, "setting off" end
    local s = ns.Engine and ns.Engine:CurrentStep()
    if not (s and TOWN_KINDS[s[1]]) then return nil, "not a town step" end
    if UnitOnTaxi and UnitOnTaxi("player") then return nil, "on a flight" end
    local z, x, y = ns.StepText:Target(s)
    local m = z and ns.DB.ZoneUiMap(z)
    local target = m and ns.Hearth.World(m, x, y)
    if not target then return nil, "the step has no position" end
    local pMap, px, py = C.GetPlayerMapPosition()
    local me = px and ns.Hearth.World(pMap, px, py)
    local away = me and ns.Hearth.Yards(me, target)
    if not away or away > NEAR_YARDS then return nil, "not in town" end
    local info = C.PlayerInfo()
    local counts = self.Counts(info.level)
    local shards = info.class == "WARLOCK" and info.level >= SHARD_LEVEL and counts.shard < LOW.shard and counts.shard or nil
    local needs, sellers, byName = {}, {}, {}
    local near = self.VendorsNear(target, info.faction)
    for _, n in ipairs(self.Needs(info, counts)) do
        for _, v in ipairs(near) do
            if ns.HasBit(v.rec[4], SELLS[n.kind]) then
                needs[#needs + 1] = n
                local e = byName[v.rec[1]]
                if not e then
                    e = { name = v.rec[1], sub = v.rec[2] or nil, kinds = {} }
                    byName[v.rec[1]] = e
                    sellers[#sellers + 1] = e
                end
                e.kinds[#e.kinds + 1] = WORDS[n.kind]
                break
            end
        end
    end
    if #needs == 0 and not shards then return nil, "nothing needed here" end
    return { needs = needs, sellers = sellers, shards = shards }
end

-- The step window line, or nil.
function S:Line()
    local d = self.current
    if not d then return nil end
    local parts = {}
    if #d.needs > 0 then
        local have = {}
        for _, n in ipairs(d.needs) do have[#have + 1] = n.have .. " " .. WORDS[n.kind] end
        local who = {}
        for _, e in ipairs(d.sellers) do
            who[#who + 1] = e.name .. (e.sub and (" (" .. e.sub .. ")") or "") .. " sells " .. joinWords(e.kinds)
        end
        parts[#parts + 1] = "Stock up before you leave town: you have " .. joinWords(have) .. ". " .. table.concat(who, "; ") .. "."
    end
    if d.shards then
        parts[#parts + 1] = string.format("You have %d Soul Shard%s: use Drain Soul on a few mobs as they die on your way out.",
            d.shards, d.shards == 1 and "" or "s")
    end
    return table.concat(parts, " ")
end

-- Re-checks the reminder; redraws the guide window when the line changes.
function S:Check()
    local d, why = self:Suggest()
    local before = self:Line()
    self.current, self.why = d, why
    if self:Line() ~= before then
        ns:Debug("supplies: " .. (d and "remind" or ("none: " .. tostring(why))))
        ns:Fire("REFRESH")
    end
end

function S:Init()
    ns:Listen("STEP_CHANGED", function() S:Check() end)
    ns:On("BAG_UPDATE_DELAYED", function() S:Check() end)
    ns:On("PLAYER_LEVEL_UP", function() C_Timer.After(1, function() S:Check() end) end)
    local acc = 0
    local f = CreateFrame("Frame")
    f:SetScript("OnUpdate", function(_, elapsed)
        acc = acc + elapsed
        if acc < CHECK then return end
        acc = 0
        S:Check()
    end)
end
