-- Questwarden - talent suggestions inside the Blizzard talent window
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- This program is free software: you can redistribute it and/or modify it under the terms of the
-- GNU General Public License as published by the Free Software Foundation, version 3.
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
-- even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details. The complete license text is in LICENSE.
--
-- Setting "Show Talent Suggestions". In the default talent window (Blizzard_TalentUI, loaded on
-- demand) this adds, for the build of your spec profile (Talents/ProfileBuilds.lua):
--   - numbered markers on the next picks (1 = next point) on the tab you are looking at; pick 1 is green with a gold
--     glow, which pulses while you have a point to spend,
--   - a gold highlight and a "1" on the bottom tab of the tree pick 1 is in, so it can be found from any tab,
--   - a small panel: the build, the next picks, deviations, and the source,
--   - a tooltip line on every talent the build uses.
-- Talents are matched by tier and column, never by name, so any client language works.
-- Nothing here spends a talent point: there is no call to LearnTalent anywhere in Questwarden.
-- Everything is post-hooked (hooksecurefunc) or added on top; Blizzard's frames are not replaced.

local _, ns = ...

local TH = { markers = {}, tabMarks = {} }
ns.TalentHints = TH

local MAX_MARKS = 3
local function prof() return ns.db.profile end

function TH:Enabled() return prof().showTalentSuggestions ~= false end

