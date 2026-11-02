-- Questwarden - equipping bigger bags automatically (part of automatic upgrades; setting autoEquipBags)
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- This program is free software: you can redistribute it and/or modify it under the terms of the
-- GNU General Public License as published by the Free Software Foundation, version 3.
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
-- even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details. The complete license text is in LICENSE.
--
-- Runs from Gear/AutoEquip.lua's pass when automatic upgrades are on and no gear change is waiting
-- (docs/AUTO_EQUIP.md, "Bags"). Same blocks: combat, cursor, open windows, another change in progress.
--   * Candidates: plain bags (item class Container, subclass Bag) in your bags that are not unbound
--     Bind-on-Equip; the binding is read as for gear (Upgrade:BindState), unknown means skipped. Profession
--     and soul bags, quivers and ammo pouches are never moved.
--   * An empty bag slot (1-4) gets the biggest candidate.
--   * All four slots full: the smallest plain bag equipped is replaced by a bigger candidate. The game only
--     swaps empty bags, so its items are first moved, one per pass, to free slots of the other plain bags;
--     without room for all of them nothing is done. The old bag lands where the new one was.
-- One action per pass, confirmed from the bag API before the next. A failed bag is not tried again this
-- session.

local _, ns = ...

local AB = { failed = {} }
ns.AutoBag = AB

local function C() return ns.Compat end
local function prof() return ns.db.profile end
local CONTAINER, PLAIN_BAG = 1, 0 -- GetItemInfo classID / subclassID
AB.CONFIRM_TIMEOUT = 2.0

local function now() return GetTime and GetTime() or 0 end
local function dbg(msg) ns:Debug("bags: " .. msg) end
local function pickup(bag, slot)
    local f = C().Has("C_Container.PickupContainerItem") or C().Has("PickupContainerItem")
    if f then f(bag, slot) return true end
end
-- Free slots and family of a bag (family 0: holds anything).
local function free(bag)
    local f = C().Has("C_Container.GetContainerNumFreeSlots") or C().Has("GetContainerNumFreeSlots")
    if not f then return 0, nil end
    local n, family = f(bag)
    return n or 0, family
end
local function invSlot(bag)
    local f = C().Has("C_Container.ContainerIDToInventoryID") or C().Has("ContainerIDToInventoryID")
    return f and f(bag)
end

-- "%d Slot %s" (CONTAINER_SLOTS) as a pattern capturing the number.
local function slotsPattern()
    local s = type(CONTAINER_SLOTS) == "string" and CONTAINER_SLOTS or "%d Slot %s"
    s = string.gsub(s, "%%%d%$", "%%")                     -- "%1$d" -> "%d"
    s = string.gsub(s, "([%(%)%.%+%-%*%?%[%]%^%$])", "%%%1") -- escape magic characters
    s = string.gsub(s, "%%d", "(%%d+)")
    s = string.gsub(s, "%%s", ".+")
    return "^" .. s
end

-- Slots of the bag in bags slot (bag, slot), from its tooltip; nil when not shown.
function AB.TooltipSlots(bag, slot)
    local pat = slotsPattern()
    for _, l in ipairs(ns.Upgrade.ScanLines("bag", bag, slot) or {}) do
        local n = tonumber(string.match(l[1] or "", pat))
        if n then return n end
    end
end

