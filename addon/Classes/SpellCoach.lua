-- Questwarden - new-spell coaching: what a spell you just learned does, whether it is on a bar, class tips
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- This program is free software: you can redistribute it and/or modify it under the terms of the
-- GNU General Public License as published by the Free Software Foundation, version 3.
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
-- even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details. The complete license text is in LICENSE.
--
-- Setting spellCoach (off by default; the setup wizard offers it). Chat only.
--   * When you learn a spell (LEARNED_SPELL_IN_TAB): its name and the first sentence of the game's own
--     description (GetSpellDescription), then, a moment later, whether any rank of it is on your action bars
--     (HasAction / GetActionInfo over the 120 action slots). If not: how to put it there. The client does not
--     say which spells are passive, so the hint says "unless it is passive".
--   * Every TIP_EVERY levels from 4: the next of your class's leveling tips (Classes/ClassAdvice.lua), in order.
-- All three client functions are guarded: without them the line is shorter, never an error.

local _, ns = ...

local SC = { pending = {} }
ns.SpellCoach = SC

local ACTION_SLOTS = 120
local TIP_EVERY = 4
local MAX_DESC = 180

local function prof() return ns.db.profile end

-- First sentence of the spell's description, without the client's colour codes; nil when there is none.
function SC.Description(spellId)
    if not GetSpellDescription then return nil end
    local ok, d = pcall(GetSpellDescription, spellId)
    if not ok or type(d) ~= "string" or d == "" then return nil end
    d = string.gsub(d, "|c%x%x%x%x%x%x%x%x", "")
    d = string.gsub(d, "|r", "")
    d = string.gsub(d, "%s+", " ")
    local first = string.match(d, "^(.-[%.!])%s") or d
    if #first > MAX_DESC then first = string.sub(first, 1, MAX_DESC - 3) .. "..." end
    return first
end

-- Is a spell of this name on any action slot?
function SC.OnBars(name)
    if not (HasAction and GetActionInfo and name) then return nil end
    for slot = 1, ACTION_SLOTS do
        if HasAction(slot) then
            local kind, id = GetActionInfo(slot)
            if kind == "spell" and id and GetSpellInfo(id) == name then return true end
        end
    end
    return false
end

function SC:OnLearned(spellId)
    if not (prof().spellCoach and spellId) then return end
    local name = GetSpellInfo(spellId)
    if not name or self.pending[name] then return end
    self.pending[name] = true
    -- Wait a moment: the description may need a moment to load, and the client may place the spell itself.
    C_Timer.After(1, function()
        SC.pending[name] = nil
        local desc = SC.Description(spellId)
        local more
        if SC.OnBars(name) == false then
            local key = ns.NewPlayer and ns.NewPlayer.Key("spellbook") or "P"
            more = { "It is not on your action bars yet. Unless it is passive, open your spellbook (" .. key .. ") and drag it onto a bar, so you can press it." }
        end
        ns.TipWindow:Say("New spell", name .. (desc and (" - " .. desc) or ""), more)
    end)
end

-- The next class tip on level-up, every TIP_EVERY levels from 4.
function SC:OnLevel(level)
    if not prof().spellCoach or not ns.ClassAdvice then return end
    level = level or 0
    if level < 4 or level % TIP_EVERY ~= 0 then return end
    local a = ns.ClassAdvice:For(ns.Compat.PlayerInfo().class)
    if not (a and a.tips and #a.tips > 0) then return end
    local i = (tonumber(ns.char.coachTip) or 0) + 1
    if i > #a.tips then return end
    ns.char.coachTip = i
    ns.TipWindow:Say("Class tip " .. i .. " of " .. #a.tips, a.tips[i])
end

function SC:Init()
    ns:On("LEARNED_SPELL_IN_TAB", function(_, spellId) SC:OnLearned(spellId) end)
    ns:On("PLAYER_LEVEL_UP", function(_, level) SC:OnLevel(level) end)
end
