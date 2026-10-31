-- ClassicGuide - compiled guide data. GENERATED from guides-src/horde/43_dustwallowmarsh.guide by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .guide source and rebuild. Guide routes and notes are original ClassicGuide content
-- (GPL-3.0-only); quest ids, NPC names and coordinates were looked up in the bundled QuestieDB-derived data.
local _, ns = ...
ns.Guides:Register({
  id="H_43_DustwallowMarsh", name="Dustwallow Marsh (49)", faction="Horde", chapter="Azeroth",
  minLevel=49, maxLevel=49, zone=15, zoneName="Dustwallow Marsh",
  desc="Dustwallow Marsh, visit 3 of 3 on the Horde route, levels 49.",
  next={{id="H_44_Tanaris"},},
  steps={
    {"travel",text="Travel to Dustwallow Marsh",dest="Dustwallow Marsh",v=1},
    {"note",text="No quests are written for this visit yet.",v=1},
    {"level",text="Tanaris starts at 49. If you are lower, kill what is around you here (or run a dungeon) until you reach it.",level=49,v=1},
  },
})
