-- Questwarden - contents of the settings window (rendered by UI/Config.lua)
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- This program is free software: you can redistribute it and/or modify it under the terms of the
-- GNU General Public License as published by the Free Software Foundation, version 3.
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
-- even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details. The complete license text is in LICENSE.
--
-- Every control changes a real setting. (UI/Config.lua can still render `planned` items, but 1.0 has none.)
-- Settings live in the active profile (ns.db.profile); see Core/SavedVars.lua for defaults.

local _, ns = ...

local function T(key, label, extra)
    local it = { type = "toggle", key = key, label = label }
    for k, v in pairs(extra or {}) do it[k] = v end
    return it
end
local function H(text) return { type = "header", text = text } end
local function prof() return ns.db.profile end

local MODIFIERS = { { "CTRL", "CTRL" }, { "ALT", "ALT" }, { "SHIFT", "SHIFT" } }

local pages = {}
ns.ConfigPages = pages

pages.general = { title = "General", items = function() return {
    T("showAllFrames", "Show all Enabled Frames", { tip = "Shows the guide window and the arrow. Off hides both." }),
    T("locked", "Lock Frames"),
    T("autohideRaid", "Autohide in Raids", { tip = "Hides the guide window and arrow while you are in a raid group." }),
    { type = "button", label = "Run Setup Again", tip = "The setup wizard for this character: route and leveling mode, talent plan, dungeons and options. It starts from your current choices, and nothing changes until you press Finish Setup.",
      func = function() ns.Config.frame:Hide() ns.Welcome:Open(true) end },
    T("simpleSettings", "Simple settings view", { tip = "Shows only the options most players need: the Advanced Settings and Profiles tabs and rarely used options are hidden. Turn it off to see everything again. Hidden options keep working as they are set.",
      after = function() ns.Config:Rebuild() end }),
    H("Features"),
    T("showMinimapButton", "Enable Minimap Button"),
    T("worldMapButton", "Enable World Map Button", { more = true, tip = "A button on the world map that opens the guide browser." }),
    T("hideWindow", "Hide Window", { more = true }),
    T("showArrow", "Hide waypoint arrow", { invert = true }),
    T("corpseNav", "Automatically Navigate to Corpse", { tip = "After you release your spirit, the arrow points to your corpse until you are alive again, then goes back to the guide. Navigation only: it never releases, resurrects or talks to a spirit healer. Not inside instances (no outdoor position). /" .. ns.slash .. " corpse off|on dismisses or brings it back.",
      after = function() ns.Corpse:OnSetting() end }),
    T("roamRoutes", "Roaming Waypoints for Kill Objectives", { tip = "Cycles through verified hunting-area waypoints until the objective is complete. The points cover where the mobs are known to spawn, not where they are right now. Only some quests have a verified route; the others keep their normal waypoint.",
      after = function() ns.Roam:Refresh() if not ns.db.profile.roamRoutes then ns.Roam:Stop("setting off") end end }),
    { more = true, type = "button", label = "Next patrol point", tip = "Moves the arrow to the next point of the hunting route. The quest step is not skipped.",
      func = function() ns.Roam:Next() end },
    { more = true, type = "button", label = "Normal objective waypoint", tip = "Turns the hunting route off for the current step and shows the normal objective waypoint. /" .. ns.slash .. " route on brings it back.",
      func = function() ns.Roam:Suspend() end },
    T("patrolPaths", "Follow Patrolling NPCs", { more = true, tip = "When a step needs an NPC that walks a known path (a quest giver, a turn-in NPC or a named mob), the arrow goes to the nearer end of the path and then along it until the step is done. The path is dotted on the world map and minimap. Path data from QuestieDB; it shows where the NPC walks, not where it is now.",
      after = function() ns.Patrol:Refresh() end }),
    T("activeItems", "Hide Active Item window", { invert = true, tip = "Buttons for usable quest items in your bags; click one to use the item (Shift-click links it, Alt-drag moves the window). The buttons change only out of combat." }),
    T("vendorTreasures", "Enable Vendor Treasures", { tip = "When a merchant opens, a green arrow marks the items it sells that are upgrades for your spec profile, as on quest rewards." }),
    T("flightTimers", "Show Flight Timers", { tip = "A bar with the time left on a flight. Each route is timed the first time you fly it." }),
    T("timedQuestWarn", "Warn Before Timed Quests", { tip = "When a timed quest's details open, says on screen and in chat how long you will have once you accept it. Timed quests are never accepted automatically." }),
    T("timedQuestBar", "Show Timed Quest Timers", { tip = "A bar with the time left on each timed quest in your log.", after = function() ns.QuestTimer:Update() end }),
    T("groupFeatures", "Enable Group Settings", { tip = "Master switch for the party features on the Communications tab and the leader's target on the Targeting tab." }),
    H("Automation"),
    { type = "toggle", label = "Quest auto accept/turn in",
      get = function() return prof().autoAccept and prof().autoTurnIn end,
      set = function(v) prof().autoAccept, prof().autoTurnIn = v, v ns.QuestAuto:Rebuild() end,
      tip = "Guide quests only. Escort quests are never accepted automatically. More options: /" .. ns.slash .. " automation." },
    T("autoReward", "Quest auto rewards", { tip = "Takes a reward only when gear scoring shows one clear upgrade, or when your class can use none of them (then the most valuable). Otherwise you choose." }),
    { type = "select", label = "Class Trainer Suggestions",
      values = function() return { { "off", "Off" }, { "important", "Important only" }, { "all", "All" } } end,
      tip = "Lists the spell ranks your class trainer has for you, checked against your spellbook, with the trainer's prices. Train steps with nothing to learn are skipped. Saved for this character. Built in: What's Training? does not need to be installed. Never buys anything.",
      get = function() return ns.Trainer:Mode() end,
      set = function(v) ns.char.trainerSuggestions = v ns.Trainer.skipCache = nil if ns.Engine then ns.Engine:Refresh() end end },
    { type = "select", label = "Automatic Training",
      values = function() return { { "off", "Off" }, { "recommended", "Recommended spells" }, { "all", "Everything I can afford" } } end,
      tip = "When you open your class trainer: Recommended learns only the ranks the training suggestions list for you (important ones, or all with suggestions set to All); Everything learns all you can afford. Spends gold; one summary chat line when you close the trainer. Saved for this character. Hold Shift to skip.",
      get = function() return ns.Trainer:AutoTrainMode() end,
      set = function(v) ns.char.autoTrain = v end },
    T("flightAuto", "Flight Path automation", { tip = "On a 'fly to' step, takes the flight to that destination when the flight map opens. Hold Shift to skip." }),
    T("bindAuto", "Innkeeper Bind automation", { tip = "On a 'set your hearthstone' step, when you talk to that town's innkeeper: picks the bind option and confirms it, only if the game names the step's inn. The step completes once the game reports your new home. Never binds at other inns. Hold Shift to skip.",
      after = function() if not ns.db.profile.bindAuto then ns.Bind:Cancel("setting off") end end }),
    T("hearthSuggest", "Hearthstone Suggestions", { tip = "When your hearthstone is ready and the next steps turn in quests in the town it is set to, the step says so if hearthing saves enough time over walking: 5 minutes for one turn-in, less for more (never under a minute). Only a suggestion: it never uses the hearthstone.",
      after = function() ns.Hearth:Check() end }),
    T("deathSkip", "Death Skip Suggestions", { tip = "When the next step is in town (turn-ins, trainers, vendors ...) and the graveyard of the zone you are in is much nearer it than you are, the step suggests dying to a mob and taking the spirit healer's resurrection: below level 10 when it saves a minute or more (no resurrection sickness), from level 10 when it saves 5 minutes or more. Never on Hardcore characters. Only a suggestion.",
      after = function() ns.DeathSkip:Check() end }),
    T("durabilityWarn", "Low Durability Warning", { tip = "When a piece of equipped gear drops below 30% durability: a red on-screen message with how many pieces are below 30%, and the raid warning sound. Again only when another piece drops below." }),
    T("skipGossip", "Skip Gossip", { more = true, tip = "Picks the only option when an NPC has one option and no quests. Hold Shift to skip." }),
    H("Window"),
    { type = "range", key = "scale", label = "Guide Window Scale", min = 0.6, max = 1.6, step = 0.05, percent = true, decimals = 2 },
    { type = "range", key = "guideFontSize", label = "Guide Font Size", min = 9, max = 18, step = 1 },
    { type = "range", key = "arrowScale", label = "Arrow Scale", min = 0.5, max = 2, step = 0.05, percent = true, decimals = 2 },
    { type = "select", key = "accentColor", label = "Accent Colour",
      tip = "The colour of headers, switches, the selected tab and progress bars in every " .. ns.name .. " window. Shows after /reload.",
      values = function() local o = {} for _, a in ipairs(ns.Widgets.ACCENTS) do o[#o + 1] = { a[1], a[2] } end return o end,
      after = function() ns:Print("Accent colour changes show after /reload.") end },
    { type = "button", label = "Reset Window Settings", tip = "Puts guide window scale, font size and arrow scale back to their defaults. Positions are kept.",
      func = function()
          local d = ns.PROFILE_DEFAULTS
          prof().scale, prof().guideFontSize, prof().arrowScale = d.scale, d.guideFontSize, d.arrowScale
          ns.Config:Changed()
      end },
    H("Inventory"),
    T("inventoryManager", "Enable Inventory Manager", { tip = "Master switch for junk selling, the junk list and junk deletion." }),
    { type = "newline" },
    T("junkIndicator", "Show junk item indicator", { more = true, tip = "A coin on bag items the inventory manager would sell." }),
    { more = true, type = "toggle", key = "discardJunkFull", label = "Discard junk if bag is full", span = 2,
      tip = "When your bags are full, destroys the junk item worth least at a vendor on your next click in the game world, key press or loot click, one item each time. Destroyed items are gone, not sold. WoW only lets add-ons destroy items during a click or key press, so it waits for yours. Never in combat, with an item on the cursor, or with a merchant, trade, bank, mail or auction window open. Quest, guide and protected items are never touched.",
      after = function() ns.Assist:UpdateDiscardTarget() end },
    T("junkModifierToggle", "Toggle junk with modified right click", { more = true, span = 2, tip = "Modifier + right-click an item in your bags to add it to (or remove it from) your junk list. Listed items are sold and deleted like grey items." }),
    { more = true, type = "select", key = "junkModifier", label = "Right Click Modifier", values = function() return MODIFIERS end },
    T("autoSellJunk", "Auto Sell Junk"),
    T("autoRepair", "Auto Repair", { tip = "At a merchant who can repair: repairs all your gear with your own money (never guild funds), after any junk is sold. Only when you can pay the whole bill; one chat line says what it cost. Works without the Inventory Manager switch. Hold Shift to skip." }),
    { type = "newline" },
    { more = true, type = "keybind", label = "Delete Cheapest Junk Item Keybind",
      get = function() return ns.Assist:JunkKey() end, set = function(key) ns.Assist:SetJunkKey(key) end },
    { more = true, type = "button", label = "Reset Junk List", func = function() ns.Assist:ResetJunkList() end },
    H("Talents"),
    T("talentHints", "Enable Talents Guides", { tip = "Chat reminders to spend talent points, following your chosen build." }),
    T("showTalentSuggestions", "Show Talent Suggestions", { tip = "In the default talent window: numbered markers on your plan's next picks, a panel with the plan, and a tooltip line. Follows your spec profile. Never spends points.",
      after = function() if ns.TalentHints then ns.TalentHints:Refresh() end end }),
    T("talentPlan", "Enable Talent Plan", { tip = "On level-up, lists your build's next picks. Also /" .. ns.slash .. " talents plan." }),
    { more = true, type = "range", key = "talentPlanCount", label = "Talent Plan Number", min = 1, max = ns.Target.maxLevel, step = 1, tip = "How many upcoming picks the plan lists." },
} end }

pages.guide = { title = "Guide Routing", items = function() local CM = ns.Completionist return {
    { type = "select", label = "Leveling mode",
      tip = "Speed follows the leveling guides. Completionist does every quest the add-on knows for this character, lowest level first and zone by zone, coming back to zones as more quests open up. Saved for this character. Switching never changes your quest history; each mode keeps its own route progress.",
      values = function() return ns.Welcome.MODES end,
      get = function() return CM:Mode() end,
      set = function(v) CM:SetMode(v) end },
    { more = true, type = "button", label = "Completionist status", func = function() for _, l in ipairs(CM:StatusLines()) do ns:Print(l) end end },
    { more = true, type = "button", label = "Plan next Completionist segment", func = function() if CM:Active() then CM:Replan("replanned") end end },
    { type = "desc", text = "Completionist routes the quests of every dungeon (from each dungeon's usual level; run steps can be skipped). The dungeon choices below are for Speed." },
    { more = true, type = "toggle", label = "Completionist: route group and elite quests", hidden = ns.Setup:Routing() ~= nil,
      tip = "For characters that finished setup this follows Show Group Quests.",
      get = function() return not CM:State().exclude.group end, set = function(v) CM:SetIncluded("group", v) end },
    { more = true, type = "toggle", label = "Completionist: route raid quests", get = function() return not CM:State().exclude.raid end, set = function(v) CM:SetIncluded("raid", v) end },
    { more = true, type = "toggle", label = "Completionist: route profession quests", get = function() return not CM:State().exclude.profession end, set = function(v) CM:SetIncluded("profession", v) end },
    { more = true, type = "toggle", label = "Completionist: route reputation quests", get = function() return not CM:State().exclude.reputation end, set = function(v) CM:SetIncluded("reputation", v) end },
    { more = true, type = "toggle", label = "Completionist: route event quests", get = function() return not CM:State().exclude.event end, set = function(v) CM:SetIncluded("event", v) end },
    { type = "newline" },
    T("skipOverleveled", "Skip overleveled steps", { tip = "Skips picking up quests that are grey for your level, unless a later quest in the guide needs them. Quests already in your log are always done and turned in. Off by default." }),
    { type = "toggle", label = "Show Group Quests", tip = "Elite and group quest steps. After setup this is saved for this character.",
      get = function() return ns.Engine:EliteOn() end, set = function(v) ns.Setup:SetElite(v) end },
    T("speedRoute", "Maximum-speed route", { tip = "Hides optional side quests." }),
    { type = "toggle", label = "Hardcore character", hidden = not ns.Target.hardcore,
      tip = "This character plays Hardcore (one life). Guides follow their Hardcore route: risky steps are left out or come with a warning. Always on for characters on a Hardcore realm; elsewhere saved for this character only.",
      get = function() return ns.char.hardcore == true or ns.TargetCheck.HardcoreRealm() end,
      set = function(v) ns.char.hardcore = v and true or false; if ns.Engine then ns.Engine:Refresh() end end },
    T("autoAdvance", "Advance steps automatically"),
    T("autoSelectGuide", "Pick a guide on first login", { more = true }),
    H("Expansion"),
    { type = "desc", text = ns.name .. " for " .. ns.Target.name .. " covers levels 1-" .. ns.Target.maxLevel .. " (" .. table.concat(ns.Target.chapters, ", ") .. ")." },
    H("Dungeons"),
    { type = "toggle", label = "Include Dungeon Quests", tip = "When disabled, " .. ns.name .. " skips dungeon quests and recommends an outdoor leveling route where available. A dungeon quest already in your log keeps its turn-in, which appears once the quest is complete. After setup this is saved for this character.",
      get = function() return ns.Setup:DungeonsOn() end, set = function(v) ns.Setup:SetDungeonsOn(v) end },
    { type = "newline" },
    { type = "desc", text = "Pick single dungeons below. * = the guides have quests for it; the others are listed for completeness. Recommended = not outleveled and at most 8 levels above you." },
    { type = "button", label = "Select Recommended Dungeons", func = function()
        local lvl = UnitLevel and UnitLevel("player") or 1
        if not ns.Setup:Routing() then prof().dungeonOff = {} end
        for _, d in ipairs(ns.Dungeons) do ns.Setup:SetDungeonSelected(d.name, ns.DungeonRecommended(d, lvl)) end
    end },
    { type = "button", label = "Select all Dungeons", func = function()
        if not ns.Setup:Routing() then prof().dungeonOff = {} end
        for _, d in ipairs(ns.Dungeons) do ns.Setup:SetDungeonSelected(d.name, true) end
    end },
    { type = "newline" },
} end }

-- One switch per dungeon of the player's faction.
do
    local base = pages.guide.items
    pages.guide.items = function()
        local out = base()
        local faction = ns.Compat.PlayerInfo().faction
        for _, d in ipairs(ns.DungeonsFor(faction)) do
            out[#out + 1] = { type = "toggle", label = d.name .. (ns.DungeonHasQuests(d.name) and " *" or ""),
                tip = string.format("Usually run at levels %d-%d.", d.min, d.max),
                disabled = function() return not ns.Setup:DungeonsOn() end,
                get = function() return ns.Setup:DungeonSelected(d.name) end,
                set = function(v) ns.Setup:SetDungeonSelected(d.name, v) end }
        end
        return out
    end
end

pages.targeting = { title = "Targeting", items = function() return {
    T("markEnabled", "Enable Targeting", { tip = "Raid markers: /" .. ns.slash .. " mark, the marker bar and guide marking." }),
    T("maxNameplateDistance", "Maximize Nameplate Distance", { tip = "Sets the game's nameplate distance to 41 yards (default 20), so step mobs are seen and marked sooner. Turning it off restores your previous value." }),
    H("Target Markers"),
    T("autoMark", "Mark Enemy Targets", { tip = "NPCs a guide step names with [mark=...]." }),
    T("autoMarkObjectives", "Mark Enemy Mobs", { tip = "The kill objectives of your current kill steps, one icon per mob type." }),
    T("markFriendly", "Mark Friendly Targets", { tip = "The NPC who gives or takes the current step's quest, and your trainer on a training step." }),
    T("markInGroup", "Enable Target Markers (Group)", { tip = "Allow automatic marking while you are in a party or raid (icons are visible to the group)." }),
    T("markReplace", "Replace existing markers", { more = true }),
    T("markNotify", "Chat messages for markers", { more = true, tip = "Problems with automatic marking, and the result of /qw mark. Automatic marks that work are not announced." }),
    T("markClearOnAdvance", "Remove my markers on step change", { more = true, span = 2 }),
    { more = true, type = "select", key = "defaultMarker", label = "Default marker",
      values = function() local o = {} for i = 8, 1, -1 do o[#o + 1] = { i, ns.Marker.Label(i) } end return o end },
    H("Targeting Macro"),
    T("markWithMacro", "Mark with the Targeting Macro", { more = true, tip = "One press of the '" .. ns.name .. "' macro targets the nearest visible mob of each kind the guide wants and gives each its raid marker. " .. ns.name .. " then never marks by itself. Off (default): automatic marking, with the icons moving to the mob you target or mouse over and on to the next visible mob when one dies or leaves your view.",
      after = function() ns.Assist:UpdateMacro() if ns.Marker.OnStep then ns.Marker:OnStep() end end }),
    T("targetMacro", "Create Targeting Macro", { tip = "Keeps a '" .. ns.name .. "' macro that targets the current step's NPCs (/tar). Put it on an action bar.",
      after = function() ns.Assist:UpdateMacro() end }),
    T("targetNotify", "Notify on new target", { tip = "A chat line when an NPC from the current step first comes into view. Off by default." }),
    H("Raid Marker Bar"),
    { type = "toggle", label = "Show the raid marker bar",
      get = function() return prof().showMarkerBar end,
      set = function(v) if (prof().showMarkerBar and true or false) ~= v then ns.MarkerBar:Toggle() end end },
    H("Active Target Frame"),
    T("activeTargets", "Enable Active Target Frame", { tip = "Click-to-target buttons for the current step's NPCs (/tar). Updates after combat." }),
    T("atEnemy", "Show Enemy Target"),
    T("atFriendly", "Show Friendly Target"),
    T("atLeader", "Follow Party Leader Target", { tip = "Adds your party leader's target. Needs Enable Group Settings (General)." }),
    T("atHideBg", "Hide Targets Background", { more = true }),
    { more = true, type = "range", key = "atScale", label = "Active Targets Scale", min = 0.8, max = 3, step = 0.05, percent = true },
    { type = "button", label = "Reset Window Position", func = function() ns.ActiveTargets:ResetPosition() end },
} end }

pages.tracker = { title = "Leveling Tracker", items = function() return {
    { type = "desc", text = "Tracks how long each level takes (played time from the server) and your XP per hour. Levels finished before you installed this version show as -." },
    T("trackerEnabled", "Enable Leveling Tracker"),
    T("trackerWithCharacter", "Always Open Leveling Report With Character Panel", { span = 2 }),
    { type = "button", label = "Open Leveling Report", func = function() ns.LevelTracker:ToggleReport() end },
    H("Level Splits"),
    T("splitsEnabled", "Enable Level Splits", { tip = "A small window with the time each recent level took." }),
    T("splitsCompare", "Compare Next Level", { tip = "Shows how the running level compares with the previous one." }),
    T("splitsTotal", "Show Total Time Split"),
    T("splitsHideBg", "Hide Splits Background", { more = true }),
    { more = true, type = "range", key = "splitsHistory", label = "Level Splits History", min = 1, max = ns.Target.maxLevel, step = 1 },
    { more = true, type = "range", key = "splitsFont", label = "Level Splits Font Size", min = 9, max = 17, step = 1 },
    { more = true, type = "range", key = "splitsAlpha", label = "Level Splits Opacity", min = 0.1, max = 1, step = 0.05, percent = true },
} end }

pages.comms = { title = "Communications", items = function() return {
    T("versionCheck", "Enable Addon Version Checks", { tip = "Tells you when a group or guild member runs a newer " .. ns.name .. "." }),
    T("questNotify", "Chat messages for quest automation"),
    H("Announcements"),
    T("announceLevelEmote", "Announce Level Ups (Emote)"),
    T("announceLevelParty", "Announce Level Ups (Party Chat)"),
    T("announceLevelGuild", "Announce Level Ups (Guild Chat)"),
    T("announceComplete", "Announce Step completion", { tip = "Party chat when a guide quest's objectives are all done. Needs Enable Group Settings." }),
    T("announceCollect", "Announce Step collection", { tip = "Party chat on guide quest progress, e.g. Wolf Meat: 3/8. Needs Enable Group Settings." }),
    T("announceFlight", "Announce Step flying timers", { tip = "Party chat when you take a flight, with the arrival time once the route is known." }),
    T("announceSkipQuestie", "Don't announce when Questie is loaded", { more = true, span = 2, tip = "Questie can announce quest progress itself; this avoids double messages." }),
    H("Grouping"),
    { type = "desc", text = "Needs Enable Group Settings (General). Announcements go to party chat, never to raids." },
    T("announceAlways", "Send announcements without another " .. ns.name .. " user in group", { more = true, span = 2,
      tip = "Off: only announce when another party member runs " .. ns.name .. " (learned from version checks)." }),
    { type = "newline" },
    T("autoShareQuests", "Automatic quest sharing", { tip = "Shares a guide quest with your party right after you accept it." }),
    H("Play Together"),
    { type = "desc", text = "For friends leveling together, each with " .. ns.name .. ". Needs Enable Group Settings (General); party members need this switch on too." },
    T("playTogether", "Show party members' steps", { tip = "Under the current step: where each party member is in the guide (ahead, behind or on your step), and 'Wait for <name>' when someone still has to pick up or turn in a quest before you move on. Sent to your party only, about once a minute and when your step changes.",
      after = function() ns.PlayTogether:Send(true) ns:Fire("REFRESH") end }),
    T("playFollowLeader", "Follow the party leader's step", { tip = "Your guide goes to the leader's guide and step whenever theirs changes, so everyone does the same step. Steps the leader is past are skipped for you, not completed. /" .. ns.slash .. " follow does it once." }),
} end }

pages.tips = { title = "Tips", items = function() return {
    T("tipsEnabled", "Enable Tips"),
    H("New Players"),
    { type = "desc", text = "Help for players new to World of Warcraft. Nothing is done for you. See also Simple settings view (General) and Play Together (Communications)." },
    T("newPlayerTips", "Explain steps and the basics", { tip = "The first time you meet each kind of step (pick up, kill, turn in, fly, train...), a tip says what to do and which key opens what. Also: full bags, your first death and talent points. Each explanation shows once per character; /" .. ns.slash .. " newplayer reset shows them again.",
      after = function() ns.NewPlayer:OnStep() end }),
    T("spellCoach", "Coach new spells", { tip = "When you learn a spell: what it does (the game's own text) and, if it is not on your action bars, how to put it there. Every few levels, a leveling tip for your class." }),
    T("professionTips", "Profession starter tips", { tip = "Once, at level 5: which professions suit a new character and the trainers nearby. /" .. ns.slash .. " professions lists the trainers any time.",
      after = function() ns.ProfessionTips:Check() end }),
    T("tipWindows", "Show tips in a window", { tip = "The tips above (steps and basics, new spells, class tips, professions) open in a small window you close with OK, one at a time; tips that come during a fight wait until it ends. Off: they go to chat.",
      after = function() if not ns.db.profile.tipWindows then ns.TipWindow:Flush() end end }),
    T("mountGoal", "Mount savings goal", { hidden = ns.Riding == nil, tip = "From 10 levels before you can ride: the price of your first mount and riding lessons, against the gold you have, under the current step. /" .. ns.slash .. " mount shows it any time.",
      after = function() ns:Fire("REFRESH") end }),
    T("sessionRecap", "Session recap", { tip = "At login, one chat line about your last session: time played, levels, quests, zones, deaths and gold. /" .. ns.slash .. " recap shows this session so far." }),
    H("Drowning"),
    T("drownWarn", "Enable Warning"),
    T("drownSound", "Enable Warning Sound"),
    { type = "range", key = "drownThreshold", label = "Threshold", min = 5, max = 50, step = 1, suffix = "%" },
    T("drownFlash", "Screen Edge Flash"),
    H("Emergency Actions"),
    T("lowHealthWarn", "Enable Warning", { tip = "Warns when your health drops below the threshold." }),
    { type = "range", key = "lowHealthThreshold", label = "Threshold", min = 5, max = 40, step = 1, suffix = "%" },
    T("lowHealthAnim", "Enable Warning Sound"),
    T("lowHealthFlash", "Screen Edge Flash"),
    H("Dangerous Mobs Tracking"),
    T("trackMobsMap", "Track Mobs on Map", { tip = "World map pins for elite and rare mobs in the shown zone (bundled data)." }),
    T("trackRares", "Track Rare Mobs", { tip = "A chat alert and sound when a rare mob's nameplate appears (rares from the bundled database)." }),
    T("skipKilledRares", "Skip mobs already killed"),
    T("trackTreasures", "Track Treasures", { tip = "World map pins for treasure chests in the shown zone." }),
    T("trackSpiritHealers", "Track Spirit Healers", { tip = "World map pins for the spirit healers (graveyards) in the shown zone, where you appear when you die." }),
    H("Item Upgrade"),
    T("gearEnabled", "Enable Item Upgrade"),
    -- Profiles of the player's own class only, so another class's profile can never be active.
    { type = "select", label = "Spec profile",
      tip = "Used for tooltips, quest rewards and automatic upgrades. Saved for this character. Automatic upgrades need a spec chosen here.",
      values = function()
          local o = { { "auto", "Automatic (tooltips only)" } }
          for _, p in ipairs(ns.Gear:ProfilesForClass(ns.Gear:Context().class)) do
              local name = p.spec and ns.Upgrade:ProfileName(p) or (p.role .. ", leveling")
              o[#o + 1] = { p.id, name .. (p.context == "pve-preraid" and " (pre-raid)" or "") .. (p.weights and "" or " *") }
          end
          return o
      end,
      get = function() return ns.char.gearProfile or "auto" end,
      set = function(v) ns.char.gearProfile = (v ~= "auto") and v or nil ns.AutoEquip:OnProfileChanged() end },
    T("gearQuestRewards", "Quest Reward Recommendation", { tip = "Ranks a quest's reward choices in chat for your spec. You still choose the reward, unless Quest Reward Automation is on." }),
    T("rewardMarkers", "Mark quest reward choices", { tip = "A green arrow on reward choices that are upgrades for your spec. When none is, a coin on the one that sells for the most." }),
    T("autoReward", "Quest Reward Automation"),
    T("gearTooltip", "Disable Tooltips", { invert = true }),
    T("gearShowPercent", "Show score change (%)", { more = true }),
    T("gearShowConfidence", "Show profile confidence", { more = true }),
    T("auctioneer", "Enable Auctioneer", { tip = "Adds an Upgrades tab to the auction house. You start each scan yourself while the auction house is open; prices are the listings that scan saw, so old or partial scans may no longer match what is for sale. Nothing is ever bought." }),
    H("Automatic Upgrades"),
    { type = "desc", text = "Equips gear from your bags when it is an upgrade for your spec profile (* = estimated from a stat priority). "
        .. "Never in combat, never Bind-on-Equip items, nothing is sold or deleted. Estimates are spec scores, not DPS or healing." },
    { type = "toggle", label = "Enable automatic upgrades",
      tip = "Off by default. Needs a spec profile. Bind-on-Equip items are never equipped automatically.",
      get = function() return prof().autoEquip end,
      set = function(v)
          if not v then prof().autoEquip = false return end
          local p, why = ns.Upgrade:ActiveProfile()
          if not p then prof().autoEquip = false ns:Print("Automatic upgrades: " .. why .. " (Spec profile).") return end
          ns.Config:Confirm("Automatically equip upgrades for " .. ns.Upgrade:ProfileName(p) .. "?\n\n"
              .. "Empty slots get any usable item; filled slots only a higher estimated spec score. "
              .. "Never in combat, never Bind-on-Equip items, replaced items stay in your bags.",
              function() prof().autoEquip = true ns.AutoEquip:Schedule() end)
      end },
    T("autoEquipEmpty", "Fill empty gear slots", { tip = "Any usable non-BoE item goes into an empty slot, even if it is not ideal for your spec." }),
    T("autoEquipBags", "Equip bigger bags", { tip = "A non-BoE bag from your bags goes into an empty bag slot. With all four slots full, it replaces your smallest bag if it has more slots; that bag's items are moved to your other bags first, and nothing happens without room for them." }),
    { more = true, type = "range", key = "autoEquipMinPct", label = "Minimum upgrade", min = 0, max = 20, step = 0.5, decimals = 1, suffix = "%",
      tip = "For occupied slots. 0 means any strictly higher score." },
    T("equipNotify", "On-screen equip messages"),
    T("equipChat", "Copy equip messages to chat", { tip = "A line in your chat frame for every automatic equip. Only you see it; nothing is sent to other players." }),
    T("equipSound", "Play a sound on automatic upgrades", { tip = "The level-up sound when an item was equipped automatically." }),
    T("boeMarkers", "Mark Bind-on-Equip upgrades in bags", { tip = "A small arrow on BoE items that would be an upgrade. Equip them yourself." }),
    { more = true, type = "button", label = "Clear excluded items",
      tip = "Items excluded with /" .. ns.slash .. " gear exclude <item> are allowed again.",
      func = function() ns.Upgrade:Exclusions().items = {} ns.AutoEquip:Schedule() end },
    { type = "header", text = "Protected Slots (never changed automatically)", more = true },
} end }

-- One toggle per gear slot, stored per character.
do
    local base = pages.tips.items
    pages.tips.items = function()
        local out = base()
        for _, slot in ipairs(ns.Gear.SCORED_SLOTS) do
            out[#out + 1] = { type = "toggle", label = ns.Gear.SLOT_NAMES[slot], more = true,
                get = function() return ns.Upgrade:SlotExcluded(slot) end,
                set = function(v) ns.Upgrade:Exclusions().slots[slot] = v and true or nil ns.AutoEquip:Schedule() end }
        end
        return out
    end
end

pages.help = { title = "Help", items = function() return {
    H("Commands"),
    { type = "desc", text = "|cffffd100/" .. ns.slash .. "|r - show or hide the guide window\n"
        .. "|cffffd100/" .. ns.slash .. " options|r - this window   |cffffd100/" .. ns.slash .. " guide|r - guide browser   |cffffd100/" .. ns.slash .. " talents|r - talent guide\n"
        .. "|cffffd100/" .. ns.slash .. " next|r, |cffffd100prev|r, |cffffd100skip|r - step control   |cffffd100/" .. ns.slash .. " gear|r - gear overview\n"
        .. "|cffffd100/" .. ns.slash .. " mark|r, |cffffd100unmark|r, |cffffd100markbar|r - raid markers   |cffffd100/" .. ns.slash .. " minimap|r - minimap button\n"
        .. "|cffffd100/" .. ns.slash .. " debug|r [api|marks|quest <id>] - diagnostics   |cffffd100/" .. ns.slash .. " help|r - every command" },
    H("The guide skips steps - why?"),
    { type = "desc", text = "A step is skipped automatically when your race or class cannot take the quest, when an earlier step it depends on was skipped, when an optional quest is not in your log, or (with Skip overleveled steps) when the quest is grey for your level. Hover a step to see the reason. Turn skipping off with Disable step skips (Advanced Settings)." },
    H("I am behind the guide's levels"),
    { type = "desc", text = "The routes assume normal experience and killing what is on your way between objectives. When a guide needs a minimum level it says so, sometimes with a grind step naming mobs and a place. Bonus or reduced experience makes the level ranges shift; just follow the steps." },
    H("Nothing gets a raid marker"),
    { type = "desc", text = "Type /" .. ns.slash .. " debug marks: it shows the current rule, whether you may mark (in a raid only the leader and assistants can) and the last decision." },
    H("Where are my settings?"),
    { type = "desc", text = "Settings are profiles (Profiles tab), shared between characters that use the same profile. Guide progress, talents and junk-sale totals always belong to the character." },
} end }

pages.advanced = { title = "Advanced Settings", items = function() return {
    T("debug", "Enable Debug"),
    T("lowQuality", "Low Quality Settings", { tip = "Redraws the arrow at most every 150 ms and shows fewer map pins." }),
    { type = "range", key = "arrowUpdateMs", label = "Update Frequency (ms)", min = 5, max = 150, step = 5,
      tip = "How often the arrow is redrawn." },
    T("preloadData", "Pre load all data", { tip = "Loads item data for your guide's quests and your bags at login, so tooltips and scoring do not wait." }),
    T("checkConflicts", "Check for Addon Incompatibility", { span = 2, tip = "At login, warns when another leveling guide add-on is loaded." }),
    H("Debug"),
    T("disableStepSkips", "Disable step skips", { tip = "Never skip steps automatically; you skip them yourself." }),
    { type = "toggle", label = "Display Lua Errors",
      get = function() return ns.Assist:LuaErrors() end, set = function(v) ns.Assist:LuaErrors(v) end,
      tip = "The game's own Lua error pop-up (scriptErrors setting)." },
    T("showMapPins", "Disable Map Pins", { invert = true }),
    T("showMinimapPin", "Show Minimap Waypoint", { tip = "A pin for the current waypoint on the minimap; it sits on the minimap's edge while the target is out of range.",
      after = function() ns.Nav:UpdateMinimapPin() end }),
} end }

local function profileNames(exclude)
    local out = {}
    for _, name in ipairs(ns.Profiles:List()) do
        if not (exclude and exclude[name]) then out[#out + 1] = { name, name } end
    end
    return out
end

pages.profiles = { title = "Profiles", items = function() return {
    { type = "button", label = "Reload guides and UI", func = function() ReloadUI() end },
    { type = "button", label = "Reset Guide Progress", func = function()
        ns.Config:Confirm("Reset your progress in the current guide?", function() ns.Engine:Reset() end)
    end },
    { type = "newline" },
    { type = "desc", text = "Profiles hold your settings, so characters can share them or each have their own. Guide progress always belongs to the character. Reset Profile puts the active profile back to its default values." },
    { type = "button", label = "Reset Profile", func = function()
        ns.Config:Confirm("Reset every setting in the profile '" .. ns.Profiles:Current() .. "' to its default?", function() ns.Profiles:Reset() end)
    end },
    { type = "label", span = 2, text = function() return "Current Profile: |cffffd100" .. tostring(ns.Profiles:Current()) .. "|r" end },
    { type = "desc", text = "Create a new profile by entering a name, or pick an existing one." },
    { type = "input", label = "New", span = 2, func = function(text)
        local ok, why = ns.Profiles:Set(text)
        if not ok then ns:Print("Profile not created: " .. tostring(why)) end
    end },
    { type = "newline" },
    { type = "select", label = "Existing Profiles", span = 2, values = function() return profileNames() end,
      get = function() return ns.Profiles:Current() end, set = function(v) ns.Profiles:Set(v) end },
    { type = "desc", text = "Copy the settings from an existing profile into the active profile." },
    { type = "select", label = "Copy From", span = 2, empty = "",
      values = function() return profileNames({ [ns.Profiles:Current()] = true }) end,
      get = function() return nil end,
      set = function(v) ns.Config:Confirm("Copy all settings from '" .. v .. "' into '" .. ns.Profiles:Current() .. "'?", function() ns.Profiles:CopyFrom(v) end) end },
    { type = "desc", text = "Delete profiles you no longer use. The active profile and the default profile cannot be deleted." },
    { type = "select", label = "Delete a Profile", span = 2, empty = "",
      values = function() return profileNames({ [ns.Profiles:Current()] = true, [ns.Profiles:Default()] = true }) end,
      get = function() return nil end,
      set = function(v) ns.Config:Confirm("Delete the profile '" .. v .. "'?", function() ns.Profiles:Delete(v) end) end },
    H(""),
    { type = "button", label = "Set current profile as default", span = 2, func = function()
        ns.Profiles:SetDefault()
        ns:Print("New characters will start with the profile '" .. ns.Profiles:Current() .. "'.")
    end },
    { type = "label", span = 1, text = function() return "Default: |cffffd100" .. tostring(ns.Profiles:Default()) .. "|r" end },
} end }