-- Plain, non-BoE bags in the backpack and bags 1-4: { bag, slot, id, size, link }.
function AB:Candidates()
    local out = {}
    for bag = 0, C().NUM_BAGS do
        for slot = 1, C().GetContainerNumSlots(bag) do
            local c = C().GetContainerItem(bag, slot)
            local info = c and c.itemID and not c.locked and not self.failed[c.itemID] and C().GetItemInfo(c.link or c.itemID)
            if info and info.classID == CONTAINER and info.subclassID == PLAIN_BAG then
                local lines = ns.Upgrade.ScanLines("bag", bag, slot)
                local d = { boundFlag = c.bound, bindType = info.bindType, tip = ns.TooltipText.Classify(lines) }
                local bind = ns.Upgrade:BindState(d)
                local size = self.TooltipSlots(bag, slot)
                if bind and bind ~= "boe" and size and size > 0 then
                    out[#out + 1] = { bag = bag, slot = slot, id = c.itemID, size = size, link = c.link }
                end
            end
        end
    end
    table.sort(out, function(a, b) if a.size ~= b.size then return a.size > b.size end return a.bag * 100 + a.slot < b.bag * 100 + b.slot end)
    return out
end

-- The next action, or nil: { kind = "equip" | "move", ... }. No side effects.
function AB:Plan()
    local cands = self:Candidates()
    if #cands == 0 then return nil end
    local best = cands[1]
    local smallest
    for bag = 1, C().NUM_BAGS do
        local size = C().GetContainerNumSlots(bag)
        if size == 0 then
            return { kind = "equip", from = best, bag = bag }
        end
        local _, family = free(bag)
        if family == 0 and (not smallest or size < smallest.size) then smallest = { bag = bag, size = size } end
    end
    if not smallest then return nil end
    local new
    for _, c in ipairs(cands) do
        if c.size > smallest.size and c.bag ~= smallest.bag then new = c break end
    end
    -- A bigger bag inside the bag it would replace moves out with the rest of that bag's items.
    if not new then
        for _, c in ipairs(cands) do if c.size > smallest.size then new = c break end end
    end
    if not new then return nil end
    -- Items still in the old bag, and room for them in the other plain bags.
    local items, room = {}, {}
    for slot = 1, smallest.size do
        local c = C().GetContainerItem(smallest.bag, slot)
        if c then items[#items + 1] = { slot = slot, locked = c.locked } end
    end
    if #items == 0 then return { kind = "equip", from = new, bag = smallest.bag, swap = true } end
    for bag = 0, C().NUM_BAGS do
        local _, family = free(bag)
        if bag ~= smallest.bag and (bag == 0 or family == 0) then
            for slot = 1, C().GetContainerNumSlots(bag) do
                if not C().GetContainerItem(bag, slot) then room[#room + 1] = { bag = bag, slot = slot } end
            end
        end
    end
    if #room < #items then return nil, "no room to empty bag " .. smallest.bag end
    local it = items[1]
    if it.locked then return nil, "an item in bag " .. smallest.bag .. " is locked" end
    return { kind = "move", bag = smallest.bag, slot = it.slot, to = room[1], new = new }
end

-- One pass: called by AutoEquip:Run when nothing blocks and no gear change is waiting. True when it acted.
function AB:Run()
    if self.busy or not prof().autoEquipBags then return false end
    local p, why = self:Plan()
    if not p then
        if why then dbg(why) end
        return false
    end
    if p.kind == "move" then return self:Move(p) end
    return self:Equip(p)
end

-- Moves one item out of the bag that is about to be replaced.
function AB:Move(p)
    local before = C().GetContainerItem(p.bag, p.slot)
    if not before or not pickup(p.bag, p.slot) or not C().CursorHasItem() then return false end
    pickup(p.to.bag, p.to.slot)
    if C().CursorHasItem() then
        pickup(p.bag, p.slot)
        if C().CursorHasItem() and ClearCursor then ClearCursor() end
        self.failed[p.new.id] = true
        return false
    end
    self.busy = { kind = "move", id = before.itemID, to = p.to, newId = p.new.id, deadline = now() + self.CONFIRM_TIMEOUT }
    self:WaitConfirm()
    return true
end

-- Puts candidate p.from into bag slot p.bag (empty, or holding an empty bag to swap).
function AB:Equip(p)
    local inv = invSlot(p.bag)
    local put = C().Has("PutItemInBag")
    local c = C().GetContainerItem(p.from.bag, p.from.slot)
    if not inv or not put or not c or c.itemID ~= p.from.id then return false end
    if not pickup(p.from.bag, p.from.slot) or not C().CursorHasItem() then self.failed[p.from.id] = true return false end
    put(inv)
    -- A swapped-out bag comes back on the cursor: it goes where the new one was.
    if C().CursorHasItem() then pickup(p.from.bag, p.from.slot) end
    if C().CursorHasItem() then
        if ClearCursor then ClearCursor() end
        self.failed[p.from.id] = true
        dbg("the client did not take " .. tostring(p.from.link))
        return false
    end
    self.busy = { kind = "equip", id = p.from.id, bag = p.bag, size = p.from.size, link = p.from.link,
                  deadline = now() + self.CONFIRM_TIMEOUT }
    self:WaitConfirm()
    return true
end

function AB:WaitConfirm()
    C_Timer.After(0.3, function() AB:Verify() end)
    C_Timer.After(self.CONFIRM_TIMEOUT + 0.1, function() AB:Verify(true) end)
end

-- Done when the bag API shows the change; otherwise give up after the timeout.
function AB:Verify(final)
    local b = self.busy
    if not b then return end
    local done
    if b.kind == "equip" then
        done = C().GetContainerNumSlots(b.bag) == b.size
    else
        local c = C().GetContainerItem(b.to.bag, b.to.slot)
        done = c and c.itemID == b.id
    end
    if done then
        self.busy = nil
        if b.kind == "equip" then
            self.failed[b.id] = true -- the bag is in place; never move it again this session
            if prof().equipChat then ns:Print("Equipped bag: " .. tostring(b.link) .. " (" .. b.size .. " slots).") end
        end
        ns.AutoEquip:Schedule(0.5)
    elseif final or now() >= b.deadline then
        self.busy = nil
        if b.kind == "equip" then self.failed[b.id] = true else self.failed[b.newId] = true end
        dbg("not confirmed by the server")
        ns.AutoEquip:Schedule(1)
    end
end
