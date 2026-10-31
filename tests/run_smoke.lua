-- ClassicGuide - headless smoke tests for a target without guide data yet (Lua 5.1).
-- Run from the repository root:  tools/build.ps1 test -Target ClassicEra   (or -Target Forever)
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- SPDX-License-Identifier: GPL-3.0-only
--
-- tests/run_tests.lua needs real quest data (the TBC fixture). This suite checks what must hold for
-- every target from day one: the staged add-on boots with its own (possibly empty) data, nothing
-- errors, the target rules come from Config/Target.lua, client detection accepts the right client
-- and refuses guides on any other, and the commands and windows work without data.

dofile("tests/mock_wow.lua")

local STAGE = dofile("build/" .. assert(os.getenv("GUIDE_TARGET"), "set GUIDE_TARGET") .. "/stage.lua")
local ADDON, root = STAGE.name, STAGE.dir
local ns = {}
local failures, passes = 0, 0
local function check(cond, msg)
    if cond then passes = passes + 1 else failures = failures + 1; print("FAIL: " .. msg) end
end

-- The client this target is built for (interface and version from the staged Config/Target.lua).
local targetChunk = assert(loadfile(root .. "Config/Target.lua"))
local probe = {}
targetChunk(ADDON, probe)
local T = probe.Target
local function client(version, iface)
    GetBuildInfo = function() return version, "99999", "Nov 1 2026", iface end
end
client(T.versionPrefix .. "9", T.interface)

-- Load in TOC order --------------------------------------------------------------------------------
local function loadFile(path)
    local chunk, err = loadfile(path)
    if not chunk then error("load " .. path .. ": " .. tostring(err)) end
    chunk(ADDON, ns)
end
local function loadXml(path, dir)
    local f = assert(io.open(path, "r"))
    local text = f:read("*a")
    f:close()
    for file in string.gmatch(text, '<Script%s+file="([^"]+)"') do loadFile(dir .. file:gsub("\\", "/")) end
end
local toc = assert(io.open(root .. ADDON .. ".toc", "r"))
local tocText = toc:read("*a")
toc:close()
for line in string.gmatch(tocText, "[^\r\n]+") do
    if not line:match("^#") then
        local rel = line:gsub("\\", "/")
        if rel:match("%.xml$") then loadXml(root .. rel, root .. rel:match("^(.*/)")) else loadFile(root .. rel) end
    end
end

-- Manifest ----------------------------------------------------------------------------------------
check(tocText:find("## Interface: " .. T.interface, 1, true) ~= nil, "TOC interface matches Config/Target.lua")
check(tocText:find("## SavedVariables: " .. ADDON .. "DB", 1, true) ~= nil, "TOC declares the account SavedVariables")
check(not tocText:find("{{", 1, true), "no template placeholders left in the TOC")

