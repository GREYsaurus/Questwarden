-- Questwarden - play together: party members' guide steps, "wait for" hints and following the leader
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- This program is free software: you can redistribute it and/or modify it under the terms of the
-- GNU General Public License as published by the Free Software Foundation, version 3.
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
-- even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details. The complete license text is in LICENSE.
--
-- Settings (off by default): playTogether, playFollowLeader; both also need Enable Group Settings.
-- While in a party (never a raid), each member who runs Questwarden sends its guide and step in a hidden add-on
-- message ("P:<guide>|<step>|<label>") when the step changes, when the party changes and once a minute. The
-- guide window then shows where the others are: on the same guide, how many steps ahead or behind; behind on
-- this step's quest, "wait for <name>". Follow the leader: when the party leader's guide or step changes, this
-- character loads the same guide and goes to the same step. Going back shows that step as current (your later
-- progress is kept); going forward marks the steps in between skipped (/qw prev reopens them). /qw follow does
-- the same once, with or without the setting. Nothing is sent to chat.

local _, ns = ...

local PT = { members = {}, lastSent = nil, leaderSeen = {} }
ns.PlayTogether = PT

local TAG = "P"
local STALE = 300      -- seconds: a member we have not heard from for this long is no longer shown
local RESEND = 60      -- seconds between repeats while grouped

local function prof() return ns.db.profile end
local function inParty()
    local raid = IsInRaid and IsInRaid()
    local group = (IsInGroup and IsInGroup()) or (GetNumGroupMembers and GetNumGroupMembers() > 0)
    return group and not raid
end

function PT:Enabled() return prof().groupFeatures and prof().playTogether and true or false end

-- Party member names in party order.
local function partyNames()
    local out = {}
    for i = 1, 4 do
        local u = "party" .. i
        local name = UnitExists and UnitExists(u) and UnitName and UnitName(u)
        if name then out[#out + 1] = { name = name, unit = u } end
    end
    return out
end

local function clean(s) return (string.gsub(tostring(s or ""), "[|\n]", " ")) end

-- The message for our current step, or nil without a guide.
function PT:Payload()
    local E = ns.Engine
    local s = E and E.guide and E:CurrentStep()
    if not s then return nil end
    local label = s.title or (s.q and ns.DB.GetQuestName(s.q)) or s.text or s[1]
    label = clean(s[1] .. " " .. tostring(label)):sub(1, 80)
    return E.guide.id .. "|" .. tostring(E.current) .. "|" .. label
end

function PT:Send(force)
    if not (self:Enabled() and inParty()) then return end
    local p = self:Payload()
    if not p or (p == self.lastSent and not force) then return end
    self.lastSent = p
    ns.Group:Send(TAG, p, "PARTY")
end

function PT:OnMessage(name, payload)
    local guide, step, label = string.match(payload or "", "^([^|]+)|(%d+)|(.*)$")
    if not guide then return end
    local m = { guide = guide, step = tonumber(step), label = label, t = GetTime and GetTime() or 0 }
    local old = self.members[name]
    self.members[name] = m
    if not old or old.guide ~= m.guide or old.step ~= m.step then ns:Fire("REFRESH") end
    if self:IsLeader(name) and prof().playFollowLeader and self:Enabled() then self:Follow(name, true) end
end

function PT:IsLeader(name)
    local u = ns.Group:LeaderUnit()
    return u ~= nil and UnitName and UnitName(u) == name
end

-- Known party members (still in the party, heard from recently): { name, guide, step, label }.
function PT:Members()
    local out, now = {}, GetTime and GetTime() or 0
    for _, p in ipairs(partyNames()) do
        local m = self.members[p.name]
        if m and now - m.t <= STALE then
            out[#out + 1] = { name = p.name, guide = m.guide, step = m.step, label = m.label, leader = self:IsLeader(p.name) }
        end
    end
    return out
end

-- Lines for the guide window under the current step (UI via Core/StepText.lua).
function PT:Lines()
    if not (self:Enabled() and inParty()) then return {} end
    local E = ns.Engine
    local s = E and E.guide and E:CurrentStep()
    if not s then return {} end
    local out = {}
    for _, m in ipairs(self:Members()) do
        local who = m.name .. (m.leader and " (leader)" or "")
        if m.guide ~= E.guide.id then
            local g = ns.Guides:Get(m.guide)
            out[#out + 1] = { text = who .. " is on another guide" .. (g and (" (" .. g.name .. ")") or "") .. ": " .. m.label }
        elseif m.step == E.current then
            out[#out + 1] = { text = who .. " is on this step too." }
        elseif m.step < E.current then
            local n = E.current - m.step
            local wait = (s[1] == "turnin" or s[1] == "accept" or s[1] == "fly" or s[1] == "hs") and "Wait for " .. who .. ": " or ""
            out[#out + 1] = { text = wait .. who .. " is " .. n .. " step" .. (n == 1 and "" or "s") .. " behind: " .. m.label, warn = wait ~= "" }
        else
            local n = m.step - E.current
            out[#out + 1] = { text = who .. " is " .. n .. " step" .. (n == 1 and "" or "s") .. " ahead: " .. m.label }
        end
    end
    return out
end

-- Goes to the guide and step `name` (the leader by default) is on. auto: only when the leader's step changed.
function PT:Follow(name, auto)
    local E = ns.Engine
    if not name then
        local u = ns.Group:LeaderUnit()
        name = u and UnitName and UnitName(u)
    end
    local m = name and self.members[name]
    if not m then
        if not auto then ns:Print("No party leader running " .. ns.name .. " with play-together on has been heard from yet.") end
        return false
    end
    local key = m.guide .. ":" .. m.step
    if auto and self.leaderSeen[name] == key then return false end
    self.leaderSeen[name] = key
    if not (E.guide and E.guide.id == m.guide) then
        if not ns.Guides:Get(m.guide) or not E:Load(m.guide) then
            ns:Print(name .. "'s guide is not available for this character.")
            return false
        end
        ns:Print("Following " .. name .. ": loaded their guide.")
    end
    local target = m.step
    if not (E.guide.steps[target]) or E.current == target then return true end
    if E.current and target < E.current then
        E.forced = target
        E:Refresh()
        ns:Print("Following " .. name .. ": back to step " .. target .. ". Your progress after it is kept.")
    else
        local n = 0
        for i = (E.current or 1), target - 1 do
            local st = E.status[i]
            if st == "active" or st == "pending" then E.progress.skipped[i] = true n = n + 1 end
        end
        E.forced = nil
        E:Refresh()
        if n > 0 then ns:Print("Following " .. name .. ": skipped " .. n .. " step(s) to catch up. /" .. ns.slash .. " prev reopens them.") end
    end
    return true
end

function PT:Init()
    ns.Group:Handle(TAG, function(name, payload) PT:OnMessage(name, payload) end)
    ns:Listen("STEP_CHANGED", function() ns:Throttle("playtogether", 1, function() PT:Send() end) end)
    ns:Listen("GUIDE_CHANGED", function() ns:Throttle("playtogether", 1, function() PT:Send() end) end)
    ns:On("GROUP_ROSTER_UPDATE", function()
        if PT:Enabled() then ns:Throttle("playtogether-roster", 3, function() PT:Send(true) end) end
        ns:Fire("REFRESH")
    end)
    local acc = 0
    local f = CreateFrame("Frame")
    f:SetScript("OnUpdate", function(_, e)
        acc = acc + e
        if acc < RESEND then return end
        acc = 0
        if PT:Enabled() and inParty() then PT:Send(true) end
    end)
end
