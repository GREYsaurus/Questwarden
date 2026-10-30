-- ClassicGuide - compiled guide data. GENERATED from guides-src/alliance/39_stranglethornvale.guide by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .guide source and rebuild. Guide routes and notes are original ClassicGuide content
-- (GPL-3.0-only); quest ids, NPC names and coordinates were looked up in the bundled QuestieDB-derived data.
local _, ns = ...
ns.Guides:Register({
  id="A_39_StranglethornVale", name="Stranglethorn Vale (46-47)", faction="Alliance", chapter="Azeroth",
  minLevel=46, maxLevel=47, zone=33, zoneName="Stranglethorn Vale",
  desc="Stranglethorn Vale, visit 5 of 5 on the Alliance route, levels 46-47.",
  next={{id="A_40_SearingGorge"},},
  steps={
    {"travel",text="Travel to Stranglethorn Vale",dest="Stranglethorn Vale",v=1},
    {"train",text="No druid trainer in this zone - train at the next town or capital.",classes={"DRUID"},v=1},
    {"train",text="No hunter trainer in this zone - train at the next town or capital.",classes={"HUNTER"},v=1},
    {"train",text="No mage trainer in this zone - train at the next town or capital.",classes={"MAGE"},v=1},
    {"train",text="No paladin trainer in this zone - train at the next town or capital.",classes={"PALADIN"},v=1},
    {"train",text="No priest trainer in this zone - train at the next town or capital.",classes={"PRIEST"},v=1},
    {"train",npc="Ian Strom",z=33,x=26.8,y=77.2,classes={"ROGUE"},v=1},
    {"train",text="No shaman trainer in this zone - train at the next town or capital.",classes={"SHAMAN"},v=1},
    {"train",text="No warlock trainer in this zone - train at the next town or capital.",classes={"WARLOCK"},v=1},
    {"train",text="No warrior trainer in this zone - train at the next town or capital.",classes={"WARRIOR"},v=1},
    {"accept",q=8551,title="The Captain's Chest",npc="Captain Hecklebury Smotts",z=33,x=26.7,y=73.6,hcSkip=true,elite=true,group=true,v=1},
    {"complete",q=8551,title="The Captain's Chest",hcSkip=true,elite=true,group=true,v=1},
    {"turnin",q=8551,title="The Captain's Chest",npc="Captain Hecklebury Smotts",z=33,x=26.7,y=73.6,hcSkip=true,elite=true,group=true,v=1},
    {"accept",q=608,title="The Bloodsail Buccaneers",npc="Fleet Master Seahorn",z=33,x=27.2,y=77,v=1},
    {"complete",q=608,title="The Bloodsail Buccaneers",v=1},
    {"turnin",q=608,title="The Bloodsail Buccaneers",npc="Fleet Master Seahorn",z=33,x=27.2,y=77,v=1},
    {"level",text="Searing Gorge starts at 47. If you are lower, kill what is around you here (or run a dungeon) until you reach it.",level=47,v=1},
  },
})
