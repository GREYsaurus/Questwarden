-- Questwarden - per-character setup: the setup wizard's choices, validation, saving and route start
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- This program is free software: you can redistribute it and/or modify it under the terms of the
-- GNU General Public License as published by the Free Software Foundation, version 3.
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
-- even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details. The complete license text is in LICENSE.
--
-- The wizard (UI/Welcome.lua) edits a DRAFT (ns.char.setup.draft); nothing else changes until Finish.
-- Finish validates the whole draft, writes the choices where the add-on already keeps them (mode, guide,
-- Hardcore flag, talent plan, gear profile, Completionist categories) plus the per-character routing record
-- (ns.char.routing: dungeons and group quests), starts the route, and only then marks setup done. If the
-- route cannot be started everything is put back as it was and the draft is kept (docs/SETUP.md).
--
-- The first page asks whether the player is new to World of Warcraft (ns.char.newPlayer). New players get
-- fewer pages in plainer words (Setup.PATHS): Speed mode; on the talents page they first say whether they want
-- to tank, heal or deal damage (or do not know), and the suggested plan follows (Setup:SuggestedPlan: the class
-- default, the spec its leveling advice names, when it fits the role); the recommended dungeons (those the leveling guides have quests
-- for) picked on a first setup so they learn to run them, no training or options page (defaults kept), the gear
-- profile following the talent plan, and the automatic-upgrades question on the talents page (off until ticked).
-- Both paths end with the helpers page (Setup.HELPERS),
-- whose switches are settings in the profile and start off.
--
-- ns.char.setup = { version, done, legacy, draft, at, lastError }
-- ns.char.routing = { dungeons = "questing" | "selected", selected = { [dungeon name] = true }, elite = bool }
--   Dungeon names are the dungeon list's names (Database/Dungeons.lua), the same strings the guides tag
--   steps with; they come from the bundled data, never from the client's language.

local _, ns = ...

local Setup = { VERSION = 1 }
ns.Setup = Setup

Setup.STEPS = {
    { id = "welcome", title = "Welcome" },
    { id = "route", title = "Route" },
    { id = "build", title = "Talents" },
    { id = "dungeons", title = "Dungeons" },
    { id = "prefs", title = "Options" },
    { id = "helpers", title = "Helpers" },
    { id = "review", title = "Review" },
}

-- Pages for new and experienced players (the experienced path until the first page is answered).
Setup.PATHS = {
    new = { "welcome", "route", "build", "dungeons", "helpers", "review" },
    experienced = { "welcome", "route", "build", "dungeons", "prefs", "helpers", "review" },
}

-- The helpers page: profile settings, all off by default (Core/SavedVars.lua, docs/NEW_PLAYERS.md).
-- `riding`: only where the game version has mount prices (Database/Riding.lua).
Setup.HELPERS = {
    { key = "newPlayerTips", name = "Explain steps and the basics",
      text = "The first time you meet each kind of step, one chat line says what to do and which key opens what. Also full bags, your first death and talent points." },
    { key = "spellCoach", name = "Coach new spells",
      text = "When you learn a spell: what it does, and how to put it on your action bars if it is not there. Every few levels, a tip for your class." },
    { key = "playTogether", name = "Play together",
      text = "Shows where your party members are in the guide and when to wait for someone. Your friends need this add-on with this switch on too. Also turns on group settings." },
    { key = "mountGoal", name = "Mount savings goal", riding = true,
      text = "From 10 levels before you can ride: what your first mount costs against the gold you have." },
    { key = "sessionRecap", name = "Session recap",
      text = "At login, one line about your last session: time played, levels, quests, zones and gold." },
    { key = "professionTips", name = "Profession starter tips",
      text = "Once, at level 5: which professions suit a new character and where their trainers are." },
    { key = "simpleSettings", name = "Simple settings view",
      text = "The settings window shows only the options most players need. Turn it off there to see everything." },
}

