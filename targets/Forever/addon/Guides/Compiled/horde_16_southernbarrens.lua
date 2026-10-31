-- Questwarden - compiled guide data. GENERATED from guides-src/horde/16_southernbarrens.guide by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .guide source and rebuild. Guide routes and notes are original Questwarden content
-- (GPL-3.0-only); quest ids, NPC names and coordinates were looked up in the bundled QuestieDB-derived data.
local _, ns = ...
ns.Guides:Register({
  id="H_16_SouthernBarrens", name="Southern Barrens (25)", faction="Horde", chapter="Azeroth",
  minLevel=25, maxLevel=25, zone=17, zoneName="The Barrens",
  desc="Southern Barrens, visit 4 of 4 on the Horde route, levels 25.",
  next={{id="H_17_ThousandNeedles"},},
  steps={
    {"travel",text="Travel to The Barrens",dest="The Barrens",v=1},
    {"accept",q=874,title="Mahren Skyseer",npc="Jorn Skyseer",z=17,x=44.9,y=59.1,optional=true,v=1},
    {"accept",q=1095,title="Further Instructions",npc="Sputtervalve",z=17,x=63,y=37.2,v=1},
    {"accept",q=1131,title="Steelsnap",npc="Melor Stonehoof",z=1638,x=61.5,y=80.9,text="Needs level 20. If you are lower, {name} skips it and moves on.",v=1},
    {"accept",q=893,title="Weapons of Choice",npc="Tatternack Steelforge",z=17,x=45.1,y=57.7,v=1},
    {"complete",q=893,title="Weapons of Choice",v=1},
    {"turnin",q=893,title="Weapons of Choice",npc="Tatternack Steelforge",z=17,x=45.1,y=57.7,v=1},
    {"accept",q=884,title="Owatanka",text="Starts from the item Owatanka's Tailspike.",optional=true,v=1},
    {"turnin",q=884,title="Owatanka",npc="Jorn Skyseer",z=17,x=44.9,y=59.1,optional=true,v=1},
    {"level",text="Thousand Needles starts at 25. If you are lower, kill what is around you here (or run a dungeon) until you reach it.",level=25,v=1},
  },
})
