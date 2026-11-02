-- Questwarden - guide progression engine
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- This program is free software: you can redistribute it and/or modify it under the terms of the
-- GNU General Public License as published by the Free Software Foundation, version 3.
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
-- even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details. The complete license text is in LICENSE.
--
-- Step states: "done", "skipped", "active", "pending", "na" (not for this character).
-- A pending step can also be waiting (Engine.waiting[i]): the pickup of a quest that starts from a dropped
-- item lets the later steps that kill its droppers go first (Core/ItemStarts.lua). It stays "pending" for
-- everything else (quest automation, vendors, markers); only the choice of the current step passes it by.
-- An [iffound] quest (an item many mobs drop, rarely) is "na" until its item is in your bags or the quest is in
-- your log: hidden and not counted, never waited for or farmed.
-- Kill packs: objective steps whose mobs spawn in the same area share a pack (s.pack = the pack's first step,
-- compiled by GuideCompiler.LinkKillPacks). When the current step is in one, the pack's other open steps are
-- "active" too: shown as current, and their mobs targeted and marked (Engine:PackSteps).
-- Completion rules per step type are in COMPLETERS below. Rules only use reliable signals
-- (quest flags, quest log, level, bind location, explicit UI messages). Anything else waits for
-- the player to click the step (manual confirmation) - the engine never guesses.

local _, ns = ...

local Engine = { guide = nil, current = nil, status = {}, autoReason = {}, waiting = {} }
ns.Engine = Engine

local T -- tracker, set in Init

local function info() return ns.Compat.PlayerInfo() end

-- Returns true when the step's completion signal is present.
local COMPLETERS = {
    accept = function(s) return T:InLog(s.q) or T:IsTurnedIn(s.q) end,
    turnin = function(s) return T:IsTurnedIn(s.q) end,
    complete = function(s)
        if T:IsTurnedIn(s.q) then return true end
        if s.obj then return T:ObjectiveDone(s.q, s.obj) end
        return T:IsComplete(s.q)
    end,
    level = function(s) return (UnitLevel("player") or 1) >= (s.level or 1) end,
    -- The step's [area=] names in the client's language (Core/Bind.lua), or a bind Questwarden verified.
    bind = function(s) return ns.Bind:IsBoundFor(s) end,
    -- Completionist's run step: done when you are inside that dungeon (Core/DungeonRun.lua).
    dungeon = function(s) return ns.DungeonRun:Current() == s.dungeon end,
}
-- A grind step ends when the player reaches s.level, and with s.pct also that percent of the way
-- through it. (UnitXP only counts XP into the current level, so any higher level counts as reached.)
COMPLETERS.grind = function(s)
    local lvl, need = UnitLevel("player") or 1, s.level or 1
    if lvl ~= need or not s.pct then return lvl >= need end
    local xp, maxXp = UnitXP("player") or 0, UnitXPMax("player") or 0
    return maxXp > 0 and xp * 100 >= s.pct * maxXp
end

-- Steps whose completion is remembered once observed (cannot be re-derived later).
local STICKY = { ["goto"] = true, note = true, train = true, fp = true, fly = true, hs = true, travel = true,
                 talk = true, buy = true, use = true, collect = true, bind = true, level = true, grind = true,
                 dungeon = true }

function Engine:Init()
    T = ns.Tracker
    ns:Listen("QUESTS_CHANGED", function() Engine:Refresh() end)
    ns:On("PLAYER_LEVEL_UP", function() C_Timer.After(0.5, function() Engine:Refresh() end) end)
    ns:On("PLAYER_XP_UPDATE", function() -- only a grind step to a percent of a level needs XP
        local s = Engine:CurrentStep()
        if s and s[1] == "grind" and s.pct then Engine:Refresh() end
    end)
    ns:On("ZONE_CHANGED_NEW_AREA", function() Engine:OnZoneChanged() end)
    ns:On("ZONE_CHANGED", function() Engine:OnZoneChanged() end)
    ns:On("PLAYER_CONTROL_GAINED", function() Engine:OnZoneChanged() end) -- landing after a flight
    ns:On("UI_INFO_MESSAGE", function(_, a, b) Engine:OnInfoMessage(type(b) == "string" and b or a) end)
    ns:On("TAXIMAP_OPENED", function() Engine:CompleteCurrentOfType("fp") end)
    ns:On("TRAINER_CLOSED", function() Engine:CompleteCurrentOfType("train") end)
    ns:On("MERCHANT_CLOSED", function() Engine:CompleteCurrentOfType("buy") end)
