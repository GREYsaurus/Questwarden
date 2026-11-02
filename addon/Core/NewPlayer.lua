-- Questwarden - new-player explainers: what each kind of guide step means, the keys that matter, short hints
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- This program is free software: you can redistribute it and/or modify it under the terms of the
-- GNU General Public License as published by the Free Software Foundation, version 3.
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
-- even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details. The complete license text is in LICENSE.
--
-- Setting newPlayerTips (off by default; the setup wizard offers it). Shown in the tip window (UI/TipWindow.lua) or
-- chat, written for this project:
--   * the first time each kind of step becomes current, one or two sentences on what it means and how to do it;
--   * once, the keys for bags, quest log, spellbook, talents, map and character (read from your key bindings);
--   * your bags almost full (at most every 10 minutes), your first death, the first talent point at level 10.
-- Each explainer is shown once per character (ns.char.explained); /qw newplayer reset shows them again.

local _, ns = ...

local NP = {}
ns.NewPlayer = NP

local BAG_LOW = 2          -- free bag slots that count as "almost full"
local BAG_REPEAT = 600     -- seconds between bag reminders

local function prof() return ns.db.profile end
local function seen() ns.char.explained = type(ns.char.explained) == "table" and ns.char.explained or {} return ns.char.explained end

-- The key bound to a game action, or the client's usual default.
local KEYS = {
    bags = { "OPENALLBAGS", "B" }, questlog = { "TOGGLEQUESTLOG", "L" }, spellbook = { "TOGGLESPELLBOOK", "P" },
    talents = { "TOGGLETALENTS", "N" }, map = { "TOGGLEWORLDMAP", "M" }, character = { "TOGGLECHARACTER0", "C" },
}
function NP.Key(id)
    local k = KEYS[id]
    local bound = k and GetBindingKey and GetBindingKey(k[1])
    return bound or (k and k[2]) or "?"
end

-- What each step kind means. Functions so the key names are read when shown.
NP.STEPS = {
    accept = function() return "\"Accept\" means: talk to the NPC (right-click them) and press Accept on the quest. NPCs with a yellow ! over their head have a quest for you. Your quests are in the quest log (" .. NP.Key("questlog") .. ")." end,
    complete = function() return "\"Complete\" means: do what the quest asks, usually killing creatures or collecting items they drop. The arrow and the map show where. Loot creatures you kill by right-clicking them. Progress shows under the step." end,
    turnin = function() return "\"Turn in\" means: go back to the NPC (a yellow ? over their head means a quest is ready), right-click them, then press Complete Quest. If you can choose a reward, the add-on marks the best one with a green arrow." end,
    ["goto"] = function() return "\"Go to\" means: walk to the place the arrow points at. The yellow arrow on screen and the pin on the map (" .. NP.Key("map") .. ") show the way." end,
    travel = function() return "\"Travel\" means: make your way to the next area. Follow the arrow; roads are usually the safest way." end,
    note = function() return "Notes are tips from the guide. Read them and press the step's check mark (or /" .. ns.slash .. " next) to move on." end,
    train = function() return "\"Train\" means: visit your class trainer to learn new spells. Spells get stronger ranks as you level, and each costs a little money. The guide lists what is worth learning." end,
    fp = function() return "\"Flight path\" means: talk to the flight master (they stand next to their flying mount) to learn this flight point. Later you can fly between points you know for a small fee." end,
    fly = function() return "\"Fly\" means: talk to the flight master and pick the destination on the map that opens. Flying is automatic; you can do something else while you travel." end,
    hs = function() return "\"Hearth\" means: use your Hearthstone (it is in your bags, " .. NP.Key("bags") .. ") to teleport back to the inn where it is set. It has a long cooldown, so the guide only uses it when it saves time." end,
    bind = function() return "\"Set your hearthstone\" means: talk to the innkeeper and choose to make this inn your home. Your Hearthstone then takes you back here." end,
    level = function() return "This step waits until you reach the level shown. Keep questing or kill creatures near your level until then." end,
    grind = function() return "\"Grind\" means: kill creatures in this area until you reach the level shown. It is the guide's way of catching up when quests run out." end,
    talk = function() return "\"Talk\" means: right-click the NPC and pick the option the guide names." end,
    buy = function() return "\"Buy\" means: right-click the merchant to open their shop, then right-click the item to buy it." end,
    use = function() return "\"Use\" means: use the item named in the step. Usable quest items also appear as buttons in a small window near the guide." end,
    collect = function() return "\"Collect\" means: gather the items named in the step, from creatures, objects on the ground or a merchant." end,
    dungeon = function() return "Dungeons are instances for a group of five players. You can skip this step to keep questing alone; the guide only shows dungeon steps if you chose them in setup." end,
}

function NP:Say(text) ns.TipWindow:Say("New player tip", text) end

-- Once per character: id is "step:<kind>", "keys", "death", "talents".
function NP:Once(id, text)
    if not (prof().newPlayerTips and text) then return false end
    local s = seen()
    if s[id] then return false end
    s[id] = true
    self:Say(text)
    return true
end

function NP:KeysText()
    return string.format("Useful keys: %s bags, %s quest log, %s spellbook, %s talents (from level 10), %s map, %s character and gear. Right-click NPCs to talk, creatures to attack and corpses to loot.",
        NP.Key("bags"), NP.Key("questlog"), NP.Key("spellbook"), NP.Key("talents"), NP.Key("map"), NP.Key("character"))
end

function NP:OnStep()
    if not prof().newPlayerTips then return end
    self:Once("keys", self:KeysText())
    local s = ns.Engine and ns.Engine:CurrentStep()
    local kind = s and s[1]
    if kind == "complete" and ns.DungeonRun and ns.DungeonRun:RunPhase(s) then kind = "dungeon" end
    local f = kind and NP.STEPS[kind]
    if f then self:Once("step:" .. kind, f()) end
end

function NP:OnBags()
    if not prof().newPlayerTips or not ns.Assist then return end
    local free = ns.Assist:FreeSlots()
    local now = GetTime and GetTime() or 0
    if free <= BAG_LOW and (not self.lastBag or now - self.lastBag >= BAG_REPEAT) then
        self.lastBag = now
        self:Say("Your bags are almost full (" .. free .. " free). Sell grey items at any merchant: right-click the merchant, then right-click the items in your bags (" .. NP.Key("bags") .. ").")
    end
end

function NP:OnDead()
    self:Once("death", "You died. Click Release Spirit, then run back to your body as a ghost (the arrow points there) and click Resurrect. The Spirit Healer at the graveyard can bring you back on the spot instead, but that damages your gear and can leave you weakened for a while.")
end

function NP:OnLevel(level)
    if (level or 0) >= 10 then
        self:Once("talents", "You have a talent point to spend: press " .. NP.Key("talents") .. ". You get one more each level. If you chose a talent plan, the talent window marks which one to take.")
    end
end

-- /qw newplayer reset
function NP:Reset() ns.char.explained = {} end

function NP:Init()
    ns:Listen("STEP_CHANGED", function() NP:OnStep() end)
    ns:Listen("GUIDE_CHANGED", function() NP:OnStep() end)
    ns:On("BAG_UPDATE", function() ns:Throttle("newplayer-bags", 2, function() NP:OnBags() end) end)
    ns:On("PLAYER_DEAD", function() NP:OnDead() end)
    ns:On("PLAYER_LEVEL_UP", function(_, level) NP:OnLevel(level) end)
    C_Timer.After(5, function() NP:OnStep() end)
end
