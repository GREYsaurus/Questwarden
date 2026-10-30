-- ClassicGuide - saved variables, defaults and migrations
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- This program is free software: you can redistribute it and/or modify it under the terms of the
-- GNU General Public License as published by the Free Software Foundation, version 3.
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
-- even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details. The complete license text is in LICENSE.
--
-- ClassicGuideDB      (account-wide): settings profiles, protection lists, frame positions
--   .profiles[name]       one table per profile (the settings below)
--   .profileKeys[char]    "Name - Realm" -> profile name used by that character
--   .defaultProfile       profile new characters start with
-- ClassicGuideCharDB  (per character): active guide, per-guide progress, simulated talents
-- Both are validated on load; anything malformed is reset field-by-field, never wholesale.
-- ns.db is a view of ClassicGuideDB whose `profile` field is the active profile; every other field
-- reads and writes ClassicGuideDB itself, so the profile table is never saved twice.

local _, ns = ...

local SCHEMA = 1

local profileDefaults = {
        debug = false,
        autoAdvance = true,       -- move to the next step when a reliable completion signal arrives
        autoSelectGuide = true,   -- pick a guide automatically on first login
        showArrow = true,
        showMapPins = true,
        useTomTom = true,
        stepsShown = 4,           -- current step + upcoming
        scale = 1,
        locked = false,
        hideCompletedOptional = false,
        showDungeonSteps = true,  -- Include Dungeon Quests: steps tagged [dungeon=...] (docs/GUIDE_FORMAT.md)
        showElite = true,
        speedRoute = false,       -- maximum-speed route: hide [optional] side quests (documented default: off)
        talentHints = true,       -- remind when talent points are unspent
        showTalentSuggestions = true, -- markers, panel and tooltip lines in the default talent window (docs/TALENTS.md)
        -- Automation (docs/AUTOMATION.md). Quest automation only ever touches quests that have an
        -- open step in the active guide; escort quests and reward choices are always manual.
        autoAccept = true,          -- accept guide quests when their offer panel opens
        autoAcceptOptional = false, -- ...including steps marked [optional]
        autoAcceptGroup = false,    -- ...including [elite]/[group]/[dungeon] steps
        autoTurnIn = true,          -- turn in guide quests that need no reward choice
        turnInUnrelated = false,    -- also turn in completed quests that are not in the guide
        questNotify = true,         -- chat messages for accepted / turned-in / manual quests
        autoSellJunk = false,       -- OFF by default: sell grey (Poor) items when a vendor opens
        sellNotify = true,          -- chat summary of junk sales
        sellNotifyItems = false,    -- one chat line per item sold
        -- Raid markers (docs/RAID_MARKERS.md)
        markEnabled = true,         -- /cg mark, the marker bar and guide marking
        autoMark = true,            -- mark NPCs the current guide step names with [mark=...]
        autoMarkObjectives = true,  -- also mark kill objectives / item droppers of the current steps
        markReplace = false,        -- automatic marking may replace an existing icon
        markClearOnAdvance = true,  -- remove our automatic icons when the step changes
        markNotify = true,          -- chat messages for marking results
        defaultMarker = 8,          -- 1 star .. 8 skull
        showMarkerBar = false,
        showMinimapButton = true,   -- minimap button (left-click: settings, right-click: guide window)
        -- Gear scoring (docs/GEAR_RESEARCH.md); read-only, never equips or chooses anything
        gearEnabled = true,
        gearTooltip = true,         -- score lines on item tooltips
        gearQuestRewards = true,    -- rank reward choices in chat
        gearShowPercent = true,     -- relative score change (%), only when both scores are valid
        gearShowConfidence = true,
        -- Automatic upgrades (Gear/AutoEquip.lua, docs/AUTO_EQUIP.md). Opt-in; never equips unbound BoE items.
        autoEquip = false,          -- equip upgrades for the chosen spec profile
        autoEquipEmpty = true,      -- fill empty gear slots with any usable non-BoE item
        autoEquipMinPct = 0,        -- minimum estimated upgrade (%) for occupied slots; must also be > 0
        equipNotify = true,         -- on-screen message after a confirmed equip
        equipChat = false,          -- copy of that message in chat
        boeMarkers = true,          -- marker on unequipped Bind-on-Equip upgrades in the bags
        -- Features from the settings window (docs/SETTINGS.md)
        activeItems = true,         -- active item window (usable quest items)
        activeItemScale = 1,
        vendorTreasures = true,     -- list/mark merchant items that are upgrades for your spec
        flightTimers = true,        -- flight timer bar (learned per route)
        groupFeatures = false,      -- master switch for the Grouping features
        junkIndicator = false,      -- coin icon on junk items in the bags
        talentPlan = true,          -- list the next picks of your build on level-up
        talentPlanCount = 5,
        dungeonOff = {},            -- [dungeon name] = true: that dungeon's quests are left out
        activeTargets = true,       -- click-to-target window for the current step's NPCs
        atEnemy = true, atFriendly = true, atLeader = false, atHideBg = false, atScale = 1,
        trackerEnabled = true,      -- leveling tracker
        trackerWithCharacter = false,
        splitsEnabled = false, splitsCompare = false, splitsTotal = true, splitsHideBg = false,
        splitsHistory = 10, splitsFont = 11, splitsAlpha = 0.9,
        versionCheck = true,        -- tell me when a group or guild member has a newer ClassicGuide
        announceComplete = false, announceCollect = false, announceFlight = false,
        announceSkipQuestie = false, announceAlways = false, autoShareQuests = false,
        trackMobsMap = false, trackTreasures = false,
        lowQuality = false,         -- slower arrow updates, fewer map pins
        preloadData = false,        -- request item data for the guide and bags at login
        auctioneer = true,          -- Upgrades tab in the auction house (UI/Auctioneer.lua); scans only on request
        -- Settings window (UI/Config.lua); features in Core/Assist.lua
        showAllFrames = true,       -- master switch for the guide window and arrow
        hideWindow = false,
        autohideRaid = false,       -- hide the guide window and arrow while in a raid group
        worldMapButton = true,      -- ClassicGuide button on the world map
        autoReward = false,         -- choose a quest reward when gear scoring finds a clear winner
        trainerAuto = false,        -- learn affordable spells at your class trainer
        trainerSuggestions = "important", -- Class Trainer Suggestions: "off", "important", "all" (docs/TRAINER.md)
        flightAuto = true,          -- fly to the current fly step's destination when the taxi map opens
        corpseNav = true,           -- arrow to your corpse while you are a ghost (Core/Corpse.lua)
        roamRoutes = true,          -- roaming hunting-area waypoints on kill steps with a verified route (Core/Roam.lua)
        bindAuto = true,            -- confirm the hearthstone bind on the guide's bind step
        skipGossip = true,          -- pick the only gossip option when an NPC offers nothing else
        inventoryManager = true,    -- master switch for junk selling, junk list and junk deletion
        junkModifierToggle = false, -- mark/unmark items as junk with modifier + right-click in bags
        junkModifier = "CTRL",
        discardJunkFull = false,    -- bags full: delete the cheapest junk item on the next click or key press
        skipOverleveled = true,     -- skip accept steps of quests that are grey for you
        disableStepSkips = false,   -- never skip steps automatically (debug)
        maxNameplateDistance = false, -- raise the nameplate CVar to its maximum (41 yards)
        markFriendly = true,        -- also mark the quest giver/finisher of the current step
        markInGroup = true,         -- allow automatic marking while in a group
        targetMacro = true,         -- keep a "ClassicGuide" macro targeting the current step's NPCs
        targetNotify = true,        -- chat note when a current-step mob or NPC first comes into view
        announceLevelEmote = false, announceLevelParty = false, announceLevelGuild = false,
        tipsEnabled = true,
        drownWarn = true, drownSound = true, drownFlash = true, drownThreshold = 20,
        lowHealthWarn = true, lowHealthThreshold = 20, lowHealthFlash = false, lowHealthAnim = true,
        trackRares = false,         -- chat alert when a rare mob's nameplate appears
        skipKilledRares = false,    -- ...but not for rares this character already killed
        colorFriendly = { r = 0.4, g = 0.8, b = 1 },  -- NPC names in step text
        colorQuest = { r = 1, g = 0.82, b = 0 },      -- quest names
        colorWarning = { r = 1, g = 0.47, b = 0.27 }, -- warnings
        guideFontSize = 12,
        showStepList = true,        -- show upcoming steps under the current one
        arrowScale = 1,
        arrowUpdateMs = 50,
        checkConflicts = true,      -- warn about other guide add-ons that act on the same NPCs
}

