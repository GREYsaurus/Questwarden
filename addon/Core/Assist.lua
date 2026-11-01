-- Questwarden - convenience features behind the settings window (UI/Config.lua)
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- This program is free software: you can redistribute it and/or modify it under the terms of the
-- GNU General Public License as published by the Free Software Foundation, version 3.
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
-- even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details. The complete license text is in LICENSE.
--
-- Every feature here is gated by its own profile setting and does nothing when it is off:
--   frames      showAllFrames / hideWindow / autohideRaid gate the guide window and the arrow
--   NPCs        trainerAuto, flightAuto, skipGossip (hold Shift to skip once); bindAuto is Core/Bind.lua
--   targeting   targetMacro (a "Questwarden" macro), targetNotify, maxNameplateDistance (CVar)
--   group chat  announceLevelEmote / Party / Guild on level-up
--   tips        drowning and low-health warnings, rare-mob alerts
--   junk        Core/Junk.lua (same ns.Assist table): junk list, delete cheapest junk, discard when full
--   misc        world map button, Lua error display (CVar), add-on conflict check
-- Nothing here equips items, spends money (except trainerAuto, which is opt-in) or acts in combat
-- where that could matter.

local _, ns = ...

local A = { notified = {}, rareSeen = {}, warned = {} }
ns.Assist = A

local C
local function prof() return ns.db.profile end
local function shiftHeld() return C and C.IsModifierHeld and C.IsModifierHeld() end
local function inCombat() return InCombatLockdown and InCombatLockdown() or false end

-- Frames ---------------------------------------------------------------------------------------------

function A:InRaid() return (IsInRaid and IsInRaid()) or false end
function A:InGroup()
    if IsInGroup then return IsInGroup() and true or false end
    return (GetNumGroupMembers and GetNumGroupMembers() or 0) > 0
end

-- Whether the guide window and the arrow may be shown at all.
function A:FramesAllowed()
    local p = prof()
    if not p.showAllFrames or p.hideWindow then return false end
    if p.autohideRaid and self:InRaid() then return false end
    return true
end

function A:ApplyFrames()
    local mf = ns.MainFrame and ns.MainFrame.frame
    if mf then mf:SetShown(ns.db.frames.main.shown ~= false and self:FramesAllowed()) end
    local nav = ns.Nav
    if nav and nav.arrow then
        ns.Widgets.Rescale(nav.arrow, "arrow", prof().arrowScale or 1)
        nav.arrow:SetShown(prof().showArrow and nav.target ~= nil and self:FramesAllowed())
    end
    if self.mapButton then self.mapButton:SetShown(prof().worldMapButton and true or false) end
end

-- NPC automation -------------------------------------------------------------------------------------

local function currentStep() return ns.Engine and ns.Engine:CurrentStep() end

-- Automatic training (opt-in, per character: Trainer:AutoTrainMode). Learns the first affordable spell the trainer
-- offers that the mode allows; TRAINER_UPDATE brings the next one. "recommended" buys only ranks the training
-- suggestions list for you (matched by name and rank, never at a profession trainer, never pet skills); "all" buys
-- anything affordable. Hold Shift to skip.
-- One purchase at a time: the trainer fires several updates before the server confirms a purchase, and the spell
-- stays listed as available until then, so a spell bought less than BUY_WAIT seconds ago and still listed is
-- waited for, not bought again. The game announces each spell; one summary line follows when you close the
-- trainer (A:TrainerSummary).
local BUY_WAIT = 3
function A:TrainerStep()
    local TR = ns.Trainer
    local mode = TR and TR:AutoTrainMode() or "off"
    if mode == "off" or shiftHeld() then return end
    if not (GetNumTrainerServices and GetTrainerServiceInfo and BuyTrainerService) then return end
    if mode == "recommended" and IsTradeskillTrainer and IsTradeskillTrainer() then return end
    local n = GetNumTrainerServices() or 0
    local fl = self.trainBuying
    if fl then
        local listed = false
        for i = 1, n do
            local name, rankText, kind = GetTrainerServiceInfo(i)
            if kind == "available" and name == fl.name and (rankText or "") == fl.rank then listed = true break end
        end
        if listed and GetTime() - fl.at < BUY_WAIT then return end
        self.trainBuying = nil
    end
    local want = mode == "recommended" and TR:RecommendedSet() or nil
    local money = GetMoney and GetMoney() or 0
    for i = 1, n do
        local name, rankText, kind = GetTrainerServiceInfo(i)
        if kind == "available" then
            local e = want and TR:EntryForService(name, rankText)
            local cost = GetTrainerServiceCost and GetTrainerServiceCost(i) or 0
            if (not want or (e and want[e.id])) and cost <= money then
                BuyTrainerService(i)
                self.trainBuying = { name = name, rank = rankText or "", at = GetTime() }
                local t = self.trainSession or { count = 0, cost = 0 }
                t.count, t.cost = t.count + 1, t.cost + cost
                self.trainSession = t
                -- In case no update follows (a failed purchase), look again once the wait is over.
                C_Timer.After(BUY_WAIT + 0.1, function() A:TrainerStep() end)
                return true
            end
        end
    end
