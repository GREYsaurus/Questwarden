-- ClassicGuide - compiled guide data. GENERATED from guides-src/horde/29_thousandneedles.guide by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .guide source and rebuild. Guide routes and notes are original ClassicGuide content
-- (GPL-3.0-only); quest ids, NPC names and coordinates were looked up in the bundled QuestieDB-derived data.
local _, ns = ...
ns.Guides:Register({
  id="H_29_ThousandNeedles", name="Thousand Needles (37-38)", faction="Horde", chapter="Azeroth",
  minLevel=37, maxLevel=38, zone=400, zoneName="Thousand Needles",
  desc="Thousand Needles, visit 4 of 4 on the Horde route, levels 37-38.",
  next={{id="H_30_DustwallowMarsh"},},
  steps={
    {"travel",text="Travel to Thousand Needles",dest="Thousand Needles",v=1},
    {"accept",q=1049,title="Compendium of the Fallen",npc="Sage Truthseeker",z=1638,x=34.4,y=46.9,dungeon="Scarlet Monastery",v=1},
    {"complete",q=1049,title="Compendium of the Fallen",dungeon="Scarlet Monastery",v=1},
    {"turnin",q=1049,title="Compendium of the Fallen",npc="Sage Truthseeker",z=1638,x=34.4,y=46.9,dungeon="Scarlet Monastery",v=1},
    {"accept",q=1111,title="Wharfmaster Dizzywig",npc="Kravel Koalbeard",z=400,x=77.8,y=77.3,v=1},
    {"turnin",q=1111,title="Wharfmaster Dizzywig",npc="Wharfmaster Dizzywig",z=17,x=63.4,y=38.4,text="Turned in at The Barrens.",v=1},
    {"accept",q=5361,title="Family Tree",npc="Cliffwatcher Longhorn",z=400,x=45.7,y=50.7,v=1},
    {"level",text="Dustwallow Marsh starts at 38. If you are lower, kill what is around you here (or run a dungeon) until you reach it.",level=38,v=1},
  },
})
