-- Questwarden - Completionist mode: route a character through every eligible quest in the bundled database
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- This program is free software: you can redistribute it and/or modify it under the terms of the
-- GNU General Public License as published by the Free Software Foundation, version 3.
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
-- even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details. The complete license text is in LICENSE.
--
-- The speed guides (Guides/Compiled) are fixed routes. Completionist mode is a separate, per-character
-- strategy (ns.char.mode = "completionist"): it plans one SEGMENT at a time from the whole quest database
-- and runs it through the normal engine as a generated guide, so steps, arrows and auto-completion work
-- the same. When a segment is finished the next one is planned; a zone is visited again whenever new
-- quests there become right for the character's level or their prerequisites are done (docs/COMPLETIONIST.md).
--
-- Policy, in priority order (no weighted score):
--   1. eligibility and prerequisites: only quests this character can take now;
--   2. level: the lowest level BAND (BAND levels wide) that has actionable work goes first, so missed
--      low-level quests come before new ones; a quest is actionable when its required level is reached
--      and its quest level is at most AHEAD levels above the character;
--   3. geography: stay in the current zone while its own lowest band is at most one band above the lowest
--      band anywhere (no zone hopping over a level or two); otherwise go to a zone with work in the lowest
--      band: the most work, then the nearest by world distance (MIN_CLUSTER items preferred);
--   4. inside the zone: every actionable quest up to one band above the lowest (finish local work), quests
--      already in the log, then pickups, objectives and turn-ins, each in nearest-neighbour order.
-- A quest that starts from an item mobs drop (no NPC or object gives it) is placed at the nearest dropper
-- outside instances. Its pickup comes after the zone's other objectives, so the item may drop on the way, and
-- its own objectives follow it (Core/ItemStarts.lua). A pickup like that you skip is remembered for the
-- character ("itemskipped") and is not planned again until the item is in your bags.
-- Categories in EXCLUDE_DEFAULT stay in the inventory and the counts but are not routed automatically.
-- Completion comes only from the game's quest-completion flag; nothing here marks a quest complete.

local _, ns = ...

local CM = {
    BAND = 5, AHEAD = 2, MIN_CLUSTER = 2, MAX_ACCEPTS = 10, LOG_RESERVE = 3,
    GUIDE_ID = "Completionist",
}
ns.Completionist = CM

-- Categories that are counted but not routed unless the player turns them on (Settings).
CM.EXCLUDE_DEFAULT = { dungeon = true, raid = true, group = true, profession = true, reputation = true,
                       event = true, repeatable = true }
CM.CATEGORY_NAMES = {
    actionable = "Ready now", inlog = "In your quest log", completed = "Completed",
    deferred = "Later (level)", blocked = "Waiting on a prerequisite", dungeon = "Dungeon", raid = "Raid",
    group = "Group/elite", profession = "Profession", reputation = "Reputation", event = "Event/seasonal",
    repeatable = "Repeatable", exclusive = "Other branch chosen", ineligible = "Not for this character",
    missing = "Missing location data", unknown = "Completion unknown", itemskipped = "Item pickup skipped",
}

local function DB() return ns.DB end
local function QDB() return ns.QDB end

-- Per-character state (SavedVariables): mode, excluded categories, visit log, last speed guide.
function CM:State()
    local c = ns.char
    if type(c.completionist) ~= "table" then c.completionist = {} end
    local s = c.completionist
    if type(s.exclude) ~= "table" then
        s.exclude = {}
        for k, v in pairs(CM.EXCLUDE_DEFAULT) do s.exclude[k] = v end
    end
    if type(s.visits) ~= "table" then s.visits = {} end
    if type(s.itemSkipped) ~= "table" then s.itemSkipped = {} end
    return s
end

function CM:Mode() return ns.char and ns.char.mode == "completionist" and "completionist" or "speed" end
function CM:Active() return self:Mode() == "completionist" end

-- Can the client tell us which quests this character has turned in? Without it, completion is "unknown".
function CM:CompletionKnown()
    if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then return true end
    return (IsQuestFlaggedCompleted or GetQuestsCompleted) and true or false
end

local instanceZone, instanceName, dungeonQuests
-- Forget cached zone classifications (the zone table changed: tests, data reload).
function CM:ResetCache() instanceZone, instanceName, dungeonQuests = nil, nil, nil end

-- The dungeon list entry (Database/Dungeons.lua) called `name`, if any.
function CM:DungeonEntry(name)
    for _, d in ipairs(ns.Dungeons or {}) do if d.name == name then return d end end
end

