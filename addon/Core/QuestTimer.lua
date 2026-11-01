-- Questwarden - timed quests
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- This program is free software: you can redistribute it and/or modify it under the terms of the
-- GNU General Public License as published by the Free Software Foundation, version 3.
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
-- even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details. The complete license text is in LICENSE.
--
-- Timed quests (Database/QuestTimers.lua, time limits from the CMaNGOS quest table): a warning before you accept
-- one (Core/QuestAuto.lua never accepts them for you), a bar with the time left while one is in your log, and the
-- guide puts its objective and turn-in first (Core/Engine.lua). The time left comes from the game (GetQuestTimers)
-- when that is unambiguous, one timer and one timed quest in the log. Otherwise it is counted from when you
-- accepted the quest (saved per character), or not shown when that is unknown too.

local _, ns = ...

local QT = {}
ns.QuestTimer = QT

local function prof() return ns.db.profile end
local function clock() return time and time() or 0 end

-- Seconds allowed for quest q, or nil when it is not timed.
function QT:Limit(q) return q and ns.QuestTimers and ns.QuestTimers[q] or nil end

function QT.Format(sec)
    sec = math.max(0, math.floor(sec + 0.5))
    if sec >= 3600 then
        return string.format("%d:%02d:%02d", math.floor(sec / 3600), math.floor(sec % 3600 / 60), sec % 60)
    end
    return string.format("%d:%02d", math.floor(sec / 60), sec % 60)
end

-- "5 minutes", "1 hour 30 minutes", "45 seconds".
function QT.Words(sec)
    if sec < 60 then return sec .. " seconds" end
    local m = math.floor(sec / 60 + 0.5)
    local h, mm, parts = math.floor(m / 60), m % 60, {}
    if h > 0 then parts[#parts + 1] = h .. (h == 1 and " hour" or " hours") end
    if mm > 0 then parts[#parts + 1] = mm .. (mm == 1 and " minute" or " minutes") end
    return table.concat(parts, " ")
end

local function acceptedAt()
    local c = ns.char
    if type(c.timedAccepted) ~= "table" then c.timedAccepted = {} end
    return c.timedAccepted
end

function QT:OnAccepted(q)
    if self:Limit(q) then acceptedAt()[q] = clock() end
end

-- Timed quests in your log, in log order: { { q =, index =, failed = } }.
function QT:InLog()
    local list = {}
    for q, e in pairs(ns.Tracker.log) do
        if self:Limit(q) then list[#list + 1] = { q = q, index = e.index or 0, failed = e.failed } end
    end
    table.sort(list, function(a, b) return a.index < b.index end)
    return list
end

-- Seconds left on quest q (nil when not known), and true when the quest has failed.
function QT:TimeLeft(q)
    local e = ns.Tracker:GetEntry(q)
    if not (e and self:Limit(q)) then return nil, false end
    if e.failed then return 0, true end
    if GetQuestTimers and #self:InLog() == 1 and select("#", GetQuestTimers()) == 1 then
        local v = tonumber((GetQuestTimers()))
        if v then return v, false end
    end
    local at = acceptedAt()[q]
    if at then return math.max(0, self:Limit(q) - (clock() - at)), false end
    return nil, false
end

-- A timed quest in your log that has not failed or run out: the guide does it first.
function QT:Running(q)
    if not self:Limit(q) then return false end
    local left, failed = self:TimeLeft(q)
    return ns.Tracker:InLog(q) and not failed and (left == nil or left > 0)
end

-- The warning before accepting (quest window, guide step).
function QT:WarningText(q)
    local limit = self:Limit(q)
    return limit and ("Timed quest: once you accept it you have " .. QT.Words(limit) .. " to finish it and turn it in.") or nil
end

-- Shown when a timed quest's details open: on screen and in chat, once per quest per window.
function QT:OnQuestDetail(q)
    local text = self:WarningText(q)
    if not text or not prof().timedQuestWarn then return end
    local now = GetTime and GetTime() or 0
    if self.warned and self.warned.q == q and now - self.warned.t < 2 then return end
    self.warned = { q = q, t = now }
    local title = ns.DB.GetQuestName(q) or ("quest " .. tostring(q))
    ns:Print("|cffff7744" .. title .. "|r - " .. text)
    if RaidNotice_AddMessage and RaidWarningFrame and ChatTypeInfo then
        RaidNotice_AddMessage(RaidWarningFrame, "Timed quest: " .. title .. " (" .. QT.Words(self:Limit(q)) .. ")", ChatTypeInfo.RAID_WARNING)
    end
end

-- Time-left line for a timed quest's objective and turn-in steps (Core/StepText.lua).
function QT:StepLine(q)
    if not ns.Tracker:InLog(q) then return nil end
    local left, failed = self:TimeLeft(q)
    if failed or left == 0 then return "Out of time: abandon the quest and take it again." end
    if left then return "Timed quest: " .. QT.Format(left) .. " left." end
    return "Timed quest: finish it and turn it in first."
end

function QT:Bar()
    if self.bar then return self.bar end
    local W = ns.Widgets
    local b = W.Panel(ns.name .. "QuestTimer", UIParent, 240, 26)
    W.Movable(b, "questTimer")
    if not (ns.db.frames.questTimer and ns.db.frames.questTimer.point) then b:ClearAllPoints() b:SetPoint("TOP", UIParent, "TOP", 0, -150) end
    local t = W.Text(b, "GameFontHighlightSmall", "CENTER")
    t:SetPoint("CENTER")
    b.text = t
    b:Hide()
    self.bar = b
    return b
end

-- Bar text: each timed quest in your log with its time left; red under a minute.
function QT:BarText()
    local lines = {}
    for _, e in ipairs(self:InLog()) do
        local left, failed = self:TimeLeft(e.q)
        local title = ns.DB.GetQuestName(e.q) or ("quest " .. e.q)
        if failed or left == 0 then
            lines[#lines + 1] = "|cffff4444" .. title .. "  failed|r"
        elseif left then
            lines[#lines + 1] = title .. "  " .. (left < 60 and ("|cffff4444" .. QT.Format(left) .. "|r") or QT.Format(left))
        end
    end
    return #lines > 0 and table.concat(lines, "\n") or nil, #lines
end

function QT:Update()
    -- Forget accept times of quests no longer in the log (not just accepted: the log scan follows the event).
    local at, now = acceptedAt(), clock()
    for q, t in pairs(at) do if not ns.Tracker:InLog(q) and now - t > 10 then at[q] = nil end end
    local text, n = self:BarText()
    if not (text and prof().timedQuestBar) then
        if self.bar then self.bar:Hide() self.bar:SetScript("OnUpdate", nil) end
        return
    end
    local b = self:Bar()
    b.text:SetText(text)
    b:SetHeight(12 + 14 * n)
    b:Show()
    b.acc = 0
    b:SetScript("OnUpdate", function(s, el)
        s.acc = s.acc + el
        if s.acc < 0.5 then return end
        s.acc = 0
        local tx = QT:BarText()
        if not tx then s:Hide() s:SetScript("OnUpdate", nil) return end
        s.text:SetText(tx)
    end)
end

function QT:Init()
    ns:On("QUEST_ACCEPTED", function(_, a, b) QT:OnAccepted(b or a) end)
    ns:Listen("QUESTS_CHANGED", function() QT:Update() end)
    self:Update()
end
