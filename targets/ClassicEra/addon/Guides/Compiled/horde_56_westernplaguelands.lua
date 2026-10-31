-- Questwarden - compiled guide data. GENERATED from guides-src/horde/56_westernplaguelands.guide by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .guide source and rebuild. Guide routes and notes are original Questwarden content
-- (GPL-3.0-only); quest ids, NPC names and coordinates were looked up in the bundled QuestieDB-derived data.
local _, ns = ...
ns.Guides:Register({
  id="H_56_WesternPlaguelands", name="Western Plaguelands (57-58)", faction="Horde", chapter="Azeroth",
  minLevel=57, maxLevel=58, zone=28, zoneName="Western Plaguelands",
  desc="Western Plaguelands, visit 2 of 2 on the Horde route, levels 57-58.",
  next={{id="H_57_Silithus"},},
  steps={
    {"travel",text="Travel to Western Plaguelands",dest="Western Plaguelands",v=1},
    {"accept",q=5341,title="Barov Family Fortune",npc="Alexi Barov",z=85,x=83.1,y=71.6,dungeon="Scholomance",v=1},
    {"complete",q=5341,title="Barov Family Fortune",dungeon="Scholomance",v=1},
    {"turnin",q=5341,title="Barov Family Fortune",npc="Alexi Barov",z=85,x=83.1,y=71.6,dungeon="Scholomance",v=1},
    {"accept",q=5235,title="Target: Gahrron's Withering",npc="Shadow Priestess Vandis",z=85,x=83,y=71.9,v=1},
    {"turnin",q=6390,title="A Plague Upon Thee",npc="Mickey Levine",z=85,x=83.3,y=72.3,v=1},
    {"complete",q=5235,title="Target: Gahrron's Withering",text="The cauldron at Gahrron's Withering.",v=1},
    {"turnin",q=5235,title="Target: Gahrron's Withering",npc="Scourge Cauldron",z=28,x=62.5,y=58.5,v=1},
    {"accept",q=5236,title="Return to the Bulwark",npc="Scourge Cauldron",z=28,x=62.5,y=58.5,v=1},
    {"turnin",q=5236,title="Return to the Bulwark",npc="Shadow Priestess Vandis",z=85,x=83,y=71.9,text="Turned in at Tirisfal Glades.",v=1},
    {"accept",q=5238,title="Mission Accomplished!",npc="High Executor Derrington",z=85,x=83.1,y=68.9,v=1},
    {"turnin",q=5238,title="Mission Accomplished!",npc="High Executor Derrington",z=85,x=83.1,y=68.9,text="Turned in at Tirisfal Glades.",v=1},
    {"accept",q=6025,title="Unfinished Business",npc="Kirsta Deepshadow",z=28,x=51.9,y=28.1,v=1},
    {"turnin",q=6025,title="Unfinished Business",npc="Kirsta Deepshadow",z=28,x=51.9,y=28.1,v=1},
    {"level",text="Silithus starts at 58. If you are lower, kill what is around you here (or run a dungeon) until you reach it.",level=58,v=1},
  },
})
