-- Questwarden - setup wizard: route and mode, talent plan, dungeons, options, review (per character)
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- This program is free software: you can redistribute it and/or modify it under the terms of the
-- GNU General Public License as published by the Free Software Foundation, version 3.
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
-- even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details. The complete license text is in LICENSE.
--
-- The window only edits the draft of Core/Setup.lua; Finish Setup applies it there. Shown by itself once per
-- character until setup is finished (not again in the same session after Set Up Later or closing), and from
-- Settings -> General -> Run Setup Again or /qw setup. Every step is one scrolling page that is laid out again
-- from the draft after each change (widgets are pooled, nothing expensive runs on a click).

local _, ns = ...

local WL = { pools = {} }
ns.Welcome = WL

local W = ns.Widgets
local function S() return ns.Setup end

local FW, FH, CW = 540, 580, 486 -- frame size, content width

-- Leveling modes for the settings window's select (UI/ConfigOptions.lua).
WL.MODES = {
    { "speed", "Speed (the leveling guides)" },
    { "completionist", "Completionist (every eligible quest)" },
}

-- Older callers --------------------------------------------------------------------------------------
function WL:Migrate() S():Migrate() end
function WL:Needed() return S():Needed() end
function WL:Draft() return self.draft or S():Draft() end

-- Pooled widgets ------------------------------------------------------------------------------------

local function makeOption(parent)
    local row = CreateFrame("Button", nil, parent)
    row:SetSize(CW, 20)
    row.check = W.Check(row)
    row.check:SetPoint("TOPLEFT", 0, -1)
    row.label = W.Text(row, "GameFontHighlight", "LEFT")
    row.label:SetPoint("TOPLEFT", 26, -2)
    row.label:SetWidth(CW - 30)
    row.note = W.Text(row, "GameFontHighlightSmall", "LEFT")
    row.note:SetPoint("TOPLEFT", 26, -18)
    row.note:SetWidth(CW - 30)
    local function click()
        if row.enabled and row.onClick then row.onClick() end
        WL:Render()
    end
    row:SetScript("OnClick", click)
    row.check:SetScript("OnClick", click)
    return row
end

function WL:Take(kind, make)
    local p = self.pools[kind]
    if not p then p = { n = 0 } self.pools[kind] = p end
    p.n = p.n + 1
    local w = p[p.n]
    if not w then w = make() p[p.n] = w end
    if w.ClearAllPoints then w:ClearAllPoints() end
    w:Show()
    return w
end

function WL:Begin()
    for _, p in pairs(self.pools) do
        for i = 1, #p do p[i]:Hide() end
        p.n = 0
    end
    if self.guideDD then self.guideDD:Hide() end
    if self.gearDD then self.gearDD:Hide() end
    self.y = -4
end

function WL:Gap(h) self.y = self.y - (h or 6) end

function WL:Text(str, font, color)
    local fs = self:Take("text", function() return W.Text(self.content, "GameFontHighlightSmall", "LEFT") end)
    fs:SetFontObject(font or "GameFontHighlightSmall")
    fs:SetWidth(CW)
    fs:SetPoint("TOPLEFT", 4, self.y)
    fs:SetText(str)
    if color then fs:SetTextColor(color[1], color[2], color[3]) else fs:SetTextColor(1, 1, 1) end
    self.y = self.y - (fs:GetStringHeight() or 12) - 6
    return fs
end

function WL:Section(str)
    self:Gap(4)
    local fs = self:Text(str, "GameFontNormal")
    fs:SetTextColor(1, 0.82, 0)
    return fs
end

-- A check row (radio when `radio`): label, optional note under it, disabled with its reason.
function WL:Option(label, note, checked, enabled, onClick)
    local row = self:Take("option", function() return makeOption(self.content) end)
    row:SetPoint("TOPLEFT", 4, self.y)
    row.label:SetText(label)
    row.note:SetText(note or "")
    row.check:SetChecked(checked and true or false)
    row.enabled, row.onClick = enabled ~= false, onClick
    if row.enabled then row.check:Enable() row.label:SetTextColor(1, 1, 1) row.note:SetTextColor(0.75, 0.75, 0.75)
    else row.check:Disable() row.label:SetTextColor(0.5, 0.5, 0.5) row.note:SetTextColor(0.5, 0.5, 0.5) end
    local h = 20 + (note and note ~= "" and ((row.note:GetStringHeight() or 12) + 2) or 0)
    row:SetHeight(h)
    self.y = self.y - h - 4
    return row
