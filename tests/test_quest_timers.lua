-- Questwarden - headless tests for timed quests (Core/QuestTimer.lua; loaded by run_tests.lua)
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- SPDX-License-Identifier: GPL-3.0-only
--
-- Scalding Mornbrew Delivery (3364, 5 minutes) is the timed quest; Dwarven Outfitters (179) and The Boar Hunter
-- (183) are the other quests of the small test guide.

local check, ns = TEST.check, TEST.ns
local QT, QA, E, G = ns.QuestTimer, ns.QuestAuto, ns.Engine, ns.Guides
local TIMED = 3364

check(QT:Limit(TIMED) == 300 and QT:Limit(179) == nil, "time limits come from Database/QuestTimers.lua")
check(QT.Words(300) == "5 minutes" and QT.Words(5400) == "1 hour 30 minutes" and QT.Words(45) == "45 seconds", "limits in words")
check(QT.Format(272) == "4:32" and QT.Format(3725) == "1:02:05", "time left as a clock")

-- The game clock and its quest timers.
MOCK.epoch = 1000000
time = function() return MOCK.epoch end
MOCK.questTimers = {}
GetQuestTimers = function() return unpack(MOCK.questTimers) end

G:Register({ id = "T_Timed", name = "Timed test", faction = "Alliance", minLevel = 1, maxLevel = 10, steps = {
    { "accept", q = TIMED, title = "Scalding Mornbrew Delivery" },
    { "accept", q = 179, title = "Dwarven Outfitters" },
    { "complete", q = 179, title = "Dwarven Outfitters" },
    { "turnin", q = TIMED, title = "Scalding Mornbrew Delivery" },
    { "turnin", q = 183, title = "The Boar Hunter" },
} })
MOCK.questLog, MOCK.completed = {}, {}
ns.Tracker.turnedIn = {}
ns.Tracker:Scan()
E:Load("T_Timed", { reset = true })

-- Before accepting: a warning on the step and when the quest's details open; never accepted for you.
local lines = table.concat(ns.StepText:Details(E.guide.steps[1]), "\n")
check(string.find(lines, "once you accept it you have 5 minutes", 1, true) ~= nil, "the pickup step warns that the quest is timed")
-- (The test character cannot take this dwarf and gnome quest, so the guide index is set here.)
QA.acceptOpen[TIMED] = E.guide.steps[1]
local ok, why = QA:CanAccept(TIMED)
check(not ok and why == "timed quest", "a timed quest is not accepted automatically")
ns.db.profile.autoAccept = true
MOCK.calls, MOCK.printed = {}, {}
MOCK.dialog = { questID = TIMED, title = "Scalding Mornbrew Delivery", text = "Deliver it while it is hot." }
MOCK.fire("QUEST_DETAIL")
local said = false
for _, m in ipairs(MOCK.printed) do if string.find(m, "5 minutes", 1, true) then said = true end end
check(#MOCK.calls == 0 and said, "quest window: warned in chat, not accepted")
MOCK.fire("QUEST_DETAIL")
local n = 0
for _, m in ipairs(MOCK.printed) do if string.find(m, "5 minutes", 1, true) then n = n + 1 end end
check(n == 1, "the warning is said once per window")
MOCK.dialog = nil

-- Accepted: the clock runs from the accept, and the game's timer wins when it is unambiguous.
MOCK.questLog = { { id = TIMED, title = "Scalding Mornbrew Delivery", objectives = {} } }
MOCK.fire("QUEST_ACCEPTED", 1, TIMED)
ns.Tracker:Scan()
MOCK.epoch = MOCK.epoch + 60
check(QT:TimeLeft(TIMED) == 240, "time left counted from the accept")
MOCK.questTimers = { 200 }
check(QT:TimeLeft(TIMED) == 200, "time left from the game's quest timer")
ns.db.profile.timedQuestBar = true
QT:Update()
check(QT.bar and QT.bar:IsShown() and string.find(QT.bar.text:GetText() or "", "3:20", 1, true) ~= nil, "the timer bar shows the time left")
lines = table.concat(ns.StepText:Details(E.guide.steps[4]), "\n")
check(string.find(lines, "3:20 left", 1, true) ~= nil, "the turn-in step shows the time left")

-- The guide puts the turn-in first: the pickup of Dwarven Outfitters waits.
E:Refresh()
check(E.current == 4, "a timed quest in the log: its turn-in comes before other pickups")
-- Only turn-ins in between: they are on the way and stay first.
G:Register({ id = "T_Timed2", name = "Timed test 2", faction = "Alliance", minLevel = 1, maxLevel = 10, steps = {
    { "accept", q = TIMED, title = "Scalding Mornbrew Delivery" },
    { "turnin", q = 183, title = "The Boar Hunter" },
    { "turnin", q = TIMED, title = "Scalding Mornbrew Delivery" },
} })
E:Load("T_Timed2", { reset = true })
check(E.current == 2, "a turn-in on the way stays before the timed turn-in")

-- Out of time: the quest failed, so it no longer comes first.
MOCK.questTimers = {}
MOCK.questLog = { { id = TIMED, title = "Scalding Mornbrew Delivery", failed = true, objectives = {} } }
ns.Tracker:Scan()
E:Load("T_Timed", { reset = true })
check(not QT:Running(TIMED) and E.current == 2, "a failed timed quest is not put first")
check(string.find(QT:BarText() or "", "failed", 1, true) ~= nil, "the bar says it failed")

-- Setting off: no bar.
ns.db.profile.timedQuestBar = false
QT:Update()
check(not QT.bar:IsShown(), "Show Timed Quest Timers off hides the bar")
ns.db.profile.timedQuestBar = true

MOCK.questLog, MOCK.questTimers = {}, {}
ns.Tracker:Scan()
GetQuestTimers, time = nil, nil
E:Load("A_Human_Elwynn", { reset = true })