local accountDefaults = {
    schema = SCHEMA,
    profiles = {},
    profileKeys = {},
    defaultProfile = "Default",
    junkList = {},          -- [itemID] = true: items the player marked as junk
    trainCosts = {},        -- [spellID] = { c = copper, t = time }: class trainer prices last seen (Classes/Trainer.lua)
    protectedItems = {},    -- [itemID] = true: never sold automatically
    protectedClasses = {},  -- [itemClassID] = true/false: overrides Vendor.CLASSES defaults
    escortExtra = {},       -- [questID] = true: extra quests that must never be auto-accepted
    migrations = {},        -- [name] = true: one-time setting changes already applied
    minimap = { angle = 220 }, -- minimap button position: degrees around the minimap
    frames = {
        main = { point = "RIGHT", x = -60, y = 120, w = 320, h = 230, minimized = false, shown = true },
        browser = { point = "CENTER", x = 0, y = 0 },
        talents = { point = "CENTER", x = 0, y = 0 },
        arrow = { point = "TOP", x = 0, y = -120 },
        orphans = { point = "CENTER", x = 0, y = 0 },
        markerBar = { point = "TOP", x = 0, y = -200 },
    },
}

local charDefaults = {
    schema = SCHEMA,
    activeGuide = nil,
    progress = {},      -- [guideId] = { step = n, done = { [stepIndex] = true }, skipped = { [stepIndex] = true } }
    history = {},       -- recently used guide ids (most recent first)
    talentBuild = nil,  -- chosen build id for this character
    simTalents = {},    -- [class] = { [talentId] = rank } simulated allocation in the calculator
    junkStats = { items = 0, copper = 0 }, -- confirmed automatic junk sales (all time)
    gearProfile = nil,  -- chosen gear profile id (Gear/Profiles.lua); nil = automatic
    gearExclude = { items = {}, slots = {} }, -- automatic upgrades never touch these items / inventory slots
    killedRares = {},   -- [npcID] = true: rares this character killed (skipKilledRares)
    hardcore = false,   -- this character plays Hardcore: follow the Hardcore route flavor (ns:IsHardcore)
}
ns.PROFILE_DEFAULTS = profileDefaults

