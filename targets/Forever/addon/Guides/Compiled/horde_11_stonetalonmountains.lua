-- ClassicGuide - compiled guide data. GENERATED from guides-src/horde/11_stonetalonmountains.guide by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .guide source and rebuild. Guide routes and notes are original ClassicGuide content
-- (GPL-3.0-only); quest ids, NPC names and coordinates were looked up in the bundled QuestieDB-derived data.
local _, ns = ...
ns.Guides:Register({
  id="H_11_StonetalonMountains", name="Stonetalon Mountains (15-16)", faction="Horde", chapter="Azeroth",
  minLevel=15, maxLevel=16, zone=406, zoneName="Stonetalon Mountains",
  desc="Stonetalon Mountains, visit 1 of 4 on the Horde route, levels 15-16.",
  next={{id="H_12_Barrens"},},
  steps={
    {"travel",text="Travel to Stonetalon Mountains",dest="Stonetalon Mountains",v=1},
    {"accept",q=6421,title="Boulderslide Ravine",npc="Mor'rogal",z=406,x=47.2,y=64,v=1},
    {"complete",q=6421,title="Boulderslide Ravine",v=1},
    {"turnin",q=6421,title="Boulderslide Ravine",npc="Mor'rogal",z=406,x=47.2,y=64,v=1},
    {"level",text="The Barrens starts at 16. If you are lower, kill what is around you here (or run a dungeon) until you reach it.",level=16,v=1},
  },
})
