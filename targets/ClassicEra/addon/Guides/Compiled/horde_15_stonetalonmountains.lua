-- ClassicGuide - compiled guide data. GENERATED from guides-src/horde/15_stonetalonmountains.guide by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .guide source and rebuild. Guide routes and notes are original ClassicGuide content
-- (GPL-3.0-only); quest ids, NPC names and coordinates were looked up in the bundled QuestieDB-derived data.
local _, ns = ...
ns.Guides:Register({
  id="H_15_StonetalonMountains", name="Stonetalon Mountains (23-25)", faction="Horde", chapter="Azeroth",
  minLevel=23, maxLevel=25, zone=406, zoneName="Stonetalon Mountains",
  desc="Stonetalon Mountains, visit 3 of 4 on the Horde route, levels 23-25.",
  next={{id="H_16_SouthernBarrens"},},
  steps={
    {"travel",text="Travel to Stonetalon Mountains",dest="Stonetalon Mountains",v=1},
    {"accept",q=1058,title="Jin'Zil's Forest Magic",npc="Witch Doctor Jin'Zil",z=406,x=74.5,y=97.9,text="Witch Doctor Jin'Zil, Malaka'jin (south).",v=1},
    {"accept",q=1087,title="Cenarius' Legacy",npc="Braelyn Firehand",z=406,x=45.9,y=60.4,text="Braelyn Firehand.",v=1},
    {"accept",q=6282,title="Harpies Threaten",npc="Maggran Earthbinder",z=406,x=47.2,y=61.2,text="Maggran Earthbinder, Sun Rock Retreat.",v=1},
    {"accept",q=6393,title="Elemental War",npc="Tsunaman",z=406,x=47.4,y=64.2,v=1},
    {"complete",q=6282,title="Harpies Threaten",text="Bloodfury harpies on the ridge east of Sun Rock.",v=1},
    {"complete",q=1058,title="Jin'Zil's Forest Magic",text="Venture Co. operators and Stonetalon creatures.",v=1},
    {"complete",q=1087,title="Cenarius' Legacy",v=1},
    {"turnin",q=1087,title="Cenarius' Legacy",npc="Braelyn Firehand",z=406,x=45.9,y=60.4,v=1},
    {"accept",q=6381,title="New Life",npc="Tammra Windfield",z=406,x=47.5,y=58.4,v=1},
    {"turnin",q=6282,title="Harpies Threaten",npc="Maggran Earthbinder",z=406,x=47.2,y=61.2,v=1},
    {"accept",q=6283,title="Bloodfury Bloodline",npc="Maggran Earthbinder",z=406,x=47.2,y=61.2,v=1},
    {"complete",q=6283,title="Bloodfury Bloodline",v=1},
    {"complete",q=6393,title="Elemental War",v=1},
    {"turnin",q=6283,title="Bloodfury Bloodline",npc="Maggran Earthbinder",z=406,x=47.2,y=61.2,v=1},
    {"turnin",q=6393,title="Elemental War",npc="Tsunaman",z=406,x=47.4,y=64.2,v=1},
    {"complete",q=6381,title="New Life",v=1},
    {"turnin",q=1058,title="Jin'Zil's Forest Magic",npc="Witch Doctor Jin'Zil",z=406,x=74.5,y=97.9,v=1},
    {"turnin",q=6381,title="New Life",npc="Tammra Windfield",z=406,x=47.5,y=58.4,v=1},
    {"level",text="Southern Barrens starts at 25. If you are lower, kill what is around you here (or run a dungeon) until you reach it.",level=25,v=1},
  },
})
