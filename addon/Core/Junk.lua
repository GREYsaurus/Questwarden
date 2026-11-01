-- Questwarden - junk: free bag slots, the junk list, deleting and discarding junk
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- This program is free software: you can redistribute it and/or modify it under the terms of the
-- GNU General Public License as published by the Free Software Foundation, version 3.
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
-- even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details. The complete license text is in LICENSE.
--
-- Part of ns.Assist (Core/Assist.lua), kept in its own file so Assist.lua stays readable; every function
-- is still A:<name>, so callers are unchanged. Settings: inventoryManager, discardJunkFull, junkModifierToggle,
-- junkModifier, and the "Delete cheapest junk item" key binding (docs/SETTINGS.md, docs/BAGS.md).

local _, ns = ...

local A = ns.Assist
local C
local function prof() return ns.db.profile end
local function inCombat() return InCombatLockdown and InCombatLockdown() or false end

-- Junk ------------------------------------------------------------------------------------------------

function A:FreeSlots()
    local n = 0
    for bag = 0, C.NUM_BAGS do
        local f = (C_Container and C_Container.GetContainerNumFreeSlots) or GetContainerNumFreeSlots
        n = n + (f and (f(bag)) or 0)
    end
    return n
end

-- Discarding junk -------------------------------------------------------------------------------------
-- The client only lets an add-on destroy an item from inside a click or key press: DeleteCursorItem
-- is restricted on every Classic-engine client (TBC 2.5 included) to a hardware event, one item per
-- event, and is refused when called from an event handler. So:
--   * "Discard junk if bag is full": when the bags are full, the junk item worth least at a vendor is
--     armed, and destroyed on the player's next click on the game world, key press or loot click
--     (hooks in A:HookInput; those are real hardware events, nothing is simulated).
--   * The "Delete cheapest junk item" key does the same on demand.
-- Junk is decided by Vendor:Classify (grey or on the junk list; never quest, quest-starting,
-- guide-needed, protected or item-data-missing items). Every attempt re-reads the slot and re-checks
-- all of that, one item per input. Failures are not retried; success is only reported once the bag
-- update confirms it.

A.discardFailed = {}   -- ["bag:slot:itemID"] = true: failed once this session; not offered again

local function junkKey(e) return e.bag .. ":" .. e.slot .. ":" .. tostring(e.itemID) end

-- Why junk cannot be touched right now, or nil.
function A:JunkBusy()
    if not prof().inventoryManager then return "the inventory manager is off" end
    if inCombat() then return "in combat" end
    local w = ns.AutoEquip and ns.AutoEquip.windows
    if w and next(w) then return "a merchant, trade, bank, mail or auction window is open" end
    if C.CursorHasItem() then return "your cursor is holding an item" end
    if self.discardPending then return "waiting for the last discard to finish" end
    return nil
end

-- The junk stack worth least at a vendor (ties: first bag slot), skipping ones that failed before.
function A:CheapestJunk()
    local list = ns.Vendor:Scan()
    table.sort(list, function(x, y)
        if x.value ~= y.value then return x.value < y.value end
        if x.bag ~= y.bag then return x.bag < y.bag end
        return x.slot < y.slot
    end)
    for _, e in ipairs(list) do
        if not self.discardFailed[junkKey(e)] then return e end
    end
    return nil
end

-- Destroys junk candidate `e`. Call only from a click or key handler (the client needs one).
function A:DiscardJunk(e)
    if not e then return false, "no junk" end
    local busy = self:JunkBusy()
    if busy then return false, busy end
    local cur = C.GetContainerItem(e.bag, e.slot)
    if not cur or cur.itemID ~= e.itemID or (cur.count or 1) ~= (e.count or 1) then return false, "the item moved" end
    if cur.locked then return false, "the item is locked" end
    if ns.Vendor:IsJunkAt(e.bag, e.slot) ~= true then return false, "no longer junk, or its item data is not loaded" end
    local pick = (C_Container and C_Container.PickupContainerItem) or PickupContainerItem
    if not (pick and DeleteCursorItem) then return false, "unsupported" end
    pick(e.bag, e.slot)
    local kind, cid
    if GetCursorInfo then kind, cid = GetCursorInfo() end
    if not C.CursorHasItem() or (GetCursorInfo and (kind ~= "item" or cid ~= e.itemID)) then
        if C.CursorHasItem() then ClearCursor() end -- only ever what this function just picked up
        self.discardFailed[junkKey(e)] = true
        return false, "could not pick up the item"
    end
    DeleteCursorItem()
    if C.CursorHasItem() then
        ClearCursor() -- refused: the item goes back to its slot
        self.discardFailed[junkKey(e)] = true
        return false, "the game refused to destroy it (it only allows this from a click or key press)"
    end
    self.discardPending = { e = e, at = GetTime and GetTime() or 0 }
    C_Timer.After(2, function() A:VerifyDiscard(true) end)
    self.discardTarget = nil
    return true
end

-- Confirms the last discard from the bag contents; reports it only then.
function A:VerifyDiscard(timeout)
    local p = self.discardPending
    if not p then return end
    local cur = C.GetContainerItem(p.e.bag, p.e.slot)
    if cur and cur.itemID == p.e.itemID then
        if not timeout then return end -- the bag update may not have arrived yet
        self.discardFailed[junkKey(p.e)] = true
        self.discardPending = nil
        ns:Print("Could not destroy " .. tostring(p.e.link) .. "; it is still in your bags.")
    else
        self.discardPending = nil
        ns:Print(string.format("Destroyed (not sold): %s x%d.", tostring(p.e.link), p.e.count or 1))
    end
    self:UpdateDiscardTarget()