-- Helpers this game version offers.
function Setup:Helpers()
    local out = {}
    for _, h in ipairs(self.HELPERS) do
        if not h.riding or ns.Riding then out[#out + 1] = h end
    end
    return out
end

-- The steps of a draft's path: { id, title } in order.
function Setup:Steps(d)
    local byId = {}
    for _, st in ipairs(self.STEPS) do byId[st.id] = st end
    local out = {}
    for _, id in ipairs(self.PATHS[d and d.newPlayer and "new" or "experienced"]) do out[#out + 1] = byId[id] end
    return out
end

-- The answer to the first page. New players follow the guides (Speed) from the recommended guide.
function Setup:SetNewPlayer(d, yes)
    d.newPlayer = yes and true or false
    if yes then
        local speed = self:ModeInfo("speed")
        if speed and speed.available then d.mode = "speed" end
        if not self:GuideValid(d.guide) then d.guide = self:RecommendedGuide() or false end
        -- A first setup starts with the recommended dungeons picked; a re-run keeps the saved choice.
        if not self:Routing() then
            d.dungeons = "selected"
            if #self:SelectedDungeons(d) == 0 then self:SelectAllDungeons(d) end
        end
        if d.dungeons == "selected" and #self:SelectedDungeons(d) == 0 then d.dungeons = "questing" end
    end
end

-- Plain words for the talent plans' roles (Talents/Builds), for new players.
Setup.ROLE_TEXT = {
    ["Tank"] = "Tank: in a group, enemies attack you while the others deal damage.",
    ["Healer"] = "Healer: in a group, you keep everyone alive.",
    ["Melee DPS"] = "Damage up close.",
    ["Ranged DPS"] = "Damage from a distance.",
    ["Melee DPS / Tank"] = "Damage up close; can also tank in a group.",
}

-- The new-player question on the talents page. `match` is looked for in the plans' role.
Setup.ROLES = {
    { id = "tank", name = "Tank", match = "Tank",
      text = "Stand in front and keep the enemies attacking you, so the others are safe. Every group needs one." },
    { id = "healer", name = "Heal", match = "Healer",
      text = "Keep the group alive with healing spells. Every group needs one." },
    { id = "dps", name = "Deal damage", match = "DPS",
      text = "Defeat the enemies, up close or from a distance. A group has three; the usual place to start." },
    { id = "unsure", name = "I don't know yet",
      text = "You get the usual leveling plan for your class. You can change it any time." },
}

function Setup:RoleInfo(id)
    for _, r in ipairs(self.ROLES) do if r.id == id then return r end end
end

-- The plan to suggest for a draft's role: the class default when it fits, else the first plan of that role.
-- Returns plan, fits (false when the class has no plan for the role: then the class default).
function Setup:SuggestedPlan(d)
    local plans, default = self:Plans(), nil
    for _, p in ipairs(plans) do if p.default then default = p end end
    local r = self:RoleInfo(d.role)
    if not (r and r.match) then return default, true end
    local function fits(p) return p.role and string.find(p.role, r.match, 1, true) ~= nil end
    if default and fits(default) then return default, true end
    for _, p in ipairs(plans) do if fits(p) then return p, true end end
    return default, false
end

function Setup:SetRole(d, id)
    d.role = id
    local p = self:SuggestedPlan(d)
    if p then self:SetPlan(d, p.id) end
end

function Setup:SetAllHelpers(d, on)
    for _, h in ipairs(self:Helpers()) do d.helpers[h.key] = on and true or false end
end

-- Player-facing names and explanations (English only, like the rest of the add-on: docs/LOCALES.md).
Setup.MODE_NAMES = { speed = "Speed (the leveling guides)", completionist = "Completionist (every eligible quest)" }
Setup.MODE_TEXT = {
    speed = "Follows the leveling guides for your race and class in their zone order, using the quests that level you fastest. This is the default.",
    completionist = "Does every quest the add-on knows for this character, lowest level first and zone by zone, and comes back to zones when more of their quests open up. Slower than Speed. Quests the database lacks or places nowhere are not covered.",
}
Setup.TRAINING_NAMES = { important = "important spells", all = "all spells", off = "off" }
Setup.AUTOTRAIN_NAMES = { off = "off", recommended = "recommended spells, at your class trainer (spends gold)", all = "everything you can afford (spends gold)" }
Setup.INCLUDE_KINDS = { -- Completionist-only categories (Core/Completionist.lua); dungeons and group quests have their own steps
    { "raid", "Raid quests" }, { "profession", "Profession quests" }, { "reputation", "Reputation quests" },
    { "event", "Event and seasonal quests" }, { "repeatable", "Repeatable quests" },
}

local function copy(t)
    local out = {}
    for k, v in pairs(t or {}) do out[k] = type(v) == "table" and copy(v) or v end
    return out
end

-- Saved state ------------------------------------------------------------------------------------------

-- ns.char.setup, created on first use. Characters from before setup version 1 kept `setupDone` and
-- `setupDraft` (mode, guide, profile, autoEquip); both move here.
function Setup:State()
    local c = ns.char
    if type(c.setup) ~= "table" then c.setup = {} end
    local s = c.setup
    if c.setupDone ~= nil then
        if c.setupDone == true then s.done, s.version = true, s.version or self.VERSION end
        c.setupDone = nil
    end
    if c.setupDraft ~= nil then
        local old = c.setupDraft
        c.setupDraft = nil
        if type(old) == "table" and not s.done and type(s.draft) ~= "table" then
            s.draft = { mode = old.mode, guide = old.guide, gear = old.profile, autoEquip = old.autoEquip }
        end
    end
    if s.done ~= nil and s.done ~= true then s.done = nil end
    if s.draft ~= nil and type(s.draft) ~= "table" then s.draft = nil end
    return s
end

-- Characters that used Questwarden before this setup existed are not sent through it: the first time setup
-- state is seen, a guide, progress, mode, talent plan or spec profile marks the character as already set up
-- (legacy). A character that has an unfinished setup draft is not legacy, it resumes the draft.
function Setup:Migrate()
    local c = ns.char
    local first = type(c.setup) ~= "table"
    local hadDraft = type(c.setupDraft) == "table"
    local s = self:State()
    if s.done or not first or hadDraft then return end
    if c.activeGuide or c.gearProfile or c.mode or c.talentBuild or (type(c.progress) == "table" and next(c.progress)) then
        s.done, s.legacy, s.version = true, true, self.VERSION
    end
end

function Setup:Done() return self:State().done == true end
function Setup:Needed() return not self:Done() end

-- The routing record of a character that confirmed setup, or nil (then the settings profile decides).
function Setup:Routing()
    local r = ns.char and ns.char.routing
    if type(r) ~= "table" then return nil end
    if r.dungeons ~= "questing" and r.dungeons ~= "selected" then r.dungeons = "questing" end
    if type(r.selected) ~= "table" then r.selected = {} end
    r.elite = r.elite == true
    return r
end

-- What the add-on knows about the character; nothing here is asked in the wizard.
function Setup:Character()
    local info = ns.Compat.PlayerInfo()
    local className = LOCALIZED_CLASS_NAMES_MALE and info.class and LOCALIZED_CLASS_NAMES_MALE[info.class]
    local raceName = UnitRace and UnitRace("player")
    return {
        name = info.name, race = info.race, class = info.class, faction = info.faction, level = info.level or 1,
        raceName = raceName or info.race, className = className or info.class,
        game = ns.Target.name, hardcoreRealm = ns.TargetCheck.HardcoreRealm() and true or false,
    }
end

-- Choices for this character ------------------------------------------------------------------------------

-- Leveling modes with availability: { id, name, text, available, why }.
function Setup:Modes()
    local guides = #self:Guides() > 0
    local cmOk, cmWhy = ns.Completionist:Available()
    return {
        { id = "speed", name = self.MODE_NAMES.speed, text = self.MODE_TEXT.speed, available = guides,
          why = not guides and ("There is no leveling guide for this race and class in " .. ns.Target.name .. ".") or nil },
        { id = "completionist", name = self.MODE_NAMES.completionist, text = self.MODE_TEXT.completionist, available = cmOk,
          why = not cmOk and ("Not available: " .. cmWhy) or nil },
    }
end

function Setup:ModeInfo(id)
    for _, m in ipairs(self:Modes()) do if m.id == id then return m end end
end

-- Speed guides for this character (faction, race, class), sorted by level: { id, name, minLevel, maxLevel }.
function Setup:Guides()
    local info = ns.Compat.PlayerInfo()
    local out = {}
    for _, g in ipairs(ns.Guides:Filter({ faction = info.faction, race = info.race, class = info.class })) do
        out[#out + 1] = { id = g.id, name = g.name, minLevel = g.minLevel or 1, maxLevel = g.maxLevel or ns.Target.maxLevel }
    end
    return out
end

function Setup:GuideValid(id)
    if not id then return false end
    for _, g in ipairs(self:Guides()) do if g.id == id then return true end end
    return false
end

-- The recommended Speed guide for the character's level and zone (Core/Selector.lua).
function Setup:RecommendedGuide()
    local g = ns.Selector:Recommend()
    return g and self:GuideValid(g.id) and g.id or nil
end

-- Talent plans for the class in this game version (Talents/Builds, target data), plus "none".
function Setup:Plans()
    local class = ns.Compat.PlayerInfo().class
    local out = {}
    for i, b in ipairs(ns.Talents:BuildsFor(class)) do
        out[#out + 1] = { id = b.id, name = b.name, role = b.role, summary = b.summary, default = i == 1 }
    end
    return out
end

function Setup:PlanValid(id)
    if id == "none" then return true end
    for _, p in ipairs(self:Plans()) do if p.id == id then return true end end
    return false
end

-- Gear spec profiles for the class (Gear/Profiles.lua); false = automatic by level.
function Setup:GearProfiles()
    local out = { { id = false, name = "Automatic (a leveling profile for your level)" } }
    for _, p in ipairs(ns.Gear:ProfilesForClass(ns.Compat.PlayerInfo().class)) do
        if p.spec then
            out[#out + 1] = { id = p.id, name = ns.Upgrade:ProfileName(p) .. (p.context == "pve-preraid" and " (pre-raid)" or "")
                .. (p.weights and "" or " *"), spec = p.spec, context = p.context }
        end
    end
    return out
end

function Setup:GearValid(id)
    if id == false then return true end
    local p = id and ns.Gear:ProfileById(id)
    return p and p.class == ns.Compat.PlayerInfo().class and true or false
end

-- The talent tree (spec) a plan belongs to, from the spec -> plan table (Talents/ProfileBuilds.lua).
function Setup:PlanSpec(planId)
    local m = ns.TalentProfileBuilds and ns.TalentProfileBuilds.specs[ns.Compat.PlayerInfo().class]
    for spec, e in pairs(m or {}) do
        if e.plan == planId then return spec end
        for _, v in ipairs(e.variants or {}) do if v == planId then return spec end end
    end
end

-- Gear profiles name a tree by its short name ("Feral" for the talent tree "Feral Combat").
local function sameTree(gearSpec, spec)
    return gearSpec ~= nil and spec ~= nil and (gearSpec == spec or string.sub(spec, 1, #gearSpec + 1) == gearSpec .. " ")
end
Setup.SameTree = sameTree

local CONTEXT_PICK = { leveling = 1, ["pve-preraid"] = 2, ["pve-raid"] = 3 }

-- The gear profile that goes with a plan: a spec profile of the same tree (automatic upgrades need one),
-- leveling before pre-raid before raid, and a tank profile only for the tank role. Else automatic.
function Setup:GearForPlan(planId, role)
    local spec = planId and planId ~= "none" and self:PlanSpec(planId)
    if not spec then return false end
    local best, bestRank
    for _, p in ipairs(ns.Gear:ProfilesForClass(ns.Compat.PlayerInfo().class)) do
        if sameTree(p.spec, spec) then
            local rank = (CONTEXT_PICK[p.context] or 4) + (((p.role == "Tank") ~= (role == "tank")) and 10 or 0)
            if not bestRank or rank < bestRank then best, bestRank = p, rank end
        end
    end
    return best and best.id or false
end

local speedDungeonCache = {}
-- Distinct quests per dungeon in the Speed guides this character can follow: { [name] = n }.
function Setup:SpeedDungeonQuests()
    local info = ns.Compat.PlayerInfo()
    local key = tostring(info.faction) .. "/" .. tostring(info.race) .. "/" .. tostring(info.class) .. "/" .. #ns.Guides.list
    if speedDungeonCache[key] then return speedDungeonCache[key] end
    local seen, out = {}, {}
    for _, g in ipairs(ns.Guides:Filter({ faction = info.faction, race = info.race, class = info.class })) do
        for _, s in ipairs(g.steps) do
            if s.dungeon and s.q and not seen[s.q] and ns.Guides:StepApplies(s, info) then
                seen[s.q] = true
                out[s.dungeon] = (out[s.dungeon] or 0) + 1
            end
        end
    end
    speedDungeonCache[key] = out
    return out
end

-- Completionist routes every dungeon (Core/Completionist.lua CM:Routes); the selection only drives Speed.
-- Dungeons of the character's faction for a mode, in level order: { id, name, min, max, faction, quests,
-- supported, status, note }. Supported = the mode has quests for it; others are listed but cannot be picked.
function Setup:Dungeons(mode)
    local info = ns.Compat.PlayerInfo()
    local level = info.level or 1
    local cmCounts = ns.Completionist:DungeonQuestCounts(info.race, info.class)
    local counts = mode == "completionist" and cmCounts or self:SpeedDungeonQuests()
    local out = {}
    for _, d in ipairs(ns.DungeonsFor(info.faction)) do
        local n = counts[d.name] or 0
        local row = { id = d.name, name = d.name, min = d.min, max = d.max, faction = d.faction, quests = n, supported = n > 0 }
        if not row.supported then
            -- Greyed out in Speed only means the Speed guides lack its quests; say whether Completionist has them.
            local cm = cmCounts[d.name] or 0
            row.status = "unsupported"
            if mode == "completionist" then
                row.note = "No quests for it in the quest data"
            elseif cm > 0 then
                row.note = string.format("No quests for it in the Speed leveling guides. Completionist mode still routes its %d quest(s)", cm)
            else
                row.note = "No quests for it in the Speed leveling guides or in Completionist's quest data"
            end
        elseif level < d.min then
            row.status, row.note = "later", "planned for later: from level " .. d.min
        elseif level > d.max then
            row.status, row.note = "outleveled", "you are above its usual levels; its quests may give little XP"
        else
            row.status, row.note = "now", "right for your level"
        end
        out[#out + 1] = row
    end
    return out
end

-- Supported dungeons selected in a draft, in level order.
function Setup:SelectedDungeons(d)
    local out = {}
    for _, row in ipairs(self:Dungeons(d.mode)) do
        if row.supported and d.selected[row.id] then out[#out + 1] = row end
    end
    return out
end

-- Draft -------------------------------------------------------------------------------------------------

-- The character's current, confirmed configuration in draft form (prefills the wizard).
function Setup:Current()
    local c, prof = ns.char, ns.db.profile
    local CM = ns.Completionist
    local mode = CM:Mode()
    local guide = mode == "completionist" and c.speedGuide or c.activeGuide
    if not self:GuideValid(guide) then guide = self:RecommendedGuide() or false end
    local plan
    if c.noTalentPlan then plan = "none"
    else
        local b = ns.Talents:Get(c.talentBuild)
        if not (b and self:PlanValid(b.id)) then b = ns.Talents:ActiveBuild() end
        plan = b and self:PlanValid(b.id) and b.id or "none"
    end
    local r = self:Routing()
    local exclude = CM:State().exclude
    local dungeons, selected, elite
    if r then
        dungeons, selected, elite = r.dungeons, copy(r.selected), r.elite
    elseif mode == "completionist" then
        -- Completionist before setup: one switch for all dungeon quests, one for group quests.
        dungeons, elite, selected = exclude.dungeon and "questing" or "selected", not exclude.group, {}
        for _, d in ipairs(ns.Dungeons or {}) do selected[d.name] = true end
    else
        dungeons, elite, selected = prof.showDungeonSteps and "selected" or "questing", prof.showElite and true or false, {}
        local off = type(prof.dungeonOff) == "table" and prof.dungeonOff or {}
        for _, d in ipairs(ns.Dungeons or {}) do if not off[d.name] then selected[d.name] = true end end
    end
    local include = {}
    for _, k in ipairs(self.INCLUDE_KINDS) do include[k[1]] = not exclude[k[1]] end
    local helpers = {}
    for _, h in ipairs(self.HELPERS) do helpers[h.key] = prof[h.key] == true end
    local newPlayer
    if c.newPlayer ~= nil then newPlayer = c.newPlayer == true end
    return {
        newPlayer = newPlayer, helpers = helpers,
        mode = mode, guide = guide, hardcore = c.hardcore == true, plan = plan,
        gear = c.gearProfile and self:GearValid(c.gearProfile) and c.gearProfile or false,
        dungeons = dungeons, selected = selected, elite = elite, include = include,
        training = ns.Trainer:Mode(), autoTrain = ns.Trainer:AutoTrainMode(), autoEquip = prof.autoEquip == true, step = 1,
    }
end

-- Repairs a draft in place (missing fields, removed guides, other classes' plans, unknown dungeons) and
-- returns notes about anything that had to change.
function Setup:Sanitize(d)
    local notes = {}
    local cur
    local function current() cur = cur or self:Current() return cur end
    if d.mode ~= "speed" and d.mode ~= "completionist" then d.mode = "speed" end
    if d.guide ~= false and not self:GuideValid(d.guide) then
        if d.guide then notes[#notes + 1] = "The saved guide " .. tostring(d.guide) .. " no longer exists; the recommended guide was chosen instead." end
        d.guide = self:RecommendedGuide() or false
    end
    d.hardcore = d.hardcore == true
    if d.plan == nil then d.plan = current().plan
    elseif not self:PlanValid(d.plan) then
        notes[#notes + 1] = "The saved talent plan " .. tostring(d.plan) .. " is not available for this class in " .. ns.Target.name .. "; it was reset."
        d.plan = current().plan
    end
    if d.gear == nil then d.gear = current().gear
    elseif not self:GearValid(d.gear) then d.gear = false end
    if d.dungeons ~= "questing" and d.dungeons ~= "selected" then d.dungeons = current().dungeons end
    if type(d.selected) ~= "table" then d.selected = current().selected end
    local known = {}
    for _, x in ipairs(ns.Dungeons or {}) do known[x.name] = true end
    for name in pairs(d.selected) do
        if type(name) ~= "string" or not known[name] then
            d.selected[name] = nil
            notes[#notes + 1] = "The saved dungeon " .. tostring(name) .. " is not in " .. ns.Target.name .. "'s dungeon list and was removed."
        end
    end
    if d.elite == nil then d.elite = current().elite end
    d.elite = d.elite == true
    if type(d.include) ~= "table" then d.include = current().include end
    d.autoEquip = d.autoEquip == true
    if d.training ~= "important" and d.training ~= "all" and d.training ~= "off" then d.training = current().training end
    if d.autoTrain ~= "off" and d.autoTrain ~= "recommended" and d.autoTrain ~= "all" then d.autoTrain = current().autoTrain end
    if d.newPlayer ~= nil then d.newPlayer = d.newPlayer == true end
    if d.role ~= nil and not self:RoleInfo(d.role) then d.role = nil end
    if type(d.helpers) ~= "table" then d.helpers = current().helpers end
    for _, h in ipairs(self.HELPERS) do d.helpers[h.key] = d.helpers[h.key] == true end
    if type(d.step) ~= "number" or d.step < 1 or d.step > #self:Steps(d) then d.step = 1 end
    return notes
end

-- The draft being edited. An unfinished first setup resumes its saved draft; otherwise a draft is made from
-- the current configuration. `fresh` drops any saved draft first (Run Setup Again).
function Setup:Draft(fresh)
    local s = self:State()
    if fresh or type(s.draft) ~= "table" then s.draft = self:Current() end
    self.notes = self:Sanitize(s.draft)
    return s.draft
end

-- Draft edits that keep related choices consistent.
function Setup:SetPlan(d, planId)
    d.plan = planId
    if not d.gearTouched then d.gear = self:GearForPlan(planId, d.role) end
    if not d.gear then d.autoEquip = false end
end

function Setup:SetGear(d, id)
    d.gear, d.gearTouched = id, true
    if not id then d.autoEquip = false end
end

function Setup:SelectAllDungeons(d)
    for _, row in ipairs(self:Dungeons(d.mode)) do if row.supported then d.selected[row.id] = true end end
end

function Setup:ClearDungeons(d) d.selected = {} end

-- Validation --------------------------------------------------------------------------------------------

-- Errors (blocking) for one step or, without `step`, for the whole draft.
function Setup:Validate(d, step)
    local errs = {}
    local function check(id) return not step or step == id end
    -- Only the page itself insists on an answer; an unanswered draft is treated as experienced.
    if step == "welcome" and d.newPlayer == nil then errs[#errs + 1] = "Choose Yes or No." end
    if step == "build" and d.newPlayer and d.role == nil then errs[#errs + 1] = "Choose what you would like to do in a group, or I don't know yet." end
    if check("route") then
        local m = self:ModeInfo(d.mode)
        if not m then errs[#errs + 1] = "Choose a leveling mode."
        elseif not m.available then errs[#errs + 1] = m.name .. " is not available for this character. " .. (m.why or "")
        end
        if d.mode == "speed" and not self:GuideValid(d.guide) then errs[#errs + 1] = "Choose a starting guide." end
    end
    if check("build") then
        if not self:PlanValid(d.plan) then errs[#errs + 1] = "Choose a talent plan, or No talent guidance." end
        if not self:GearValid(d.gear) then errs[#errs + 1] = "The chosen gear profile is not for your class." end
    end
    if check("dungeons") and d.mode == "speed" and d.dungeons == "selected" and #self:SelectedDungeons(d) == 0 then
        errs[#errs + 1] = "Select at least one dungeon, or choose Questing only."
    end
    return #errs == 0, errs
end

-- Non-blocking notes for the review screen.
function Setup:Warnings(d)
    local out = {}
    for _, n in ipairs(self.notes or {}) do out[#out + 1] = n end
    if d.mode == "speed" and d.dungeons == "selected" then
        local skipped = 0
        for _, row in ipairs(self:Dungeons(d.mode)) do if not row.supported and d.selected[row.id] then skipped = skipped + 1 end end
        if skipped > 0 then out[#out + 1] = skipped .. " selected dungeon(s) have no quests in this mode and are not routed." end
    end
    if d.mode == "completionist" then
        out[#out + 1] = "Completionist coverage: quests the bundled data lacks, or whose giver or finisher has no position, are not routed (docs/COMPLETIONIST.md)."
    end
    local spec = self:PlanSpec(d.plan)
    local gp = d.gear and ns.Gear:ProfileById(d.gear)
    if gp and spec and gp.spec and not sameTree(gp.spec, spec) then
        out[#out + 1] = "Your gear profile (" .. gp.spec .. ") is for a different tree than your talent plan (" .. spec .. "); talent-window suggestions follow the gear profile."
    end
    return out
end

-- Finish ------------------------------------------------------------------------------------------------

-- Everything Finish may change, to put back if starting the route fails.
function Setup:Snapshot()
    local c, prof = ns.char, ns.db.profile
    return {
        mode = c.mode, activeGuide = c.activeGuide, speedGuide = c.speedGuide, hardcore = c.hardcore,
        talentBuild = c.talentBuild, noTalentPlan = c.noTalentPlan, gearProfile = c.gearProfile,
        routing = c.routing and copy(c.routing) or nil, exclude = copy(ns.Completionist:State().exclude),
        autoEquip = prof.autoEquip, training = c.trainerSuggestions, autoTrain = c.autoTrain,
        newPlayer = c.newPlayer, helpers = self:HelperValues(), groupFeatures = prof.groupFeatures,
    }
end

function Setup:HelperValues()
    local out = {}
    for _, h in ipairs(self.HELPERS) do out[h.key] = ns.db.profile[h.key] end
    return out
end

function Setup:Restore(snap)
    local c, prof = ns.char, ns.db.profile
    c.mode, c.speedGuide, c.hardcore = snap.mode, snap.speedGuide, snap.hardcore
    c.talentBuild, c.noTalentPlan, c.gearProfile = snap.talentBuild, snap.noTalentPlan, snap.gearProfile
    c.routing, c.trainerSuggestions, c.autoTrain = snap.routing, snap.training, snap.autoTrain
    ns.Completionist:State().exclude = snap.exclude
    prof.autoEquip = snap.autoEquip
    c.newPlayer, prof.groupFeatures = snap.newPlayer, snap.groupFeatures
    for k, v in pairs(snap.helpers or {}) do prof[k] = v end
    if snap.activeGuide and snap.activeGuide ~= ns.Completionist.GUIDE_ID and ns.Guides:Get(snap.activeGuide) then
        if c.activeGuide ~= snap.activeGuide then pcall(ns.Engine.Load, ns.Engine, snap.activeGuide) end
    elseif snap.activeGuide == ns.Completionist.GUIDE_ID and c.mode == "completionist" then
        pcall(ns.Completionist.Replan, ns.Completionist)
    end
    c.activeGuide = snap.activeGuide
end

-- Writes the draft's choices and starts the route. Returns true, or false and why.
function Setup:Apply(d)
    local c, prof = ns.char, ns.db.profile
    local CM = ns.Completionist
    if ns.Target.hardcore and not ns.TargetCheck.HardcoreRealm() then c.hardcore = d.hardcore end
    c.talentBuild = d.plan ~= "none" and d.plan or nil
    c.noTalentPlan = d.plan == "none" or nil
    c.gearProfile = d.gear or nil
    c.routing = { dungeons = d.dungeons, selected = copy(d.selected), elite = d.elite }
    c.trainerSuggestions = d.training
    c.autoTrain = d.autoTrain
    ns.Trainer.skipCache = nil
    local ex = CM:State().exclude
    for _, k in ipairs(self.INCLUDE_KINDS) do ex[k[1]] = not d.include[k[1]] end
    prof.autoEquip = (d.autoEquip and d.gear and ns.Upgrade:ActiveProfile()) and true or false
    if d.newPlayer ~= nil then c.newPlayer = d.newPlayer end
    for _, h in ipairs(self:Helpers()) do prof[h.key] = d.helpers[h.key] == true end
    if d.helpers.playTogether then prof.groupFeatures = true end
    if d.mode == "completionist" then
        local ok, why = CM:Available()
        if not ok then return false, "Completionist is not available: " .. why end
        if not CM:SetMode("completionist") then return false, "the Completionist route could not be planned." end
        if d.guide then c.speedGuide = d.guide end
    else
        if not self:GuideValid(d.guide) then return false, "the chosen guide no longer exists." end
        c.mode = "speed"
        if c.activeGuide ~= d.guide or not ns.Engine.guide or ns.Engine.guide.id ~= d.guide then
            -- Loaded with its saved progress; steps already done in the game count as done (quest flags).
            if not ns.Engine:Load(d.guide) then return false, "the guide " .. tostring(d.guide) .. " could not be loaded." end
        else
            ns.Engine:Refresh()
        end
    end
    if ns.AutoEquip then ns.AutoEquip:OnProfileChanged() end
    if ns.TalentHints and ns.TalentHints.Refresh then ns.TalentHints:Refresh() end
    if ns.Config and ns.Config.Rebuild then ns.Config:Rebuild() end
    if ns.NewPlayer then ns.NewPlayer:OnStep() end
    return true
end

-- Validates and applies the draft; setup is marked done only when the route started. Returns ok, message.
function Setup:Finish(d)
    local s = self:State()
    d = d or self:Draft()
    local ok, errs = self:Validate(d)
    if not ok then return false, errs[1] end
    local snap = self:Snapshot()
    local good, res, why = pcall(self.Apply, self, d)
    if not good or not res then
        self:Restore(snap)
        local msg = "Setup was not finished: " .. tostring(good and why or res)
        s.lastError = msg
        return false, msg
    end
    s.done, s.version, s.draft, s.legacy, s.lastError = true, self.VERSION, nil, nil, nil
    s.at = time and time() or 0
    self.dismissed = nil
    return true, "Setup saved."
end

-- Set Up Later / closing the window: nothing is applied. A first setup keeps its draft for next time;
-- a re-run of setup is simply cancelled. The wizard does not reopen by itself again this session.
function Setup:Postpone()
    local s = self:State()
    if s.done then s.draft = nil end
    self.dismissed = true
end

-- One-line summaries for the review screen and /qw setup status.
function Setup:Summary(d)
    local ch = self:Character()
    local lines = {}
    lines[#lines + 1] = string.format("Character: %s, level %d %s %s (%s), %s.", tostring(ch.name), ch.level, tostring(ch.raceName), tostring(ch.className), tostring(ch.faction), ch.game)
    if d.newPlayer ~= nil then lines[#lines + 1] = "New to World of Warcraft: " .. (d.newPlayer and "yes" or "no") .. "." end
    lines[#lines + 1] = "Mode: " .. (self.MODE_NAMES[d.mode] or d.mode) .. "."
    local g = d.guide and ns.Guides:Get(d.guide)
    if d.mode == "speed" then
        lines[#lines + 1] = "Starting guide: " .. (g and g.name or "none") .. "."
    elseif g then
        lines[#lines + 1] = "Speed guide kept for switching back: " .. g.name .. "."
    end
    if ns.Target.hardcore then
        lines[#lines + 1] = "Hardcore route: " .. ((d.hardcore or ch.hardcoreRealm) and "yes" or "no") .. (ch.hardcoreRealm and " (Hardcore realm)" or "") .. "."
    end
    local b = d.plan ~= "none" and ns.Talents:Get(d.plan)
    lines[#lines + 1] = "Talent plan: " .. (b and b.name or "No talent guidance") .. " (a plan only; your learned talents are not changed)."
    local gp = d.gear and ns.Gear:ProfileById(d.gear)
    lines[#lines + 1] = "Gear profile: " .. (gp and ns.Upgrade:ProfileName(gp) or "Automatic") .. "."
    if d.mode == "completionist" then
        local n, k = 0, 0
        for _, row in ipairs(self:Dungeons("completionist")) do if row.supported then n, k = n + row.quests, k + 1 end end
        lines[#lines + 1] = string.format("Dungeons: all of them (Completionist routes every dungeon: %d quests in %d dungeons). Your Speed dungeon selection is kept for Speed.", n, k)
    elseif d.dungeons == "selected" then
        local names = {}
        for _, row in ipairs(self:SelectedDungeons(d)) do names[#names + 1] = row.name end
        lines[#lines + 1] = "Dungeons: " .. (#names > 0 and table.concat(names, ", ") or "none selected") .. "."
    else
        lines[#lines + 1] = "Dungeons: questing only (no dungeon runs are routed)."
    end
    lines[#lines + 1] = "Group and elite quests: " .. (d.elite and "routed" or "not routed") .. "."
    if d.mode == "completionist" then
        local on = {}
        for _, k in ipairs(self.INCLUDE_KINDS) do if d.include[k[1]] then on[#on + 1] = string.lower(k[2]) end end
        lines[#lines + 1] = "Also routed: " .. (#on > 0 and table.concat(on, ", ") or "nothing else") .. "."
    end
    lines[#lines + 1] = "Class training suggestions: " .. (self.TRAINING_NAMES[d.training] or d.training) .. "."
    lines[#lines + 1] = "Automatic training: " .. (self.AUTOTRAIN_NAMES[d.autoTrain] or d.autoTrain) .. "."
    lines[#lines + 1] = "Automatic upgrades: " .. (d.autoEquip and d.gear and "on" or "off") .. "."
    local on = {}
    for _, h in ipairs(self:Helpers()) do if d.helpers[h.key] then on[#on + 1] = string.lower(h.name) end end
    lines[#lines + 1] = "Helpers: " .. (#on > 0 and table.concat(on, ", ") or "none") .. "."
    return lines
end

-- Settings window access to the routing choices: a character that confirmed setup edits its own record;
-- others edit the settings profile as before.
function Setup:DungeonsOn()
    local r = self:Routing()
    if r then return r.dungeons == "selected" end
    return ns.db.profile.showDungeonSteps and true or false
end

function Setup:SetDungeonsOn(on)
    local r = self:Routing()
    if r then r.dungeons = on and "selected" or "questing" else ns.db.profile.showDungeonSteps = on and true or false end
    if ns.Engine.guide then ns.Engine:Refresh() end
end

function Setup:DungeonSelected(name)
    local r = self:Routing()
    if r then return r.selected[name] == true end
    local off = ns.db.profile.dungeonOff
    return not (type(off) == "table" and off[name])
end

function Setup:SetDungeonSelected(name, on)
    local r = self:Routing()
    if r then r.selected[name] = on and true or nil
    else
        local p = ns.db.profile
        if type(p.dungeonOff) ~= "table" then p.dungeonOff = {} end
        p.dungeonOff[name] = (not on) or nil
    end
    if ns.Engine.guide then ns.Engine:Refresh() end
end

function Setup:SetElite(on)
    local r = self:Routing()
    if r then r.elite = on and true or false else ns.db.profile.showElite = on and true or false end
    if ns.Engine.guide then ns.Engine:Refresh() end
end