-- The build to follow: the spec profile's plan; without a spec profile, the build chosen in the
-- Questwarden talent window (or the class's leveling build).
function TH:Build()
    -- "No talent guidance" chosen in setup (Core/Setup.lua): no plan, no markers.
    if ns.char.noTalentPlan then return nil, "no guidance", nil end
    local info = ns.Compat.PlayerInfo()
    local p = ns.char.gearProfile and ns.Gear:ProfileById(ns.char.gearProfile)
    if p and p.class == info.class then
        local b, why = ns.Talents:BuildForProfile(p)
        return b, why, p
    end
    return ns.Talents:ActiveBuild(), nil, nil
end

-- Points per tree from live ranks, and whether `t` can take its next rank now.
local function treePoints(live, ci)
    local per = { 0, 0, 0 }
    for id, r in pairs(live) do
        local t = ci.byId[id]
        if t then per[t.tab] = per[t.tab] + r end
    end
    return per
end

function TH:Blocked(t, live, ci)
    local per = treePoints(live, ci)
    if per[t.tab] < (t.tier - 1) * 5 then return string.format("needs %d points in its tree first", (t.tier - 1) * 5) end
    if t.prereq and (live[t.prereq[1]] or 0) < t.prereq[2] then
        local pre = ci.byId[t.prereq[1]]
        return "needs " .. (pre and pre.name or "its prerequisite") .. " first"
    end
    return nil
end

-- The suggestion state: { build, next = {picks}, deviations, blocked, unspent, why, profile }.
function TH:State()
    local b, why, p = self:Build()
    local st = { build = b, why = why, profile = p, next = {}, deviations = 0 }
    if not b then return st end
    local live, mismatches = ns.Talents:ReadLive()
    st.mismatches = mismatches
    local ci = ns.Talents:Index(b.class)
    local seq = ns.Talents:Expand(b)
    local _, idx = ns.Talents:NextPick(b, live)
    -- Deviations: points above what the plan ever puts into that talent.
    local want = {}
    for _, s in ipairs(seq) do want[s.talent.id] = math.max(want[s.talent.id] or 0, s.rank) end
    for id, r in pairs(live) do
        if r > (want[id] or 0) then st.deviations = st.deviations + r - (want[id] or 0) end
    end
    st.unspent = ns.Compat.GetUnspentTalentPoints()
    -- Next picks: the plan's missing points in order (a later rank of the same talent counts once).
    local seen = {}
    for i = idx, #seq do
        local s = seq[i]
        if (live[s.talent.id] or 0) < s.rank and not seen[s.talent.id] then
            seen[s.talent.id] = true
            st.next[#st.next + 1] = { talent = s.talent, rank = s.rank, level = s.level, index = i, levels = {} }
            if #st.next >= MAX_MARKS then break end
        end
    end
    -- The levels of every point the plan still puts into each of those talents.
    for _, pk in ipairs(st.next) do
        for i = idx, #seq do
            local s = seq[i]
            if s.talent.id == pk.talent.id and (live[s.talent.id] or 0) < s.rank then pk.levels[#pk.levels + 1] = s.level end
        end
    end
    st.playerLevel = ns.Compat.PlayerInfo().level
    if st.next[1] and ci then st.blocked = self:Blocked(st.next[1].talent, live, ci) end
    st.live, st.ci = live, ci
    return st
end

-- "level 12", or "now" for a level you have reached (its point is due).
function TH.LevelText(level, playerLevel)
    if playerLevel and level <= playerLevel then return "now" end
    return "level " .. level
end

-- The levels to put points into a talent: "now" for the ones you have reached ("now x2" for two), then the later
-- levels, e.g. "now, 12, 13, 14".
function TH.LevelsText(levels, playerLevel)
    local due, later = 0, {}
    for _, l in ipairs(levels or {}) do
        if playerLevel and l <= playerLevel then due = due + 1 else later[#later + 1] = tostring(l) end
    end
    if due > 0 then table.insert(later, 1, due > 1 and ("now x" .. due) or "now") end
    return table.concat(later, ", ")
end

-- Blizzard talent window --------------------------------------------------------------------------
local function selectedTab()
    local f = _G.PlayerTalentFrame
    if not f then return nil end
    if PanelTemplates_GetSelectedTab then
        local t = PanelTemplates_GetSelectedTab(f)
        if t then return t end
    end
    return f.selectedTab or f.currentSelectedTab
end

local function talentButton(i) return _G["PlayerTalentFrameTalent" .. i] end

-- A looping fade (bright to dim and back) on a texture; nil when the client has no animation groups.
local function pulse(tex)
    local g = tex.CreateAnimationGroup and tex:CreateAnimationGroup()
    local a = g and g.CreateAnimation and g:CreateAnimation("Alpha")
    if not a then return nil end
    if a.SetFromAlpha then a:SetFromAlpha(1) a:SetToAlpha(0.25) end
    a:SetDuration(0.6)
    g:SetLooping("BOUNCE")
    return g
end

local function marker(b)
    local m = TH.markers[b]
    if not m and b.CreateFontString then
        m = { text = b:CreateFontString(nil, "OVERLAY", "NumberFontNormalLarge"), glow = b:CreateTexture(nil, "OVERLAY") }
        m.text:SetPoint("TOPLEFT", b, "TOPLEFT", -4, 4)
        -- The levels to spend its points at, under the button.
        m.levels = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        m.levels:SetPoint("TOP", b, "BOTTOM", 0, -2)
        m.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        m.glow:SetBlendMode("ADD")
        m.glow:SetVertexColor(1, 0.82, 0)
        m.glow:SetSize(80, 80)
        m.glow:SetPoint("CENTER", b, "CENTER", 0, 0)
        m.pulse = pulse(m.glow)
        TH.markers[b] = m
    end
    return m
end

-- The highlight on a tree's bottom tab (PlayerTalentFrameTab1-3).
local function tabMark(tab)
    local m = TH.tabMarks[tab]
    if not m and tab.CreateTexture then
        m = { glow = tab:CreateTexture(nil, "OVERLAY"), text = tab:CreateFontString(nil, "OVERLAY", "NumberFontNormalLarge") }
        m.glow:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight")
        m.glow:SetBlendMode("ADD")
        m.glow:SetVertexColor(1, 0.82, 0)
        m.glow:SetPoint("TOPLEFT", tab, "TOPLEFT", 4, 2)
        m.glow:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", -4, 2)
        m.text:SetPoint("TOPRIGHT", tab, "TOPRIGHT", -2, 6)
        m.text:SetTextColor(0.3, 1, 0.3)
        m.text:SetText("1")
        m.pulse = pulse(m.glow)
        TH.tabMarks[tab] = m
    end
    return m
end

local function hideMark(m)
    m.glow:Hide()
    m.text:Hide()
    if m.levels then m.levels:Hide() end
    if m.pulse then m.pulse:Stop() end
end

local function showGlow(m, pulsing)
    m.glow:Show()
    if m.pulse then if pulsing then m.pulse:Play() else m.pulse:Stop() end end
end

function TH:HideMarkers()
    for _, m in pairs(self.markers) do hideMark(m) end
    for _, m in pairs(self.tabMarks) do hideMark(m) end
end

function TH:Panel()
    if self.panel or not _G.PlayerTalentFrame then return self.panel end
    local f = CreateFrame("Frame", ns.name .. "TalentHints", _G.PlayerTalentFrame, ns.Compat.BackdropTemplate)
    f:SetSize(220, 150)
    f:SetPoint("TOPLEFT", _G.PlayerTalentFrame, "TOPRIGHT", -30, -12)
    if f.SetBackdrop then
        f:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
        f:SetBackdropColor(0.05, 0.05, 0.08, 0.92)
    end
    f.text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.text:SetPoint("TOPLEFT", 10, -10)
    f.text:SetWidth(200)
    f.text:SetJustifyH("LEFT")
    self.panel = f
    return f
end

-- Text of the panel (also used by the tests).
function TH:PanelText(st)
    st = st or self:State()
    local L = {}
    if not st.build then
        L[1] = "|cffffd100" .. ns.name .. " talents|r"
        if st.why == "no guidance" then
            L[2] = "No talent guidance (your setup choice). Pick a plan with /" .. ns.slash .. " setup to get suggestions."
        elseif st.why == "no plan" and st.profile then
            L[2] = "No talent plan for " .. ns.Upgrade:ProfileName(st.profile) .. " yet. Pick another spec profile, or spend points your own way."
        else
            L[2] = "Choose a spec profile (Settings, Tips) for talent suggestions."
        end
        return table.concat(L, "\n")
    end
    L[#L + 1] = "|cffffd100" .. st.build.name .. "|r"
    if #st.next == 0 then
        L[#L + 1] = "Plan complete."
    else
        for i, p in ipairs(st.next) do
            local tree = st.ci and st.ci.tabs[p.talent.tab] and st.ci.tabs[p.talent.tab].name or ""
            L[#L + 1] = string.format("%d. %s %d/%d |cff999999(%s, %s)|r", i, p.talent.name, p.rank, p.talent.ranks, tree, TH.LevelText(p.level, st.playerLevel))
        end
        if st.blocked then L[#L + 1] = "|cffff7777Next pick " .. st.blocked .. ".|r" end
    end
    if st.deviations > 0 then
        L[#L + 1] = string.format("|cffffaa55Your talents differ from this plan by %d point(s). Suggestions continue with the plan's next missing pick; matching the plan exactly would need a respec (" .. ns.name .. " never resets talents).|r", st.deviations)
    end
    if st.unspent and st.unspent > 0 then L[#L + 1] = st.unspent .. " point(s) to spend - click the talent yourself." end
    L[#L + 1] = "|cff999999" .. ns.Talents:SourceLine(st.build) .. "|r"
    return table.concat(L, "\n")
end

function TH:Refresh()
    if not _G.PlayerTalentFrame then return end
    self:HideMarkers()
    local panel = self:Panel()
    if not self:Enabled() then if panel then panel:Hide() end return end
    local st = self:State()
    if panel then panel.text:SetText(self:PanelText(st)) panel:SetHeight((tonumber(panel.text:GetStringHeight()) or 120) + 20) panel:Show() end
    if not st.ci then return end
    local pulsing = (st.unspent or 0) > 0
    local first = st.next[1]
    local tb = first and _G["PlayerTalentFrameTab" .. first.talent.tab]
    local tm = tb and tabMark(tb)
    if tm then showGlow(tm, pulsing) tm.text:Show() end
    local tab = selectedTab()
    if not tab then return end
    for n, p in ipairs(st.next) do
        if p.talent.tab == tab and p.talent.liveIndex then
            for i = 1, (MAX_NUM_TALENTS or 40) do
                local b = talentButton(i)
                if not b then break end
                if b.GetID and b:GetID() == p.talent.liveIndex and (not b.IsShown or b:IsShown()) then
                    local m = marker(b)
                    if m then
                        m.text:SetText(tostring(n))
                        if n == 1 then m.text:SetTextColor(0.3, 1, 0.3) else m.text:SetTextColor(1, 1, 1) end
                        m.text:Show()
                        m.levels:SetText(TH.LevelsText(p.levels, st.playerLevel))
                        if n == 1 then m.levels:SetTextColor(0.3, 1, 0.3) else m.levels:SetTextColor(1, 1, 1) end
                        m.levels:Show()
                        if n == 1 then showGlow(m, pulsing) end
                    end
                end
            end
        end
    end
end

-- Tooltip line for (tab, index): where the talent sits in the plan.
function TH:TooltipLine(tab, index)
    if not self:Enabled() then return nil end
    local st = self:State()
    if not st.build or not st.ci then return nil end
    local t
    for _, x in ipairs(st.ci.tabs[tab] and st.ci.tabs[tab].talents or {}) do if x.liveIndex == index then t = x break end end
    if not t then return nil end
    for n, p in ipairs(st.next) do
        if p.talent.id == t.id then
            return string.format(ns.name .. ": pick %d of your plan (points: %s)", n, TH.LevelsText(p.levels, st.playerLevel)), n == 1
        end
    end
    local want = 0
    for _, s in ipairs((ns.Talents:Expand(st.build))) do if s.talent.id == t.id then want = math.max(want, s.rank) end end
    if want == 0 then return ns.name .. ": not in your plan (" .. st.build.name .. ")" end
    return string.format(ns.name .. ": your plan takes %d/%d", want, t.ranks)
end

function TH:Hook()
    if self.hooked or not _G.PlayerTalentFrame then return end
    self.hooked = true
    if type(_G.PlayerTalentFrame_Update) == "function" then
        hooksecurefunc("PlayerTalentFrame_Update", function() TH:Refresh() end)
    end
    _G.PlayerTalentFrame:HookScript("OnShow", function() TH:Refresh() end)
    for i = 1, 3 do
        local tabButton = _G["PlayerTalentFrameTab" .. i]
        if tabButton and tabButton.HookScript then tabButton:HookScript("OnClick", function() TH:Refresh() end) end
    end
end

function TH:Init()
    if GameTooltip and GameTooltip.SetTalent then
        hooksecurefunc(GameTooltip, "SetTalent", function(tt, tab, index)
            local line, isNext = TH:TooltipLine(tab, index)
            if line then
                if isNext then tt:AddLine(line, 0.3, 1, 0.3) else tt:AddLine(line, 0.6, 0.8, 1) end
                tt:Show()
            end
        end)
    end
    self:Hook()
    ns:On("ADDON_LOADED", function(_, name) if name == "Blizzard_TalentUI" then TH:Hook() end end)
    ns:Listen("TALENTS_CHANGED", function() TH:Refresh() end)
end
