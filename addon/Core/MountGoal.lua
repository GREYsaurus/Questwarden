-- Questwarden - mount savings goal: the gold your first mount costs against what you have
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- This program is free software: you can redistribute it and/or modify it under the terms of the
-- GNU General Public License as published by the Free Software Foundation, version 3.
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
-- even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details. The complete license text is in LICENSE.
--
-- Setting mountGoal (off by default; the setup wizard offers it). Prices are target data (Database/Riding.lua,
-- with their source); a target without them never shows the goal. From LEAD levels before the riding level until
-- you can ride (TBC: Apprentice Riding known) or LATE levels after it, the guide window shows one line, for
-- example "Mount at 40: 100g - you have 37g 20s (63g to go)", and chat says so when you level up in that range.
-- Paladins and Warlocks learn their first mount from the class trainer: their line says so, plus the riding
-- price where they still need riding (TBC). /qw mount prints the goal any time.

local _, ns = ...

local MG = {}
ns.MountGoal = MG

local LEAD = 10   -- levels before the riding level that the line appears
local LATE = 5    -- levels after it that it keeps showing (Classic Era has no riding spell to check)

local function prof() return ns.db.profile end
local function money(c) return GetCoinTextureString and GetCoinTextureString(c) or (math.floor(c / 10000) .. "g") end

-- The class mount spell for your class, or nil.
local function classMount(R)
    local class = ns.Compat.PlayerInfo().class
    return R.classMounts and R.classMounts[class]
end

-- Cost of the first mount for this character in copper, and what it is made of.
function MG:Cost()
    local R = ns.Riding
    if not R then return nil end
    local cm = classMount(R)
    if cm then
        local price = 0
        local wt = ns.WhatsTrainingData
        local row = wt and wt.classes and wt.classes[ns.Compat.PlayerInfo().class]
        row = row and row[cm]
        if row and row[2] then price = row[2] end
        local riding = R.classMountNeedsRiding and R.training or 0
        return price + riding, { classSpell = cm, classPrice = row and row[2], riding = riding }
    end
    return R.training + R.mount, { riding = R.training, mount = R.mount }
end

-- True once you can ride (known riding spell or class mount); nil when the client cannot tell.
function MG:CanRide()
    local R = ns.Riding
    if not R or not IsSpellKnown then return nil end
    local cm = classMount(R)
    if cm and IsSpellKnown(cm) and not (R.classMountNeedsRiding and R.ridingSpell and not IsSpellKnown(R.ridingSpell)) then return true end
    if R.ridingSpell and IsSpellKnown(R.ridingSpell) and not cm then return true end
    return false
end

function MG:Active()
    local R = ns.Riding
    if not (prof().mountGoal and R) then return false end
    local level = UnitLevel("player") or 1
    if level < R.level - LEAD or level > R.level + LATE then return false end
    return not self:CanRide()
end

-- The goal line, or nil.
function MG:Line(force)
    local R = ns.Riding
    if not R or not (force or self:Active()) then return nil end
    local cost, parts = self:Cost()
    local have = GetMoney and GetMoney() or 0
    local head
    if parts.classSpell then
        local spell = GetSpellInfo(parts.classSpell) or "your class mount"
        head = string.format("Mount at %d: learn %s from your class trainer", R.level, spell)
        if cost > 0 then head = head .. string.format(" (%s%s)", money(cost), parts.riding > 0 and (", with Apprentice Riding") or "") end
    else
        head = string.format("Mount at %d: %s (riding %s + mount %s)", R.level, money(cost), money(parts.riding), money(parts.mount))
    end
    if cost <= 0 then return head .. "." end
    local rest = cost - have
    return head .. " - you have " .. money(have) .. (rest > 0 and (" (" .. money(rest) .. " to go)") or " - enough!")
end

function MG:Print()
    local l = self:Line(true)
    if not l then return ns:Print("No mount prices for " .. ns.Target.name .. ".") end
    ns:Print(l)
    if ns.Riding.discountText then ns:Print("  " .. ns.Riding.discountText) end
end

function MG:OnLevel()
    if not self:Active() then return end
    local l = self:Line()
    if l then ns:Print("|cffffd100Savings goal:|r " .. l) end
end

function MG:Init()
    ns:On("PLAYER_LEVEL_UP", function() C_Timer.After(1, function() MG:OnLevel() end) end)
    ns:On("PLAYER_MONEY", function() if MG:Active() then ns:Throttle("mountgoal", 2, function() ns:Fire("REFRESH") end) end end)
end
