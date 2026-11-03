-- Questwarden - headless tests: help for new players (docs/NEW_PLAYERS.md) and the setup wizard's new-player path
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- SPDX-License-Identifier: GPL-3.0-only
-- Loaded by tests/run_tests.lua after boot (TBC fixture); uses TEST.check and TEST.ns.

local check, ns = TEST.check, TEST.ns
local S, WL, CF, E = ns.Setup, ns.Welcome, ns.Config, ns.Engine
local function prof() return ns.db.profile end
local function printed(pattern, from)
    for i = (from or 0) + 1, #MOCK.printed do if string.find(MOCK.printed[i], pattern, 1, true) then return true end end
    return false
end
local function count(pattern, from)
    local n = 0
    for i = (from or 0) + 1, #MOCK.printed do if string.find(MOCK.printed[i], pattern, 1, true) then n = n + 1 end end
    return n
end

local KEYS = { "newPlayerTips", "spellCoach", "playTogether", "playFollowLeader", "mountGoal", "sessionRecap", "professionTips", "simpleSettings" }
for _, k in ipairs(KEYS) do check(ns.PROFILE_DEFAULTS[k] == false, "new-player setting " .. k .. " is off by default") end
local saved = {}
for _, k in ipairs(KEYS) do saved[k] = prof()[k] end
saved.groupFeatures, saved.autoEquip = prof().groupFeatures, prof().autoEquip
local gearProfile0 = ns.char.gearProfile
check(ns.PROFILE_DEFAULTS.gearQuestRewards == false and ns.PROFILE_DEFAULTS.rewardMarkers == true and ns.PROFILE_DEFAULTS.autoReward == false,
    "quest reward markers are on by default, the chat ranking is off; choosing the reward stays with the player")

