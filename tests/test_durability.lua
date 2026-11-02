-- Questwarden - headless tests for the low durability warning (loaded by run_tests.lua)
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- SPDX-License-Identifier: GPL-3.0-only

local check, ns = TEST.check, TEST.ns
local D = ns.Durability
local prof = ns.db.profile

local dur = {}   -- [slot] = { cur, max }
local warnings, sounds = {}, 0
local real = { dur = GetInventoryItemDurability, notice = RaidNotice_AddMessage, frame = RaidWarningFrame,
    chat = ChatTypeInfo, sound = PlaySound, kit = SOUNDKIT, setting = prof.durabilityWarn }
GetInventoryItemDurability = function(slot) local d = dur[slot] if d then return d[1], d[2] end end
RaidNotice_AddMessage = function(_, text) warnings[#warnings + 1] = text end
RaidWarningFrame, ChatTypeInfo = {}, { RAID_WARNING = {} }
SOUNDKIT = { RAID_WARNING = 8959 }
PlaySound = function(id) if id == 8959 then sounds = sounds + 1 end end
local function event() MOCK.fire("UPDATE_INVENTORY_DURABILITY") end

prof.durabilityWarn = true
D.count = 0
dur = { [1] = { 50, 50 }, [5] = { 100, 100 }, [7] = { 40, 75 } }
event()
check(#warnings == 0 and sounds == 0, "no warning while all gear is at 30% or more")
dur[5] = { 29, 100 }
event()
check(warnings[1] == "Low durability: 1 piece is below 30%. Repair soon.", "a piece below 30% gives a warning with the count: " .. tostring(warnings[1]))
check(sounds == 1, "...and the warning sound")
event()
check(#warnings == 1 and sounds == 1, "the same count does not warn again")
dur[1], dur[7] = { 0, 50 }, { 10, 75 }
event()
check(warnings[2] == "Low durability: 3 pieces are below 30%. Repair soon.", "another piece dropping below warns again with the new count")
check(D.LowCount() == 3, "broken pieces count as low")
dur = { [1] = { 50, 50 }, [5] = { 100, 100 }, [7] = { 75, 75 } }
event()
dur[5] = { 20, 100 }
event()
check(#warnings == 3 and sounds == 3, "after a repair the warning comes again")
prof.durabilityWarn = false
D.count = 0
event()
check(#warnings == 3 and sounds == 3, "setting off: no warning")
dur[2] = { 5, 0 }
check(D.LowCount() == 1, "items without durability are ignored")

GetInventoryItemDurability, RaidNotice_AddMessage, RaidWarningFrame, ChatTypeInfo = real.dur, real.notice, real.frame, real.chat
PlaySound, SOUNDKIT, prof.durabilityWarn = real.sound, real.kit, real.setting
D.count = 0