end

function Engine:Load(guideId, opts)
    local g = ns.Guides:Get(guideId)
    if not g then
        ns:Print("Unknown guide: " .. tostring(guideId))
        return false
    end
    self.guide = g
    self.forced = nil
    self.current = nil
    self.status = {}
    self.autoReason = {}
    ns.char.activeGuide = g.id
    local hist = ns.char.history
    for i = #hist, 1, -1 do if hist[i] == g.id then table.remove(hist, i) end end
    table.insert(hist, 1, g.id)
    while #hist > 15 do table.remove(hist) end
    if opts and opts.reset then ns:ResetProgress(g.id) end
    self.progress = ns:GetProgress(g.id)
    self:Refresh(true)
    ns:Fire("GUIDE_CHANGED", g)
    return true
end

-- Whether the steps of dungeon `name` are left out: all dungeons off, or this one deselected. A character
-- that confirmed setup has its own choice (ns.char.routing, Core/Setup.lua); others use the settings profile.
function Engine:DungeonOff(name)
    -- Completionist's generated segments route every dungeon (docs/COMPLETIONIST.md).
    if self.guide and self.guide.dynamic then return false end
    local r = ns.Setup:Routing()
    if r then return r.dungeons ~= "selected" or not r.selected[name] end
    local prof = ns.db.profile
    if not prof.showDungeonSteps then return true end
    return type(prof.dungeonOff) == "table" and prof.dungeonOff[name] == true
end

-- Whether [elite]/[group] steps are in the route (per character after setup, as above).
function Engine:EliteOn()
    local r = ns.Setup:Routing()
    if r then return r.elite == true end
    return ns.db.profile.showElite and true or false
end

-- Whether quest q can only be taken after a dungeon quest that is excluded right now: one of its
-- required prerequisites, or every one of its alternative prerequisites, is excluded and not done.
function Engine:NeedsExcluded(q)
    local rec = ns.DB.GetQuestByID(q)
    if not rec then return false end
    local ex = self.excludedDungeon
    for _, p in ipairs(rec.preGroup or {}) do
        if ex[p] and not T:IsTurnedIn(p) then return true end
    end
    local single = rec.preSingle or {}
    if #single == 0 then return false end
    for _, p in ipairs(single) do
        if not ex[p] or T:IsTurnedIn(p) then return false end
    end
    return true
end

-- A quest is grey (little or no XP) when the player is more than GetQuestGreenRange() levels above
-- it; without that API the TBC value for most levels (8) is used.
function Engine:IsGrey(q)
    local lvl = ns.DB.GetQuestLevel(q)
    if not lvl or lvl <= 0 then return false end
    local range = GetQuestGreenRange and GetQuestGreenRange() or 8
    return (UnitLevel("player") or 1) - lvl > range
end

