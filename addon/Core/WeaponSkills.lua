-- Questwarden - weapon skill tips: weapon masters and weapon types you have not learned (setting: weaponSkillTips)
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- This program is free software: you can redistribute it and/or modify it under the terms of the
-- GNU General Public License as published by the Free Software Foundation, version 3.
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
-- even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details. The complete license text is in LICENSE.
--
-- Two tips, each shown once per character (UI/TipWindow.lua; it never trains anything):
--   * Passing a weapon master: within NEAR_YARDS of a weapon master of your faction (Database/Supplies.lua, from the
--     CMaNGOS trainer lists) who teaches weapon skills your class can learn (Gear.CLASS_GEAR) and you have not
--     learned yet, at your level: which ones, and what each costs. Once per weapon master.
--   * A weapon in your bags of a type your class can learn but you have not: you cannot equip it until you do, and
--     which weapon masters of your faction teach it. Once per weapon type.
-- "Learned" is the weapon's proficiency spell in your spellbook (IsSpellKnown), or a weapon of that type equipped.

local _, ns = ...

local WS = {}
ns.WeaponSkills = WS

local C = ns.Compat
local NEAR_YARDS = 60
local CHECK = 5
-- Weapon subclass (item class 2) -> its proficiency spell and name (the 1.15.9 client's SpellName table).
WS.SKILLS = {
    [0] = { 196, "One-Handed Axes" }, [1] = { 197, "Two-Handed Axes" }, [2] = { 264, "Bows" }, [3] = { 266, "Guns" },
    [4] = { 198, "One-Handed Maces" }, [5] = { 199, "Two-Handed Maces" }, [6] = { 200, "Polearms" },
    [7] = { 201, "One-Handed Swords" }, [8] = { 202, "Two-Handed Swords" }, [10] = { 227, "Staves" },
    [13] = { 15590, "Fist Weapons" }, [15] = { 1180, "Daggers" }, [16] = { 2567, "Thrown" }, [18] = { 5011, "Crossbows" },
}
local WEAPON_SLOTS = { 16, 17, 18 }

local function prof() return ns.db.profile end
local function masters() return ns.SupplyData and ns.SupplyData.weaponMasters or {} end

local function factionTag(faction) return faction == "Alliance" and "A" or faction == "Horde" and "H" or nil end

-- Whether your class can learn this weapon type at all.
function WS.ClassCan(class, sub)
    local rules = ns.Gear and ns.Gear.CLASS_GEAR[class]
    for _, w in ipairs(rules and rules.weapons or {}) do if w == sub then return true end end
    return false
end

-- Whether you have learned this weapon type: its proficiency spell, or such a weapon equipped.
function WS.Known(sub)
    local sk = WS.SKILLS[sub]
    if not sk then return true end
    if not IsSpellKnown then return true end
    if IsSpellKnown(sk[1]) then return true end
    for _, slot in ipairs(WEAPON_SLOTS) do
        local id = GetInventoryItemID and GetInventoryItemID("player", slot)
        local d = id and ns.Gear:ItemData(id)
        if d and d.classID == 2 and d.subclassID == sub then return true end
    end
    return false
end

-- What this weapon master teaches you now: { {sub=, name=, cost=}, ... } by name.
function WS.Teachable(rec, info)
    local out = {}
    for sub, t in pairs(rec[6] or {}) do
        if WS.SKILLS[sub] and WS.ClassCan(info.class, sub) and info.level >= (t[2] or 0) and not WS.Known(sub) then
            out[#out + 1] = { sub = sub, name = WS.SKILLS[sub][2], cost = t[1] }
        end
    end
    table.sort(out, function(a, b) return a.name < b.name end)
    return out
end

-- The weapon masters of your faction who teach `sub`: { "Name (Zone)", ... }.
function WS.MastersFor(sub, faction)
    local tag, out = factionTag(faction), {}
    for _, rec in pairs(masters()) do
        if tag and string.find(rec[2], tag, 1, true) and rec[6] and rec[6][sub] then
            out[#out + 1] = rec[1] .. " (" .. (ns.DB.ZoneName(rec[3]) or "?") .. ", " .. C.FormatMoney(rec[6][sub][1]) .. ")"
        end
    end
    table.sort(out)
    return out
end

local function joinWords(t)
    if #t <= 1 then return t[1] or "" end
    return table.concat(t, ", ", 1, #t - 1) .. " and " .. t[#t]
end

-- The weapon master tip text for `rec`, or nil when it teaches you nothing now.
function WS.MasterText(rec, info)
    local list = WS.Teachable(rec, info)
    if #list == 0 then return nil end
    local parts = {}
    for _, e in ipairs(list) do parts[#parts + 1] = e.name .. " (" .. C.FormatMoney(e.cost) .. ")" end
    return rec[1] .. " is a weapon master: you can learn " .. joinWords(parts) .. " here. You can only equip a"
        .. " weapon type once you have learned it, so this is worth it when you want to use a weapon of that type."
end

-- Passing a weapon master: the tip, once per weapon master.
function WS:CheckMasters()
    local info = C.PlayerInfo()
    local tag = factionTag(info.faction)
    local pMap, px, py = C.GetPlayerMapPosition()
    local me = px and ns.Hearth.World(pMap, px, py)
    if not (tag and me) then return end
    ns.char.weaponMastersSeen = ns.char.weaponMastersSeen or {}
    for id, rec in pairs(masters()) do
        if not ns.char.weaponMastersSeen[id] and string.find(rec[2], tag, 1, true) then
            local map = ns.DB.ZoneUiMap(rec[3])
            local yd = map and ns.Hearth.Yards(me, ns.Hearth.World(map, rec[4], rec[5]))
            if yd and yd <= NEAR_YARDS then
                local text = self.MasterText(rec, info)
                if text then
                    ns.char.weaponMastersSeen[id] = true
                    ns.TipWindow:Say("Weapon master", text)
                end
            end
        end
    end
end

-- A weapon in your bags you cannot equip yet: the tip, once per weapon type.
function WS:CheckBags()
    local info = C.PlayerInfo()
    ns.char.weaponTypeTips = ns.char.weaponTypeTips or {}
    for bag = 0, C.NUM_BAGS do
        for slot = 1, C.GetContainerNumSlots(bag) do
            local it = C.GetContainerItem(bag, slot)
            local d = it and it.itemID and ns.Gear:ItemData(it.itemID)
            local sub = d and d.classID == 2 and d.subclassID
            if sub and WS.SKILLS[sub] and not ns.char.weaponTypeTips[sub] and WS.ClassCan(info.class, sub) and not WS.Known(sub) then
                local where = WS.MastersFor(sub, info.faction)
                if #where > 0 then
                    ns.char.weaponTypeTips[sub] = true
                    local name = WS.SKILLS[sub][2]
                    ns.TipWindow:Say("New weapon type", "You cannot equip " .. (d.link or d.name) .. " until you learn " .. name
                        .. " from a weapon master: " .. joinWords(where) .. ".")
                end
            end
        end
    end
end

function WS:Check()
    if not prof().weaponSkillTips or not ns.char then return end
    if UnitOnTaxi and UnitOnTaxi("player") then return end
    self:CheckMasters()
end

function WS:Init()
    ns:On("BAG_UPDATE_DELAYED", function() if prof().weaponSkillTips and ns.char then WS:CheckBags() end end)
    local acc = 0
    local f = CreateFrame("Frame")
    f:SetScript("OnUpdate", function(_, elapsed)
        acc = acc + elapsed
        if acc < CHECK then return end
        acc = 0
        WS:Check()
    end)
end
