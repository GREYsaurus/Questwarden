-- Questwarden - headless tests for quests started by a dropped item (Core/ItemStarts.lua; loaded by run_tests.lua)
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- SPDX-License-Identifier: GPL-3.0-only
--
-- The compiled-guide checks use the real TBC Elwynn guide. The engine checks use a small generated guide built
-- from real quest, item and NPC ids (The Collector, started by the Gold Pickup Schedule that Defias drop) so the
-- states can be set one at a time. The Completionist block uses a synthetic fixture like test_completionist.lua.

local check, ns = TEST.check, TEST.ns
local E, IS, T = ns.Engine, ns.ItemStarts, ns.Tracker
local real = { log = MOCK.questLog, level = MOCK.player.level, refresh = E.Refresh, slot = MOCK.bags[0][9] }

local function setLog(ids)
    MOCK.questLog = {}
    for _, q in ipairs(ids) do MOCK.questLog[#MOCK.questLog + 1] = { id = q, title = "Q" .. q, objectives = { { text = "x: 0/1", done = false } } } end
    T:Scan()
end
local function bags(id)
    MOCK.bags[0][9] = id and { itemID = id, count = 1 } or nil
    MOCK.fire("BAG_UPDATE_DELAYED")
end

-- Compiled guide data ---------------------------------------------------------------------------------
local g = ns.Guides:Get("A_Human_Elwynn")
local acc
for _, s in ipairs(g.steps) do if s[1] == "accept" and s.q == 123 then acc = s end end
check(acc and acc.starter == 1307 and acc.npc == nil, "The Collector's pickup names its start item (Gold Pickup Schedule), no NPC")
check(acc and type(acc.drops) == "table" and #acc.drops > 0, "and the NPCs that drop it, from the data")
local allDrop = true
for _, id in ipairs(acc and acc.drops or {}) do
    local found = false
    for _, d in ipairs(ns.DB.GetItemByID(1307).npcDrops) do if d == id then found = true end end
    allDrop = allDrop and found
end
check(allDrop, "every listed dropper is one the item data names (nothing made up)")
check(acc and acc.x == nil, "no fixed waypoint: the step targets the nearest dropper live")
local viaOk, killQ = acc and acc.via and #acc.via > 0, nil
for _, j in ipairs(acc and acc.via or {}) do
    local s = g.steps[j]
    viaOk = viaOk and j > acc.index and (s[1] == "complete" or s[1] == "grind")
    if s[1] == "complete" then
        local hits = false
        for id in pairs(ns.DB.ObjectiveNpcIds(s.q) or {}) do
            for _, d in ipairs(acc.drops) do if d == id then hits = true end end
        end
        viaOk = viaOk and hits
        killQ = killQ or s.q
    end
end
check(viaOk and killQ, "its kill steps (via) come later in the guide and kill one of the droppers")

-- A generated guide: the item pickup, a kill quest whose mobs drop the item, then the item quest's own steps
MOCK.player.level = 15
local KQ, IQ, ITEM = killQ, 123, 1307
local steps = {
    { "accept", q = IQ, title = "The Collector", starter = ITEM, drops = acc.drops, via = { 3 } }, -- 1
    { "accept", q = KQ },                                                                       -- 2
    { "complete", q = KQ },                                                                     -- 3
    { "complete", q = IQ },                                                                     -- 4
    { "turnin", q = IQ },                                                                       -- 5
    { "turnin", q = KQ },                                                                       -- 6
}
ns.Guides:RegisterDynamic({ id = "TEST_ItemStarts", name = "Item starts", faction = "Both", minLevel = 1, maxLevel = 60, dynamic = true, steps = steps })
setLog({})
bags(nil)
E:Load("TEST_ItemStarts", { reset = true })
local S = E.guide.steps

-- D: no item, a kill step ahead -> the kill steps go first
check(E.status[1] == "pending" and E.waiting[1] and E.current == 2, "item not in bags, kill step ahead: the pickup waits, the route goes on")
check(IS:State(S[1]) == "waiting", "state: waiting for a kill step")
check(E.waiting[4] and E.waiting[5] and not E.waiting[6], "the item quest's objective and turn-in wait with it; other steps do not")
local up = E:Upcoming(10)
local shown = false
for _, i in ipairs(up) do if i == 4 or i == 5 then shown = true end end
check(not shown, "steps for a quest you do not have yet are not listed as upcoming")
setLog({ KQ })
E:Refresh()
check(E.current == 3, "the kill step is current")
local kill = table.concat(ns.StepText:Details(S[3]), "\n")
check(string.find(kill, "can drop Gold Pickup Schedule, which starts The Collector", 1, true), "the kill step says its mobs can drop the item")
check(not string.find(kill, "%d+%%"), "no drop rate is claimed")

-- C: the item drops -> back to the pickup, which says to use it; the item is not the quest
local refreshes = 0
E.Refresh = function(self, ...) refreshes = refreshes + 1 return real.refresh(self, ...) end
bags(ITEM)
check(refreshes == 1, "the item arriving refreshes the guide (bag event, once)")
MOCK.fire("BAG_UPDATE_DELAYED")
check(refreshes == 1, "an unrelated bag update does not refresh again")
E.Refresh = real.refresh
check(E.current == 1 and IS:State(S[1]) == "have", "item in bags: the pickup is current again")
check(string.find(ns.StepText:Title(S[1]), "Use [Gold Pickup Schedule] to accept", 1, true), "title: use the item to accept the quest")
check(string.find(table.concat(ns.StepText:Details(S[1]), "\n"), "right-click it, then click Accept", 1, true), "details: how to start it")
check(ns.StepText:Target(S[1]) == nil, "no waypoint while the item is in your bags")
check(E.status[1] ~= "done", "having the item is not having the quest")
E:Refresh() -- e.g. the quest window opened and closed without accepting: nothing in the log changed
check(E.current == 1 and E.status[1] == "active", "an opened quest window is not acceptance")

-- B: accepted
setLog({ KQ, IQ })
bags(nil) -- the item is used up
E:Refresh()
check(E.status[1] == "done" and IS:State(S[1]) == "accepted", "accepted: the pickup is done once the quest is in your log")
check(not E.waiting[4] and E.status[4] ~= "skipped", "its objective is open again")

-- D -> fallback: no item and the kill steps are behind you
E:Reset()
setLog({ KQ })
E.progress.done[2], E.progress.done[3] = true, true
E:Refresh()
check(E.current == 1 and IS:State(S[1]) == "farm", "kill steps done, no item: the pickup comes back to farm the item")
check(string.find(ns.StepText:Title(S[1]), "Get [Gold Pickup Schedule] from ", 1, true), "title: get the item from its droppers")
local fd = table.concat(ns.StepText:Details(S[1]), "\n")
check(string.find(fd, "Dropped by: ", 1, true) and string.find(fd, "Skip this step", 1, true), "details: the droppers and the way out")
local tz = ns.StepText:Target(S[1])
check(tz ~= nil, "the arrow points at a dropper")
local npcs = ns.Assist:StepNpcIds()
check(npcs[acc.drops[1]] ~= nil or next(npcs) ~= nil, "the droppers are the step's targets (macro, target list)")

-- Skip stays a skip, not completion; the quest's later steps step aside
E:Skip(1)
check(E.status[1] == "skipped" and E.status[4] == "skipped" and E.status[5] == "skipped", "skipped: the pickup and its quest's steps are skipped")
check(E.current == 6, "the route goes on")
check(not T:IsTurnedIn(IQ) and not T:InLog(IQ), "skipping never marks the quest done")
-- The item turns up later and you accept it after all
setLog({ KQ, IQ })
E:Refresh()
check(E.status[1] == "done" and E.status[4] ~= "skipped" and E.current == 4, "taken after all: the pickup counts as done and its steps come back")
check(E.progress.skipped[1] == true, "(the skip is still recorded)")

-- A: turned in
MOCK.completed[IQ] = true
setLog({ KQ })
T.turnedIn[IQ] = true
E:Refresh()
check(IS:State(S[1]) == "done" and E.status[1] == "done", "turned in: done")
MOCK.completed[IQ], T.turnedIn[IQ] = nil, nil

-- E: not available -> the engine's own auto-skip, whatever the bags hold
E:Reset()
MOCK.player.level = 1
setLog({})
bags(ITEM)
E:Refresh()
check(E.status[1] == "skipped" and E.autoReason[1] and string.find(E.autoReason[1], "level", 1, true), "below the required level: skipped with the reason, item or not")
MOCK.player.level = 15

-- No kill step in the guide: the pickup is the farm step at once
bags(nil)
steps = { { "accept", q = IQ, starter = ITEM, drops = acc.drops }, { "complete", q = IQ }, { "turnin", q = IQ } }
ns.Guides:RegisterDynamic({ id = "TEST_ItemStarts", name = "Item starts", faction = "Both", minLevel = 1, maxLevel = 60, dynamic = true, steps = steps })
E:Load("TEST_ItemStarts", { reset = true })
check(E.current == 1 and IS:State(E.guide.steps[1]) == "farm", "no kill step for its droppers: farm the item now")
-- A kill step that is itself waiting: never "guide finished" with open steps
steps = { { "accept", q = IQ, starter = ITEM, drops = acc.drops, via = { 2 } }, { "turnin", q = IQ } }
ns.Guides:RegisterDynamic({ id = "TEST_ItemStarts", name = "Item starts", faction = "Both", minLevel = 1, maxLevel = 60, dynamic = true, steps = steps })
E:Load("TEST_ItemStarts", { reset = true })
check(E.current == 1, "only waiting steps left: the first of them is current, the guide is not finished")

-- A starter item for a later pickup already in your bags: the current step says so
steps = { { "note", text = "first" }, { "accept", q = IQ, starter = ITEM, drops = acc.drops } }
ns.Guides:RegisterDynamic({ id = "TEST_ItemStarts", name = "Item starts", faction = "Both", minLevel = 1, maxLevel = 60, dynamic = true, steps = steps })
E:Load("TEST_ItemStarts", { reset = true })
bags(ITEM)
check(E.current == 1 and string.find(table.concat(ns.StepText:Details(E.guide.steps[1]), "\n"), "You have Gold Pickup Schedule: it starts The Collector", 1, true),
    "an item in your bags for a later pickup is pointed out")
bags(nil)

-- [iffound]: an item many kinds of mob drop. Hidden (and not counted) until the item or the quest turns up
setLog({})
bags(nil)
steps = { { "note", text = "first" }, { "accept", q = IQ, starter = ITEM, drops = acc.drops, ifFound = true },
          { "complete", q = IQ, ifFound = true }, { "turnin", q = IQ, ifFound = true }, { "note", text = "last" } }
ns.Guides:RegisterDynamic({ id = "TEST_ItemStarts", name = "Item starts", faction = "Both", minLevel = 1, maxLevel = 60, dynamic = true, steps = steps })
E:Load("TEST_ItemStarts", { reset = true })
local _, total = E:Counts()
check(E.status[2] == "na" and E.status[3] == "na" and E.status[4] == "na", "iffound: no item, no quest: its steps are hidden")
check(total == 2, "and not counted in the guide's progress")
E.progress.done[1] = true
E:Refresh()
check(E.current == 5, "the route goes past them: never waited for, never farmed")
bags(ITEM)
check(E.current == 2 and IS:State(E.guide.steps[2]) == "have", "the item in your bags: the pickup appears and is current")
local d = table.concat(ns.StepText:Details(E.guide.steps[2]), " ")
check(string.find(d, "right-click it, then click Accept", 1, true) and string.find(d, "only because you found the item", 1, true),
    "it says to use the item, and why the step appeared")
check(E.status[3] == "na", "its objective stays hidden until the quest is taken")
setLog({ IQ })
bags(nil)
E:Refresh()
check(E.status[2] == "done" and E.status[3] ~= "na" and E.status[4] ~= "na" and E.current == 3, "accepted: its objective and turn-in are in the route")
setLog({})
E:Refresh()
check(E.status[3] == "na" and E.current == 5, "abandoned without the item: hidden again")

-- Completionist ------------------------------------------------------------------------------------------
local CM, QDB = ns.Completionist, ns.QDB
local saved = { quests = QDB.quests, npcs = QDB.npcs, objects = QDB.objects, items = QDB.items, names = QDB.zones.names,
                parent = QDB.zones.parent, geo = ns.ZoneGeo, log = T.log, turned = T.turnedIn, state = ns.char.completionist }
local MUL = 215
local function npc(name, x, y) return { name, 1, 60, 0, MUL, { [MUL] = { { x, y } } } } end
QDB.npcs = { [9001] = npc("Giver", 40, 50), [9101] = npc("Plainstrider", 45, 55), [9102] = npc("Prairie Wolf", 60, 60),
             [9103] = npc("Quilboar", 70, 70) }
QDB.objects = {}
QDB.items = { [7001] = { "Torn Letter", { 9103 } }, [7002] = { "Nobody's Letter", {} } }
QDB.zones.names, QDB.zones.parent = { [MUL] = "Mulgore" }, {}
ns.ZoneGeo = { [MUL] = { 1, -1000, -1000, 1000, 1000 } }
QDB.quests = {
    [101] = { "Plain", 1, 2, 0, 0, { 9001 }, nil, nil, { 9001 }, nil, "", { c = { 9101 } }, nil, nil, MUL },
    [102] = { "Letter", 1, 3, 0, 0, nil, nil, { 7001 }, { 9001 }, nil, "", { c = { 9102 } }, nil, nil, MUL },
    [103] = { "Lost letter", 1, 3, 0, 0, nil, nil, { 7002 }, { 9001 }, nil, "", { c = { 9102 } }, nil, nil, MUL },
}
T.log, T.turnedIn = {}, {}
ns.char.completionist = nil
CM:ResetCache()
local ctx = { race = "Tauren", class = "WARRIOR", faction = "Horde", level = 3,
              completed = function() return false end, inLog = function() return false end }
local z, _, _, name, item = CM:GiverPos(QDB.quests[102])
check(z == MUL and name == "Quilboar" and item == 7001, "Completionist: an item-started quest is placed at the NPC that drops the item")
check(CM:Classify(102, ctx) == "actionable", "and is routed")
check(CM:Classify(103, ctx) == "missing", "an item no NPC drops in the data stays 'missing location data' (no guessed source)")
local seg = CM:Plan(ctx, { MUL, 40, 50 })
local order = {}
for i, s in ipairs(seg.steps) do order[(s[1] or "") .. (s.q or "")] = i end
check(order.accept102 and order.complete101 and order.accept102 > order.complete101, "the item pickup comes after the zone's other objectives")
check(order.complete102 and order.complete102 > order.accept102 and order.turnin102 > order.complete102, "then its own objective and turn-in")
local ps = seg.steps[order.accept102]
check(ps.starter == 7001 and ps.drops and ps.drops[1] == 9103, "the pickup carries the item and its dropper")
-- Skipping it in a segment keeps it out until the item is in your bags
ns.Guides:RegisterDynamic({ id = CM.GUIDE_ID, name = "Completionist", faction = "Both", minLevel = 1, maxLevel = 60, dynamic = true, steps = seg.steps })
CM.segment = seg
ns:ResetProgress(CM.GUIDE_ID)
ns.char.progress[CM.GUIDE_ID].skipped[order.accept102] = true
CM:RecordItemSkips()
check(CM:Classify(102, ctx) == "itemskipped", "a skipped item pickup is its own category, not completed")
check(CM:Summary(CM:Inventory(ctx)).itemskipped == 1 and CM:Summary(CM:Inventory(ctx)).completed == 0, "and counted apart from completed quests")
bags(7001)
check(CM:Classify(102, ctx) == "actionable", "with the item in your bags it is planned again")
bags(nil)

QDB.quests, QDB.npcs, QDB.objects, QDB.items = saved.quests, saved.npcs, saved.objects, saved.items
QDB.zones.names, QDB.zones.parent, ns.ZoneGeo = saved.names, saved.parent, saved.geo
T.log, T.turnedIn, ns.char.completionist = saved.log, saved.turned, saved.state
CM.segment = nil
CM:ResetCache()

MOCK.questLog, MOCK.player.level, MOCK.bags[0][9] = real.log, real.level, real.slot
T:Scan()
E:Load("A_Human_Elwynn", { reset = true })
