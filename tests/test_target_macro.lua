-- Questwarden - headless tests: the targeting macro marks the step's mobs (markWithMacro, Core/Assist.lua)
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- SPDX-License-Identifier: GPL-3.0-only
-- Loaded by tests/run_tests.lua after boot; uses TEST.check and TEST.ns.

local check, ns = TEST.check, TEST.ns
local A, M, E = ns.Assist, ns.Marker, ns.Engine
local prof = ns.db.profile

local function loadStepWith(guideId, pred)
    E:Load(guideId, { reset = true })
    local idx
    for i, s in ipairs(E.guide.steps) do if pred(s) then idx = i break end end
    for i = 1, idx - 1 do E.progress.done[i] = true end
    E:Refresh()
    M:OnStep()
    return idx
end
MOCK.questLog, MOCK.completed = {}, {}
ns.Tracker.turnedIn = {}
ns.Tracker:Scan()
MOCK.units, MOCK.icons, MOCK.markCalls = {}, {}, 0

check(prof.markWithMacro == true, "marking by the targeting macro is the default")
loadStepWith("H_OrcTroll_Durotar", function(s) return s[1] == "complete" and s.q == 790 end)
local body, n = A:MacroBody()
check(M.rule and M.rule.types[3281] == 8, "the step's rule gives Sarkoth the skull")
check(string.find(body, "/cleartarget\n/tar Sarkoth\n/tm [harm,nodead]!8", 1, true) ~= nil and n >= 1,
    "the macro targets Sarkoth and marks it with the skull (" .. body:gsub("\n", " | ") .. ")")
check(#body <= 255, "the macro fits the 255-character limit (" .. #body .. ")")
-- the current step's own mob comes last, so the press ends on it
local last = body:match("/tar ([^\n]+)\n/tm [^\n]*$") or body:match("/tar ([^\n]+)$")
check(last == "Sarkoth", "the current step's mob is targeted last (" .. tostring(last) .. ")")

-- Every /tm follows its own /cleartarget + /tar, so a kind not in view marks nothing
local ok = true
for chunk in (body .. "\n"):gmatch("(/cleartarget\n.-)\n?%f[/]") do
    if chunk:find("/tm", 1, true) and not chunk:find("^/cleartarget\n/tar [^\n]+\n/tm %[harm,nodead%]!%d$") then ok = false end
end
check(ok, "each mark is guarded: clear, target by name, then /tm [harm,nodead]!icon")

-- Pressing the macro: a small stand-in for the client's /cleartarget, /tar (nearest living unit of that name)
-- and /tm [harm,nodead]!icon (one icon per unit, one unit per icon) shows the marker moving between mobs.
local world = {}
local function press(macro)
    local tgt, icons = nil, MOCK.icons
    for line in macro:gmatch("[^\n]+") do
        if line == "/cleartarget" then tgt = nil
        else
            local name = line:match("^/tar (.+)$")
            if name then
                local best
                for _, u in ipairs(world) do
                    if u.name == name and not u.dead and (not best or u.dist < best.dist) then best = u end
                end
                tgt = best or tgt
            else
                local icon = tonumber(line:match("^/tm %[harm,nodead%]!(%d)$"))
                if icon and tgt and not tgt.dead and icons[tgt.guid] ~= icon then
                    for g, i in pairs(icons) do if i == icon then icons[g] = nil end end
                    icons[tgt.guid] = icon
                end
            end
        end
    end
    return tgt
end
local function mob(guid, name, dist) local u = { guid = guid, name = name, dist = dist } world[#world + 1] = u return u end
MOCK.icons = {}
local first, second = mob("w1", "Sarkoth", 10), mob("w2", "Sarkoth", 25)
local t = press(body)
check(MOCK.icons.w1 == 8 and t == first, "a press targets and marks the nearest one")
press(body)
check(MOCK.icons.w1 == 8 and MOCK.icons.w2 == nil, "pressing again keeps the mark (never toggled off)")
first.dead = true
MOCK.icons.w1 = nil -- the game removes a dead mob's icon
press(body)
check(MOCK.icons.w2 == 8, "after a kill the next press moves the mark to the next mob")
local third = mob("w3", "Sarkoth", 5)
press(body)
check(MOCK.icons.w3 == 8 and MOCK.icons.w2 == nil, "a nearer mob takes the mark on the next press (marks are never stuck)")
world = {}
press(body)
check(MOCK.icons.w3 == 8, "nothing in view: nothing is marked or moved")
MOCK.icons = {}

-- The add-on does not mark by itself while the macro marks
local sarkoth = MOCK.creature(3281, 11, "Sarkoth")
MOCK.units.target = sarkoth
MOCK.fire("PLAYER_TARGET_CHANGED")
MOCK.tick(0.6)
check(MOCK.markCalls == 0 and MOCK.icons[sarkoth.guid] == nil, "with macro marking the add-on never calls SetRaidTarget itself")

-- Off: the old macro (targeting only) and automatic marking
prof.markWithMacro = false
body = A:MacroBody()
check(not body:find("/tm", 1, true) and body:find("/tar Sarkoth", 1, true), "macro marking off: the macro only targets")
M:OnStep()
MOCK.fire("PLAYER_TARGET_CHANGED")
MOCK.tick(0.6)
check(MOCK.icons[sarkoth.guid] == 8, "macro marking off: automatic marking marks again")
prof.markWithMacro = true

-- A kill step whose item drops from several wolves: one target-and-mark per kind
ns.Engine:Load("A_Human_Elwynn", { reset = true })
MOCK.units, MOCK.icons, MOCK.markCalls = {}, {}, 0
M:OnStep()
check(#ns.errors == 0, "no captured errors after targeting macro tests: " .. table.concat(ns.errors, " | "))