end

-- One chat line for a trainer visit with automatic training: how many spells and what they cost.
function A:TrainerSummary()
    local t = self.trainSession
    self.trainSession, self.trainBuying = nil, nil
    if not (t and t.count > 0) then return end
    ns:Print("Automatic training: learned " .. t.count .. (t.count == 1 and " spell" or " spells") .. " for "
        .. ns.Compat.FormatMoney(t.cost) .. ". Hold Shift when you open the trainer to skip it.")
end

-- Flies to the current fly step's destination when the flight map opens. With a flight graph
-- (Database/Flights.lua) the step's node gives the client's full name ("Auberdine, Darkshore"),
-- which is tried first; otherwise the first reachable node whose name contains the destination.
function A:OnTaxiMap()
    local s = currentStep()
    if not (prof().flightAuto and s and s[1] == "fly" and s.dest) or shiftHeld() then return end
    if not (NumTaxiNodes and TaxiNodeName and TakeTaxiNode) then return end
    local node = s.node and ns.Flights and ns.Flights.nodes[s.node]
    local exact = node and string.lower(node.full)
    local want = string.lower(s.dest)
    local pick
    for i = 1, NumTaxiNodes() or 0 do
        local name = TaxiNodeName(i)
        local kind = TaxiNodeGetType and TaxiNodeGetType(i)
        if type(name) == "string" and (kind == nil or kind == "REACHABLE") then
            local low = string.lower(name)
            if exact and low == exact then pick = i break end
            if not pick and string.find(low, want, 1, true) then pick = i end
        end
    end
    if pick then
        ns:Print("Flying to " .. TaxiNodeName(pick) .. " (flight path automation; hold Shift to choose yourself).")
        TakeTaxiNode(pick)
        return true
    end
end