-- Explainers -------------------------------------------------------------------------------------------
local NP = ns.NewPlayer
check(ns.PROFILE_DEFAULTS.tipWindows == true, "tips open in a window by default")
local tipWindows0 = prof().tipWindows
prof().tipWindows = false -- chat first; the window is tested below
NP:Reset()
local before = #MOCK.printed
NP:OnStep()
check(#MOCK.printed == before, "explainers are silent while the setting is off")
prof().newPlayerTips = true
NP:OnStep()
check(printed("Useful keys: B bags", before), "the first explanation lists the default keys")
local kind = E:CurrentStep() and E:CurrentStep()[1]
if kind and NP.STEPS[kind] then check(count("New player tip:", before) == 2, "...and explains the current step's kind (" .. kind .. ")") end
local n = #MOCK.printed
NP:OnStep()
check(#MOCK.printed == n, "each explanation shows once per character")
GetBindingKey = function(a) return a == "TOGGLEQUESTLOG" and "SHIFT-L" or nil end
check(NP.Key("questlog") == "SHIFT-L" and NP.Key("bags") == "B", "keys follow the player's bindings, else the default")
GetBindingKey = nil
for k, f in pairs(NP.STEPS) do check(type(f()) == "string" and #f() > 20, "step kind " .. k .. " has an explanation") end
NP:OnLevel(10)
check(printed("talent point", n), "level 10 explains talent points")
NP:Reset()
check(next(ns.char.explained) == nil, "/qw newplayer reset forgets what was shown")

-- Tip window ------------------------------------------------------------------------------------------
local TW = ns.TipWindow
local function ok() TW.ok.scripts.OnClick(TW.ok) TW.frame.scripts.OnHide(TW.frame) end -- the mock's Hide fires no OnHide
prof().tipWindows = true
before = #MOCK.printed
NP:OnDead()
check(#MOCK.printed == before and TW.frame and TW.frame:IsShown(), "with tip windows on, a tip opens a window instead of chat")
check(TW.title:GetText() == "New player tip" and TW.text:GetText():find("Release Spirit", 1, true), "...titled, with the tip's text")
NP:OnLevel(10)
check(TW.text:GetText():find("Release Spirit", 1, true) and TW.ok:GetText():find("1 more", 1, true), "a second tip waits behind the first; OK says how many")
ok()
check(TW.frame:IsShown() and TW.text:GetText():find("talent point", 1, true), "OK shows the next tip")
ok()
check(not TW.frame:IsShown() and #TW.queue == 0, "OK on the last tip closes the window")
MOCK.combat = true
TW:Say("Class tip 1 of 3", "Fight in combat")
check(not TW.frame:IsShown() and #TW.queue == 1, "tips that come in combat wait")
MOCK.combat = false
MOCK.fire("PLAYER_REGEN_ENABLED")
check(TW.frame:IsShown() and TW.title:GetText() == "Class tip 1 of 3", "...and open when combat ends")
TW:Say("Professions", "First line", { "- a", "- b" })
check(TW.ok:GetText():find("1 more", 1, true), "a tip with extra lines queues too")
prof().tipWindows = false
TW:Flush()
check(#TW.queue == 0 and printed("Professions:|r First line", before), "turning the window off sends waiting tips to chat")
ok()
NP:Reset()
prof().newPlayerTips = false

-- New-spell coaching -----------------------------------------------------------------------------------
local SC = ns.SpellCoach
GetSpellDescription = function() return "|cffffffffDeals 10 damage|r to the target. Then more text." end
check(SC.Description(1) == "Deals 10 damage to the target.", "spell description: first sentence without colour codes")
local bars = {}
HasAction = function(slot) return bars[slot] ~= nil end
GetActionInfo = function(slot) return "spell", bars[slot] end
local realSpellInfo = GetSpellInfo
GetSpellInfo = function(id) return id == 100 and "Fireball" or (id == 200 and "Frostbolt" or nil) end
check(SC.OnBars("Fireball") == false, "a spell not on any bar is found missing")
bars[13] = 100
check(SC.OnBars("Fireball") == true, "...and found once it is on a bar")
before = #MOCK.printed
SC:OnLearned(200)
MOCK.tick(1.5)
check(#MOCK.printed == before, "spell coaching is silent while the setting is off")
prof().spellCoach = true
SC:OnLearned(200)
MOCK.tick(1.5)
check(printed("New spell:|r Frostbolt - Deals 10 damage", before), "a learned spell is named with what it does")
check(printed("not on your action bars", before), "...with how to put it on a bar")
before = #MOCK.printed
SC:OnLearned(100)
MOCK.tick(1.5)
check(printed("Fireball", before) and not printed("not on your action bars", before), "no bar hint for a spell already on a bar")
local tips = ns.ClassAdvice and ns.ClassAdvice:For(ns.Compat.PlayerInfo().class)
if tips and tips.tips and #tips.tips > 0 then
    ns.char.coachTip, ns.char.coachTipsShown = nil, nil
    before = #MOCK.printed
    SC:OnLevel(5)
    check(#MOCK.printed == before, "no class tip between tip levels")
    SC:OnLevel(8)
    check(printed("Class tip 1 of", before) and ns.char.coachTipsShown[1], "class tips come every few levels")
    check(SC.TipLevel("Use Overpower (12) every time a target dodges.") == 12, "a tip's level is the first level it names")
    check(SC.TipLevel("Learn Whirlwind at 36 for groups. Mortal Strike (from 40) later.") == 36, "...also written as 'at N'")
    check(SC.TipLevel("Keep First Aid trained.") == 0, "a tip naming no level can come any time")
    -- A tip whose level is not reached waits; the next one that fits comes instead.
    local keep = tips.tips
    tips.tips = { "Charge first.", "Use Overpower (12) when it dodges.", "Bandages help." }
    ns.char.coachTipsShown = { [1] = true }
    before = #MOCK.printed
    SC:OnLevel(8)
    check(printed("Class tip 3 of 3", before) and not printed("Overpower", before), "a tip for a spell you cannot learn yet waits")
    before = #MOCK.printed
    SC:OnLevel(12)
    check(printed("Class tip 2 of 3", before), "...and comes once you reach its level")
    ns.char.coachTip, ns.char.coachTipsShown = 2, nil
    before = #MOCK.printed
    SC:OnLevel(16)
    check(printed("Class tip 3 of 3", before), "old saves keep the tips they already showed")
    tips.tips = keep
end
prof().spellCoach = false
GetSpellInfo, GetSpellDescription, HasAction, GetActionInfo = realSpellInfo, nil, nil, nil

-- Mount savings goal -------------------------------------------------------------------------------------
local MG = ns.MountGoal
local level0, class0, money0 = MOCK.player.level, MOCK.player.class, MOCK.money
if ns.Riding then
    local R = ns.Riding
    check(R.source and R.level and R.training > 0 and R.mount > 0, "mount prices name their source")
    MOCK.player.class = "WARRIOR"
    MOCK.player.level = R.level - 5
    MOCK.money = 10000
    check(MG:Line() == nil, "no savings goal while the setting is off")
    prof().mountGoal = true
    local l = MG:Line()
    check(l and string.find(l, "Mount at " .. R.level, 1, true) and string.find(l, "to go", 1, true), "savings goal line: " .. tostring(l))
    check(MG:Cost() == R.training + R.mount, "a warrior's first mount: riding plus a mount")
    MOCK.money = R.training + R.mount
    check(string.find(MG:Line(), "enough!", 1, true), "...says when you have enough")
    MOCK.player.level = R.level - 11
    check(MG:Line() == nil, "not shown more than 10 levels before the riding level")
    MOCK.player.class = "PALADIN"
    MOCK.player.level = R.level
    l = MG:Line(true)
    check(l and string.find(l, "class trainer", 1, true), "paladins learn their mount from the class trainer: " .. tostring(l))
    prof().mountGoal = false
else
    before = #MOCK.printed
    MG:Print()
    check(MG:Line(true) == nil and printed("No mount prices", before), "no mount prices on this target: nothing is shown")
end
MOCK.player.level, MOCK.player.class, MOCK.money = level0, class0, money0

-- Session recap --------------------------------------------------------------------------------------
local SR = ns.SessionRecap
ns.char.session = { start = 1000, last = 1600, level0 = 3, level = 5, xp = 900, quests = 7, deaths = 1, zones = { "Durotar" }, money0 = 0, money = 0 }
SR:Start()
check(ns.char.lastSession and ns.char.lastSession.quests == 7 and ns.char.session.quests == 0, "a new session starts at login; the old one is kept")
local txt = SR.Text(ns.char.lastSession)
check(string.find(txt, "10 min", 1, true) and string.find(txt, "level 3 to 5", 1, true) and string.find(txt, "7 quests turned in", 1, true)
    and string.find(txt, "Durotar", 1, true) and string.find(txt, "1 death", 1, true), "recap text: " .. txt)
before = #MOCK.printed
SR:PrintLast()
check(#MOCK.printed == before, "no recap at login while the setting is off")
prof().sessionRecap = true
SR:PrintLast()
check(printed("Last session:", before), "the last session's recap at login")
MOCK.fire("QUEST_TURNED_IN", 1, 0, 0)
check(ns.char.session.quests == 1, "turned-in quests are counted")
prof().sessionRecap = false

-- Profession tips -------------------------------------------------------------------------------------
local PF = ns.ProfessionTips
check(PF:Find("min")[1] == "Mining" and PF:Find("first aid")[1] == "First Aid" and PF:Find("zzz") == nil, "professions are found by name or prefix")
ns.char.professionTipsShown = nil
MOCK.player.level = 5
before = #MOCK.printed
PF:Check()
check(#MOCK.printed == before, "no profession tips while the setting is off")
prof().professionTips = true
PF:Check()
check(printed("Professions:", before) and ns.char.professionTipsShown, "profession advice once, from level 5")
n = #MOCK.printed
PF:Check()
check(#MOCK.printed == n, "...and only once")
local found = 0
for _, e in ipairs(PF.LIST) do if PF:Trainer(e) then found = found + 1 end end
check(found > 0, "profession trainers are found in the NPC data (" .. found .. " of " .. #PF.LIST .. ")")
prof().professionTips = false
MOCK.player.level = level0

-- Play together ----------------------------------------------------------------------------------------
local PT = ns.PlayTogether
local sent = {}
local oldChat, oldGroup, oldNum = C_ChatInfo, IsInGroup, GetNumGroupMembers
C_ChatInfo = { SendAddonMessage = function(p, m, ch) sent[#sent + 1] = ch .. ":" .. m end, RegisterAddonMessagePrefix = function() end }
IsInGroup = function() return true end
GetNumGroupMembers = function() return 2 end
MOCK.units.party1 = { name = "Buddy", guid = "Player-2" }
PT:Send(true)
check(#sent == 0, "nothing is sent while play-together is off")
prof().groupFeatures, prof().playTogether = true, true
PT:Send(true)
check(sent[1] and string.find(sent[1], "PARTY:P:" .. E.guide.id .. "|" .. E.current .. "|", 1, true), "our guide and step go to the party: " .. tostring(sent[1]))
ns.Group:OnAddonMessage(ns.Group.PREFIX, "P:" .. E.guide.id .. "|" .. E.current .. "|accept Test", "PARTY", "Buddy-Realm")
local lines = PT:Lines()
check(#lines == 1 and string.find(lines[1].text, "Buddy is on this step too", 1, true), "a party member on the same step")
if E.current > 1 then
    ns.Group:OnAddonMessage(ns.Group.PREFIX, "P:" .. E.guide.id .. "|" .. (E.current - 1) .. "|accept Test", "PARTY", "Buddy-Realm")
    lines = PT:Lines()
    check(string.find(lines[1].text, "1 step behind", 1, true), "a party member behind: " .. lines[1].text)
end
ns.Group:OnAddonMessage(ns.Group.PREFIX, "P:Other_Guide|3|accept Test", "PARTY", "Buddy-Realm")
check(string.find(PT:Lines()[1].text, "another guide", 1, true), "a party member on another guide")
MOCK.units.party1 = nil
check(#PT:Lines() == 0, "members who left the party are not shown")
before = #MOCK.printed
check(PT:Follow(nil, false) == false and printed("No party leader", before), "/qw follow without a leader heard from says so")
C_ChatInfo, IsInGroup, GetNumGroupMembers = oldChat, oldGroup, oldNum
PT.members = {}
prof().groupFeatures, prof().playTogether = saved.groupFeatures, false
prof().tipWindows = tipWindows0

-- Simple settings view --------------------------------------------------------------------------------
CF:Show("advanced")
local function visible() local s = {} for _, id in ipairs(CF:VisibleTabs()) do s[id] = true end return s end
check(visible().advanced and visible().profiles, "all tabs without the simple view")
local function widgets(id) CF:Show(id) return #CF.built[id].widgets end
local full = widgets("general")
prof().simpleSettings = true
CF:Rebuild()
check(not visible().advanced and not visible().profiles and visible().general and visible().help, "simple view: Advanced and Profiles tabs are hidden")
check(not CF.tabs.advanced:IsShown() and CF.tabs.general:IsShown(), "...and their tab buttons too")
check(CF.current == "general", "an open hidden tab switches to General")
check(widgets("general") < full, "simple view leaves out rarely used options on General")
prof().simpleSettings = false
CF:Rebuild()
check(widgets("general") == full and visible().advanced, "turning it off shows everything again")
local function hasKey(page, key)
    for _, it in ipairs(ns.ConfigPages[page].items(CF)) do if it.key == key and not it.hidden then return true end end
end
check(hasKey("general", "simpleSettings"), "Simple settings view is on General")
check(hasKey("comms", "playTogether") and hasKey("comms", "playFollowLeader"), "Play Together is on Communications")
for _, k in ipairs({ "newPlayerTips", "spellCoach", "professionTips", "sessionRecap" }) do check(hasKey("tips", k), k .. " is on Tips") end
check(hasKey("tips", "mountGoal") == (ns.Riding ~= nil or nil), "Mount savings goal is on Tips where there are mount prices")
CF.frame:Hide()

-- Setup wizard: new-player path ----------------------------------------------------------------------
local guide0, setup0, routing0, newPlayer0 = ns.char.activeGuide, ns.char.setup, ns.char.routing, ns.char.newPlayer
ns.char.newPlayer, ns.char.routing = nil, nil -- a first setup
WL:Open(true)
local d = WL.draft
check(d.step == 1 and WL:StepId() == "welcome", "the wizard opens on the new-to-WoW question")
for _, k in ipairs(KEYS) do if k ~= "playFollowLeader" then check(d.helpers[k] == false, "helper " .. k .. " starts off") end end
check(not WL:Go(1), "Next needs an answer")
S:SetNewPlayer(d, true)
local ids = {}
for _, st in ipairs(S:Steps(d)) do ids[#ids + 1] = st.id end
check(table.concat(ids, ",") == "welcome,route,build,dungeons,helpers,review", "new players: " .. table.concat(ids, ","))
check(d.mode == "speed" and S:GuideValid(d.guide), "new players follow the leveling guides")
local supported = 0
for _, row in ipairs(S:Dungeons("speed")) do if row.supported then supported = supported + 1 end end
if supported > 0 then
    check(d.dungeons == "selected" and #S:SelectedDungeons(d) == supported, "a first setup picks every recommended dungeon (" .. supported .. ")")
else
    check(d.dungeons == "questing", "no recommended dungeons: questing only")
end
WL:Render()
check(WL.dots[6]:IsShown() and not WL.dots[7]:IsShown(), "the page labels follow the shorter path")
check(WL:Go(1) and WL:Go(1) and WL:StepId() == "build", "on to the talents page")
check(not WL:Go(1) and WL:StepId() == "build", "Next needs the group-role answer")
-- Role question: the suggested plan fits the role, or is the class default when the class has no such plan.
local default
for _, p in ipairs(S:Plans()) do if p.default then default = p end end
for _, r in ipairs(S.ROLES) do
    S:SetRole(d, r.id)
    local p, fits = S:SuggestedPlan(d)
    check(d.plan == p.id, "role " .. r.id .. ": the suggested plan is chosen (" .. p.id .. ")")
    if r.match and fits then check(string.find(p.role, r.match, 1, true), "role " .. r.id .. ": " .. p.id .. " is a " .. p.role .. " plan")
    else check(p.id == default.id, "role " .. r.id .. ": the class default plan") end
    WL:Render()
end
S:SetRole(d, "unsure")
check(d.plan == default.id, "I don't know yet: the usual leveling plan")
check(d.gear == S:GearForPlan(d.plan, d.role), "the gear profile follows the suggested plan")
check(d.autoEquip == false, "automatic upgrades start off")

-- Gear profile for a plan: a spec profile of the plan's tree whenever the class has one (every class here).
local class1 = MOCK.player.class
for class, specs in pairs(ns.TalentProfileBuilds.specs) do
    MOCK.player.class = class
    for spec, e in pairs(specs) do
        local have, tank, other = false, false, false
        for _, p in ipairs(ns.Gear:ProfilesForClass(class)) do
            if S.SameTree(p.spec, spec) then
                have = true
                if p.role == "Tank" then tank = true else other = true end
            end
        end
        local id = S:GearForPlan(e.plan)
        local p = id and ns.Gear:ProfileById(id)
        check((p ~= nil) == have, class .. " " .. spec .. ": a gear profile exactly when the tree has one (" .. tostring(id) .. ")")
        if p then
            check(S.SameTree(p.spec, spec) and p.class == class, class .. " " .. spec .. ": " .. p.id .. " is for that tree")
            check(p.role ~= "Tank" or not other, class .. " " .. spec .. ": no tank profile unless asked")
            local tp = ns.Gear:ProfileById(S:GearForPlan(e.plan, "tank"))
            if tank then check(tp.role == "Tank", class .. " " .. spec .. ": the tank role gets the tank profile") end
        end
    end
end
MOCK.player.class = class1
check(S.SameTree("Feral", "Feral Combat") and S.SameTree("Arms", "Arms") and not S.SameTree("Fire", "Frost") and not S.SameTree("Fer", "Feral Combat"), "tree names match whole words")
for i = 4, 6 do check(WL:Go(1) and d.step == i, "Next to " .. S:Steps(d)[i].id) end
WL:Render()
WL:Go(-1)
check(WL:StepId() == "helpers", "back on the helpers page")
S:SetAllHelpers(d, true)
check(d.helpers.newPlayerTips and d.helpers.simpleSettings and (d.helpers.mountGoal == (ns.Riding ~= nil)), "Turn On All ticks every helper this game version offers")
local summary = table.concat(S:Summary(d), "\n")
check(string.find(summary, "New to World of Warcraft: yes", 1, true) and string.find(summary, "Helpers: explain steps", 1, true), "the review lists the answer and the helpers")
-- A failed route start puts the helpers back.
prof().groupFeatures, prof().playTogether = false, false
local load = E.Load
E.Load = function() return false end
d.guide = (function() for _, g in ipairs(S:Guides()) do if g.id ~= ns.char.activeGuide then return g.id end end end)() or d.guide
local ok = S:Finish(d)
E.Load = load
if not ok then check(prof().newPlayerTips == false and prof().groupFeatures == false and ns.char.newPlayer == nil, "a failed finish leaves the helpers as they were") end
d.guide = guide0 or d.guide
d.step = #S:Steps(d)
local wantGear = d.gear
if wantGear then d.autoEquip = true end
local finished, why = S:Finish(d)
check(finished, "Finish Setup succeeds on the new-player path: " .. tostring(why))
check(ns.char.gearProfile == (wantGear or nil), "the spec profile is saved for automatic upgrades (" .. tostring(wantGear) .. ")")
check(prof().autoEquip == (wantGear and true or false), "automatic upgrades follow the new player's answer")
check(ns.char.newPlayer == true and prof().newPlayerTips and prof().spellCoach and prof().playTogether and prof().sessionRecap, "the helpers are saved")
check(prof().groupFeatures == true, "play together turns on group settings")
WL:Open(true)
check(WL.draft.newPlayer == true and WL.draft.helpers.spellCoach == true, "running setup again starts from the saved answer and helpers")
S:SetNewPlayer(WL.draft, false)
check(#S:Steps(WL.draft) == 7, "answering No gives every page")
WL:Later()

-- Put everything back for later tests.
for k, v in pairs(saved) do prof()[k] = v end
ns.char.newPlayer, ns.char.setup, ns.char.routing = newPlayer0, setup0, routing0
ns.char.gearProfile = gearProfile0
if guide0 and E.guide and E.guide.id ~= guide0 then E:Load(guide0) end
CF:Rebuild()