-- Whether a quest step should be skipped automatically for this character, and why.
function Engine:AutoSkipReason(s, ctx)
    if ns.db.profile.disableStepSkips then return nil end
    if s[1] == "train" and ns.Trainer then return ns.Trainer:SkipReason() end
    if not s.q then return nil end
    -- A quest that is complete in your log is always turned in, whatever its level.
    if s[1] == "turnin" and T:InLog(s.q) and T:IsComplete(s.q) then return nil end
    if s[1] == "accept" then
        if T:IsTurnedIn(s.q) then return nil end -- counts as done, not skipped
        -- Below the quest's required level: skip it instead of blocking the guide. It comes back if
        -- you reach the level before doing anything after it; once you have moved on it stays
        -- skipped, so the guide never sends you back for it.
        local lp = self.progress and self.progress.levelSkip
        if lp and lp[s.index] and not T:InLog(s.q) and (self.maxDone or 0) > (s.index or 0) then
            return "passed while below the required level"
        end
        local ok, why, req = ns.DB.IsQuestAvailable(s.q, ctx)
        if not ok and why == "level" and not T:InLog(s.q) then
            if self.progress then
                self.progress.levelSkip = self.progress.levelSkip or {}
                self.progress.levelSkip[s.index] = true
            end
            return "needs level " .. tostring(req) .. "; picked up if you reach it before moving on"
        end
        if not ok and (why == "race" or why == "class" or why == "exclusive" or why == "too high level") then
            return "not available (" .. why .. ")"
        end
        if ns.db.profile.skipOverleveled and not T:InLog(s.q) and self:IsGrey(s.q) and not (self.prereqOf and self.prereqOf[s.q]) then
            return "grey quest for your level"
        end
        if self.excludedDungeon and next(self.excludedDungeon) and not T:InLog(s.q) and self:NeedsExcluded(s.q) then
            return "needs a dungeon quest (Include Dungeon Quests is off)"
        end
    elseif s[1] == "turnin" or s[1] == "complete" then
        -- A dungeon quest in your log whose run is not planned (dungeon not selected) or whose run step you
        -- skipped: its objective and turn-in step aside until the quest is complete, so questing goes on.
        -- Nothing is marked done; the turn-in comes back by itself once the quest log says complete.
        if s.dungeon and T:InLog(s.q) and not T:IsComplete(s.q) then
            if self:DungeonOff(s.dungeon) then return "dungeon not selected; turn it in once the quest is complete" end
            local ci = s[1] == "turnin" and self.completeIndex and self.completeIndex[s.q]
            if ci and self.status[ci] == "skipped" then return "dungeon run skipped; the turn-in comes back when the quest is complete" end
        end
        if not T:InLog(s.q) and not T:IsTurnedIn(s.q) then
            -- The player never picked it up (or abandoned it). If the matching accept step was
            -- skipped / not applicable, skip this too rather than blocking the route.
            local acc = self.acceptIndex and self.acceptIndex[s.q]
            if acc then
                local st = self.status[acc]
                if st == "skipped" or st == "na" then return "quest was skipped" end
            elseif not self.acceptIndex or not self.acceptIndex[s.q] then
                -- Accepted in an earlier guide: only block if the DB says the player could have it.
                local ok, why = ns.DB.IsQuestAvailable(s.q, ctx)
                if not ok and (why == "race" or why == "class") then return "not available (" .. why .. ")" end
                -- Optional pick-ups from an earlier guide (breadcrumbs): if the quest log has been
                -- read and the quest is not there, the player never took it. Re-evaluated on every
                -- refresh, never saved, so a late quest log scan cannot skip it for good.
                if s.optional and T.lastScan > 0 then return "not in your quest log" end
            end
        end
    end
    return nil
end

