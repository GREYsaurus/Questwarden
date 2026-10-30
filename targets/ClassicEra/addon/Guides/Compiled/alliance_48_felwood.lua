-- ClassicGuide - compiled guide data. GENERATED from guides-src/alliance/48_felwood.guide by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .guide source and rebuild. Guide routes and notes are original ClassicGuide content
-- (GPL-3.0-only); quest ids, NPC names and coordinates were looked up in the bundled QuestieDB-derived data.
local _, ns = ...
ns.Guides:Register({
  id="A_48_Felwood", name="Felwood (53-54)", faction="Alliance", chapter="Azeroth",
  minLevel=53, maxLevel=54, zone=361, zoneName="Felwood",
  desc="Felwood, visit 1 of 3 on the Alliance route, levels 53-54.",
  next={{id="A_49_Winterspring"},},
  steps={
    {"travel",text="Travel to Felwood",dest="Felwood",v=1},
    {"accept",q=8461,title="Deadwood of the North",npc="Nafien",z=361,x=64.8,y=8.1,text="Nafien.",v=1},
    {"complete",q=8461,title="Deadwood of the North",text="Deadwood furbolgs in northern Felwood.",v=1},
    {"turnin",q=8461,title="Deadwood of the North",npc="Nafien",z=361,x=64.8,y=8.1,v=1},
    {"accept",q=8465,title="Speak to Salfa",npc="Nafien",z=361,x=64.8,y=8.1,text="Nafien. Turned in at the Winterspring end of the Timbermaw tunnel.",v=1},
    {"accept",q=4421,title="The Corruption of the Jadefire",npc="Eridan Bluewind",z=361,x=51.4,y=81.5,text="Eridan Bluewind.",v=1},
    {"complete",q=4421,title="The Corruption of the Jadefire",text="Jadefire satyrs at Jadefire Glen.",v=1},
    {"turnin",q=4421,title="The Corruption of the Jadefire",npc="Eridan Bluewind",z=361,x=51.4,y=81.5,v=1},
    {"accept",q=4906,title="Further Corruption",npc="Eridan Bluewind",z=361,x=51.4,y=81.5,v=1},
    {"complete",q=4906,title="Further Corruption",text="Xavathras, Jadefire Glen.",v=1},
    {"turnin",q=4906,title="Further Corruption",npc="Eridan Bluewind",z=361,x=51.4,y=81.5,v=1},
    {"accept",q=5156,title="Verifying the Corruption",npc="Taronn Redfeather",z=361,x=50.9,y=81.6,text="Taronn Redfeather.",v=1},
    {"complete",q=5156,title="Verifying the Corruption",text="Explore the area north of Shatter Scar Vale.",v=1},
    {"turnin",q=5156,title="Verifying the Corruption",npc="Taronn Redfeather",z=361,x=50.9,y=81.6,v=1},
    {"accept",q=5155,title="Forces of Jaedenar",npc="Greta Mosshoof",z=361,x=51.2,y=82.1,text="Greta Mosshoof, Emerald Sanctuary.",v=1},
    {"complete",q=5155,title="Forces of Jaedenar",text="Jaedenar cultists.",v=1},
    {"turnin",q=5155,title="Forces of Jaedenar",npc="Greta Mosshoof",z=361,x=51.2,y=82.1,v=1},
    {"accept",q=5157,title="Collection of the Corrupt Water",npc="Greta Mosshoof",z=361,x=51.2,y=82.1,v=1},
    {"complete",q=5157,title="Collection of the Corrupt Water",text="Fill the vessel at the corrupted moonwell in Jaedenar.",v=1},
    {"turnin",q=5157,title="Collection of the Corrupt Water",npc="Greta Mosshoof",z=361,x=51.2,y=82.1,v=1},
    {"fp",npc="Mishellena",z=361,x=62.5,y=24.2,place="Talonbranch Glade",v=1},
    {"accept",q=8460,title="Timbermaw Ally",npc="Grazle",z=361,x=50.9,y=85,text="Grazle, Timbermaw Hold area.",v=1},
    {"turnin",q=8460,title="Timbermaw Ally",npc="Grazle",z=361,x=50.9,y=85,v=1},
    {"level",text="Winterspring starts at 54. If you are lower, kill what is around you here (or run a dungeon) until you reach it.",level=54,v=1},
  },
})
