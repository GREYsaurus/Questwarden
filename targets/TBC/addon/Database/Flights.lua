-- ClassicGuide - flight graph: none for this target (the TBC fixture keeps TBCGuide's data).
-- Targets with clientTables.flights in target.json get a generated Database/Flights.lua (tools/build.ps1 import-client).
local _, ns = ...
ns.Flights = { nodes = {}, links = {} }
