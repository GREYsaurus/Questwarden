-- ClassicGuide - compiled guide data. GENERATED from guides-src/horde/50_azshara.guide by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .guide source and rebuild. Guide routes and notes are original ClassicGuide content
-- (GPL-3.0-only); quest ids, NPC names and coordinates were looked up in the bundled QuestieDB-derived data.
local _, ns = ...
ns.Guides:Register({
  id="H_50_Azshara", name="Azshara (53-54)", faction="Horde", chapter="Azeroth",
  minLevel=53, maxLevel=54, zone=16, zoneName="Azshara",
  desc="Azshara, visit 2 of 2 on the Horde route, levels 53-54.",
  next={{id="H_51_Felwood"},},
  steps={
    {"travel",text="Travel to Azshara",dest="Azshara",v=1},
    {"note",text="No quests are written for this visit yet.",v=1},
    {"level",text="Felwood starts at 54. If you are lower, kill what is around you here (or run a dungeon) until you reach it.",level=54,v=1},
  },
})
