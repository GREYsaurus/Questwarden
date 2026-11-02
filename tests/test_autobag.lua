-- Questwarden - headless tests: equipping bigger bags automatically (Gear/AutoBag.lua)
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- SPDX-License-Identifier: GPL-3.0-only
-- Loaded by tests/run_tests.lua after tests/test_autoequip.lua; uses TEST.check and TEST.ns.

local check, ns = TEST.check, TEST.ns
local AE, AB = ns.AutoEquip, ns.AutoBag
local function prof() return ns.db.profile end
local I = MOCK.items

-- Tooltip lines come from MOCK.items[id].tip, as in tests/test_autoequip.lua.
local realScan = ns.Upgrade.ScanLines
ns.Upgrade.ScanLines = function(kind, a, b)
    local x = kind == "bag" and MOCK.bags[a] and MOCK.bags[a][b]
    return x and I[x.itemID] and I[x.itemID].tip or {}
end

local function bagItem(id, name, size, t)
    t = t or {}
    t.name, t.classID, t.subclassID, t.bagSize = name, 1, t.subclassID or 0, size
    t.bindType = t.bindType or 0
    t.tip = { { name }, { size .. " Slot Bag" } }
    I[id] = t
end
bagItem(96001, "Small Pouch", 6)
bagItem(96002, "Big Bag", 14)
bagItem(96003, "Fancy BoE Bag", 16, { bindType = 2 })
bagItem(96004, "Soul Pouch", 20, { subclassID = 1 })
bagItem(96005, "Huge Bag", 16, { bindType = 1 })
I[96010] = { name = "Linen Cloth", classID = 7 }
I[96011] = { name = "Copper Ore", classID = 7 }

local function reset(bags, sizes, equippedBags)
    MOCK.bags, MOCK.bagSizes, MOCK.bagFamily, MOCK.equippedBags = bags, sizes or {}, {}, equippedBags or {}
    MOCK.putCalls, MOCK.equipCalls, MOCK.equipped = {}, {}, {}
    MOCK.combat, MOCK.cursor, MOCK.cursorItem, MOCK.freeOverride, MOCK.putFails = false, false, nil, nil, false
    AE.windows, AE.busy, AE.failed, AB.busy, AB.failed = {}, nil, {}, nil, {}
end
local function run() AE:Schedule(0) MOCK.tick(30) end
local function where(id)
    for b, t in pairs(MOCK.bags) do for s, x in pairs(t) do if x.itemID == id then return b, s end end end
end

prof().autoEquip, prof().gearEnabled, prof().autoEquipBags = true, true, true

-- Empty bag slots: biggest non-BoE bag first; BoE and profession bags stay -------------------------------------
reset({ [0] = { [1] = { itemID = 96001 }, [2] = { itemID = 96002 }, [3] = { itemID = 96003, bound = false },
                [4] = { itemID = 96004 } } })
run()
check(MOCK.equippedBags[1] == 96002 and MOCK.bagSizes[1] == 14, "the biggest bag goes into the first empty bag slot")
check(MOCK.equippedBags[2] == 96001, "the next bag goes into the next empty slot")
check(where(96003) == 0, "an unbound Bind-on-Equip bag is never equipped")
check(where(96004) == 0, "a profession or soul bag is never equipped")
check(MOCK.equippedBags[3] == nil and MOCK.equippedBags[4] == nil, "nothing else is put in a bag slot")

-- Setting off, or automatic upgrades off: nothing ----------------------------------------------------------------
reset({ [0] = { [1] = { itemID = 96002 } } })
prof().autoEquipBags = false
run()
check(#MOCK.putCalls == 0, "Equip bigger bags off: no bag is equipped")
prof().autoEquipBags, prof().autoEquip = true, false
run()
check(#MOCK.putCalls == 0, "automatic upgrades off: no bag is equipped")
prof().autoEquip = true

-- In combat: waits ------------------------------------------------------------------------------------------------
MOCK.combat = true
run()
check(#MOCK.putCalls == 0, "no bag is equipped in combat")
MOCK.combat = false
MOCK.fire("PLAYER_REGEN_ENABLED")
MOCK.tick(30)
check(MOCK.equippedBags[1] == 96002, "the bag is equipped once combat ends")

-- All slots full: the smallest bag is emptied into the others, then swapped ----------------------------------------
reset({ [0] = { [1] = { itemID = 96005, bound = true } },
        [1] = { [1] = { itemID = 96010 }, [3] = { itemID = 96011 } }, [2] = {}, [3] = {}, [4] = {} },
      { [1] = 6, [2] = 10, [3] = 10, [4] = 12 }, { [1] = 96001, [2] = 96002, [3] = 96002, [4] = 96002 })
run()
check(MOCK.equippedBags[1] == 96005 and MOCK.bagSizes[1] == 16, "a bigger bag replaces the smallest one")
check(where(96001) == 0, "the old bag lands where the new one was")
local b1, b2 = where(96010), where(96011)
check(b1 and b1 ~= 1 and b2 and b2 ~= 1, "the old bag's items were moved to the other bags first")
check(next(MOCK.bags[1]) == nil, "the new bag starts empty")

-- No bigger bag: nothing changes -----------------------------------------------------------------------------------
reset({ [0] = { [1] = { itemID = 96001 } }, [1] = {}, [2] = {}, [3] = {}, [4] = {} },
      { [1] = 10, [2] = 10, [3] = 10, [4] = 10 }, { [1] = 96002, [2] = 96002, [3] = 96002, [4] = 96002 })
run()
check(#MOCK.putCalls == 0, "a smaller bag never replaces an equipped one")

-- No room for the old bag's items: nothing changes --------------------------------------------------------------------
local full = function(n) local t = {} for s = 1, n do t[s] = { itemID = 96010 } end return t end
local back = full(16)
back[16] = { itemID = 96005, bound = true }
reset({ [0] = back, [1] = full(6), [2] = full(10), [3] = full(10), [4] = full(10) },
      { [1] = 6, [2] = 10, [3] = 10, [4] = 10 }, { [1] = 96001, [2] = 96002, [3] = 96002, [4] = 96002 })
run()
check(#MOCK.putCalls == 0 and MOCK.equippedBags[1] == 96001, "without room for the old bag's items, nothing is swapped")
check(#MOCK.bags[1] == 6, "and its items stay where they were")

-- A profession bag in a slot is never replaced ---------------------------------------------------------------------------
reset({ [0] = { [1] = { itemID = 96005, bound = true } }, [1] = {}, [2] = {}, [3] = {}, [4] = {} },
      { [1] = 6, [2] = 16, [3] = 16, [4] = 16 }, { [1] = 96004, [2] = 96005, [3] = 96005, [4] = 96005 })
MOCK.bagFamily[1] = 256
run()
check(#MOCK.putCalls == 0, "a soul or profession bag in a bag slot is never swapped out")

-- The client refuses: not tried again -------------------------------------------------------------------------------------
reset({ [0] = { [1] = { itemID = 96002 } } })
MOCK.putFails = true
run()
check(#MOCK.putCalls == 1 and MOCK.cursorItem == nil and where(96002) == 0, "a refused bag goes back and is not retried")

-- Tooltip size pattern follows the client's string -------------------------------------------------------------------------
CONTAINER_SLOTS = "%d Slot %s"
check(AB.TooltipSlots(0, 1) == 14, "the bag size is read from the tooltip")

reset({ [0] = {} })
MOCK.bagSizes, MOCK.equippedBags = {}, {}
prof().autoEquip = false
ns.Upgrade.ScanLines = realScan