function Engine:Refresh(silent)
    local g = self.guide
    if not g then return end
    local p = self.progress
    local ctx = T:Context()
    local prof = ns.db.profile
    self.acceptIndex, self.completeIndex = {}, {}
    for i, s in ipairs(g.steps) do
        if s[1] == "accept" and s.q then self.acceptIndex[s.q] = i end
        if s[1] == "complete" and s.q then self.completeIndex[s.q] = i end
    end
    -- Dungeon quests left out by "Include Dungeon Quests" (never ones already in the log).
    -- A single dungeon can also be switched off (Guide Routing -> Dungeons).
    self.excludedDungeon = {}
    for _, s in ipairs(g.steps) do
        if s.dungeon and s.q and self:DungeonOff(s.dungeon) and not T:InLog(s.q) and not T:IsTurnedIn(s.q) then
            self.excludedDungeon[s.q] = true
        end
    end
    -- Quests that unlock another quest of this guide are never skipped as grey (the chain needs them).
    if self.prereqGuide ~= g then
        self.prereqGuide, self.prereqOf = g, {}
        for _, s in ipairs(g.steps) do
            if s[1] == "accept" and s.q then
                local q = ns.DB.GetQuestByID(s.q)
                if q then
                    for _, p in ipairs(q.preGroup or {}) do self.prereqOf[p] = true end
                    for _, p in ipairs(q.preSingle or {}) do self.prereqOf[p] = true end
                end
            end
        end
    end

    -- Highest step you have marked done (level-skipped pickups behind it stay skipped).
    self.maxDone = 0
    for i in pairs(p.done) do if type(i) == "number" and i > self.maxDone then self.maxDone = i end end

    local firstOpen
    for i, s in ipairs(g.steps) do
        local st
        if not ns.Guides:StepApplies(s, ctx) then
            st = "na"
        elseif (s.dungeon and self:DungeonOff(s.dungeon) and not (s.q and T:InLog(s.q))) or (s.elite and not self:EliteOn())
            or (s.optional and prof.speedRoute)
            or (s.hcSkip and ns:IsHardcore()) or (s.hcOnly and not ns:IsHardcore()) then
            st = "na"
        elseif s.ifFound and s.q and not T:InLog(s.q) and not T:IsTurnedIn(s.q)
            and not (s[1] == "accept" and s.starter and ns.ItemStarts and ns.ItemStarts:Has(s.starter)) then
            st = "na"
        elseif p.skipped[i] and not (s.starter and s.q and (T:InLog(s.q) or T:IsTurnedIn(s.q))) then
            -- (A skipped item-started pickup counts as done once you take the quest after all.)
            st = "skipped"
        elseif p.done[i] then
            st = "done"
        else
            local fn = COMPLETERS[s[1]]
            if fn and fn(s) then
                st = "done"
                if STICKY[s[1]] then p.done[i] = true end
            else
                local why = self:AutoSkipReason(s, ctx)
                if why then
                    st = "skipped"
                    self.autoReason[i] = why
                else
                    st = "pending"
                end
            end
        end
        self.status[i] = st
    end

    -- Item-started pickups wait for their kill steps (Core/ItemStarts.lua), and so do the objective and
    -- turn-in steps of those quests while the quest is not in your log.
    self.waiting = {}
    local IS = ns.ItemStarts
    if IS then
        for i, s in ipairs(g.steps) do
            if self.status[i] == "pending" and s[1] == "accept" and IS:Waits(s, self.status) then self.waiting[i] = true end
        end
        if next(self.waiting) then
            for i, s in ipairs(g.steps) do
                if self.status[i] == "pending" and (s[1] == "complete" or s[1] == "turnin") and s.q
                    and not T:InLog(s.q) and not T:IsTurnedIn(s.q) then
                    local a = self.acceptIndex[s.q]
                    if a and self.waiting[a] then self.waiting[i] = true end
                end
            end
        end
    end
    local firstWaiting
    for i in ipairs(g.steps) do
        if self.status[i] == "pending" then
            if not self.waiting[i] then firstOpen = i break end
            firstWaiting = firstWaiting or i
        end
    end
    -- Only waiting steps left (their kill steps are themselves waiting): take the first, never "finished".
    firstOpen = firstOpen or firstWaiting
    firstOpen = self:TimedFirst(firstOpen)

    if self.forced and (not firstOpen or self.forced < firstOpen) then
        firstOpen = self.forced
        if self.status[firstOpen] ~= "pending" then self.status[firstOpen] = "pending" end
    else
        self.forced = nil
    end
    local old = self.current
    self.current = firstOpen
    if firstOpen then
        self.status[firstOpen] = "active"
        p.step = firstOpen
        local pack = g.steps[firstOpen].pack
        if pack then
            for i = firstOpen + 1, #g.steps do
                if g.steps[i].pack ~= pack then break end
                -- Only quests you have: an objective step whose quest you have not picked up yet waits.
                if self.status[i] == "pending" and not self.waiting[i] and not (g.steps[i].q and not T:InLog(g.steps[i].q)) then
                    self.status[i] = "active"
                end
            end
        end
    end
    if not firstOpen then
        p.step = #g.steps + 1
        if old and not silent then self:OnGuideFinished() end
    end
    if old ~= self.current then ns:Fire("STEP_CHANGED", self.current, old) end
    ns:Fire("REFRESH")
end

-- A timed quest in your log comes first (Core/QuestTimer.lua): its next open objective or turn-in step becomes
-- current, unless only turn-ins and travel lie before it (on the way). The steps passed over stay open and come
-- back once it is done. The guides already put these steps first; this covers a quest taken out of order.
local NOT_ON_THE_WAY = { accept = true, complete = true, grind = true, level = true, dungeon = true }
function Engine:TimedFirst(firstOpen)
    local QT, g = ns.QuestTimer, self.guide
    if not (firstOpen and QT and ns.QuestTimers and next(ns.QuestTimers)) then return firstOpen end
    for j = firstOpen, #g.steps do
        local s = g.steps[j]
        if self.status[j] == "pending" and not self.waiting[j] and s.q and (s[1] == "complete" or s[1] == "turnin")
            and QT:Running(s.q) then
            for i = firstOpen, j - 1 do
                if self.status[i] == "pending" and not self.waiting[i] and NOT_ON_THE_WAY[g.steps[i][1]] then return j end
            end
            return firstOpen
        end
    end
    return firstOpen
end

function Engine:OnGuideFinished()
    local g = self.guide
    -- A finished Completionist segment plans the next one (Core/Completionist.lua).
    if g and g.dynamic and ns.Completionist and ns.Completionist:OnSegmentFinished() then return end
    local nextG = ns.Selector:NextAfter(g, info())
    if nextG then
        ns:Print("Guide complete: " .. g.name .. ". Next: " .. nextG.name)
        if ns.db.profile.autoAdvance then
            C_Timer.After(1, function() Engine:Load(nextG.id) end)
        end
    else
        ns:Print("Guide complete: " .. g.name .. ". Open /" .. ns.slash .. " guide to choose the next guide.")
    end
