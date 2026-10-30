-- ClassicGuide - roaming hunting routes. GENERATED from guides-src/routes by tools/build.ps1 guides.
-- DO NOT EDIT: edit the .routes source and rebuild. Route points come from QuestieDB-derived spawn data
-- (docs/ROAMING.md); the route selection and order are original ClassicGuide content (GPL-3.0-only).
local _, ns = ...
ns.RoamRoutes = {
  [7] = {
    { name="Kobold Camp Cleanup: Kobold Vermin", zone=12, r=15, loop=true,
      objs={{i=1,kind="kill",name="Kobold Vermin",npcs={6}}},
      pts={{47.6,35.8,note="West end of the kobold camp"},{49.6,35.7,note="Middle of the camp"},{51.3,37,note="East end of the camp"}} },
  },
  [18] = {
    { name="Brotherhood of Thieves: Red Burlap Bandana", zone=12, r=20, loop=true,
      objs={{i=1,kind="drop",item=752,name="Red Burlap Bandana",npcs={38}}},
      pts={{53.6,46.8},{52.1,49.9},{54.1,50.3},{55.5,48.2},{55.7,42.5}} },
  },
  [25] = {
    { name="Stonetalon Standstill: Befouled Water Elemental", zone=331, r=20, loop=true,
      objs={{i=1,kind="kill",name="Befouled Water Elemental",npcs={3917}}},
      pts={{47.8,68.6},{46.2,70.3},{48.1,72.3},{47.7,70.3}} },
  },
  [33] = {
    { name="Wolves Across the Border: Tough Wolf Meat", zone=12, r=20, loop=true,
      objs={{i=1,kind="drop",item=750,name="Tough Wolf Meat",npcs={69,299}}},
      pts={{46.1,38.4,note="West of the abbey"},{48.7,37.9,note="North of the abbey"},{50.6,36.3,note="North-east field"},{52.3,39.4,note="East of the abbey"},{51.6,43.6,note="South-east, by the vineyard path"},{49.1,46.2,note="South of the abbey"},{46.1,43.6,note="South-west field"}} },
  },
  [38] = {
    { name="Westfall Stew: Murloc Eye", zone=40, r=15, loop=true,
      objs={{i=2,kind="drop",item=730,name="Murloc Eye",npcs={126,127,171,391,456,458,513,515,517}}},
      pts={{53.5,10.6},{52.5,9.5},{55.8,8.7}} },
  },
  [46] = {
    { name="Bounty on Murlocs: Torn Murloc Fin", zone=12, r=15, loop=true,
      objs={{i=1,kind="drop",item=780,name="Torn Murloc Fin",npcs={46,732}}},
      pts={{79.3,56.8},{78.1,57},{79.5,54.6}} },
  },
  [52] = {
    { name="Protect the Frontier: Prowler", zone=12, r=15, loop=true,
      objs={{i=1,kind="kill",name="Prowler",npcs={118}}},
      pts={{79.7,83},{80.5,80},{81.6,77.5},{81.7,83.2}} },
  },
  [56] = {
    { name="The Night Watch: Skeletal Warrior", zone=10, r=15, loop=true,
      objs={{i=1,kind="kill",name="Skeletal Warrior",npcs={48}}},
      pts={{80.5,68.9},{77.5,71.8},{80.3,73}} },
    { name="The Night Watch: Skeletal Mage", zone=10, r=15, loop=true,
      objs={{i=2,kind="kill",name="Skeletal Mage",npcs={203}}},
      pts={{77.6,68.2},{78.2,75.6},{79.6,74.5},{79,72},{79.7,69.3}} },
  },
  [57] = {
    { name="The Night Watch: Skeletal Horror", zone=10, r=15, loop=true,
      objs={{i=2,kind="kill",name="Skeletal Horror",npcs={202}}},
      pts={{81.4,57.1},{79.3,58.3},{80.6,60.8}} },
  },
  [83] = {
    { name="Red Linen Goods: Red Linen Bandana", zone=12, r=15, loop=true,
      objs={{i=1,kind="drop",item=1019,name="Red Linen Bandana",npcs={116,473,474,880,881,6846,6927}}},
      pts={{73.9,50.3},{73,55.3},{74.3,52.5}} },
  },
  [86] = {
    { name="Pie for Billy: Chunk of Boar Meat", zone=12, r=15, loop=true,
      objs={{i=1,kind="drop",item=769,name="Chunk of Boar Meat",npcs={113,119,330,390,524}}},
      pts={{41.2,85.9},{40.8,88.7},{42.3,86.5}} },
  },
  [89] = {
    { name="The Everstill Bridge: Iron Pike", zone=44, r=20, loop=true,
      objs={{i=1,kind="drop",item=2856,name="Iron Pike",npcs={426,430,446,580}},{i=2,kind="drop",item=1013,name="Iron Rivet",npcs={426,430,446,580}}},
      pts={{23.9,35.4},{20.9,34.3},{19.7,23.9},{17,19.1},{19.2,14.6},{23.4,26.7}} },
  },
  [101] = {
    { name="The Totem of Infliction: Vial of Spider Venom", zone=10, r=20, loop=true,
      objs={{i=2,kind="drop",item=1130,name="Vial of Spider Venom",npcs={217,539,569,930,949}}},
      pts={{30.1,51},{30.5,47.2},{33.2,49},{31.1,55.6}} },
  },
  [112] = {
    { name="Collecting Kelp: Crystal Kelp Frond", zone=12, r=15, loop=true,
      objs={{i=1,kind="drop",item=1256,name="Crystal Kelp Frond",npcs={285,735}}},
      pts={{56.5,66.8},{52.5,68.8},{54.6,66.4}} },
  },
  [152] = {
    { name="The Coast Isn't Clear: Murloc Coastrunner", zone=40, r=15, loop=true,
      objs={{i=1,kind="kill",name="Murloc Coastrunner",npcs={126}}},
      pts={{44.7,8.3},{42.4,12},{42.7,8.9}} },
  },
  [156] = {
    { name="Gather Rot Blossoms: Rot Blossom", zone=10, r=15, loop=true,
      objs={{i=1,kind="drop",item=1598,name="Rot Blossom",npcs={202,531}}},
      pts={{81.4,57.1},{79.3,58.3},{80.6,60.8}} },
  },
  [170] = {
    { name="A New Threat: Rockjaw Trogg", zone=1, r=20, loop=true,
      objs={{i=1,kind="kill",name="Rockjaw Trogg",npcs={707}}},
      pts={{32.4,75.2},{30.6,74.7},{29.5,77},{31.4,76.6}} },
    { name="A New Threat: Burly Rockjaw Trogg", zone=1, r=20, loop=true,
      objs={{i=2,kind="kill",name="Burly Rockjaw Trogg",npcs={724}}},
      pts={{26.6,72.8},{24.3,74.5},{24.7,72.7}} },
  },
  [179] = {
    { name="Dwarven Outfitters: Tough Wolf Meat", zone=1, r=20, loop=true,
      objs={{i=1,kind="drop",item=750,name="Tough Wolf Meat",npcs={704,705}}},
      pts={{26.7,75.3},{28.5,73.6},{26.5,70.4},{30.3,74.2},{28.7,76.6}} },
  },
  [183] = {
    { name="The Boar Hunter: Small Crag Boar", zone=1, r=20, loop=true,
      objs={{i=1,kind="kill",name="Small Crag Boar",npcs={708}}},
      pts={{24,68.7},{22.1,71.9},{20,75.6},{20.3,73.6},{20.8,69.9},{22.4,69.7}} },
  },
  [192] = {
    { name="Panther Mastery: Shadowmaw Panther", zone=33, r=15, loop=true,
      objs={{i=1,kind="kill",name="Shadowmaw Panther",npcs={684}}},
      pts={{39.5,40.9},{39.5,42.2},{41.3,40.3},{40.5,40.3}} },
  },
  [203] = {
    { name="The Second Rebellion: Kurzen Jungle Fighter", zone=33, r=15, loop=true,
      objs={{i=1,kind="kill",name="Kurzen Jungle Fighter",npcs={937}}},
      pts={{44.8,11.3},{43.7,9.7},{44.4,9.9}} },
  },
  [221] = {
    { name="Worgen in the Woods: Nightbane Dark Runner", zone=10, r=15, loop=true,
      objs={{i=1,kind="kill",name="Nightbane Dark Runner",npcs={205}}},
      pts={{65.4,69.4},{65.4,67},{66.8,68.6}} },
  },
  [224] = {
    { name="In Defense of the King's Lands: Stonesplinter Scout", zone=38, r=15, loop=true,
      objs={{i=2,kind="kill",name="Stonesplinter Scout",npcs={1162}}},
      pts={{34.6,71.2},{31.5,75.1},{34.3,76}} },
  },
  [237] = {
    { name="In Defense of the King's Lands: Stonesplinter Skullthumper", zone=38, r=15, loop=true,
      objs={{i=1,kind="kill",name="Stonesplinter Skullthumper",npcs={1163}}},
      pts={{35.7,87.8},{34.3,86.8},{35.8,81.7},{36.1,84.2}} },
    { name="In Defense of the King's Lands: Stonesplinter Seer", zone=38, r=20, loop=true,
      objs={{i=2,kind="kill",name="Stonesplinter Seer",npcs={1166}}},
      pts={{34.7,89.3},{34.1,85.8},{35,81.7},{36.7,78.7},{36.4,84.4}} },
  },
  [261] = {
    { name="Down the Scarlet Path: Undead Ravager", zone=405, r=20, loop=true,
      objs={{i=1,kind="kill",name="Undead Ravager",npcs={11561}}},
      pts={{64.3,88.9},{63.3,91.1},{60.4,90.4},{65.1,86.7}} },
  },
  [263] = {
    { name="In Defense of the King's Lands: Stonesplinter Shaman", zone=38, r=15, loop=true,
      objs={{i=1,kind="kill",name="Stonesplinter Shaman",npcs={1197}}},
      pts={{34.5,93.4},{36.4,93.5},{36.9,90.5}} },
  },
  [267] = {
    { name="The Trogg Threat: Trogg Stone Tooth", zone=38, r=20, loop=true,
      objs={{i=1,kind="drop",item=2536,name="Trogg Stone Tooth",npcs={1161,1162,1163,1164,1165,1166,1167,1197,1393}}},
      pts={{33.9,71.5},{30.9,74.2},{28.9,82.2},{28.7,86.4},{32.8,78.3}} },
  },
  [317] = {
    { name="Stocking Jetsteam: Chunk of Boar Meat", zone=1, r=20, loop=true,
      objs={{i=1,kind="drop",item=769,name="Chunk of Boar Meat",npcs={708,1125,1126,1127}}},
      pts={{24,68.7},{22.1,71.9},{20,75.6},{20.3,73.6},{20.8,69.9},{22.4,69.7}} },
  },
  [364] = {
    { name="The Mindless Ones: Mindless Zombie", zone=85, r=20, loop=true,
      objs={{i=1,kind="kill",name="Mindless Zombie",npcs={1501}}},
      pts={{32.9,63.9},{31.3,63.7},{31.2,62},{34.8,62.8},{34.3,64.6}} },
    { name="The Mindless Ones: Wretched Zombie", zone=85, r=20, loop=true,
      objs={{i=2,kind="kill",name="Wretched Zombie",npcs={1502}}},
      pts={{33.6,64.6},{32.1,62},{33.8,62.1}} },
  },
  [381] = {
    { name="The Scarlet Crusade: Scarlet Armband", zone=85, r=20, loop=true,
      objs={{i=1,kind="drop",item=3266,name="Scarlet Armband",npcs={1506,1507,1667}}},
      pts={{37.7,65.8},{36.5,68.3},{37.5,70.4},{38,68.2}} },
  },
  [418] = {
    { name="Thelsamar Blood Sausages: Boar Intestines", zone=38, r=15, loop=true,
      objs={{i=1,kind="drop",item=3172,name="Boar Intestines",npcs={1190,1191,1192}}},
      pts={{37.6,35.1},{35.5,34},{37.6,38.8}} },
  },
  [426] = {
    { name="The Mills Overrun: Blackened Skull", zone=85, r=15, loop=true,
      objs={{i=2,kind="drop",item=3163,name="Blackened Skull",npcs={1522}}},
      pts={{47.9,34.1},{49,34.2},{49.6,36.3}} },
  },
  [427] = {
    { name="At War With The Scarlet Crusade: Scarlet Warrior", zone=85, r=20, loop=true,
      objs={{i=1,kind="kill",name="Scarlet Warrior",npcs={1535}}},
      pts={{30.8,46.8},{32,46.3},{33.9,48.5},{32.1,48.8}} },
  },
  [456] = {
    { name="The Balance of Nature: Young Nightsabers", zone=141, r=20, loop=true,
      objs={{i=1,kind="kill",name="Young Nightsaber",npcs={2031}}},
      pts={{61.6,40.6,note="North-east of Aldrassil"},{63.2,42.3,note="East edge of the glen"},{62.2,44.4,note="South-east"},{60.6,45.6,note="South of the tree"}} },
    { name="The Balance of Nature: Young Thistle Boars", zone=141, r=15, loop=true,
      objs={{i=2,kind="kill",name="Young Thistle Boar",npcs={1984}}},
      pts={{55.8,41.4,note="West of the tree, east of the Grellkin"},{56.9,42.6,note="Foot of the tree, west side"},{57.3,45.3,note="South-west of the tree"},{55.8,43.6,note="West side, keep clear of the Grellkin to the west"}} },
  },
  [457] = {
    { name="The Balance of Nature: Mangy Nightsaber", zone=141, r=15, loop=true,
      objs={{i=1,kind="kill",name="Mangy Nightsaber",npcs={2032}}},
      pts={{60,35.8},{60.5,34.4},{61.7,35.2}} },
  },
  [479] = {
    { name="Ambermill Investigations: Dalaran Pendant", zone=130, r=20, loop=true,
      objs={{i=1,kind="drop",item=3354,name="Dalaran Pendant",npcs={1912,1914,1915}}},
      pts={{61.5,62.4},{59.1,62.4},{58,65.4},{60,66},{63.2,64.3}} },
  },
  [487] = {
    { name="The Road to Darnassus: Gnarlpine Ambusher", zone=141, r=15, loop=true,
      objs={{i=1,kind="kill",name="Gnarlpine Ambusher",npcs={2152}}},
      pts={{46.3,52.2},{45.6,53.9},{46.5,54}} },
  },
  [546] = {
    { name="Souvenirs of Death: Hillsbrad Human Skull", zone=267, r=20, loop=true,
      objs={{i=1,kind="drop",item=3692,name="Hillsbrad Human Skull",npcs={232,2244,2260,2261,2264,2265,2266,2267,2268,2269,2270,2305}}},
      pts={{80.7,45.5},{77.4,44.7},{75.6,40.9},{78.8,40.3},{82,41.1}} },
  },
  [570] = {
    { name="Mok'thardin's Enchantment: Shadowmaw Claw", zone=33, r=15, loop=true,
      objs={{i=1,kind="drop",item=3838,name="Shadowmaw Claw",npcs={684,1713}}},
      pts={{39.5,40.9},{39.5,42.2},{41.3,40.3},{40.5,40.3}} },
    { name="Mok'thardin's Enchantment: Pristine Tigress Fang", zone=33, r=15, loop=true,
      objs={{i=2,kind="drop",item=3839,name="Pristine Tigress Fang",npcs={772}}},
      pts={{39.5,40.9},{39.5,42.2},{41.3,40.3},{40.5,40.3}} },
  },
  [574] = {
    { name="Special Forces: Kurzen Commando", zone=33, r=15, loop=true,
      objs={{i=1,kind="kill",name="Kurzen Commando",npcs={938}}},
      pts={{45.9,8.2},{46.5,7.1},{47.3,7.6}} },
  },
  [581] = {
    { name="Hunt for Yenniku: Bloodscalp Tusk", zone=33, r=20, loop=true,
      objs={{i=1,kind="drop",item=3901,name="Bloodscalp Tusk",npcs={587,588,595,597,660,671,694,697,699,701,702}}},
      pts={{23,11.9},{23.3,9},{24.6,10.4},{25.7,9.4},{26,12.4},{24.4,12.7}} },
  },
  [582] = {
    { name="Headhunting: Shrunken Head", zone=33, r=15, loop=true,
      objs={{i=1,kind="drop",item=1532,name="Shrunken Head",npcs={671}}},
      pts={{23.4,8.7},{23.1,10.5},{24.4,10.3}} },
  },
  [596] = {
    { name="Bloody Bone Necklaces: Bloody Bone Necklace", zone=33, r=20, loop=true,
      objs={{i=1,kind="drop",item=3915,name="Bloody Bone Necklace",npcs={587,588,595,597,660,671,694,697,699,701,702}}},
      pts={{23,11.9},{23.3,9},{24.6,10.4},{25.7,9.4},{26,12.4},{24.4,12.7}} },
  },
  [678] = {
    { name="Call to Arms: Boulderfist Brute", zone=45, r=15, loop=true,
      objs={{i=1,kind="kill",name="Boulderfist Brute",npcs={2566}}},
      pts={{52.1,73},{53.6,75.4},{54.4,73.1}} },
  },
  [710] = {
    { name="Study of the Elements: Rock: Small Stone Shard", zone=3, r=20, loop=true,
      objs={{i=1,kind="drop",item=4626,name="Small Stone Shard",npcs={2735}}},
      pts={{19.1,45.8},{18.1,42.1},{21.3,44.2},{23.5,45.5},{21.6,47.9}} },
  },
  [733] = {
    { name="Scrounging: Scrap Metal", zone=3, r=15, loop=true,
      objs={{i=1,kind="drop",item=4630,name="Scrap Metal",npcs={2701,2715,2716,2717,2718,2719,2720,2906,2907}}},
      pts={{9.4,74.3},{8.7,77.4},{8.6,84.4},{7.5,90.4},{7.5,94.8},{9.4,90.4},{10.2,80.1},{13,74.6}} },
  },
  [743] = {
    { name="Dangers of the Windfury: Windfury Talon", zone=215, r=15, loop=true,
      objs={{i=1,kind="drop",item=4751,name="Windfury Talon",npcs={2962,2963}}},
      pts={{67,70.3},{65.5,70.6},{63.6,71.8},{62,71.6},{63.9,70.2},{66,68.8},{67.8,69.5},{67.7,71.6}} },
  },
  [747] = {
    { name="The Hunt Begins: Plainstrider Meat", zone=215, r=20, loop=true,
      objs={{i=1,kind="drop",item=4739,name="Plainstrider Meat",npcs={2955}},{i=2,kind="drop",item=4740,name="Plainstrider Feather",npcs={2955}}},
      pts={{47.9,77},{47.1,75.3},{50,74.7},{48.9,76.3}} },
  },
  [748] = {
    { name="Poison Water: Plainstrider Talon", zone=215, r=20, loop=true,
      objs={{i=2,kind="drop",item=4759,name="Plainstrider Talon",npcs={2955,2956,2957}}},
      pts={{47.9,77},{47.1,75.3},{50,74.7},{48.9,76.3}} },
  },
  [750] = {
    { name="The Hunt Continues: Mountain Cougar Pelt", zone=215, r=20, loop=true,
      objs={{i=1,kind="drop",item=4742,name="Mountain Cougar Pelt",npcs={2961}}},
      pts={{48.1,89.8},{47.6,92.2},{49.3,90.9},{50.8,89.4}} },
  },
  [757] = {
    { name="Rite of Strength: Bristleback Belt", zone=215, r=20, loop=true,
      objs={{i=1,kind="drop",item=4770,name="Bristleback Belt",npcs={2952,2953}}},
      pts={{59.5,78.9},{59.6,77},{60.2,75.4},{61.4,76.4}} },
  },
  [766] = {
    { name="Mazzranache: Plainstrider Scale", zone=215, r=20, loop=true,
      objs={{i=3,kind="drop",item=4806,name="Plainstrider Scale",npcs={2955,2956,2957}}},
      pts={{47.9,77},{47.1,75.3},{50,74.7},{48.9,76.3}} },
  },
  [780] = {
    { name="The Battleboars: Battleboar Snout", zone=215, r=15, loop=true,
      objs={{i=1,kind="drop",item=4848,name="Battleboar Snout",npcs={2954,2966}},{i=2,kind="drop",item=4849,name="Battleboar Flank",npcs={2954,2966}}},
      pts={{55.1,80.1},{54.4,81.9},{56,82}} },
  },
  [818] = {
    { name="A Solvent Spirit: Crawler Mucus", zone=14, r=15, loop=true,
      objs={{i=2,kind="drop",item=4888,name="Crawler Mucus",npcs={3106,3107,3108,3228}}},
      pts={{54.6,82},{52.8,83},{51.8,84},{54.4,83.3}} },
  },
  [821] = {
    { name="Chen's Empty Keg: Savannah Lion Tusk", zone=17, r=15, loop=true,
      objs={{i=1,kind="drop",item=4893,name="Savannah Lion Tusk",npcs={3241,3243,3415,3416,3425}}},
      pts={{55.1,30.6},{54.5,29.9},{54.9,29.3}} },
  },
  [835] = {
    { name="Securing the Lines: Dustwind Savage", zone=14, r=15, loop=true,
      objs={{i=1,kind="kill",name="Dustwind Savage",npcs={3117}}},
      pts={{53.8,24.5},{52.3,24},{53.8,22.3}} },
  },
  [867] = {
    { name="Harpy Raiders: Witchwing Talon", zone=17, r=20, loop=true,
      objs={{i=1,kind="drop",item=5064,name="Witchwing Talon",npcs={3276,3277,3278,3279,3280,3452}}},
      pts={{40.4,16.2},{38.8,17.2},{37.9,15.9},{38.4,13},{39.2,12.3},{38.9,14.7},{41,14.9}} },
  },
  [878] = {
    { name="Tribes at War: Bristleback Water Seeker", zone=17, r=15, loop=true,
      objs={{i=1,kind="kill",name="Bristleback Water Seeker",npcs={3260}}},
      pts={{47,53.6},{46.5,53.7},{47.2,52.9}} },
  },
  [887] = {
    { name="Southsea Freebooters: Southsea Cannoneer", zone=17, r=15, loop=true,
      objs={{i=2,kind="kill",name="Southsea Cannoneer",npcs={3382}}},
      pts={{63.6,46.3},{64.2,47.8},{64.3,47.1}} },
  },
  [896] = {
    { name="Miner's Fortune: Cats Eye Emerald", zone=17, r=20, loop=true,
      objs={{i=1,kind="drop",item=5097,name="Cats Eye Emerald",npcs={3283,3286,9336}}},
      pts={{60.7,3.8},{59.7,3},{60,3.8},{61.3,5.4},{62,5.4},{61.7,4.5},{61.9,3.7}} },
  },
  [899] = {
    { name="Consumed by Hatred: Bristleback Quilboar Tusk", zone=17, r=20, loop=true,
      objs={{i=1,kind="drop",item=5085,name="Bristleback Quilboar Tusk",npcs={3258,3260,3261,3263}}},
      pts={{51.2,55.4},{51.2,54.6},{52.8,52.2},{53.3,53.3},{53.4,54.3},{52.4,53.7}} },
  },
  [958] = {
    { name="Tools of the Highborne: Highborne Relic", zone=148, r=20, loop=true,
      objs={{i=1,kind="drop",item=5360,name="Highborne Relic",npcs={2176,2177,2178}}},
      pts={{41.9,58.9},{42.1,61.6},{43.2,62.7},{43.6,60.3},{42.9,58.2}} },
  },
  [970] = {
    { name="The Tower of Althalaxx: Glowing Soul Gem", zone=331, r=15, loop=true,
      objs={{i=1,kind="drop",item=5366,name="Glowing Soul Gem",npcs={3725,3727,3728,3730}}},
      pts={{31.8,29.7},{30.6,31.3},{31.6,31.2}} },
  },
  [977] = {
    { name="Are We There, Yeti?: Pristine Yeti Horn", zone=618, r=15, loop=true,
      objs={{i=1,kind="drop",item=12367,name="Pristine Yeti Horn",npcs={7459,7460}}},
      pts={{70.5,38.6},{70.7,37.6},{71.5,39.1}} },
  },
  [983] = {
    { name="Buzzbox 827: Crawler Leg", zone=148, r=20, loop=true,
      objs={{i=1,kind="drop",item=5385,name="Crawler Leg",npcs={2231,2232,2233,2234,2235,2236}}},
      pts={{35.5,50.1},{35.2,48},{35.6,46.6},{36.4,48.8}} },
  },
  [1008] = {
    { name="The Zoram Strand: Wrathtail Head", zone=331, r=20, loop=true,
      objs={{i=1,kind="drop",item=5490,name="Wrathtail Head",npcs={3711,3712,3713,3715,3717,3944}}},
      pts={{8.1,15.5},{6.9,15.4},{5.4,14.5},{6.3,11.4},{7.3,12.7}} },
  },
  [1105] = {
    { name="Hardened Shells: Hardened Tortoise Shell", zone=400, r=15, loop=true,
      objs={{i=1,kind="drop",item=5795,name="Hardened Tortoise Shell",npcs={4142,4143,4144}}},
      pts={{82.2,54.7},{81.5,53.1},{83.2,54.3}} },
  },
  [1366] = {
    { name="Centaur Bounty: Centaur Ear", zone=405, r=20, loop=true,
      objs={{i=1,kind="drop",item=6067,name="Centaur Ear",npcs={4632,4633,4634,4635,4636,4637,4638,4639,4640,4641,4642,4643}}},
      pts={{74.2,47.4},{72.8,46.7},{74,50.1}} },
  },
  [1387] = {
    { name="Centaur Bounty: Centaur Ear", zone=405, r=20, loop=true,
      objs={{i=1,kind="drop",item=6067,name="Centaur Ear",npcs={4632,4633,4634,4635,4636,4637,4638,4639,4640,4641,4642,4643}}},
      pts={{74.2,47.4},{72.8,46.7},{74,50.1}} },
  },
  [1456] = {
    { name="The Karnitol Shipwreck: Karnitol's Satchel", zone=405, r=15, loop=true,
      objs={{i=1,kind="drop",item=6245,name="Karnitol's Satchel",npcs={4716,4719}}},
      pts={{28.3,9.3},{28.8,11.6},{30.5,10.6}} },
  },
  [1458] = {
    { name="Reagents for Reclaimers Inc.: Hatefury Claw", zone=405, r=20, loop=true,
      objs={{i=1,kind="drop",item=6246,name="Hatefury Claw",npcs={4670,4671,4672,4673,4674,4675}},{i=2,kind="drop",item=6247,name="Hatefury Horn",npcs={4670,4671,4672,4673,4674,4675}}},
      pts={{78.7,22.1},{74.3,23.4},{76.8,24.3}} },
  },
  [1470] = {
    { name="Piercing the Veil: Rattlecage Skull", zone=85, r=15, loop=true,
      objs={{i=1,kind="drop",item=6281,name="Rattlecage Skull",npcs={1890}}},
      pts={{32.7,59.9},{31.7,61.1},{33.5,62}} },
  },
  [1525] = {
    { name="Call of Fire: Fire Tar", zone=17, r=15, loop=true,
      objs={{i=1,kind="drop",item=5026,name="Fire Tar",npcs={3267,3268,3269,3271}}},
      pts={{55.6,26.9},{55,26.9},{55.7,26.1}} },
  },
  [2258] = {
    { name="Badlands Reagent Run: Rock Elemental Shard", zone=3, r=20, loop=true,
      objs={{i=3,kind="drop",item=7848,name="Rock Elemental Shard",npcs={92,2735,2736,2791}}},
      pts={{19.1,45.8},{18.1,42.1},{21.3,44.2},{23.5,45.5},{21.6,47.9}} },
  },
  [2869] = {
    { name="Against the Hatecrest: Hatecrest Naga Scale", zone=357, r=20, loop=true,
      objs={{i=1,kind="drop",item=9247,name="Hatecrest Naga Scale",npcs={5331,5332,5333,5334,5335,5336,5337,8136}}},
      pts={{27.3,68.5},{25.5,66.4},{26.4,68.3},{27.3,69.8},{28.2,70.3},{28.1,68.2}} },
  },
  [2877] = {
    { name="Skulk Rock Clean-up: Green Sludge", zone=47, r=15, loop=true,
      objs={{i=1,kind="kill",name="Green Sludge",npcs={2655}}},
      pts={{45.8,43},{45.8,40.7},{47.7,41.6}} },
  },
  [2880] = {
    { name="Troll Necklace Bounty: Troll Tribal Necklace", zone=47, r=20, loop=true,
      objs={{i=1,kind="drop",item=9259,name="Troll Tribal Necklace",npcs={2639,2640,2641,2642,2643,2644,2645,2646,2647,2648,2649,2650}}},
      pts={{68.2,71.3},{65.5,70.4},{61.4,68.5},{63.1,72},{65.6,74.7},{67.6,76.7}} },
  },
  [2974] = {
    { name="A Grim Discovery: Grimtotem Horn", zone=357, r=15, loop=true,
      objs={{i=1,kind="drop",item=9460,name="Grimtotem Horn",npcs={7725,7726,7727}}},
      pts={{69.8,38.7},{68.9,38.8},{69.1,40.3}} },
  },
  [3452] = {
    { name="The Flame's Casing: Symbol of Ragnaros", zone=51, r=20, loop=true,
      objs={{i=1,kind="drop",item=10552,name="Symbol of Ragnaros",npcs={5860,5861,5862,8419}}},
      pts={{24.2,35.5},{16.9,34.3},{19.5,36.9},{23.5,39.7}} },
  },
  [3901] = {
    { name="Rattling the Rattlecages: Rattlecage Skeleton", zone=85, r=15, loop=true,
      objs={{i=1,kind="kill",name="Rattlecage Skeleton",npcs={1890}}},
      pts={{32.7,59.9},{31.7,61.1},{33.5,62}} },
  },
  [4101] = {
    { name="Cleansing Felwood: Blood Amber", zone=361, r=20, loop=true,
      objs={{i=1,kind="drop",item=11503,name="Blood Amber",npcs={7100,7101}}},
      pts={{55.5,17.3},{57,17.7},{58.1,18.6},{57.3,19.7}} },
  },
  [4102] = {
    { name="Cleansing Felwood: Blood Amber", zone=361, r=20, loop=true,
      objs={{i=1,kind="drop",item=11503,name="Blood Amber",npcs={7100,7101}}},
      pts={{55.5,17.3},{57,17.7},{58.1,18.6},{57.3,19.7}} },
  },
  [4841] = {
    { name="Pacify the Centaur: Galak Scout", zone=400, r=15, loop=true,
      objs={{i=1,kind="kill",name="Galak Scout",npcs={4094}}},
      pts={{41,36.2},{39.3,36.9},{40.1,34.9}} },
    { name="Pacify the Centaur: Galak Windchaser", zone=400, r=15, loop=true,
      objs={{i=3,kind="kill",name="Galak Windchaser",npcs={4096}}},
      pts={{42.6,38.4},{41.6,40.8},{41.5,38.9},{42.8,36.5}} },
  },
  [5092] = {
    { name="Clear the Way: Skeletal Flayer", zone=28, r=20, loop=true,
      objs={{i=1,kind="kill",name="Skeletal Flayer",npcs={1783}}},
      pts={{38.2,55.4},{36.3,56.6},{37.4,58.6}} },
    { name="Clear the Way: Slavering Ghoul", zone=28, r=15, loop=true,
      objs={{i=2,kind="kill",name="Slavering Ghoul",npcs={1791}}},
      pts={{38.5,55},{37.2,54.2},{37.2,56.9}} },
  },
  [6161] = {
    { name="Claim Rackmore's Treasure!: Rackmore's Golden Key", zone=405, r=20, loop=true,
      objs={{i=2,kind="drop",item=15881,name="Rackmore's Golden Key",npcs={4711,4712,4713,4714,4715,4716,4718,4719}}},
      pts={{28.3,7.1},{27.9,9.7},{29.3,11.9},{30.3,8.8}} },
  },
  [6441] = {
    { name="Satyr Horns: Satyr Horns", zone=331, r=20, loop=true,
      objs={{i=1,kind="drop",item=5481,name="Satyr Horns",npcs={3752,3754,3755,3757,3758,3759,3762,3763,3765,3767,3770,3771}}},
      pts={{66.9,56.2},{66.5,54.3},{66.5,52.1},{68.4,53.7}} },
  },
  [7844] = {
    { name="Cannibalistic Cousins: Vilebranch Soothsayer", zone=47, r=15, loop=true,
      objs={{i=2,kind="kill",name="Vilebranch Soothsayer",npcs={4467}}},
      pts={{47.5,66.8},{48.4,65},{48.9,68.4}} },
  },
  [8365] = {
    { name="Pirate Hats Ahoy!: Southsea Pirate Hat", zone=440, r=20, loop=true,
      objs={{i=1,kind="drop",item=20519,name="Southsea Pirate Hat",npcs={7855,7856,7857,7858,7883}}},
      pts={{72.2,47.2},{71.4,43.4},{72.9,45.6},{75.8,45.4},{74.1,47.6}} },
  },
}
