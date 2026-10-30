-- ClassicGuide - compiled guide data. GENERATED from guides-src/horde/16_stranglethorn_late.guide by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .guide source and rebuild. Guide routes and notes are original ClassicGuide content
-- (GPL-3.0-only); quest ids, NPC names and coordinates were looked up in the bundled QuestieDB-derived data.
local _, ns = ...
ns.Guides:Register({
  id="H_Stranglethorn_Late", name="Stranglethorn Vale (return, 39-45)", faction="Horde", chapter="Azeroth",
  minLevel=39, maxLevel=40, zone=33, zoneName="Stranglethorn Vale",
  desc="A second pass through Stranglethorn Vale at 39-45 for the quests the first visit was too low for.",
  next={{id="H_SwampOfSorrows"},},
  steps={
    {"note",text="Back in Stranglethorn Vale for the higher-level quests.",v=1},
    {"accept",q=576,title="Keep An Eye Out",npc="Dizzy One-Eye",z=33,x=28.6,y=75.9,v=1},
    {"accept",q=209,title="Skullsplitter Tusks",npc="Kebok",z=33,x=27,y=77.1,v=1},
    {"accept",q=587,title="Up to Snuff",npc="Deeg",z=33,x=26.9,y=77.4,v=1},
    {"accept",q=573,title="Mok'thardin's Enchantment",npc="Far Seer Mok'thardin",z=33,x=32.1,y=29.2,v=1},
    {"accept",q=589,title="The Singing Crystals",npc="Kin'weelay",z=33,x=32.3,y=27.7,v=1},
    {"accept",q=196,title="Raptor Mastery",npc="Hemet Nesingwary",z=33,x=35.7,y=10.8,v=1},
    {"complete",q=209,title="Skullsplitter Tusks",v=1},
    {"complete",q=589,title="The Singing Crystals",v=1},
    {"complete",q=196,title="Raptor Mastery",v=1},
    {"complete",q=573,title="Mok'thardin's Enchantment",v=1},
    {"complete",q=576,title="Keep An Eye Out",v=1},
    {"complete",q=587,title="Up to Snuff",v=1},
    {"turnin",q=576,title="Keep An Eye Out",npc="Dizzy One-Eye",z=33,x=28.6,y=75.9,v=1},
    {"turnin",q=209,title="Skullsplitter Tusks",npc="Kebok",z=33,x=27,y=77.1,v=1},
    {"turnin",q=587,title="Up to Snuff",npc="Deeg",z=33,x=26.9,y=77.4,v=1},
    {"turnin",q=573,title="Mok'thardin's Enchantment",npc="Far Seer Mok'thardin",z=33,x=32.1,y=29.2,v=1},
    {"turnin",q=589,title="The Singing Crystals",npc="Kin'weelay",z=33,x=32.3,y=27.7,v=1},
    {"turnin",q=196,title="Raptor Mastery",npc="Hemet Nesingwary",z=33,x=35.7,y=10.8,v=1},
  },
})
