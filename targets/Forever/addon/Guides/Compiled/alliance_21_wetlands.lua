-- Questwarden - compiled guide data. GENERATED from guides-src/alliance/21_wetlands.guide by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .guide source and rebuild. Guide routes and notes are original Questwarden content
-- (GPL-3.0-only); quest ids, NPC names and coordinates were looked up in the bundled QuestieDB-derived data.
local _, ns = ...
ns.Guides:Register({
  id="A_21_Wetlands", name="Wetlands (30-31)", faction="Alliance", chapter="Azeroth",
  minLevel=30, maxLevel=31, zone=11, zoneName="Wetlands",
  desc="Wetlands, visit 3 of 3 on the Alliance route, levels 30-31.",
  next={{id="A_22_HillsbradFoothills"},},
  steps={
    {"travel",text="Travel to Wetlands",dest="Wetlands",v=1},
    {"train",text="No druid trainer in this zone - train at the next town or capital.",classes={"DRUID"},v=1},
    {"train",text="No hunter trainer in this zone - train at the next town or capital.",classes={"HUNTER"},v=1},
    {"train",text="No mage trainer in this zone - train at the next town or capital.",classes={"MAGE"},v=1},
    {"train",text="No paladin trainer in this zone - train at the next town or capital.",classes={"PALADIN"},v=1},
    {"train",text="No priest trainer in this zone - train at the next town or capital.",classes={"PRIEST"},v=1},
    {"train",text="No rogue trainer in this zone - train at the next town or capital.",classes={"ROGUE"},v=1},
    {"train",text="No shaman trainer in this zone - train at the next town or capital.",classes={"SHAMAN"},v=1},
    {"train",text="No warlock trainer in this zone - train at the next town or capital.",classes={"WARLOCK"},v=1},
    {"train",text="No warrior trainer in this zone - train at the next town or capital.",classes={"WARRIOR"},v=1},
    {"travel",text="Travel to Ironforge",dest="Ironforge",classes={"WARLOCK"},races={"Human","Gnome"},v=1},
    {"turnin",q=1758,title="Tome of the Cabal",npc="Krom Stoutarm",z=1537,x=74.2,y=9.4,text="Krom Stoutarm, Hall of Explorers, Ironforge.",classes={"WARLOCK"},races={"Human","Gnome"},v=1},
    {"accept",q=1802,title="Tome of the Cabal",npc="Krom Stoutarm",z=1537,x=74.2,y=9.4,classes={"WARLOCK"},races={"Human","Gnome"},v=1},
    {"travel",text="Travel to Wetlands",dest="Wetlands",classes={"WARLOCK"},races={"Human","Gnome"},v=1},
    {"accept",q=304,title="A Grim Task",npc="Longbraid the Grim",z=11,x=49.8,y=18.3,text="Longbraid the Grim, Dun Modr.",v=1},
    {"complete",q=304,title="A Grim Task",text="Balgaras the Foul, at the Dark Iron camp east of Dun Modr.",v=1},
    {"turnin",q=304,title="A Grim Task",npc="Longbraid the Grim",z=11,x=49.8,y=18.3,v=1},
    {"accept",q=633,title="The Thandol Span",npc="Rhag Garmason",z=11,x=49.9,y=18.2,text="Needs level 28. If you are lower, {name} skips it and moves on.",v=1},
    {"complete",q=633,title="The Thandol Span",text="Click Cache of Explosives.",v=1},
    {"turnin",q=633,title="The Thandol Span",npc="Rhag Garmason",z=11,x=49.9,y=18.2,v=1},
    {"accept",q=634,title="Plea To The Alliance",npc="Rhag Garmason",z=11,x=49.9,y=18.2,text="Needs level 28. If you are lower, {name} skips it and moves on.",v=1},
    {"turnin",q=634,title="Plea To The Alliance",npc="Captain Nials",z=45,x=45.8,y=47.6,text="Turned in at Arathi Highlands.",v=1},
    {"accept",q=631,title="The Thandol Span",npc="Rhag Garmason",z=11,x=49.9,y=18.2,v=1},
    {"turnin",q=631,title="The Thandol Span",npc="Ebenezer Rustlocke's Corpse",z=11,x=51.3,y=8,v=1},
    {"level",text="Hillsbrad Foothills starts at 31. If you are lower, kill what is around you here (or run a dungeon) until you reach it.",level=31,v=1},
  },
})
