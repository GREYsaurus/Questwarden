-- Questwarden - headless tests: per-character setup wizard (Core/Setup.lua, UI/Welcome.lua)
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- SPDX-License-Identifier: GPL-3.0-only
-- Loaded by tests/run_tests.lua after boot (TBC fixture); uses TEST.check and TEST.ns. Characters are
-- simulated by swapping the per-character SavedVariables table and re-running InitSavedVariables.

local check, ns = TEST.check, TEST.ns
local S, WL, E, CM, T = ns.Setup, ns.Welcome, ns.Engine, ns.Completionist, ns.Tracker
local function prof() return ns.db.profile end

local function copy(t) local o = {} for k, v in pairs(t or {}) do o[k] = type(v) == "table" and copy(v) or v end return o end
local keep = {
    sv = _G[ns.svChar], player = copy(MOCK.player), log = MOCK.questLog, completed = MOCK.completed,
    showDungeonSteps = prof().showDungeonSteps, dungeonOff = copy(prof().dungeonOff), showElite = prof().showElite,
    autoEquip = prof().autoEquip, load = E.Load, available = CM.Available,
}

-- A brand-new character: empty per-character SavedVariables, a fresh session.
local function newCharacter(name, race, class, faction, level)
    MOCK.player.name, MOCK.player.race, MOCK.player.class, MOCK.player.faction, MOCK.player.level = name, race, class, faction, level
    _G[ns.svChar] = {}
    ns:InitSavedVariables()
    MOCK.questLog, MOCK.completed = {}, {}
    T.turnedIn = {}
    T:Scan()
    S.dismissed = nil
    WL.open, WL.draft = nil, nil
    if WL.frame then WL.frame.shown = false end
    return _G[ns.svChar]
end

-- Switch to a character whose SavedVariables table exists (a later login).
local function login(sv, player)
    for k, v in pairs(player) do MOCK.player[k] = v end
    _G[ns.svChar] = sv
    ns:InitSavedVariables()
    S.dismissed = nil
    WL.open, WL.draft = nil, nil
    if WL.frame then WL.frame.shown = false end
end

-- First-time setup -------------------------------------------------------------------------------------
local orcSV = newCharacter("Grok", "Orc", "WARRIOR", "Horde", 1)
local orc = copy(MOCK.player)
S:Migrate()
check(S:Needed(), "a new character needs setup")
WL:Init()
MOCK.tick(2.5)
check(WL.open and WL.frame and WL.frame.shown, "the wizard opens by itself for a new character")
local d = WL.draft
check(d.mode == "speed" and d.step == 1 and S:GuideValid(d.guide), "defaults: Speed, step 1, the recommended guide")
check(S:Validate(d, "route"), "the default route step is valid")
local guideBefore = ns.char.activeGuide

