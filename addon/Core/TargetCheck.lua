-- ClassicGuide - is this the game client this build was made for? (docs/COMPATIBILITY.md)
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
-- warning. WOW_PROJECT_ID and C_GameRules (Hardcore) are not on the API allowlist yet.

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
    if T.verified == false then
        self.ok = false
        self.reason = string.format("%s data for %s has not been verified in the live game yet, so no guides are loaded. "
            .. "The other tools still work.", ns.name, T.name)
        return false
    end
    return true
end

-- One chat line at login (Core/Boot.lua), and the same text in /cg debug.
function TC:Message()
    if not self.ok then return "|cffff5555" .. self.reason .. "|r" end
    if self.warning then return "|cffff7744note:|r " .. self.warning end
end

TC:Evaluate()

-- Is this character on the Hardcore ruleset? The player says so in Settings -> Guide Routing (per character).
-- Detecting Hardcore realms needs C_GameRules.IsHardcoreActive, which is not on the API allowlist yet.
function ns:IsHardcore()
    return ns.Target.hardcore and ns.char and ns.char.hardcore == true or false
end
