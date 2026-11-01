-- Questwarden - headless tests: class training from the bundled What's Training? data (Classes/WhatsTrainingData.lua)
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- SPDX-License-Identifier: GPL-3.0-only
-- Loaded by tests/run_tests.lua after boot (TBC target); uses TEST.check and TEST.ns. The spellbook is a set of known
-- spell ids behind a mocked IsSpellKnown.

local check, ns = TEST.check, TEST.ns
local TR, CM, W = ns.Trainer, ns.Completionist, ns.WhatsTrainingData
local prof = ns.db.profile

-- Data: the TBC folder of the pinned upstream, inside our namespace only ----------------------------------------------
check(W and W.source and W.source.game == "TBC" and W.source.commit == "26caff2fb3cb7d0bd5ed13c15b69be71a16dbafe",
    "TBC loads What's Training's TBC data at the pinned commit")
check(_G.WhatsTrainingData == nil and _G.WhatsTraining == nil, "nothing is put in the global namespace (no clash with the add-on itself)")
local n = 0
for _, c in pairs(W.classes) do for _ in pairs(c) do n = n + 1 end end
check(n > 1500, "every class has trainer spells (" .. n .. ")")
check(W.classes.HUNTER[4187] == nil, "hunter pet abilities (taught to the pet) are not class-trainer spells")
check(W.classes.MAGE[32271] and W.classes.MAGE[32271][5] == "Alliance", "TBC-only spells are there (Teleport: Exodar, Alliance only)")

-- Entries merge the client tables with the trainer list ------------------------------------------------------------
TR.cache, TR.nameIndex = {}, nil
local function entry(class, id) for _, e in ipairs(TR:Entries(class)) do if e.id == id then return e end end end
local rend2 = entry("WARRIOR", 6546)
check(rend2 and rend2.source == "trainer" and rend2.listCost == 600 and rend2.req and rend2.req[1] == 772, "Rend 2: sold by the trainer, base price 6 silver, needs Rend 1")
check(entry("WARRIOR", 71).source == "quest", "Defensive Stance stays a class-quest spell")
check(entry("SHAMAN", 3599).source == "other", "Searing Totem 1 is not sold by the trainer (totem quest): source other")
check(entry("WARRIOR", 3127) and entry("WARRIOR", 3127).source == "trainer", "trainer-only passives the client import leaves out are added (Parry)")
local ms2 = entry("WARRIOR", 21551)
check(ms2 and ms2.talentReq == 12294, "Mortal Strike 2 needs the talent (Mortal Strike 1)")

-- Availability ----------------------------------------------------------------------------------------------------
local known = {}
local realKnown = IsSpellKnown
IsSpellKnown = function(id) return known[id] == true end
local keep = { class = MOCK.player.class, race = MOCK.player.race, faction = MOCK.player.faction, level = MOCK.player.level,
               char = ns.char.trainerSuggestions, defer = ns.char.trainerDeferLevel }
MOCK.player.class, MOCK.player.race, MOCK.player.faction, MOCK.player.level = "WARRIOR", "Human", "Alliance", 10
ns.char.trainerSuggestions, ns.char.trainerDeferLevel = "all", nil
local function ready(list, id) for _, e in ipairs(list) do if e.id == id then return true end end return false end
local a = TR:Available()
check(ready(a.ready, 772) and ready(a.ready, 6546), "Rend 1 and 2 are both ready at 10: rank 2 can be bought right after rank 1")
known[772] = true
a = TR:Available()
check(not ready(a.ready, 772) and ready(a.ready, 6546), "learning a rank updates the list (Rend 1 known, Rend 2 still ready)")
known[6546] = true
check(not ready(TR:Available().ready, 6546), "a known rank is never suggested again")
MOCK.player.level = 8
check(not ready(TR:Available().ready, 2687), "Bloodrage (level 10) is not ready at level 8")
MOCK.player.level = 10
check(ready(TR:Available().ready, 2687), "...and is ready at level 10")
MOCK.player.level = 48
check(not ready(TR:Available().ready, 21551), "Mortal Strike 2 needs the talent: not suggested without it")
known[12294] = true
check(ready(TR:Available().ready, 21551), "with the talent, Mortal Strike 2 is ready")
-- Faction: a mage's Alliance teleport never for the Horde
MOCK.player.class, MOCK.player.race, MOCK.player.faction, MOCK.player.level = "MAGE", "Orc", "Horde", 30
check(not ready(TR:Available().ready, 3561) and ready(TR:Available().ready, 3567), "faction teleports: only your faction's (Teleport: Orgrimmar, not Stormwind)")
-- Other sources are listed apart, never as a trainer purchase
MOCK.player.class, MOCK.player.race, MOCK.player.faction, MOCK.player.level = "SHAMAN", "Orc", "Horde", 20
a = TR:Available()
check(not ready(a.ready, 3599) and ready(a.other, 3599), "Searing Totem 1 is listed as not from the class trainer, not as training")
local lines = table.concat(TR:Lines(10), "\n")
check(string.find(lines, "Not from the class trainer", 1, true) ~= nil, "the list says which spells come from somewhere else")
-- Costs: listed base price when no trainer was seen
ns.db.trainCosts = {}
local c, kind = TR:Cost(entry("SHAMAN", 8044))
check(c and kind == "listed", "a rank never seen at a trainer shows the listed base price (" .. tostring(kind) .. ")")

