-- Questwarden - compiled guide data. GENERATED from guides-src/horde/19_stonetalonmountains.guide by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .guide source and rebuild. Guide routes and notes are original Questwarden content
-- (GPL-3.0-only); quest ids, NPC names and coordinates were looked up in the bundled QuestieDB-derived data.
local _, ns = ...
ns.Guides:Register({
  id="H_19_StonetalonMountains", name="Stonetalon Mountains (27-28)", faction="Horde", chapter="Azeroth",
  minLevel=27, maxLevel=28, zone=406, zoneName="Stonetalon Mountains",
  desc="Stonetalon Mountains, visit 4 of 4 on the Horde route, levels 27-28.",
  next={{id="H_20_ThousandNeedles"},},
  steps={
    {"fly",text="Take the flight from Splintertree Post.",dest="Sun Rock Retreat",node=29,v=1},
    {"travel",text="Travel to Stonetalon Mountains",dest="Stonetalon Mountains",v=1},
    {"turnin",q=1095,title="Further Instructions",npc="Ziz Fizziks",z=406,x=59,y=62.6,v=1},
    {"accept",q=1096,title="Gerenzo Wrenchwhistle",npc="Ziz Fizziks",z=406,x=59,y=62.6,v=1},
    {"complete",q=1096,title="Gerenzo Wrenchwhistle",v=1},
    {"accept",q=1088,title="Ordanus",npc="Braelyn Firehand",z=406,x=45.9,y=60.4,v=1},
    {"complete",q=1088,title="Ordanus",text="Ordanus is in the Sons of Cenarius camp.",v=1},
    {"turnin",q=1088,title="Ordanus",npc="Braelyn Firehand",z=406,x=45.9,y=60.4,v=1},
    {"turnin",q=1096,title="Gerenzo Wrenchwhistle",npc="Ziz Fizziks",z=406,x=59,y=62.6,v=1},
    {"accept",q=1089,title="The Den",npc="Braelyn Firehand",z=406,x=45.9,y=60.4,v=1},
    {"complete",q=1089,title="The Den",v=1},
    {"turnin",q=1089,title="The Den",npc="Talon Den Hoard",z=406,x=26.6,y=10.9,v=1},
    {"accept",q=1058,title="Jin'Zil's Forest Magic",npc="Witch Doctor Jin'Zil",z=406,x=74.5,y=97.9,text="Witch Doctor Jin'Zil, Malaka'jin (south).",v=1},
    {"complete",q=1058,title="Jin'Zil's Forest Magic",text="Venture Co. operators and Stonetalon creatures.",v=1},
    {"turnin",q=1058,title="Jin'Zil's Forest Magic",npc="Witch Doctor Jin'Zil",z=406,x=74.5,y=97.9,v=1},
    {"accept",q=6282,title="Harpies Threaten",npc="Maggran Earthbinder",z=406,x=47.2,y=61.2,text="Maggran Earthbinder, Sun Rock Retreat.",v=1},
    {"complete",q=6282,title="Harpies Threaten",text="Bloodfury harpies on the ridge east of Sun Rock.",v=1},
    {"turnin",q=6282,title="Harpies Threaten",npc="Maggran Earthbinder",z=406,x=47.2,y=61.2,v=1},
    {"accept",q=6283,title="Bloodfury Bloodline",npc="Maggran Earthbinder",z=406,x=47.2,y=61.2,v=1},
    {"complete",q=6283,title="Bloodfury Bloodline",v=1},
    {"turnin",q=6283,title="Bloodfury Bloodline",npc="Maggran Earthbinder",z=406,x=47.2,y=61.2,v=1},
    {"level",text="Thousand Needles starts at 28. If you are lower, kill what is around you here (or run a dungeon) until you reach it.",level=28,v=1},
  },
})