-- Kind of an instance zone ("dungeon"/"raid") and, for listed dungeons, its name in the dungeon list. Zone
-- names in the data are "<Instance> - Dungeon - <Part>"; the part before " - " is the dungeon's name.
local function isInstance(zone)
    if not instanceZone then
        instanceZone, instanceName = {}, {}
        local dn = {}
        for _, d in ipairs(ns.Dungeons or {}) do dn[d.name] = true end
        for id, name in pairs(QDB().zones.names or {}) do
            if type(name) == "string" then
                local base = string.match(name, "^(.-) %- ") or name
                if dn[name] or string.find(name, " %- Dungeon", 1) then
                    instanceZone[id] = "dungeon"
                    if dn[base] then instanceName[id] = base end
                elseif string.find(name, " %- Raid", 1) then instanceZone[id] = "raid" end
            end
        end
    end
    return instanceZone[zone], instanceName[zone]
end

-- Zones where a quest's objectives are: { [zone] = true } and the dungeon/raid kind if any is inside one.
local function objectiveZones(r)
    local Q, N, O = QDB().QUEST, QDB().NPC, QDB().OBJECT
    local obj = r[Q.OBJECTIVES] or {}
    local zones, inside, dname = {}, nil, nil
    -- Instance spawns are dropped by the importer (QuestieDB marks them -1,-1), so the record's home zone
    -- also counts for telling dungeon and raid objectives apart.
    local function at(z)
        local kind, name = isInstance(z)
        inside = inside or kind
        dname = dname or name
    end
    local function npc(id)
        local n = QDB().npcs[id]
        for z in pairs(n and n[N.SPAWNS] or {}) do zones[z] = true; at(z) end
        if n and n[N.ZONE] then at(n[N.ZONE]) end
    end
    local function object(id)
        local o = QDB().objects[id]
        for z in pairs(o and o[O.SPAWNS] or {}) do zones[z] = true; at(z) end
        if o and o[O.ZONE] then at(o[O.ZONE]) end
    end
    for _, id in ipairs(obj.c or {}) do npc(id) end
    for _, id in ipairs(obj.k or {}) do npc(id) end
    for _, id in ipairs(obj.o or {}) do object(id) end
    for _, it in ipairs(obj.i or {}) do
        local item = QDB().items[it]
        for _, id in ipairs(item and item[QDB().ITEM.NPC_DROPS] or {}) do npc(id) end
        for _, id in ipairs(item and item[QDB().ITEM.OBJECT_DROPS] or {}) do object(id) end
    end
    return zones, inside, dname
end

local function hostileElite(id)
    local N = QDB().NPC
    local n = QDB().npcs[id]
    return n and (n[N.RANK] == 1 or n[N.RANK] == 2 or n[N.RANK] == 3) and DB().HostileToPlayer(n[N.FRIENDLY])
end

