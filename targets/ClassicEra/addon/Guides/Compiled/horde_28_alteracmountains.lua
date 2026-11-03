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
    {"complete",q=63,title="Call of Water",text="Silverpine Forest: kill the Corrupt Minor Manifestation of Water for its bracers.",classes={"SHAMAN"},v=1},
    {"turnin",q=63,title="Call of Water",npc="Brazier of Everfount",z=130,x=38.3,y=44.6,text="Place the bracers and the Remaining Drops of Purest Water on the Brazier of Everfount, right beside it.",classes={"SHAMAN"},v=1},
    {"accept",q=100,title="Call of Water",npc="Brazier of Everfount",z=130,x=38.3,y=44.6,text="From the Brazier of Everfount.",classes={"SHAMAN"},v=1},
    {"turnin",q=100,title="Call of Water",npc="Minor Manifestation of Water",text="Talk to the Minor Manifestation of Water.",classes={"SHAMAN"},v=1},
    {"accept",q=96,title="Call of Water",npc="Minor Manifestation of Water",text="Islen Waterseer is in the Barrens; the guide gets there next.",classes={"SHAMAN"},v=1},
    {"level",text="Thousand Needles starts at 37. If you are lower, kill what is around you here (or run a dungeon) until you reach it.",level=37,v=1},
  },
})
