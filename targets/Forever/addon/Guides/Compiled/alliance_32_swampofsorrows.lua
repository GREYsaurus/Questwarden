-- Questwarden - compiled guide data. GENERATED from guides-src/alliance/32_swampofsorrows.guide by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .guide source and rebuild. Guide routes and notes are original Questwarden content
-- (GPL-3.0-only); quest ids, NPC names and coordinates were looked up in the bundled QuestieDB-derived data.
local _, ns = ...
ns.Guides:Register({
  id="A_32_SwampofSorrows", name="Swamp of Sorrows (41-42)", faction="Alliance", chapter="Azeroth",
  minLevel=41, maxLevel=42, zone=8, zoneName="Swamp of Sorrows",
  desc="Swamp of Sorrows, visit 1 of 1 on the Alliance route, levels 41-42.",
  next={{id="A_33_StranglethornVale"},},
  steps={
    {"travel",text="Travel to Swamp of Sorrows",dest="Swamp of Sorrows",v=1},
    {"accept",q=1396,title="Encroaching Wildlife",npc="Watcher Biggs",z=8,x=26.7,y=59.8,v=1},
    {"note",text="The next quest, Galen's Escape, is an escort: pick it up only when you are ready to follow the NPC.",v=1},
    {"accept",q=1393,title="Galen's Escape",npc="Galen Goodward",z=8,x=65.5,y=18.2,v=1},
    {"complete",q=1393,title="Galen's Escape",text="Escort: stay close; it fails if the NPC dies.",v=1},
    {"complete",q=1396,title="Encroaching Wildlife",v=1},
    {"turnin",q=1393,title="Galen's Escape",npc="Galen's Strongbox",z=8,x=47.8,y=39.8,v=1},
    {"turnin",q=1396,title="Encroaching Wildlife",npc="Watcher Biggs",z=8,x=26.7,y=59.8,v=1},
    {"level",text="Stranglethorn Vale starts at 42. If you are lower, kill what is around you here (or run a dungeon) until you reach it.",level=42,v=1},
  },
})
