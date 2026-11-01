-- Questwarden - class trainer suggestions
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- This program is free software: you can redistribute it and/or modify it under the terms of the
-- GNU General Public License as published by the Free Software Foundation, version 3.
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
-- even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details. The complete license text is in LICENSE.
--
-- Which spell ranks your class trainer has for you now, from the client's own tables
-- (Classes/TrainingData.lua) checked live against your spellbook (IsSpellKnown). Setting
-- "Class Trainer Suggestions": Off / Important only / All (docs/TRAINER.md).
--   - Talent ranks are listed only once you know the rank before (that is, took the talent).
--   - Spells from class quests are listed apart and never count as a reason to visit a trainer.
--   - Race-only spells are listed only for that race.
-- Suggestions only inform. Nothing is bought here; the separate, opt-in "Auto-train" assist is the
-- only thing in Questwarden that ever spends money at a trainer.

local _, ns = ...

local TR = { cache = {} }
ns.Trainer = TR

local PRIO_NAME = { "important", "useful", "optional" }
TR.PRIO_NAME = PRIO_NAME

local function prof() return ns.db.profile end

local function raceBit(race)
    local b = ns.QDB and ns.QDB.RACE_BITS and ns.QDB.RACE_BITS[race]
    return b or 0
end

-- Where a rank is learned (e.source): "trainer" = sold by the class trainer; "quest" = a class quest (our notes);
-- "other" = not sold by the class trainer according to What's Training? (books, drops, vendors, quests our notes do
-- not name; how exactly is not known here). Without What's Training data for this game (Forever) every non-quest rank
-- counts as "trainer", as before.
-- The class's entries, with priority, source, baseline price and requirements resolved once.
function TR:Entries(class)
    if self.cache[class] then return self.cache[class] end
    local data = ns.TrainingData and ns.TrainingData.classes[class] or {}
    local wt = ns.WhatsTrainingData and ns.WhatsTrainingData.classes and ns.WhatsTrainingData.classes[class]
    if wt and not next(wt) then wt = nil end
    local notes = ns.TrainingNotes or {}
    local imp, opt = {}, {}
    for _, n in ipairs((notes.important or {})[class] or {}) do imp[n] = true end
    for _, n in ipairs((notes.optional or {})[class] or {}) do opt[n] = true end
    local quest = (notes.quest or {})[class] or {}
    local function prioOf(name)
        if not name then return 2 end
        local prio = imp[name] and 1 or opt[name] and 3 or 2
        if prio == 2 then
            for _, pat in ipairs(notes.optionalPattern or {}) do
                if string.find(name, pat) then prio = 3 break end
            end
        end
        return prio
    end
    -- What's Training row -> requirements: previous ranks, talent, faction, races (as our race mask), skill.
    local function applyWT(e, w)
        e.source, e.listCost, e.level = "trainer", w[2], w[1]
        e.req = (#w[3] > 0) and w[3] or nil
        e.talentReq = w[4] ~= 0 and w[4] or nil
        e.faction = w[5] ~= "" and w[5] or nil
        if w[6] then
            local mask = 0
            for _, r in ipairs(w[6]) do mask = mask + raceBit(r) end
            e.race = mask
        end
        e.skill = w[7] and w[7][1] or nil
    end
    local out, seen = {}, {}
    for _, r in ipairs(data) do
        local name = r[5]
        local e = { id = r[1], level = r[2], rank = r[3], prev = r[4], name = name, talent = r[6] == 1,
            race = r[7], prio = prioOf(name), quest = quest[r[1]] }
        local w = wt and wt[r[1]]
        if w then applyWT(e, w)
        elseif e.quest then e.source = "quest"
        else e.source = wt and "other" or "trainer" end
        seen[e.id] = true
        out[#out + 1] = e
    end
    -- Trainer ranks the client-table import leaves out (passives such as Parry or Dual Wield, level-1 spells): the
    -- name comes from the client at display time.
    for id, w in pairs(wt or {}) do
        if not seen[id] then
            local e = { id = id, rank = 0, prev = 0, talent = w[4] ~= 0, race = 0, prio = 2 }
            applyWT(e, w)
            out[#out + 1] = e
        end
    end
    table.sort(out, function(a, b) if a.level ~= b.level then return a.level < b.level end return a.id < b.id end)
    self.cache[class] = out
    return out
end

-- nil when the client cannot tell (then suggestions are not shown at all).
function TR.Known(id)
    if IsSpellKnown then return IsSpellKnown(id) and true or false end
    if IsPlayerSpell then return IsPlayerSpell(id) and true or false end
    return nil
end

function TR.CanCheck() return (IsSpellKnown or IsPlayerSpell) and true or false end

-- Localized name and rank text from the client; the English data name if the client has none.
function TR.SpellName(e)
    local n = GetSpellInfo and GetSpellInfo(e.id)
    return n or e.name or ("spell " .. tostring(e.id))
end

-- Status of one entry for this character: "ready", "later", "known", "talent" (needs the talent or the rank
-- before it), "prereq" (needs an earlier rank first), "quest", "other" (not from the class trainer), "race",
-- "faction".
function TR:Status(e, level, race, faction)
    if e.race ~= 0 and not ns.HasBit(e.race, raceBit(race)) then return "race" end
    if e.faction and faction and e.faction ~= faction then return "faction" end
    if TR.Known(e.id) then return "known" end
    if e.source == "quest" or e.quest then return "quest" end
    if e.source == "other" then return "other" end
    if e.level > level then return "later" end
    if e.talentReq and not TR.Known(e.talentReq) then return "talent" end
    if e.talent and not e.talentReq and e.prev ~= 0 and not TR.Known(e.prev) then return "talent" end
    if e.req then
        for _, id in ipairs(e.req) do if not TR.Known(id) then return "prereq" end end
    end
    return "ready"
end

-- Per character once chosen (setup wizard or settings: ns.char.trainerSuggestions); before that the settings
-- profile's value, so existing characters keep what they had.
function TR:Mode()
    local m = ns.char and ns.char.trainerSuggestions or prof().trainerSuggestions
    if m == "off" or m == "important" or m == "all" then return m end
    return "important"
end

-- What the trainer has for you now: { ready = {entries}, quest = {entries}, other = {entries}, level = n }.
-- `mode` overrides the setting ("important" or "all"); deferred levels are ignored here. A rank whose earlier rank
-- you do not know yet is ready when that earlier rank is ready too (you can buy both in one visit, in order).
function TR:Available(mode, level)
    local info = ns.Compat.PlayerInfo()
    level = level or info.level
    mode = mode or self:Mode()
    local res = { ready = {}, quest = {}, other = {}, level = level }
    if mode == "off" or not TR.CanCheck() then return res end
    local entries, st, ready = self:Entries(info.class), {}, {}
    for _, e in ipairs(entries) do
        st[e] = self:Status(e, level, info.race, info.faction)
        if st[e] == "ready" then ready[e.id] = true end
    end
    local changed = true
    while changed do
        changed = false
        for _, e in ipairs(entries) do
            if st[e] == "prereq" then
                local ok = true
                for _, id in ipairs(e.req) do if not (TR.Known(id) or ready[id]) then ok = false break end end
                if ok then st[e], ready[e.id], changed = "ready", true, true end
            end
        end
    end
    for _, e in ipairs(entries) do
        local s = st[e]
        if s == "ready" and (mode == "all" or e.prio == 1) then res.ready[#res.ready + 1] = e
        elseif s == "quest" and e.level <= level then res.quest[#res.quest + 1] = e
        elseif s == "other" and e.level <= level then res.other[#res.other + 1] = e end
    end
    table.sort(res.ready, function(a, b)
        if a.prio ~= b.prio then return a.prio < b.prio end
        if a.level ~= b.level then return a.level < b.level end
        local an, bn = a.name or TR.SpellName(a), b.name or TR.SpellName(b)
        if an ~= bn then return an < bn end
        if a.rank ~= b.rank then return a.rank < b.rank end
        return a.id < b.id
    end)
    return res
end

-- Grouped one line per spell: "Rend (Rank 2, 3)".
function TR.Group(list)
    local out, at = {}, {}
    for _, e in ipairs(list) do
        local key = e.name or TR.SpellName(e)
        local g = at[key]
        if not g then
            g = { name = TR.SpellName(e), prio = e.prio, ranks = {}, first = e, entries = {} }
            at[key] = g
            out[#out + 1] = g
        end
        if e.rank > 0 then g.ranks[#g.ranks + 1] = e.rank end
        g.entries[#g.entries + 1] = e
    end
    return out
end

function TR.GroupText(g)
    if #g.ranks == 0 then return g.name end
    local r = {}
    for i, n in ipairs(g.ranks) do r[i] = tostring(n) end
    return g.name .. " (Rank " .. table.concat(r, ", ") .. ")"
end

-- Automatic training (Core/Assist.lua TrainerStep): "off", "recommended" (only the ranks the suggestions list:
-- important ones, or all with suggestions set to All) or "all" (everything the trainer offers that you can afford).
-- Per character (ns.char.autoTrain, setup wizard or settings). A character that never chose keeps the old profile
-- switch "Trainer automation" (trainerAuto), which meant "all".
function TR:AutoTrainMode()
    local m = ns.char and ns.char.autoTrain
    if m == "off" or m == "recommended" or m == "all" then return m end
    return prof().trainerAuto and "all" or "off"
end

-- The ranks automatic training may buy in "recommended" mode: { [spell id] = true }.
function TR:RecommendedSet()
    local mode = self:Mode() == "all" and "all" or "important"
    local set = {}
    for _, e in ipairs(self:Available(mode).ready) do set[e.id] = true end
    return set
end

-- The data entry for a trainer service (localized name + rank), or nil.
function TR:EntryForService(name, rankText)
    if not name then return nil end
    local rank = tonumber(string.match(rankText or "", "(%d+)")) or 0
    return self:NameIndex(ns.Compat.PlayerInfo().class)[string.lower(name) .. "#" .. rank]
end

-- Deferred: hidden until you reach a higher level (or "Show trainer suggestions again").
function TR:Deferred()
    local d = ns.char.trainerDeferLevel
    return type(d) == "number" and (UnitLevel("player") or 1) <= d
end

function TR:Defer()
    self.skipCache = nil
    ns.char.trainerDeferLevel = UnitLevel("player") or 1
    ns:Fire("TRAINER_CHANGED")
    if ns.Engine and ns.Engine.Refresh then ns.Engine:Refresh() end
end

function TR:ViewAgain()
    ns.char.trainerDeferLevel = nil
    ns:Fire("TRAINER_CHANGED")
    if ns.Engine and ns.Engine.Refresh then ns.Engine:Refresh() end
    self:Report(true)
end

-- Route: a train step is skipped when, for the chosen setting, the trainer has nothing new.
-- Off keeps the old behaviour (train steps always shown). Unknown (no spell API) never skips.
function TR:SkipReason()
    if self:Mode() == "off" or not TR.CanCheck() then return nil end
    if self:Deferred() then return "training deferred until your next level" end
    -- One spellbook check per refresh is enough for every train step of the guide.
    local now, key = GetTime and GetTime() or 0, self:Mode() .. (UnitLevel("player") or 1)
    local c = self.skipCache
    if not (c and c.key == key and now - c.at < 1) then
        c = { key = key, at = now, n = #self:Available().ready }
        self.skipCache = c
    end
    if c.n == 0 then
        return self:Mode() == "important" and "nothing important to train yet" or "nothing new to train yet"
    end
    return nil
end

-- Training costs --------------------------------------------------------------------------------------
-- The client tables carry no trainer prices, so prices come from the trainer window itself:
--   "current": the class trainer you have open right now (GetTrainerServiceCost, which already
--              includes any reputation discount you get there);
--   "seen":    what a class trainer charged a character of this account before (saved in
--              QuestwardenDB.trainCosts); another trainer or reputation can change it;
--   nil:       unknown - never guessed.
-- Amounts are integer copper. Nothing here buys anything.
TR.live = {}

local function costCache()
    local db = ns.db
    if type(db.trainCosts) ~= "table" then db.trainCosts = {} end
    return db.trainCosts
end

-- Localized name + rank number -> entry, for matching trainer services to the data.
function TR:NameIndex(class)
    self.nameIndex = self.nameIndex or {}
    if self.nameIndex[class] then return self.nameIndex[class] end
    local idx = {}
    for _, e in ipairs(self:Entries(class)) do
        idx[string.lower(TR.SpellName(e)) .. "#" .. e.rank] = e
    end
    self.nameIndex[class] = idx
    return idx
end

function TR:ScanTrainer()
    if IsTradeskillTrainer and IsTradeskillTrainer() then return end
    if not (GetNumTrainerServices and GetTrainerServiceInfo and GetTrainerServiceCost) then return end
    local idx = self:NameIndex(ns.Compat.PlayerInfo().class)
    local cache, now, found = costCache(), time and time() or 0, 0
    self.live = {}
    for i = 1, GetNumTrainerServices() or 0 do
        local name, rankText, kind = GetTrainerServiceInfo(i)
        if name and kind ~= "header" then
            local rank = tonumber(string.match(rankText or "", "(%d+)")) or 0
            local e = idx[string.lower(name) .. "#" .. rank]
            local c = GetTrainerServiceCost(i)
            if e and type(c) == "number" and c >= 0 then
                self.live[e.id] = c
                cache[e.id] = { c = c, t = now }
                found = found + 1
            end
        end
    end
    self.trainerOpen = found > 0
    ns:Fire("TRAINER_CHANGED")
end

-- copper, "current" | "seen" | "listed" | nil. "listed" is the baseline trainer price from What's Training?, before
-- reputation discounts, so the trainer may charge less.
function TR:Cost(e)
    if self.trainerOpen and self.live[e.id] then return self.live[e.id], "current" end
    local c = costCache()[e.id]
    if type(c) == "table" and type(c.c) == "number" then return c.c, "seen" end
    if type(e.listCost) == "number" then return e.listCost, "listed" end
    return nil, nil
end

-- The bill for a list of entries: total copper of the known prices, how many prices are unknown
-- or only "seen", and whether the total is complete.
function TR:Bill(list)
    local b = { total = 0, unknown = 0, seen = 0, listed = 0, n = #list }
    for _, e in ipairs(list) do
        local c, kind = self:Cost(e)
        if c then
            b.total = b.total + c
            if kind == "seen" then b.seen = b.seen + 1 end
            if kind == "listed" then b.listed = b.listed + 1 end
        else
            b.unknown = b.unknown + 1
        end
    end
    b.complete = b.unknown == 0
    return b
end

local function money(c) return ns.Compat.FormatMoney(c) end

function TR.BillText(b, label)
    if b.n == 0 then return nil end
    if b.total == 0 and b.unknown == b.n then return label .. ": cost unknown until you open a class trainer." end
    local t = label .. ": " .. money(b.total)
    if not b.complete then t = t .. " |cffffaa55(partial: " .. b.unknown .. " price(s) unknown)|r" end
    if b.seen > 0 then t = t .. " |cff999999(" .. b.seen .. " last seen at a trainer)|r" end
    if b.listed > 0 then t = t .. " |cff999999(" .. b.listed .. " at the listed base price; a reputation discount can lower it)|r" end
    if b.complete then
        local have = GetMoney and GetMoney() or 0
        t = t .. (have >= b.total and " - you can afford it." or (" - you are " .. money(b.total - have) .. " short."))
    end
    return t
end

local function groupCost(g)
    local total, unknown = 0, false
    for _, e in ipairs(g.entries) do
        local c = TR:Cost(e)
        if c then total = total + c else unknown = true end
    end
    if unknown and total == 0 then return "" end
    return " |cffcccccc" .. money(total) .. (unknown and "+?" or "") .. "|r"
end

-- Lines for a train step (and the report): the top suggestions, then quest spells.
function TR:Lines(max)
    local lines = {}
    if self:Mode() == "off" then return lines end
    if not TR.CanCheck() then
        lines[1] = "This client cannot tell which spells you know, so no trainer list is shown."
        return lines
    end
    if self:Deferred() then
        lines[1] = "Trainer suggestions hidden until your next level (/" .. ns.slash .. " train shows them)."
        return lines
    end
    local a = self:Available()
    local groups = TR.Group(a.ready)
    max = max or 6
    for i, g in ipairs(groups) do
        if i > max then lines[#lines + 1] = "... and " .. (#groups - max) .. " more (/" .. ns.slash .. " train)" break end
        lines[#lines + 1] = "- " .. TR.GroupText(g) .. groupCost(g) .. (g.prio ~= 1 and (" |cff999999" .. PRIO_NAME[g.prio] .. "|r") or "")
    end
    for _, e in ipairs(a.quest) do lines[#lines + 1] = "- " .. TR.SpellName(e) .. " |cff999999(" .. e.quest .. ")|r" end
    if #a.other > 0 then
        local names = {}
        for _, g in ipairs(TR.Group(a.other)) do names[#names + 1] = TR.GroupText(g) end
        lines[#lines + 1] = "|cff999999Not from the class trainer (a book, drop, vendor or quest): " .. table.concat(names, ", ") .. "|r"
    end
    -- Totals: everything listed; with "All", important and the rest separately too.
    local imp, rest = {}, {}
    for _, e in ipairs(a.ready) do if e.prio == 1 then imp[#imp + 1] = e else rest[#rest + 1] = e end end
    local t = TR.BillText(self:Bill(a.ready), "Total")
    if t then lines[#lines + 1] = t end
    if #rest > 0 and #imp > 0 then
        lines[#lines + 1] = TR.BillText(self:Bill(imp), "Important")
        lines[#lines + 1] = TR.BillText(self:Bill(rest), "Useful and optional")
    end
    if ns.PetSkills then for _, l in ipairs(ns.PetSkills:Lines(3)) do lines[#lines + 1] = l end end
    return lines
end

-- Nearest class trainer of your faction: same zone first, else your capital. zone, x, y, name.
TR.CAPITALS = { Alliance = { 1519, 1537, 1657, 3557 }, Horde = { 1637, 1497, 1638, 3487 } }
local function classSub()
    local info = ns.Compat.PlayerInfo()
    return info.class and (info.class:sub(1, 1) .. info.class:sub(2):lower() .. " Trainer")
end

function TR:NearestTrainer()
    return self:NearestNPC(classSub())
end

-- Where a train step sends you: the class trainer nearest to you in the zone you are in (Goldshire's, not
-- Northshire's, once you have left the valley). With none there: the cheapest flight you know to a zone with
-- your class trainer (Core/FlightPaths.lua), and the arrow goes to the flight master. Else the trainer the guide
-- names, else your capital's. zone, x, y, name, flight plan (nil, or { from, to, cost, hops, trainer, master }).
function TR:TrainerFor(s)
    local sub = classSub()
    local z, x, y, name = self:NearestHere(sub)
    if z then return z, x, y, name end
    local plan = self:FlightPlan()
    if plan then
        local n = ns.Flights.nodes[plan.from]
        return n.zone, n.x, n.y, plan.master or n.name, plan
    end
    if s and s.z and s.x and s.y then return s.z, s.x, s.y, s.npc end
    return self:NearestNPC(sub)
end

-- The cheapest known flight to a zone with your class trainer, plus that trainer's and the flight master's
-- names; nil when you know no such flight from the zone you are in.
function TR:FlightPlan()
    local FPs = ns.FlightPaths
    if not (FPs and ns.Flights) then return nil end
    local plan = FPs:CheapestTo(function(zone) return self:TrainerIn(zone) ~= nil end)
    if not plan then return nil end
    local from, to = ns.Flights.nodes[plan.from], ns.Flights.nodes[plan.to]
    plan.trainer = select(4, self:TrainerIn(to.zone))
    plan.master = from.npc and ns.DB.GetNPCName(from.npc) or nil
    return plan
end

-- One line describing a flight plan for the step details.
function TR.FlightText(plan)
    local F = ns.Flights.nodes
    local from, to = F[plan.from], F[plan.to]
    local price = plan.cost and ns.Compat.FormatMoney(plan.cost) or "price not seen yet"
    return "No class trainer in this zone. Cheapest known flight: " .. from.name .. " to " .. to.name .. " (" .. price
        .. (plan.hops > 1 and (", " .. plan.hops .. " flights") or "") .. "), then " .. tostring(plan.trainer) .. "."
end

-- Friendly NPCs of your faction with this English sub-name, as a list of ids (one scan per sub-name and
-- faction; the bundled data does not change while you play).
TR.npcsBy = {}
local function npcsWithSub(sub)
    local info = ns.Compat.PlayerInfo()
    local key = tostring(sub) .. "|" .. tostring(info.faction)
    if TR.npcsBy[key] then return TR.npcsBy[key] end
    local side = info.faction == "Alliance" and "A" or "H"
    local N, list = ns.QDB.NPC, {}
    for id, r in pairs(ns.QDB.npcs) do
        local f = r[N.FRIENDLY]
        if sub and r[N.SUBNAME] == sub and f and string.find(f, side, 1, true) then list[#list + 1] = id end
    end
    table.sort(list)
    TR.npcsBy[key] = list
    return list
end

-- The NPC with this sub-name nearest to you in the zone you are in: zone, x, y, name; nil when the zone has
-- none (or your position is unknown). Measured from where you stand each call.
function TR:NearestHere(sub)
    local mapId, px, py = ns.Compat.GetPlayerMapPosition()
    local here = mapId and ns.DB.AreaForUiMap(mapId)
    if not (here and px and py) then return nil end
    local best, bestD
    for _, id in ipairs(npcsWithSub(sub)) do
        local z, x, y = ns.DB.GetNPCPosition(id, here, px, py) -- px, py: 0-100 like the data
        if z == here then
            local d = (x - px) ^ 2 + (y - py) ^ 2
            if not bestD or d < bestD then best, bestD = { z, x, y, ns.DB.GetNPCName(id) }, d end
        end
    end
    if best then return best[1], best[2], best[3], best[4] end
end

-- Nearest friendly NPC with this English sub-name in the bundled data ("Warrior Trainer",
-- "Demon Trainer", "Pet Trainer"): same zone first, else your faction's capitals.
function TR:NearestNPC(sub)
    local z, x, y, name = self:NearestHere(sub)
    if z then return z, x, y, name end
    local info = ns.Compat.PlayerInfo()
    local cap
    for _, id in ipairs(npcsWithSub(sub)) do
        for rank, area in ipairs(self.CAPITALS[info.faction] or {}) do
            local cz, cx, cy = ns.DB.GetNPCPosition(id, area)
            if cz == area and (not cap or rank < cap.rank) then cap = { cz, cx, cy, ns.DB.GetNPCName(id), rank = rank } end
        end
    end
    if cap then return cap[1], cap[2], cap[3], cap[4] end
    return nil
end

-- Your class trainer in `zone` (area id): zone, x, y, name; nil when the bundled data has none there.
function TR:TrainerIn(zone)
    local info = ns.Compat.PlayerInfo()
    if not (zone and info.class) then return nil end
    local sub = info.class:sub(1, 1) .. info.class:sub(2):lower() .. " Trainer"
    local side = info.faction == "Alliance" and "A" or "H"
    local N = ns.QDB.NPC
    local best
    for id, r in pairs(ns.QDB.npcs) do
        local f = r[N.FRIENDLY]
        if r[N.SUBNAME] == sub and f and string.find(f, side, 1, true) then
            local z, x, y = ns.DB.GetNPCPosition(id, zone)
            if z and (ns.DB.ParentZone(z) or z) == zone and (not best or id < best[5]) then best = { z, x, y, r[N.NAME], id } end
        end
    end
    if best then return best[1], best[2], best[3], best[4] end
end

-- Completionist (Core/Completionist.lua): an optional train step for a segment in `zone`, or nil. Only when
-- suggestions are on and not deferred, something is ready to train, and your class trainer is in that zone: the
-- route never travels just to train. The step is skipped like any train step once nothing is left
-- (SkipReason) and is never a quest.
function TR:TrainStepFor(zone)
    if self:Mode() == "off" or self:Deferred() or not TR.CanCheck() then return nil end
    if #self:Available().ready == 0 then return nil end
    local z, x, y, name = self:TrainerIn(zone)
    if not z then return nil end
    return { "train", z = z, x = x, y = y, npc = name, optional = true,
             text = "Optional: your class trainer is here; " .. #self:Available().ready .. " rank(s) to learn." }
end

function TR:Waypoint()
    local step = ns.Engine and ns.Engine:CurrentStep()
    local z, x, y, name = self:TrainerFor(step and step[1] == "train" and step or nil)
    if z then
        ns.Nav:SetTarget(z, x, y, name)
        return true
    end
    return false
end

-- Chat report (/cg train): everything for the setting, plus where the route trains next.
function TR:Report(force)
    if self:Mode() == "off" and not force then return end
    local mode = self:Mode() == "off" and "all" or self:Mode()
    local a = self:Available(mode)
    local groups = TR.Group(a.ready)
    if #groups == 0 and #a.quest == 0 then
        ns:Print("Class trainer: nothing new for you at level " .. a.level .. (mode == "important" and " (important spells; set Class Trainer Suggestions to All for the rest)." or "."))
        return
    end
    local parts = {}
    for _, g in ipairs(groups) do parts[#parts + 1] = TR.GroupText(g) end
    if #parts > 0 then ns:Print("Class trainer has: " .. table.concat(parts, ", ") .. ".") end
    local bill = TR.BillText(self:Bill(a.ready), "Cost")
    if bill and #parts > 0 then ns:Print(bill) end
    for _, e in ipairs(a.quest) do ns:Print("From a class quest: " .. TR.SpellName(e) .. " - " .. e.quest .. ".") end
    if #a.other > 0 then
        local names = {}
        for _, g in ipairs(TR.Group(a.other)) do names[#names + 1] = TR.GroupText(g) end
        ns:Print("Not from the class trainer (a book, drop, vendor or quest): " .. table.concat(names, ", ") .. ".")
    end
    local nxt = self:NextTrainStep()
    if nxt then ns:Print("Your route trains next at step " .. nxt .. ".") end
end

function TR:NextTrainStep()
    local E = ns.Engine
    local g = E and E.guide
    if not g then return nil end
    for i = (E.current or 1), #g.steps do
        if g.steps[i][1] == "train" and E.status[i] ~= "na" then return i end
    end
    return nil
end

-- New level: one short line when important spells became available (never while deferred).
function TR:OnLevelUp(level)
    if self:Mode() == "off" or not TR.CanCheck() then return end
    if ns.char.trainerDeferLevel and level > ns.char.trainerDeferLevel then ns.char.trainerDeferLevel = nil end
    local a = self:Available("important", level)
    local fresh = {}
    for _, e in ipairs(a.ready) do if e.level == level then fresh[#fresh + 1] = e end end
    if #fresh == 0 then return end
    local parts = {}
    for _, g in ipairs(TR.Group(fresh)) do parts[#parts + 1] = TR.GroupText(g) end
    local nxt = self:NextTrainStep()
    ns:Print("New at your class trainer: " .. table.concat(parts, ", ") .. "."
        .. (nxt and (" Your route visits a trainer at step " .. nxt .. ".") or " /" .. ns.slash .. " train waypoint marks the nearest trainer."))
end

function TR:Init()
    ns:On("PLAYER_LEVEL_UP", function(_, level)
        -- Spellbook updates after the event: check a moment later.
        C_Timer.After(1, function() TR:OnLevelUp(tonumber(level) or UnitLevel("player")) if ns.Engine then ns.Engine:Refresh() end end)
    end)
    ns:On("TRAINER_SHOW", function() C_Timer.After(0.1, function() TR:ScanTrainer() end) end)
    ns:On("TRAINER_UPDATE", function() TR:ScanTrainer() end)
    ns:On("TRAINER_CLOSED", function() TR.trainerOpen, TR.live = false, {} ns:Fire("TRAINER_CHANGED") end)
    ns:On("LEARNED_SPELL_IN_TAB", function() TR.skipCache = nil ns:Throttle("trainer-refresh", 0.5, function() if ns.Engine then ns.Engine:Refresh() end end) end)
end
