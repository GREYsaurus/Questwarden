-- ClassicGuide - compiled guide data. GENERATED from guides-src/horde/49_burningsteppes.guide by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .guide source and rebuild. Guide routes and notes are original ClassicGuide content
-- (GPL-3.0-only); quest ids, NPC names and coordinates were looked up in the bundled QuestieDB-derived data.
local _, ns = ...
ns.Guides:Register({
  id="H_49_BurningSteppes", name="Burning Steppes (53)", faction="Horde", chapter="Azeroth",
  minLevel=53, maxLevel=53, zone=46, zoneName="Burning Steppes",
  desc="Burning Steppes, visit 1 of 1 on the Horde route, levels 53.",
  next={{id="H_50_Azshara"},},
  steps={
    {"travel",text="Travel to Burning Steppes",dest="Burning Steppes",v=1},
    {"note",text="No quests are written for this visit yet.",v=1},
    {"level",text="Azshara starts at 53. If you are lower, kill what is around you here (or run a dungeon) until you reach it.",level=53,v=1},
  },
})
