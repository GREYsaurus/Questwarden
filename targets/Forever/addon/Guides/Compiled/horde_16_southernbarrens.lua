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
    {"turnin",q=3514,title="Horde Presence",npc="Kadrak",z=17,x=48.1,y=5.4,optional=true,v=1},
    {"turnin",q=1221,title="Blueleaf Tubers",npc="Mebok Mizzyrix",z=17,x=62.4,y=37.6,optional=true,v=1},
    {"accept",q=1131,title="Steelsnap",npc="Melor Stonehoof",z=1638,x=61.5,y=80.9,text="Needs level 20. If you are lower, {name} skips it and moves on.",v=1},
    {"accept",q=893,title="Weapons of Choice",npc="Tatternack Steelforge",z=17,x=45.1,y=57.7,v=1},
    {"complete",q=893,title="Weapons of Choice",v=1},
    {"turnin",q=893,title="Weapons of Choice",npc="Tatternack Steelforge",z=17,x=45.1,y=57.7,v=1},
    {"accept",q=884,title="Owatanka",text="Starts from the item Owatanka's Tailspike.",optional=true,starter=5102,drops={3473},v=1},
    {"turnin",q=884,title="Owatanka",npc="Jorn Skyseer",z=17,x=44.9,y=59.1,optional=true,v=1},
    {"complete",q=2478,title="Mission: Possible But Not Probable",text="At the Venture Co. tower north of the Sludge Fen: steal Silixiz's Tower Key from Foreman Silixiz, kill two each of the drones, patrollers and lookouts, and kill Grand Foreman Puzik Gallywix.",classes={"ROGUE"},v=1},
    {"turnin",q=2478,title="Mission: Possible But Not Probable",npc="Shenthul",z=1637,x=43,y=53.7,text="Shenthul, Cleft of Shadow, Orgrimmar.",classes={"ROGUE"},v=1},
    {"accept",q=2479,title="Hinott's Assistance",npc="Shenthul",z=1637,x=43,y=53.7,text="Serge Hinott is in Tarren Mill; the guide gets there at 29.",classes={"ROGUE"},v=1},
    {"level",text="Thousand Needles starts at 25. If you are lower, kill what is around you here (or run a dungeon) until you reach it.",level=25,v=1},
  },
})
