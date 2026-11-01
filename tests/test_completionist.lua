-- Questwarden tests - Completionist mode (Core/Completionist.lua).
-- SPDX-License-Identifier: GPL-3.0-only
--
-- Most routing checks use a SYNTHETIC fixture (made-up quest ids 101-499 and NPC ids 9000+ in three zones
-- named after real ones): it tests the policy, it is not a real itinerary. The last block uses the real
-- bundled data and the real engine.

local check, ns = TEST.check, TEST.ns
local CM, QDB = ns.Completionist, ns.QDB

-- ---------------------------------------------------------------- synthetic fixture
local real = { quests = QDB.quests, npcs = QDB.npcs, objects = QDB.objects, items = QDB.items,
               names = QDB.zones.names, parent = QDB.zones.parent, geo = ns.ZoneGeo, log = ns.Tracker.log,
               turned = ns.Tracker.turnedIn, state = ns.char.completionist, mode = ns.char.mode }

local MUL, BAR, DUR, WC = 215, 17, 14, 718
local TAUREN, HUMAN, WARRIOR = QDB.RACE_BITS.Tauren, QDB.RACE_BITS.Human, QDB.CLASS_BITS.WARRIOR
local function npc(name, zone, x, y, rank) return { name, 1, 60, rank or 0, zone, { [zone] = { { x, y } } } } end
-- quest record: name, req, level, races, classes, startNpcs, startObj, startItems, endNpcs, endObj, text, objectives,
-- preGroup, preSingle, zone, exclusive, next, breadcrumb, specialFlags, maxLevel
local function quest(name, req, level, giver, target, zone, extra)
    local r = { name, req, level, 0, 0, { giver }, nil, nil, { giver }, nil, "", { c = { target } }, nil, nil, zone }
    for k, v in pairs(extra or {}) do r[k] = v end
    return r
end

local function useFixture()
    QDB.npcs = {
        [9001] = npc("Mulgore Giver", MUL, 40, 50), [9002] = npc("Barrens Giver", BAR, 50, 30), [9003] = npc("Durotar Giver", DUR, 50, 50),
        [9101] = npc("Plainstrider", MUL, 45, 55), [9102] = npc("Prairie Wolf", MUL, 60, 60), [9103] = npc("Bristleback", MUL, 30, 70),
        [9201] = npc("Zhevra", BAR, 52, 35), [9202] = npc("Raptor", BAR, 55, 40), [9211] = npc("Kolkar", BAR, 40, 70),
        [9212] = npc("Harpy", BAR, 42, 72), [9301] = npc("Scorpid", DUR, 52, 52), [9302] = npc("Boar", DUR, 55, 55),
        [9303] = npc("Crab", DUR, 60, 40), [9401] = npc("Cave Boss", WC, 50, 50, 1), [9402] = npc("Ogre Elite", BAR, 60, 20, 1),
        [9499] = { "Nowhere Giver", 1, 60, 0, MUL, {} },
    }
    QDB.objects, QDB.items = {}, {}
    QDB.zones.names = { [MUL] = "Mulgore", [BAR] = "The Barrens", [DUR] = "Durotar", [WC] = "Wailing Caverns" }
    QDB.zones.parent = {}
    ns.ZoneGeo = { [MUL] = { 1, -1000, -1000, 1000, 1000 }, [BAR] = { 1, -1000, 2000, 1000, 4000 }, [DUR] = { 1, -1000, 5000, 1000, 7000 } }
    QDB.quests = {
        [101] = quest("Mulgore 1", 1, 2, 9001, 9101, MUL),
        [102] = quest("Mulgore 2", 2, 4, 9001, 9102, MUL),
        [103] = quest("Mulgore chain", 3, 5, 9001, 9103, MUL, { [13] = { 101 } }),
        [201] = quest("Barrens 1", 8, 10, 9002, 9201, BAR),
        [202] = quest("Barrens 2", 9, 11, 9002, 9202, BAR),
        [303] = quest("Durotar 0", 8, 10, 9003, 9303, DUR),
        [301] = quest("Durotar 1", 10, 13, 9003, 9301, DUR),
        [302] = quest("Durotar 2", 10, 14, 9003, 9302, DUR),
        [211] = quest("Barrens 3", 15, 18, 9002, 9211, BAR),
        [212] = quest("Barrens 4", 15, 19, 9002, 9212, BAR),
        [401] = quest("Alliance only", 1, 3, 9001, 9101, MUL, { [4] = HUMAN }),
        [402] = quest("Dungeon", 15, 20, 9002, 9401, BAR),
        [403] = quest("Repeatable", 1, 3, 9001, 9101, MUL, { [19] = 1 }),
        [404] = quest("Event", 1, 3, 9001, 9101, -22),
        [405] = quest("Other branch", 1, 2, 9001, 9101, MUL, { [16] = { 101 } }),
        [406] = quest("No location", 1, 2, 9499, 9101, MUL),
        [407] = quest("Elite", 15, 20, 9002, 9402, BAR),
    }
    ns.Tracker.log, ns.Tracker.turnedIn = {}, {}
    ns.char.completionist = nil
    CM:ResetCache()
