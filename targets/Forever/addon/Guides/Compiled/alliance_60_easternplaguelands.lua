-- ClassicGuide - compiled guide data. GENERATED from guides-src/alliance/60_easternplaguelands.guide by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .guide source and rebuild. Guide routes and notes are original ClassicGuide content
-- (GPL-3.0-only); quest ids, NPC names and coordinates were looked up in the bundled QuestieDB-derived data.
local _, ns = ...
ns.Guides:Register({
  id="A_60_EasternPlaguelands", name="Eastern Plaguelands (59)", faction="Alliance", chapter="Azeroth",
  minLevel=59, maxLevel=59, zone=139, zoneName="Eastern Plaguelands",
  desc="Eastern Plaguelands, visit 2 of 2 on the Alliance route, levels 59.",
  next={{id="A_61_Winterspring"},},
  steps={
    {"travel",text="Travel to Eastern Plaguelands",dest="Eastern Plaguelands",v=1},
    {"accept",q=5251,title="The Archivist",npc="Duke Nicholas Zverenhoff",z=139,x=71.6,y=50.1,dungeon="Stratholme",v=1},
    {"accept",q=5281,title="The Restless Souls",npc="Caretaker Alen",z=139,x=69.9,y=53.7,v=1},
    {"accept",q=6024,title="Hameya's Plea",npc="Torn Scroll",z=139,x=22.9,y=73,v=1},
    {"turnin",q=5281,title="The Restless Souls",npc="Egan",z=139,x=11.4,y=26.6,v=1},
    {"accept",q=5212,title="The Flesh Does Not Lie",npc="Betina Bigglezink",z=139,x=71.7,y=49.9,dungeon="Stratholme",v=1},
    {"accept",q=5243,title="Houses of the Holy",npc="Leonid Barthalomew the Revered",z=139,x=71.9,y=48.3,dungeon="Stratholme",v=1},
    {"complete",q=5251,title="The Archivist",dungeon="Stratholme",v=1},
    {"turnin",q=5251,title="The Archivist",npc="Duke Nicholas Zverenhoff",z=139,x=71.6,y=50.1,dungeon="Stratholme",v=1},
    {"complete",q=6024,title="Hameya's Plea",v=1},
    {"turnin",q=6024,title="Hameya's Plea",npc="Mound of Dirt",z=139,x=23.6,y=73.8,v=1},
    {"complete",q=5212,title="The Flesh Does Not Lie",dungeon="Stratholme",v=1},
    {"complete",q=5243,title="Houses of the Holy",dungeon="Stratholme",v=1},
    {"turnin",q=5212,title="The Flesh Does Not Lie",npc="Betina Bigglezink",z=139,x=71.7,y=49.9,dungeon="Stratholme",v=1},
    {"turnin",q=5243,title="Houses of the Holy",npc="Leonid Barthalomew the Revered",z=139,x=71.9,y=48.3,dungeon="Stratholme",v=1},
    {"accept",q=5529,title="Plagued Hatchlings",npc="Betina Bigglezink",z=139,x=71.7,y=49.9,dungeon="Scholomance",v=1},
    {"complete",q=5529,title="Plagued Hatchlings",dungeon="Scholomance",v=1},
    {"turnin",q=5529,title="Plagued Hatchlings",npc="Betina Bigglezink",z=139,x=71.7,y=49.9,dungeon="Scholomance",v=1},
    {"level",text="Winterspring starts at 59. If you are lower, kill what is around you here (or run a dungeon) until you reach it.",level=59,v=1},
  },
})