-- "Name - Realm" for the current character.
function ns.CharKey()
    local name = UnitName and UnitName("player") or "Unknown"
    local realm = GetRealmName and GetRealmName() or "Realm"
    return tostring(name) .. " - " .. tostring(realm)
end

-- Fills a profile table with defaults and repairs invalid values.
function ns.FixProfile(p)
    ns.Merge(p, profileDefaults)
    local dm = p.defaultMarker
    if type(dm) ~= "number" or dm < 1 or dm > 8 then p.defaultMarker = 8 end
    if p.junkModifier ~= "CTRL" and p.junkModifier ~= "ALT" and p.junkModifier ~= "SHIFT" then p.junkModifier = "CTRL" end
    if p.trainerSuggestions ~= "off" and p.trainerSuggestions ~= "important" and p.trainerSuggestions ~= "all" then p.trainerSuggestions = "important" end
    for _, k in ipairs({ "colorFriendly", "colorQuest", "colorWarning" }) do
        local c = p[k]
        if type(c) ~= "table" or type(c.r) ~= "number" or type(c.g) ~= "number" or type(c.b) ~= "number" then
            local d = profileDefaults[k]
            p[k] = { r = d.r, g = d.g, b = d.b }
        end
    end
    return p
end

local function sanitizeProgress(p)
    if type(p) ~= "table" then return {} end
    for guideId, rec in pairs(p) do
        if type(guideId) ~= "string" or type(rec) ~= "table" then
            p[guideId] = nil
        else
            if type(rec.step) ~= "number" or rec.step < 1 then rec.step = 1 end
            if type(rec.done) ~= "table" then rec.done = {} end
            if type(rec.skipped) ~= "table" then rec.skipped = {} end
        end
    end
    return p
