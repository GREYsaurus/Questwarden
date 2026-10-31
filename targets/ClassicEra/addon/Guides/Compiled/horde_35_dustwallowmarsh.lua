-- Questwarden - compiled guide data. GENERATED from guides-src/horde/35_dustwallowmarsh.guide by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .guide source and rebuild. Guide routes and notes are original Questwarden content
-- (GPL-3.0-only); quest ids, NPC names and coordinates were looked up in the bundled QuestieDB-derived data.
local _, ns = ...
ns.Guides:Register({
  id="H_35_DustwallowMarsh", name="Dustwallow Marsh (43-44)", faction="Horde", chapter="Azeroth",
  minLevel=43, maxLevel=44, zone=15, zoneName="Dustwallow Marsh",
  desc="Dustwallow Marsh, visit 2 of 3 on the Horde route, levels 43-44.",
  next={{id="H_36_Desolace"},},
  steps={
    {"travel",text="Travel to Dustwallow Marsh",dest="Dustwallow Marsh",v=1},
    {"fp",npc="Shardi",z=15,x=35.6,y=31.9,place="Brackenwall Village",node=55,v=1},
    {"accept",q=1169,title="Identifying the Brood",npc="Draz'Zilb",z=15,x=37.2,y=33.1,text="Draz'Zilb.",v=1},
    {"accept",q=1166,title="Overlord Mok'Morokk's Concern",npc="Overlord Mok'Morokk",z=15,x=36.3,y=31.4,v=1},
    {"accept",q=1168,title="Army of the Black Dragon",npc="Tharg",z=15,x=37.4,y=31.4,text="Tharg.",v=1},
    {"complete",q=1169,title="Identifying the Brood",text="Black dragonspawn in the south.",v=1},
    {"complete",q=1168,title="Army of the Black Dragon",v=1},
    {"complete",q=1166,title="Overlord Mok'Morokk's Concern",text="Mok'Morokk's Snuff: loot Mok'Morokk's Snuff. Mok'Morokk's Grog: loot Mok'Morokk's Grog.",v=1},
    {"turnin",q=1169,title="Identifying the Brood",npc="Draz'Zilb",z=15,x=37.2,y=33.1,v=1},
    {"accept",q=1170,title="The Brood of Onyxia",npc="Draz'Zilb",z=15,x=37.2,y=33.1,v=1},
    {"turnin",q=1166,title="Overlord Mok'Morokk's Concern",npc="Overlord Mok'Morokk",z=15,x=36.3,y=31.4,v=1},
    {"turnin",q=1170,title="The Brood of Onyxia",npc="Overlord Mok'Morokk",z=15,x=36.3,y=31.4,v=1},
    {"accept",q=1171,title="The Brood of Onyxia",npc="Overlord Mok'Morokk",z=15,x=36.3,y=31.4,v=1},
    {"turnin",q=1171,title="The Brood of Onyxia",npc="Draz'Zilb",z=15,x=37.2,y=33.1,v=1},
    {"accept",q=1172,title="The Brood of Onyxia",npc="Draz'Zilb",z=15,x=37.2,y=33.1,hcSkip=true,v=1},
    {"note",text=" - Hardcore: the eggs lie in the Wyrmbog, close to the dragonkin guarding Onyxia's Lair. Stay on the outer edge, and leave this quest out rather than go deep.",hcOnly=true,v=1},
    {"complete",q=1172,title="The Brood of Onyxia",text="Destroy the eggs in Wyrmbog.",hcSkip=true,v=1},
    {"turnin",q=1172,title="The Brood of Onyxia",npc="Draz'Zilb",z=15,x=37.2,y=33.1,hcSkip=true,v=1},
    {"turnin",q=1168,title="Army of the Black Dragon",npc="Tharg",z=15,x=37.4,y=31.4,v=1},
    {"level",text="Desolace starts at 44. If you are lower, kill what is around you here (or run a dungeon) until you reach it.",level=44,v=1},
  },
})
