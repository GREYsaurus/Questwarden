-- ClassicGuide - compiled guide data. GENERATED from guides-src/alliance/38_hinterlands.guide by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .guide source and rebuild. Guide routes and notes are original ClassicGuide content
-- (GPL-3.0-only); quest ids, NPC names and coordinates were looked up in the bundled QuestieDB-derived data.
local _, ns = ...
ns.Guides:Register({
  id="A_38_Hinterlands", name="The Hinterlands (46)", faction="Alliance", chapter="Azeroth",
  minLevel=46, maxLevel=46, zone=47, zoneName="The Hinterlands",
  desc="The Hinterlands, visit 1 of 2 on the Alliance route, levels 46.",
  next={{id="A_39_StranglethornVale"},},
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
    {"fp",npc="Guthrum Thunderfist",z=47,x=11.1,y=46.2,place="Aerie Peak",node=43,v=1},
    {"accept",q=2880,title="Troll Necklace Bounty",npc="Fraggar Thundermantle",z=47,x=14.8,y=44.6,text="Fraggar Thundermantle.",v=1},
    {"accept",q=2877,title="Skulk Rock Clean-up",npc="Fraggar Thundermantle",z=47,x=14.8,y=44.6,v=1},
    {"accept",q=2988,title="Witherbark Cages",npc="Gryphon Master Talonaxe",z=47,x=9.8,y=44.5,text="Gryphon Master Talonaxe.",v=1},
    {"complete",q=2988,title="Witherbark Cages",text="Witherbark trolls' cages around the Hinterlands.",v=1},
    {"complete",q=2880,title="Troll Necklace Bounty",text="Any Witherbark trolls.",v=1},
    {"turnin",q=2988,title="Witherbark Cages",npc="Gryphon Master Talonaxe",z=47,x=9.8,y=44.5,v=1},
    {"accept",q=2989,title="The Altar of Zul",npc="Gryphon Master Talonaxe",z=47,x=9.8,y=44.5,v=1},
    {"complete",q=2989,title="The Altar of Zul",text="Explore the altar (trolls are dense here).",v=1},
    {"turnin",q=2989,title="The Altar of Zul",npc="Gryphon Master Talonaxe",z=47,x=9.8,y=44.5,v=1},
    {"turnin",q=2880,title="Troll Necklace Bounty",npc="Fraggar Thundermantle",z=47,x=14.8,y=44.6,v=1},
    {"complete",q=2877,title="Skulk Rock Clean-up",text="Oozes at Skulk Rock.",v=1},
    {"turnin",q=2877,title="Skulk Rock Clean-up",npc="Fraggar Thundermantle",z=47,x=14.8,y=44.6,v=1},
    {"level",text="Stranglethorn Vale starts at 46. If you are lower, kill what is around you here (or run a dungeon) until you reach it.",level=46,v=1},
  },
})
