-- ClassicGuide - compiled guide data. GENERATED from guides-src/alliance/16_ashenvale.guide by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .guide source and rebuild. Guide routes and notes are original ClassicGuide content
-- (GPL-3.0-only); quest ids, NPC names and coordinates were looked up in the bundled QuestieDB-derived data.
local _, ns = ...
ns.Guides:Register({
  id="A_16_Ashenvale", name="Ashenvale (24)", faction="Alliance", chapter="Azeroth",
  minLevel=24, maxLevel=24, zone=331, zoneName="Ashenvale",
  desc="Ashenvale, visit 2 of 3 on the Alliance route, levels 24.",
  next={{id="A_17_Wetlands"},},
  steps={
    {"travel",text="Travel to Ashenvale",dest="Ashenvale",v=1},
    {"train",text="No druid trainer in this zone - train at the next town or capital.",classes={"DRUID"},v=1},
    {"train",npc="Danlaar Nightstride",z=331,x=50.1,y=68,classes={"HUNTER"},v=1},
    {"train",text="No mage trainer in this zone - train at the next town or capital.",classes={"MAGE"},v=1},
    {"train",text="No paladin trainer in this zone - train at the next town or capital.",classes={"PALADIN"},v=1},
    {"train",text="No priest trainer in this zone - train at the next town or capital.",classes={"PRIEST"},v=1},
    {"train",text="No rogue trainer in this zone - train at the next town or capital.",classes={"ROGUE"},v=1},
    {"train",text="No shaman trainer in this zone - train at the next town or capital.",classes={"SHAMAN"},v=1},
    {"train",text="No warlock trainer in this zone - train at the next town or capital.",classes={"WARLOCK"},v=1},
    {"train",text="No warrior trainer in this zone - train at the next town or capital.",classes={"WARRIOR"},v=1},
    {"accept",q=1009,title="Ruuzel",npc="Talen",z=331,x=14.8,y=31.3,v=1},
    {"accept",q=1054,title="Culling the Threat",npc="Raene Wolfrunner",z=331,x=36.6,y=49.6,v=1},
    {"complete",q=1009,title="Ruuzel",text="Ruuzel patrols the island off the strand.",group=2,v=1},
    {"turnin",q=1009,title="Ruuzel",npc="Talen",z=331,x=14.8,y=31.3,v=1},
    {"complete",q=1054,title="Culling the Threat",v=1},
    {"turnin",q=1054,title="Culling the Threat",npc="Raene Wolfrunner",z=331,x=36.6,y=49.6,v=1},
    {"accept",q=1017,title="Mage Summoner",npc="Sentinel Velene Starstrike",z=331,x=49.8,y=67.2,v=1},
    {"complete",q=1017,title="Mage Summoner",text="Sarilus Foulborne camps beside Mystral Lake.",v=1},
    {"turnin",q=1017,title="Mage Summoner",npc="Sentinel Velene Starstrike",z=331,x=49.8,y=67.2,v=1},
    {"level",text="Wetlands starts at 24. If you are lower, kill what is around you here (or run a dungeon) until you reach it.",level=24,v=1},
  },
})
