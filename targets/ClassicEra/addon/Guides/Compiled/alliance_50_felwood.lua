-- Questwarden - compiled guide data. GENERATED from guides-src/alliance/50_felwood.guide by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .guide source and rebuild. Guide routes and notes are original Questwarden content
-- (GPL-3.0-only); quest ids, NPC names and coordinates were looked up in the bundled QuestieDB-derived data.
local _, ns = ...
ns.Guides:Register({
  id="A_50_Felwood", name="Felwood (54-55)", faction="Alliance", chapter="Azeroth",
  minLevel=54, maxLevel=55, zone=361, zoneName="Felwood",
  desc="Felwood, visit 2 of 3 on the Alliance route, levels 54-55.",
  next={{id="A_51_BurningSteppes"},},
  steps={
    {"fly",text="Take the flight from Everlook.",dest="Talonbranch Glade",node=65,v=1},
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
    {"accept",q=4101,title="Cleansing Felwood",npc="Arathandris Silversky",z=361,x=54.2,y=86.8,text="Arathandris Silversky.",v=1},
    {"complete",q=7602,title="Flawless Fel Essence",classes={"WARLOCK"},optional=true,v=1},
    {"turnin",q=7602,title="Flawless Fel Essence",npc="Impsy",z=361,x=41.4,y=45,text="Impsy, west Felwood.",classes={"WARLOCK"},optional=true,v=1},
    {"accept",q=7603,title="Kroshius' Infernal Core",npc="Impsy",z=361,x=41.4,y=45,classes={"WARLOCK"},optional=true,v=1},
    {"complete",q=7603,title="Kroshius' Infernal Core",text="Shatter Scar Vale: use the Fel Fire by Kroshius' remains, then defeat him when he rises.",classes={"WARLOCK"},optional=true,v=1},
    {"turnin",q=7603,title="Kroshius' Infernal Core",npc="Niby the Almighty",z=361,x=41.4,y=44.8,text="Niby the Almighty. Inferno.",classes={"WARLOCK"},optional=true,v=1},
    {"complete",q=4101,title="Cleansing Felwood",text="Cenarion Plant Salve - gather from Felwood.",v=1},
    {"turnin",q=4101,title="Cleansing Felwood",npc="Arathandris Silversky",z=361,x=54.2,y=86.8,v=1},
    {"accept",q=5882,title="Salve via Hunting",npc="Arathandris Silversky",z=361,x=54.2,y=86.8,text="Arathandris Silversky. Needs Cleansing Felwood turned in.",v=1},
    {"complete",q=5882,title="Salve via Hunting",text="Corrupted Soul Shards from Cursed Oozes in the Ruins of Constellas, west of the road.",v=1},
    {"turnin",q=5882,title="Salve via Hunting",npc="Arathandris Silversky",z=361,x=54.2,y=86.8,v=1},
    {"accept",q=8462,title="Speak to Nafien",npc="Grazle",z=361,x=50.9,y=85,v=1},
    {"turnin",q=8462,title="Speak to Nafien",npc="Nafien",z=361,x=64.8,y=8.1,v=1},
    {"turnin",q=8471,title="Winterfall Ritual Totem",npc="Kernda",z=361,x=65.5,y=3.5,v=1},
    {"turnin",q=5084,title="Falling to Corruption",npc="Deadwood Cauldron",z=361,x=60.2,y=5.8,v=1},
    {"level",text="Burning Steppes starts at 55. If you are lower, kill what is around you here (or run a dungeon) until you reach it.",level=55,v=1},
  },
})
