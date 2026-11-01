-- Questwarden - headless smoke tests for a target without guide data yet (Lua 5.1).
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
-- STAGE.toc / STAGE.data: the TOC to load and where the target's data sits (the packaged download keeps it
-- under Targets/<Target>/; a single-target stage has it at the root).
local targetChunk = assert(loadfile(root .. (STAGE.data or "") .. "Config/Target.lua"))
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
local toc = assert(io.open(root .. (STAGE.toc or (ADDON .. ".toc")), "r"))
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
    -- A fresh level-1 character has done nothing: steps ahead that wait for a level are not progress.
    local pDone, pTotal = ns.Engine:Counts()
    local ahead = 0
    for i, st in pairs(ns.Engine.status) do if st == "skipped" and i > (ns.Engine.current or 0) then ahead = ahead + 1 end end
    check(ahead > 0 and pDone <= 1 and pTotal > 50, "progress at level 1 with nothing done stays near 0 (" .. pDone .. "/" .. pTotal .. ", " .. ahead .. " later steps waiting for a level)")
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
    -- Spells whose client level is only in SpellLevels.SpellLevel (BaseLevel 0) are trainer spells too.
    local lvlOf = {}
    for _, r in ipairs(ns.TrainingData.classes.DRUID) do lvlOf[r[1]] = r[2] end
    for _, r in ipairs(ns.TrainingData.classes.ROGUE) do lvlOf[r[1]] = r[2] end
    check(lvlOf[29166] == 40, "Innervate is a level-40 druid trainer spell")
    check(lvlOf[8681] == 20 and lvlOf[2835] == 30, "rogue poison recipes are listed (Instant Poison 20, Deadly Poison 30)")
    -- Class advice (Classes/ClassAdvice.lua): every class has a summary, tips and trainer levels.
    local noAdvice = {}
    for _, cls in ipairs({ "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }) do
        local a = ns.ClassAdvice:For(cls)
        if not (a and type(a.summary) == "string" and #a.tips >= 5 and ns.ClassAdvice:IsTrainingLevel(cls, 20)) then noAdvice[#noAdvice + 1] = cls end
    end
    check(#noAdvice == 0, "every class has Classic leveling advice (missing: " .. table.concat(noAdvice, ",") .. ")")
    check(not ns.ClassAdvice:IsTrainingLevel("WARRIOR", 21), "trainer levels are the even levels")
    -- Escort safeguard list (Database/EscortQuests.lua): never accepted automatically.
    local nEsc = 0
    for _ in pairs(ns.EscortQuests) do nEsc = nEsc + 1 end
    check(nEsc >= 40 and ns.EscortQuests[155] and ns.EscortQuests[2078], "Classic escort list built (" .. nEsc .. " quests, incl. Defias Traitor and Gyromast)")
    check(ns.DB.GetEscortStatus(1560) == true, "Tooga's Quest is treated as an escort")
    -- Flight graph (Database/Flights.lua): client taxi nodes, each tied to its flight master.
    local nNodes, nNpc = 0, 0
    for _, n in pairs(ns.Flights.nodes) do nNodes = nNodes + 1; if n.npc then nNpc = nNpc + 1 end end
    check(nNodes >= 60 and nNpc >= nNodes - 3, "flight graph built (" .. nNodes .. " nodes, " .. nNpc .. " with a flight master)")
    local aub = ns.Flights.nodes[26]
    check(aub and aub.name == "Auberdine" and aub.faction == "A" and ns.DB.ZoneName(aub.zone) == "Darkshore", "Auberdine is an Alliance node in Darkshore")
    local toAub = false
    for _, l in ipairs(ns.Flights.links[27] or {}) do if l == 26 then toAub = true end end
    check(toAub, "Rut'theran Village flies to Auberdine")
    local flyStep
    for _, gid in ipairs({ "A_42_DustwallowMarsh", "H_36_Desolace" }) do
        local fg = ns.Guides:Get(gid)
        for _, st in ipairs(fg and fg.steps or {}) do if st[1] == "fly" and st.node then flyStep = flyStep or st end end
    end
    check(flyStep and ns.Flights.nodes[flyStep.node], "route fly steps carry their flight node")
    -- Completionist mode on Classic data: a new Tauren starts in Mulgore; later quests wait; no false completion.
    local CMs = ns.Completionist
    local cctx = { race = "Tauren", class = "WARRIOR", faction = "Horde", level = 1,
                   completed = function() return false end, inLog = function() return false end }
    local cseg = CMs:Plan(cctx, { 215, 45, 75 })
    check(cseg.kind == "quests" and cseg.zone == 215 and #cseg.accepted > 0, "Completionist: a new Tauren starts with Mulgore quests (Classic data)")
    local csum = CMs:Summary(cseg.inv)
    check(csum.completed == 0 and csum.deferred > 0 and csum.routable > 300, "Completionist: nothing counted done without completion data; later quests deferred (" .. csum.routable .. " routable)")
    -- Setup on Classic data (Core/Setup.lua): Classic defaults, Hardcore choice, Classic plans and dungeons.
    local S = ns.Setup
    local sd = S:Current()
    check(sd.dungeons == "questing" and sd.elite == false, "setup: Classic Era drafts start with questing only and no group quests")
    check(sd.plan == "warrior_arms_iv" and S:PlanValid("warrior_fury_iv") and not S:PlanValid("warrior_arms_70"), "setup: Classic warrior plans only")
    local cdq = CMs:DungeonQuestCounts("Human", "WARRIOR")
    check((cdq["The Deadmines"] or 0) > 0 and (cdq["Blackrock Depths"] or 0) > 0, "setup: Completionist finds quests per Classic dungeon")
    local sp, hasSup = S:SpeedDungeonQuests(), false
    for _, row in ipairs(S:Dungeons("speed")) do if row.supported then hasSup = true end end
    check(next(sp) ~= nil and hasSup, "setup: the Classic guides offer dungeons to select")
    -- Dungeon runs (Core/DungeonRun.lua): every dungeon the Classic guides send you to has an entrance arrow.
    local noEntrance = {}
    for _, gd in ipairs(ns.Guides.list) do
        for _, st in ipairs(gd.steps) do
            if st.dungeon and not ns.DungeonRun:HasEntrance(st.dungeon) then noEntrance[st.dungeon] = true end
        end
    end
    check(next(noEntrance) == nil and select(1, ns.DungeonRun:Entrance("The Deadmines")) == 40, "dungeon runs: every guide dungeon has an entrance (Deadmines in Westfall)")
    -- Item-drop objectives count as targets: "Wolves Across the Border" (33) needs Tough Wolf Meat from wolves.
    local wolfIds = ns.DB.ObjectiveNpcIds(33, 12) or {}
    check(wolfIds[299] and wolfIds[69], "the wolves that drop Tough Wolf Meat are targets of quest 33 (Young Wolf 299, Timber Wolf 69)")
    -- Class training from What's Training? (Classes/WhatsTrainingData.lua): Classic Era data only, licences packaged.
    local WTD = ns.WhatsTrainingData
    check(WTD and WTD.source and WTD.source.game == "Vanilla" and WTD.classes.MAGE[3561] and not WTD.classes.MAGE[32271],
        "What's Training: Classic Era loads the Vanilla data (Teleport: Stormwind yes, TBC's Teleport: Exodar no)")
    check(WTD.classes.WARRIOR[6546] and WTD.classes.WARRIOR[6546][2] == 600, "What's Training: Rend 2 base price 6 silver")
    local htEntry
    for _, e in ipairs(ns.Trainer:Entries("DRUID")) do if e.id == 25297 then htEntry = e end end
    check(htEntry and htEntry.source == "other", "What's Training: Healing Touch rank 11 (a book) is not sold by the class trainer")
    for _, f in ipairs({ "Classes/WhatsTraining_LICENSE.txt", "Database/Questie/UPSTREAM_LICENSE.md" }) do
        local fh = io.open("build/" .. STAGE.target .. "/" .. ns.name .. "/" .. f, "r") -- the release zip has them under Targets/<Target>/
        local text = fh and fh:read("*a") or ""
        if fh then fh:close() end
        check(#text > 100, "packaged licence file: " .. f)
    end
    local wcRow
    for _, row in ipairs(S:Dungeons("speed")) do if row.id == "Wailing Caverns" then wcRow = row end end
    check(wcRow and not wcRow.supported and string.find(wcRow.note, "Speed leveling guides", 1, true) and string.find(wcRow.note, "Completionist mode still routes", 1, true),
        "setup: a dungeon greyed out for Speed says Completionist still routes it (" .. tostring(wcRow and wcRow.note) .. ")")
    local hsd = S:Draft(true)
    hsd.hardcore, hsd.dungeons = true, "questing"
    local hcOk = S:Finish(hsd)
    check(hcOk and ns.char.hardcore == true and ns:IsHardcore(), "setup: the Hardcore route choice is saved for the character")
    ns.char.hardcore, ns.char.routing, ns.char.setup = false, nil, nil
    ns.Engine:Load("A_Human_Elwynn")
    -- Spirit healers (Database/Questie/SpiritHealers.lua): one per graveyard, shown as map pins on request.
    local nGy, nGyZones = 0, 0
    for _, pts in pairs(ns.QDB.spiritHealers) do nGyZones = nGyZones + 1; nGy = nGy + #pts end
    check(nGy >= 80 and nGyZones >= 40, "spirit healers bundled (" .. nGy .. " in " .. nGyZones .. " zones)")
    local p = ns.db.profile
    local realArea = ns.DB.AreaForUiMap
    ns.DB.AreaForUiMap = function() return 12 end -- Elwynn Forest
    p.tipsEnabled, p.trackMobsMap, p.trackTreasures, p.trackSpiritHealers = true, false, false, true
    local gyPins, onlyGy = ns.MapExtras:Entries(1), true
    for _, e in ipairs(gyPins) do if e.kind ~= "spirit" then onlyGy = false end end
    check(#gyPins >= 2 and onlyGy, "Track Spirit Healers pins Elwynn's graveyards only (" .. #gyPins .. ")")
    p.trackSpiritHealers = false
    check(#ns.MapExtras:Entries(1) == 0, "spirit healer pins are off by default")
    ns.DB.AreaForUiMap = realArea
    -- Dangerous mobs (questie.allDangerousMobs): every hostile rare is bundled, not only quest mobs.
    local N, nRare = ns.QDB.NPC, 0
    for _, r in pairs(ns.QDB.npcs) do
        if (r[N.RANK] == 2 or r[N.RANK] == 4) and not r[N.FRIENDLY] and r[N.SPAWNS] then nRare = nRare + 1 end
    end
    check(nRare >= 300 and ns.QDB.npcs[8301], "every hostile rare is bundled (" .. nRare .. ", incl. Clack the Reaver)")
    local firstMob
    for _, e in ipairs(ns.MapExtras:Index()[4] or {}) do if e.kind ~= "spirit" then firstMob = e break end end
    check(firstMob and firstMob.kind == "rare", "map pins list rares before elites (Blasted Lands)")
    -- A rare friendly to one faction only is a danger to the other (Watch Commander Zalaphil, Durotar).
    local function zalaphilPinned()
        ns.MapExtras.byZone = nil
        for _, e in ipairs(ns.MapExtras:Index()[14] or {}) do if e.id == 5809 then return true end end
        return false
    end
    local realFaction = MOCK.player.faction
    MOCK.player.faction = "Horde"
    local forHorde = zalaphilPinned() and ns.DB.HostileToPlayer("A")
    MOCK.player.faction = "Alliance"
    local forAlliance = zalaphilPinned() or ns.DB.HostileToPlayer("A")
    MOCK.player.faction = realFaction
    ns.MapExtras.byZone = nil
    check(ns.QDB.npcs[5809] and forHorde and not forAlliance, "a rare friendly to Alliance only is pinned for Horde, not Alliance")
    local hexx
    for _, e in ipairs(ns.MapExtras:Index()[47] or {}) do if e.id == 7995 then hexx = e end end
    check(hexx and hexx.patrols, "Vile Priestess Hexx is pinned and marked as patrolling")
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
    -- A Hardcore realm turns the Hardcore route on without the setting (C_GameRules.IsHardcoreActive).
    local realGR = C_GameRules
    C_GameRules = { IsHardcoreActive = function() return true end }
    check(ns:IsHardcore(), "a Hardcore realm turns the Hardcore route on")
    C_GameRules = { IsHardcoreActive = function() return false end }
    check(not ns:IsHardcore(), "a normal realm leaves it to the setting")
    C_GameRules = realGR
    ns.db.profile.showElite = false
    ns.Engine:Refresh()
end

-- Detection ---------------------------------------------------------------------------------------
local TC = ns.TargetCheck
-- WOW_PROJECT_CAMELOT exists only on the Forever client.
do
    local pid, cam = WOW_PROJECT_ID, WOW_PROJECT_CAMELOT
    WOW_PROJECT_ID, WOW_PROJECT_CAMELOT = 18, 18
    local onForever = TC:Evaluate()
    WOW_PROJECT_ID, WOW_PROJECT_CAMELOT = 2, nil
    check(TC.IsForeverClient() == false and (ns.Target.id == "Forever" or not onForever), "a non-Forever build refuses the Forever client (project id)")
    WOW_PROJECT_ID, WOW_PROJECT_CAMELOT = pid, cam
    TC:Evaluate()
end
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

-- Key bindings: each header is declared once (the client warns "Binding header ... loaded more than once").
do
    local f = io.open("build/" .. STAGE.target .. "/" .. ns.name .. "/Bindings.xml", "r")
    local xml = f and f:read("*a") or ""
    if f then f:close() end
    local headers, seen, dup = 0, {}, false
    for h in string.gmatch(xml, 'header="([^"]+)"') do
        headers = headers + 1
        if seen[h] then dup = true end
        seen[h] = true
    end
    local bindings = select(2, string.gsub(xml, "<Binding ", ""))
    check(headers >= 1 and not dup and bindings >= 2, "Bindings.xml declares each header once (" .. headers .. " header(s), " .. bindings .. " bindings)")
end

-- Commands and windows without data ----------------------------------------------------------------
for _, cmd in ipairs({ "help", "debug", "guide", "talents", "class", "gear", "orphans", "options" }) do
    local ok, err = pcall(SlashCmdList[ns.key], cmd)
    check(ok, "/" .. ns.slash .. " " .. cmd .. " runs without data: " .. tostring(err))
end
check(#ns.errors == 0, "no captured errors after commands: " .. table.concat(ns.errors, " | "))

print(string.format("[%s] %d passed, %d failed", STAGE.target, passes, failures))
os.exit(failures == 0 and 0 or 1)
