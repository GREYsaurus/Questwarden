-- Questwarden - compiled guide data. GENERATED from guides-src/alliance/44_hinterlands.guide by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .guide source and rebuild. Guide routes and notes are original Questwarden content
-- (GPL-3.0-only); quest ids, NPC names and coordinates were looked up in the bundled QuestieDB-derived data.
local _, ns = ...
ns.Guides:Register({
  id="A_44_Hinterlands", name="The Hinterlands (50)", faction="Alliance", chapter="Azeroth",
  minLevel=50, maxLevel=50, zone=47, zoneName="The Hinterlands",
  desc="The Hinterlands, visit 2 of 2 on the Alliance route, levels 50.",
  next={{id="A_45_BlastedLands"},},
  steps={
    {"travel",text="Travel to The Hinterlands",dest="The Hinterlands",v=1},
    {"train",text="No druid trainer in this zone - train at the next town or capital.",classes={"DRUID"},v=1},
    {"train",text="No hunter trainer in this zone - train at the next town or capital.",classes={"HUNTER"},v=1},
    {"train",text="No mage trainer in this zone - train at the next town or capital.",classes={"MAGE"},v=1},
    {"train",text="No paladin trainer in this zone - train at the next town or capital.",classes={"PALADIN"},v=1},
    {"train",text="No priest trainer in this zone - train at the next town or capital.",classes={"PRIEST"},v=1},
    {"train",text="No rogue trainer in this zone - train at the next town or capital.",classes={"ROGUE"},v=1},
    {"train",text="No shaman trainer in this zone - train at the next town or capital.",classes={"SHAMAN"},v=1},
    {"train",text="No warlock trainer in this zone - train at the next town or capital.",classes={"WARLOCK"},v=1},
    {"train",text="No warrior trainer in this zone - train at the next town or capital.",classes={"WARRIOR"},v=1},
    {"accept",q=1446,title="Jammal'an the Prophet",npc="Atal'ai Exile",z=47,x=33.8,y=75.2,dungeon="The Temple of Atal'Hakkar",v=1},
    {"complete",q=1446,title="Jammal'an the Prophet",dungeon="The Temple of Atal'Hakkar",v=1},
    {"turnin",q=1446,title="Jammal'an the Prophet",npc="Atal'ai Exile",z=47,x=33.8,y=75.2,dungeon="The Temple of Atal'Hakkar",v=1},
    {"level",text="Blasted Lands starts at 50. If you are lower, kill what is around you here (or run a dungeon) until you reach it.",level=50,v=1},
  },
})
