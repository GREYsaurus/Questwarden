-- Questwarden - compiled guide data. GENERATED from guides-src/horde/28_alteracmountains.guide by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .guide source and rebuild. Guide routes and notes are original Questwarden content
-- (GPL-3.0-only); quest ids, NPC names and coordinates were looked up in the bundled QuestieDB-derived data.
local _, ns = ...
ns.Guides:Register({
  id="H_28_AlteracMountains", name="Alterac Mountains (37)", faction="Horde", chapter="Azeroth",
  minLevel=37, maxLevel=37, zone=36, zoneName="Alterac Mountains",
  desc="Alterac Mountains, visit 1 of 1 on the Horde route, levels 37.",
  next={{id="H_29_ThousandNeedles"},},
  steps={
    {"travel",text="Travel to Alterac Mountains",dest="Alterac Mountains",v=1},
    {"accept",q=535,title="Valik",npc="Henchman Valik",z=36,x=57.2,y=69.5,v=1},
    {"complete",q=535,title="Valik",v=1},
    {"turnin",q=535,title="Valik",npc="Henchman Valik",z=36,x=57.2,y=69.5,v=1},
    {"level",text="Thousand Needles starts at 37. If you are lower, kill what is around you here (or run a dungeon) until you reach it.",level=37,v=1},
  },
})