end

function ns:InitSavedVariables()
    local fresh = type(_G[ns.svAccount]) ~= "table" or next(_G[ns.svAccount]) == nil
    if type(_G[ns.svAccount]) ~= "table" then _G[ns.svAccount] = {} end
    if type(_G[ns.svChar]) ~= "table" then _G[ns.svChar] = {} end
    -- Before 0.5.0 there was a single ClassicGuideDB.profile; it becomes the "Default" profile.
    local legacy = type(_G[ns.svAccount].profile) == "table" and _G[ns.svAccount].profile or nil
    _G[ns.svAccount].profile = nil
    ns.Merge(_G[ns.svAccount], accountDefaults)
    ns.Merge(_G[ns.svChar], charDefaults)
    for _, key in ipairs({ "profiles", "profileKeys", "junkList", "trainCosts" }) do
        if type(_G[ns.svAccount][key]) ~= "table" then _G[ns.svAccount][key] = {} end
    end
    local profiles = _G[ns.svAccount].profiles
    for name, p in pairs(profiles) do
        if type(name) ~= "string" or type(p) ~= "table" then profiles[name] = nil end
    end
    if legacy and not profiles.Default then profiles.Default = legacy end
    if type(_G[ns.svAccount].defaultProfile) ~= "string" then _G[ns.svAccount].defaultProfile = "Default" end
    if type(_G[ns.svChar].killedRares) ~= "table" then _G[ns.svChar].killedRares = {} end
    _G[ns.svChar].progress = sanitizeProgress(_G[ns.svChar].progress)
    if type(_G[ns.svChar].history) ~= "table" then _G[ns.svChar].history = {} end
    if type(_G[ns.svChar].simTalents) ~= "table" then _G[ns.svChar].simTalents = {} end
    for _, key in ipairs({ "protectedItems", "protectedClasses", "escortExtra", "migrations" }) do
        if type(_G[ns.svAccount][key]) ~= "table" then _G[ns.svAccount][key] = {} end
    end
    -- After 0.4.0: objective marking became the default (before, only 5 guide steps marked anything).
    -- Saved settings from earlier versions still hold the old default, so turn it on once.
    local mig = _G[ns.svAccount].migrations
    if not mig.objectiveMarking then
        mig.objectiveMarking = true
        local flipped = false
        for _, p in pairs(profiles) do
            if not fresh and p.autoMarkObjectives == false then p.autoMarkObjectives = true flipped = true end
        end
        if flipped then
            ns.migrationNote = "raid markers now also mark the mobs of your current kill steps. "
                .. "Turn this off with /" .. ns.slash .. " set autoMarkObjectives off."
        end
    end
    -- Active profile for this character.
    local key = ns.CharKey()
    local active = _G[ns.svAccount].profileKeys[key]
    if type(active) ~= "string" or type(profiles[active]) ~= "table" then
        active = _G[ns.svAccount].defaultProfile
        if type(profiles[active]) ~= "table" and active ~= "Default" and type(profiles.Default) == "table" then active = "Default" end
        _G[ns.svAccount].profileKeys[key] = active
    end
    profiles[active] = profiles[active] or {}
    for _, p in pairs(profiles) do ns.FixProfile(p) end
    local mm = _G[ns.svAccount].minimap
    if type(mm) ~= "table" then _G[ns.svAccount].minimap = { angle = 220 } mm = _G[ns.svAccount].minimap end
    local ang = tonumber(mm.angle)
    if not ang or ang ~= ang or ang == math.huge or ang == -math.huge then mm.angle = 220 else mm.angle = ang % 360 end
    local js = _G[ns.svChar].junkStats
    if type(js) ~= "table" or type(js.items) ~= "number" or type(js.copper) ~= "number" then
        _G[ns.svChar].junkStats = { items = 0, copper = 0 }
    end
    if _G[ns.svChar].gearProfile ~= nil and type(_G[ns.svChar].gearProfile) ~= "string" then
        _G[ns.svChar].gearProfile = nil
    end
    for _, p in pairs(_G[ns.svAccount].profiles) do
        if type(p) == "table" and p.dungeonOff ~= nil and type(p.dungeonOff) ~= "table" then p.dungeonOff = {} end
    end
    if type(_G[ns.svChar].levelLog) ~= "table" then _G[ns.svChar].levelLog = {} end
    if _G[ns.svChar].setupDraft ~= nil and type(_G[ns.svChar].setupDraft) ~= "table" then _G[ns.svChar].setupDraft = nil end
    if _G[ns.svChar].trainerDeferLevel ~= nil and type(_G[ns.svChar].trainerDeferLevel) ~= "number" then _G[ns.svChar].trainerDeferLevel = nil end
    if _G[ns.svChar].petDeferLevel ~= nil and type(_G[ns.svChar].petDeferLevel) ~= "number" then _G[ns.svChar].petDeferLevel = nil end
    if _G[ns.svChar].petSkills ~= nil and type(_G[ns.svChar].petSkills) ~= "table" then _G[ns.svChar].petSkills = nil end
    if type(_G[ns.svAccount].flightTimes) ~= "table" then _G[ns.svAccount].flightTimes = {} end
    local gx = _G[ns.svChar].gearExclude
    if type(gx) ~= "table" then gx = {} _G[ns.svChar].gearExclude = gx end
    if type(gx.items) ~= "table" then gx.items = {} end
    if type(gx.slots) ~= "table" then gx.slots = {} end
    if _G[ns.svChar].activeGuide ~= nil and type(_G[ns.svChar].activeGuide) ~= "string" then
        _G[ns.svChar].activeGuide = nil
    end
    -- Future migrations: if ClassicGuideDB.schema < N then ... end
    _G[ns.svAccount].schema = SCHEMA
    _G[ns.svChar].schema = SCHEMA
    ns:SetActiveProfile(active)
    ns.char = _G[ns.svChar]