-- The first page asks whether the player is new; the experienced path has every page
check(d.newPlayer == nil and S:Steps(d)[1].id == "welcome", "the first page asks whether the player is new")
check(not WL:Go(1) and d.step == 1, "Next needs an answer on the first page")
S:SetNewPlayer(d, false)
check(#S:Steps(d) == 7 and WL:Go(1) and d.step == 2, "experienced: seven pages, Next moves to the route")

-- Back and Next keep choices
check(WL:Go(1) and d.step == 3, "Next moves to the talent step")
local plans = S:Plans()
check(#plans >= 2, "warrior plans are offered (" .. #plans .. ")")
for _, p in ipairs(plans) do check(ns.Talents:Get(p.id).class == "WARRIOR", "plan " .. p.id .. " is a warrior plan") end
S:SetPlan(d, plans[2].id)
WL:Go(1)
WL:Go(-1)
check(d.step == 3 and d.plan == plans[2].id, "Back keeps the chosen plan")
check(ns.char.talentBuild == nil and ns.char.mode == nil, "nothing is applied while choosing")

-- Dismiss: not done, draft kept, not reopened this session
WL:Later()
check(not S:Done() and type(ns.char.setup.draft) == "table" and not WL.open, "Set Up Later keeps the draft and does not finish setup")
check(ns.char.activeGuide == guideBefore, "dismissing does not change the active guide")
WL:Init()
MOCK.tick(2.5)
check(not WL.open, "a dismissed wizard does not reopen in the same session")

-- Reload: the draft resumes
login(orcSV, orc)
WL:Init()
MOCK.tick(2.5)
check(WL.open and WL.draft.plan == plans[2].id and WL.draft.step == 3, "after a reload the wizard resumes the draft and step")
d = WL.draft

-- Invalid choices block finishing
local goodGuide = d.guide
d.guide = false
check(not WL:Finish() and not S:Done(), "Speed without a guide cannot be finished")
d.guide = goodGuide
d.step = 4
d.dungeons, d.selected = "selected", {}
check(not WL:Go(1) and d.step == 4 and WL.switchQ.shown, "no dungeon selected: Next is blocked and Questing Only is offered")
WL.switchQ.scripts.OnClick(WL.switchQ)
check(d.dungeons == "questing" and WL:Go(1), "Use Questing Only resolves it")

-- A failing route start keeps everything as it was
ns.Engine.Load = function() return false end
d.guide = (function() for _, g in ipairs(S:Guides()) do if g.id ~= ns.char.activeGuide then return g.id end end end)()
local ok, msg = S:Finish(d)
ns.Engine.Load = keep.load
check(not ok and not S:Done() and string.find(msg, "not finished", 1, true), "a failed route start does not finish setup: " .. tostring(msg))
check(type(ns.char.setup.draft) == "table" and ns.char.setup.draft.plan == plans[2].id, "the choices are kept for a retry")
check(ns.char.routing == nil and ns.char.talentBuild == nil and ns.char.activeGuide == guideBefore, "nothing was half-applied")
d.guide = goodGuide

-- Finish
d.step = 7
check(WL:Finish(), "Finish Setup succeeds")
check(S:Done() and ns.char.setup.draft == nil and ns.char.setup.version == S.VERSION, "setup is done, draft cleared, version saved")
check(ns.char.mode == "speed" and E.guide and E.guide.id == goodGuide, "Standard (Speed) activates the chosen guide")
check(ns.char.talentBuild == plans[2].id and not ns.char.noTalentPlan, "the plan is saved")
check(ns.char.routing.dungeons == "questing", "questing only is saved for this character")
login(orcSV, orc)
WL:Init()
MOCK.tick(2.5)
check(not WL.open, "a finished setup does not show again after a reload")

-- Builds ---------------------------------------------------------------------------------------------------
local live = ns.Talents:ReadLive()
local unspent = ns.Compat.GetUnspentTalentPoints()
local n0 = 0
for _ in pairs(live or {}) do n0 = n0 + 1 end
WL:Open(true)
d = WL.draft
check(d.plan == plans[2].id and d.mode == "speed" and d.guide == goodGuide, "Run Setup Again starts from the current choices")
S:SetPlan(d, "none")
check(WL:Finish() and ns.char.noTalentPlan == true and ns.char.talentBuild == nil, "No talent guidance is a valid choice")
local b, why = ns.TalentHints:Build()
check(b == nil and why == "no guidance", "with no guidance the talent window suggests nothing")
local n1 = 0
for _ in pairs(ns.Talents:ReadLive() or {}) do n1 = n1 + 1 end
check(n1 == n0 and ns.Compat.GetUnspentTalentPoints() == unspent, "choosing a plan never changes learned talents")
local note = S:Sanitize({ plan = "druid_feral_iv" })
check(#note > 0, "another class's plan is reset with a note")

-- Cancelling a re-run changes nothing
WL:Open(true)
WL.draft.mode, WL.draft.dungeons = "completionist", "selected"
WL:Later()
check(ns.char.mode == "speed" and ns.char.routing.dungeons == "questing" and S:Done() and ns.char.setup.draft == nil, "cancelling a re-run leaves the active settings unchanged")

-- Independent characters --------------------------------------------------------------------------------
local taurenSV = newCharacter("Moo", "Tauren", "DRUID", "Horde", 1)
local tauren = copy(MOCK.player)
S:Migrate()
check(S:Needed() and ns.char.routing == nil, "a second character gets its own setup")
d = S:Draft()
for _, p in ipairs(S:Plans()) do check(ns.Talents:Get(p.id).class == "DRUID", "druid plan " .. p.id .. " is a druid plan") end
check(#S:Plans() > 0, "plans are offered at level 1, before talent points exist")
d.mode = "completionist"
S:SetPlan(d, S:Plans()[1].id)
d.dungeons, d.selected = "selected", { ["Blackfathom Deeps"] = true }
check(S:Finish(d), "Completionist setup finishes")
check(ns.char.mode == "completionist" and E.guide and E.guide.id == CM.GUIDE_ID, "Completionist activates the generated route")
check(CM:Routes("dungeon", "Wailing Caverns") and CM:Routes("dungeon", "Blackfathom Deeps"), "Completionist routes every dungeon, whatever the Speed selection")
login(orcSV, orc)
check(ns.char.mode == "speed" and ns.char.routing.dungeons == "questing" and ns.char.noTalentPlan == true, "the first character keeps its own choices")
login(taurenSV, tauren)
check(ns.char.mode == "completionist" and ns.char.routing.selected["Blackfathom Deeps"], "the second character keeps its own choices")

-- Completionist not available: not silently replaced by Speed
CM.Available = function() return false, "test" end
check(not S:ModeInfo("completionist").available, "an unavailable mode is shown as unavailable")
WL:Open(true)
d = WL.draft
local okU = S:Finish(d)
CM.Available = keep.available
check(not okU and ns.char.mode == "completionist", "choosing an unavailable mode fails instead of switching to Speed")
WL:Later()

-- Mid-level character: progress already in the game is reconciled --------------------------------------
local midSV = newCharacter("Mid", "Orc", "WARRIOR", "Horde", 22)
local g = ns.Guides:Get(S:RecommendedGuide())
check(g ~= nil, "a level-22 character gets a recommended guide (" .. tostring(g and g.id) .. ")")
local firstQ
for _, s in ipairs(g.steps) do if s[1] == "accept" and s.q and not s.classes and not s.races then firstQ = s.q break end end
MOCK.completed[firstQ] = true
T:Scan()
d = S:Draft()
d.dungeons = "questing"
check(S:Finish(d) and E.guide.id == g.id, "mid-level setup starts the recommended guide")
local firstIdx
for i, s in ipairs(g.steps) do if s.q == firstQ and s[1] == "accept" then firstIdx = i break end end
check(E.status[firstIdx] == "done", "a quest already turned in counts as done, nothing is replayed")
MOCK.completed[firstQ] = nil

-- Dungeons (Speed) ------------------------------------------------------------------------------------
local rows = S:Dungeons("speed")
local bfd
for _, r in ipairs(rows) do if r.id == "Blackfathom Deeps" then bfd = r end end
check(bfd and bfd.supported and bfd.quests >= 1, "Blackfathom Deeps has guide quests for this character")
local hasAlliance = false
for _, r in ipairs(rows) do if r.faction == "Alliance" then hasAlliance = true end end
check(not hasAlliance, "dungeons of the other faction are not listed")
local cmCounts = CM:DungeonQuestCounts("Orc", "WARRIOR")
local greyed
for _, r in ipairs(rows) do if not r.supported and (cmCounts[r.id] or 0) > 0 then greyed = r break end end
check(greyed == nil or (string.find(greyed.note, "Speed leveling guides", 1, true) and string.find(greyed.note, "Completionist mode still routes", 1, true)),
    "a dungeon greyed out for Speed says Completionist still routes its quests (" .. tostring(greyed and greyed.note) .. ")")

E:Load("H_Ashenvale", { reset = true })
local acc, comp, tin
for i, s in ipairs(E.guide.steps) do
    if s.q == 6921 then if s[1] == "accept" then acc = i elseif s[1] == "complete" then comp = i else tin = i end end
end
check(ns.char.routing.dungeons == "questing" and E.status[acc] == "na", "questing only: the dungeon quest is not routed")
ns.char.routing = { dungeons = "selected", selected = { ["Wailing Caverns"] = true }, elite = false }
E:Refresh()
check(E.status[acc] == "na", "only selected dungeons enter the route (Blackfathom not selected)")
ns.char.routing.selected["Blackfathom Deeps"] = true
E:Refresh()
check(E.status[acc] ~= "na" and E.status[comp] ~= "na", "a selected dungeon's quest is routed")

-- Deferral: skip the run; questing continues; nothing is marked complete
table.insert(MOCK.questLog, { id = 6921, title = "Amongst the Ruins", complete = false, objectives = { { text = "Sapphire", done = false } } })
T:Scan()
E:Refresh()
E:Skip(comp)
E:Refresh()
check(E.status[comp] == "skipped" and E.status[tin] == "skipped" and E.current ~= tin, "skipping the run sets the turn-in aside, questing continues")
check(not T:IsTurnedIn(6921) and T:InLog(6921), "skipping never marks the quest complete")
MOCK.questLog[#MOCK.questLog].complete = true
MOCK.questLog[#MOCK.questLog].objectives[1].done = true
T:Scan()
E:Refresh()
check(E.status[tin] == "pending" or E.status[tin] == "active", "once the quest is complete its turn-in comes back")
MOCK.questLog[#MOCK.questLog].complete = false
MOCK.questLog[#MOCK.questLog].objectives[1].done = false
T:Scan()
-- Deselecting removes the planned run (an in-log quest keeps only its turn-in for later)
E.progress.skipped[comp] = nil
ns.char.routing.selected["Blackfathom Deeps"] = nil
E:Refresh()
check(E.status[comp] == "skipped" and string.find(E.autoReason[comp], "not selected", 1, true), "a deselected dungeon's run leaves the route")
MOCK.questLog = {}
T:Scan()
-- Future dungeons can be selected
newCharacter("Lowbie", "Orc", "WARRIOR", "Horde", 5)
d = S:Draft()
d.dungeons, d.selected = "selected", { ["Blackfathom Deeps"] = true }
for _, r in ipairs(S:Dungeons("speed")) do if r.id == "Blackfathom Deeps" then bfd = r end end
check(bfd.status == "later" and S:Validate(d, "dungeons"), "a dungeon above your level can be selected for later")
-- Draft selections survive questing only and back
d.dungeons = "questing"
d.dungeons = "selected"
check(d.selected["Blackfathom Deeps"], "the selection is kept while questing only is chosen")

-- Persistence and migration ------------------------------------------------------------------------------
-- Legacy character (guide and progress, no setup state): marked done, profile settings still apply
local legacySV = newCharacter("Old", "Orc", "WARRIOR", "Horde", 22)
ns.char.setup = nil
ns.char.activeGuide = "H_Ashenvale"
ns.char.progress = { H_Ashenvale = { step = 4, done = { [1] = true }, skipped = {} } }
S:Migrate()
check(S:Done() and ns.char.setup.legacy and ns.char.routing == nil, "an existing character is not sent through setup")
check(ns.char.progress.H_Ashenvale.step == 4 and ns.char.activeGuide == "H_Ashenvale", "its guide and progress are kept")
prof().showDungeonSteps = false
check(E:DungeonOff("Blackfathom Deeps"), "without setup the settings profile still decides")
prof().showDungeonSteps = true
-- A character from 0.1.0-alpha.2 with an unfinished setup draft resumes it
newCharacter("Alpha", "Orc", "WARRIOR", "Horde", 3)
ns.char.setup = nil
ns.char.activeGuide = "H_OrcTroll_Durotar"
ns.char.setupDraft = { mode = "completionist", guide = "H_OrcTroll_Durotar", profile = false, autoEquip = false }
S:Migrate()
check(not S:Done() and S:Draft().mode == "completionist" and ns.char.setupDraft == nil, "an old unfinished draft is resumed, not skipped")
-- Old setupDone flag
newCharacter("Alpha2", "Orc", "WARRIOR", "Horde", 3)
ns.char.setup, ns.char.setupDone = nil, true
check(S:Done() and ns.char.setupDone == nil, "the old setupDone flag carries over")
-- Corrupt and unknown values
newCharacter("Broken", "Orc", "WARRIOR", "Horde", 3)
_G[ns.svChar].setup, _G[ns.svChar].routing = "garbage", 42
ns:InitSavedVariables()
check(ns.char.setup == nil and ns.char.routing == nil, "corrupt setup and routing records are dropped, not fatal")
ns.char.routing = { dungeons = "bogus", selected = "x" }
local r = S:Routing()
check(r.dungeons == "questing" and type(r.selected) == "table" and r.elite == false, "a damaged routing record is repaired to safe values")
ns.char.routing = nil
ns.char.setup = { draft = { guide = "No_Such_Guide", plan = "no_such_plan", selected = { ["Old Dungeon"] = true, ["Blackfathom Deeps"] = true } } }
d = S:Draft()
check(S:GuideValid(d.guide) and S:PlanValid(d.plan), "a removed guide or plan is replaced")
check(d.selected["Old Dungeon"] == nil and d.selected["Blackfathom Deeps"], "unknown dungeons are dropped, known ones kept")
check(#S.notes >= 3, "each replacement is explained (" .. #S.notes .. " notes)")

-- Confirmed changes keep quest history and progress
login(orcSV, orc)
MOCK.completed[firstQ] = true
local histBefore = 0
for _ in pairs(MOCK.completed) do histBefore = histBefore + 1 end
local progBefore = ns.char.progress[ns.char.activeGuide]
WL:Open(true)
WL.draft.mode = "completionist"
check(WL:Finish() and ns.char.mode == "completionist", "switching to Completionist through setup works")
WL:Open(true)
WL.draft.mode = "speed"
check(WL:Finish() and ns.char.mode == "speed", "and back to Speed")
local histAfter = 0
for _ in pairs(MOCK.completed) do histAfter = histAfter + 1 end
check(histAfter == histBefore and ns.char.progress[ns.char.activeGuide] == progBefore, "quest history and guide progress are untouched")
MOCK.completed[firstQ] = nil

-- Commands and settings entry
local okCmd = pcall(SlashCmdList[ns.key], "setup status")
check(okCmd, "/" .. ns.slash .. " setup status runs")
ns.Config:Show("general")
local rerun
for _, x in ipairs(ns.Config.built.general.widgets) do if x.item and x.item.label == "Run Setup Again" then rerun = x end end
check(rerun ~= nil, "Settings -> General has Run Setup Again")
ns.Config.frame:Hide()
if WL.frame then WL:Later() end

-- restore
_G[ns.svChar] = keep.sv
for k, v in pairs(keep.player) do MOCK.player[k] = v end
ns:InitSavedVariables()
MOCK.questLog, MOCK.completed = keep.log, keep.completed
T.turnedIn = {}
T:Scan()
prof().showDungeonSteps, prof().dungeonOff, prof().showElite, prof().autoEquip = keep.showDungeonSteps, keep.dungeonOff, keep.showElite, keep.autoEquip
S.dismissed = nil
if ns.char.activeGuide and ns.Guides:Get(ns.char.activeGuide) then E:Load(ns.char.activeGuide) end
check(#ns.errors == 0, "no captured errors after setup tests: " .. table.concat(ns.errors, " | "))
