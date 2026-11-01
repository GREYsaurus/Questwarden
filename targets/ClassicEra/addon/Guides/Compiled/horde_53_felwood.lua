-- Questwarden - compiled guide data. GENERATED from guides-src/horde/53_felwood.guide by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .guide source and rebuild. Guide routes and notes are original Questwarden content
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
    {"accept",q=5204,title="Retribution of the Light",npc="Jessir Moonbow",z=361,x=51.4,y=82,v=1},
    {"turnin",q=8462,title="Speak to Nafien",npc="Nafien",z=361,x=64.8,y=8.1,v=1},
    {"turnin",q=5084,title="Falling to Corruption",npc="Deadwood Cauldron",z=361,x=60.2,y=5.8,v=1},
    {"fp",npc="Brakkar",z=361,x=34.4,y=54,place="Bloodvenom Post",node=48,v=1},
    {"accept",q=4102,title="Cleansing Felwood",npc="Maybess Riverbreeze",z=361,x=46.8,y=83.1,text="Maybess Riverbreeze, Emerald Sanctuary.",v=1},
    {"complete",q=5204,title="Retribution of the Light",v=1},
    {"turnin",q=5204,title="Retribution of the Light",npc="Remains of Trey Lightforge",z=361,x=38.5,y=50.4,v=1},
    {"turnin",q=6605,title="A Strange One",npc="Winna Hazzard",z=361,x=34.2,y=52.3,optional=true,v=1},
    {"complete",q=4102,title="Cleansing Felwood",text="Blood Amber drops from Dessecus, Warpwood Moss Flayer and Warpwood Shredder.",v=1},
    {"turnin",q=4102,title="Cleansing Felwood",npc="Maybess Riverbreeze",z=361,x=46.8,y=83.1,v=1},
    {"accept",q=5385,title="The Remains of Trey Lightforge",npc="Remains of Trey Lightforge",z=361,x=38.5,y=50.4,v=1},
    {"accept",q=5887,title="Salve via Hunting",npc="Maybess Riverbreeze",z=361,x=46.8,y=83.1,text="Maybess Riverbreeze. Needs Cleansing Felwood turned in.",v=1},
    {"turnin",q=5385,title="The Remains of Trey Lightforge",npc="Jessir Moonbow",z=361,x=51.4,y=82,v=1},
    {"complete",q=5887,title="Salve via Hunting",text="Corrupted Soul Shards from Cursed Oozes in the Ruins of Constellas, west of the road.",v=1},
    {"turnin",q=5887,title="Salve via Hunting",npc="Maybess Riverbreeze",z=361,x=46.8,y=83.1,v=1},
    {"grind",z=361,x=38,y=49.9,text="Western Plaguelands starts at 56 and the quests here don't quite get you there: grind these until you reach it.",level=56,mobs={"Jaedenar Darkweaver","Jaedenar Legionnaire","Jaedenar Warlock"},v=0},
  },
})