end

-- Keybind / slash: destroy the cheapest junk item (one per key press).
function A:DeleteCheapestJunk(quiet)
    local busy = self:JunkBusy()
    if busy then
        if not quiet then ns:Print("Junk not destroyed: " .. busy .. ".") end
        return false, busy
    end
    local e = self:CheapestJunk()
    if not e then
        if not quiet then ns:Print("No junk to delete.") end
        return false, "no junk"
    end
    local ok, why = self:DiscardJunk(e)
    if not ok and not quiet then ns:Print("Junk not destroyed: " .. tostring(why) .. ".") end
    return ok, why
end

-- Arms the full-bags discard: the cheapest junk item, or nil when off, bags not full or a discard is
-- still being confirmed.
function A:UpdateDiscardTarget()
    local p = prof()
    local e
    if p.discardJunkFull and p.inventoryManager and not self.discardPending and self:FreeSlots() == 0 then
        e = self:CheapestJunk()
    end
    self.discardTarget = e
    return e
end

-- Called from every hooked click and key press. Cheap when nothing is armed.
function A:OnHardwareInput()
    local e = self.discardTarget
    if not e then return end
    local p = prof()
    if not (p.discardJunkFull and p.inventoryManager) or self:FreeSlots() > 0 then self.discardTarget = nil return end
    if self:JunkBusy() then return end -- stays armed for a later input
    self.discardTarget = nil
    local ok, why = self:DiscardJunk(e)
    if not ok and self.discardFailed[junkKey(e)] then ns:Print("Junk not destroyed: " .. tostring(why) .. ".") end
    return ok
end

-- Hooks the player's own input: clicks on the game world, key presses (passed on to the game
-- untouched) and loot button clicks.
function A:HookInput()
    if self.inputHooked or not CreateFrame then return end
    if inCombat() then self.inputPending = true return end
    self.inputHooked, self.inputPending = true, nil
    local run = function() A:OnHardwareInput() end
    if WorldFrame and WorldFrame.HookScript then
        WorldFrame:HookScript("OnMouseDown", run)
        WorldFrame:HookScript("OnMouseUp", run)
    end
    local f = CreateFrame("Frame", ns.name .. "JunkInput", UIParent)
    if f.SetPropagateKeyboardInput then -- without it, a key script would swallow the player's keys
        f:SetPropagateKeyboardInput(true)
        f:SetScript("OnKeyDown", run)
        f:SetScript("OnKeyUp", run)
    end
    self.inputFrame = f
    for i = 1, 10 do
        local b = _G["LootButton" .. i]
        if b and b.HookScript then b:HookScript("OnClick", run) end
    end
end

function A:OnBagsChanged()
    if self.discardPending then self:VerifyDiscard(false) end
    self:UpdateDiscardTarget()
end

local MODS = {
    CTRL = function() return IsControlKeyDown and IsControlKeyDown() end,
    ALT = function() return IsAltKeyDown and IsAltKeyDown() end,
    SHIFT = function() return IsShiftKeyDown and IsShiftKeyDown() end,
}

-- Marks or unmarks a bag item as junk (sold and deleted like grey items).
function A:ToggleJunk(itemID)
    if not itemID then return end
    local list = ns.db.junkList
    list[itemID] = not list[itemID] or nil
    local info = C.GetItemInfo(itemID)
    ns:Print((info and info.name or ("item " .. itemID)) .. (list[itemID] and " is now on your junk list." or " was removed from your junk list."))
    return list[itemID] == true
end

function A:OnBagItemClick(button, mouse)
    local p = prof()
    if mouse ~= "RightButton" or not (p.inventoryManager and p.junkModifierToggle) then return end
    local held = MODS[p.junkModifier or "CTRL"]
    if not (held and held()) then return end
    local bag, slot = button:GetParent() and button:GetParent():GetID(), button:GetID()
    local item = bag and slot and C.GetContainerItem(bag, slot)
    if item then return self:ToggleJunk(item.itemID) end
end

function A:ResetJunkList()
    wipe(ns.db.junkList)
    ns:Print("Junk list cleared.")
end

A.BINDING = ns.key .. "_DELETEJUNK"
function A:JunkKey() return GetBindingKey and GetBindingKey(self.BINDING) or nil end
function A:SetJunkKey(key)
    if not (SetBinding and SaveBindings) or inCombat() then return false end
    local old = self:JunkKey()
    if old then SetBinding(old) end
    if key then SetBinding(key, self.BINDING) end
    SaveBindings(GetCurrentBindingSet and GetCurrentBindingSet() or 1)
    return true
end

-- Events and input hooks; called from A:Init.
function A:InitJunk()
    C = ns.Compat
    ns:On("BAG_UPDATE_DELAYED", function() ns:Throttle("junk-discard", 0.3, function() A:OnBagsChanged() end) end)
    ns:On("UI_ERROR_MESSAGE", function(_, _, msg)
        if msg and (msg == ERR_INV_FULL or msg == INVENTORY_FULL) then A:UpdateDiscardTarget() end
    end)
    ns:On("PLAYER_REGEN_ENABLED", function() if A.inputPending then A:HookInput() end end)
    if hooksecurefunc and ContainerFrameItemButton_OnModifiedClick then
        hooksecurefunc("ContainerFrameItemButton_OnModifiedClick", function(btn, mouse) A:OnBagItemClick(btn, mouse) end)
    end
    self:HookInput()
end

-- Key binding target (Bindings.xml).
_G[ns.name .. "_DeleteCheapestJunk"] = function() A:DeleteCheapestJunk() end
