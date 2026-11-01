-- Questwarden - headless tests: the look (UI/Widgets.lua theme helpers, settings sidebar and search, guide card)
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- SPDX-License-Identifier: GPL-3.0-only
-- Loaded by tests/run_tests.lua after boot (TBC fixture); uses TEST.check and TEST.ns.

local check, ns = TEST.check, TEST.ns
local W, CF, ST = ns.Widgets, ns.Config, ns.StepText
local function prof() return ns.db.profile end

-- Accent colours ---------------------------------------------------------------------------------------
check(ns.PROFILE_DEFAULTS.accentColor == "blue", "the accent colour is blue by default")
local blue = { W.THEME.accent[1], W.THEME.accent[2], W.THEME.accent[3] }
check(W.ApplyAccent("green") and W.THEME.accent[2] > W.THEME.accent[3], "an accent preset changes the theme's accent")
check(not W.ApplyAccent("plaid"), "an unknown accent is refused")
W.ApplyAccent("blue")
check(W.THEME.accent[1] == blue[1] and W.THEME.accent[3] == blue[3], "blue is the original accent")
local accentItem
for _, it in ipairs(ns.ConfigPages.general.items(CF)) do if it.key == "accentColor" then accentItem = it end end
check(accentItem and #accentItem.values() == #W.ACCENTS, "Accent Colour is on General with every preset")

-- Switch ----------------------------------------------------------------------------------------------
local sw = W.Switch(UIParent)
sw:SetChecked(true)
check(sw.knob.point and sw.knob.point[1] == "RIGHT", "a switch that is on has its knob on the right")
sw:SetChecked(false)
check(sw.knob.point[1] == "LEFT", "...and on the left when off")
sw:Disable()
check(sw:GetChecked() == false, "disabling keeps the state")

-- Settings sidebar and search ---------------------------------------------------------------------------
CF:Show("general")
check(CF.searchBox ~= nil, "the sidebar has a search box")
local p = CF.tabs.general.point
check(p and p[2] == CF.frame and p[4] == 16 and p[5] == -110, "tabs are down the sidebar")
check(CF.tabs.guide.point[5] == -140, "...one under the other")
CF:Search("junk")
check(CF.current == "search:junk" and CF.built["search:junk"] and #CF.built["search:junk"].widgets > 1, "a search shows its own page")
for id, tab in pairs(CF.tabs) do check(not tab.selected, "no tab is selected while searching (" .. id .. ")") end
local items = CF:SearchItems("junk")
check(items[1].type == "header" and items[1].text == "General", "results are grouped under their tab's name")
local labels = {}
for _, it in ipairs(items) do if it.label then labels[#labels + 1] = it.label end end
check(#labels >= 3, "every option about junk is found (" .. table.concat(labels, ", ") .. ")")
for _, it in ipairs(items) do
    if it.label then check(string.find(string.lower(it.label .. " " .. (it.tip or "")), "junk", 1, true), "result matches: " .. it.label) end
end
local none = CF:SearchItems("zzzqqq")
check(#none == 1 and none[1].type == "desc" and string.find(none[1].text, "No option matches", 1, true), "no match says so")
check(#CF:SearchItems("AUTO REPAIR") > 0, "search ignores case")
prof().simpleSettings = true
CF:Rebuild()
local simpleHit = false
for _, it in ipairs(CF:SearchItems("modified right click")) do if it.key == "junkModifierToggle" then simpleHit = true end end
check(not simpleHit, "the simple view's hidden options are not found")
prof().simpleSettings = false
CF:Rebuild()
CF:Search("junk")
CF:Search("")
check(CF.current == "general", "clearing the search goes back to the last tab")
CF:Search("j")
check(CF.current == "general", "one letter does not search")
CF.frame:Hide()

-- Guide card: objective progress ------------------------------------------------------------------------
local getEntry = ns.Tracker.GetEntry
ns.Tracker.GetEntry = function() return { objectives = { { text = "Wolf Meat: 3/8" }, { text = "Gnolls slain: 2/2", done = true }, { text = "Find the cave" } } } end
local s = { "complete", q = 1 }
check(math.abs(ST:Progress(s) - (3 / 8 + 1 + 0) / 3) < 1e-9, "progress averages the objectives")
s.obj = 1
check(math.abs(ST:Progress(s) - 3 / 8) < 1e-9, "a step for one objective counts only that one")
check(ST:Progress({ "accept", q = 1 }) == nil, "no progress bar on other kinds of step")
ns.Tracker.GetEntry = function() return nil end
check(ST:Progress({ "complete", q = 1 }) == nil, "no progress bar for a quest not in the log")
ns.Tracker.GetEntry = getEntry
check(pcall(function() ns.MainFrame:Render() end), "the guide window renders")
local r = ns.MainFrame.rows[1]
if r then check(r.hl:IsShown() and r.accent:IsShown(), "the current step is shown as a card") end
