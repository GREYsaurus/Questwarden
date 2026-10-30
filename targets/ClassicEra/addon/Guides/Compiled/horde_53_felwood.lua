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
    {"accept",q=8462,title="Speak to Nafien",npc="Grazle",z=361,x=50.9,y=85,v=1},
    {"turnin",q=8462,title="Speak to Nafien",npc="Nafien",z=361,x=64.8,y=8.1,v=1},
    {"fp",npc="Brakkar",z=361,x=34.4,y=54,place="Bloodvenom Post",v=1},
    {"accept",q=4102,title="Cleansing Felwood",npc="Maybess Riverbreeze",z=361,x=46.8,y=83.1,text="Maybess Riverbreeze, Emerald Sanctuary.",v=1},
    {"complete",q=4102,title="Cleansing Felwood",text="Blood Amber drops from Dessecus, Warpwood Moss Flayer and Warpwood Shredder.",v=1},
    {"turnin",q=4102,title="Cleansing Felwood",npc="Maybess Riverbreeze",z=361,x=46.8,y=83.1,v=1},
    {"accept",q=5887,title="Salve via Hunting",npc="Maybess Riverbreeze",z=361,x=46.8,y=83.1,text="Maybess Riverbreeze. Needs Cleansing Felwood turned in.",v=1},
    {"complete",q=5887,title="Salve via Hunting",text="Corrupted Soul Shards from Cursed Oozes in the Ruins of Constellas, west of the road.",v=1},
    {"turnin",q=5887,title="Salve via Hunting",npc="Maybess Riverbreeze",z=361,x=46.8,y=83.1,v=1},
    {"level",text="Western Plaguelands starts at 56. If you are lower, kill what is around you here (or run a dungeon) until you reach it.",level=56,v=1},
  },
})
