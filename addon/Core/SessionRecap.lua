-- Questwarden - session recap: what you did since you logged in, and last time
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- This program is free software: you can redistribute it and/or modify it under the terms of the
-- GNU General Public License as published by the Free Software Foundation, version 3.
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
-- even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details. The complete license text is in LICENSE.
--
-- Setting sessionRecap (off by default; the setup wizard offers it). The counts are kept for every session
-- (ns.char.session, saved as they change, so a crash loses nothing): play time, levels, experience, quests
-- turned in, zones visited, deaths and money. Chat at logout is never seen, so the recap of the last session is
-- printed at the next login (when it lasted at least MIN_SHOWN seconds); /qw recap shows this session so far.

local _, ns = ...

local SR = {}
ns.SessionRecap = SR

local MIN_SHOWN = 120

local function prof() return ns.db.profile end
local function now() return time and time() or 0 end

function SR:New()
    return { start = now(), last = now(), level0 = UnitLevel("player") or 1, level = UnitLevel("player") or 1,
        xp = 0, quests = 0, deaths = 0, zones = {}, money0 = GetMoney and GetMoney() or 0, money = GetMoney and GetMoney() or 0 }
end

-- The previous session (if any) becomes the last one; a new one starts.
function SR:Start()
    local c = ns.char
    if type(c.session) == "table" and c.session.start then c.lastSession = c.session end
    c.session = self:New()
    self.xp, self.xpMax = UnitXP("player") or 0, UnitXPMax("player") or 0
    self:Zone()
end

function SR:S()
    if type(ns.char.session) ~= "table" then ns.char.session = self:New() end
    return ns.char.session
end

function SR:Touch()
    local s = self:S()
    s.last, s.level = now(), UnitLevel("player") or s.level
    s.money = GetMoney and GetMoney() or s.money
end

function SR:Zone()
    local z = GetRealZoneText and GetRealZoneText()
    if not z or z == "" then return end
    local s = self:S()
    for _, v in ipairs(s.zones) do if v == z then return end end
    s.zones[#s.zones + 1] = z
end

-- Experience gained, across level-ups.
function SR:OnXP()
    local s = self:S()
    local cur, max = UnitXP("player") or 0, UnitXPMax("player") or 0
    local level = UnitLevel("player") or s.level
    if self.xp then
        if level > (self.xpLevel or level) then s.xp = s.xp + math.max(0, (self.xpMax or 0) - self.xp) + cur
        elseif cur >= self.xp then s.xp = s.xp + (cur - self.xp) end
    end
    self.xp, self.xpMax, self.xpLevel = cur, max, level
    self:Touch()
end

local function duration(sec)
    sec = math.max(0, sec or 0)
    local h, m = math.floor(sec / 3600), math.floor((sec % 3600) / 60)
    if h > 0 then return string.format("%d h %d min", h, m) end
    return string.format("%d min", m)
end

-- One recap line for a session record.
function SR.Text(s)
    local parts = { duration((s.last or s.start) - s.start) }
    local levels = (s.level or s.level0) - (s.level0 or 0)
    if levels > 0 then parts[#parts + 1] = string.format("level %d to %d", s.level0, s.level) end
    if (s.xp or 0) > 0 then parts[#parts + 1] = s.xp .. " experience" end
    parts[#parts + 1] = s.quests .. " quest" .. (s.quests == 1 and "" or "s") .. " turned in"
    if #s.zones > 0 then parts[#parts + 1] = "zones: " .. table.concat(s.zones, ", ") end
    if (s.deaths or 0) > 0 then parts[#parts + 1] = s.deaths .. " death" .. (s.deaths == 1 and "" or "s") end
    local dm = (s.money or 0) - (s.money0 or 0)
    if dm ~= 0 and GetCoinTextureString then parts[#parts + 1] = (dm > 0 and "+" or "-") .. GetCoinTextureString(math.abs(dm)) end
    return table.concat(parts, ", ") .. "."
end

function SR:PrintLast()
    local s = ns.char.lastSession
    if not (prof().sessionRecap and type(s) == "table" and s.start) then return end
    if (s.last or s.start) - s.start < MIN_SHOWN then return end
    ns:Print("|cffffd100Last session:|r " .. SR.Text(s))
end

function SR:PrintNow()
    self:Touch()
    ns:Print("|cffffd100This session so far:|r " .. SR.Text(self:S()))
    local last = ns.char.lastSession
    if type(last) == "table" and last.start then ns:Print("Last session: " .. SR.Text(last)) end
end

function SR:Init()
    self:Start()
    ns:On("PLAYER_XP_UPDATE", function() SR:OnXP() end)
    ns:On("PLAYER_LEVEL_UP", function() SR:Touch() end)
    ns:On("QUEST_TURNED_IN", function() local s = SR:S() s.quests = s.quests + 1 SR:Touch() end)
    ns:On("PLAYER_DEAD", function() local s = SR:S() s.deaths = s.deaths + 1 SR:Touch() end)
    ns:On("ZONE_CHANGED_NEW_AREA", function() SR:Zone() SR:Touch() end)
    ns:On("PLAYER_MONEY", function() SR:Touch() end)
    ns:On("PLAYER_LOGOUT", function() SR:Touch() end)
    C_Timer.After(8, function() SR:PrintLast() end)
end
