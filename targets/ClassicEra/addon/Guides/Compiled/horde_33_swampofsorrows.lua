-- ClassicGuide - compiled guide data. GENERATED from guides-src/horde/33_swampofsorrows.guide by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .guide source and rebuild. Guide routes and notes are original ClassicGuide content
-- (GPL-3.0-only); quest ids, NPC names and coordinates were looked up in the bundled QuestieDB-derived data.
local _, ns = ...
ns.Guides:Register({
  id="H_33_SwampofSorrows", name="Swamp of Sorrows (41-42)", faction="Horde", chapter="Azeroth",
  minLevel=41, maxLevel=42, zone=8, zoneName="Swamp of Sorrows",
  desc="Swamp of Sorrows, visit 1 of 2 on the Horde route, levels 41-42.",
  next={{id="H_34_StranglethornVale"},},
  steps={
    {"travel",text="Travel to Swamp of Sorrows",dest="Swamp of Sorrows",v=1},
    {"note",text="From Grom'gol ride north through Duskwood (Alliance zone: keep off the roads) and east through Deadwind Pass into the Swamp of Sorrows.",v=1},
    {"accept",q=1389,title="Draenethyst Crystals",npc="Magtoor",z=8,x=26,y=31.4,text="Magtoor, a Lost One in the hut at the west end of the swamp. He is friendly.",v=1},
    {"fp",npc="Breyk",z=8,x=46.1,y=54.8,place="Stonard",v=1},
    {"accept",q=1424,title="Pool of Tears",npc="Fel'zerul",z=8,x=47.9,y=54.8,text="Fel'zerul, Stonard.",v=1},
    {"note",text="The next quest, Galen's Escape, is an escort: pick it up only when you are ready to follow the NPC.",v=1},
    {"accept",q=1393,title="Galen's Escape",npc="Galen Goodward",z=8,x=65.5,y=18.2,v=1},
    {"complete",q=1393,title="Galen's Escape",text="Escort: stay close; it fails if the NPC dies.",v=1},
    {"accept",q=698,title="Lack of Surplus",npc="Dar",z=8,x=44.7,y=57.2,text="Dar, just outside Stonard.",v=1},
    {"accept",q=1430,title="Fresh Meat",npc="Dar",z=8,x=44.7,y=57.2,text="Dar.",v=1},
    {"complete",q=698,title="Lack of Surplus",text="Unprepared Sawtooth Flanks from Sawtooth Crocolisks around the lakes east of Stonard.",v=1},
    {"complete",q=1389,title="Draenethyst Crystals",text="Draenethyst Crystals on the ground in the same north-east area.",v=1},
    {"complete",q=1424,title="Pool of Tears",text="Atal'ai Artifacts on the ground around the Pool of Tears, east of Stonard.",v=1},
    {"turnin",q=698,title="Lack of Surplus",npc="Tok'Kar",z=8,x=81.3,y=81,text="Tok'Kar at the Misty Reed Strand, south-east coast.",v=1},
    {"accept",q=699,title="Lack of Surplus",npc="Tok'Kar",z=8,x=81.3,y=81,v=1},
    {"complete",q=699,title="Lack of Surplus",text="Sawtooth Snapper Claws from Sawtooth Snappers on the east coast, north of Tok'Kar.",v=1},
    {"complete",q=1430,title="Fresh Meat",text="Monstrous Crawler Legs from Monstrous Crawlers on the same east coast.",v=1},
    {"turnin",q=699,title="Lack of Surplus",npc="Tok'Kar",z=8,x=81.3,y=81,text="Tok'Kar.",v=1},
    {"turnin",q=1424,title="Pool of Tears",npc="Fel'zerul",z=8,x=47.9,y=54.8,text="Fel'zerul.",v=1},
    {"turnin",q=1393,title="Galen's Escape",npc="Galen's Strongbox",z=8,x=47.8,y=39.8,v=1},
    {"turnin",q=1430,title="Fresh Meat",npc="Dar",z=8,x=44.7,y=57.2,text="Dar.",v=1},
    {"turnin",q=1389,title="Draenethyst Crystals",npc="Magtoor",z=8,x=26,y=31.4,text="Magtoor, at the west end of the swamp.",v=1},
    {"level",text="Stranglethorn Vale starts at 42. If you are lower, kill what is around you here (or run a dungeon) until you reach it.",level=42,v=1},
  },
})
