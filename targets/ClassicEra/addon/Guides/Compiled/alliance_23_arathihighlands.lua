-- Questwarden - compiled guide data. GENERATED from guides-src/alliance/23_arathihighlands.guide by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .guide source and rebuild. Guide routes and notes are original Questwarden content
-- (GPL-3.0-only); quest ids, NPC names and coordinates were looked up in the bundled QuestieDB-derived data.
local _, ns = ...
ns.Guides:Register({
  id="A_23_ArathiHighlands", name="Arathi Highlands (32)", faction="Alliance", chapter="Azeroth",
  minLevel=32, maxLevel=32, zone=45, zoneName="Arathi Highlands",
  desc="Arathi Highlands, visit 1 of 2 on the Alliance route, levels 32.",
  next={{id="A_24_StranglethornVale"},},
  steps={
    {"travel",text="Travel to Arathi Highlands",dest="Arathi Highlands",v=1},
    {"train",text="No druid trainer in this zone - train at the next town or capital.",classes={"DRUID"},v=1},
    {"train",text="No hunter trainer in this zone - train at the next town or capital.",classes={"HUNTER"},v=1},
    {"train",text="No mage trainer in this zone - train at the next town or capital.",classes={"MAGE"},v=1},
    {"train",text="No paladin trainer in this zone - train at the next town or capital.",classes={"PALADIN"},v=1},
    {"train",text="No priest trainer in this zone - train at the next town or capital.",classes={"PRIEST"},v=1},
    {"train",text="No rogue trainer in this zone - train at the next town or capital.",classes={"ROGUE"},v=1},
    {"train",text="No shaman trainer in this zone - train at the next town or capital.",classes={"SHAMAN"},v=1},
    {"train",text="No warlock trainer in this zone - train at the next town or capital.",classes={"WARLOCK"},v=1},
    {"train",text="No warrior trainer in this zone - train at the next town or capital.",classes={"WARRIOR"},v=1},
    {"accept",q=681,title="Northfold Manor",npc="Captain Nials",z=45,x=45.8,y=47.6,text="Captain Nials, Refuge Pointe.",v=1},
    {"complete",q=681,title="Northfold Manor",text="Syndicate at Northfold Manor, north-west.",v=1},
    {"turnin",q=681,title="Northfold Manor",npc="Captain Nials",z=45,x=45.8,y=47.6,v=1},
    {"level",text="Stranglethorn Vale starts at 32. If you are lower, kill what is around you here (or run a dungeon) until you reach it.",level=32,v=1},
  },
})
