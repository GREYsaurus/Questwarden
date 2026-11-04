-- Questwarden - in-game diagnostics (/cg debug ...)
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- This program is free software: you can redistribute it and/or modify it under the terms of the
-- GNU General Public License as published by the Free Software Foundation, version 3.
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
-- even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details. The complete license text is in LICENSE.
--
-- These checks exist because the add-on could not be run in the real client during development.
-- They let a tester confirm API availability, talent data vs. client, and quest data quickly.

local _, ns = ...

local D = {}
ns.Diagnostics = D

local function line(msg) DEFAULT_CHAT_FRAME:AddMessage("  " .. msg) end

function D:Summary()
    local iface, build, version = ns.Compat.GetInterface()
    ns:Print(string.format("version %s - client %s build %s (interface %d), built for %s (interface %d)",
        tostring(ns.version), tostring(version), tostring(build), iface, ns.Target.name, ns.Target.interface))
    local msg = ns.TargetCheck:Message()
    if msg then line(msg) end
    if ns.Guides.refused > 0 then line(ns.Guides.refused .. " guides not loaded (wrong client or unverified target)") end
    local nq, nn = 0, 0
    for _ in pairs(ns.QDB.quests) do nq = nq + 1 end
    for _ in pairs(ns.QDB.npcs) do nn = nn + 1 end
    line(string.format("quest db: %d quests, %d npcs", nq, nn))
    line(string.format("guides: %d loaded, %d rejected", #ns.Guides.list, #ns.Guides.rejected))
    line(string.format("talent builds: %d", #ns.Talents.buildList))
    line(string.format("quest log entries tracked: %d", ns.Tracker:Count()))
    line(string.format("errors captured: %d (/" .. ns.slash .. " debug errors)", #ns.errors))
end

D.APIS = {
        "C_QuestLog.IsQuestFlaggedCompleted", "IsQuestFlaggedCompleted", "GetQuestsCompleted",
        "GetQuestLogTitle", "GetNumQuestLeaderBoards", "GetQuestLogLeaderBoard",
        "C_Map.GetBestMapForUnit", "C_Map.GetPlayerMapPosition", "C_Map.GetWorldPosFromMapPos", "C_Map.GetMapInfo",
        "GetPlayerFacing", "GetBindLocation", "GetTalentInfo", "GetTalentTabInfo", "UnitCharacterPoints",
        "C_AddOns.GetAddOnMetadata", "GetAddOnMetadata", "Settings.RegisterCanvasLayoutCategory",
        "InterfaceOptions_AddCategory", "BackdropTemplateMixin", "C_Timer.After",
        -- automation
        "C_Container.GetContainerItemInfo", "GetContainerItemInfo", "C_Container.UseContainerItem", "UseContainerItem",
        "C_Container.GetContainerItemQuestInfo", "GetContainerItemQuestInfo", "GetItemInfo", "GetMoney",
        "GetItemStats", "GetInventoryItemLink", "GetCombatRating", "GetQuestItemLink",
        "C_GossipInfo.GetAvailableQuests", "C_GossipInfo.SelectAvailableQuest", "C_GossipInfo.GetActiveQuests",
        "C_GossipInfo.SelectActiveQuest", "GetGossipAvailableQuests", "GetAvailableQuestInfo", "GetActiveQuestID",
        "GetQuestID", "AcceptQuest", "CompleteQuest", "IsQuestCompletable", "GetNumQuestChoices", "GetQuestReward",
        "GetQuestMoneyToGet", "C_QuestLog.GetMaxNumQuestsCanAccept", "Settings.RegisterCanvasLayoutSubcategory",
        -- hearthstone binding (Core/Bind.lua)
        "C_GossipInfo.GetOptions", "C_GossipInfo.SelectOption", "C_Map.GetAreaInfo",
        "C_PlayerInteractionManager.ConfirmationInteraction", "ConfirmBinder",
        -- corpse waypoint (Core/Corpse.lua)
        "C_DeathInfo.GetCorpseMapPosition", "UnitIsGhost",
        -- raid markers
        "SetRaidTarget", "GetRaidTargetIndex", "UnitGUID", "IsInRaid", "UnitIsGroupLeader", "UnitIsGroupAssistant",
        "InCombatLockdown", "C_Container.PickupContainerItem", "PickupContainerItem", "EquipCursorItem",
        "GetInventoryItemID", "IsEquippableItem", "C_Container.GetContainerNumFreeSlots", "GetContainerNumFreeSlots",
        "CursorHasItem", "ClearCursor", "hooksecurefunc", "ContainerFrame_Update",
        -- auction house (UI/Auctioneer.lua)
        "QueryAuctionItems", "CanSendAuctionQuery", "GetNumAuctionItems", "GetAuctionItemInfo", "GetAuctionItemLink",
        "AuctionFrameTab_OnClick", "PanelTemplates_SetNumTabs", "AuctionFrameBrowse_Search",
        -- not found in Forever's UI source (docs/generated/Forever/api-audit.md): checked by the launch check
        "WorldMapFrame.OnMapChanged", "InterfaceOptions_AddCategory", "InterfaceOptionsFrame_OpenToCategory",
        "GetNumTalentTabs", "UnitCharacterPoints", "SelectGossipAvailableQuest", "SelectGossipActiveQuest",
        "GetQuestTimers", "AbandonQuest", "GetNumRaidMembers", "IsRaidLeader", "IsRaidOfficer", "InterfaceOptionsFrame",
        "GetGossipOptions", "GetNumGossipAvailableQuests", "GetNumGossipActiveQuests", "GetQuestGreenRange",
        "GetMacroIndexByName", "ContainerFrameItemButton_OnModifiedClick", "IsAddOnLoaded", "RegisterAddonMessagePrefix",
        "CharacterFrame.HookScript", "BrowseName", "GetCoinTextureString", "GetSpellName", "GetPetTrainingPoints",
        "GetNumCrafts", "GetCraftInfo", "IsQuestFlaggedCompleted", "UseContainerItem", "GetItemCooldown", "GetItemSpell",
        -- newer APIs Forever might have instead (only looked up by name here, never called)
        "C_ClassTalents.GetActiveConfigID", "C_Traits.GetConfigInfo", "C_SpecializationInfo.GetTalentInfo",
        "C_CreatureInfo.GetRaceInfo", "C_GameRules.IsHardcoreActive",
}

function D:Api()
    local apis = D.APIS
    ns:Print("API availability:")
    for _, a in ipairs(apis) do
        line((ns.Compat.Has(a) and "|cff55ff55yes|r " or "|cffff5555no|r  ") .. a)
    end
    local m = {}
    for k in pairs(ns.Compat.missing) do m[#m + 1] = k end
    if #m > 0 then line("fallbacks used: " .. table.concat(m, ", ")) end
end

function D:TalentCheck()
    local live, mismatches = ns.Talents:ReadLive()
    local n = 0
    for _ in pairs(live) do n = n + 1 end
    ns:Print(string.format("talents: %d talents with points; %d data mismatches", n, #mismatches))
    for i = 1, math.min(#mismatches, 15) do line(mismatches[i]) end
    local b = ns.Talents:ActiveBuild()
    if b then
        local _, errs = ns.Talents:Expand(b)
        line("active build: " .. b.name .. (#errs > 0 and (" |cffff5555(" .. #errs .. " errors)|r") or " (valid)"))
    end
end

function D:Quest(id)
    id = tonumber(id)
    if not id then return ns:Print("usage: /" .. ns.slash .. " debug quest <questId>") end
    local q = ns.DB.GetQuestByID(id)
    if not q then return ns:Print("quest " .. id .. " not in database") end
    ns:Print(string.format("%d: %s (level %d, requires %d)", id, q.name, q.level, q.requiredLevel))
    local f = ns.DB.GetQuestFactionRestrictions(id)
    line("faction: " .. tostring(f) .. ", zone: " .. tostring(ns.DB.ZoneName(ns.DB.GetQuestZone(id))))
    line("completed: " .. tostring(ns.Tracker:IsTurnedIn(id)) .. ", in log: " .. tostring(ns.Tracker:InLog(id)))
    local ok, why, extra = ns.DB.IsQuestAvailable(id, ns.Tracker:Context())
    line("available: " .. tostring(ok) .. (why and (" (" .. why .. (extra and (" " .. extra) or "") .. ")") or ""))
    local s = q.startNpcs[1]
    if s then
        local z, x, y = ns.DB.GetNPCPosition(s)
        line(string.format("start: %s %s", tostring(ns.DB.GetNPCName(s)), z and string.format("%.1f,%.1f %s", x, y, tostring(ns.DB.ZoneName(z))) or ""))
    end
end

-- Launch check for a new client (World of Warcraft: Forever, docs/FOREVER_PLAN.md step 7): what this client is and
-- which APIs it has, saved in QuestwardenDB.launchCheck (written to WTF\Account\<account>\SavedVariables when you
-- log out or /reload) so the maintainer can read it. Reads only; changes nothing in the game.
function D:Launch()
    local function call(f, ...) if type(f) == "function" then local ok, a, b, c, d = pcall(f, ...) if ok then return a, b, c, d end end end
    local r = { version = ns.version, target = ns.Target.id, time = time and time() }
    local version, build, _, iface = call(GetBuildInfo)
    r.client = { version = version, build = build, interface = iface }
    r.project = { id = WOW_PROJECT_ID, camelot = WOW_PROJECT_CAMELOT }
    local meta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    r.tocFile = call(meta, ns.name, "X-TocFile")
    r.questLog = { max = C_QuestLog and call(C_QuestLog.GetMaxNumQuestsCanAccept), constant = MAX_QUESTLOG_QUESTS }
    local _, raceFile, raceId = call(UnitRace, "player")
    local _, classFile, classId = call(UnitClass, "player")
    r.player = { race = raceFile, raceId = raceId, class = classFile, classId = classId, level = call(UnitLevel, "player"),
        faction = call(UnitFactionGroup, "player"), hardcore = C_GameRules and call(C_GameRules.IsHardcoreActive) }
    r.talents = { tabs = call(GetNumTalentTabs), unspent = call(UnitCharacterPoints, "player"), names = {} }
    for t = 1, r.talents.tabs or 0 do
        local name = call(GetTalentTabInfo, t)
        r.talents.names[t] = { name = name, talents = call(GetNumTalents, t) }
    end
    local map = C_Map and call(C_Map.GetBestMapForUnit, "player")
    r.place = { map = map, zone = GetZoneText and GetZoneText(), sub = GetSubZoneText and GetSubZoneText() }
    r.apis = {}
    local missing = {}
    for _, a in ipairs(D.APIS) do
        r.apis[a] = ns.Compat.Has(a) and true or false
        if not r.apis[a] then missing[#missing + 1] = a end
    end
    ns.db.launchCheck = r
    ns:Print(string.format("launch check: client %s build %s (interface %s), project %s (Forever %s), TOC file %s",
        tostring(version), tostring(build), tostring(iface), tostring(WOW_PROJECT_ID), tostring(WOW_PROJECT_CAMELOT), tostring(r.tocFile)))
    line(string.format("quest log max %s, talent tabs %s, %s %s: %d of %d APIs missing",
        tostring(r.questLog.max or r.questLog.constant), tostring(r.talents.tabs), tostring(raceFile), tostring(classFile), #missing, #D.APIS))
    line("Saved. Type /reload (or log out) so it is written to SavedVariables\\" .. ns.name .. ".lua.")
end

function D:Run(arg)
    local cmd, rest = string.match(arg or "", "^(%S*)%s*(.-)$")
    if cmd == "launch" then return self:Launch() end
    if cmd == "api" then return self:Api() end
    if cmd == "talents" then return self:TalentCheck() end
    if cmd == "quest" then return self:Quest(rest) end
    if cmd == "nav" then
        ns:Print("navigation:")
        for _, l in ipairs(ns.Nav:DebugLines()) do line(l) end
        return
    end
    if cmd == "marks" then
        local M = ns.Marker
        local r = M.rule
        local p = ns.db.profile
        ns:Print("raid markers: " .. (r and "rule active" or ("no rule: " .. tostring(M.noRuleWhy)))
            .. (M.blocked and ", BLOCKED by the client" or "") .. (M.stopped and ", paused for this step" or ""))
        line(string.format("settings: markEnabled=%s autoMark=%s autoMarkObjectives=%s markReplace=%s",
            tostring(p.markEnabled), tostring(p.autoMark), tostring(p.autoMarkObjectives), tostring(p.markReplace)))
        local ok, why = ns.Compat.CanMark()
        line("can mark now: " .. tostring(ok) .. (why and (" (" .. why .. ")") or "")
            .. (SetRaidTarget and "" or "; SetRaidTarget is MISSING in this client"))
        if r then
            local byIcon = {}
            for id, icon in pairs(r.types) do
                byIcon[icon] = byIcon[icon] or {}
                table.insert(byIcon[icon], id .. " " .. tostring(ns.DB.GetNPCName(id)))
            end
            for icon, ids in pairs(byIcon) do
                table.sort(ids)
                line(M.Label(icon) .. (M.holder[icon] and " (on a mob now)" or "") .. ": " .. table.concat(ids, ", "))
            end
        end
        local last = M.last
        if last then
            line(string.format("last decision: %s%s, %ds ago", last.reason, last.name and (" - " .. tostring(last.name)) or "",
                math.floor((GetTime() - (last.at or 0)) + 0.5)))
        end
        return
    end
    if cmd == "escort" then
        local id = tonumber(rest)
        if not id then return ns:Print("usage: /" .. ns.slash .. " debug escort <questId>") end
        local manual, why = ns.DB.GetEscortStatus(id)
        return ns:Print(string.format("%d %s: %s", id, tostring(ns.DB.GetQuestName(id)),
            manual and ("manual only (" .. why .. ")") or "may be auto-accepted when it is in the active guide"))
    end
    if cmd == "errors" then
        ns:Print(#ns.errors .. " captured errors:")
        for i = 1, #ns.errors do line(ns.errors[i]) end
        return
    end
    if cmd == "on" or cmd == "off" then
        ns.db.profile.debug = (cmd == "on")
        return ns:Print("debug " .. cmd)
    end
    self:Summary()
end