-- A quest no NPC or object gives that starts from an item: the item and the NPCs that drop it with a spawn
-- outside instances (an empty list when none does). Nil for any other quest.
function CM:Starter(r)
    local Q, N = QDB().QUEST, QDB().NPC
    if #(r[Q.START_NPCS] or {}) > 0 or #(r[Q.START_OBJECTS] or {}) > 0 then return nil end
    local item = (r[Q.START_ITEMS] or {})[1]
    if not item then return nil end
    local it = QDB().items[item]
    local drops = {}
    for _, id in ipairs(it and it[QDB().ITEM.NPC_DROPS] or {}) do
        local n = QDB().npcs[id]
        for z in pairs(n and n[N.SPAWNS] or {}) do
            if not isInstance(z) then drops[#drops + 1] = id break end
        end
    end
    return item, drops
end

-- Where a quest starts / ends: zone, x, y (nil when the data has no position). For a quest started by a
-- dropped item: the nearest NPC that drops it, and the item as a fifth value.
function CM:GiverPos(r, nearZone, nx, ny)
    local Q = QDB().QUEST
    for _, id in ipairs(r[Q.START_NPCS] or {}) do
        local z, x, y = DB().GetNPCPosition(id, nearZone, nx, ny)
        if z then return z, x, y, DB().GetNPCName(id) end
    end
    for _, id in ipairs(r[Q.START_OBJECTS] or {}) do
        local z, x, y = DB().GetObjectPosition(id, nearZone, nx, ny)
        if z then return z, x, y, DB().GetObjectName(id) end
    end
    local item, drops = self:Starter(r)
    for _, id in ipairs(drops or {}) do
        local z, x, y = DB().GetNPCPosition(id, nearZone, nx, ny)
        if z and not isInstance(z) then return z, x, y, DB().GetNPCName(id), item end
    end
end

function CM:FinisherPos(r, nearZone, nx, ny)
    local Q = QDB().QUEST
    for _, id in ipairs(r[Q.END_NPCS] or {}) do
        local z, x, y = DB().GetNPCPosition(id, nearZone, nx, ny)
        if z then return z, x, y, DB().GetNPCName(id) end
    end
    for _, id in ipairs(r[Q.END_OBJECTS] or {}) do
        local z, x, y = DB().GetObjectPosition(id, nearZone, nx, ny)
        if z then return z, x, y, DB().GetObjectName(id) end
    end
end

-- The special kind of a quest, or nil for an ordinary one: event, profession, reputation, repeatable,
-- dungeon, raid or group (elite targets). Such quests are counted under their kind and routed only when the
-- player has turned that kind on. Dungeon quests also return the dungeon's name (third value) when the
-- instance is in the dungeon list.
function CM:Special(r)
    local Q = QDB().QUEST
    local classes = r[Q.CLASSES] or 0
    if (r[Q.ZONE] or 0) < 0 and classes == 0 then return "event", "special category " .. tostring(r[Q.ZONE]) end
    if (r[Q.LEVEL] or 0) < 0 then return "event", "scaling or event quest" end
    if r[Q.REQ_SKILL] then return "profession" end
    if r[Q.REQ_MIN_REP] then return "reputation" end
    if ns.HasBit(r[Q.SPECIAL_FLAGS] or 0, QDB().SPECIAL_FLAG_REPEATABLE or 1) then return "repeatable" end
    local _, inside, dname = objectiveZones(r)
    if inside then return inside, nil, dname end
    local obj = r[Q.OBJECTIVES] or {}
    for _, n in ipairs(obj.c or {}) do if hostileElite(n) then return "group", "elite target" end end
    for _, n in ipairs(obj.k or {}) do if hostileElite(n) then return "group", "elite target" end end
end

-- The category of one quest for this character (see CATEGORY_NAMES) and a short reason.
-- `ctx` = { race, class, level, completed = fn(id) -> true/false/nil, inLog = fn(id) }; `exclude` = the
-- special kinds not routed (default: the character's settings).
function CM:Classify(id, ctx, exclude)
    local Q = QDB().QUEST
    local r = QDB().quests[id]
    if not r or type(r[Q.NAME]) ~= "string" then return "missing", "no quest record" end
    local races, classes = r[Q.RACES] or 0, r[Q.CLASSES] or 0
    local rb = QDB().RACE_BITS[ctx.race or ""]
    if races ~= 0 and rb and not ns.HasBit(races, rb) then return "ineligible", "race" end
    local cb = QDB().CLASS_BITS[ctx.class or ""]
    if classes ~= 0 and cb and not ns.HasBit(classes, cb) then return "ineligible", "class" end
    local done = ctx.completed(id)
    if done == true then return "completed" end
    if ctx.inLog(id) then return "inlog" end
    for _, ex in ipairs(r[Q.EXCLUSIVE] or {}) do
        if ctx.completed(ex) == true or ctx.inLog(ex) then return "exclusive", ex end
    end
    local level, req = r[Q.LEVEL] or 0, r[Q.REQ_LEVEL] or 0
    if r[Q.MAX_LEVEL] and r[Q.MAX_LEVEL] > 0 and (ctx.level or 1) > r[Q.MAX_LEVEL] then return "ineligible", "too high level" end
    local kind, why, dname = self:Special(r)
    if kind and not self:Routes(kind, dname, exclude) then return kind, why or dname end
    if done == nil then return "unknown" end
    if not self:GiverPos(r) or not self:FinisherPos(r) then return "missing", "no giver or finisher position" end
    for _, pre in ipairs(r[Q.PRE_GROUP] or {}) do
        if ctx.completed(pre) ~= true then return "blocked", pre end
    end
    local single = r[Q.PRE_SINGLE]
    if single and #single > 0 then
        local any = false
        for _, pre in ipairs(single) do if ctx.completed(pre) == true then any = true break end end
        if not any then return "blocked", single[1] end
    end
    if req > (ctx.level or 1) then return "deferred", req end
    if level > (ctx.level or 1) + self.AHEAD then return "deferred", level - self.AHEAD end
    -- A selected dungeon's quests are picked up from the level the dungeon is usually run at, not earlier,
    -- so they do not sit in the quest log for many levels.
    local d = kind == "dungeon" and dname and self:DungeonEntry(dname)
    if d and d.min > (ctx.level or 1) then return "deferred", d.min end
    -- An item pickup you skipped stays out of the route until the item is in your bags.
    if self:State().itemSkipped[id] then
        local item = self:Starter(r)
        if item and not (ns.ItemStarts and ns.ItemStarts:Has(item)) then return "itemskipped", item end
    end
    return "actionable"
end

-- Whether a special kind is routed for this character. Dungeon quests: always (Completionist goes through every
-- dungeon; the dungeon selection in setup is for Speed only), picked up from the dungeon's usual level and run
-- through skippable run steps. Group/elite quests: the setup's group-quest choice (ns.char.routing). Characters
-- that never confirmed setup, and every other kind, use the Completionist category switches (`exclude`).
function CM:Routes(kind, dname, exclude)
    if kind == "dungeon" then return true end
    local r = ns.Setup and ns.Setup:Routing()
    if r and kind == "group" then return r.elite == true end
    exclude = exclude or self:State().exclude
    return not exclude[kind]
end

-- Whether Completionist mode can run here, and why not: it needs a verified game version, the game's quest
-- completion flags and the zone geography table.
function CM:Available()
    if not ns.Target.verified then return false, ns.Target.name .. " is not verified yet, so no route can be planned." end
    if not self:CompletionKnown() then return false, "this game client does not report which quests you completed." end
    if not ns.ZoneGeo or not next(ns.ZoneGeo) then return false, "the zone geography data is missing from this build." end
    return true
end

-- Quests per listed dungeon that this race and class can take: { [name] = n } (cached; data does not change).
function CM:DungeonQuestCounts(race, class)
    local key = tostring(race) .. "/" .. tostring(class)
    dungeonQuests = dungeonQuests or {}
    if dungeonQuests[key] then return dungeonQuests[key] end
    local Q, out = QDB().QUEST, {}
    local rb, cb = QDB().RACE_BITS[race or ""], QDB().CLASS_BITS[class or ""]
    for _, r in pairs(QDB().quests) do
        local races, classes = r[Q.RACES] or 0, r[Q.CLASSES] or 0
        if (races == 0 or not rb or ns.HasBit(races, rb)) and (classes == 0 or not cb or ns.HasBit(classes, cb)) then
            local kind, _, dname = self:Special(r)
            if kind == "dungeon" and dname then out[dname] = (out[dname] or 0) + 1 end
        end
    end
    dungeonQuests[key] = out
    return out
end

-- The character context from the live game.
function CM:Context()
    local info = ns.Compat.PlayerInfo()
    local known = self:CompletionKnown()
    info.completed = function(id)
        if ns.Tracker.turnedIn[id] then return true end
        if not known then return nil end
        return ns.Compat.IsQuestCompleted(id)
    end
    info.inLog = function(id) return ns.Tracker:InLog(id) end
    info.inside = ns.DungeonRun and ns.DungeonRun:Current() -- the listed dungeon you are in, if any
    info.live = true -- planning for the character in the game (adds optional training, Classes/Trainer.lua)
    return info
end

-- Every quest, by category: { counts = {cat = n}, byCat = {cat = {ids}}, cat = {[id] = cat}, why = {[id] = reason} }.
function CM:Inventory(ctx)
    ctx = ctx or self:Context()
    local exclude = self:State().exclude
    local inv = { counts = {}, byCat = {}, cat = {}, why = {} }
    for id in pairs(QDB().quests) do
        local c, why = self:Classify(id, ctx, exclude)
        inv.cat[id], inv.why[id] = c, why
        inv.counts[c] = (inv.counts[c] or 0) + 1
        inv.byCat[c] = inv.byCat[c] or {}
        table.insert(inv.byCat[c], id)
    end
    for _, l in pairs(inv.byCat) do table.sort(l) end
    return inv
end

-- World position of a zone-percent point (nil without zone geography).
function CM:World(z, x, y)
    local g = ns.ZoneGeo and ns.ZoneGeo[z] or ns.ZoneGeo and ns.ZoneGeo[DB().ParentZone(z)]
    if not g then return nil end
    return g[1], g[4] - (y or 50) / 100 * (g[4] - g[2]), g[5] - (x or 50) / 100 * (g[5] - g[3])
end

-- Distance between two zone points in yards; math.huge across continents or without geography.
function CM:Distance(z1, x1, y1, z2, x2, y2)
    local c1, a1, b1 = self:World(z1, x1, y1)
    local c2, a2, b2 = self:World(z2, x2, y2)
    if not c1 or not c2 or c1 ~= c2 then return math.huge end
    return math.sqrt((a1 - a2) ^ 2 + (b1 - b2) ^ 2)
end

local function band(level) return math.max(1, math.ceil(math.max(level, 1) / CM.BAND)) end

-- Where the character is: zone, x, y (percent); nil when unknown.
function CM:Here()
    local mapId, px, py = ns.Compat.GetPlayerMapPosition()
    local z = mapId and DB().AreaForUiMap(mapId)
    if not z then return nil end
    return DB().ParentZone(z) or z, px and px * 100, py and py * 100
end

-- Work items per zone for the chosen band: pickups (actionable quests given here), objectives and
-- turn-ins of quests already in the log.
function CM:Work(inv, ctx, here)
    local Q = QDB().QUEST
    local hz, hx, hy = here and here[1], here and here[2], here and here[3]
    local exclude = self:State().exclude
    local minBand
    for _, id in ipairs(inv.byCat.actionable or {}) do
        local b = band(QDB().quests[id][Q.LEVEL] or 0)
        if not minBand or b < minBand then minBand = b end
    end
    local zones = {}
    local function add(z, kind, id, x, y, name, b)
        z = DB().ParentZone(z) or z
        zones[z] = zones[z] or { zone = z, pickups = {}, objectives = {}, turnins = {}, n = 0 }
        local e = { q = id, x = x, y = y, name = name }
        table.insert(zones[z][kind], e)
        zones[z].n = zones[z].n + 1
        if b and (not zones[z].best or b < zones[z].best) then zones[z].best = b end
        return e
    end
    for _, id in ipairs(inv.byCat.actionable or {}) do
        local r = QDB().quests[id]
        local b = band(r[Q.LEVEL] or 0)
        if b <= minBand + 1 then
            local z, x, y, name, item = self:GiverPos(r, hz, hx, hy)
            if z then add(z, "pickups", id, x, y, name, b).starter = item end
        end
    end
    -- Dungeon quests in the log that are not complete yet are not zone work: they become one "run" step per
    -- dungeon (runs[name] = {ids}), and their turn-ins are planned only once the quest log says complete.
    local runs = {}
    for _, id in ipairs(inv.byCat.inlog or {}) do
        local r = QDB().quests[id]
        local kind, dname
        if r then kind, _, dname = self:Special(r) end
        local routed = not kind or self:Routes(kind, dname, exclude)
        local complete = r and ns.Tracker:IsComplete(id)
        if r and (routed or (complete and kind == "dungeon")) then
            if complete then
                local z, x, y, name = self:FinisherPos(r, hz, hx, hy)
                if z then add(z, "turnins", id, x, y, name, minBand) end
            elseif kind == "dungeon" then
                if dname then runs[dname] = runs[dname] or {}; table.insert(runs[dname], id) end
            else
                local z, x, y, name = DB().GetObjectiveLocation(id, hz, hx, hy)
                if z then add(z, "objectives", id, x, y, name, minBand) end
                local fz, fx, fy, fname = self:FinisherPos(r, hz, hx, hy)
                if fz then add(fz, "turnins", id, fx, fy, fname, minBand) end
            end
        end
    end
    return zones, minBand or 1, runs
end

-- One "dungeon" step per dungeon with open quests in the log, once the character is at the dungeon's usual
-- level: it says it is time to find a group, points the arrow at the entrance and ends when you enter
-- (Core/DungeonRun.lua). Skipping it never completes a quest: the turn-ins are planned from the quest log
-- when the quests are complete, and the step comes back in later segments until then.
function CM:RunSteps(runs, level, inside)
    local names, out = {}, {}
    for name in pairs(runs or {}) do names[#names + 1] = name end
    table.sort(names)
    for _, name in ipairs(names) do
        local d = self:DungeonEntry(name)
        if name ~= inside and (not d or d.min <= (level or 1)) then
            local titles = {}
            for _, id in ipairs(runs[name]) do titles[#titles + 1] = QDB().quests[id][1] end
            table.sort(titles)
            out[#out + 1] = { "dungeon", dungeon = name, dungeonRun = name, text = string.format(
                "Quests: %s. Not now? Skip this step to keep questing; the quests stay in your log, and their turn-ins appear once they are complete.",
                table.concat(titles, ", ")) }
        end
    end
    return out
end

-- Picks the zone for the next segment (policy steps 2-3 above): the current zone while its lowest band is
-- within one band of the lowest anywhere; otherwise, among zones with work in the lowest band, those with at
-- least MIN_CLUSTER items (or all when none has that many): most work, then nearest, then lowest zone id
-- (so the choice never depends on table order).
function CM:PickZone(zones, here, minBand)
    local hz = here and here[1]
    local cur = hz and zones[hz]
    if cur and cur.n > 0 and (cur.best or minBand) <= minBand + 1 then return cur end
    local list, big = {}, false
    for _, w in pairs(zones) do
        if w.n > 0 and (w.best or minBand) == minBand then
            w.dist = here and self:Distance(hz, here[2], here[3], w.zone, 50, 50) or math.huge
            list[#list + 1] = w
            if w.n >= self.MIN_CLUSTER then big = true end
        end
    end
    local best
    for _, w in ipairs(list) do
        if not big or w.n >= self.MIN_CLUSTER then
            if not best or w.n > best.n or (w.n == best.n and (w.dist < best.dist or (w.dist == best.dist and w.zone < best.zone))) then
                best = w
            end
        end
    end
    return best
end

-- Nearest-neighbour order from a start point.
local function nearestOrder(items, sx, sy)
    local out, left = {}, {}
    for i, it in ipairs(items) do left[i] = it end
    local cx, cy = sx or 50, sy or 50
    while #left > 0 do
        local bi, bd = 1, math.huge
        for i, it in ipairs(left) do
            local d = ((it.x or 50) - cx) ^ 2 + ((it.y or 50) - cy) ^ 2
            if d < bd or (d == bd and it.q < left[bi].q) then bi, bd = i, d end
        end
        local it = table.remove(left, bi)
        out[#out + 1] = it
        cx, cy = it.x or cx, it.y or cy
    end
    return out
end

-- Plans the next segment: { zone, band, steps, accepted = {ids}, deferred = n, reason } or a level/grind
-- segment when only later content remains, or nil when nothing eligible and known is left.
function CM:Plan(ctx, here)
    ctx = ctx or self:Context()
    local inv = self:Inventory(ctx)
    local zones, minBand, runs = self:Work(inv, ctx, here)
    local seg = { inv = inv, steps = {} }
    -- Inside a dungeon with open quests for it: a dungeon segment, its objectives in the order of the quest ids.
    -- Leaving the dungeon plans again (Init: DUNGEON_CHANGED).
    if ctx.inside and runs[ctx.inside] then
        seg.kind, seg.dungeon = "dungeon", ctx.inside
        seg.steps[1] = { "note", text = string.format("You are in %s. Do its quests below; leaving with some unfinished is fine, they stay in your log.", ctx.inside) }
        local ids = runs[ctx.inside]
        table.sort(ids)
        for _, id in ipairs(ids) do
            seg.steps[#seg.steps + 1] = { "complete", q = id, title = QDB().quests[id][1], dungeon = ctx.inside }
        end
        return seg
    end
    local w = self:PickZone(zones, here, minBand)
    local runSteps = self:RunSteps(runs, ctx.level, ctx.inside)
    if not w then
        for _, s in ipairs(runSteps) do seg.steps[#seg.steps + 1] = s end
        -- Nothing to do now: the next level that unlocks deferred quests.
        local nextLevel
        for _, id in ipairs(inv.byCat.deferred or {}) do
            local l = inv.why[id]
            if type(l) == "number" and (not nextLevel or l < nextLevel) then nextLevel = l end
        end
        if nextLevel and nextLevel > (ctx.level or 1) then
            seg.kind = "level"
            seg.steps[#seg.steps + 1] = { "level", level = nextLevel, text = string.format(
                "No quest you can do right now. Reach level %d: %d deferred quests then start opening up.", nextLevel, inv.counts.deferred or 0) }
            return seg
        end
        seg.kind = #runSteps > 0 and "runs" or "done"
        return seg
    end
    seg.kind, seg.zone, seg.band = "quests", w.zone, minBand
    local _, logMax = ns.Compat.QuestLogSize()
    local cap = (logMax or ns.Target.questLogMax or 20) - self.LOG_RESERVE
    local inLog = ns.Tracker:Count()
    local sx, sy = here and here[1] == w.zone and here[2] or nil, here and here[1] == w.zone and here[3] or nil
    local zoneName = DB().ZoneName(w.zone) or ("zone " .. w.zone)
    local visits = 0
    for _, v in ipairs(self:State().visits) do if v.zone == w.zone then visits = visits + 1 end end
    seg.visit = visits + 1
    local lo, hi = (minBand or 1) * self.BAND - self.BAND + 1, (minBand or 1) * self.BAND
    if not here or here[1] ~= w.zone then
        seg.steps[#seg.steps + 1] = { "travel", dest = zoneName, text = "Travel to " .. zoneName }
    end
    seg.steps[#seg.steps + 1] = { "note", text = string.format("%s, visit %d (quests of levels %d-%d): %d pickups, %d objectives, %d turn-ins here.",
        zoneName, seg.visit, lo, hi, #w.pickups, #w.objectives, #w.turnins) }
    seg.accepted = {}
    -- Mutually exclusive quests: never both. With neither chosen yet the route takes the lower id (pickups are
    -- tried in id order for this check); a branch the player already took decides (Classify: "exclusive").
    -- The data may list the link on one side only, so it counts both ways.
    local closed, conflict, byId = {}, {}, {}
    for _, it in ipairs(w.pickups) do byId[#byId + 1] = it.q end
    table.sort(byId)
    for _, q in ipairs(byId) do
        for _, ex in ipairs(QDB().quests[q][QDB().QUEST.EXCLUSIVE] or {}) do
            conflict[q] = conflict[q] or {}; conflict[q][ex] = true
            conflict[ex] = conflict[ex] or {}; conflict[ex][q] = true
        end
    end
    local kept = {}
    for _, q in ipairs(byId) do
        local clash = false
        for other in pairs(conflict[q] or {}) do if kept[other] then clash = true end end
        if clash then closed[q] = true else kept[q] = true end
    end
    local itemPickups = {} -- quests started by a dropped item: after the other objectives (see the top of the file)
    for _, it in ipairs(nearestOrder(w.pickups, sx, sy)) do
        if inLog + #seg.accepted >= cap or #seg.accepted >= self.MAX_ACCEPTS then break end
        local r = QDB().quests[it.q]
        if closed[it.q] then
            seg.skippedExclusive = (seg.skippedExclusive or 0) + 1
        elseif it.starter then
            seg.accepted[#seg.accepted + 1] = it.q
            itemPickups[#itemPickups + 1] = it
        else
        seg.accepted[#seg.accepted + 1] = it.q
        seg.steps[#seg.steps + 1] = { "accept", q = it.q, title = r[1], z = w.zone, x = it.x, y = it.y, npc = it.name }
        end
    end
    -- Optional class training while the route is in a zone with your class trainer (Classes/Trainer.lua): never a
    -- detour, never counted as a quest. Live play only (the planner is also run on test and coverage data).
    if ctx.live and ns.Trainer then
        local t = ns.Trainer:TrainStepFor(w.zone)
        if t then seg.steps[#seg.steps + 1] = t end
    end
    -- objectives: quests in the log plus those just picked up, located in this zone
    local late = {}
    for _, it in ipairs(itemPickups) do late[it.q] = true end
    local function objectiveSteps(list, only)
        local objectives = {}
        for _, it in ipairs(list) do objectives[#objectives + 1] = it end
        for _, q in ipairs(seg.accepted) do
            local r = QDB().quests[q]
            local obj = r[QDB().QUEST.OBJECTIVES]
            if obj and next(obj) and (late[q] or false) == only then
                local z, x, y, name = DB().GetObjectiveLocation(q, w.zone, sx, sy)
                if z and (DB().ParentZone(z) or z) == w.zone then objectives[#objectives + 1] = { q = q, x = x, y = y, name = name } end
            end
        end
        for _, it in ipairs(nearestOrder(objectives, sx, sy)) do
            local r = QDB().quests[it.q]
            seg.steps[#seg.steps + 1] = { "complete", q = it.q, title = r[1], z = w.zone, x = it.x, y = it.y, text = it.name and ("Objectives near " .. it.name) or nil }
        end
    end
    objectiveSteps(w.objectives, false)
    -- Item pickups: get the item from its droppers here (the step targets the nearest one), then their objectives.
    for _, it in ipairs(nearestOrder(itemPickups, sx, sy)) do
        local r = QDB().quests[it.q]
        local _, all = self:Starter(r)
        local drops = {}
        for _, id in ipairs(all) do
            local n = QDB().npcs[id]
            for z in pairs(n and n[QDB().NPC.SPAWNS] or {}) do
                if (DB().ParentZone(z) or z) == w.zone then drops[#drops + 1] = id break end
            end
        end
        if #drops == 0 then drops = all end
        seg.steps[#seg.steps + 1] = { "accept", q = it.q, title = r[1], starter = it.starter, drops = drops,
            text = "Starts from the item " .. (DB().GetItemName(it.starter) or ("item " .. it.starter)) .. "." }
    end
    objectiveSteps({}, true)
    local turnins, seen = {}, {}
    for _, it in ipairs(w.turnins) do turnins[#turnins + 1] = it; seen[it.q] = true end
    for _, q in ipairs(seg.accepted) do
        local r = QDB().quests[q]
        local z, x, y, name = self:FinisherPos(r, w.zone, sx, sy)
        if z and (DB().ParentZone(z) or z) == w.zone and not seen[q] then turnins[#turnins + 1] = { q = q, x = x, y = y, name = name } end
    end
    for _, it in ipairs(nearestOrder(turnins, sx, sy)) do
        local r = QDB().quests[it.q]
        seg.steps[#seg.steps + 1] = { "turnin", q = it.q, title = r[1], z = w.zone, x = it.x, y = it.y, npc = it.name }
    end
    for _, s in ipairs(runSteps) do seg.steps[#seg.steps + 1] = s end
    seg.deferred = inv.counts.deferred or 0
    return seg
end

-- Builds the generated guide for a segment and loads it. Route progress for the old segment is dropped;
-- quest history is the game's and is never touched.
function CM:Load(seg)
    local info = ns.Compat.PlayerInfo()
    local level = UnitLevel and UnitLevel("player") or 1
    local g = { id = self.GUIDE_ID, name = "Completionist", faction = info.faction or "Both", minLevel = level, maxLevel = level,
                dynamic = true, steps = seg.steps }
    if #g.steps == 0 then
        g.steps = { { "note", text = "Completionist: every eligible quest the data knows is done or excluded. See /" .. ns.slash .. " completionist." } }
    end
    if not ns.Guides:RegisterDynamic(g) then return false end
    if seg.kind == "quests" then
        local v = self:State().visits
        local last = v[#v]
        if not last or last.zone ~= seg.zone or last.band ~= seg.band then
            v[#v + 1] = { zone = seg.zone, band = seg.band, level = level, quests = seg.accepted, deferred = seg.deferred, at = time and time() or 0 }
            while #v > 200 do table.remove(v, 1) end
        end
    end
    self:RecordItemSkips()
    ns:ResetProgress(self.GUIDE_ID)
    self.segment = seg
    return ns.Engine:Load(self.GUIDE_ID)
end

-- Item pickups you skipped in the segment that ends (Skip on the step, not an automatic skip), unless you took
-- the quest after all: kept out of later segments until the item is in your bags (Classify: "itemskipped").
function CM:RecordItemSkips()
    local seg = self.segment
    local p = seg and ns.char.progress and ns.char.progress[self.GUIDE_ID]
    if not (p and type(p.skipped) == "table") then return end
    for i, s in ipairs(seg.steps or {}) do
        if s.starter and s.q and p.skipped[i] and not ns.Tracker:InLog(s.q) and not ns.Tracker:IsTurnedIn(s.q) then
            self:State().itemSkipped[s.q] = true
        end
    end
end

-- Plans and loads the next segment (also on demand: /qw completionist replan).
function CM:Replan(reason)
    if not self:Active() then return false end
    local h = { self:Here() }
    local seg = self:Plan(nil, h[1] and h or nil)
    local ok = self:Load(seg)
    if ok and reason and seg.zone then
        ns:Print(string.format("Completionist: %s. Next: %s.", reason, DB().ZoneName(seg.zone) or seg.zone))
    end
    return ok
end

-- Mode switch. The speed guide in use is remembered and comes back with its own progress; quest
-- completion is the game's and is never changed.
function CM:SetMode(mode)
    local c = ns.char
    if mode == "completionist" then
        if c.mode ~= "completionist" and c.activeGuide and c.activeGuide ~= self.GUIDE_ID then c.speedGuide = c.activeGuide end
        c.mode = "completionist"
        self:State()
        return self:Replan()
    end
    c.mode = "speed"
    local back = c.speedGuide and ns.Guides:Get(c.speedGuide) or ns.Selector:Recommend()
    if back then return ns.Engine:Load(back.id) end
    return true
end

-- Entering or leaving a dungeon plans again: a dungeon segment inside, the normal route outside.
function CM:Init()
    ns:Listen("DUNGEON_CHANGED", function(_, now, was)
        if not CM:Active() then return end
        if now or (CM.segment and CM.segment.kind == "dungeon") then
            CM:Replan(now and ("entered " .. now) or ("left " .. tostring(was)))
        end
    end)
end

-- The finished generated guide plans the next segment (Engine:OnGuideFinished calls this).
function CM:OnSegmentFinished()
    if not self:Active() then return false end
    C_Timer.After(0.5, function() CM:Replan("segment done") end)
    return true
end

-- Progress with explicit denominators. "Eligible known" = quests this character can ever take that the
-- data describes well enough to route (completed + ready + in log + later + waiting on prerequisites).
function CM:Summary(inv)
    inv = inv or self:Inventory()
    local c = inv.counts
    local function n(k) return c[k] or 0 end
    -- A special kind is only a category when it is not routed (Classify), so its count is the excluded part;
    -- dungeon quests can be partly routed (selected dungeons only).
    local excluded = 0
    for k in pairs(CM.EXCLUDE_DEFAULT) do excluded = excluded + n(k) end
    local routable = n("completed") + n("actionable") + n("inlog") + n("deferred") + n("blocked")
    return {
        completed = n("completed"), remaining = n("actionable") + n("inlog") + n("deferred") + n("blocked"),
        routable = routable, deferred = n("deferred"), blocked = n("blocked"), excluded = excluded,
        exclusive = n("exclusive"), unknown = n("unknown"), missing = n("missing"), ineligible = n("ineligible"),
        itemskipped = n("itemskipped"),
    }
end

function CM:StatusLines()
    local inv = self:Inventory()
    local s = self:Summary(inv)
    local out = {
        string.format("Mode: %s.", self:Active() and "Completionist" or "Speed"),
        string.format("Eligible quests with routable data: %d done of %d (%d left: %d ready or in your log, %d later by level, %d waiting on a prerequisite).",
            s.completed, s.routable, s.remaining, s.remaining - s.deferred - s.blocked, s.deferred, s.blocked),
        string.format("Not routed automatically (turn on in setup or Settings): %d (raid %d, group/elite %d, profession %d, reputation %d, event %d, repeatable %d). Dungeon quests are routed for every dungeon.",
            s.excluded, inv.counts.raid or 0, inv.counts.group or 0, inv.counts.profession or 0,
            inv.counts.reputation or 0, inv.counts.event or 0, inv.counts.repeatable or 0),
        string.format("Other branch chosen: %d. Missing location data: %d. Completion unknown: %d. Item pickups you skipped: %d (back once the item is in your bags).",
            s.exclusive, s.missing, s.unknown, s.itemskipped),
        "Coverage: every quest in the bundled QuestieDB data for this game; quests the data lacks or places nowhere are not routed.",
    }
    local seg = self.segment
    if seg and seg.zone then
        out[#out + 1] = string.format("Current segment: %s, visit %d, quests of levels %d-%d.", DB().ZoneName(seg.zone) or seg.zone,
            seg.visit or 1, (seg.band or 1) * self.BAND - self.BAND + 1, (seg.band or 1) * self.BAND)
    end
    return out
end

-- Settings toggle for one category (routing only; the inventory always counts it).
function CM:SetIncluded(category, on)
    self:State().exclude[category] = not on
end
