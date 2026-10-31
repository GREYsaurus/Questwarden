-- ClassicGuide - compiled guide data. GENERATED from guides-src/horde/23_stranglethornvale.guide by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .guide source and rebuild. Guide routes and notes are original ClassicGuide content
-- (GPL-3.0-only); quest ids, NPC names and coordinates were looked up in the bundled QuestieDB-derived data.
local _, ns = ...
ns.Guides:Register({
  id="H_23_StranglethornVale", name="Stranglethorn Vale (30-31)", faction="Horde", chapter="Azeroth",
  minLevel=30, maxLevel=31, zone=33, zoneName="Stranglethorn Vale",
  desc="Stranglethorn Vale, visit 1 of 5 on the Horde route, levels 30-31.",
  next={{id="H_24_ShimmeringFlats"},},
  steps={
    {"travel",text="Travel to Stranglethorn Vale",dest="Stranglethorn Vale",v=1},
    {"train",text="No druid trainer in this zone - train at the next town or capital.",classes={"DRUID"},v=1},
    {"train",npc="Kragg",z=33,x=31.2,y=28.7,classes={"HUNTER"},v=1},
    {"train",text="No mage trainer in this zone - train at the next town or capital.",classes={"MAGE"},v=1},
    {"train",text="No paladin trainer in this zone - train at the next town or capital.",classes={"PALADIN"},v=1},
    {"train",text="No priest trainer in this zone - train at the next town or capital.",classes={"PRIEST"},v=1},
    {"train",npc="Ian Strom",z=33,x=26.8,y=77.2,classes={"ROGUE"},v=1},
    {"train",text="No shaman trainer in this zone - train at the next town or capital.",classes={"SHAMAN"},v=1},
    {"train",text="No warlock trainer in this zone - train at the next town or capital.",classes={"WARLOCK"},v=1},
    {"train",text="No warrior trainer in this zone - train at the next town or capital.",classes={"WARRIOR"},v=1},
    {"accept",q=583,title="Welcome to the Jungle",npc="Barnil Stonepot",z=33,x=35.7,y=10.5,text="Barnil Stonepot, Nesingwary's Expedition.",v=1},
    {"turnin",q=583,title="Welcome to the Jungle",npc="Hemet Nesingwary",z=33,x=35.7,y=10.8,v=1},
    {"accept",q=185,title="Tiger Mastery",npc="Ajeck Rouack",z=33,x=35.6,y=10.6,v=1},
    {"accept",q=190,title="Panther Mastery",npc="Sir S. J. Erlgadin",z=33,x=35.6,y=10.6,v=1},
    {"complete",q=185,title="Tiger Mastery",v=1},
    {"complete",q=190,title="Panther Mastery",v=1},
    {"turnin",q=185,title="Tiger Mastery",npc="Ajeck Rouack",z=33,x=35.6,y=10.6,v=1},
    {"accept",q=186,title="Tiger Mastery",npc="Ajeck Rouack",z=33,x=35.6,y=10.6,v=1},
    {"turnin",q=190,title="Panther Mastery",npc="Sir S. J. Erlgadin",z=33,x=35.6,y=10.6,v=1},
    {"complete",q=186,title="Tiger Mastery",v=1},
    {"turnin",q=186,title="Tiger Mastery",npc="Ajeck Rouack",z=33,x=35.6,y=10.6,v=1},
    {"accept",q=201,title="Investigate the Camp",npc="Krazek",z=33,x=26.9,y=77.2,v=1},
    {"turnin",q=201,title="Investigate the Camp",npc="Krazek",z=33,x=26.9,y=77.2,v=1},
    {"accept",q=575,title="Supply and Demand",npc="Drizzlik",z=33,x=28.3,y=77.6,text="Drizzlik, Booty Bay.",v=1},
    {"complete",q=575,title="Supply and Demand",text="Large River Crocolisk Skin drops from River Crocolisk.",v=1},
    {"turnin",q=575,title="Supply and Demand",npc="Drizzlik",z=33,x=28.3,y=77.6,v=1},
    {"level",text="Shimmering Flats starts at 31. If you are lower, kill what is around you here (or run a dungeon) until you reach it.",level=31,v=1},
  },
})
