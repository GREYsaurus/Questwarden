-- ClassicGuide - compiled guide data. GENERATED from guides-src/alliance/42_dustwallowmarsh.guide by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .guide source and rebuild. Guide routes and notes are original ClassicGuide content
-- (GPL-3.0-only); quest ids, NPC names and coordinates were looked up in the bundled QuestieDB-derived data.
local _, ns = ...
ns.Guides:Register({
  id="A_42_DustwallowMarsh", name="Dustwallow Marsh (49)", faction="Alliance", chapter="Azeroth",
  minLevel=49, maxLevel=49, zone=15, zoneName="Dustwallow Marsh",
  desc="Dustwallow Marsh, visit 2 of 2 on the Alliance route, levels 49.",
  next={{id="A_43_Tanaris"},},
  steps={
    {"fly",text="Take the flight from Feathermoon.",dest="Theramore",node=32,v=1},
    {"travel",text="Travel to Dustwallow Marsh",dest="Dustwallow Marsh",v=1},
    {"accept",q=2846,title="Tiara of the Deep",npc="Tabetha",z=15,x=46.1,y=57.1,dungeon="Zul'Farrak",v=1},
    {"complete",q=2846,title="Tiara of the Deep",dungeon="Zul'Farrak",v=1},
    {"turnin",q=2846,title="Tiara of the Deep",npc="Tabetha",z=15,x=46.1,y=57.1,dungeon="Zul'Farrak",v=1},
    {"level",text="Tanaris starts at 49. If you are lower, kill what is around you here (or run a dungeon) until you reach it.",level=49,v=1},
  },
})
