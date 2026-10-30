-- ClassicGuide - compiled guide data. GENERATED from guides-src/alliance/15_darkshore.guide by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .guide source and rebuild. Guide routes and notes are original ClassicGuide content
-- (GPL-3.0-only); quest ids, NPC names and coordinates were looked up in the bundled QuestieDB-derived data.
local _, ns = ...
ns.Guides:Register({
  id="A_15_Darkshore", name="Darkshore (23-24)", faction="Alliance", chapter="Azeroth",
  minLevel=23, maxLevel=24, zone=148, zoneName="Darkshore",
  desc="Darkshore, visit 3 of 3 on the Alliance route, levels 23-24.",
  next={{id="A_16_Ashenvale"},},
  steps={
    {"travel",text="Travel to Darkshore",dest="Darkshore",v=1},
    {"note",text="No quests are written for this visit yet.",v=1},
    {"level",text="Ashenvale starts at 24. If you are lower, kill what is around you here (or run a dungeon) until you reach it.",level=24,v=1},
  },
})
