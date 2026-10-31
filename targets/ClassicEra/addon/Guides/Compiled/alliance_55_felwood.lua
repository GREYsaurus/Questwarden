-- Questwarden - compiled guide data. GENERATED from guides-src/alliance/55_felwood.guide by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .guide source and rebuild. Guide routes and notes are original Questwarden content
-- (GPL-3.0-only); quest ids, NPC names and coordinates were looked up in the bundled QuestieDB-derived data.
local _, ns = ...
ns.Guides:Register({
  id="A_55_Felwood", name="Felwood (58)", faction="Alliance", chapter="Azeroth",
  minLevel=58, maxLevel=58, zone=361, zoneName="Felwood",
  desc="Felwood, visit 3 of 3 on the Alliance route, levels 58.",
  next={{id="A_56_Azshara"},},
  steps={
    {"travel",text="Travel to Felwood",dest="Felwood",v=1},
    {"train",npc="Golhine the Hooded",z=361,x=61.9,y=24.5,classes={"DRUID"},v=1},
    {"train",npc="Kaerbrus",z=361,x=61.9,y=23.6,classes={"HUNTER"},v=1},
    {"train",text="No mage trainer in this zone - train at the next town or capital.",classes={"MAGE"},v=1},
    {"train",text="No paladin trainer in this zone - train at the next town or capital.",classes={"PALADIN"},v=1},
    {"train",text="No priest trainer in this zone - train at the next town or capital.",classes={"PRIEST"},v=1},
    {"train",text="No rogue trainer in this zone - train at the next town or capital.",classes={"ROGUE"},v=1},
    {"train",text="No shaman trainer in this zone - train at the next town or capital.",classes={"SHAMAN"},v=1},
    {"train",text="No warlock trainer in this zone - train at the next town or capital.",classes={"WARLOCK"},v=1},
    {"train",text="No warrior trainer in this zone - train at the next town or capital.",classes={"WARRIOR"},v=1},
    {"note",text="No quests are written for this visit yet.",v=1},
    {"level",text="Azshara starts at 58. If you are lower, kill what is around you here (or run a dungeon) until you reach it.",level=58,v=1},
  },
})
