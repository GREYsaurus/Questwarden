-- Questwarden - class leveling tips: lookup and chat output (the tips are target data, Classes/ClassAdvice.lua)
-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
-- This program is free software: you can redistribute it and/or modify it under the terms of the
-- GNU General Public License as published by the Free Software Foundation, version 3.
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
-- even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details. The complete license text is in LICENSE.

local _, ns = ...

local Advice = ns.ClassAdvice or { data = {} }
ns.ClassAdvice = Advice

function Advice:For(class) return self.data[class] end

function Advice:PrintFor(class)
    local a = self.data[class]
    if not a then return ns:Print("No advice for " .. tostring(class)) end
    ns:Print("|cffffd100" .. class .. " leveling tips|r")
    DEFAULT_CHAT_FRAME:AddMessage("  " .. a.summary)
    for _, t in ipairs(a.tips) do DEFAULT_CHAT_FRAME:AddMessage("  - " .. t) end
end

-- Is `level` a level at which this class normally gets new trainable ranks?
function Advice:IsTrainingLevel(class, level)
    local a = self.data[class]
    return a and ns.Contains(a.trainingLevels, level) or false
end
