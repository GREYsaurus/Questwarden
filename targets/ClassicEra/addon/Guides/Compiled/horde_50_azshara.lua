-- Questwarden - compiled guide data. GENERATED from guides-src/horde/50_azshara.guide by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .guide source and rebuild. Guide routes and notes are original Questwarden content
-- (GPL-3.0-only); quest ids, NPC names and coordinates were looked up in the bundled QuestieDB-derived data.
local _, ns = ...
ns.Guides:Register({
  id="H_50_Azshara", name="Azshara (53-54)", faction="Horde", chapter="Azeroth",
  minLevel=53, maxLevel=54, zone=16, zoneName="Azshara",
  desc="Azshara, visit 2 of 2 on the Horde route, levels 53-54.",
  next={{id="H_51_Felwood"},},
  steps={
    {"travel",text="Travel to Azshara",dest="Azshara",v=1},
    {"accept",q=3601,title="Kim'jael Indeed!",npc="Kim'jael",z=16,x=53.4,y=21.8,v=1},
    {"complete",q=3601,title="Kim'jael Indeed!",v=1},
    {"turnin",q=3601,title="Kim'jael Indeed!",npc="Kim'jael",z=16,x=53.4,y=21.8,v=1},
    {"accept",q=5534,title="Kim'jael's \"Missing\" Equipment",npc="Kim'jael",z=16,x=53.4,y=21.8,v=1},
    {"complete",q=5534,title="Kim'jael's \"Missing\" Equipment",v=1},
    {"turnin",q=5534,title="Kim'jael's \"Missing\" Equipment",npc="Kim'jael",z=16,x=53.4,y=21.8,v=1},
    {"accept",q=3561,title="Delivery to Archmage Xylem",npc="Jediga",z=16,x=22.6,y=51.4,v=1},
    {"turnin",q=3561,title="Delivery to Archmage Xylem",npc="Archmage Xylem",z=16,x=29.2,y=40.2,v=1},
    {"accept",q=3565,title="Xylem's Payment to Jediga",npc="Archmage Xylem",z=16,x=29.2,y=40.2,v=1},
    {"turnin",q=3565,title="Xylem's Payment to Jediga",npc="Jediga",z=16,x=22.6,y=51.4,v=1},
    {"level",text="Felwood starts at 54. If you are lower, kill what is around you here (or run a dungeon) until you reach it.",level=54,v=1},
  },
})