end

function WL:Button(label, w, onClick, x)
    local b = self:Take("button", function()
        local nb = W.Button(self.content, "", 150, 22, function(s) if s.onClick then s.onClick() end WL:Render() end)
        return nb
    end)
    b:SetText(label)
    b:SetWidth(w or 150)
    b.onClick = onClick
    b:SetPoint("TOPLEFT", x or 4, self.y)
    return b
end

function WL:Dropdown(dd)
    dd:ClearAllPoints()
    dd:SetPoint("TOPLEFT", self.content, "TOPLEFT", -12, self.y)
    dd:Show()
    UIDropDownMenu_SetText(dd, dd.label())
    self.y = self.y - 34
end

-- Steps ---------------------------------------------------------------------------------------------

local render = {}

function render.route(d)
    local ch = S():Character()
    WL:Text(string.format("%s: level %d %s %s, %s, %s. Known from the game; nothing to enter.",
        tostring(ch.name), ch.level, tostring(ch.raceName), tostring(ch.className), tostring(ch.faction), ch.game), nil, { 0.75, 0.75, 0.75 })
    WL:Section("Leveling mode")
    for _, m in ipairs(S():Modes()) do
        WL:Option(m.name, m.available and m.text or m.why, d.mode == m.id, m.available, function() d.mode = m.id end)
    end
    local rec = S():RecommendedGuide()
    local recG = rec and ns.Guides:Get(rec)
    if d.mode == "speed" then
        WL:Section("Starting guide")
        WL:Dropdown(WL.guideDD)
        WL:Text("Recommended for your level and zone: " .. (recG and recG.name or "none") .. ". A guide you used before keeps its progress, and quests you already turned in count as done, so starting above level 1 is fine.")
    else
        WL:Section("Speed guide to return to")
        WL:Dropdown(WL.guideDD)
        WL:Text("Completionist plans from your level, quest log and completed quests, so starting above level 1 is fine. If you switch back to Speed later, this guide is loaded with its own progress.")
    end
    if ns.Target.hardcore then
        WL:Section("Hardcore")
        if ch.hardcoreRealm then
            WL:Option("Hardcore route", "You are on a Hardcore realm, so the Hardcore route is always used.", true, false)
        else
            WL:Option("Hardcore route (one life)", "Guides leave out risky steps or warn about them. Only this character.", d.hardcore, true,
                function() d.hardcore = not d.hardcore end)
        end
    end
end

function render.build(d)
    WL:Text("A talent plan is a recommendation for this character. " .. ns.name .. " never spends talent points or changes gear: the plan drives the level-up reminder, the markers in the talent window and the calculator (/" .. ns.slash .. " talents). Plans start with the first talent point at level 10; you can pick one now.")
    local live, spent = ns.Talents:ReadLive(), 0
    for _, r in pairs(live or {}) do spent = spent + r end
    WL:Text(string.format("Your talents right now: %d point(s) spent, %d unspent. Choosing a plan does not change them.",
        spent, ns.Compat.GetUnspentTalentPoints() or 0), nil, { 0.75, 0.75, 0.75 })
    WL:Section("Talent plan (" .. ns.Target.name .. ")")
    for _, p in ipairs(S():Plans()) do
        local note = (p.role and (p.role .. ". ") or "") .. (p.summary or "") .. (p.default and " Class default." or "")
        WL:Option(p.name, note, d.plan == p.id, true, function() S():SetPlan(d, p.id) end)
    end
    WL:Option("No talent guidance", "No plan: no picks in reminders or the talent window. You still get a reminder of unspent points.",
        d.plan == "none", true, function() S():SetPlan(d, "none") end)
    WL:Section("Gear profile")
    WL:Dropdown(WL.gearDD)
    WL:Text("Scores gear for tooltips, quest rewards and bag markers. It follows your talent plan's tree unless you pick one here. * = estimated weights.")
