-- ClassicGuide - compiled guide data. GENERATED from guides-src/horde/24_shimmeringflats.guide by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .guide source and rebuild. Guide routes and notes are original ClassicGuide content
-- (GPL-3.0-only); quest ids, NPC names and coordinates were looked up in the bundled QuestieDB-derived data.
local _, ns = ...
ns.Guides:Register({
  id="H_24_ShimmeringFlats", name="Shimmering Flats (31-32)", faction="Horde", chapter="Azeroth",
  minLevel=31, maxLevel=32, zone=400, zoneName="Thousand Needles",
  desc="Shimmering Flats, visit 3 of 4 on the Horde route, levels 31-32.",
  next={{id="H_25_Desolace"},},
  steps={
    {"travel",text="Travel to Thousand Needles",dest="Thousand Needles",v=1},
    {"accept",q=1718,title="The Islander",npc="Torm Ragetotem",z=1638,x=57.2,y=87.4,classes={"WARRIOR"},races={"Orc","Scourge","Tauren","Troll"},optional=true,v=1},
    {"accept",q=1102,title="A Vengeful Fate",npc="Auld Stonespire",z=1638,x=36,y=59.9,dungeon="Razorfen Kraul",v=1},
    {"complete",q=1102,title="A Vengeful Fate",dungeon="Razorfen Kraul",v=1},
    {"turnin",q=1102,title="A Vengeful Fate",npc="Auld Stonespire",z=1638,x=36,y=59.9,dungeon="Razorfen Kraul",v=1},
    {"turnin",q=1718,title="The Islander",npc="Klannoc Macleod",z=17,x=68.6,y=49.2,text="Turned in at The Barrens.",classes={"WARRIOR"},races={"Orc","Scourge","Tauren","Troll"},optional=true,v=1},
    {"accept",q=1719,title="The Affray",npc="Klannoc Macleod",z=17,x=68.6,y=49.2,classes={"WARRIOR"},races={"Orc","Scourge","Tauren","Troll"},v=1},
    {"complete",q=1719,title="The Affray",classes={"WARRIOR"},races={"Orc","Scourge","Tauren","Troll"},v=1},
    {"turnin",q=1719,title="The Affray",npc="Klannoc Macleod",z=17,x=68.6,y=49.2,text="Turned in at The Barrens.",classes={"WARRIOR"},races={"Orc","Scourge","Tauren","Troll"},v=1},
    {"accept",q=1145,title="The Swarm Grows",npc="Korran",z=17,x=51.1,y=29.6,v=1},
    {"turnin",q=1145,title="The Swarm Grows",npc="Belgrom Rockmaul",z=1637,x=75.2,y=34.2,text="Turned in at Orgrimmar.",classes={"WARRIOR"},races={"Orc","Scourge","Tauren","Troll"},v=1},
    {"turnin",q=1145,title="The Swarm Grows",npc="Belgrom Rockmaul",z=1637,x=75.2,y=34.2,text="Turned in at Orgrimmar.",classes={"ROGUE","PRIEST","MAGE","WARLOCK"},races={"Scourge"},v=1},
    {"turnin",q=1145,title="The Swarm Grows",npc="Belgrom Rockmaul",z=1637,x=75.2,y=34.2,text="Turned in at Orgrimmar.",classes={"HUNTER","ROGUE","SHAMAN","WARLOCK"},races={"Orc"},v=1},
    {"turnin",q=1145,title="The Swarm Grows",npc="Belgrom Rockmaul",z=1637,x=75.2,y=34.2,text="Turned in at Orgrimmar.",classes={"HUNTER","ROGUE","PRIEST","SHAMAN","MAGE"},races={"Troll"},v=1},
    {"turnin",q=1145,title="The Swarm Grows",npc="Belgrom Rockmaul",z=1637,x=75.2,y=34.2,text="Turned in at Orgrimmar.",classes={"HUNTER","SHAMAN","DRUID"},races={"Tauren"},v=1},
    {"accept",q=1175,title="A Bump in the Road",npc="Trackmaster Zherin",z=400,x=81.6,y=78,text="Trackmaster Zherin.",v=1},
    {"complete",q=1175,title="A Bump in the Road",text="Saltstone basilisks.",v=1},
    {"turnin",q=1175,title="A Bump in the Road",npc="Trackmaster Zherin",z=400,x=81.6,y=78,v=1},
    {"accept",q=1110,title="Rocket Car Parts",npc="Kravel Koalbeard",z=400,x=77.8,y=77.3,text="Kravel Koalbeard.",v=1},
    {"complete",q=1110,title="Rocket Car Parts",text="Parts scattered on the flats.",v=1},
    {"turnin",q=1110,title="Rocket Car Parts",npc="Kravel Koalbeard",z=400,x=77.8,y=77.3,v=1},
    {"level",text="Desolace starts at 32. If you are lower, kill what is around you here (or run a dungeon) until you reach it.",level=32,v=1},
  },
})
