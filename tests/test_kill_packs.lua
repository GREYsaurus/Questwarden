-- Questwarden - headless tests for kill packs (Core/Engine.lua; loaded by run_tests.lua)
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- SPDX-License-Identifier: GPL-3.0-only
--
-- Objective steps whose mobs spawn in the same area are done together (GuideCompiler.LinkKillPacks). Every open
-- step of the current step's pack is shown as current, and targeted and marked. The engine checks use a small
-- generated guide with real Dun Morogh quests; the last block uses the real TBC Dun Morogh guide.

local check, ns = TEST.check, TEST.ns
local G, E, M, A = ns.Guides, ns.Engine, ns.Marker, ns.Assist

-- The registry only takes a pack that is a run of steps naming its first step.
local nRejected, nErrors = #G.rejected, #ns.errors
G:Register({ id = "T_PackAhead", name = "t", faction = "Alliance", steps = { { "complete", q = 179, pack = 2 }, { "complete", q = 183, pack = 2 } } })
G:Register({ id = "T_PackGap", name = "t", faction = "Alliance", steps = {
    { "complete", q = 179, pack = 1 }, { "note", text = "x" }, { "complete", q = 183, pack = 1 } } })
check(G.byId["T_PackAhead"] == nil and G.byId["T_PackGap"] == nil and #G.rejected == nRejected + 2,
    "registry rejects a pack that points ahead or has a gap")
table.remove(G.rejected) table.remove(G.rejected)
while #ns.errors > nErrors do table.remove(ns.errors) end

-- Five Dun Morogh kill and drop quests in one pack (more than Marker.MAX_TYPES), then one step outside it.
G:Register({ id = "T_Pack", name = "Pack test", faction = "Alliance", minLevel = 1, maxLevel = 10, steps = {
    { "complete", q = 179, title = "Dwarven Outfitters", pack = 1 },
    { "complete", q = 183, title = "The Boar Hunter", pack = 1 },
    { "complete", q = 170, title = "A New Threat", pack = 1 },
    { "complete", q = 182, title = "The Troll Cave", pack = 1 },
    { "complete", q = 313, title = "The Grizzled Den", pack = 1 },
    { "complete", q = 317, title = "Stocking Jetsteam" },
    { "note", text = "after" },
} })
check(G.byId["T_Pack"] ~= nil, "registry accepts a five-step pack")
-- All five quests are in your log, with nothing done yet.
local function inLog(...)
    local log = {}
    for _, q in ipairs({ ... }) do log[#log + 1] = { id = q, title = "Quest " .. q, objectives = { { text = "x: 0/1", done = false } } } end
    return log
end
MOCK.questLog, MOCK.completed = inLog(179, 183, 170, 182, 313), {}
ns.Tracker.turnedIn = {}
ns.Tracker:Scan()
E:Load("T_Pack", { reset = true })
local st = E.status
check(E.current == 1 and st[2] == "active" and st[3] == "active" and st[4] == "active" and st[5] == "active",
    "every open step of the current pack is active")
check(st[6] == "pending", "the step after the pack is not")
check(#E:PackSteps() == 5, "PackSteps lists the whole pack")
check(#E:Upcoming(1) == 5, "the step list shows the whole pack even when it shows one step")
check(pcall(function() ns.MainFrame:Render() end), "main window renders a pack")

local ids = A:StepNpcIds()
check(ids[705] and ids[708] and ids[707] and ids[724], "targets cover the mobs of every pack step (wolves, boars, troggs)")
-- The macro holds what fits in 255 characters; it must reach past the first step's wolves.
local body = A:MacroBody()
local later = false
for name in string.gmatch(body, "/tar ([^\n]+)") do
    if not string.find(name, "Wolf", 1, true) then later = true end
end
check(later and #body <= 255, "the targeting macro names mobs of later pack steps")

ns.db.profile.autoMarkObjectives = true
M:OnStep()
local n = 0
for _ in pairs(M.rule and M.rule.icons or {}) do n = n + 1 end
check(n == 5 and n > M.MAX_TYPES, "markers: one icon per pack step, beyond the usual " .. M.MAX_TYPES)

-- A pack step finished out of order stays done; the rest stay current.
E:MarkDone(3)
check(E.current == 1 and st[3] == "done" and #E:PackSteps() == 4, "a finished pack step drops out of the pack")
E:MarkDone(1)
check(E.current == 2 and E.status[4] == "active" and E.status[5] == "active" and #E:PackSteps() == 3,
    "finishing the current step moves on inside the pack")
M:OnStep()
check(M.rule and M.rule.types[705] == nil and M.rule.types[708], "the finished steps' mobs are no longer marked")

-- A pack step whose quest you have not picked up yet is not current, and its mobs are not marked.
MOCK.questLog = inLog(179, 170, 182, 313)
ns.Tracker:Scan()
E:Load("T_Pack", { reset = true })
M:OnStep()
check(E.status[2] == "pending" and E.status[3] == "active", "a pack step of a quest not in your log waits")
check(M.rule and M.rule.types[705] and not M.rule.types[708], "mobs of a quest not in your log are not marked")
check(not A:StepNpcIds()[708], "nor in the target list")

-- Objectives your log shows done drop out: A New Threat with its Rockjaw Troggs slain, Burly ones still needed.
MOCK.questLog = inLog(179, 183, 182, 313)
MOCK.questLog[#MOCK.questLog + 1] = { id = 170, title = "A New Threat", objectives = {
    { text = "Rockjaw Trogg slain: 6/6", type = "monster", done = true },
    { text = "Burly Rockjaw Trogg slain: 2/6", type = "monster", done = false } } }
ns.Tracker:Scan()
E:Load("T_Pack", { reset = true })
E:MarkDone(1) E:MarkDone(2)
M:OnStep()
check(E.current == 3 and M.rule and M.rule.types[724] and not M.rule.types[707], "a finished kill objective is no longer marked")
local ids3 = A:StepNpcIds()
check(ids3[724] and not ids3[707], "nor targeted")
-- An item objective: Dwarven Outfitters' Tough Wolf Meat collected, so its wolves drop out.
MOCK.questLog = inLog(183, 170, 182, 313)
MOCK.questLog[#MOCK.questLog + 1] = { id = 179, title = "Dwarven Outfitters", objectives = {
    { text = "Tough Wolf Meat: 8/8", type = "item", done = true } } }
ns.Tracker:Scan()
check(not next(ns.Tracker:OpenObjectiveNpcIds(179) or { x = 1 }), "a collected item objective leaves no droppers")
check(ns.Tracker:OpenObjectiveNpcIds(4242) == nil, "a quest not in your log: nil")
MOCK.questLog = {}
ns.Tracker:Scan()

-- The shipped Dun Morogh guide: Dwarven Outfitters and The Boar Hunter are done together.
local g = G.byId["A_DwarfGnome_DunMorogh"]
local a, b
for i, s in ipairs(g.steps) do
    if s[1] == "complete" and s.q == 179 then a = i end
    if s[1] == "complete" and s.q == 183 then b = i end
end
check(a and b and g.steps[a].pack and g.steps[a].pack == g.steps[b].pack, "Dun Morogh: Dwarven Outfitters and The Boar Hunter share a pack")
MOCK.questLog = inLog(179, 183)
ns.Tracker:Scan()
E:Load("A_DwarfGnome_DunMorogh", { reset = true })
for i = 1, a - 1 do E.progress.done[i] = true end
E:Refresh()
check(E.current == a and E.status[b] == "active", "Dun Morogh: both are current at once")
MOCK.questLog = {}
ns.Tracker:Scan()
E:Load("A_Human_Elwynn", { reset = true })
