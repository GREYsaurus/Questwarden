-- Questwarden - compiled guide data. GENERATED from guides-src/horde/11_stonetalonmountains.guide by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .guide source and rebuild. Guide routes and notes are original Questwarden content
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
    {"grind",z=406,x=57.1,y=75.5,text="The Barrens starts at 16 and the quests here don't quite get you there: grind these until you reach it.",level=16,mobs={"Deepmoss Creeper"},v=0},
  },
})
