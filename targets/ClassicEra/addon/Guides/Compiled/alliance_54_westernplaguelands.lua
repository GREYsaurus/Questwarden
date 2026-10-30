-- ClassicGuide - compiled guide data. GENERATED from guides-src/alliance/54_westernplaguelands.guide by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .guide source and rebuild. Guide routes and notes are original ClassicGuide content
-- (GPL-3.0-only); quest ids, NPC names and coordinates were looked up in the bundled QuestieDB-derived data.
local _, ns = ...
ns.Guides:Register({
  id="A_54_WesternPlaguelands", name="Western Plaguelands (57-58)", faction="Alliance", chapter="Azeroth",
  minLevel=57, maxLevel=58, zone=28, zoneName="Western Plaguelands",
  desc="Western Plaguelands, visit 2 of 2 on the Alliance route, levels 57-58.",
  next={{id="A_55_Felwood"},},
  steps={
    {"travel",text="Travel to Western Plaguelands",dest="Western Plaguelands",v=1},
    {"accept",q=5343,title="Barov Family Fortune",npc="Weldon Barov",z=28,x=43.4,y=83.7,dungeon="Scholomance",v=1},
    {"accept",q=5382,title="Doctor Theolen Krastinov, the Butcher",npc="Eva Sarkhoff",z=28,x=70.2,y=73.7,dungeon="Scholomance",v=1},
    {"complete",q=5382,title="Doctor Theolen Krastinov, the Butcher",dungeon="Scholomance",v=1},
    {"turnin",q=5382,title="Doctor Theolen Krastinov, the Butcher",npc="Eva Sarkhoff",z=28,x=70.2,y=73.7,dungeon="Scholomance",v=1},
    {"complete",q=5343,title="Barov Family Fortune",dungeon="Scholomance",v=1},
    {"turnin",q=5343,title="Barov Family Fortune",npc="Weldon Barov",z=28,x=43.4,y=83.7,dungeon="Scholomance",v=1},
    {"level",text="Felwood starts at 58. If you are lower, kill what is around you here (or run a dungeon) until you reach it.",level=58,v=1},
  },
})
