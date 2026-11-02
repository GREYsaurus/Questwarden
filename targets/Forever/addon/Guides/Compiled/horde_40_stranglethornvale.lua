-- Questwarden - compiled guide data. GENERATED from guides-src/horde/40_stranglethornvale.guide by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .guide source and rebuild. Guide routes and notes are original Questwarden content
-- (GPL-3.0-only); quest ids, NPC names and coordinates were looked up in the bundled QuestieDB-derived data.
local _, ns = ...
ns.Guides:Register({
  id="H_40_StranglethornVale", name="Stranglethorn Vale (47)", faction="Horde", chapter="Azeroth",
  minLevel=47, maxLevel=47, zone=33, zoneName="Stranglethorn Vale",
  desc="Stranglethorn Vale, visit 5 of 5 on the Horde route, levels 47.",
  next={{id="H_41_SearingGorge"},},
  steps={
    {"travel",text="Travel to Stranglethorn Vale",dest="Stranglethorn Vale",v=1},
    {"accept",q=586,title="Speaking with Gan'zulah",npc="Bubbling Cauldron",z=33,x=32.2,y=27.6,v=1},
    {"bind",npc="Innkeeper Thulbek",z=33,x=31.5,y=29.8,place="Grom'gol Base Camp",npcId=5814,areas={117},v=1},
    {"complete",q=586,title="Speaking with Gan'zulah",v=1},
    {"turnin",q=586,title="Speaking with Gan'zulah",npc="Bubbling Cauldron",z=33,x=32.2,y=27.6,v=1},
    {"accept",q=588,title="The Fate of Yenniku",npc="Bubbling Cauldron",z=33,x=32.2,y=27.6,v=1},
    {"turnin",q=588,title="The Fate of Yenniku",npc="Kin'weelay",z=33,x=32.3,y=27.7,v=1},
    {"accept",q=589,title="The Singing Crystals",npc="Kin'weelay",z=33,x=32.3,y=27.7,v=1},
    {"complete",q=589,title="The Singing Crystals",v=1},
    {"turnin",q=589,title="The Singing Crystals",npc="Kin'weelay",z=33,x=32.3,y=27.7,v=1},
    {"accept",q=608,title="The Bloodsail Buccaneers",npc="Fleet Master Seahorn",z=33,x=27.2,y=77,v=1},
    {"complete",q=608,title="The Bloodsail Buccaneers",v=1},
    {"turnin",q=608,title="The Bloodsail Buccaneers",npc="Fleet Master Seahorn",z=33,x=27.2,y=77,v=1},
    {"level",text="Searing Gorge starts at 47. If you are lower, kill what is around you here (or run a dungeon) until you reach it.",level=47,v=1},
  },
})
