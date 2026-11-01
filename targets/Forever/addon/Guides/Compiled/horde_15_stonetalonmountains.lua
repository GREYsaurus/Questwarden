-- Questwarden - compiled guide data. GENERATED from guides-src/horde/15_stonetalonmountains.guide by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .guide source and rebuild. Guide routes and notes are original Questwarden content
-- (GPL-3.0-only); quest ids, NPC names and coordinates were looked up in the bundled QuestieDB-derived data.
local _, ns = ...
ns.Guides:Register({
  id="H_15_StonetalonMountains", name="Stonetalon Mountains (23-25)", faction="Horde", chapter="Azeroth",
  minLevel=23, maxLevel=25, zone=406, zoneName="Stonetalon Mountains",
  desc="Stonetalon Mountains, visit 3 of 4 on the Horde route, levels 23-25.",
  next={{id="H_16_SouthernBarrens"},},
  steps={
    {"fly",text="Take the flight from Ratchet.",dest="Sun Rock Retreat",node=29,v=1},
    {"travel",text="Travel to Stonetalon Mountains",dest="Stonetalon Mountains",v=1},
    {"accept",q=1087,title="Cenarius' Legacy",npc="Braelyn Firehand",z=406,x=45.9,y=60.4,text="Braelyn Firehand.",v=1},
    {"accept",q=5881,title="Calling in the Reserves",npc="Maggran Earthbinder",z=406,x=47.2,y=61.2,v=1},
    {"accept",q=6393,title="Elemental War",npc="Tsunaman",z=406,x=47.4,y=64.2,v=1},
    {"complete",q=1087,title="Cenarius' Legacy",v=1},
    {"turnin",q=1087,title="Cenarius' Legacy",npc="Braelyn Firehand",z=406,x=45.9,y=60.4,v=1},
    {"accept",q=6381,title="New Life",npc="Tammra Windfield",z=406,x=47.5,y=58.4,v=1},
    {"complete",q=6393,title="Elemental War",v=1},
    {"complete",q=6381,title="New Life",v=1},
    {"turnin",q=6393,title="Elemental War",npc="Tsunaman",z=406,x=47.4,y=64.2,v=1},
    {"turnin",q=6381,title="New Life",npc="Tammra Windfield",z=406,x=47.5,y=58.4,v=1},
    {"note",text=" - The next quest, Vorsha the Lasher, is an escort: pick it up only when you are ready to follow the NPC.",classes={"SHAMAN"},races={"Orc","Tauren","Troll"},v=1},
    {"accept",q=6641,title="Vorsha the Lasher",npc="Muglash",z=331,x=12.1,y=34.6,text="Escort quest: start it when you are ready to follow.",classes={"SHAMAN"},races={"Orc","Tauren","Troll"},v=1},
    {"complete",q=6641,title="Vorsha the Lasher",text="Escort: stay close; it fails if the NPC dies.",classes={"SHAMAN"},races={"Orc","Tauren","Troll"},v=1},
    {"turnin",q=6641,title="Vorsha the Lasher",npc="Warsong Runner",z=331,x=12.2,y=34.2,text="Turned in at Ashenvale.",classes={"SHAMAN"},races={"Orc","Tauren","Troll"},v=1},
    {"level",text="Southern Barrens starts at 25. If you are lower, kill what is around you here (or run a dungeon) until you reach it.",level=25,v=1},
  },
})