-- Per-character setting, defer ------------------------------------------------------------------------------------
ns.char.trainerSuggestions = nil
prof.trainerSuggestions = "important"
check(TR:Mode() == "important", "without a character choice the settings profile decides (existing characters keep theirs)")
ns.char.trainerSuggestions = "off"
check(TR:Mode() == "off" and #TR:Available().ready == 0, "the character's choice wins; off lists nothing")
ns.char.trainerSuggestions = "all"
TR.skipCache = nil
check(TR:SkipReason() == nil, "something to train: a train step is not skipped")
TR:Defer()
check(TR:SkipReason() ~= nil and string.find(TR:SkipReason(), "deferred", 1, true), "deferring skips train steps until the next level, without marking anything learned")
check(not known[8044], "deferring never records training")
ns.char.trainerDeferLevel = nil

-- Completionist: optional train step only where your trainer is ----------------------------------------------------
MOCK.player.class, MOCK.player.race, MOCK.player.faction, MOCK.player.level = "WARRIOR", "Orc", "Horde", 10
known = { [772] = true }
local z = TR:TrainerIn(14) -- Durotar
check(z ~= nil, "a Horde warrior trainer is found in Durotar")
local step = TR:TrainStepFor(14)
check(step and step[1] == "train" and step.optional and step.z, "a segment in Durotar gets an optional train step at the trainer")
check(TR:TrainStepFor(12) == nil, "no Horde warrior trainer in Elwynn Forest: no train step, never a detour")
ns.char.trainerSuggestions = "off"
check(TR:TrainStepFor(14) == nil, "suggestions off: no train step")
ns.char.trainerSuggestions = "all"
local ctx = { race = "Orc", class = "WARRIOR", faction = "Horde", level = 10, live = true,
              completed = function() return false end, inLog = function() return false end }
local seg = CM:Plan(ctx, { 14, 50, 50 })
local trains, accepts = 0, 0
for _, s in ipairs(seg.steps) do if s[1] == "train" then trains = trains + 1 end if s[1] == "accept" then accepts = accepts + 1 end end
check(seg.kind == "quests" and seg.zone == 14 and trains == 1 and #seg.accepted == accepts, "a Durotar segment has one train step; training is not a quest")
ctx.live = nil
seg = CM:Plan(ctx, { 14, 50, 50 })
trains = 0
for _, s in ipairs(seg.steps) do if s[1] == "train" then trains = trains + 1 end end
check(trains == 0, "plans for data and tests (not live play) never add training")

-- Automatic training: off by default; "recommended" buys only listed ranks; the old profile switch means "all" ---------
local A = ns.Assist
MOCK.player.class, MOCK.player.race, MOCK.player.faction, MOCK.player.level = "WARRIOR", "Human", "Alliance", 10
known = {}
TR.cache, TR.nameIndex = {}, nil
local services, bought = {}, {}
local realSvc = { GetNumTrainerServices, GetTrainerServiceInfo, GetTrainerServiceCost, BuyTrainerService, IsTradeskillTrainer, GetMoney, GetSpellInfo }
-- The client's own spell names (the mock names every spell "Spell"); services are matched by name and rank.
GetSpellInfo = function(id) if id == 772 or id == 6546 then return "Rend", nil, "icon" end return "Spell " .. tostring(id), nil, "icon" end
GetNumTrainerServices = function() return #services end
GetTrainerServiceInfo = function(i) return services[i].name, services[i].rank, services[i].kind end
GetTrainerServiceCost = function(i) return services[i].cost end
BuyTrainerService = function(i) bought[#bought + 1] = services[i].name .. " " .. (services[i].rank or "") known[services[i].id] = true table.remove(services, i) end
IsTradeskillTrainer = function() return false end
GetMoney = function() return 100000 end
local function trainer()
    services = {
        { name = "Rend", rank = "Rank 1", kind = "available", cost = 100, id = 772 },     -- important for warriors
        { name = "Rend", rank = "Rank 2", kind = "available", cost = 600, id = 6546 },
        { name = "Mystery Skill", rank = "", kind = "available", cost = 50, id = 999002 }, -- not in our data
    }
    bought = {}
end
local function visit() for _ = 1, 10 do if not A:TrainerStep() then break end end end
local keepAuto, keepProfAuto = ns.char.autoTrain, prof.trainerAuto
ns.char.autoTrain, prof.trainerAuto = nil, false
check(TR:AutoTrainMode() == "off", "automatic training is off by default")
trainer() visit()
check(#bought == 0, "off: nothing is bought")
ns.char.autoTrain, ns.char.trainerSuggestions = "recommended", "all"
known = {}
trainer() visit()
local got = table.concat(bought, ",")
check(got:find("Rend Rank 1", 1, true) and got:find("Rend Rank 2", 1, true) and not got:find("Mystery", 1, true),
    "recommended: the listed ranks are learned in order, nothing the suggestions do not list (" .. got .. ")")
check(known[772] and known[6546] and not known[999002], "only what was bought counts as learned")
-- The server confirms a purchase later: the trainer keeps listing the spell and sends several updates meanwhile.
-- It is bought once, and one summary line comes when the trainer closes (the game announces each spell).
known = {}
trainer()
local realBuy = BuyTrainerService
BuyTrainerService = function(i) bought[#bought + 1] = services[i].name .. " " .. (services[i].rank or "") end
A.trainSession, A.trainBuying = nil, nil
local nPrint = #MOCK.printed
for _ = 1, 6 do A:TrainerStep() end
check(#bought == 1 and #MOCK.printed == nPrint, "unconfirmed purchase: bought once, no chat line per update (" .. #bought .. " bought)")
table.remove(services, 1) -- confirmed: the rank leaves the list
A:TrainerStep()
check(#bought == 2 and bought[2] == "Rend Rank 2", "the next rank once the first is confirmed")
table.remove(services, 1)
A:TrainerSummary()
check(#MOCK.printed == nPrint + 1 and string.find(MOCK.printed[#MOCK.printed], "learned 2 spells", 1, true) ~= nil,
    "closing the trainer prints one summary line (" .. tostring(MOCK.printed[#MOCK.printed]) .. ")")
A:TrainerSummary()
check(#MOCK.printed == nPrint + 1, "no second summary")
BuyTrainerService = realBuy
GetMoney = function() return 150 end
known = {}
trainer() visit()
check(#bought == 1 and bought[1] == "Rend Rank 1", "only what you can afford is bought")
GetMoney = function() return 100000 end
IsTradeskillTrainer = function() return true end
known = {}
trainer() visit()
check(#bought == 0, "recommended never buys at a profession trainer")
IsTradeskillTrainer = function() return false end
ns.char.autoTrain, prof.trainerAuto = nil, true
check(TR:AutoTrainMode() == "all", "a character that never chose keeps the old 'Trainer automation' switch (everything)")
ns.char.autoTrain = "off"
check(TR:AutoTrainMode() == "off", "the character's choice wins over the old switch")
GetNumTrainerServices, GetTrainerServiceInfo, GetTrainerServiceCost, BuyTrainerService, IsTradeskillTrainer, GetMoney, GetSpellInfo =
    realSvc[1], realSvc[2], realSvc[3], realSvc[4], realSvc[5], realSvc[6], realSvc[7]
TR.nameIndex = nil
ns.char.autoTrain, prof.trainerAuto = keepAuto, keepProfAuto

-- Setup wizard keeps the choice per character --------------------------------------------------------------------
local S = ns.Setup
local setupKeep, routingKeep = ns.char.setup, ns.char.routing
ns.char.setup = nil
local d = S:Draft(true)
check(d.training == "all", "the wizard starts from the current training choice")
d.training = "important"
check(ns.char.trainerSuggestions == "all", "choosing in the wizard changes nothing before Finish")
check(d.autoTrain == "off", "the wizard proposes no automatic training (opt-in)")
d.autoTrain, d.dungeons = "recommended", "questing"
local fok, fmsg = S:Finish(d)
check(fok, "setup finishes: " .. tostring(fmsg))
check(ns.char.trainerSuggestions == "important", "Finish saves the training choice for the character")
check(ns.char.autoTrain == "recommended" and TR:AutoTrainMode() == "recommended", "Finish saves the automatic-training opt-in for the character")
ns.char.autoTrain = nil
ns.char.setup, ns.char.routing = setupKeep, routingKeep

-- restore
IsSpellKnown = realKnown
MOCK.player.class, MOCK.player.race, MOCK.player.faction, MOCK.player.level = keep.class, keep.race, keep.faction, keep.level
ns.char.trainerSuggestions, ns.char.trainerDeferLevel = keep.char, keep.defer
TR.cache, TR.nameIndex, TR.skipCache = {}, nil, nil
ns.Engine:Load("A_Human_Elwynn", { reset = true })
check(#ns.errors == 0, "no captured errors after What's Training tests: " .. table.concat(ns.errors, " | "))