-- Gossip options as { {name=, type=, id=} } for both the modern and the legacy API.
function A:GossipOptions()
    local out = {}
    local get = C_GossipInfo and C_GossipInfo.GetOptions
    if get then
        for i, o in ipairs(get() or {}) do
            out[#out + 1] = { name = o.name, type = o.type, icon = o.icon, id = o.gossipOptionID or i, modern = true }
        end
        return out
    end
    if GetGossipOptions then
        local raw = { GetGossipOptions() }
        for i = 1, #raw, 2 do out[#out + 1] = { name = raw[i], type = raw[i + 1], id = (i + 1) / 2 } end
    end
    return out
end

local function selectOption(o)
    if o.modern and C_GossipInfo and C_GossipInfo.SelectOption then C_GossipInfo.SelectOption(o.id)
    elseif SelectGossipOption then SelectGossipOption(o.id) end
end
function A:SelectGossipOption(o) selectOption(o) end

local function gossipQuestCount()
    local n = 0
    if C_GossipInfo and C_GossipInfo.GetAvailableQuests then
        n = #(C_GossipInfo.GetAvailableQuests() or {}) + #(C_GossipInfo.GetActiveQuests() or {})
    elseif GetNumGossipAvailableQuests then
        n = (GetNumGossipAvailableQuests() or 0) + (GetNumGossipActiveQuests and GetNumGossipActiveQuests() or 0)
    end
    return n
end

-- Hearthstone binding (Core/Bind.lua) goes first; Skip Gossip never touches a bind option or an NPC
-- with quests, and stays out while a bind is pending.
function A:OnGossip()
    if shiftHeld() then return end
    if ns.Bind:OnGossip() then return "bind" end
    local opts = self:GossipOptions()
    local only = opts[1]
    if prof().skipGossip and #opts == 1 and not ns.Bind.pending and not ns.Bind:IsBinder(only)
        and gossipQuestCount() == 0 then
        selectOption(only)
        return "skip"
    end
end

-- Targeting --------------------------------------------------------------------------------------------

-- NPC ids the current step is about: explicit [mark] NPCs, kill objectives and the mobs that drop quest items
-- (DB.ObjectiveNpcIds), quest giver / finisher. With a kill pack, those of all its open steps (Engine:PackSteps).
function A:StepNpcIds()
    local ids = {}
    local s, E = currentStep(), ns.Engine
    if not s then return ids end
    self:AddStepNpcs(s, ids)
    for k, i in ipairs(E.guide and E:PackSteps() or {}) do
        if k > 1 then self:AddStepNpcs(E.guide.steps[i], ids) end
    end
    return ids
end

function A:AddStepNpcs(s, ids)
    if type(s.mark) == "table" and s.mark.npcs then for _, id in ipairs(s.mark.npcs) do ids[id] = true end end
    local q = s.q and ns.DB.GetQuestByID(s.q)
    if q then
        if s[1] == "complete" then
            -- Without the objectives your log shows done; a quest not in your log yet lists all of them.
            local here = ns.Completionist:Here()
            local open = ns.Tracker:OpenObjectiveNpcIds(s.q, here) or ns.DB.ObjectiveNpcIds(s.q, here)
            for id in pairs(open or {}) do ids[id] = true end
        elseif s[1] == "accept" then
            for _, id in ipairs(q.startNpcs or {}) do ids[id] = true end
            -- An item-started quest: the NPCs that drop the item, while you still need it (Core/ItemStarts.lua).
            for id in pairs(s.starter and ns.ItemStarts:Npcs(s) or {}) do ids[id] = true end
        elseif s[1] == "turnin" then
            for _, id in ipairs(q.endNpcs or {}) do ids[id] = true end
        end
    end
    -- The innkeeper, flight master or vendor a step names (Core/Marker.lua).
    for id in pairs(ns.Marker:NamedNpcs(s) or {}) do ids[id] = true end
    return ids
end

-- The targeting macro, within the 255-character macro limit. Per NPC name of the step: "/cleartarget", "/tar <name>"
-- and, with markWithMacro and an icon for it in the marker rule (Core/Marker.lua), "/tm [harm,nodead]!<icon>".
-- One press so targets and marks the nearest visible mob of each kind: /cleartarget first means a kind not in view
-- marks nothing ([harm] needs a target), and "!" never toggles an icon the mob already has. The current step's
-- own mobs come last, so you end up targeting one of them. Marks set by your key press, not by add-on code.
function A:MacroBody()
    local rule = ns.Marker and ns.Marker.rule
    local mark = prof().markWithMacro and prof().markEnabled and rule
    local names, byName = {}, {}
    local function add(id, primary)
        local n = ns.DB.GetNPCName(id)
        if not n then return end
        local e = byName[n]
        if not e then e = { name = n } byName[n] = e names[#names + 1] = e end
        e.primary = e.primary or primary
        e.icon = e.icon or (mark and rule.types[id]) or nil
    end
    for id in pairs(self:StepNpcIds()) do add(id, true) end
    for id in pairs(mark and rule.types or {}) do add(id, false) end
    -- Others first, then the current step's own; icon order within each, then by name.
    table.sort(names, function(a, b)
        if a.primary ~= b.primary then return not a.primary end
        if (a.icon or 0) ~= (b.icon or 0) then return (a.icon or 0) < (b.icon or 0) end
        return a.name < b.name
    end)
    local body, n = "", 0
    for _, e in ipairs(names) do
        local part = "/cleartarget\n/tar " .. e.name .. (e.icon and ("\n/tm [harm,nodead]!" .. e.icon) or "")
        local nb = body == "" and part or (body .. "\n" .. part)
        if #nb > 255 then break end
        body, n = nb, n + 1
    end
    if body == "" then body = "/cleartarget" end
    return body, n
end

A.MACRO = ns.name

function A:UpdateMacro()
    if not prof().targetMacro or not (GetMacroIndexByName and CreateMacro and EditMacro) then return end
    if inCombat() then self.macroPending = true return end
    self.macroPending = nil
    local body, n = self:MacroBody()
    if body == self.lastBody then return end
    self.lastBody = body
    local idx = GetMacroIndexByName(self.MACRO) or 0
    if idx == 0 then
        local count = GetNumMacros and GetNumMacros() or 0
        if count >= (MAX_ACCOUNT_MACROS or 36) then return end
        CreateMacro(self.MACRO, "INV_MISC_MAP_01", body, nil)
        ns:Print("Created the '" .. ns.name .. "' macro: it targets the current step's NPCs. Drag it from the Macros window (General tab) to an action bar.")
    else
        EditMacro(idx, nil, nil, body)
    end
    if n > 0 and prof().targetNotify then ns:Debug("targeting macro updated (" .. n .. " NPCs)") end
end

-- First sighting of a current-step NPC (nameplate or target): one chat note per NPC id per step.
function A:OnUnitSeen(unit)
    local id, guid = C.UnitNpcId(unit)
    if not id then return end
    local p = prof()
    if p.targetNotify and not self.notified[id] and self:StepNpcIds()[id] then
        self.notified[id] = true
        ns:Print("|cff66ccff" .. tostring(UnitName and UnitName(unit) or id) .. "|r from your current step is nearby.")
    end
    if p.tipsEnabled and p.trackRares and guid and not self.rareSeen[guid] then
        local npc = ns.DB.GetNPCByID(id)
        if npc and (npc.rank == 2 or npc.rank == 4) and ns.DB.HostileToPlayer(npc.friendly)
            and not (p.skipKilledRares and ns.char.killedRares[id]) then
            self.rareSeen[guid] = true
            ns:Print("|cffff7744Rare:|r " .. tostring(npc.name) .. " is nearby.")
            if PlaySound and SOUNDKIT and SOUNDKIT.RAID_WARNING then PlaySound(SOUNDKIT.RAID_WARNING) end
        end
    end
end

function A:OnUnitDied(guid)
    if type(guid) ~= "string" then return end
    local kind, _, _, _, _, id = strsplit("-", guid)
    id = tonumber(id)
    if kind ~= "Creature" or not id then return end
    local npc = ns.DB.GetNPCByID(id)
    if npc and (npc.rank == 2 or npc.rank == 4) and self.rareSeen[guid] then ns.char.killedRares[id] = true end
end

-- Nameplates are visible out to 20 yards by default; 41 is the client maximum in TBC.
function A:ApplyNameplateDistance()
    if not (GetCVar and SetCVar) then return end
    local on = prof().maxNameplateDistance
    local cur = tonumber(GetCVar("nameplateMaxDistance"))
    if on and cur ~= 41 then
        if cur and cur ~= 41 then ns.db.nameplatePrev = cur end
        SetCVar("nameplateMaxDistance", 41)
    elseif not on and cur == 41 and ns.db.nameplatePrev then
        SetCVar("nameplateMaxDistance", ns.db.nameplatePrev)
        ns.db.nameplatePrev = nil
    end
end

function A:LuaErrors(on)
    if on == nil then return GetCVar and GetCVar("scriptErrors") == "1" end
    if SetCVar then SetCVar("scriptErrors", on and "1" or "0") end
end

-- Announcements ---------------------------------------------------------------------------------------

function A:OnLevelUp(level)
    local p = prof()
    if not SendChatMessage then return end
    local msg = "reached level " .. tostring(level) .. "!"
    if p.announceLevelEmote then SendChatMessage(msg, "EMOTE") end
    if p.announceLevelParty and self:InGroup() and not self:InRaid() then SendChatMessage("I " .. msg, "PARTY") end
    if p.announceLevelGuild and IsInGuild and IsInGuild() then SendChatMessage("I " .. msg, "GUILD") end
end

-- Warnings --------------------------------------------------------------------------------------------

local function flash()
    local f = A.flash
    if not f then
        f = CreateFrame("Frame", nil, UIParent)
        f:SetAllPoints(UIParent)
        f:SetFrameStrata("FULLSCREEN_DIALOG")
        local t = f:CreateTexture(nil, "BACKGROUND")
        t:SetAllPoints()
        t:SetTexture("Interface\\FullScreenTextures\\LowHealth")
        t:SetBlendMode("ADD")
        f.tex = t
        f:Hide()
        A.flash = f
    end
    f.left = 1.2
    f:SetAlpha(1)
    f:Show()
    f:SetScript("OnUpdate", function(self, el)
        self.left = self.left - el
        self:SetAlpha(math.max(0, self.left / 1.2))
        if self.left <= 0 then self:Hide() self:SetScript("OnUpdate", nil) end
    end)
end

local function warn(text, sound)
    local frame = RaidWarningFrame or UIErrorsFrame
    if RaidNotice_AddMessage and RaidWarningFrame and ChatTypeInfo then
        RaidNotice_AddMessage(RaidWarningFrame, text, ChatTypeInfo.RAID_WARNING)
    elseif frame and frame.AddMessage then
        frame:AddMessage(text, 1, 0.3, 0.2)
    end
    if sound and PlaySound and SOUNDKIT and SOUNDKIT.RAID_WARNING then PlaySound(SOUNDKIT.RAID_WARNING) end
end

-- Breath: called while a BREATH mirror timer runs. `remaining`/`max` in milliseconds.
function A:CheckBreath(remaining, max)
    local p = prof()
    if not (p.tipsEnabled and p.drownWarn) or not remaining or not max or max <= 0 then return end
    local pct = remaining / max * 100
    if pct <= (p.drownThreshold or 20) then
        if not self.warned.breath then
            self.warned.breath = true
            warn(ns.name .. ": you are running out of breath - surface now!", p.drownSound)
            if p.drownFlash then flash() end
            return true
        end
    else
        self.warned.breath = nil
    end
end

function A:CheckHealth()
    local p = prof()
    if not (p.tipsEnabled and p.lowHealthWarn) or not UnitHealth then return end
    local hp, max = UnitHealth("player"), UnitHealthMax and UnitHealthMax("player") or 0
    if not hp or max <= 0 or (UnitIsDeadOrGhost and UnitIsDeadOrGhost("player")) then return end
    local pct = hp / max * 100
    if pct <= (p.lowHealthThreshold or 20) then
        if not self.warned.health then
            self.warned.health = true
            warn(ns.name .. ": low health - heal, eat, use a potion or get out!", p.lowHealthAnim)
            if p.lowHealthFlash then flash() end
            return true
        end
    elseif pct > (p.lowHealthThreshold or 20) + 10 then
        self.warned.health = nil
    end
end

function A:OnMirrorTimer(timer, value, max)
    if timer ~= "BREATH" then return end
    self.breathMax = max
    if not self.breathTicker then
        local f = CreateFrame("Frame")
        local acc = 0
        f:SetScript("OnUpdate", function(_, el)
            acc = acc + el
            if acc < 0.25 then return end
            acc = 0
            local left = GetMirrorTimerProgress and GetMirrorTimerProgress("BREATH")
            if left then A:CheckBreath(left, A.breathMax) end
        end)
        self.breathTicker = f
    end
    self.breathTicker:Show()
    self:CheckBreath(value, max)
end

function A:OnMirrorStop(timer)
    if timer == "BREATH" then
        self.warned.breath = nil
        if self.breathTicker then self.breathTicker:Hide() end
    end
end

-- World map button --------------------------------------------------------------------------------------

function A:CreateMapButton()
    if self.mapButton or not WorldMapFrame then return end
    local b = CreateFrame("Button", ns.name .. "WorldMapButton", WorldMapFrame)
    b:SetSize(28, 28)
    b:SetPoint("TOPRIGHT", WorldMapFrame, "TOPRIGHT", -60, -28)
    b:SetFrameStrata("HIGH")
    b:SetNormalTexture("Interface\\Icons\\INV_Misc_Map_01")
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
    b:SetScript("OnClick", function() ns.Browser:Toggle() end)
    b:SetScript("OnEnter", function(s)
        GameTooltip:SetOwner(s, "ANCHOR_LEFT")
        GameTooltip:AddLine(ns.name)
        GameTooltip:AddLine("Click to open the guide browser.", 1, 1, 1)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    self.mapButton = b
end

-- Conflicts ----------------------------------------------------------------------------------------------

A.CONFLICTS = { "RXPGuides", "ZygorGuidesViewerClassic", "ZygorGuidesViewerTBC", "TourGuide", "Guidelime", "AzerothAutoPilot" }

function A:Conflicts()
    local loaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
    local out = {}
    if not loaded then return out end
    for _, name in ipairs(self.CONFLICTS) do
        if loaded(name) then out[#out + 1] = name end
    end
    return out
end

function A:CheckConflicts()
    if not prof().checkConflicts then return end
    local list = self:Conflicts()
    if #list > 0 then
        ns:Print("|cffff7744Other leveling guide add-ons are loaded:|r " .. table.concat(list, ", ")
            .. ". They may accept quests, mark targets or move the arrow too. Turn this check off in Advanced Settings.")
    end
end

-- Init ------------------------------------------------------------------------------------------------

function A:Init()
    C = ns.Compat
    ns:On("GROUP_ROSTER_UPDATE", function() A:ApplyFrames() end)
    ns:On("RAID_ROSTER_UPDATE", function() A:ApplyFrames() end)
    ns:On("TRAINER_SHOW", function() A.trainSession, A.trainBuying = nil, nil C_Timer.After(0.2, function() A:TrainerStep() end) end)
    ns:On("TRAINER_UPDATE", function() C_Timer.After(0.2, function() A:TrainerStep() end) end)
    ns:On("TRAINER_CLOSED", function() A:TrainerSummary() end)
    ns:On("TAXIMAP_OPENED", function() A:OnTaxiMap() end)
    ns:On("GOSSIP_SHOW", function() A:OnGossip() end)
    ns:On("NAME_PLATE_UNIT_ADDED", function(_, unit) if unit then A:OnUnitSeen(unit) end end)
    ns:On("PLAYER_TARGET_CHANGED", function() A:OnUnitSeen("target") end)
    ns:On("PLAYER_LEVEL_UP", function(_, level) A:OnLevelUp(level) end)
    ns:On("UNIT_HEALTH", function(_, unit) if unit == "player" then A:CheckHealth() end end)
    ns:On("MIRROR_TIMER_START", function(_, timer, value, max) A:OnMirrorTimer(timer, value, max) end)
    ns:On("MIRROR_TIMER_STOP", function(_, timer) A:OnMirrorStop(timer) end)
    ns:On("PLAYER_REGEN_ENABLED", function() if A.macroPending then A:UpdateMacro() end end)
    ns:On("COMBAT_LOG_EVENT_UNFILTERED", function()
        if not CombatLogGetCurrentEventInfo then return end
        local _, sub, _, _, _, _, _, destGUID = CombatLogGetCurrentEventInfo()
        if sub == "UNIT_DIED" then A:OnUnitDied(destGUID) end
    end)
    ns:Listen("STEP_CHANGED", function() wipe(A.notified) A:UpdateMacro() end)
    ns:Listen("PROFILE_CHANGED", function() A:ApplyFrames() A:ApplyNameplateDistance() end)
    self:InitJunk()
    self:CreateMapButton()
    self:ApplyFrames()
    self:ApplyNameplateDistance()
    self:CheckConflicts()
    ns:Listen("GUIDE_CHANGED", function() A:Preload() end)
    C_Timer.After(5, function() A:Preload() end)
end

-- Pre load all data: ask the client for the item data the current guide's quests use (objective and
-- quest-starting items) and your bag items, a few per frame, so tooltips and scoring never wait.
function A:Preload()
    if not prof().preloadData then return end
    local ids, seen = {}, {}
    local function add(id) if id and not seen[id] then seen[id] = true ids[#ids + 1] = id end end
    local g = ns.Engine and ns.Engine.guide
    for _, s in ipairs(g and g.steps or {}) do
        if s.q then for _, id in ipairs(ns.DB.GetQuestItems(s.q) or {}) do add(id) end end
    end
    for bag = 0, C.NUM_BAGS do
        for slot = 1, C.GetContainerNumSlots(bag) do
            local it = C.GetContainerItem(bag, slot)
            add(it and it.itemID)
        end
    end
    local req = C.Has("C_Item.RequestLoadItemDataByID")
    local info = C.Has("C_Item.GetItemInfo") or C.Has("GetItemInfo")
    local i = 0
    local function batch()
        for _ = 1, 20 do
            i = i + 1
            local id = ids[i]
            if not id then return end
            if req then pcall(req, id) elseif info then info(id) end
        end
        C_Timer.After(0.2, batch)
    end
    batch()
    return #ids
end
