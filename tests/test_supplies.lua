-- Questwarden - headless tests for the supply reminders and the weapon skill tips (loaded by run_tests.lua)
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- SPDX-License-Identifier: GPL-3.0-only

local check, ns = TEST.check, TEST.ns
local S, WS, E = ns.Supplies, ns.WeaponSkills, ns.Engine
local prof = ns.db.profile

local SIZE = { [1429] = { 3470.8, 2314.6 } }
local pos = { map = 1429, x = 0.5, y = 0.5 }
local real = { best = C_Map.GetBestMapForUnit, ppos = C_Map.GetPlayerMapPosition, world = C_Map.GetWorldPosFromMapPos,
    known = IsSpellKnown, say = ns.TipWindow.Say, player = {}, vendors = ns.SupplyData.vendors,
    masters = ns.SupplyData.weaponMasters, bags = MOCK.bags, equipped = MOCK.equipped,
    setting = prof.supplyReminders, tips = prof.weaponSkillTips }
for k, v in pairs(MOCK.player) do real.player[k] = v end
C_Map.GetBestMapForUnit = function() return pos.map end
C_Map.GetPlayerMapPosition = function()
    if not pos.x then return nil end
    return { GetXY = function() return pos.x, pos.y end }
end
C_Map.GetWorldPosFromMapPos = function(map, v)
    local s = SIZE[map]
    if not s then return nil end
    return map, { GetXY = function() return v.x * s[1], v.y * s[2] end }
end
local function at(x, y) pos.x, pos.y = x / 100, y / 100 end
local function goTo(i)
    for j = 1, #E.guide.steps do E.progress.done[j], E.progress.skipped[j] = j < i or nil, nil end
    E:Refresh()
