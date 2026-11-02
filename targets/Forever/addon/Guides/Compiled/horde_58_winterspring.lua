-- Questwarden - compiled guide data. GENERATED from guides-src/horde/58_winterspring.guide by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .guide source and rebuild. Guide routes and notes are original Questwarden content
-- (GPL-3.0-only); quest ids, NPC names and coordinates were looked up in the bundled QuestieDB-derived data.
local _, ns = ...
ns.Guides:Register({
  id="H_58_Winterspring", name="Winterspring (59-60)", faction="Horde", chapter="Azeroth",
  minLevel=59, maxLevel=60, zone=618, zoneName="Winterspring",
  desc="Winterspring, visit 2 of 2 on the Horde route, levels 59-60.",
  next={},
  steps={
    {"travel",text="Travel to Winterspring",dest="Winterspring",v=1},
    {"accept",q=8464,title="Winterfall Activity",npc="Salfa",z=618,x=27.7,y=34.5,text="Salfa. The Winterfall camp is far east, past Everlook.",v=1},
    {"complete",q=8464,title="Winterfall Activity",text="Winterfall Shamans, Den Watchers and Ursa at the Winterfall Village east of Everlook.",v=1},
    {"accept",q=5055,title="Brumeran of the Chillwind",npc="Storm Shadowhoof",z=618,x=61.9,y=38.4,v=1},
    {"accept",q=977,title="Are We There, Yeti?",npc="Umi Rumplesnicker",z=618,x=60.9,y=37.6,v=1},
    {"complete",q=5055,title="Brumeran of the Chillwind",text="Brumeran, a chimaera in the south of the zone.",v=1},
    {"complete",q=977,title="Are We There, Yeti?",text="Pristine Yeti Horn from the Ice Thistle Matriarch, east of Everlook.",v=1},
    {"turnin",q=5055,title="Brumeran of the Chillwind",npc="Storm Shadowhoof",z=618,x=61.9,y=38.4,text="Storm Shadowhoof, Everlook.",v=1},
    {"turnin",q=977,title="Are We There, Yeti?",npc="Umi Rumplesnicker",z=618,x=60.9,y=37.6,text="Umi Rumplesnicker.",v=1},
    {"accept",q=5163,title="Are We There, Yeti?",npc="Umi Rumplesnicker",z=618,x=60.9,y=37.6,v=1},
    {"complete",q=5163,title="Are We There, Yeti?",v=1},
    {"accept",q=6606,title="A Little Luck",npc="Harlo Wigglesworth",z=618,x=61.1,y=38.4,v=1},
    {"turnin",q=6606,title="A Little Luck",npc="Witch Doctor Mau'ari",z=618,x=61.9,y=38.3,v=1},
    {"accept",q=969,title="Luck Be With You",npc="Witch Doctor Mau'ari",z=618,x=61.9,y=38.3,v=1},
    {"turnin",q=5163,title="Are We There, Yeti?",npc="Umi Rumplesnicker",z=618,x=60.9,y=37.6,v=1},
    {"turnin",q=8464,title="Winterfall Activity",npc="Salfa",z=618,x=27.7,y=34.5,text="Salfa, back at the tunnel.",v=1},
    {"complete",q=969,title="Luck Be With You",v=1},
    {"turnin",q=969,title="Luck Be With You",npc="Witch Doctor Mau'ari",z=618,x=61.9,y=38.3,v=1},
    {"grind",z=618,x=67.6,y=39.5,text="The next steps expect level 60 and the quests here don't quite get you there: grind these until you reach it.",level=60,mobs={"Winterfall Ursa","Ice Thistle Patriarch"},v=0},
  },
})
