-- Questwarden - low durability warning (setting: durabilityWarn)
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- This program is free software: you can redistribute it and/or modify it under the terms of the
-- GNU General Public License as published by the Free Software Foundation, version 3.
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
-- even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details. The complete license text is in LICENSE.
--
-- When an equipped piece drops below LOW (30%) of its durability, a raid-warning style message says how many
-- pieces are below it, with the raid warning sound. It comes again only when the count grows (another piece
-- drops below), so repairing or dying repeatedly does not repeat it; after a repair the count starts over.
-- Also checked once after login and loading screens. Items without durability (rings, trinkets ...) are ignored.

local _, ns = ...

local D = { count = 0 }
ns.Durability = D

local LOW = 0.30
local SLOTS = 19 -- equipped inventory slots 1-19

local function prof() return ns.db.profile end

-- Equipped pieces below LOW of their durability (broken ones too).
function D.LowCount()
    if not GetInventoryItemDurability then return 0 end
    local n = 0
    for slot = 1, SLOTS do
        local cur, max = GetInventoryItemDurability(slot)
        if cur and max and max > 0 and cur / max < LOW then n = n + 1 end
    end
    return n
end

function D.Text(n)
    return string.format("Low durability: %d %s below %d%%. Repair soon.", n, n == 1 and "piece is" or "pieces are", LOW * 100)
end

-- Re-counts; warns when more pieces are low than at the last check.
function D:Check()
    local n = self.LowCount()
    local before = self.count
    self.count = n
    if n == 0 or n <= before or not prof().durabilityWarn then return end
    local text = self.Text(n)
    if RaidNotice_AddMessage and RaidWarningFrame and ChatTypeInfo then
        RaidNotice_AddMessage(RaidWarningFrame, text, ChatTypeInfo.RAID_WARNING)
    elseif UIErrorsFrame and UIErrorsFrame.AddMessage then
        UIErrorsFrame:AddMessage(text, 1, 0.3, 0.2)
    end
    if PlaySound and SOUNDKIT and SOUNDKIT.RAID_WARNING then PlaySound(SOUNDKIT.RAID_WARNING) end
end

function D:Init()
    ns:On("UPDATE_INVENTORY_DURABILITY", function() D:Check() end)
    ns:On("PLAYER_ENTERING_WORLD", function() D.count = 0 C_Timer.After(5, function() D:Check() end) end)
end