end
local said = {}
ns.TipWindow.Say = function(_, title, text) said[#said + 1] = { title = title, text = text } end

-- The generated data
local d = ns.SupplyData
check(d and d.food[4540] == 1 and d.drink[159] == 1, "Tough Hunk of Bread is food and Refreshing Spring Water a drink, from level 1")
check(d.ammo[2512] == "arrow" and d.ammo[2516] == "bullet", "Rough Arrow and Light Shot are ammo")
check(d.vendors[295] and d.vendors[295][1] == "Innkeeper Farley" and ns.HasBit(d.vendors[295][4], 1) and ns.HasBit(d.vendors[295][4], 2),
    "Innkeeper Farley sells food and drink")
check(d.weaponMasters[11867] and d.weaponMasters[11867][1] == "Woo Ping" and d.weaponMasters[11867][6][10],
    "Woo Ping is a weapon master who teaches Staves")

-- An Elwynn turn-in step, a vendor next to it
E:Load("A_Human_Elwynn", { reset = true })
local iT, tx, ty
for i, s in ipairs(E.guide.steps) do
    if s[1] == "turnin" and s.q then
        local z, x, y = ns.StepText:Target(s)
        if z and ns.DB.ZoneUiMap(z) == 1429 then iT, tx, ty = i, x, y break end
    end
end
check(iT ~= nil, "an Elwynn turn-in step with a position")
d.vendors = { [900001] = { "Test Grocer", "Food & Drink", "A", 3, 12, { tx + 1, ty } },
    [900002] = { "Test Bowyer", false, "A", 4, 12, { tx, ty + 1 } },
    [900003] = { "Horde Grocer", false, "H", 3, 12, { tx, ty } } }
goTo(iT)
MOCK.player.class, MOCK.player.level, MOCK.player.faction = "MAGE", 12, "Alliance"
MOCK.items[4540] = { name = "Tough Hunk of Bread", classID = 0 }
MOCK.items[159] = { name = "Refreshing Spring Water", classID = 0 }
MOCK.bags = { [0] = { [1] = { itemID = 4540, count = 4 }, [2] = { itemID = 159, count = 20 } } }
prof.supplyReminders = true
at(tx + 2, ty)
S:Check()
check(S.current and #S.current.needs == 1 and S.current.needs[1].kind == "food", "mage with 4 food and 20 drinks: food only")
local details = table.concat(ns.StepText:Details(E.guide.steps[iT]), "\n")
check(string.find(details, "Stock up before you leave town: you have 4 food. Test Grocer (Food & Drink) sells food.", 1, true),
    "the step names what is short and who sells it: " .. details)
check(not string.find(details, "Horde Grocer", 1, true), "vendors of the other faction are left out")

MOCK.bags[0][2] = { itemID = 159, count = 3 }
S:Check()
check(S.current and #S.current.needs == 2, "food and drinks both low")
check(string.find(S:Line(), "you have 4 food and 3 drinks. Test Grocer (Food & Drink) sells food and drinks.", 1, true), "both on one line")

MOCK.player.class = "WARRIOR"
S:Check()
check(S.current and #S.current.needs == 1, "warriors are not told to buy drinks")

-- Hunters: the ranged weapon decides arrows or bullets
MOCK.player.class = "HUNTER"
MOCK.items[2504] = { name = "Worn Shortbow", classID = 2, subclassID = 2, equipLoc = "INVTYPE_RANGED" }
MOCK.items[2512] = { name = "Rough Arrow", classID = 6 }
MOCK.equipped[18] = 2504
MOCK.bags[0][3] = { itemID = 2512, count = 200 }
MOCK.bags[0][1] = { itemID = 4540, count = 20 }
MOCK.bags[0][2] = { itemID = 159, count = 20 }
S:Check()
check(S.current and S.current.needs[1].kind == "arrow" and S.current.needs[1].have == 200, "a hunter with a bow and 200 arrows: arrows")
check(string.find(S:Line(), "Test Bowyer sells arrows", 1, true), "...from the bowyer")
MOCK.bags[0][3].count = 800
S:Check()
check(S.current == nil, "enough of everything: no line")

-- Warlocks: Soul Shards need no vendor
MOCK.player.class = "WARLOCK"
MOCK.items[6265] = { name = "Soul Shard", classID = 12 }
MOCK.bags[0][4] = { itemID = 6265, count = 1 }
S:Check()
check(S.current and S.current.shards == 1 and string.find(S:Line(), "1 Soul Shard: use Drain Soul", 1, true), "a warlock with 1 Soul Shard is told")
MOCK.player.level = 9
S:Check()
check(S.current == nil, "...not before level 10")

-- Away from town, low level, setting off
MOCK.player.class, MOCK.player.level = "MAGE", 12
MOCK.bags[0][1].count = 2
at(tx + 20, ty)
S:Check()
check(S.current == nil and S.why == "not in town", "far from the step: no line")
at(tx + 2, ty)
MOCK.player.level = 4
S:Check()
check(S.current == nil, "below level 5: no line")
MOCK.player.level = 12
prof.supplyReminders = false
S:Check()
check(S.current == nil and S.why == "setting off", "setting off: no line")
prof.supplyReminders = true
d.vendors = {}
S:Check()
check(S.current == nil, "no vendor here: no line")

-- Weapon skills
local known = {}
IsSpellKnown = function(id) return known[id] == true end
check(WS.ClassCan("MAGE", 10) and not WS.ClassCan("MAGE", 1) and not WS.ClassCan("DRUID", 6), "class weapon types from Gear.CLASS_GEAR")
MOCK.equipped = {}
ns.char.weaponMastersSeen, ns.char.weaponTypeTips = {}, {}
prof.weaponSkillTips = true
d.weaponMasters = { [900010] = { "Test Master", "A", 12, tx, ty, { [10] = { 1000, 1 }, [15] = { 1000, 1 }, [6] = { 10000, 20 }, [1] = { 1000, 1 } } } }
at(tx + 1, ty)
said = {}
WS:Check()
check(#said == 1 and string.find(said[1].text, "you can learn Daggers", 1, true) and string.find(said[1].text, "and Staves", 1, true),
    "passing a weapon master: what a mage can learn there")
check(not string.find(said[1].text, "Two-Handed Axes", 1, true) and not string.find(said[1].text, "Polearms", 1, true),
    "...not what the class cannot learn")
WS:Check()
check(#said == 1, "...once per weapon master")
ns.char.weaponMastersSeen = {}
known[227], known[1180] = true, true
said = {}
WS:Check()
check(#said == 0, "nothing new to learn: no tip")

-- A weapon you cannot equip yet
known = {}
MOCK.items[2132] = { name = "Short Staff", classID = 2, subclassID = 10, equipLoc = "INVTYPE_2HWEAPON" }
MOCK.bags = { [0] = { [1] = { itemID = 2132, count = 1 } } }
said = {}
WS:CheckBags()
check(#said == 1 and string.find(said[1].text, "until you learn Staves from a weapon master: Test Master", 1, true),
    "a staff in the bags of a mage without Staves: where to learn it")
WS:CheckBags()
check(#said == 1, "...once per weapon type")
ns.char.weaponTypeTips = {}
MOCK.equipped[16] = 2132
said = {}
WS:CheckBags()
check(#said == 0, "a weapon of that type equipped counts as learned")

C_Map.GetBestMapForUnit, C_Map.GetPlayerMapPosition, C_Map.GetWorldPosFromMapPos = real.best, real.ppos, real.world
IsSpellKnown, ns.TipWindow.Say, d.vendors, d.weaponMasters = real.known, real.say, real.vendors, real.masters
MOCK.bags, MOCK.equipped, prof.supplyReminders, prof.weaponSkillTips = real.bags, real.equipped, real.setting, real.tips
for k, v in pairs(real.player) do MOCK.player[k] = v end
ns.char.weaponMastersSeen, ns.char.weaponTypeTips = nil, nil
S.current = nil
