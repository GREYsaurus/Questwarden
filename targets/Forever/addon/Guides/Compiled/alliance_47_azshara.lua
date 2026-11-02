-- Questwarden - compiled guide data. GENERATED from guides-src/alliance/47_azshara.guide by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .guide source and rebuild. Guide routes and notes are original Questwarden content
-- (GPL-3.0-only); quest ids, NPC names and coordinates were looked up in the bundled QuestieDB-derived data.
local _, ns = ...
ns.Guides:Register({
  id="A_47_Azshara", name="Azshara (52-53)", faction="Alliance", chapter="Azeroth",
  minLevel=52, maxLevel=53, zone=16, zoneName="Azshara",
  desc="Azshara, visit 2 of 3 on the Alliance route, levels 52-53.",
  next={{id="A_48_Felwood"},},
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
    {"accept",q=3601,title="Kim'jael Indeed!",npc="Kim'jael",z=16,x=53.4,y=21.8,v=1},
    {"complete",q=3601,title="Kim'jael Indeed!",v=1},
    {"turnin",q=3601,title="Kim'jael Indeed!",npc="Kim'jael",z=16,x=53.4,y=21.8,v=1},
    {"accept",q=5534,title="Kim'jael's \"Missing\" Equipment",npc="Kim'jael",z=16,x=53.4,y=21.8,v=1},
    {"complete",q=5534,title="Kim'jael's \"Missing\" Equipment",v=1},
    {"turnin",q=5534,title="Kim'jael's \"Missing\" Equipment",npc="Kim'jael",z=16,x=53.4,y=21.8,v=1},
    {"grind",z=16,x=58.1,y=27,text="Felwood starts at 53 and the quests here don't quite get you there: grind these until you reach it.",level=53,mobs={"Blood Elf Reclaimer","Blood Elf Surveyor","Legashi Satyr"},v=0},
  },
})
