-- Questwarden - a small window for new-player tips, dismissed with OK (docs/NEW_PLAYERS.md)
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- This program is free software: you can redistribute it and/or modify it under the terms of the
-- GNU General Public License as published by the Free Software Foundation, version 3.
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
-- even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details. The complete license text is in LICENSE.
--
-- Setting tipWindows (on by default): the new-player helpers' tips (Core/NewPlayer.lua, Classes/SpellCoach.lua,
-- Core/ProfessionTips.lua) show here one at a time; OK (or Escape) shows the next. Tips that come in combat wait
-- until it ends. Off: they go to chat as before.

local _, ns = ...
local W = ns.Widgets

local TW = { queue = {} }
ns.TipWindow = TW

local WIDTH = 380
local TEXT_W = WIDTH - 28

local function chat(title, text, more)
    ns:Print("|cffffd100" .. title .. ":|r " .. text)
    for _, l in ipairs(more or {}) do DEFAULT_CHAT_FRAME:AddMessage("  " .. l) end
end

-- A tip: title, its text, and optional extra lines (shown under it; in chat, one indented line each).
function TW:Say(title, text, more)
    if not ns.db.profile.tipWindows then return chat(title, text, more) end
    local body = text
    if more and #more > 0 then body = body .. "\n\n" .. table.concat(more, "\n") end
    self.queue[#self.queue + 1] = { title = title, text = body }
    if self.frame and self.frame:IsShown() then self:Label() else self:Next() end
end

-- OK, with how many tips wait behind this one.
function TW:Label()
    local okText = "OK"
    self.ok:SetText(#self.queue > 0 and (okText .. " (" .. #self.queue .. " more)") or okText)
end

function TW:Create()
    local f = W.Panel(ns.name .. "TipWindow", UIParent, WIDTH, 120)
    f:SetFrameStrata("DIALOG")
    f:Hide()
    W.Movable(f, "tips")
    tinsert(UISpecialFrames, ns.name .. "TipWindow") -- Escape counts as OK
    self.title = W.TitleBar(f, "")
    self.text = W.Text(f, "GameFontHighlight")
    self.text:SetPoint("TOPLEFT", 14, -(W.TITLE_H + 12))
    self.text:SetWidth(TEXT_W)
    self.ok = W.Button(f, "OK", 100, 22, function() f:Hide() end)
    self.ok:SetPoint("BOTTOM", 0, 12)
    f:SetScript("OnHide", function() TW:Next() end)
    self.frame = f
end

-- Shows the next waiting tip, unless one is showing or the player is in combat.
function TW:Next()
    if #self.queue == 0 or ns.Compat.InCombat() then return end
    if not self.frame then self:Create() end
    if self.frame:IsShown() then return end
    local tip = table.remove(self.queue, 1)
    self.current = tip
    self.title:SetText(tip.title)
    self.text:SetText(tip.text)
    self:Label()
    self.frame:SetHeight(W.TITLE_H + 12 + self.text:GetStringHeight() + 50)
    self.frame:Show()
    W.FadeIn(self.frame)
end

-- Tips waiting while the setting is turned off go to chat.
function TW:Flush()
    while #self.queue > 0 do
        local tip = table.remove(self.queue, 1)
        chat(tip.title, tip.text)
    end
end

function TW:Init()
    ns:On("PLAYER_REGEN_ENABLED", function() TW:Next() end)
end
