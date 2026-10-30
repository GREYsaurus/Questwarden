-- ClassicGuide - compiled guide data. GENERATED from guides-src/alliance/06_ashenvale_late.guide by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .guide source and rebuild. Guide routes and notes are original ClassicGuide content
-- (GPL-3.0-only); quest ids, NPC names and coordinates were looked up in the bundled QuestieDB-derived data.
local _, ns = ...
ns.Guides:Register({
  id="A_Ashenvale_Late", name="Ashenvale (return, 25-31)", faction="Alliance", chapter="Azeroth",
  minLevel=24, maxLevel=25, zone=331, zoneName="Ashenvale",
  desc="A second pass through Ashenvale at 25-31 for the quests the first visit was too low for.",
  next={{id="A_Wetlands"},},
  steps={
    {"note",text="Back in Ashenvale for the higher-level quests.",v=1},
    {"accept",q=4581,title="Kayneth Stillwind",npc="Shindrell Swiftfire",z=331,x=34.7,y=48.8,v=1},
    {"accept",q=1022,title="The Howling Vale",npc="Sentinel Melyria Frostshadow",z=331,x=22.2,y=53,v=1},
    {"accept",q=1021,title="Vile Satyr! Dryads in Danger!",npc="Illiyana",z=331,x=21.7,y=53.3,v=1},
    {"accept",q=1140,title="The Tower of Althalaxx",npc="Delgren the Purifier",z=331,x=26.2,y=38.7,v=1},
    {"accept",q=1011,title="Forsaken Diseases",npc="Kayneth Stillwind",z=331,x=85.2,y=44.7,v=1},
    {"complete",q=1140,title="The Tower of Althalaxx",v=1},
    {"complete",q=1011,title="Forsaken Diseases",v=1},
    {"complete",q=1022,title="The Howling Vale",v=1},
    {"turnin",q=1140,title="The Tower of Althalaxx",npc="Delgren the Purifier",z=331,x=26.2,y=38.7,v=1},
    {"turnin",q=1022,title="The Howling Vale",npc="Sentinel Melyria Frostshadow",z=331,x=22.2,y=53,v=1},
    {"turnin",q=1021,title="Vile Satyr! Dryads in Danger!",npc="Anilia",z=331,x=78.3,y=44.8,v=1},
    {"turnin",q=1011,title="Forsaken Diseases",npc="Kayneth Stillwind",z=331,x=85.2,y=44.7,v=1},
    {"turnin",q=4581,title="Kayneth Stillwind",npc="Kayneth Stillwind",z=331,x=85.2,y=44.7,v=1},
    {"accept",q=1012,title="Insane Druids",npc="Kayneth Stillwind",z=331,x=85.2,y=44.7,v=1},
    {"accept",q=1031,title="The Branch of Cenarius",npc="Anilia",z=331,x=78.3,y=44.8,v=1},
    {"complete",q=1031,title="The Branch of Cenarius",v=1},
    {"complete",q=1012,title="Insane Druids",v=1},
    {"turnin",q=1012,title="Insane Druids",npc="Kayneth Stillwind",z=331,x=85.2,y=44.7,v=1},
    {"turnin",q=1031,title="The Branch of Cenarius",npc="Illiyana",z=331,x=21.7,y=53.3,v=1},
    {"accept",q=1032,title="Satyr Slaying!",npc="Illiyana",z=331,x=21.7,y=53.3,v=1},
    {"complete",q=1032,title="Satyr Slaying!",v=1},
    {"turnin",q=1032,title="Satyr Slaying!",npc="Illiyana",z=331,x=21.7,y=53.3,v=1},
  },
})
