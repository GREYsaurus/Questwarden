-- Questwarden - is this the game client this build was made for? (docs/COMPATIBILITY.md)
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- This program is free software: you can redistribute it and/or modify it under the terms of the
-- GNU General Public License as published by the Free Software Foundation, version 3.
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
-- even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details. The complete license text is in LICENSE.
--
-- Each build carries one target's data (Config/Target.lua). Quest ids, NPC positions and talents
-- differ between Classic Era, Forever and TBC, so guides built for one are WRONG on another. The
-- check runs while the add-on loads, before the compiled guides register: on a different client, or
-- for a target whose data is not verified yet, Guides:Register refuses every guide and the player
-- gets one clear message at login. Everything else (talent calculator, settings) still loads.
--
-- Signals: GetBuildInfo's interface number and version string, compared with the target's
-- minInterface/maxInterface and versionPrefix. A client that reports no interface (0) only gets a
-- warning. WOW_PROJECT_ID tells Forever apart: WOW_PROJECT_CAMELOT exists only on the Forever client, so a
-- Forever client running a Classic Era or TBC build (or the reverse) is refused even if interface numbers
-- overlap.

local _, ns = ...

local TC = { ok = true }
ns.TargetCheck = TC

function TC:Evaluate()
    local T = ns.Target
    local iface, build, version = ns.Compat.GetInterface()
    self.interface, self.build, self.version = iface, build, version
    self.ok, self.reason, self.warning = true, nil, nil
    if iface == 0 then
        self.warning = "this client did not report its interface number; " .. ns.name .. " assumes it is " .. T.name .. "."
    elseif iface < T.minInterface or iface > T.maxInterface
        or (type(version) == "string" and T.versionPrefix and string.sub(version, 1, #T.versionPrefix) ~= T.versionPrefix) then
        self.ok = false
        self.reason = string.format("this %s build is for %s (interface %d), but this client is version %s (interface %d). "
            .. "No guides were loaded, because their quests and coordinates would be wrong here. Install the %s build for this game.",
            ns.name, T.name, T.interface, tostring(version), iface, ns.name)
        return false
    end
    local forever = TC.IsForeverClient()
    if forever ~= nil and forever ~= (T.id == "Forever") then
        self.ok = false
        self.reason = string.format("this %s build is for %s, but this client is %s. "
            .. "No guides were loaded, because their quests and coordinates would be wrong here.",
            ns.name, T.name, forever and "World of Warcraft: Forever" or "not World of Warcraft: Forever")
        return false
    end
    if T.verified == false then
        self.ok = false
        self.reason = string.format("%s data for %s has not been verified in the live game yet, so no guides are loaded. "
            .. "The other tools still work.", ns.name, T.name)
        return false
    end
    return true
end

-- true on the Forever client, false on another client that reports a project id, nil when it cannot tell.
function TC.IsForeverClient()
    if type(WOW_PROJECT_ID) ~= "number" then return nil end
    return WOW_PROJECT_CAMELOT ~= nil and WOW_PROJECT_ID == WOW_PROJECT_CAMELOT
end

-- One chat line at login (Core/Boot.lua), and the same text in /cg debug.
function TC:Message()
    if not self.ok then return "|cffff5555" .. self.reason .. "|r" end
    if self.warning then return "|cffff7744note:|r " .. self.warning end
end

TC:Evaluate()

-- Is this character on the Hardcore ruleset? On a Hardcore realm the client says so (C_GameRules.IsHardcoreActive);
-- anywhere else the player can still choose it in Settings -> Guide Routing (per character), for self-imposed
-- Hardcore runs. Only targets with a Hardcore ruleset (Target.hardcore) have the Hardcore route flavor.
function TC.HardcoreRealm()
    return C_GameRules and type(C_GameRules.IsHardcoreActive) == "function" and C_GameRules.IsHardcoreActive() == true or false
end

function ns:IsHardcore()
    if not ns.Target.hardcore then return false end
    return TC.HardcoreRealm() or (ns.char and ns.char.hardcore == true) or false
end
