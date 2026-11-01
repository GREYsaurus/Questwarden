-- Questwarden - compiled guide data. GENERATED from guides-src/horde/47_blastedlands.guide by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .guide source and rebuild. Guide routes and notes are original Questwarden content
-- (GPL-3.0-only); quest ids, NPC names and coordinates were looked up in the bundled QuestieDB-derived data.
local _, ns = ...
ns.Guides:Register({
  id="H_47_BlastedLands", name="Blasted Lands (51-52)", faction="Horde", chapter="Azeroth",
  minLevel=51, maxLevel=52, zone=4, zoneName="Blasted Lands",
  desc="Blasted Lands, visit 1 of 1 on the Horde route, levels 51-52.",
  next={{id="H_48_UnGoroCrater"},},
  steps={
    {"travel",text="Travel to Blasted Lands",dest="Blasted Lands",v=1},
    {"accept",q=2603,title="Vulture's Vigor",npc="Bloodmage Lynnore",z=4,x=50.6,y=14.3,v=1},
    {"accept",q=2601,title="The Basilisk's Bite",npc="Bloodmage Lynnore",z=4,x=50.6,y=14.3,v=1},
    {"accept",q=2581,title="Snickerfang Jowls",npc="Bloodmage Drazial",z=4,x=50.6,y=14.2,v=1},
    {"accept",q=2583,title="A Boar's Vitality",npc="Bloodmage Drazial",z=4,x=50.6,y=14.2,v=1},
    {"accept",q=2585,title="The Decisive Striker",npc="Bloodmage Drazial",z=4,x=50.6,y=14.2,v=1},
    {"note",text=" - Hardcore: Clack the Reaver, a level 53 rare, roams the ground around Kum'isha. Look for it before you go in and out.",hcOnly=true,v=1},
    {"accept",q=2521,title="To Serve Kum'isha",npc="Kum'isha the Collector",z=4,x=52,y=35.6,v=1},
    {"accept",q=3501,title="Everything Counts In Large Amounts",npc="Kum'isha the Collector",z=4,x=52,y=35.6,v=1},
    {"complete",q=2603,title="Vulture's Vigor",pack=10,v=1},
    {"complete",q=2601,title="The Basilisk's Bite",pack=10,v=1},
    {"complete",q=2585,title="The Decisive Striker",pack=10,v=1},
    {"complete",q=2583,title="A Boar's Vitality",pack=10,v=1},
    {"complete",q=2581,title="Snickerfang Jowls",pack=10,v=1},
    {"complete",q=2521,title="To Serve Kum'isha",pack=10,v=1},
    {"complete",q=3501,title="Everything Counts In Large Amounts",pack=10,v=1},
    {"turnin",q=2603,title="Vulture's Vigor",npc="Bloodmage Lynnore",z=4,x=50.6,y=14.3,v=1},
    {"turnin",q=2601,title="The Basilisk's Bite",npc="Bloodmage Lynnore",z=4,x=50.6,y=14.3,v=1},
    {"turnin",q=2581,title="Snickerfang Jowls",npc="Bloodmage Drazial",z=4,x=50.6,y=14.2,v=1},
    {"turnin",q=2583,title="A Boar's Vitality",npc="Bloodmage Drazial",z=4,x=50.6,y=14.2,v=1},
    {"turnin",q=2585,title="The Decisive Striker",npc="Bloodmage Drazial",z=4,x=50.6,y=14.2,v=1},
    {"turnin",q=2521,title="To Serve Kum'isha",npc="Kum'isha the Collector",z=4,x=52,y=35.6,v=1},
    {"turnin",q=3501,title="Everything Counts In Large Amounts",npc="Kum'isha the Collector",z=4,x=52,y=35.6,v=1},
    {"level",text="Un'Goro Crater starts at 51. If you are lower, kill what is around you here (or run a dungeon) until you reach it.",level=51,v=1},
  },
})