end

-- Manual controls -------------------------------------------------------------------------------

function Engine:MarkDone(i)
    if not self.guide then return end
    i = i or self.current
    if not i then return end
    self.forced = nil
    self.progress.done[i] = true
    self.progress.skipped[i] = nil
    self:Refresh()
end

function Engine:Skip(i)
    if not self.guide then return end
    i = i or self.current
    if not i then return end
    self.forced = nil
    self.progress.skipped[i] = true
    self:Refresh()
end

-- /cg next: complete (manual) the current step.
function Engine:Next() self:MarkDone() end

-- /cg prev: reopen the most recent done/skipped step before the current one.
function Engine:Prev()
    if not self.guide then return end
    local from = (self.current or (#self.guide.steps + 1)) - 1
    for i = from, 1, -1 do
        local st = self.status[i]
        if st == "done" or st == "skipped" then
            self.progress.done[i] = nil
            self.progress.skipped[i] = nil
            self.autoReason[i] = nil
            -- Quest-derived completions cannot be undone, so the step is shown as current until
            -- the player advances again (Refresh honours self.forced).
            self.forced = i
            self:Refresh()
            return
        end
    end
end

function Engine:Reset()
    if not self.guide then return end
    ns:ResetProgress(self.guide.id)
    self.progress = ns:GetProgress(self.guide.id)
    self.autoReason = {}
    self:Refresh(true)
    ns:Print("Progress reset for " .. self.guide.name)
end

function Engine:CompleteCurrentOfType(kind)
    local s = self:CurrentStep()
    if s and s[1] == kind then self:MarkDone(self.current) end
end

function Engine:CurrentStep()
    return self.guide and self.current and self.guide.steps[self.current]
end

-- Zone-based completion for travel steps (fly/hs/travel/goto-zone). A fly step with a flight node
-- (Database/Flights.lua) also completes in the node's zone. Several steps can complete at once:
-- landing finishes "fly Auberdine" and the "travel Darkshore" after it.
function Engine:OnZoneChanged()
    local zone = string.lower(ns.Compat.GetZoneText() or "")
    local sub = string.lower(GetSubZoneText and GetSubZoneText() or "")
    for _ = 1, 3 do
        local s = self:CurrentStep()
        if not (s and (s[1] == "fly" or s[1] == "hs" or s[1] == "travel") and s.dest) then return end
        local dest = string.lower(s.dest)
        local node = s[1] == "fly" and s.node and ns.Flights and ns.Flights.nodes[s.node]
        local nodeZone = node and ns.DB.ZoneName(node.zone)
        if not (zone == dest or sub == dest or (nodeZone and zone == string.lower(nodeZone))) then return end
        self:MarkDone(self.current)
    end
end

local NEW_FP = ERR_NEWTAXIPATH or "New flight path discovered!"
function Engine:OnInfoMessage(msg)
    if msg == NEW_FP then self:CompleteCurrentOfType("fp") end
end

-- Progress summary for the UI.
function Engine:Counts()
    local done, total = 0, 0
    if not self.guide then return 0, 0 end
    -- A skipped step counts once you are past it, or when you skipped it yourself. Steps ahead of you that are
    -- only skipped for now (e.g. "needs level N", picked up if you reach it) are not progress yet.
    local cur = self.current or math.huge
    local manual = self.progress and self.progress.skipped or {}
    for i = 1, #self.guide.steps do
        local st = self.status[i]
        if st ~= "na" then
            total = total + 1
            if st == "done" or (st == "skipped" and (i < cur or manual[i])) then done = done + 1 end
        end
    end
    return done, total
end

-- The current step and the open steps of its kill pack (just the current step when it has none).
function Engine:PackSteps()
    local out = {}
    if not self.guide or not self.current then return out end
    out[1] = self.current
    local steps, pack = self.guide.steps, self.guide.steps[self.current].pack
    if not pack then return out end
    for i = self.current + 1, #steps do
        if steps[i].pack ~= pack then break end
        if self.status[i] == "active" then out[#out + 1] = i end
    end
    return out
end

-- Next N open steps starting at the current one (for display); the whole current kill pack even when it is longer.
function Engine:Upcoming(n)
    local out = {}
    if not self.guide or not self.current then return out end
    n = math.max(n, #self:PackSteps())
    for i = self.current, #self.guide.steps do
        local st = self.status[i]
        if st == "active" or (st == "pending" and not self.waiting[i]) then
            out[#out + 1] = i
            if #out >= n then break end
        end
    end
    return out
end