end

function render.dungeons(d)
    if d.mode == "completionist" then
        WL:Text("Completionist routes the quests of every dungeon. Its quests are picked up once you reach the dungeon's usual level, and each dungeon gets a run step. A run step never marks a quest complete: skip it to keep questing, and the turn-ins appear when the quests are complete.")
        WL:Section("Dungeons routed")
        for _, row in ipairs(S():Dungeons("completionist")) do
            if row.supported then
                WL:Text(string.format("%s: levels %d-%d, %d quest(s); %s.", row.name, row.min, row.max, row.quests, row.note))
            end
        end
        WL:Text("Your dungeon selection for Speed is kept and used if you switch to Speed.", nil, { 0.75, 0.75, 0.75 })
        return
    end
    WL:Option("Questing only", "No dungeon quests are routed. Dungeon quests already in your log keep their turn-in, which appears once they are complete.",
        d.dungeons == "questing", true, function() d.dungeons = "questing" end)
    WL:Option("Include selected dungeons", "The guides add the quests of the dungeons you pick, where they place them. Picking a dungeon does not assume you have a group: skip its steps to put it off, nothing is marked complete.",
        d.dungeons == "selected", true, function() d.dungeons = "selected" end)
    if d.dungeons ~= "selected" then
        WL:Text("Your dungeon picks are kept if you switch back.", nil, { 0.75, 0.75, 0.75 })
        return
    end
    WL:Gap(2)
    local y = WL.y
    WL:Button("Select All Supported", 170, function() S():SelectAllDungeons(d) end)
    WL:Button("Clear Selection", 140, function() S():ClearDungeons(d) end, 184)
    WL.y = y - 30
    for _, row in ipairs(S():Dungeons("speed")) do
        local note = string.format("Levels %d-%d. %s%s.", row.min, row.max,
            row.supported and (row.quests .. " quest(s) in the guides; ") or "", row.note) .. (row.faction and (" " .. row.faction .. " only.") or "")
        WL:Option(row.name, note, row.supported and d.selected[row.id], row.supported,
            function() d.selected[row.id] = (not d.selected[row.id]) or nil end)
    end
    WL:Text("Dungeons of the other faction are not listed. Greyed out: the guides have no quests for that dungeon in this game version.", nil, { 0.75, 0.75, 0.75 })
end

function render.prefs(d)
    WL:Option("Route group and elite quests", "Quests whose targets are elite. Off: they are left out of the route (and counted, not routed, in Completionist).",
        d.elite, true, function() d.elite = not d.elite end)
    if d.mode == "completionist" then
        WL:Section("Completionist also routes")
        for _, k in ipairs(S().INCLUDE_KINDS) do
            WL:Option(k[2], nil, d.include[k[1]], true, function() d.include[k[1]] = not d.include[k[1]] end)
        end
        WL:Text("Off by default: they are counted in /" .. ns.slash .. " completionist but not routed.", nil, { 0.75, 0.75, 0.75 })
    end
    WL:Section("Automatic upgrades")
    WL:Option("Equip upgrades from my bags automatically",
        d.gear and "Off unless you tick it. Empty slots are filled with usable items; filled slots only get a higher estimated score, not a guaranteed gain. Never in combat, and unbound Bind-on-Equip items are never equipped. This switch is part of your settings profile."
        or "Needs a gear profile (Talents step).",
        d.autoEquip and d.gear, d.gear and true or false, function() d.autoEquip = not d.autoEquip end)
end