-- Boot --------------------------------------------------------------------------------------------
local printed = {}
local realAdd = DEFAULT_CHAT_FRAME.AddMessage
DEFAULT_CHAT_FRAME.AddMessage = function(self, msg, ...) printed[#printed + 1] = tostring(msg); return realAdd(self, msg, ...) end
MOCK.fire("ADDON_LOADED", ADDON)
MOCK.fire("PLAYER_LOGIN")
MOCK.tick(0.5)

check(type(ns.db) == "table" and type(ns.char) == "table", "saved variables initialised")
check(_G[ns.svAccount] == ns.db.root or type(_G[ns.svAccount]) == "table", "account SavedVariables global is " .. ns.svAccount)
check(#ns.errors == 0, "no captured errors after boot: " .. table.concat(ns.errors, " | "))
check(ns.name == ADDON and ns.slash == STAGE.slash, "name and slash come from tools/addon.json")
check(SlashCmdList[ns.key] ~= nil, "slash command registered")
check(_G[ADDON] == ns, "public handle _G." .. ADDON)
check(ns.Target.id == STAGE.target, "Config/Target.lua is the " .. STAGE.target .. " target")
check(#ns.Guides.rejected == 0, "no rejected guides")
if #ns.Guides.list == 0 then check(ns.Selector:Recommend() == nil, "no guide recommended when there are none") end

-- Target rules ------------------------------------------------------------------------------------
check(ns.TalentPointsAt(ns.Target.maxLevel) == ns.Target.maxLevel - ns.Target.firstTalentLevel + 1, "talent points at the level cap")
check(ns.TalentPointsAt(ns.Target.firstTalentLevel - 1) == 0, "no talent points before the first talent level")
if STAGE.target == "ClassicEra" then
    check(ns.Target.maxLevel == 60 and ns.TalentPointsAt(60) == 51, "Classic Era: level 60, 51 talent points")
    check(ns.Target.questLogMax == 20, "Classic Era: quest log holds 20")
    check(#ns.Target.chapters == 1 and ns.Target.chapters[1] == "Azeroth", "Classic Era: Azeroth only")
end

-- Real data (Classic Era, Phase 2) --------------------------------------------------------------------
if STAGE.target == "ClassicEra" then
    check(ns.DB.GetQuestByID(783) and ns.DB.GetQuestByID(783).name == "A Threat Within", "Classic quest 783 resolves")
    check(ns.QDB.NPC_FLAGS.INNKEEPER == 128 and ns.QDB.NPC_FLAGS.FLIGHT_MASTER == 8, "vanilla NPC flag numbering from the Classic data")
    local combos, races = 0, 0
    for _, r in pairs(ns.RaceClass.races) do races = races + 1; combos = combos + #r.classes end
    check(races == 8 and combos == 40, "8 races, 40 race/class combinations (" .. races .. ", " .. combos .. ")")
    local trees, maxTier = 0, 0
    for _, cls in ipairs({ "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }) do
        trees = trees + #(ns.TalentTrees[cls] or {})
        for _, tab in ipairs(ns.TalentTrees[cls] or {}) do for _, t in ipairs(tab.talents) do if t.tier > maxTier then maxTier = t.tier end end end
    end
    check(trees == 27 and maxTier == 7, "27 talent trees, 7 tiers (" .. trees .. ", " .. maxTier .. ")")
    check(ns.Engine.guide and ns.Engine.guide.id == "A_Human_Elwynn", "a Human warrior gets the Elwynn start guide")
    local noPlan = {}
    for _, cls in ipairs({ "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }) do
        local ok = false
        for _, bld in ipairs(ns.Talents:BuildsFor(cls)) do if bld.kind == "leveling" then ok = true end end
        if not ok then noPlan[#noPlan + 1] = cls end
    end
    check(#noPlan == 0, "every class has a leveling talent plan (missing: " .. table.concat(noPlan, ",") .. ")")
    local ab = ns.Talents:ActiveBuild()
    check(ab and ab.id == "warrior_arms_iv", "a warrior's default plan is Icy Veins Arms (" .. tostring(ab and ab.id) .. ")")
    check(#ns.Talents.buildList == 28, "28 talent plans registered (" .. #ns.Talents.buildList .. ")")
    -- Group content is opt-in on Classic Era (Target.contentDefaults).
    check(ns.db.profile.showElite == false and ns.db.profile.showDungeonSteps == false, "Classic Era: elite and dungeon quests off by default")
    local function firstStep(pred)
        for _, gd in ipairs(ns.Guides.list) do
            for i, st in ipairs(gd.steps) do if pred(st) then return gd, i end end
        end
    end
    local dg, di = firstStep(function(st) return st.dungeon and st[1] == "accept" end)
    local eg, ei = firstStep(function(st) return st.elite and st[1] == "accept" end)
    check(dg ~= nil and eg ~= nil, "guides contain dungeon and elite steps")
    if dg and eg then
        ns.Engine:Load(dg.id)
        check(ns.Engine.status[di] == "na", "a dungeon step is left out while dungeon quests are off")
        ns.db.profile.showDungeonSteps = true
        ns.Engine:Refresh()
        check(ns.Engine.status[di] ~= "na", "it is back when Include Dungeon Quests is on")
        ns.db.profile.showDungeonSteps = false
        ns.Engine:Load(eg.id)
        check(ns.Engine.status[ei] == "na", "an elite step is left out while group quests are off")
        ns.db.profile.showElite = true
        ns.Engine:Refresh()
        check(ns.Engine.status[ei] ~= "na" or ns.Engine.status[ei] == nil, "it is back when Show Group Quests is on")
        ns.db.profile.showElite = false
        ns.Engine:Load("A_Human_Elwynn")
    end
    -- Gear profiles (docs/GEAR_RESEARCH_CLASSIC.md): priority-only, sourced, every class covered at 60.
    local KNOWN, at60, leveling, bad = {}, {}, {}, {}
    for _, k in pairs(ns.Gear.STAT_KEYS) do KNOWN[k] = true end
    for _, p in ipairs(ns.GearProfiles.list) do
        local ok = p.weights == nil and type(p.priority) == "table" and #p.priority > 0 and type(p.sources) == "table" and #p.sources > 0
        for _, k in ipairs(p.priority or {}) do ok = ok and KNOWN[k] == true end
        if not ok then bad[#bad + 1] = p.id end
        if p.levelMax == 60 then at60[p.class] = true end
        if p.context == "leveling" then leveling[p.class] = true end
    end
    check(#bad == 0, "gear profiles are priority-only, sourced, with known stats (bad: " .. table.concat(bad, ",") .. ")")
    local miss60, missLvl = {}, {}
    for _, cls in ipairs({ "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }) do
        if not at60[cls] then miss60[#miss60 + 1] = cls end
        if not leveling[cls] and cls ~= "HUNTER" and cls ~= "ROGUE" then missLvl[#missLvl + 1] = cls end
    end
    check(#miss60 == 0, "every class has a level-60 gear profile (missing: " .. table.concat(miss60, ",") .. ")")
    check(#missLvl == 0, "every class with a sourced leveling priority has a leveling profile (missing: " .. table.concat(missLvl, ",") .. ")")
    local wp = ns.Gear:SelectProfile({ class = "WARRIOR", level = 20 })
    check(wp and wp.id == "warrior_leveling_early", "a level-20 warrior gets the early leveling profile (" .. tostring(wp and wp.id) .. ")")
    -- Trainer notes point at real Classic trainer data (Classes/TrainingNotes.lua, TrainingData.lua).
    local byId, byName, missing = {}, {}, {}
    for cls, list in pairs(ns.TrainingData.classes) do
        byId[cls], byName[cls] = {}, {}
        for _, r in ipairs(list) do byId[cls][r[1]] = true; byName[cls][r[5]] = true end
    end
    for cls, q in pairs(ns.TrainingNotes.quest) do
        for sid in pairs(q) do if not (byId[cls] and byId[cls][sid]) then missing[#missing + 1] = cls .. " " .. sid end end
    end
    for _, key in ipairs({ "important", "optional" }) do
        for cls, list in pairs(ns.TrainingNotes[key]) do
            for _, n in ipairs(list) do if not (byName[cls] and byName[cls][n]) then missing[#missing + 1] = cls .. " " .. n end end
        end
    end
    check(#missing == 0, "every trainer-note spell exists in the Classic trainer data (missing: " .. table.concat(missing, ", ") .. ")")
    check(ns.TrainingNotes.quest.WARRIOR and ns.TrainingNotes.quest.WARRIOR[71] ~= nil, "Defensive Stance is a warrior quest spell")
    check(not byName.DRUID["Mangle"], "Mangle (not in Classic Era) is left out of the druid trainer data")
    -- Escort safeguard list (Database/EscortQuests.lua): never accepted automatically.
    local nEsc = 0
    for _ in pairs(ns.EscortQuests) do nEsc = nEsc + 1 end
    check(nEsc >= 40 and ns.EscortQuests[155] and ns.EscortQuests[2078], "Classic escort list built (" .. nEsc .. " quests, incl. Defias Traitor and Gyromast)")
    check(ns.DB.GetEscortStatus(1560) == true, "Tooga's Quest is treated as an escort")
    -- Hardcore flavor: Hogger (level 11 elite) is not on the Hardcore route.
    local g = ns.Guides:Get("A_Human_Elwynn")
    local hogger
    for i, st in ipairs(g.steps) do if st[1] == "accept" and st.hcSkip then hogger = i break end end
    check(hogger ~= nil, "the Elwynn guide marks a step [hc=skip]")
    ns.db.profile.showElite = true -- Hogger is elite: group quests on, so only the Hardcore flag decides
    ns.Engine:Refresh()
    check(ns.Engine.status[hogger] ~= "na", "Speed route keeps the Hogger pickup (group quests on)")
    ns.char.hardcore = true
    ns.Engine:Refresh()
    check(ns:IsHardcore() and ns.Engine.status[hogger] == "na", "Hardcore route leaves the Hogger pickup out")
    ns.char.hardcore = false
    ns.db.profile.showElite = false
    ns.Engine:Refresh()
end

-- Detection ---------------------------------------------------------------------------------------
local TC = ns.TargetCheck
if ns.Target.verified then
    check(TC.ok, "the target's own client is accepted")
    check(ns.Guides.refused == 0, "no guides refused on the right client")
else
    check(not TC.ok and TC.reason:find("not been verified", 1, true), "unverified target refuses guides with a clear reason")
    local said = false
    for _, m in ipairs(printed) do if m:find("not been verified", 1, true) then said = true end end
    check(said, "unverified target says so at login")
end
-- A different game version: TBC Anniversary client against this build.
client("2.5.6", 20506)
check(not TC:Evaluate() and TC.reason:find("2.5.6", 1, true) and TC.reason:find(ns.Target.name, 1, true), "a TBC client is refused, naming both versions")
local before = ns.Guides.refused
ns.Guides:Register({ id = "SMOKE_Test", faction = "Both", steps = { { "note", text = "x" } } })
check(ns.Guides.refused == before + 1 and not ns.Guides:Get("SMOKE_Test"), "guides are refused on the wrong client")
-- Same family, wrong minor version (version prefix check).
client("1.14.4", 11404)
check(not TC:Evaluate(), "an older Classic client outside the interface range is refused")
client(T.versionPrefix .. "9", 0)
TC:Evaluate()
check(TC.warning ~= nil and TC.ok == (ns.Target.verified ~= false), "unknown interface (0) only warns (an unverified target still refuses)")
client(T.versionPrefix .. "9", T.interface)
TC:Evaluate()

-- Text placeholders -------------------------------------------------------------------------------
if TC.ok then
    ns.Guides:Register({ id = "SMOKE_Text", faction = "Both", steps = { { "note", text = "{name} skips it; /{slash} guide" } } })
    local g = ns.Guides:Get("SMOKE_Text")
    check(g and g.steps[1].text == ns.name .. " skips it; /" .. ns.slash .. " guide", "{name} and {slash} expand in guide text")
end

-- Commands and windows without data ----------------------------------------------------------------
for _, cmd in ipairs({ "help", "debug", "guide", "talents", "class", "gear", "orphans", "options" }) do
    local ok, err = pcall(SlashCmdList[ns.key], cmd)
    check(ok, "/" .. ns.slash .. " " .. cmd .. " runs without data: " .. tostring(err))
end
check(#ns.errors == 0, "no captured errors after commands: " .. table.concat(ns.errors, " | "))

print(string.format("[%s] %d passed, %d failed", STAGE.target, passes, failures))
os.exit(failures == 0 and 0 or 1)