end

-- Points ns.db at ClassicGuideDB with `profile` = the named profile (which must exist).
function ns:SetActiveProfile(name)
    ns.db = setmetatable({ profile = _G[ns.svAccount].profiles[name], profileName = name }, {
        __index = _G[ns.svAccount],
        __newindex = _G[ns.svAccount],
    })
end

-- Saved progress is stored by step index. When a guide's steps were reordered (Guides/Layouts.lua),
-- progress saved with the previous order is moved to the new indices once, so done and skipped
-- steps stay attached to the same steps. Unknown older layouts are left as they are (quest steps
-- re-check themselves against your quest log anyway).
local function remap(set, map)
    if type(set) ~= "table" then return {} end
    local out = {}
    for i, v in pairs(set) do
        if type(i) == "number" then out[map[i] or i] = v end
    end
    return out
end

function ns:ApplyLayout(guideId, p)
    local L = ns.GuideLayouts and ns.GuideLayouts[guideId]
    if not L or p.layout == L.layout then return p end
    -- Walk every layout change since the one the progress was saved with: maps[v] moves layout
    -- v-1 to v (`map` alone is the older form, for the last step only).
    for v = (p.layout or 1) + 1, L.layout do
        local m = (L.maps and L.maps[v]) or (v == L.layout and L.map)
        if m then
            p.done, p.skipped = remap(p.done, m), remap(p.skipped, m)
            if p.levelSkip then p.levelSkip = remap(p.levelSkip, m) end
            if type(p.step) == "number" then p.step = m[p.step] or p.step end
        end
    end
    p.layout = L.layout
    return p
end

function ns:GetProgress(guideId)
    local p = ns.char.progress[guideId]
    if not p then
        local L = ns.GuideLayouts and ns.GuideLayouts[guideId]
        p = { step = 1, done = {}, skipped = {}, layout = L and L.layout or nil }
        ns.char.progress[guideId] = p
    end
    return ns:ApplyLayout(guideId, p)
end

function ns:ResetProgress(guideId)
    local L = ns.GuideLayouts and ns.GuideLayouts[guideId]
    ns.char.progress[guideId] = { step = 1, done = {}, skipped = {}, layout = L and L.layout or nil }
end

function ns:ResetSettings()
    _G[ns.svAccount] = nil
    ns:InitSavedVariables()
end