function render.review(d)
    for _, l in ipairs(S():Summary(d)) do WL:Text(l) end
    local warn = S():Warnings(d)
    if #warn > 0 then
        WL:Section("Notes")
        for _, w in ipairs(warn) do WL:Text(w, nil, { 1, 0.82, 0.4 }) end
    end
    local ok, errs = S():Validate(d)
    if not ok then
        WL:Section("Fix before finishing")
        for _, e in ipairs(errs) do WL:Text(e, nil, { 1, 0.4, 0.3 }) end
    end
    WL:Gap(4)
    WL:Text("Finish Setup saves these choices for this character and starts the route. Your quest history and guide progress are never reset. You can run setup again from Settings -> General.", nil, { 0.75, 0.75, 0.75 })
end

-- Window --------------------------------------------------------------------------------------------

function WL:Build()
    if self.frame then return self.frame end
    local f = W.Panel(ns.name .. "Welcome", UIParent, FW, FH)
    f:Hide() -- hidden until Open, so a failure while building never leaves an empty window on screen
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:EnableMouse(true)
    W.Movable(f, "welcome")
    W.TitleBar(f, ns.name .. " setup")
    W.CloseButton(f, function() WL:Later() end)
    self.progress = W.Text(f, "GameFontNormal", "LEFT")
    self.progress:SetPoint("TOPLEFT", 16, -38)
    self.progress:SetWidth(FW - 32)
    self.dots = {}
    for i, st in ipairs(S().STEPS) do
        local t = W.Text(f, "GameFontHighlightSmall", "CENTER")
        t:SetPoint("TOPLEFT", 16 + (i - 1) * ((FW - 32) / #S().STEPS), -58)
        t:SetWidth((FW - 32) / #S().STEPS)
        t:SetText(i .. ". " .. st.title)
        self.dots[i] = t
    end
    local scroll, content = W.Scroll(f, ns.name .. "WelcomeScroll")
    scroll:SetPoint("TOPLEFT", 16, -80)
    scroll:SetPoint("BOTTOMRIGHT", -34, 74)
    content:SetWidth(CW + 8)
    self.scroll, self.content = scroll, content
    self.msg = W.Text(f, "GameFontHighlightSmall", "LEFT")
    self.msg:SetPoint("BOTTOMLEFT", 16, 46)
    self.msg:SetWidth(FW - 32)
    self.msg:SetTextColor(1, 0.4, 0.3)
    self.back = W.Button(f, "Back", 90, 24, function() WL:Go(-1) end)
    self.back:SetPoint("BOTTOMLEFT", 16, 14)
    self.later = W.Button(f, "Set Up Later", 120, 24, function() WL:Later() end)
    self.later:SetPoint("BOTTOM", 0, 14)
    self.nextB = W.Button(f, "Next", 120, 24, function() WL:Go(1) end)
    self.nextB:SetPoint("BOTTOMRIGHT", -16, 14)
    self.finishB = W.Button(f, "Finish Setup", 120, 24, function() WL:Finish() end)
    self.finishB:SetPoint("BOTTOMRIGHT", -16, 14)
    self.switchQ = W.Button(f, "Use Questing Only", 150, 22, function()
        WL.draft.dungeons = "questing" WL.msg:SetText("") WL:Render()
    end)
    self.switchQ:SetPoint("BOTTOMRIGHT", -16, 42)
    -- The client runs a dropdown's list function as soon as it is created (before any draft exists), so
    -- every list and label function here must work without a draft.
    self.guideDD = W.Dropdown(content, ns.name .. "WelcomeGuide", 320, function()
        local out, d = {}, WL.draft or {}
        for _, g in ipairs(S():Guides()) do
            out[#out + 1] = { text = string.format("%s (%d-%d)", g.name, g.minLevel, g.maxLevel), value = g.id, checked = d.guide == g.id }
        end
        return out
    end, function(v) if WL.draft then WL.draft.guide = v WL:Render() end end)
    self.guideDD.label = function()
        local g = WL.draft and WL.draft.guide and ns.Guides:Get(WL.draft.guide)
        return g and string.format("%s (%d-%d)", g.name, g.minLevel or 1, g.maxLevel or ns.Target.maxLevel) or "Choose a guide"
    end
    self.gearDD = W.Dropdown(content, ns.name .. "WelcomeGear", 320, function()
        local out = {}
        local d = WL.draft or {}
        for _, p in ipairs(S():GearProfiles()) do out[#out + 1] = { text = p.name, value = p.id, checked = d.gear == p.id } end
        return out
    end, function(v) if WL.draft then S():SetGear(WL.draft, v) WL:Render() end end)
    self.gearDD.label = function()
        local d = WL.draft or {}
        for _, p in ipairs(S():GearProfiles()) do if p.id == d.gear then return p.name end end
        return "-"
    end
    if UISpecialFrames then table.insert(UISpecialFrames, f:GetName()) end
    f:SetScript("OnHide", function() if WL.draft and not WL.finishing and WL.open then WL:Later(true) end end)
    self.frame = f
    f:Hide()
    return f
end

function WL:StepId() return S().STEPS[self.draft.step].id end

-- Lays out the current step from the draft.
function WL:Render()
    if not self.frame or not self.draft then return end
    local d = self.draft
    local n = #S().STEPS
    self:Begin()
    render[self:StepId()](d)
    self.content:SetHeight(-self.y + 8)
    self.progress:SetText(string.format("Step %d of %d: %s", d.step, n, S().STEPS[d.step].title))
    for i, t in ipairs(self.dots) do
        if i == d.step then t:SetTextColor(1, 0.82, 0) elseif i < d.step then t:SetTextColor(1, 1, 1) else t:SetTextColor(0.5, 0.5, 0.5) end
    end
    if d.step > 1 then self.back:Enable() else self.back:Disable() end
    self.nextB:SetShown(d.step < n)
    self.finishB:SetShown(d.step == n)
    self.switchQ:SetShown(self:StepId() == "dungeons" and d.mode == "speed" and d.dungeons == "selected" and #S():SelectedDungeons(d) == 0)
end

-- Back (-1) or Next (+1). Next checks the current step first; Back never loses anything.
function WL:Go(delta)
    local d = self.draft
    if delta > 0 then
        local ok, errs = S():Validate(d, self:StepId())
        if not ok then self.msg:SetText(errs[1]) self:Render() return false end
    end
    d.step = math.max(1, math.min(#S().STEPS, d.step + delta))
    self.msg:SetText("")
    if self.scroll.SetVerticalScroll then self.scroll:SetVerticalScroll(0) end
    self:Render()
    return true
end

function WL:Finish()
    self.finishing = true
    local ok, msg = S():Finish(self.draft)
    self.finishing = nil
    if not ok then
        if self.msg then self.msg:SetText(msg) end
        ns:Print(msg)
        self:Render()
        return false
    end
    self.open, self.draft = nil, nil
    if self.frame then self.frame:Hide() end
    if ns.MainFrame and ns.MainFrame.Show then ns.MainFrame:Show() end
    ns:Print("Setup saved. Run it again any time: Settings -> General -> Run Setup Again, or /" .. ns.slash .. " setup.")
    return true
end

-- Set Up Later / close: nothing is applied (Setup:Postpone).
function WL:Later(fromHide)
    local first = not S():Done()
    S():Postpone()
    self.open, self.draft = nil, nil
    if not fromHide and self.frame then self.frame:Hide() end
    if first then ns:Print("Setup postponed; your choices so far are kept. Resume it with /" .. ns.slash .. " setup or Settings -> General.") end
end

-- Opens the wizard. `rerun`: start from the current configuration (setup already done).
function WL:Open(rerun)
    self:Build()
    self.draft = S():Draft(rerun or S():Done())
    self.open = true
    if self.msg then self.msg:SetText(S():State().lastError or "") end
    self:Render()
    self.frame:Show()
end

-- At login: shown once for a character whose setup is not finished, unless dismissed this session. In combat
-- it waits until combat ends.
function WL:Init()
    if not S():Needed() then return end
    local function show()
        if not S():Needed() or S().dismissed or WL.open then return end
        if ns.Compat.InCombat() then WL.waitCombat = true return end
        WL:Open()
    end
    ns:On("PLAYER_REGEN_ENABLED", function() if WL.waitCombat then WL.waitCombat = nil show() end end)
    C_Timer.After(2, show)
end
