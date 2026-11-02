-- Questwarden - profession starter tips: which professions suit a new character and where their trainers are
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- This program is free software: you can redistribute it and/or modify it under the terms of the
-- GNU General Public License as published by the Free Software Foundation, version 3.
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
-- even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details. The complete license text is in LICENSE.
--
-- Setting professionTips (off by default; the setup wizard offers it). At level START (or at login above it),
-- once per character, a few lines of advice written for this project, then the trainers in the zone you are
-- in. Trainers come from the bundled NPC data by their English sub-name (for example "Mining Trainer",
-- "Journeyman Alchemist"), friendly to your faction, as the class trainer search does (Classes/Trainer.lua).
-- /qw professions lists the trainers here (else in your capital); /qw professions <name> points the arrow at one.

local _, ns = ...

local PF = {}
ns.ProfessionTips = PF

local START = 5

local function prof() return ns.db.profile end

-- Profession, kind, trainer sub-names (both naming styles in the bundled data).
PF.LIST = {
    { "Herbalism", "gathering", { "Herbalism Trainer" } },
    { "Mining", "gathering", { "Mining Trainer" } },
    { "Skinning", "gathering", { "Skinning Trainer" } },
    { "Alchemy", "crafting", { "Alchemy Trainer", "Journeyman Alchemist", "Apprentice Alchemist" } },
    { "Blacksmithing", "crafting", { "Blacksmithing Trainer", "Journeyman Blacksmith", "Apprentice Blacksmith" } },
    { "Enchanting", "crafting", { "Enchanting Trainer", "Journeyman Enchanter", "Apprentice Enchanter" } },
    { "Engineering", "crafting", { "Engineering Trainer", "Journeyman Engineer", "Apprentice Engineer" } },
    { "Leatherworking", "crafting", { "Leatherworking Trainer", "Journeyman Leatherworker", "Apprentice Leatherworker" } },
    { "Tailoring", "crafting", { "Tailoring Trainer", "Journeyman Tailor", "Apprentice Tailor" } },
    { "Jewelcrafting", "crafting", { "Jewelcrafting Trainer", "Apprentice Jewelcrafter" } },
    { "First Aid", "secondary", { "First Aid Trainer" } },
    { "Cooking", "secondary", { "Cooking Trainer" } },
    { "Fishing", "secondary", { "Fishing Trainer" } },
}

PF.ADVICE = {
    "Professions are optional, but they help. You can have two main professions; Cooking, First Aid and Fishing come on top of those.",
    "Easiest start: two gathering professions (Herbalism, Mining or Skinning). You collect as you quest and sell to other players at the auction house, which pays for your mount.",
    "Or pair a gathering profession with the crafting one that uses it: Mining with Blacksmithing or Engineering, Skinning with Leatherworking, Herbalism with Alchemy. Tailoring and Enchanting use cloth and items from creatures.",
    "First Aid makes bandages that heal you between fights, and Cooking turns meat from creatures into food. Both are cheap and make leveling easier.",
    "Changing a main profession later means starting the new one from scratch, so pick ones you like.",
}

-- Nearest trainer of one profession: zone, x, y, name (same zone first, else your capital).
function PF:Trainer(entry)
    local TR = ns.Trainer
    for _, sub in ipairs(entry[3]) do
        local z, x, y, name = TR:NearestHere(sub)
        if z then return z, x, y, name, true end
    end
    for _, sub in ipairs(entry[3]) do
        local z, x, y, name = TR:NearestNPC(sub)
        if z then return z, x, y, name, false end
    end
end

function PF:Find(name)
    name = string.lower(name or "")
    for _, e in ipairs(self.LIST) do
        if string.lower(e[1]) == name or string.find(string.lower(e[1]), name, 1, true) == 1 then return e end
    end
end

-- Trainer lines; `hereOnly`: only trainers in the zone you are in.
function PF:Lines(hereOnly)
    local out = {}
    for _, e in ipairs(self.LIST) do
        local z, x, y, name, here = self:Trainer(e)
        if z and (here or not hereOnly) then
            out[#out + 1] = string.format("%s (%s): %s, %s %.0f, %.0f", e[1], e[2], tostring(name), ns.DB.ZoneName(z) or "?", x, y)
        end
    end
    return out
end

function PF:PrintAll()
    local lines = self:Lines(false)
    if #lines == 0 then return ns:Print("No profession trainers of your faction found in the data.") end
    ns:Print("Profession trainers (nearest in your zone, else your capital). /" .. ns.slash .. " professions <name> points the arrow there:")
    for _, l in ipairs(lines) do DEFAULT_CHAT_FRAME:AddMessage("  " .. l) end
end

function PF:Waypoint(name)
    local e = self:Find(name)
    if not e then return ns:Print("Unknown profession '" .. tostring(name) .. "'.") end
    local z, x, y, npc = self:Trainer(e)
    if not z then return ns:Print("No " .. e[1] .. " trainer of your faction found in the data.") end
    ns.Nav:SetTarget(z, x, y, npc .. " (" .. e[1] .. ")", "manual")
    ns:Print("Arrow set to " .. npc .. ", " .. e[1] .. " trainer.")
end

-- Once per character, from level START.
function PF:Check()
    if not prof().professionTips or ns.char.professionTipsShown then return end
    if (UnitLevel("player") or 1) < START then return end
    ns.char.professionTipsShown = true
    local more = {}
    for i = 2, #self.ADVICE do more[#more + 1] = "- " .. self.ADVICE[i] end
    local here = self:Lines(true)
    if #here > 0 then
        more[#more + 1] = "Trainers in this zone:"
        for _, l in ipairs(here) do more[#more + 1] = "  " .. l end
    end
    more[#more + 1] = "/" .. ns.slash .. " professions lists every trainer; /" .. ns.slash .. " professions mining (for example) points the arrow there."
    ns.TipWindow:Say("Professions", self.ADVICE[1], more)
end

function PF:Init()
    ns:On("PLAYER_LEVEL_UP", function() C_Timer.After(2, function() PF:Check() end) end)
    C_Timer.After(12, function() PF:Check() end)
end
