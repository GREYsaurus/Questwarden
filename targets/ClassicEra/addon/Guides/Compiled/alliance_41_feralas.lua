-- ClassicGuide - compiled guide data. GENERATED from guides-src/alliance/41_feralas.guide by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .guide source and rebuild. Guide routes and notes are original ClassicGuide content
-- (GPL-3.0-only); quest ids, NPC names and coordinates were looked up in the bundled QuestieDB-derived data.
local _, ns = ...
ns.Guides:Register({
  id="A_41_Feralas", name="Feralas (48-49)", faction="Alliance", chapter="Azeroth",
  minLevel=48, maxLevel=49, zone=357, zoneName="Feralas",
  desc="Feralas, visit 2 of 2 on the Alliance route, levels 48-49.",
  next={{id="A_42_DustwallowMarsh"},},
  steps={
    {"travel",text="Travel to Feralas",dest="Feralas",v=1},
    {"train",text="No druid trainer in this zone - train at the next town or capital.",classes={"DRUID"},v=1},
    {"train",text="No hunter trainer in this zone - train at the next town or capital.",classes={"HUNTER"},v=1},
    {"train",text="No mage trainer in this zone - train at the next town or capital.",classes={"MAGE"},v=1},
    {"train",text="No paladin trainer in this zone - train at the next town or capital.",classes={"PALADIN"},v=1},
    {"train",text="No priest trainer in this zone - train at the next town or capital.",classes={"PRIEST"},v=1},
    {"train",text="No rogue trainer in this zone - train at the next town or capital.",classes={"ROGUE"},v=1},
    {"train",text="No shaman trainer in this zone - train at the next town or capital.",classes={"SHAMAN"},v=1},
    {"train",text="No warlock trainer in this zone - train at the next town or capital.",classes={"WARLOCK"},v=1},
    {"train",text="No warrior trainer in this zone - train at the next town or capital.",classes={"WARRIOR"},v=1},
    {"accept",q=2844,title="The Giant Guardian",npc="Rockbiter",z=357,x=42.4,y=22,text="Rockbiter at the Twin Colossals.",v=1},
    {"turnin",q=2844,title="The Giant Guardian",npc="Shay Leafrunner",z=357,x=38.2,y=10.3,v=1},
    {"level",text="Dustwallow Marsh starts at 49. If you are lower, kill what is around you here (or run a dungeon) until you reach it.",level=49,v=1},
  },
})
