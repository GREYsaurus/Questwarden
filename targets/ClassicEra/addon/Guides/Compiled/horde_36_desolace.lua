-- ClassicGuide - compiled guide data. GENERATED from guides-src/horde/36_desolace.guide by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .guide source and rebuild. Guide routes and notes are original ClassicGuide content
-- (GPL-3.0-only); quest ids, NPC names and coordinates were looked up in the bundled QuestieDB-derived data.
local _, ns = ...
ns.Guides:Register({
  id="H_36_Desolace", name="Desolace (44)", faction="Horde", chapter="Azeroth",
  minLevel=44, maxLevel=44, zone=405, zoneName="Desolace",
  desc="Desolace, visit 2 of 2 on the Horde route, levels 44.",
  next={{id="H_37_Tanaris"},},
  steps={
    {"travel",text="Travel to Desolace",dest="Desolace",v=1},
    {"train",text="No druid trainer in this zone - train at the next town or capital.",classes={"DRUID"},v=1},
    {"train",text="No hunter trainer in this zone - train at the next town or capital.",classes={"HUNTER"},v=1},
    {"train",text="No mage trainer in this zone - train at the next town or capital.",classes={"MAGE"},v=1},
    {"train",text="No paladin trainer in this zone - train at the next town or capital.",classes={"PALADIN"},v=1},
    {"train",text="No priest trainer in this zone - train at the next town or capital.",classes={"PRIEST"},v=1},
    {"train",text="No rogue trainer in this zone - train at the next town or capital.",classes={"ROGUE"},v=1},
    {"train",text="No shaman trainer in this zone - train at the next town or capital.",classes={"SHAMAN"},v=1},
    {"train",text="No warlock trainer in this zone - train at the next town or capital.",classes={"WARLOCK"},v=1},
    {"train",text="No warrior trainer in this zone - train at the next town or capital.",classes={"WARRIOR"},v=1},
    {"turnin",q=5361,title="Family Tree",npc="Nataka Longhorn",z=405,x=55.4,y=55.8,optional=true,v=1},
    {"note",text="The next quest, Gizelton Caravan, is an escort: pick it up only when you are ready to follow the NPC.",v=1},
    {"accept",q=5943,title="Gizelton Caravan",npc="Rigger Gizelton",z=405,x=66.7,y=58.6,v=1},
    {"complete",q=5943,title="Gizelton Caravan",text="Escort: stay close; it fails if the NPC dies.",v=1},
    {"turnin",q=5943,title="Gizelton Caravan",npc="Smeed Scrabblescrew",z=405,x=60.9,y=61.9,v=1},
    {"accept",q=7028,title="Twisted Evils",npc="Willow",z=405,x=62.2,y=39.6,v=1},
    {"complete",q=7028,title="Twisted Evils",v=1},
    {"turnin",q=7028,title="Twisted Evils",npc="Willow",z=405,x=62.2,y=39.6,v=1},
    {"accept",q=5501,title="Bone Collector",npc="Bibbly F'utzbuckle",z=405,x=62.3,y=39,v=1},
    {"complete",q=5501,title="Bone Collector",v=1},
    {"turnin",q=5501,title="Bone Collector",npc="Bibbly F'utzbuckle",z=405,x=62.3,y=39,v=1},
    {"note",text="The next quest, Get Me Out of Here!, is an escort: pick it up only when you are ready to follow the NPC.",v=1},
    {"accept",q=6132,title="Get Me Out of Here!",npc="Melizza Brimbuzzle",z=405,x=34,y=53.5,v=1},
    {"complete",q=6132,title="Get Me Out of Here!",text="Escort: stay close; it fails if the NPC dies.",v=1},
    {"turnin",q=6132,title="Get Me Out of Here!",npc="Hornizz Brimbuzzle",z=405,x=47.8,y=61.8,v=1},
    {"level",text="Tanaris starts at 44. If you are lower, kill what is around you here (or run a dungeon) until you reach it.",level=44,v=1},
  },
})
