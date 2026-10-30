-- ClassicGuide - compiled guide data. GENERATED from guides-src/horde/53_felwood.guide by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .guide source and rebuild. Guide routes and notes are original ClassicGuide content
-- (GPL-3.0-only); quest ids, NPC names and coordinates were looked up in the bundled QuestieDB-derived data.
local _, ns = ...
ns.Guides:Register({
  id="H_53_Felwood", name="Felwood (55-56)", faction="Horde", chapter="Azeroth",
  minLevel=55, maxLevel=56, zone=361, zoneName="Felwood",
  desc="Felwood, visit 2 of 2 on the Horde route, levels 55-56.",
  next={{id="H_54_WesternPlaguelands"},},
  steps={
    {"travel",text="Travel to Felwood",dest="Felwood",v=1},
    {"note",text="No quests are written for this visit yet.",v=1},
    {"level",text="Western Plaguelands starts at 56. If you are lower, kill what is around you here (or run a dungeon) until you reach it.",level=56,v=1},
  },
})
