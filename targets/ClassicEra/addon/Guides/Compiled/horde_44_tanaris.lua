-- ClassicGuide - compiled guide data. GENERATED from guides-src/horde/44_tanaris.guide by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .guide source and rebuild. Guide routes and notes are original ClassicGuide content
-- (GPL-3.0-only); quest ids, NPC names and coordinates were looked up in the bundled QuestieDB-derived data.
local _, ns = ...
ns.Guides:Register({
  id="H_44_Tanaris", name="Tanaris (49-50)", faction="Horde", chapter="Azeroth",
  minLevel=49, maxLevel=50, zone=440, zoneName="Tanaris",
  desc="Tanaris, visit 2 of 2 on the Horde route, levels 49-50.",
  next={{id="H_45_Azshara"},},
  steps={
    {"travel",text="Travel to Tanaris",dest="Tanaris",v=1},
    {"accept",q=10,title="The Scrimshank Redemption",npc="Senior Surveyor Fizzledowser",z=440,x=50.2,y=27.5,v=1},
    {"complete",q=10,title="The Scrimshank Redemption",text="Inside the Noxious Lair tunnels.",v=1},
    {"turnin",q=10,title="The Scrimshank Redemption",npc="Senior Surveyor Fizzledowser",z=440,x=50.2,y=27.5,v=1},
    {"accept",q=110,title="Insect Part Analysis",npc="Senior Surveyor Fizzledowser",z=440,x=50.2,y=27.5,v=1},
    {"turnin",q=110,title="Insect Part Analysis",npc="Alchemist Pestlezugg",z=440,x=50.9,y=27,text="Alchemist Pestlezugg.",v=1},
    {"accept",q=113,title="Insect Part Analysis",npc="Alchemist Pestlezugg",z=440,x=50.9,y=27,v=1},
    {"turnin",q=113,title="Insect Part Analysis",npc="Senior Surveyor Fizzledowser",z=440,x=50.2,y=27.5,v=1},
    {"accept",q=3161,title="Gahz'ridian",npc="Marvon Rivetseeker",z=440,x=52.7,y=45.9,text="Marvon Rivetseeker, south of Gadgetzan. Needs level 43.",optional=true,v=1},
    {"note",text="The next quest, Tooga's Quest, is an escort: pick it up only when you are ready to follow the NPC.",v=1},
    {"accept",q=1560,title="Tooga's Quest",npc="Tooga",z=440,x=31.8,y=74.2,v=1},
    {"complete",q=1560,title="Tooga's Quest",text="Escort: stay close; it fails if the NPC dies.",v=1},
    {"complete",q=3161,title="Gahz'ridian",text="Wear the Gahz'ridian Detector helmet he gives you and dig up Gahz'ridian Ornaments in the Gahz'ridian ruins, south-west.",optional=true,v=1},
    {"turnin",q=3161,title="Gahz'ridian",npc="Marvon Rivetseeker",z=440,x=52.7,y=45.9,optional=true,v=1},
    {"accept",q=2605,title="The Thirsty Goblin",npc="Marin Noggenfogger",z=440,x=51.8,y=28.7,text="Marin Noggenfogger, Gadgetzan. Needs level 44.",optional=true,v=1},
    {"turnin",q=1560,title="Tooga's Quest",npc="Torta",z=440,x=66.6,y=25.7,v=1},
    {"complete",q=2605,title="The Thirsty Goblin",text="Laden Dew Glands from Thistleshrub Dew Collectors in the south-west of Tanaris.",optional=true,v=1},
    {"turnin",q=2605,title="The Thirsty Goblin",npc="Marin Noggenfogger",z=440,x=51.8,y=28.7,optional=true,v=1},
    {"accept",q=2606,title="In Good Taste",npc="Marin Noggenfogger",z=440,x=51.8,y=28.7,v=1},
    {"turnin",q=2606,title="In Good Taste",npc="Sprinkle",z=440,x=51.1,y=26.9,v=1},
    {"level",text="Azshara starts at 50. If you are lower, kill what is around you here (or run a dungeon) until you reach it.",level=50,v=1},
  },
})