end

local function restore()
    QDB.quests, QDB.npcs, QDB.objects, QDB.items = real.quests, real.npcs, real.objects, real.items
    QDB.zones.names, QDB.zones.parent, ns.ZoneGeo = real.names, real.parent, real.geo
    ns.Tracker.log, ns.Tracker.turnedIn = real.log, real.turned
    ns.char.completionist, ns.char.mode = real.state, real.mode
    CM:ResetCache()
end

local function ctxFor(level, done, opts)
    opts = opts or {}
    return { race = opts.race or "Tauren", class = "WARRIOR", faction = "Horde", level = level,
             completed = function(id) if opts.unknown then return nil end return done[id] == true end,
             inLog = function(id) return opts.log and opts.log[id] or false end }
end

useFixture()

-- Classification ----------------------------------------------------------------------------------
local c = ctxFor(1, {})
check(CM:Classify(401, c) == "ineligible", "a quest for another race is ineligible")
check(CM:Classify(101, c) == "actionable", "a level-1 quest is actionable at level 1")
check(CM:Classify(102, c) == "deferred", "a required level above yours defers the quest")
check(CM:Classify(103, ctxFor(5, {})) == "blocked", "an open prerequisite blocks the quest")
check(CM:Classify(103, ctxFor(5, { [101] = true })) == "actionable", "the prerequisite done unblocks it")
check(CM:Classify(405, ctxFor(1, { [101] = true })) == "exclusive", "the other branch of a choice is not counted as unfinished")
check(CM:Classify(402, ctxFor(20, {})) == "dungeon", "a quest with objectives inside an instance is a dungeon quest")
check(CM:Classify(407, ctxFor(20, {})) == "group", "a quest with an elite target is a group quest")
check(CM:Classify(403, c) == "repeatable" and CM:Classify(404, c) == "event", "repeatable and event quests are their own categories")
check(CM:Classify(406, c) == "missing", "a quest whose giver has no position is missing data, not routable")
check(CM:Classify(101, ctxFor(1, {}, { unknown = true })) == "unknown", "without completion data the state is unknown, never assumed")
check(CM:Classify(101, ctxFor(5, { [101] = true })) == "completed", "a completed quest is completed")
CM:SetIncluded("dungeon", true)
check(CM:Classify(402, ctxFor(20, {})) == "actionable", "turning dungeon quests on makes them routable")
CM:SetIncluded("dungeon", false)

