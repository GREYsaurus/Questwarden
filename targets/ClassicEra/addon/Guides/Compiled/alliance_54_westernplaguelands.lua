-- Questwarden - compiled guide data. GENERATED from guides-src/alliance/54_westernplaguelands.guide by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .guide source and rebuild. Guide routes and notes are original Questwarden content
-- (GPL-3.0-only); quest ids, NPC names and coordinates were looked up in the bundled QuestieDB-derived data.
local _, ns = ...
ns.Guides:Register({
  id="A_54_WesternPlaguelands", name="Western Plaguelands (57-58)", faction="Alliance", chapter="Azeroth",
  minLevel=57, maxLevel=58, zone=28, zoneName="Western Plaguelands",
  desc="Western Plaguelands, visit 2 of 2 on the Alliance route, levels 57-58.",
  next={{id="A_55_Felwood"},},
  steps={
    {"fly",text="Take the flight from Light's Hope Chapel.",dest="Chillwind Camp",node=66,v=1},
    {"travel",text="Travel to Western Plaguelands",dest="Western Plaguelands",v=1},
    {"accept",q=5343,title="Barov Family Fortune",npc="Weldon Barov",z=28,x=43.4,y=83.7,dungeon="Scholomance",v=1},
    {"turnin",q=5152,title="Auntie Marlene",npc="Marlene Redpath",z=28,x=49.2,y=78.6,optional=true,v=1},
    {"accept",q=5382,title="Doctor Theolen Krastinov, the Butcher",npc="Eva Sarkhoff",z=28,x=70.2,y=73.7,dungeon="Scholomance",v=1},
    {"complete",q=5382,title="Doctor Theolen Krastinov, the Butcher",dungeon="Scholomance",v=1},
    {"turnin",q=5382,title="Doctor Theolen Krastinov, the Butcher",npc="Eva Sarkhoff",z=28,x=70.2,y=73.7,dungeon="Scholomance",v=1},
    {"complete",q=5343,title="Barov Family Fortune",dungeon="Scholomance",v=1},
    {"turnin",q=5343,title="Barov Family Fortune",npc="Weldon Barov",z=28,x=43.4,y=83.7,dungeon="Scholomance",v=1},
    {"accept",q=5153,title="A Strange Historian",npc="Marlene Redpath",z=28,x=49.2,y=78.6,v=1},
    {"accept",q=5225,title="Target: Gahrron's Withering",npc="High Priestess MacDonnell",z=28,x=43,y=84.5,v=1},
    {"complete",q=5225,title="Target: Gahrron's Withering",text="Cauldron Lord Soulwrath at the Gahrron's Withering cauldron, east.",v=1},
    {"turnin",q=5225,title="Target: Gahrron's Withering",npc="Scourge Cauldron",z=28,x=62.5,y=58.5,v=1},
    {"accept",q=5226,title="Return to Chillwind Camp",npc="Scourge Cauldron",z=28,x=62.5,y=58.5,v=1},
    {"turnin",q=5226,title="Return to Chillwind Camp",npc="High Priestess MacDonnell",z=28,x=43,y=84.5,v=1},
    {"accept",q=5237,title="Mission Accomplished!",npc="Commander Ashlam Valorfist",z=28,x=42.7,y=84,v=1},
    {"turnin",q=5237,title="Mission Accomplished!",npc="Commander Ashlam Valorfist",z=28,x=42.7,y=84,text="Commander Ashlam Valorfist.",v=1},
    {"accept",q=6025,title="Unfinished Business",npc="Kirsta Deepshadow",z=28,x=51.9,y=28.1,v=1},
    {"complete",q=6025,title="Unfinished Business",v=1},
    {"turnin",q=6025,title="Unfinished Business",npc="Kirsta Deepshadow",z=28,x=51.9,y=28.1,v=1},
    {"accept",q=5537,title="Skeletal Fragments",npc="Alchemist Arbington",z=28,x=42.7,y=83.8,v=1},
    {"complete",q=5153,title="A Strange Historian",v=1},
    {"complete",q=5537,title="Skeletal Fragments",v=1},
    {"turnin",q=5537,title="Skeletal Fragments",npc="Alchemist Arbington",z=28,x=42.7,y=83.8,v=1},
    {"turnin",q=5153,title="A Strange Historian",npc="Chromie",z=28,x=39.5,y=66.8,v=1},
    {"level",text="Felwood starts at 58. If you are lower, kill what is around you here (or run a dungeon) until you reach it.",level=58,v=1},
  },
})
