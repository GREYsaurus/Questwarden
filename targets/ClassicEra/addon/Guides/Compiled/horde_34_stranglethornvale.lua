-- ClassicGuide - compiled guide data. GENERATED from guides-src/horde/34_stranglethornvale.guide by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .guide source and rebuild. Guide routes and notes are original ClassicGuide content
-- (GPL-3.0-only); quest ids, NPC names and coordinates were looked up in the bundled QuestieDB-derived data.
local _, ns = ...
ns.Guides:Register({
  id="H_34_StranglethornVale", name="Stranglethorn Vale (42-43)", faction="Horde", chapter="Azeroth",
  minLevel=42, maxLevel=43, zone=33, zoneName="Stranglethorn Vale",
  desc="Stranglethorn Vale, visit 4 of 5 on the Horde route, levels 42-43.",
  next={{id="H_35_DustwallowMarsh"},},
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
    {"accept",q=621,title="Zanzil's Secret",npc="Crank Fizzlebub",z=33,x=27.1,y=77.2,v=1},
    {"accept",q=617,title="Akiris by the Bundle",npc="Privateer Bloads",z=33,x=26.8,y=76.4,v=1},
    {"complete",q=621,title="Zanzil's Secret",v=1},
    {"complete",q=617,title="Akiris by the Bundle",v=1},
    {"accept",q=609,title="Voodoo Dues",npc="\"Sea Wolf\" MacKinley",z=33,x=27.8,y=77.1,v=1},
    {"turnin",q=621,title="Zanzil's Secret",npc="Crank Fizzlebub",z=33,x=27.1,y=77.2,v=1},
    {"turnin",q=617,title="Akiris by the Bundle",npc="Privateer Bloads",z=33,x=26.8,y=76.4,v=1},
    {"complete",q=609,title="Voodoo Dues",v=1},
    {"turnin",q=609,title="Voodoo Dues",npc="\"Sea Wolf\" MacKinley",z=33,x=27.8,y=77.1,v=1},
    {"accept",q=573,title="Mok'thardin's Enchantment",npc="Far Seer Mok'thardin",z=33,x=32.1,y=29.2,v=1},
    {"complete",q=573,title="Mok'thardin's Enchantment",v=1},
    {"turnin",q=573,title="Mok'thardin's Enchantment",npc="Far Seer Mok'thardin",z=33,x=32.1,y=29.2,v=1},
    {"level",text="Dustwallow Marsh starts at 43. If you are lower, kill what is around you here (or run a dungeon) until you reach it.",level=43,v=1},
  },
})