-- Level first, then geography ---------------------------------------------------------------------
local done = { [303] = true }
local seg = CM:Plan(ctxFor(13, done), { DUR, 50, 50 })
check(seg.zone == MUL, "missed quests two bands lower come first, even though the current zone has work (level before travel)")
seg = CM:Plan(ctxFor(10, { [101] = true, [102] = true, [103] = true, [201] = true }), { BAR, 50, 50 })
check(seg.zone == BAR, "work one band above the lowest keeps you in the current zone (no hopping over a level)")
done = { [101] = true, [102] = true, [103] = true }
seg = CM:Plan(ctxFor(10, done), { MUL, 40, 50 })
check(seg.zone == BAR, "equal work in two zones: the nearer one (geography inside a band)")
local accepts, kinds = 0, {}
for _, s in ipairs(seg.steps) do kinds[#kinds + 1] = s[1]; if s[1] == "accept" then accepts = accepts + 1 end end
check(kinds[1] == "travel" and accepts == 2, "a segment in another zone starts with travel, then its pickups (both Barrens quests in the window)")
local order = table.concat(kinds, ",")
check(string.find(order, "accept.*complete.*turnin") ~= nil, "pickups, then objectives, then turn-ins")

-- The whole fixture: a recurring zone is visited again ---------------------------------------------
done = {}
local level, here, zones, guard = 1, { MUL, 40, 50 }, {}, 0
while guard < 20 do
    guard = guard + 1
    seg = CM:Plan(ctxFor(level, done), here)
    if seg.kind == "done" then break end
    if seg.kind == "level" then
        level = seg.steps[1].level
    else
        zones[#zones + 1] = seg.zone
        for _, q in ipairs(seg.accepted) do done[q] = true; level = math.max(level, QDB.quests[q][3]) end
        here = { seg.zone, 50, 50 }
    end
end
local seq = table.concat(zones, ">")
check(seq == "215>215>215>17>17>14>14>17>17", "route: Mulgore, the Barrens, Durotar, back to the Barrens (" .. seq .. ")")
local routed, ids = 0, {}
for q in pairs(done) do routed = routed + 1 ids[#ids + 1] = q end
table.sort(ids)
check(routed == 10 and not done[401] and not done[402] and not done[403] and not done[404] and not done[405] and not done[406] and not done[407],
    "every ordinary eligible quest is routed once; ineligible, excluded, exclusive and missing ones never are (" .. table.concat(ids, ",") .. ")")

-- Quest log capacity and unknown completion ---------------------------------------------------------
local _, logMax = ns.Compat.QuestLogSize()
for i = 1, logMax - CM.LOG_RESERVE do ns.Tracker.log[90000 + i] = { complete = false, objectives = {} } end
seg = CM:Plan(ctxFor(1, {}), { MUL, 40, 50 })
check(seg.kind == "quests" and #seg.accepted == 0, "a nearly full quest log takes no more pickups")
ns.Tracker.log = {}
seg = CM:Plan(ctxFor(1, {}, { unknown = true }), { MUL, 40, 50 })
check(seg.kind == "done" and (seg.inv.counts.unknown or 0) > 0, "unknown completion routes nothing and says so")
local sum = CM:Summary(CM:Inventory(ctxFor(20, { [101] = true })))
check(sum.completed == 1 and sum.excluded >= 4 and sum.routable == sum.completed + sum.remaining,
    "the summary keeps completed, remaining and excluded apart, with one denominator")

restore()

-- Real data, engine, modes and setup ------------------------------------------------------------------
local realCtx = { race = "Tauren", class = "WARRIOR", faction = "Horde", level = 1,
                  completed = function() return false end, inLog = function() return false end }
seg = CM:Plan(realCtx, { 215, 45, 75 })
check(seg.kind == "quests" and seg.zone == 215 and #seg.accepted > 0, "real data: a new Tauren starts with Mulgore quests")
local inv = seg.inv
check((inv.counts.deferred or 0) > 100 and (inv.counts.ineligible or 0) > 100, "real data: later quests are deferred, Alliance and other-class quests ineligible")

local E = ns.Engine
local before = ns.char.activeGuide
local completedBefore = 0
for _ in pairs(MOCK.completed) do completedBefore = completedBefore + 1 end
ns.char.mode = nil
check(CM:Mode() == "speed", "characters without a choice stay on Speed (the default)")
CM:SetMode("completionist")
check(ns.char.mode == "completionist" and E.guide and E.guide.id == CM.GUIDE_ID and E.guide.dynamic, "Completionist mode loads a generated route")
check(ns.char.speedGuide == before, "the speed guide in use is remembered")
check(#ns.Guides:Filter({}) > 0 and not ns.Contains(ns.Guides:Filter({}), ns.Guides:Get(CM.GUIDE_ID)), "the generated route is not offered in the guide browser")
CM:SetMode("speed")
local completedAfter = 0
for _ in pairs(MOCK.completed) do completedAfter = completedAfter + 1 end
check(ns.char.mode == "speed" and ns.char.activeGuide == before and completedAfter == completedBefore,
    "switching back restores the speed guide; quest history is untouched")

local WL = ns.Welcome
local setupBefore, draftBefore = ns.char.setupDone, ns.char.setupDraft
ns.char.setupDone, ns.char.setupDraft = nil, nil
check(WL:Draft().mode == "speed", "first-login setup proposes Speed")
WL:Draft().mode = "completionist"
check(not ns.char.setupDone, "choosing in setup does nothing before Finish")
WL:Finish()
check(ns.char.setupDone and ns.char.mode == "completionist" and E.guide.id == CM.GUIDE_ID, "Finish with Completionist saves the mode and plans the route")
CM:SetMode("speed")
ns.char.setupDone, ns.char.setupDraft = setupBefore, draftBefore
check(#ns.errors == 0, "no captured errors after Completionist tests: " .. table.concat(ns.errors, " | "))
