-- ClassicGuide - compiled guide data. GENERATED from guides-src/alliance/25_shimmeringflats.guide by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .guide source and rebuild. Guide routes and notes are original ClassicGuide content
-- (GPL-3.0-only); quest ids, NPC names and coordinates were looked up in the bundled QuestieDB-derived data.
local _, ns = ...
ns.Guides:Register({
  id="A_25_ShimmeringFlats", name="Shimmering Flats (33-34)", faction="Alliance", chapter="Azeroth",
  minLevel=33, maxLevel=34, zone=400, zoneName="Thousand Needles",
  desc="Shimmering Flats, visit 1 of 1 on the Alliance route, levels 33-34.",
  next={{id="A_26_StranglethornVale"},},
  steps={
    {"travel",text="Travel to Thousand Needles",dest="Thousand Needles",v=1},
    {"accept",q=1105,title="Hardened Shells",npc="Wizzle Brassbolts",z=400,x=78.1,y=77.1,v=1},
    {"accept",q=1104,title="Salt Flat Venom",npc="Fizzle Brassbolts",z=400,x=78.1,y=77.1,v=1},
    {"accept",q=1110,title="Rocket Car Parts",npc="Kravel Koalbeard",z=400,x=77.8,y=77.3,v=1},
    {"accept",q=1176,title="Load Lightening",npc="Pozzik",z=400,x=80.2,y=75.9,v=1},
    {"accept",q=1175,title="A Bump in the Road",npc="Trackmaster Zherin",z=400,x=81.6,y=78,v=1},
    {"complete",q=1175,title="A Bump in the Road",v=1},
    {"complete",q=1110,title="Rocket Car Parts",v=1},
    {"complete",q=1176,title="Load Lightening",v=1},
    {"complete",q=1104,title="Salt Flat Venom",v=1},
    {"complete",q=1105,title="Hardened Shells",v=1},
    {"turnin",q=1176,title="Load Lightening",npc="Pozzik",z=400,x=80.2,y=75.9,v=1},
    {"turnin",q=1105,title="Hardened Shells",npc="Wizzle Brassbolts",z=400,x=78.1,y=77.1,v=1},
    {"turnin",q=1104,title="Salt Flat Venom",npc="Fizzle Brassbolts",z=400,x=78.1,y=77.1,v=1},
    {"turnin",q=1110,title="Rocket Car Parts",npc="Kravel Koalbeard",z=400,x=77.8,y=77.3,v=1},
    {"turnin",q=1175,title="A Bump in the Road",npc="Trackmaster Zherin",z=400,x=81.6,y=78,v=1},
    {"level",text="Stranglethorn Vale starts at 36. If you are lower, kill what is around you here (or run a dungeon) until you reach it.",level=36,v=1},
  },
})
