-- Questwarden - compiled guide data. GENERATED from guides-src/horde/45_azshara.guide by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .guide source and rebuild. Guide routes and notes are original Questwarden content
-- (GPL-3.0-only); quest ids, NPC names and coordinates were looked up in the bundled QuestieDB-derived data.
local _, ns = ...
ns.Guides:Register({
  id="H_45_Azshara", name="Azshara (50)", faction="Horde", chapter="Azeroth",
  minLevel=50, maxLevel=50, zone=16, zoneName="Azshara",
  desc="Azshara, visit 1 of 2 on the Horde route, levels 50.",
  next={{id="H_46_Hinterlands"},},
  steps={
    {"travel",text="Travel to Azshara",dest="Azshara",v=1},
    {"train",text="No druid trainer in this zone - train at the next town or capital.",classes={"DRUID"},v=1},
    {"train",text="No hunter trainer in this zone - train at the next town or capital.",classes={"HUNTER"},v=1},
    {"train",text="No mage trainer in this zone - train at the next town or capital.",classes={"MAGE"},v=1},
    {"train",text="No paladin trainer in this zone - train at the next town or capital.",classes={"PALADIN"},v=1},
    {"train",text="No priest trainer in this zone - train at the next town or capital.",classes={"PRIEST"},v=1},
    {"train",text="No rogue trainer in this zone - train at the next town or capital.",classes={"ROGUE"},v=1},
    {"train",text="No shaman trainer in this zone - train at the next town or capital.",classes={"SHAMAN"},v=1},
    {"train",text="No warlock trainer in this zone - train at the next town or capital.",classes={"WARLOCK"},v=1},
    {"train",text="No warrior trainer in this zone - train at the next town or capital.",classes={"WARRIOR"},v=1},
    {"accept",q=3517,title="Stealing Knowledge",npc="Jediga",z=16,x=22.6,y=51.4,v=1},
    {"accept",q=5536,title="A Land Filled with Hatred",npc="Loh'atu",z=16,x=11.4,y=78.2,v=1},
    {"accept",q=5535,title="Spiritual Unrest",npc="Loh'atu",z=16,x=11.4,y=78.2,v=1},
    {"complete",q=3517,title="Stealing Knowledge",v=1},
    {"complete",q=5536,title="A Land Filled with Hatred",v=1},
    {"complete",q=5535,title="Spiritual Unrest",v=1},
    {"turnin",q=5536,title="A Land Filled with Hatred",npc="Loh'atu",z=16,x=11.4,y=78.2,v=1},
    {"turnin",q=5535,title="Spiritual Unrest",npc="Loh'atu",z=16,x=11.4,y=78.2,v=1},
    {"turnin",q=3517,title="Stealing Knowledge",npc="Jediga",z=16,x=22.6,y=51.4,v=1},
    {"level",text="The Hinterlands starts at 50. If you are lower, kill what is around you here (or run a dungeon) until you reach it.",level=50,v=1},
  },
})
