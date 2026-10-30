-- ClassicGuide - compiled guide data. GENERATED from guides-src/horde/14_southernbarrens.guide by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .guide source and rebuild. Guide routes and notes are original ClassicGuide content
-- (GPL-3.0-only); quest ids, NPC names and coordinates were looked up in the bundled QuestieDB-derived data.
local _, ns = ...
ns.Guides:Register({
  id="H_14_SouthernBarrens", name="Southern Barrens (22-23)", faction="Horde", chapter="Azeroth",
  minLevel=22, maxLevel=23, zone=17, zoneName="The Barrens",
  desc="Southern Barrens, visit 3 of 4 on the Horde route, levels 22-23.",
  next={{id="H_15_StonetalonMountains"},},
  steps={
    {"travel",text="Travel to The Barrens",dest="The Barrens",v=1},
    {"train",text="No druid trainer in this zone - train at the next town or capital.",classes={"DRUID"},v=1},
    {"train",text="No hunter trainer in this zone - train at the next town or capital.",classes={"HUNTER"},v=1},
    {"train",text="No mage trainer in this zone - train at the next town or capital.",classes={"MAGE"},v=1},
    {"train",text="No paladin trainer in this zone - train at the next town or capital.",classes={"PALADIN"},v=1},
    {"train",text="No priest trainer in this zone - train at the next town or capital.",classes={"PRIEST"},v=1},
    {"train",text="No rogue trainer in this zone - train at the next town or capital.",classes={"ROGUE"},v=1},
    {"train",text="No shaman trainer in this zone - train at the next town or capital.",classes={"SHAMAN"},v=1},
    {"train",text="No warlock trainer in this zone - train at the next town or capital.",classes={"WARLOCK"},v=1},
    {"train",text="No warrior trainer in this zone - train at the next town or capital.",classes={"WARRIOR"},v=1},
    {"accept",q=893,title="Weapons of Choice",npc="Tatternack Steelforge",z=17,x=45.1,y=57.7,v=1},
    {"complete",q=893,title="Weapons of Choice",v=1},
    {"turnin",q=893,title="Weapons of Choice",npc="Tatternack Steelforge",z=17,x=45.1,y=57.7,v=1},
    {"accept",q=884,title="Owatanka",text="Starts from the item Owatanka's Tailspike.",optional=true,v=1},
    {"turnin",q=884,title="Owatanka",npc="Jorn Skyseer",z=17,x=44.9,y=59.1,optional=true,v=1},
    {"level",text="Stonetalon Mountains starts at 23. If you are lower, kill what is around you here (or run a dungeon) until you reach it.",level=23,v=1},
  },
})
