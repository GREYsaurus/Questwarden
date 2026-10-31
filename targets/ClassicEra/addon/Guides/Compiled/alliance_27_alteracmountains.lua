-- Questwarden - compiled guide data. GENERATED from guides-src/alliance/27_alteracmountains.guide by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .guide source and rebuild. Guide routes and notes are original Questwarden content
-- (GPL-3.0-only); quest ids, NPC names and coordinates were looked up in the bundled QuestieDB-derived data.
local _, ns = ...
ns.Guides:Register({
  id="A_27_AlteracMountains", name="Alterac Mountains (37)", faction="Alliance", chapter="Azeroth",
  minLevel=37, maxLevel=37, zone=36, zoneName="Alterac Mountains",
  desc="Alterac Mountains, visit 1 of 1 on the Alliance route, levels 37.",
  next={{id="A_28_ArathiHighlands"},},
  steps={
    {"travel",text="Travel to Alterac Mountains",dest="Alterac Mountains",v=1},
    {"note",text="No quests are written for this visit yet.",v=1},
    {"level",text="Arathi Highlands starts at 37. If you are lower, kill what is around you here (or run a dungeon) until you reach it.",level=37,v=1},
  },
})
