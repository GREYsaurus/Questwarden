# Changelog

## Unreleased

- **Steps no longer say "unverified".** Steps with hand-placed coordinates, such as Ulag the Cleaver at the Brill crypt, showed it in orange under the step text. It only meant the spot came from the guide rather than the quest database, so the label is gone from the game; the audit tools still track it.
- **Setup wizard:** the author's note now opens with a warning, in the warning colour, that the routes are not perfect and are constantly being improved.

## 0.1.0-alpha.35 (2026-11-02)

- **The Admiral's Orders step now says where the Aged Envelope comes from.** It points to Benedict's Chest in Tiragarde Keep and says to open it with the key Lieutenant Benedict drops. The step no longer appears in the Tirisfal Glades or Eversong Forest guides, because the envelope can't be found there.
- **Class quests that teach spells are now in the Classic Era and Forever guides,** at the level they open and at places the route already visits. Each step shows only for the classes and races that can take it. The list comes from the quests that reward a spell in the CMaNGOS quest data.
  - Level 10–12: Undead warriors get Defensive Stance in Brill (Ulag the Cleaver), and dwarf and gnome warriors get it in Ironforge (Vejrek). Undead and gnome warlocks get Summon Voidwalker. Dwarf hunters get the Kharanos taming quests, and dwarf and tauren hunters get Beast Training. Paladins get Redemption (human in Stormwind and Elwynn, dwarf in Ironforge and Dun Morogh). The level-10 priest racial spells (Touch of Weakness, Hex of Weakness, Desperate Prayer for dwarves, Starshards) are in too.
  - Level 14–20: druids get Cure Poison and Aquatic Form, and level 20 brings Summon Succubus, rogue Poisons and the priest racial spells (Devouring Plague, Shadowguard, Feedback, Fear Ward, Elune's Grace). The Horde gets a level-20 class stop in Orgrimmar for these.
  - Level 30–50: Berserker Stance (Alliance warriors too), shaman Call of Water and Call of Air, Summon Felhunter, the level-40 Felsteed and paladin Warhorse, and an optional Inferno chain in Felwood.
  - Removed or fixed broken class steps: Speak with Dillinger in the Mulgore and Barrens guides, Call of Water in Stonetalon without the quests before it, News of Dogran before its prerequisite, and Forged Steel before Thun'grim Firegaze.
  - `tools/research/class_quests.py` lists the class quests no guide has.
- **Optional steps** now say what optional means: the route works without the quest, so do it for the experience and reward, or right-click the step to skip it.
- **Quest rewards:** the reward ranking no longer goes to chat. The green arrow or coin on the reward window still marks the pick. It is turned off once for everyone, and you can turn it back on with Quest Reward Recommendation (Item Upgrade settings).
- **Setup wizard:** the first page has a note from the author: the routes are still being improved, thanks for trying the add-on, and please report problems and suggestions on the CurseForge page.
- **Fixed:** seven kill-step notes named the wrong mobs, for example Greater Duskbats for A New Plague (it needs Vicious Night Web Spiders), Scarlet Zealots for At War With The Scarlet Crusade (Captain Vachon and Scarlet Friars), and Durotar Tigers for Lost But Not Forgotten (Dreadmaw Crocolisks). The others were in Darkshore, Duskwood, Stranglethorn Vale and Felwood. The notes now name the mobs the quest needs.
- **Guides set your hearthstone after the starting zones.** Before, only the six starting-zone guides had a "set your hearthstone" step, so hearth suggestions stopped after level 10 or so. 25 guides now set it at the town you keep walking back to: Horde at the Crossroads, Ratchet, Sun Rock Retreat, Tarren Mill, Booty Bay, Hammerfall, Grom'gol, Gadgetzan, Camp Mojache, Revantusk Village and Cenarion Hold; Alliance at Auberdine, Astranaar, Menethil Harbor, Darkshire, Booty Bay, Theramore, Nijel's Point, Gadgetzan and Feathermoon Stronghold. `tools/research/hearth_spots.py` lists the long walks back to town and the towns with an inn that would cut them.
- **Hearthstone suggestions** show for shorter trips back to town. Hearthing now has to save 3 minutes for one turn-in, 90 seconds for two, and a minute for three or more. Before, it was 5 minutes, 2.5 minutes and 100 seconds. For example, walking back to Brill from the Tirisfal coast with two turn-ins now gets the suggestion.
- **Active item window:** an item that starts a quest you have not taken, such as A Letter to Yvette, now gets the first button. Clicking it opens the quest, the same as right-clicking it in your bags. The button goes away once the quest is in your log, and the guide step points you to the button.
- **Talent window:** the next talent to take is easier to spot. It has a larger gold glow that pulses while you have a point to spend, and the bottom tab of its tree is highlighted with a "1". Each suggested talent shows the levels at which to put its points, with levels you have already reached shown as "now". The panel and tooltips also no longer name a level you have passed.
- **Fixed:** automatic raid markers could stop for the rest of a kill step. A mark was checked 0.4 seconds after it was set, so a slow server or a mob killed in that moment counted as a failure, and two failures paused marking without a word. The icon now gets a second look, a dead mob is no failure, and when marking does pause, chat says why.
- **Fixed:** the waypoint diamond on the world map was drawn away from the waypoint (further right and down the more the map was zoomed out), so it did not match the minimap pin and the arrow. Its position now ignores its own size scaling.

**Tested:** offline only (TBC suite 5,702/5,702, Classic Era smoke 93/93, Forever 34/34, route audits 0 errors; Forever's 6 known data errors are reported only). Not checked in the live game.

## 0.1.0-alpha.34 (2026-11-01)

- **Low durability warning** (on; Settings → Low Durability Warning): when equipped gear drops below 30% durability, a red on-screen message says how many pieces are below 30%, with the raid warning sound. It repeats only when another piece drops below.
- **Class tips wait for their level.** A tip that names a spell or quest level ("Overpower (12)", "at 10") is held until you reach it; the next tip that fits comes instead. Tips already shown are kept.
- The quest log's **Orphaned** button sits under *Abandon Quest* instead of at the top right.

**Tested:** offline only (TBC suite 5,686/5,686, Classic Era smoke 93/93, Forever 34/34, route audits 0 errors; Forever's 6 known data errors are reported only). Not checked in the live game.

## 0.1.0-alpha.33 (2026-11-01)

- **Quests done in the same place are done together (Classic Era and Forever):**
  - Tirisfal Glades (also TBC): *Doom Weed* is picked up in Brill and gathered among the Rot Hide gnolls while you do *Graverobbers*.
  - Teldrassil: *Timberling Sprouts* with *Timberling Seeds* at Lake Al'Ameth.
  - Tanaris (both factions): *The Dunemaul Compound* while you dig for *Gahz'ridian* at the compound, and *Thistleshrub Valley* with *The Thirsty Goblin*'s dew collectors.
  - Feralas: *Stinglasher* in the Zukk'ash hive with *Zukk'ash Infestation*.
  - The new report `tools/research/pack_misses.py` lists such pairs, including quests you can pick up before the earlier step.
- **Fixed:** Hillsbrad Foothills (Horde) turned in *Souvenirs of Death* before the skulls were collected; the turn-in now comes after.
- **Bigger bags are equipped automatically** (part of automatic upgrades; *Equip bigger bags*, on). A plain bag that isn't unbound Bind-on-Equip goes into an empty bag slot. When all four slots are full, it replaces your smallest bag if it has more slots: that bag's items are moved to your other bags first, and nothing happens if they don't fit. Profession and soul bags are left alone.

**Tested:** offline only (TBC suite 5,659/5,659, Classic Era smoke 93/93, Forever 34/34, route audits 0 errors; Forever's 6 known data errors are reported only). Not checked in the live game.

## 0.1.0-alpha.32 (2026-11-01)

- **Quests from objects:** when a quest is picked up from, or handed in at, an object instead of an NPC (a wanted poster, a notice board, a grave), the step says so and what to do: for example, "Wanted! is not an NPC but a wanted poster, on a post or board. Right-click it to read the quest, then press Accept."
- **Tirisfal Glades (Undead start):** the 10 pumpkins for *Fields of Grief* are now collected at Solliden Farmstead together with the Scarlet Warriors for *At War With The Scarlet Crusade*. Before, the guide had no step for them, and the later step that named the pumpkins was the delivery quest. *Wanted: Maggot Eye* (a level 11 mob) moves from about level 6 to the end of the zone, at about level 10, after the Agamand Mills quests.
- **Hard quests come later (Classic Era and Forever).** Quests whose targets are well above your level at that point now come after easier ones:
  - Durotar: *Sarkoth* after *Cutting Teeth*; *Vanquish the Betrayers* after the level 6 grind; *Dark Storms*, with Skull Rock after it, at the end of Durotar near level 12.
  - The Barrens: *The Guns of Northwatch* and *Free From the Hold* (level 20) moved from visit 2 (about level 16) to the start of visit 3 (level 22, from Ratchet).
  - Wetlands: *The Cursed Crew* (level 29) moved to visit 2, just before *Lifting the Curse*, which follows it.
  - Where a quest cannot move without an extra trip, the step now names the target's level: *Supervisor Fizsprocket*, *Ursal the Mauler*, *Steelsnap*, *Breaking the Keystone* (Fozruk, 42) and *Dark Heart*.
  - The report `tools/research/quest_level_report.py` lists such steps per target.
- ***Skip overleveled steps* is off by default.** Saved profiles are switched off once. A quest that is complete in your log is always turned in, whatever its level.
- **Removed:** the indoors and outdoors hints ("You are indoors: the arrow shows only the direction", "find the way out", "may be inside"), which did not work reliably in the game, and the indoor spots they learned. The capital city hints stay.
- **Removed:** the chat line "Arrow points to your corpse".

**Tested:** offline only (TBC suite 5,628/5,628, Classic Era smoke 93/93, Forever 34/34, route audits 0 errors; Forever's 6 known data errors are reported only). The guide changes were not played through in the live game. The author checked in the game that patrol paths are drawn and followed (docs/PATROLS.md).

## 0.1.0-alpha.31 (2026-11-01)

- **Forever (not shipped yet):** trainer spell lists imported from the Forever client tables, and the Forever talent trees (27 trees, 466 talents) taken from the wowforevertalents.com calculator, which reads the launch client's talent hotfixes. The client's own tables still hold Classic Era's trees, so they are no longer imported for Forever. Talents with no known spell show their icon in the talent window. All unverified until checked in the game.
- **New-player tips open in a window** you close with **OK**, instead of chat: step explanations, the useful keys, full bags, first death, talent points, new spells, class tips and profession advice. They come one at a time (OK says how many more are waiting) and wait until a fight is over. *Show tips in a window* (Tips → New Players, on by default) switches back to chat.
- ***Notify on new target* is off by default:** the "<NPC> from your current step is nearby" chat line no longer shows unless you turn it on (Settings → Targeting). Saved profiles are switched off once.
- **Fixed:** the arrow went to the place an objective is done before you had the item it needs. For example, *Marla's Last Wish* pointed at Marla's Grave before you had Samuel's Remains from Samuel Fipps. The arrow now goes to where the item drops first, then to the objective once it is in your bags. This affects every quest whose objective needs an item that is not an objective itself (about 120 to 150 quests per game version).
- **Fixed:** collect quests sent you to a named NPC that the next quest in the chain needs. For example, *The Scarlet Crusade* counted Meven Korgal as an armband target, though *The Red Messenger* is to kill him. Such NPCs are now left out of the arrow, the target lists and the hunting routes while other mobs drop the item (Meven Korgal in Tirisfal Glades, Lord Shalzaru in Feralas).
- **Death skip suggestions:** when the next step is in town and the graveyard you would land at is much nearer it than you are, the step suggests dying to a mob and taking the spirit healer's resurrection. Below level 10, where there is no resurrection sickness, when it saves a minute or more; from level 10 only when it saves 5 minutes or more. Never on Hardcore characters, and never while a hearthstone suggestion shows. *Death Skip Suggestions* (General → Automation, on by default).

**Tested:** offline only (TBC suite 5,636/5,636, Classic Era smoke 93/93, Forever 34/34, route audits 0 errors; Forever's 6 known data errors are reported only). In the live game, the author checked several times that settings are kept after /reload, and that the new-player tip windows work; the other new features are not checked in game yet.

## 0.1.0-alpha.30 (2026-11-01)

- **Fixed:** an upgrade over an equipped item that scores 0 for your spec profile (for example boots with no armor, against boots with armor under Protection) was not equipped when *Minimum upgrade* was above 0%, because no percentage can be worked out from 0. Any gain over 0 now clears the minimum. The auction house Upgrades tab's *Min upgrade %* filter keeps these items too.

**Tested:** the fix was checked in the live game by the author. Offline: TBC suite 5,574/5,574, Classic Era smoke 93/93, Forever 31/31, route audits 0 errors.

## 0.1.0-alpha.29 (2026-11-01)

- **Setup now sets your spec for gear.** The gear profile that follows the talent plan is the spec profile of the plan's tree (leveling first, then pre-raid, then raid), so *Spec profile* in the settings is filled in and automatic upgrades can work. Before, most classes got *Automatic*, because only a few trees have a leveling profile, and Druid's "Feral Combat" did not match the gear profiles' "Feral". New players who choose to tank get the tank profile where there is one. Classes with no spec profile for the tree still get *Automatic* (for example Classic Era Hunters, Rogues, Mages and Warlocks).
- **The new-player setup asks about automatic upgrades** on the talents page: *Put on better gear automatically?*, off unless ticked.
- **Quest reward upgrades are on for everyone:** the reward choices are ranked in chat (*Quest Reward Recommendation*) and marked on the reward panel. Saved profiles are switched on once. You still choose the reward yourself, unless *Quest Reward Automation* is on.

**Tested:** offline only (TBC suite 5,573/5,573, Classic Era smoke 93/93, Forever 31/31, route audits 0 errors). Not checked in the live game.

## 0.1.0-alpha.28 (2026-11-01)

- **Fixed:** the on/off switches in the settings window did not move when clicked, so they looked like they did nothing (the setting itself did change).

**Tested:** the fix was checked in the live game by the author. Offline: TBC suite 5,481/5,481, Classic Era smoke 93/93, Forever 31/31, route audits 0 errors.

## 0.1.0-alpha.27 (2026-11-01)

- **Help for players new to World of Warcraft.** All off by default; turn them on in the setup wizard's new *Helpers* page or in the settings (docs/NEW_PLAYERS.md):
  - **Explain steps and the basics** (Tips → New Players): the first time each kind of step comes up, one chat line says what to do and which key opens what. Also full bags, your first death and talent points. `/qw newplayer reset` shows them again.
  - **Coach new spells:** when you learn a spell, what it does (the game's own text) and, if it is not on your action bars, how to put it there; every 4 levels, a leveling tip for your class.
  - **Profession starter tips:** at level 5, which professions suit a new character and the trainers nearby. `/qw professions [name]`.
  - **Mount savings goal** (Classic Era and TBC): from 10 levels before riding, your first mount's price against your gold, under the current step. Prices from Warcraft Tavern. `/qw mount`.
  - **Session recap:** at login, one line about your last session: time, levels, quests, zones, deaths and gold. `/qw recap`.
  - **Play together** (Communications): party members running Questwarden see where each other are in the guide, with "Wait for <name>" when someone still has to pick up or turn in. *Follow the party leader's step* keeps everyone on the leader's step; `/qw follow` does it once.
  - **Simple settings view** (General): hides the Advanced Settings and Profiles tabs and rarely needed options.
- **A more modern look.** Every change is to how things look; what they do is the same.
  - **Guide window:** the current step is a card with an accent bar, a larger icon and, on kill and collect steps, a bar with the objectives' progress. Upcoming steps are quieter (dimmed, grey icons), and the step fades in when it changes. The progress line under the header is thinner; the percentage is in the header and the step count in its tooltip.
  - **Settings window:** the tabs are a sidebar, with a **search box** that finds options on every tab by name or tooltip. On/off options are switches.
  - **Setup wizard:** choices are cards (accent border on the chosen one), a segmented bar shows how far along you are, pages fade in, and the first page has a title.
  - **Accent Colour** (General, Window): blue (default), teal, green, purple, gold or red, after `/reload`. Windows have a soft shadow.
- **Clean-up:** the colours of the setup wizard, settings window, talent window, Active Targets and gear tooltips now come from the shared theme (`W.THEME`: new `good`, `gold`, `warn` and `bad` entries), so some shades are slightly different. Junk handling moved from `Core/Assist.lua` into `Core/Junk.lua` without changing what it does. `THIRD_PARTY_LICENSES.md` now says correctly that the talent plans are Icy Veins' talent allocations (facts, not guide text).
- **The setup wizard asks first whether you are new to World of Warcraft.** New players get six pages in plain words: the talents page asks whether they want to tank, heal or deal damage (or don't know yet) and suggests a talent plan for it, and the dungeons page explains dungeons and picks the recommended ones (those the guides have quests for), so new players learn to run them. No leveling-mode or training choices; those keep their defaults. Experienced players get every page as before. Both end with the Helpers page.

**Tested:** offline only (TBC suite 5,480/5,480, Classic Era smoke 93/93, Forever 31/31, route audits 0 errors). Not checked in the live game.

## 0.1.0-alpha.26 (2026-11-01)

- **Fixed: the CurseForge app could not install Questwarden** ("Mod is not supported by the application"). The download now also holds a plain `Questwarden.toc`, a copy of the Classic Era one, because the app needs a TOC named like the add-on folder. Classic Era and TBC still load their own TOC (`Questwarden_Vanilla.toc`, `Questwarden_TBC.toc`).

**Tested:** offline only (TBC suite 5,168/5,168, Classic Era smoke 93/93, Forever 31/31, route audits 0 errors). Not checked in the live game.

## 0.1.0-alpha.25 (2026-11-01)

- **Fixed: the arrow for a kill pack led away from where its mobs meet.** While two or more steps of a kill pack are open, the arrow now points at the spot where all their mobs spawn, instead of following the first step's hunting route. Example: Stocking Jetsteam and The Grizzled Den in Dun Morogh now lead to the wendigo cave (about 43, 56.5), where boars and wendigos meet, not to the boars about 1,000 yards west. A hunting route of a pack step that never comes within 8 map percent of the pack's spot is no longer used for it, even after the other steps are done; the arrow then shows the nearest spawn. The new `tools/research/pack_spots.py` checks every guide: 30 such routes in Classic Era and 25 in TBC were affected.

**Tested:** offline only (TBC suite 5,168/5,168, Classic Era smoke 93/93, Forever 31/31, route audits 0 errors). Not checked in the live game.

## 0.1.0-alpha.24 (2026-11-01)

- **Fixed: item quests pointed at mobs far above the quest's level.** When ordinary mobs near the quest's level drop a quest item, the arrow, raid markers, target list and patrol hints now leave out the rares, elites and mobs more than 3 levels higher that drop it too. Example: The Grizzled Den now sends you to Young Wendigos and Wendigos, not Edan the Howler (rare, level 9) or the level 11 elites Old Icebeard and Vagash. The same goes for every guide: 132 item objectives in Classic Era and 136 in TBC had such droppers (for example Chunk of Boar Meat for Stocking Jetsteam no longer lists the level 10-16 boars of other zones). When no ordinary mob near the level drops an item, all droppers still count.

**Tested:** offline only (TBC suite 5,153/5,153, Classic Era smoke 93/93, Forever 31/31, route audits 0 errors). Not checked in the live game.

## 0.1.0-alpha.23 (2026-11-01)

- **Timed quests.** Questwarden now knows the 29 timed quests of Classic Era and the 40 of TBC, with their time limits (from the CMaNGOS quest tables).
  - **Warning before you accept.** The pickup step says how long you will have, and when the quest's window opens a warning shows on screen and in chat. Timed quests are never accepted automatically: you choose when the clock starts. Turn the warning off with *Warn Before Timed Quests* (General, Features).
  - **Timer.** While a timed quest is in your log, a bar shows the time left (red under a minute, "failed" when it ran out), and its objective and turn-in steps show it too. Turn the bar off with *Show Timed Quest Timers*. The time comes from the game when it is clear which quest a timer belongs to, otherwise it is counted from when you accepted.
  - **Turned in first.** The guides now go from a timed quest's pickup straight to its objective and turn-in. Only turn-ins on the way stay in between, and only while the estimated walk stays within half the limit. Where possible the pickup moved down instead, so the clock starts later. 10 guides changed in Classic Era and 7 in TBC. Examples: Apothecary Zamah (Barrens) is now picked up on your last stop at the Crossroads and taken straight to Thunder Bluff; Mist (TBC Teldrassil) is turned in right after the escort instead of 51 steps later; MacKreel's Moonshine (TBC Wetlands) is picked up on the way out to Southshore. Saved progress follows the moved steps.
  - If you take a timed quest out of the guide's order, the guide puts its next step first anyway, unless only turn-ins and travel lie before it.
- **Fixed: the arrow stayed on an objective you already finished.** On quests with several objectives in different places, the arrow now leaves out what your log shows done and goes to the nearest objective still open, as soon as you loot or kill. Example: A Refugee's Quandary, where Felix's Box, Chest and Bucket of Bolts lie in three places. This works in every guide (226 such quests in Classic Era, 352 in TBC).
- **Fixed: innkeepers were not marked.** The innkeeper of a "Set your Hearthstone" step now gets a raid marker and is in the target list, like quest NPCs. So does the NPC a flight-path, vendor or talk step names.
- **Vendor treasures: arrows instead of a chat list.** Merchant items that are upgrades for your spec now get the same large green arrow as quest rewards, and nothing is printed in chat.

**Tested:** offline only (TBC suite 5,150/5,150, Classic Era smoke 93/93, Forever 31/31, route audits 0 errors). Not checked in the live game.

## 0.1.0-alpha.22 (2026-11-01)

- **Nearest quest giver first.** Where the guide lists several pickups and turn-ins in a row, it now sends you to the nearest NPC first instead of walking past one and coming back. Example: a new dwarf or gnome now starts with Sten Stoutarm's Dwarven Outfitters, right where you appear, then The Boar Hunter farther west. 88 such stretches were reordered in Classic Era and 103 in TBC, in every zone.
  - Pickups stay after the turn-ins of their prerequisites, and turn-ins after their pickups.
  - A pickup you may not have the level for yet stays after the turn-ins before it, whose XP may get you there. This also fixes two pickups the route model reached just below their level (Rejold's New Brew in Dun Morogh, Deep Ocean, Vast Sea in Darkshore).
  - Saved progress follows the moved steps.
- **Fixed: mobs marked for a quest you haven't picked up.** Kill-pack steps whose quest is not in your log no longer show as current, and their mobs are not marked or targeted (example: boars before you accept The Boar Hunter).
- **Fixed: finished objectives still marked.** Once your quest log shows an objective done, its mobs stop being marked and targeted, while the quest's other objectives stay (example: Rockjaw Troggs after 6/6 in A New Threat, while Burly Rockjaw Troggs are still needed). A collected item objective drops its droppers the same way.
- **Quest reward markers: bigger, and only the best upgrade.** The green arrow is now larger, points up, and sits only on the choice that is the biggest upgrade. The coin for the most valuable choice (when none is an upgrade) is larger too.

**Tested:** offline only (TBC suite 5,099/5,099, Classic Era smoke 93/93, Forever 31/31, route audits 0 errors). Not checked in the live game.

## 0.1.0-alpha.21 (2026-11-01)

- **Quest reward markers.** On a quest's reward panel, a green arrow (the same one as on bag upgrades) marks each reward choice that is an upgrade for your spec profile. When none is, a coin marks the choice that sells for the most at a vendor. They show when you read the quest and when you turn it in. Turn them off with *Mark quest reward choices* (Item Upgrade settings, on by default).
- **Fixed: "Choose your reward" printed twice.** The client can fire its reward event twice for one panel; the message now shows once.
- **Kill packs: kill and drop quests in the same area are done together.** When the mobs of several quests in your log spawn in the same area, their objective steps now show together as current, so you kill them all in one trip. Examples: Dwarven Outfitters and The Boar Hunter in Dun Morogh; the four Un'Goro quests that join Beware of Pterrordax on the Classic Era Horde route.
  - **Any number of quests.** A pack holds as many quests as share the area: up to 7 in Classic Era and 8 in TBC.
  - **Drop quests count too:** a quest whose items drop from mobs joins by those mobs.
  - **Targets, macro and raid markers** cover the mobs of every open step of the pack. Each step gets its own icon, so a pack can use all eight icons, not just the usual four. The 255-character macro limit still applies.
  - **Finishing one step** of a pack leaves the others current. The arrow still points at the first open one.
  - **The guides were reordered for this.** 39 Classic Era steps and 94 TBC steps moved next to the steps they overlap with. That gives 100 packs in Classic Era and 184 in TBC. Saved progress follows the moved steps. The route model's XP and levels are unchanged, as the quests are the same.

**Tested:** offline only (TBC suite 5,086/5,086, Classic Era smoke 93/93, Forever 31/31, route audits 0 errors). Not checked in the live game.

## 0.1.0-alpha.20 (2026-11-01)

- **Quests started by dropped items.** A pickup whose quest starts from an item now knows the item, the mobs that drop it (from the data) and the later kill steps of the guide where those mobs are. Without the item the guide does those kill steps first and their step says the mobs can drop it. When the item is in your bags the guide comes back to the pickup: "Use [item] to accept ...". If the kill steps are behind you and there is still no item, the pickup asks you to get it from the droppers, with the arrow on the nearest one, or to skip. The quest's objective and turn-in steps wait with the pickup. Having the item or opening its quest window is not acceptance. A skipped pickup counts as done if you take the quest later. Completionist now routes these quests: at the nearest dropper, after the zone's other objectives. A skipped one is kept out until the item is in your bags. No drop rates are claimed. Details: docs/ITEM_STARTS.md.
- **More quests in the speed guides: item-started quests that fill leveling gaps.** These quests start from an item that one named mob drops, or that the mobs the guide already sends you to kill drop. 7 were added to the Classic Era guides and 24 to the TBC guides (15 of them in Outland). Each pickup goes right before the guide's steps that kill the droppers, or near the named mob. Examples: The Harvester (Barrens), Noboru the Cudgel (Swamp of Sorrows), Flute of Xavaric (Felwood), the four Netherstorm named-mob quests. Escorts, elite droppers and turn-ins in other zones were left out. The route model's grinding drops from 50.9 to 50.4 levels in Classic Era and from 54.8 to 53.8 in TBC.
- **More item quests, turned in elsewhere where needed.** A second batch lets an item quest be turned in later in the route, in another zone (the pickup says where), and no longer waits for the required level: below it, the pickup is skipped with "needs level N" as usual. This adds The Key to Freedom and Winterfall Ritual Totem to Classic Era, and 6 quests to TBC (among them Captain Sander's Hidden Treasure and Drain Schematics). Grinding in the route model is now 50.3 levels in Classic Era and 53.5 in TBC. When some droppers of an item are elite and others aren't, the step now points only at the non-elite ones.
- **Item quests that appear only if you find the item.** A new `[iffound]` guide flag marks these steps. They stay hidden, and aren't counted, until the item is in your bags or the quest is in your log. Then the pickup appears with "Use [item] to accept ...", and the objective and turn-in follow once you take it. Added for items dozens of kinds of mob drop, which a guide can't send you to farm: the OOX distress beacons, the Pendant of Myzrael and Brann Bronzebeard's Lost Letter in both games, plus 7 more TBC quests (for example A Strange Red Key and Missing Missive). In total, 5 quests in Classic Era and 12 in TBC, in each faction's guides.
- **Speed-guide optimization run: more quests, and grind steps that send you to dense spawns.**
  - **More quests.** Classic Era gets 15 more quests (14 of them follow-ups in quest chains, such as A Strange Historian, The Broken Sigil and Horde Presence). TBC gets about 220 more, in guides that still needed grinding:
    - single quests near the route;
    - chain follow-ups;
    - 22 unused quests in Silverpine, Westfall, Loch Modan, Ashenvale and Hillsbrad.
  - **Less grinding in the route model.** Classic Era goes from 50.3 to 50.0 levels and TBC from 53.5 to 40.1. Classic Era zones on the route have almost no usable quests left.
  - **Grind steps.** Where the model still arrives three-quarters of a level or more short of a guide's closing level check, that check becomes a grind step: 22 in Classic Era and 23 in TBC. Each one:
    - names non-elite mobs near your level;
    - points at the densest cluster of their spawns near the guide's last steps.
  - **Partial-level targets.** When that spot is passed before the guide's last quests, the step asks only for part of a level ("until level 16 (20% through)"), and those quests finish the job. The new `grind 16.2` form is how a guide writes this.
  - **Smaller shortfalls** keep their plain level check, because the model counts no rested or discovery XP.
- **Auto repair (opt-in).** A new *Auto Repair* setting next to *Auto Sell Junk*, off by default. At a merchant who can repair, it repairs all your gear with your own money (never guild funds), after any junk is sold, and only when you can pay the whole bill. One chat line says what it cost, or what it would cost when you cannot pay. Hold Shift to skip.
- **README and CurseForge description** rewritten for the current alpha.

**Tested:** offline only (TBC suite 5,048/5,048, Classic Era smoke 93/93, Forever 31/31, route audits 0 errors). Not checked in the live game.

## 0.1.0-alpha.19 (2026-11-01)

- **Hearthstone suggestions.** When your hearthstone is off cooldown and the next steps turn in quests in the town it is set to, the step says when hearthing beats walking: "Hearthstone ready: hearth to Goldshire for 3 turn-ins there; saves about 4 min over walking." The fewer the turn-ins, the more it has to save (5 minutes for one, 2.5 for two, never under a minute), because the hearthstone has a long cooldown. Walking time uses the straight line, a margin for roads and your run speed (mounted if you are); hearthing counts the cast, a loading screen and the walk from the inn. The inn is where you last set the hearthstone or landed after hearthing, else the innkeeper of the guide's bind step. Only a suggestion: it never uses the hearthstone. New setting *Hearthstone Suggestions* (on). Details: docs/HEARTHSTONE.md.
- **No chat ranking of quest rewards.** Choosing a quest reward no longer prints "Reward comparison ..." with a line per item; hovering a reward still shows how it compares with what you wear. The ranking can be turned back on with *Quest Reward Recommendation* (Gear settings, now off by default) or `/qw set gearQuestRewards on`. Saved settings are switched off once.

**Tested:** offline only (TBC suite 4,964/4,964, Classic Era smoke 93/93, Forever 31/31, route audits 0 errors). Not checked in the live game.

## 0.1.0-alpha.18 (2026-11-01)

- **Patrolling NPCs.** When a step needs an NPC that walks a path (a quest giver, a turn-in NPC or a named mob), the arrow goes to the nearer end of its path and then along it, point by point, until the step is done: back along the path at the far end, round again on a loop. The path is dotted on the world map and the minimap, and the step says the NPC patrols. Only NPCs with at most 2 known spawns are followed, so common mobs that patrol keep their normal waypoint. Paths come from the waypoints in QuestieDB (the same pinned source), in a new `Database/Questie/Patrols.lua`: 215 NPCs on Classic Era, 332 on TBC, with paths under 2% of the map left out. New setting *Follow Patrolling NPCs* (on). Details: docs/PATROLS.md.

**Tested:** offline only (TBC suite 4,928/4,928, Classic Era smoke 93/93, Forever 31/31, route audits 0 errors). Not checked in the live game.

## 0.1.0-alpha.17 (2026-11-01)

- **No chat line for every raid marker.** Automatic marks that work are no longer announced ("Marked Stonetusk Boar with Cross." each time a boar was marked). Chat messages stay for marking problems (could not mark, marking paused) and for `/qw mark`.

**Tested:** offline only (TBC suite 4,876/4,876, Classic Era smoke 93/93, Forever 31/31, route audits 0 errors). Not checked in the live game.

## 0.1.0-alpha.16 (2026-11-01)

- **Train steps suggest a flight when your zone has no class trainer.** The step names the cheapest flight path you know from your zone to a zone with your class trainer (Sentinel Hill to Stormwind, for example) and points the arrow at the flight master. Known flight paths and prices are saved per character each time you open a flight map; a price you have not seen yet is shown as "price not seen yet", never guessed. With no known flight, the step uses the trainer the guide names as before.

**Tested:** offline only (TBC suite 4,876/4,876, Classic Era smoke 93/93, Forever 31/31, route audits 0 errors). Not checked in the live game.

## 0.1.0-alpha.15 (2026-11-01)

- **Fix: guides sent you to a turn-in between objectives in the same place** (Elwynn: Kobold Candles was turned in at Goldshire before The Fargodeep Mine and Gold Dust Exchange, which are done at the same mine with the same kobolds). Across all Classic Era and TBC guides, 60 complete steps of quests already in your log now come before a far-away turn-in when their objectives are next to the ones you just finished. Each move was kept only if it shortens the walk. Saved progress follows the new step order.
- **Fix: automatic training spammed the chat and bought the same spell repeatedly.** The trainer sends several updates before the server confirms a purchase, and each one bought the still-listed spell again with another chat line (six "Learned Holy Light (Rank 2)" lines for one spell). Now it waits for each purchase to be confirmed before the next, and prints one line when you close the trainer: how many spells were learned and what they cost. The game's own "You have learned a new spell" lines stay.
- **Fix: train steps point to the nearest class trainer.** A train step now sends you to your class trainer nearest to where you stand in your zone (Brother Wilhelm in Goldshire, not Brother Sammuel in Northshire), on the arrow, in the step title and for the raid marker. When your zone has none, it uses the trainer the guide names. `/qw train waypoint` and the pet trainer waypoint also measure distance correctly now: they compared your position on the wrong scale and could pick a trainer farther away.
- **Fix: "find the way out" for a target in the same building** (William Pestle in the Lion's Pride Inn). Indoors, the arrow now says to find the way out only when the target is known to be outside, because you stood at it outdoors before. Otherwise it says the arrow shows only the direction, since the target may be outside or in another room.

**Tested:** offline only (TBC suite 4,869/4,869, Classic Era smoke 93/93, Forever 31/31, route audits 0 errors). Not checked in the live game.

## 0.1.0-alpha.14 (2026-11-01)

- **Weapon upgrades by DPS:** a weapon with the same secondary stats as your equipped one (or none on either), the same kind (two-hander, one-hander, ranged) and more DPS is equipped automatically. The notification says how much DPS it adds.
- **Automatic training of recommended spells** (opt-in; setup wizard and Settings → *Automatic Training*, per character). At your class trainer it learns the ranks the training suggestions list for you that you can afford, with a chat line per spell; hold Shift to skip. *Everything I can afford* keeps the old behaviour. Characters with the old *Trainer automation* switch on keep it until they choose.
- **Training steps mark the trainer** with a raid icon, like quest givers on accept and turn-in steps (setting *Mark Friendly Targets*). It marks the trainer the step names, or your class trainers in that zone when the step names none.

**Tested:** offline only (TBC suite 4,857/4,857, Classic Era smoke 93/93, Forever 31/31, route audits 0 errors). Not checked in the live game.

## 0.1.0-alpha.13 (2026-11-01)

- **Fix: raid markers paused themselves and stuck on the old mob** ("paused for this step" in `/qw debug marks`). When a marked mob had gone out of sight and back, moving its icon to your new target looked like someone else had changed the icon, so marking stopped for the step. Quick retargeting could also count as two failures and pause it. Moving an icon now releases every mob it was on, and an icon that Questwarden itself moved is never treated as an outside change or a failure.

**Tested:** offline only (TBC suite 4,832/4,832, Classic Era smoke 93/93, Forever 31/31, route audits 0 errors). The bug was found from in-game `/qw debug marks` output; the fix has not been checked in game yet.

## 0.1.0-alpha.12 (2026-11-01)

- **Fix: "Target is inside" for mobs that are outside** (Kobold Workers at Echo Ridge Mine). A place named in the step text ("Echo Ridge Mine is north of the abbey") no longer counts as indoors; the text has to put the target inside ("inside", "in the cave", "at the back of the cave", "top of the tower"). Hints from step text now say "may be inside"; only spots learned by standing there indoors say "is inside".

**Tested:** offline only (TBC suite 4,829/4,829, Classic Era smoke 93/93, Forever 31/31, route audits 0 errors). Not checked in the live game.

## 0.1.0-alpha.11 (2026-11-01)

- **Fix: a black square around the waypoint pins** on the minimap and world map. The glow behind the diamond is now drawn additively, as the game draws that texture.
- **Class training from What's Training?** (docs/TRAINER.md), built in: What's Training? does not need to be installed.
  - **Trainer list:** its class-trainer data (MIT, by fusionpit; Classic Era and TBC data from commit `26caff2`) decides which ranks the class trainer sells, at which level, and with which earlier-rank, talent, faction and race requirements.
  - **Not from the trainer:** spells the trainer does not sell (books such as Classic's rank-11 Healing Touch, the shaman totem quests, mounts) are no longer suggested as training; they are listed apart.
  - **Prices:** every trainer rank now has a price, the listed base price until you have seen your trainer's own price (a reputation discount can lower it).
  - **Buying in order:** a rank and the earlier rank it needs can both be listed for the same visit, in order.
  - **Completionist:** a segment in a zone with your class trainer gets an optional train step when there is something to train. Training is never a detour and never counted as a quest.
  - **Per character:** the training setting is saved per character and offered in the setup wizard's Options step. Existing characters keep their setting.
- **Licences:** the Classic Era and Forever data now carry QuestieDB's licence copy (`Database/Questie/UPSTREAM_LICENSE.md`), as the TBC data already did.

**Tested:** offline only (TBC suite 4,827/4,827, Classic Era smoke 93/93, Forever 31/31, route audits 0 errors). Not checked in the live game: the pin glow, the marker priority and the training lists at a real trainer need an in-game check.

- **Raid marker priority:** your living target first, then the mob under your mouse, then a mob in view. An icon moves only to a mob that outranks its holder, so a mouseover never takes the icon off your target, and mobs coming into view never take it off your mouseover. When your target dies, the icon goes to your mouseover first.
- **Fix:** right after a death, a mob in view could grab an icon meant for your mouseover, because a new mark only counted once it was confirmed. Marks now count from the moment they are asked for.

## 0.1.0-alpha.10 (2026-11-01)

- **Raid markers are automatic again, and move:**
  - Icons go to the mob you target or mouse over.
  - When the marked mob dies or leaves your view (its nameplate goes away), the icon moves to the next visible mob of the step by itself; you don't have to look at it.
  - An icon is held only while its mob is visible and alive (before: up to 60 seconds after it left view, which kept icons stuck on the first mob).
  - A nameplate coming into view still never takes an icon from a visible living mob, so icons don't jump around on their own.
- **Marking with the macro is optional again** (*Mark with the Targeting Macro*, now off by default; alpha.9's saved "on" is switched back once). The macro still targets the step's mobs.
- **README** updated for the current alpha: status, downloads, features and commands.

**Tested:** offline only (TBC suite 4,785/4,785, Classic Era smoke 88/88, Forever 31/31, route audits 0 errors). Not checked in the live game: how the icons move in a real fight needs an in-game check.

## 0.1.0-alpha.9 (2026-11-01)

- **Fix: an NPC by a door was called "inside".** Deputy Willem at Northshire Abbey was remembered as indoors because the player accepted his quest from just inside the abbey (the old 12-yard arrival radius). Spots are now learned only within 5 yards of the target, and a spot ever seen outdoors never counts as inside. Spots learned by 0.1.0-alpha.8 are cleared once.
- **Raid markers by macro** (docs/RAID_MARKERS.md): the "Questwarden" targeting macro now also marks. One press targets the nearest visible mob of each kind the guide wants and gives it that kind's raid icon. Each press re-picks the nearest living mob, so a marker moves on after a kill or to a nearer mob instead of sticking to the first one. Questwarden no longer marks by itself while this is on (setting *Mark with the Targeting Macro*, on by default; off brings back the automatic marking).
- **Chat line for automatic equips** is now on by default (only you see it). Settings saved as "off" are switched on once.
- **"Find the way out" now shows from 15 yards** (was 40), so it appears when you stand inside a building next to an outdoor target, as in Northshire Abbey.

**Tested:** offline only (TBC suite 4,780/4,780, Classic Era smoke 88/88, Forever 31/31, route audits 0 errors). Not checked in the live game: the macro marking and the indoor hints need an in-game check.

## 0.1.0-alpha.8 (2026-11-01)

- **Fix: mobs that drop a quest item were not targets.** For example the wolves for *Wolves Across the Border*. The target list, the target macro and raid marking now include the NPCs that drop a quest's items: all of them when up to 6 kinds drop it, otherwise those in your zone. Before, the list had kill objectives only and marking needed 3 or fewer droppers.
- **Raid marker follows your target:** targeting another mob of the current step moves the step's icon to it. Mobs only moused over or seen by nameplate still never take it from a living mob.
- **Armor-only upgrades:** an item with nothing but armor is equipped automatically over an equally bare item with less armor. It never replaces an item with stats.
- **Level-up sound on automatic upgrades** (setting *Play a sound on automatic upgrades*, on by default).
- **City, building and cave hints** (docs/SETTINGS.md, "Navigation hints"): the arrow points in a straight line, so the guide now warns when that will mislead you.
  - **Target in a capital:** follow the streets.
  - **You are in a capital and the target is outside it:** leave the city first.
  - **You are indoors and the target is not nearby:** find the way out first.
  - **Target inside a building, cave or mine:** look for the entrance. Known from the step's own text, or learned the first time you arrive there indoors.
  - Each hint shows in the step text, and the most pressing one also shows under the arrow. There are no paths through cities or buildings: the add-on has no data for them.
- **Waypoint pins:**
  - The minimap and world-map pins are now a purple diamond with a glow, so they no longer look like quest-giver "!" icons.
  - The world-map pin stays in the map canvas's own layer and is placed again while the map is open.
  - `/qw debug nav` shows what the pins see.

**Tested:** offline only (TBC suite 4,744/4,744, Classic Era smoke 88/88, Forever 31/31, route audits 0 errors). Not checked in the live game: the pins, the marker move, armor-only equips, the sound and the hints need an in-game check.

## 0.1.0-alpha.7 (2026-11-01)

- **Navigation arrow:** about a third larger, with a larger distance label. *Arrow Scale* still resizes it.
- **Time to arrival:** next to the distance, a countdown (m:ss) to the waypoint, worked out from how fast you are closing on it. It follows running, mounts and flight paths, and shows nothing while you stand still, move away, or just after a teleport or a new waypoint.

**Tested:** offline only (TBC suite 4,712/4,712, Classic Era smoke 87/87, Forever 31/31, route audits 0 errors). The arrow size and the countdown have not been checked in the live game.

## 0.1.0-alpha.6 (2026-11-01)

- **TomTom support removed.** Waypoints use only Questwarden's own navigation: the arrow, the world-map pin and a new **minimap pin** for the current waypoint (it sits on the minimap's edge while the target is out of range, and turns with a rotating minimap). Setting: *Show Minimap Waypoint* (on by default). The old TomTom setting is dropped from saved profiles, and CurseForge no longer lists TomTom as an optional dependency.
- **Fix: "Binding header QUESTWARDEN was attempted to be loaded more than once".** The key bindings declare their header only once.
- **Dungeon runs** (docs/DUNGEONS.md):
  - A dungeon quest's objective step now starts as a note while you are outside the dungeon: *Run <dungeon>: find a group*, with the arrow on the dungeon's entrance. Once you enter, the step moves on to the quest's objectives.
  - Completionist's run step does the same, ends when you enter, and plans a dungeon segment while you are inside.
  - After a death inside a dungeon, releasing points the arrow to its entrance, also after a reload.
  - Entrance positions: QuestieDB's dungeon table, for all 19 Classic Era and 34 TBC dungeons.

**Tested:** offline only (TBC suite 4,704/4,704, Classic Era smoke 87/87, Forever 31/31, route audits 0 errors). Not checked in the live game: the minimap pin's placement, entering detection and the entrance positions need an in-game check.

## 0.1.0-alpha.5 (2026-11-01)

- **Fix: the guide progress bar counted steps you had not done.** Steps ahead of you that wait for a level ("needs level N; picked up if you reach it") counted as done, so a new level-1 character saw about 71% of Elwynn Forest complete. Skipped steps now count once you are past them or when you skipped them yourself.
- **Setup: clearer greyed-out dungeons.** A dungeon greyed out in the Speed list now says it has no quests in the Speed leveling guides, and how many of its quests Completionist still routes.

**Tested:** offline only (TBC suite 4,657/4,657, Classic Era smoke 85/85, Forever 30/30, route audits 0 errors). Both issues were reported from the live game on Classic Era; the fixes have not been checked in game yet.

## 0.1.0-alpha.4 (2026-11-01)

- **Fix: the setup window opened empty** (no step content, Next drawn over Finish). In the game client a dropdown fills its list as soon as it is created, and the wizard's guide and gear-profile lists read the setup draft before it existed, so building the window stopped halfway. The lists now work without a draft, and the window stays hidden until it is fully built.
- **Tests:** the mock client now fills dropdown lists on creation like the game, which reproduces this bug.

**Tested:** offline only (TBC suite 4,656/4,656, Classic Era smoke 83/83, Forever 30/30, route audits 0 errors). The bug was reported from the live game on Classic Era; the fix itself has not been checked in game yet.

## 0.1.0-alpha.3 (2026-11-01)

- **Setup wizard** (docs/SETUP.md): a per-character, five-step setup replaces the one-page first-login window.
  - **Steps:** route (Speed or Completionist, starting guide, Hardcore on Classic Era); talent plan (or *No talent guidance*) and gear profile; dungeons (questing only or selected dungeons, with level, coverage and status per dungeon); options (group quests, Completionist categories, automatic upgrades); review.
  - **Back/Next** with per-step checks. Nothing applies before *Finish Setup*; a failed route start puts everything back and keeps the draft.
  - **Set Up Later** no longer marks setup done: the draft resumes next session; the window does not reopen in the same session.
  - **Reopening:** *Run Setup Again* in Settings → General, or `/qw setup` (`/qw setup status`). Existing characters are not asked again.
- **Per-character dungeons and group quests:** after setup, *Include Dungeon Quests*, the dungeon switches and *Show Group Quests* are saved for the character (`ns.char.routing`) instead of the shared settings profile. Characters without setup keep using the profile.
- **Dungeon runs no longer block the guide:** a dungeon quest in your log whose dungeon is off, or whose run you skipped, steps aside (nothing marked complete); its turn-in returns when the quest is complete.
- **Completionist routes every dungeon:**
  - quests are picked up from the dungeon's usual level;
  - each dungeon gets a skippable run step, and turn-ins wait for completion;
  - coverage is now about 1,190-1,410 routable quests per Classic Era character and 1,890-2,150 per TBC character.
- **No talent guidance:** a per-character choice that turns off plan picks in reminders and the talent window.

**Tested:** offline only (TBC suite 4,656/4,656, Classic Era smoke 83/83, Forever 30/30, route audits 0 errors). Not played in the live game.

## 0.1.0-alpha.2 (2026-10-31)

- **Completionist mode** (docs/COMPLETIONIST.md). A second, per-character leveling mode next to Speed: every eligible quest in the bundled data, planned one zone visit at a time from the character's level, quest log, completion and position, and run through the normal engine as a generated guide.
  - **Routing:** level first (bands of 5, quest level at most 2 above you), then geography (stay in the current zone while its work is within a band of the lowest; otherwise the zone with the most lowest-band work, then the nearest). Zones are revisited as their quests open up; with nothing actionable the route shows the level that opens more. Mutually exclusive quests are never both taken.
  - **Counted, not routed by default:** dungeon, raid, group/elite, profession, reputation, event and repeatable quests (each can be switched on). Progress uses one denominator and keeps excluded, other-branch, missing-data and unknown-completion quests apart.
  - **Setup and settings:** first-time setup starts with the mode choice (Speed preselected, applied only on Finish); Settings → Guide Routing and `/qw completionist` switch it. Switching never changes quest history; the Speed guide and its progress come back.
  - **New data:** `Database/ZoneGeo.lua` (each zone's continent and world box, from the client's map table) for distances between zones.
  - **Coverage:** `tools/build.ps1 completionist-coverage` writes the per-race/class matrix with the planner itself: Classic Era about 1,100-1,300 routable quests per character, TBC about 1,800-2,000.
  - **Tests:** a synthetic fixture for the routing rules (level before travel, geography within a band, prerequisites, return visits, exclusivity, log capacity, unknown completion), real-data checks on both targets, mode switching and first-time setup.

**Tested:** offline only (TBC suite 4,586/4,586, Classic Era smoke 78/78, Forever 30/30, route audits 0 errors). Not played in the live game.

## 0.1.0-alpha.1 (2026-10-31)

**Renamed to Questwarden** (from ClassicGuide) on 2026-10-31, before the first release: the name covers Classic Era, TBC and Forever alike. Slash commands `/qw`, `/questwarden`, `/qwgear`; saved settings `QuestwardenDB`. Entries below that were written before the rename use the new name.

Questwarden is a new add-on for **WoW Classic Era** (1.15.9, interface 11509), forked from TBCGuide 0.9.5, and designed to target **WoW: Forever** later. Phase 1 of 3 builds the multi-target foundation; there are no Classic Era guides or data yet.

### Phase 1: fork and multi-target scaffolding

- **Fork.** TBCGuide's full history is kept. The engine, interface, compatibility layer, tests and build tools are shared code in `addon/`.
- **Targets.** Everything that differs between game versions lives in `targets/<Target>/`: game rules (`Target.<Target>.lua`, shipped as `Config/Target.lua`), data, guide sources and the TOC interface line. `tools/build.ps1 <command> -Target ClassicEra|Forever|TBC` stages the add-on for one target in `build/<Target>/`, and every check runs on that staged copy.
  - **ClassicEra:** level cap 60, 51 talent points, quest log 20, Azeroth only, interface 11509 (confirmed from the wago.tools build list, Questie's release.json and Blizzard's 1.15.9 UI source). Empty data, ready for Phase 2.
  - **Forever:** skeleton with unverified rules (interface 16001, build 1.60.1) and empty data. Marked unverified, so it never loads guides, and it is never packaged.
  - **TBC:** TBCGuide 0.9.5's data and guides, kept only as the engine's test fixture. Never packaged; removed in Phase 2.
- **One name, one place.** The name (`Questwarden`) and slash command (`/qw`, also `/questwarden` and `/qwgear`) are set only in `tools/addon.json`. The build writes the TOC, bindings and SavedVariables (`QuestwardenDB`, `QuestwardenCharDB`) from it, the Lua code derives every global name at runtime, and the lint gate fails on a hard-coded name. `tools/build.ps1 rename <Name> [<slash>]` changes it; renaming was tested end to end.
- **Wrong-client detection.** A build loaded on a different game version (checked from the client's interface number and version) says so at login and loads no guides, because their quests and coordinates would be wrong. Unverified targets refuse guides too.
- **Hardcore character** setting (Settings → Guide Routing), saved per character, for the Phase 2 Hardcore route flavor.
- **Target rules everywhere.** Talent points, level cap, quest-log size, guide chapters and level ranges come from the target in the add-on, the guide compiler, the validator and the route audit (which now warns at 3 below the target's quest-log cap). The validator's coverage checks are switched on per target (`target.json` `require`).
- **Guide and talent-build text** may say `{name}` and `{slash}` instead of the add-on's name.
- **API audit.** `tools/research/api_audit.py` checks every allowlisted API against Blizzard's UI source for a client and reports protected and restricted functions (docs/COMPATIBILITY.md). On 1.15.9 only `SetRaidTarget` and `DeleteCursorItem` are restricted, and both were already handled. `TargetUnit` is not used. The audit also found 32 APIs the code reaches by name through `Compat.has` that were never on the allowlist (inherited from TBCGuide); lint now warns about each, pending review.
- **Tests.** `tools/build.ps1 test` runs the build-tool self-test, then the full suite (TBC fixture) or the new smoke suite (`tests/run_smoke.lua`: boot with empty data, target rules, detection, commands without data). `tools/lua51.py` runs them without a Lua binary.
- **Docs.** New: docs/DATA_POLICY.md (allowed sources, the reference-file rules, the cross-check process), docs/DATA_GAPS.md. Rewritten: README.md, INSTALL.md, docs/DEVELOPER.md, docs/COMPATIBILITY.md, docs/KNOWN_LIMITATIONS.md. TBCGuide's TBC-specific research and reports moved to docs/tbcguide/.

### Tested

- **Offline (all passing):** `tools/build.ps1 all` for ClassicEra, Forever and TBC (lint 0 errors and 39 warnings for the by-name APIs; validation 0 errors; TBC route audit 52 routes, 0 errors, 31 warnings, the same as TBCGuide 0.9.5); build-tool self-test 21/21; TBC engine suite 4,420/4,420; Classic Era smoke 33/33; Forever smoke 29/29.
- **In the game client:** nothing yet.

### Phase 2: Classic Era data and guides (in progress)

- **Classic Era data pipeline.** The importers read each target's QuestieDB flavor and client build from `target.json`. Classic Era now has 4,257 quests, 4,835 NPCs, 852 objects and 2,865 items from QuestieDB's Classic data (3,041 corrections), plus talent trees (432 talents, 27 trees), the race/class table (8 races, 40 combinations), 1,330 trainer ranks, and hunter pet and demon skills from the 1.15.9.70576 client tables. Re-importing the TBC fixture reproduces TBCGuide's data, which checks the importer.
- **Vanilla NPC flags.** Classic data numbers flight masters (8) and innkeepers (128) differently from TBC (8192, 65536). The flags now come from the target's data, so flight-path, inn and trainer steps find the right NPCs.
- **Season of Discovery spells left out.** The 1.15 client tables also contain SoD and seasonal spells (1,334, all ids 400000+). They are excluded from trainer and pet data and listed for review.
- **Hardcore route flavor.** Steps can be `[hc=skip]` (left out for Hardcore characters) or `[hc=only]` (warnings). The engine follows the character's *Hardcore character* setting, and the route audit walks every route as Speed and as Hardcore.
- **First routes, 1-12:** Human (Northshire, Elwynn, Stormwind at 10) and Orc/Troll (Valley of Trials, Durotar, Orgrimmar), adapted from TBCGuide's routes and rebuilt on Classic data. Classic prerequisites that TBC removed are respected (Milly Osworth after Brotherhood of Thieves; Bounty on Murlocs left out). Full Classic class chains at 10 (warrior Bartleby to Dead-tooth Jack, warlock Voidwalker, rogue, mage, priest). Hardcore: Hogger and the Gazz'uz quest are skipped, with warnings for Tiragarde Keep, Zalazane, Fizzle Darkstorm and Princess. Level bands checked against Joana's Classic guides (research only).
- **Fixed** (also present in TBCGuide 0.9.5): the hunter *Taming the Beast* steps were described as escorts. They are taming quests.
- **All racial starts and 1-58 chains.** TBCGuide's Azeroth guides (41 files, plus hunting routes) are ported and rebuilt on Classic data. Every one of the 40 Classic race/class combinations now has a route from its racial start to 58 that passes the route audit as Speed and as Hardcore: 0 order errors, quest log at most 20/20, no pickup left un-turned-in.
  - Removed: Draenei and Blood Elf steps; quests added in TBC patches (Dustwallow's 2.4 hubs, Mudsprocket, and others in Ashenvale, Hillsbrad, the Hinterlands, Thousand Needles, Badlands, Swamp of Sorrows, Barrens and Mulgore).
  - Rewritten: Alliance Dustwallow, from Classic's Theramore and Shady Rest Inn chains.
  - Classic prerequisites: Hillsbrad's *Souvenirs of Death* after *Battle of Hillsbrad*; the warrior *Speak with Coleman* after *Path of Defense*. Winterspring's Storm Shadowhoof bounties are Horde-only.
- **Classic XP model for the route audit.** Quest XP from QuestieDB's Classic table, XP per level from the Classic table (warcraft.wiki.gg), the same kill-XP assumption as before. **Finding:** the ported routes leave about 25 (Alliance) to 27 (Horde) of levels 1-58 to grinding in this model, because TBC needed far less XP. Adding Classic quest content to close that gap, and a 58-60 zone, is the next work.
- **Talent plans:** 28 Icy Veins Classic leveling builds for all nine classes (each also the spec's level-60 build), decoded from the source's talent calculator and checked point by point against the 51-point client trees. No Assassination Rogue plan: neither Icy Veins nor Wowhead publishes one. See docs/TALENTS.md.
- **61 quests added** to 28 guides by `tools/research/quest_insert.py`: started by an NPC or notice board in the zone, objectives in the zone, no elite targets, prerequisites already done, placed at the nearest existing step and only where the character meets the required level. Excluded picks are listed with reasons in `tools/research/quest_exclude.json`. Grinding in the XP model falls only from about 25.2 to 24.3 levels (Alliance) and 26.8 to 25.4 (Horde): most of the remaining candidates are chains that start in other zones or end in another zone, which need hand-planned routes.
- **54 chain quests added across guides** by `tools/research/chain_insert.py` (`chain_candidates.py` lists every unused chain with the zones it needs): members in prerequisite order, each pickup where the modelled level allows it, turn-ins at most two guides later (marked optional when in another guide). Excludes events (Lunar Festival, Scourge Invasion), elite targets, dungeon objectives. Modelled grinding is now 23.6 (Alliance) and 23.9 (Horde) levels of 1-58.
- **How much grinding is left depends on kill XP**, which the model assumes is half the quest XP (TBCGuide's rule of thumb). If kills along the route are worth as much as the quests, the same routes leave 14.7 and 15.8 levels. Play-testing a few zones would settle it.
- **Re-balanced for Classic XP** (`tools/research/rebalance.py`, `zone_guide.py`). Before, 97 pickups sat where the modelled character was too low to take them. Now:
  - 30 **grind stops** (`grind <level> <two nearby mobs of that level>`) come before quests up to 1.5 levels out of reach;
  - 4 pickups move to a later visit near the same giver; 40 quests that could never be taken where they were are taken out (with their steps in other guides);
  - three **return-visit guides** (Stranglethorn for both factions, Alliance Ashenvale), generated from quests no guide used, follow on from their zones;
  - every guide's `@levels` now matches the level the model enters and leaves it at, so the guide browser and guide selection send characters to the right zone.
  Level-gated pickups: 97 -> 12. Modelled grinding stays at about 24.6 levels of 1-58 for each faction: the earlier figure counted XP from quests the character could not yet take. The outdoor, solo, single-zone quests are close to used up; the rest of Classic's quest XP is in elite and group quests, dungeon quests and chains that span zones.
- **Elite/group and dungeon quests as opt-in content** (`tools/research/group_insert.py`): 26 quests, about 125k XP.
  - **8 elite/group quests**, such as Stranglethorn's Kurzen and Panther Mastery lines, the Sigil of Strom and WANTED: Overseer Maltorius. Every step is `[elite; group; hc=skip]`.
  - **18 dungeon quests** across Wailing Caverns, the Stockade, Zul'Farrak, the Sunken Temple, Blackrock Depths and Spire, Scholomance and Stratholme, each step tagged with its instance.
  - **Off by default on Classic Era** (new `contentDefaults` in `Target.ClassicEra.lua`). Turn them on under *Show Group Quests* and *Include Dungeon Quests*. The Hardcore route never takes the elite ones.
  - **Classic Era dungeon list** (`Database/Dungeons.lua`, 19 dungeons) for the per-dungeon settings.
  - **Route audit:** elite, group and dungeon quests now count for the quest log (the case where they are on) but never for XP (the case where they are off). Solo grinding therefore reads 25.0 (Alliance) and 24.8 (Horde); players who do this content level faster.
- **13 more dungeon quests, given in cities and neighbouring zones** (`tools/research/dungeon_cross.py`, about 37k XP).
  - Covered: Ragefire Chasm (Orgrimmar, the Undercity), the Deadmines and the Stockade (Stormwind), Gnomeregan and Scarlet Monastery (Ironforge, Thunder Bluff), Razorfen Kraul and Scholomance.
  - **Where a quest lands:** at a city or neighbouring-zone visit the route already makes. A visit counts only if every character on that route makes it, so steps limited to a class or race, optional steps and Hardcore-only steps don't count. Guides follow their `@next` paths, so a pickup in one race's start zone is never turned in on another race's path.
  - **Same opt-in rule** as the other dungeon quests (*Include Dungeon Quests*).
- **Mixed dungeon chains** (same tool): 4 more dungeon quests and 2 lead-ins, about 39k XP.
  - **What the tool now plans:** the whole chain behind a dungeon quest. That covers outdoor lead-ins, talk-only steps, quests that start from an item, and follow-ups handed out inside the instance. A dungeon visit is one "run": the steps inside an instance stay together, and quests given inside it are picked up during a run the route already makes.
  - **Placed:** Alliance Blackrock Spire (*Bijou's Belongings*, *Message to Maxwell*, *Maxwell's Mission*, *General Drakkisath's Command* and *Demise*) and Horde *Blackfathom Villainy*.
  - **Still missing:** 59 dungeon quests, each with its reason in `docs/generated/ClassicEra/dungeon-unplaced.csv`.
    - 24 have a pickup the route never reaches at the needed level: Dire Maul quests in Feralas, Maraudon quests in Desolace, Blackrock quests in the Badlands.
    - 34 have a lead-in that is an escort (excluded by rule), has no spawn data for its objective (Overmaster Pyron, the Screecher Spirits), or is itself blocked.
    - The rest are given inside an instance no route enters at that level.
- **Escort quests are back in the generated routes, each with a note** (`tools/research/qdb.py` `escort()`, used by `quest_insert`, `chain_insert`, `group_insert` and `dungeon_cross`).
  - **Format:** a `note` step right before the pickup says the next quest is an escort. The escort's own step follows the accept straight away: *Escort: stay close; it fails if the NPC dies.*
  - **How escorts are recognised:** quest flag 2 plus escort wording in the quest text. Other flag-2 quests (scripted events, duels, timed tasks) stay out.
  - **Added, about 26k XP:**
    - Alliance: *Mist*, *Supplies to Auberdine*, *Hints of a New Plague?*, the Desolace *Gizelton Caravan*, *Bodyguard for Hire* and *Get Me Out of Here!*.
    - Horde: *Free From the Hold*, *Galen's Escape* and the two Gizelton escorts.
    - Both factions: *Tooga's Quest* (Tanaris).
  - **Also placed:** re-running the chain tool placed two non-escort chain quests, *Tiger Mastery* and *Return to Tinkee*.
  - **Hand-written escorts get the same note** (`tools/research/escort_notes.py`): 15 notes, each carrying its pickup's class, race and group flags. Among them: Stinky, Torek's Assault, Vorsha the Lasher, Escape Through Force, Protect Kanati Greycloud and the Thousand Needles escorts.
  - **Wrong "Escort quest" labels removed** from 38 steps. The TBC port had put them on quests that aren't escorts:
    - *Taming the Beast* (pet taming).
    - The Un'Goro pylons (exploration).
    - *Great Bear Spirit*, *Body and Heart* and *Hidden Enemies*.
    - *Arikara*, *The True Masters*, *Sathrah's Sacrifice*, *Freed from the Hive* and *Corrupted Sabers*.
  - ***The Tome of Valor*** now says what it is: a defend event in which Daphne Stilwell must survive.
  - ***Gyromast's Revenge*** keeps its label. You lead the robot back, even though the data has no escort flag.
  - **Escort wording now also covers** "help … escape" and "must survive". That brings in *Therylune's Escape* and *Freedom for All Creatures*, which now have their notes.
  - **The Deadmines' Defias Brotherhood chain is still out.** Its escort is now allowed, but the chain goes back and forth between Westfall and Redridge, and the Alliance route doesn't return to Westfall.
- **Routes rebuilt to the maintainer's zone order** (`targets/ClassicEra/zone-order.json`; `tools/research/zone_order.py`).
  - **Structure:** after the race start zones, every stop in the order is its own guide: 52 Alliance visits, 49 Horde visits, levels 12 to 60.
    - Stonetalon, Stranglethorn, Felwood and Azshara come back several times.
    - New zones: Silithus, Blasted Lands, Azshara and Alterac, plus Alliance visits to Stonetalon, Shimmering Flats and Swamp of Sorrows.
    - The route ends in Winterspring at 60.
  - **How the old content moved:** every quest step went, with its flags and notes, to the first visit of its zone that fits the quest's level and comes after its prerequisites. Steps keep their old order within a visit.
  - **Quests picked up only in a race's start zone** keep their later steps for that race (`[race=...]`).
  - **Dropped, because the order doesn't visit those zones:** Westfall, Redridge and Silverpine, and the quests that depend on them (`docs/generated/ClassicEra/zone-order-dropped.csv`).
  - **New quests:** `zone_guide.py --fill` added about 81 unused Classic quests to the visits, in route order.
    - Silithus: 13 for each faction.
    - Blasted Lands: 7 each.
    - Others include Horde Azshara, both factions' Arathi return visits and Alliance Stonetalon.
    - The fill now judges "already done" by the actual `@next` path, not by level band.
  - **Levels:** each visit ends with a `level` step for the next stop's first level, with a note that the order expects grinding or a dungeon there. Quests now carry about 28 levels after the start zones. The model leaves about 20 levels to grinding and dungeons (Alliance 20.1, Horde 20.3), down from about 25. Level-gated pickups: 26.
  - **Fixed:** the Duskwood *The Legend of Stalvan* (66) had a turn-in without a pickup. Madame Eva's pickup is added.
- **Quests spread across repeat visits** (`tools/research/spread_visits.py`): 76 moves.
  - **What can move:** a quest, together with everything in its visit that needs it, moves to a later visit of the same zone. That happens when the later visit's level range fits it better, nothing that depends on it comes earlier, and the old visit keeps at least 3 quests.
  - **Examples:** Barrens quests moved into the Southern Barrens visits, Stranglethorn's Mastery and Bloodsail lines into the later Stranglethorn visits, the Gahrron's Withering chains into the second Western Plaguelands visit, and the Felwood cleansing quests into the second Felwood visit.
  - **Effect:** level-gated pickups went from 26 to 16. Modelled grinding rose slightly (Alliance 20.8, Horde 21.1): earlier visits now end lower, and some quest XP lands near the cap.
  - **Still empty, because the data has nothing that fits:** Alliance Darkshore 23-24, Alterac 37, and Felwood, Azshara and Tanaris at 58. Horde Dustwallow 49 and Burning Steppes 53.
- **Classic Era gear stat priorities** (`targets/ClassicEra/addon/Gear/Profiles.lua`, sources in `docs/GEAR_RESEARCH_CLASSIC.md`).
  - **What's there:** 14 leveling profiles and 19 level-60 profiles, from the Icy Veins Classic leveling, Hardcore and PvE stat pages, with Wowhead as a cross-check.
  - **All priority-only:** no Classic source publishes numeric weights. Items are compared stat by stat; automatic upgrades use labelled estimates.
  - **Gaps:** Rogue and Hunter have no leveling profile, because no usable source ranks their leveling stats.
  - **Smoke tests:** check that the profiles are priority-only and sourced, that every class has a level-60 profile, and that leveling profiles are chosen by level.
- **Classic Era trainer notes and escort list.**
  - **Quest spells:** `Classes/TrainingNotes.lua` marks 22 spells that come from class quests, not the trainer. The client's own teaching spells back them: *Path of Defense* teaches Defensive Stance, Taunt and Sunder Armor; *Path of the Berserker* teaches Berserker Stance and Intercept; Beast Training and Tame Beast teach the hunter pet spells; Bear Form teaches Maul and Growl; the warlock "Teach Summon" spells teach the demons. This answers the Defensive Stance question in DATA_GAPS.
  - **Important and optional spells:** the leveling lists carried over from TBC, limited to spells Classic trainers teach. TBC-only spells are gone, and so are Classic talents such as Ice Block. (Innervate was also dropped here by mistake; see the trainer-level fix below.)
  - **Escort list:** `Database/EscortQuests.lua`, the never-auto-accept list, now has 52 quests. They come from the Classic data (escort wording, or the party-accept flag plus escort wording) plus two found by review. Rebuild it with `escort_notes.py --list`.
  - **Fixed:** the trainer data listed *Mangle* as a level-6 druid spell; Classic Era has no Mangle. A new `excludeSpellIds` list in `target.json` leaves it out (shown in the excluded-spells report).
  - **Smoke tests:** check that every note spell exists in the Classic trainer data, that Mangle is gone, and that the escort list and escort detection work.
- **Classic Era class leveling advice** (`Classes/ClassAdvice.lua`, shown by `/qw class` and in the talent window): a summary and 6-7 tips for each of the nine classes, written in our own words.
  - **Classic content only:** totem quests and no Dual Wield for shamans; pet quests and the dead zone for hunters; Felsteed trained and Dreadsteed from a quest for warlocks; no Mangle; no Felguard.
  - **Levels checked:** every trainer level quoted was checked against the Classic trainer data, quest levels match the trainer notes, and talents are named as talents without a level. The tips are still unverified in game.
  - **Trainer levels:** generated from the data: every even level from 4 to 60 for all classes.
- **Rares and dangerous mobs.**
  - **All of them bundled:** `Npcs.lua` used to keep only the mobs quests involve (103 of the 270 rares in the Classic data). A new `questie.allDangerousMobs` switch in `target.json` (on for Classic Era) also keeps every hostile elite, rare elite and rare with spawns: 543 more NPCs, from the same QuestieDB data. *Track Rare Mobs* and the map pins now cover every rare.
  - **Map pins:** rares come first, then elites, then chests, so the per-map pin cap never hides a rare. A patrolling mob's tooltip says it may not be where the pin is.
  - **Danger report:** `tools/research/danger_report.py` lists route steps with a hostile elite, a higher-level rare, or a mob 5+ levels above the step's model level within 40 yards (`docs/generated/ClassicEra/danger-near-steps.csv`). It found 13 steps in 5 places; each now has a Hardcore note: the Twilight elites around Zamael in Searing Gorge, Jintha'alor and Vile Priestess Hexx in the Hinterlands (Horde), Clack the Reaver near Kum'isha in the Blasted Lands (both factions), and the Twilight Thugs at the Master's Glaive in Darkshore.
  - **Smoke tests:** check that every hostile rare is bundled, that rares come first on the map, and that a patrolling elite is marked.
- **Flight paths.**
  - **Flight graph:** `import-client` now builds `Database/Flights.lua` from the client's `TaxiNodes` and `TaxiPath` tables (two more wago.tools tables, switched on by `clientTables.flights`). It has 64 Alliance, Horde and neutral nodes with 268 direct flights. Each node has its zone, map position and, for 61 of them, its flight master. TBC and Forever ship an empty graph.
  - **Compiler:** every `fp` step is tied to its node (all 47 resolve), and a `fly` destination must be a flight node of the guide's faction.
  - **Route audit:** a `fly` step fails when no earlier `fp` step on that route learned the destination, or when no learned flight path in the current zone connects to it.
  - **Fly steps:** `tools/research/fly_steps.py` added 10, before visits the route can now fly to: Theramore, Gadgetzan, Talonbranch Glade and Chillwind Camp for Alliance; Ratchet, Sun Rock Retreat (twice), Grom'gol, Shadowprey Village and Stonard for Horde. Most visits still go on foot or by boat, because the destination's flight path is not learned yet or the learned paths do not connect.
  - **Add-on:** flight automation picks the step's node by its full client name first, and landing completes both the `fly` step and the `travel` step after it.
  - **Found by the check:** the Night Elf route's *fly Auberdine* from Rut'theran comes before any route learns Auberdine. The quest *Flight to Auberdine* says Vesprystus flies you there, so the step stays, marked unverified, with the boat as the fallback (10 audit warnings).
  - **Tests:** smoke checks for the graph and the route fly steps; engine tests for the exact node choice and for landing.
- **Cross-check command.** `tools/build.ps1 crosscheck -Reference <folder>` (`tools/research/crosscheck.py`) compares our generated spirit healers, flight nodes, rares, mob levels and ranks, and trainer spells with a reference add-on's data files kept outside the repository. It refuses a folder inside the repository and writes only `docs/generated/CROSSCHECK.md`, which is kept out of the repository because it quotes reference values; nothing from the reference reaches the add-on (docs/DATA_POLICY.md). The first run is summarised in DATA_GAPS.md. It found one bug of ours, now fixed: rares that QuestieDB marks friendly to one faction were left out for both. They now count as dangerous to the other faction (12 more rares bundled; map pins, rare alerts and the danger report judge by the player's or guide's faction). Elites friendly to one faction stay out: they are guards and flight masters in their own towns.
- **Hunting routes regenerated from Classic spawns.** `tools/research/roam_propose.py` and `roam_coverage.py` now take a target and read its own QuestieDB spawn list, map sizes and compiled guides (they still pointed at TBCGuide's old paths). Classic Era now has 104 routes in 25 zones, used 108 times, covering 121 quest objectives in 98 quests, up from 96 uses of the TBC-generated routes.
  - **Dropped:** Westfall, Redridge and Silverpine (not on the zone order any more; 5 compiler warnings gone) and Searing Gorge, whose *Flame's Casing* droppers are elites in the Classic data.
  - **New:** Un'Goro Crater and Wetlands.
  - **Review:** Classic gets its own `targets/ClassicEra/roaming-overrides.csv`, carried over from TBCGuide's zone review (same old-world terrain; Outland and TBC-race zones dropped). The five zones TBCGuide never reviewed (Stonetalon Mountains, Azshara, Alterac Mountains, Blasted Lands, Silithus) were then reviewed from general knowledge of their terrain, not walked: the first four strict, Silithus normal. That gave routes for *A Gnome's Respite* and the two Kum'isha quests, for 107 routes in 27 zones covering 124 objectives in 101 quests. Records: `docs/generated/ClassicEra/roaming-dispositions.csv`.
- **One download for Classic Era and TBC Classic Anniversary** (maintainer's decision). The TBC target, TBCGuide 0.9.5's data and 1-70 guides, is no longer a test fixture: it ships in the same zip as Classic Era.
  - **How:** `tools/build.ps1 package` now builds `dist/Questwarden-<version>.zip` from every shipped target. The shared code sits once at the root of the folder and each game's data under `Targets/<Target>/`, with `Questwarden_Vanilla.toc` (interface 11509) and `Questwarden_TBC.toc` (interface 20506) each listing its own data. Each client loads the TOC for its game type, as Blizzard's own 1.15.9 and 2.5.6 UI add-ons do. A shared file that differs between targets stops the build.
  - **Tested through each TOC:** the Classic Era smoke suite and the full TBC engine suite run against the assembled folder before it is zipped. The test runners take the TOC and data location from `stage.lua`.
  - **TBCGuide:** the README says not to run both on TBC. The conflict check does not name it, because the lint gate keeps the old name out of shipped code.
  - **Not yet for TBC:** flight graph, spirit healers, the full rare list and regenerated hunting routes (DATA_GAPS.md).
- **TBC data brought up to the Classic Era standard.**
  - **Flight graph:** 107 nodes and 460 direct flights from the 2.5.6 client, Outland included. The importer now also takes Outland (map 530) and leaves out scripted quest flights, PvP bombing runs and teleports, which share the taxi tables ("Quest - …", "Nagrand - PvP - …"). A flight-path name can match outside the step's zone when exactly one node of that faction has it, as with Shattrath.
  - **Guide fixes found by the graph:** three `fp` steps named flight paths the client does not have (Fairbreeze Village; Cenarion Refuge for both factions) and are removed. Westfall's conditional *fly Lakeshire* is now a `travel` step. The three quest flights, Honor Hold, Thrallmar and Auberdine, are marked unverified, with their quest text as the reason.
  - **Spirit healers** (154) and **every hostile rare and elite** (887 more NPCs) for TBC, with the same switches as Classic Era.
  - **Hunting routes:** TBC gets its own review file. Regenerating gives the same 185 routes, which checks the generator.
  - **Danger report** for TBC (27 steps; review only, since TBC has no Hardcore flavor). The report now skips invisible helper NPCs such as Hallow's End's "Headless Horseman - Fire (DND)", which had flagged 225 rows.
  - **Tested:** TBC suite 4,435/4,435, route audit 0 errors (88 warnings, 57 of them the unverified quest flights); the combined download passes through both TOCs.
- **Trainer levels fixed: Innervate and rogue poisons** (found by the cross-check). The trainer and pet importers read a spell's level only from `SpellLevels.BaseLevel`. That is 0 for Classic Era's Innervate (trained at 40) and for every rogue poison recipe, so they looked like level-1 spells and were left out. Both importers now fall back to `SpellLevel`.
  - **Classic Era:** Innervate (40) and 18 poison ranks (Instant, Deadly, Wound, Crippling, Blinding Powder) added; 21 hunter pet skill ranks got their real levels. Innervate is back on the druid's important list.
  - **TBC:** 22 poison ranks and the warrior's *Stance Mastery* (20, from the client tables; check in game) added.
  - **Docs:** TRAINER.md no longer says poison recipes have no level. Smoke tests check Innervate and the poisons.
- **Cross-zone solo chains.** `tools/research/dungeon_cross.py --outdoor` plans unused outdoor and talk-only quests the way it plans dungeon chains: pick up near the giver in a guide whose level fits, then objectives and turn-in in the same guide or the next two along the zone order, only where every route into the turn-in guide has passed the pickup.
  - **Left out:** seasonal and event quests (a negative QuestieDB zone/sort, e.g. Winter Veil, the Ahn'Qiraj war effort), quests with elite targets, and objectives the route would reach more than 2 levels under the quest's level.
  - **Result:** 42 quests (16 Alliance, 26 Horde; 76,855 XP across both), such as *Pridewings of Stonetalon* (Ashenvale to Stonetalon to Ashenvale), *Winterfall Firewater* and *Falling to Corruption* (Felwood and Winterspring), *Report to Helgrum* (Badlands to Swamp of Sorrows) and *The Champion of the Banshee Queen* (Western to Eastern Plaguelands). The escort *The Sleeper Has Awakened* got its note. Modelled grinding is about 0.6 (Alliance) and 0.7 (Horde) levels lower; route audit 0 errors, quest log peak still 15/20.
  - **Not placed:** listed with the reason in `docs/generated/ClassicEra/outdoor-unplaced.csv`: mostly a prerequisite no route takes (525) or a giver no route visits at the right level (204).
- **API approvals (maintainer, 2026-10-31).**
  - **Allowlist:** the 32 APIs the inherited code reaches by name (item and container info, gear stats, auto-equip, the auction tab), plus `WOW_PROJECT_ID`, `WOW_PROJECT_CAMELOT` and `C_GameRules.IsHardcoreActive`. Lint now reports no warnings.
  - **Hardcore realms:** the Hardcore route turns on automatically on a Hardcore realm. The per-character setting stays for self-imposed Hardcore and shows as on when the realm is Hardcore.
  - **Forever client:** a Classic Era or TBC build refuses the Forever client, and the Forever build refuses the others, by project id (`WOW_PROJECT_CAMELOT` exists only on Forever, = 18 in its UI source) as well as by interface number.
  - **Tests:** smoke checks for both.
- **Blocked quest chains and pet ranks explained.**
  - **The 525 "prerequisite not placed" quests** are 418 quests in about 240 chains, each stuck at its first quest: 106 chains start with a quest that is no solo candidate (a dungeon quest, an NPC inside an instance, elite targets, a class or event quest), 69 with a giver no route visits at that level, 34 with a finisher not visited after the pickup, 18 with objectives not visited. Many start in Westfall, Redridge, Silverpine or a capital, which the zone order does not visit. `outdoor-unplaced.csv` now names each blocked quest's chain head and its reason (`blocked_by`, `blocked_by_reason`). Re-running the planner places nothing more.
  - **Pet Growl and resistance ranks** were never missing: the cross-check's reference lists the hunter's Beast Training spells, which teach the pet spells our data holds. The cross-check now follows the client's learn-spell effect, and only Growl 15147 is left to check.
- **Phase 3 started: World of Warcraft: Forever** (docs/FOREVER_PLAN.md, new).
  - **Quest data:** QuestieDB's Forever data (approved) imported: 5,232 quests, with Forever's quest-correction layers applied in QuestieDB's order (16,549 applied). The importer gained ordered fix layers, a per-target zone folder, `*_add`/`*_remove` correction keys, the Skyborne race masks and race masks wider than 32 bits (the compiler reads them as 64-bit too).
  - **Routes:** the Forever target compiles Classic Era's guide sources (`guidesFrom`) with 0 errors; for borrowed guides a renamed quest is a warning and a hunting route that no longer fits is left out. The route audit walks 92 routes and reports 6 Forever-specific errors; an unverified target's audit reports without failing the build.
  - **Client tables:** Forever's race/class table (46 combinations) and flight graph (68 nodes) from wago.tools `wowf`; the talent and trainer importers do not read Forever's modern layout yet.
  - **API audits** re-run for all three clients against today's allowlist.
- **Spirit healers.** The Classic client has no graveyard table, so they come from QuestieDB: every spawn of the Spirit Healer NPC, 84 positions, written to `Database/Questie/SpiritHealers.lua` (switched on by `questie.spiritHealers`; not cut down like `Npcs.lua`). A new *Track Spirit Healers* setting (off by default) shows them as world map pins; they come first in the pin list, so the pin cap never hides one. Smoke tests check the data and the pins.

Tested offline: ClassicEra build all passes (107 guides; 80 route walks, Speed and Hardcore: 0 errors, 22 warnings, quest log peak 15/20; smoke suite 73/73); TBC suite 4,435/4,435; Forever 29/29. Nothing has been run in the game client.

---

# TBCGuide history (the add-on Questwarden was forked from)

## 0.9.5

### Added
- **Automatically Navigate to Corpse** (Settings → General, on by default): after you release your spirit, the arrow points to your corpse ("Corpse 120 yd") until you are alive again, then goes back to the current guide step or hunting route. Navigation only: it never releases, resurrects or talks to a spirit healer.
  - **Where the position comes from:** the game's own corpse position (C_DeathInfo), for the map you died on, then your current map and its parent maps. No position, or 0,0, means no arrow; the game is asked again a few times, then you get a short note.
  - **Instances:** dying inside a dungeon, raid or battleground gives no outdoor position, so there is a note instead of an arrow.
  - **Controls:** `/tbcg corpse off` returns the arrow to the guide, `/tbcg corpse on` brings it back. A waypoint you set yourself (such as `/tbcg train waypoint`) also replaces it.
- Arriving near a waypoint only completes a "go to" step when the arrow is showing that step (not a hunting route point or your corpse).


## 0.9.4

### Added
- **Roaming Waypoints for Kill Objectives** (Settings → General, on by default): on a kill step with a verified route, the arrow walks a loop of points through the mobs' known spawn area and moves to the next point when you reach one, until the objective is done. Navigation only: it never targets, fights or completes a step for you.
  - **Supported now:** 194 quest objectives in 170 quests, with 160 distinct routes in 39 zones, from the starting zones to Shadowmoon Valley, for both factions. Every other step keeps its normal waypoint.
  - **How the routes were made:** each point is the centre of real spawns, and every leg was checked against the full spawn list, kept away from elites and other-faction towns, and reviewed zone by zone. Caves, mines, multi-level areas, named and elite enemies, escorts and small spawn spots keep a single waypoint.
  - **Records:** all 949 candidate objectives have a recorded decision and reason (docs/research/roaming-dispositions.csv). None of the routes has been walked in the game yet.
  - **Checking the target:** on English clients a route only runs when the quest log's objective names its target.
  - **Controls:** *Next patrol point* and *Normal objective waypoint* buttons, `/tbcg route next | off | on`, and a key binding for the next point.
  - **Routes** are built from real spawn data and checked by the compiler (docs/ROAMING.md); `docs/generated/roaming-candidates.csv` lists the steps that could get one next.
- **Waypoints you choose** (such as `/tbcg train waypoint`) are no longer replaced by the periodic objective retargeting on kill steps.

### Fixed
- **Active Item window:** clicking an item now uses it. The buttons were set up correctly as secure item buttons, but on this client a secure button acts on the mouse-down event (the default "use on key down" setting) and ours only listened for mouse-up, so clicks did nothing. They now listen for both, and the client acts once.
  - **Also:** the buttons show the total stack count and the item's cooldown, and grey out when the item is used up during combat (the list itself changes after combat, so a button never shows one item and uses another). Shift-click links the item in chat, Alt-drag moves the window; neither uses it.


## 0.9.3

### Fixed
- **Discard junk if bag is full** now works without any confirmation: when the bags are full, the cheapest junk item is destroyed on your next click in the game world, key press or loot click, one item each time.
  - **Why the change:** the client only lets add-ons destroy items during a click or key press, so the old attempt from a bag update was refused and left the item on your cursor.
  - **Safety:** every attempt re-checks the slot and the junk rules, and waits while you are in combat, holding an item, or at a merchant, trade, bank, mail or auction window.
  - **Feedback:** success is reported only once the bags confirm it, and failed items are not retried.

- **Innkeeper Bind automation** sets your hearthstone again, and bind steps complete on every client.
  - **Why it failed:** on this client the innkeeper's gossip options have no type, so the bind option was never found; the confirmation used a function the client no longer has; and the step only completed when the game's home name equalled the guide's English town name, which fails for The Crossroads, Theramore Isle, Grom'gol Base Camp, the inns with their own area (Thunderbrew Distillery, Stoutlager Inn, Deepwater Tavern, Gallows' End Tavern, Wildhammer Keep) and every non-English client.
  - **Now:** each bind step names its inn by client area id and innkeeper id. TBCGuide acts only at that innkeeper, confirms only a dialog for that inn, and completes the step only once the game reports the new home. Quest turn-ins at the innkeeper go first. Nothing is retried; declining, closing the window, changing step or turning the setting off cancels it.


## 0.9.2

### Added
- **Winterspring** (both factions, through the Timbermaw tunnel from Felwood) and **Horde Swamp of Sorrows** (Stonard).
- **More quests on existing routes:**
  - Mudsprocket in Dustwallow (both factions);
  - Andre Firebeard, Gahz'ridian and The Thirsty Goblin in Tanaris;
  - Shizzle's Flyer, the bloodpetal quests and Finding the Source in Un'Goro;
  - the Revantusk board in Horde Hinterlands;
  - the Cabal quests and Warden Treelos in Terokkar;
  - Aeris Landing and Wazat in Nagrand, plus Sunspring for Alliance.
- **Less grinding:** in the route model, grinding from 30 to 58 falls from 12.3 to 10.5 levels (Alliance) and from 12.2 to 9.4 (Horde). See docs/LEVELS_31_60.md.
- **Assassination talent plan** from Wowhead's TBC leveling build (docs/TALENTS.md).
- **Training costs** on train steps: from the trainer you have open, or as last seen. Partial totals are marked, and the list says whether you can afford it.
- **Pet and demon skills** (`/tbcg pet`): hunter pet skills (family, pet level, training points, Beast Training) and warlock Grimoires (level, base price, demon trainer). See docs/PETS.md.

### Changed
- **Felwood** now leads into Winterspring.
- **Saved progress** follows guides reordered in any release since 0.7.0.


## 0.9.1

### Added
- **New zones in the 31-60 route:**
  - Desolace (Alliance and Horde) and the Badlands (Alliance and Horde);
  - Searing Gorge and Eastern Plaguelands (shared, with Horde-only Nathanos steps).
- **Expanded guides:** Horde Feralas (4 → 14 quests), Alliance Western Plaguelands (9 → 26, with the Chillwind cauldron chain), Horde Western Plaguelands (14 → 20), Felwood (both), and Horde Blade's Edge (15 → 25, Mok'Nathal Village).
  - In the route model, grinding from 30 to 58 falls from about 17 to 12.3 levels (Alliance) and from 16 to 12.2 (Horde). See docs/LEVELS_31_60.md.
- **Outland:** all 13 guides were reordered within their travel segments (estimated travel down about 35%), with 166 data notes. See docs/OUTLAND.md.
- **Talent plans for every spec**, taken from the Icy Veins TBC Classic leveling guides in their own point order. Each runs from the first point at 10 to 70 with no forced respec, including Demonology from level 10. New: Marksmanship, Survival, Subtlety, Discipline, Arcane, Demonology, Restoration Druid and Frost single-target. See docs/TALENTS.md.

### Changed
- **Existing talent plans** now follow the Icy Veins builds. Old saved choices still resolve to the new plans, and learned talents are never touched. Assassination keeps TBCGuide's own plan, because Icy Veins has no Assassination leveling build.
- **Saved progress** follows guides reordered across several releases (0.7.0 or 0.9.0 → now).
- **Shared guides** can mark steps `[faction=Horde]` or `[faction=Alliance]`.

## 0.9.0

Our biggest update yet: a first-login setup, bag add-on support, non-English client support, class trainer suggestions, talent suggestions in the talent window, an auction house upgrades tab, and a full route pass from level 1 to 60.

### Changed
- **1-30 routes tidied:** the 25 guides that got quests in 0.6.0 were reordered within their travel segments, keeping every quest, chain and gate.
  - **Travel:** per-character travel on those guides is 36% lower than in 0.7.0 (an approximate, map-distance measure).
  - **Gated pickups:** the ones the new XP model flags fell from 206 to 116.
  - **Notes:** 514 notes taken from the bundled data were added (drop sources, objects, elites, escorts, turn-in zones, level needed).

  Details and the method: docs/ROUTE_PASS_1.0.md.
- **31-60 routes tidied:** the 18 guides from Thousand Needles / Arathi to Western Plaguelands were reordered within their travel segments (summed travel -29%, every quest and chain kept), with 62 data notes. Saved progress follows. Coverage matrix and status: docs/LEVELS_31_60.md.
- **Pickups you're too low for** are skipped with the reason instead of blocking the guide. They come back if you reach the level before moving on.
- **Saved progress** follows the reordered steps (`Guides/Layouts.lua`).

### Added
- **Auction house Upgrades tab** (*Enable Auctioneer*): a scan you start, with progress, cancel and partial/stale labels, and upgrades for your spec grouped by slot, scored exactly like automatic upgrades.
  - **Filters:** price, minimum % and slot, with a sort by % or price.
  - **Never automatic:** nothing is ever bought.

  See docs/AUCTION.md.
- **Window settings** (General): guide window scale, font size and arrow scale, with a reset.
- **First-login setup:** pick a guide and a spec profile, and opt in to automatic upgrades explicitly (off unless ticked). Saved per character; skip, resume after a reload, or reopen from Settings → General. Existing characters are not interrupted.
- **Bag add-ons:** the BoE upgrade arrow and junk markers also work in Bagnon, AdiBags and Baganator (docs/BAGS.md). Not yet tested in game.
- **Non-English clients:** tooltip reading uses the client's own strings for binding and effects; unread equip effects make an upgrade uncertain instead of being ignored (docs/LOCALES.md).
- **Dungeon quests** are tagged from quest data in the compiler, with hand tags winning. The route XP model no longer counts dungeon quest XP (docs/DUNGEONS.md).
- **Class trainer suggestions** (*Class Trainer Suggestions*: Off / Important only / All): train steps list the spell ranks your trainer has for you, from the client's own spell tables checked against your spellbook. Train steps with nothing new are skipped. Talent ranks only after the talent, class-quest spells listed apart, `/tbcg train` (defer, waypoint). Never buys anything (docs/TRAINER.md).
- **Talent suggestions in the talent window** (*Show Talent Suggestions*): numbered markers on your plan's next picks, a panel with the plan, deviations and what blocks the next pick, and tooltip lines. Follows your spec profile (21 of 28 have a plan). Never spends points (docs/TALENTS.md).
- **Route audit XP model:** QuestieDB TBC quest XP and the post-2.3 XP table, a per-character travel measure, and `docs/generated/level-gates.csv`.

### Removed
- The unfinished *Follow Party Leader Macro*, *Quest Sellable Recommendation* and *Always Show Total EP* options. The settings window has no greyed-out placeholders left.

## 0.7.0

### Added
- **Automatic upgrades** (opt-in, Tips → Automatic Upgrades). TBCGuide equips gear from your bags for the spec profile you choose.
  - **What it equips:** empty slots get any usable item; filled slots only a higher estimated spec score.
  - **Never:** in combat, with an open merchant, trade, bank, mail or auction window, or when the binding is unknown. **Never unbound Bind-on-Equip items.**
  - **How:** one change at a time, confirmed before an on-screen message (optionally also in chat).
  - **Protection:** protected slots, plus `/tbcg gear exclude <item>`.
  - Details: docs/AUTO_EQUIP.md.
- **BoE upgrade markers:** a green arrow on unbound Bind-on-Equip upgrades in the default bags. The tooltip says what it replaces and the estimated spec-score change, and that you need to equip it yourself.
- **Spec profiles for every spec:** Marksmanship and Survival Hunter, Discipline Priest, and Assassination and Subtlety Rogue, so all 28 specs have one; Feral cat and bear stay separate.
  - The Spec profile dropdown lists only your class and is saved per character.
  - Specs without published numbers use **estimated** weights for automatic upgrades, labelled as estimates.

- **Settings window features built** (all were greyed out before):
  - **General:**
    - Active Item window (click to use quest items);
    - Vendor Treasures (merchant items that are upgrades for your spec);
    - flight timers (each route is timed the first time you fly it);
    - Group Settings switch;
    - junk coin indicator in bags;
    - talent plan (`/tbcg talents plan`).
  - **Guide Routing:** choose single dungeons, *Select Recommended* and *Select all*.
  - **Targeting:** Active Target Frame (click-to-target buttons for the step's NPCs, optional party leader target).
  - **Leveling Tracker:** time per level from played time, XP per hour, a leveling report (`/tbcg tracker`), level splits with history, compare and total.
  - **Communications:** version checks, party announcements (completion, collection, flights; only to other TBCGuide users unless you allow it), automatic quest sharing.
  - **Tips:** map pins for elite/rare mobs and treasure chests.
  - **Advanced:** low-quality mode, pre-load item data.

### Changed
- **New look:** every TBCGuide window has a flat dark style with a blue accent.
  - Title bars; flat buttons, checkboxes, inputs, sliders and tabs.
  - The settings window has one tab row, and the guide window a slimmer progress bar.
- **Removed:** the Look and Feel tab, and the options that had nothing to act on (XP rate, Solo Self Found, beta features, hearthstone batching, quest log size).

### Fixed
- The shared event throttle could stop with an error when one throttled job scheduled another.

Not tested in the game client.

## 0.6.0

### Changed
- **Denser 1-30 routes:** 448 quests added across 25 guides, including class quests that used to be only a note on train steps, such as *Taming the Beast*, druid forms, totem quests and Voidwalker. Every added quest passed the compiler and route audit. Not tested in the game client.

## 0.5.0

### Fixed
- Horde *Trouble in the Deeps* is now turned in at Zoram'gar Outpost in Ashenvale, where its quest giver is. Before, the Stonetalon guide asked you to turn it in there, with an empty objective step. The note for *Amongst the Ruins* now says the Fathom Stone is inside Blackfathom Deeps.

### Added
- **Settings window** (`/tbcg options`, minimap button). It has two rows of tabs (General, Guide Routing, Targeting, Leveling Tracker, Communications, Tips, Help / Look and Feel, Advanced Settings, Profiles) with gold section headers, checkboxes, sliders, dropdowns, colour swatches and a key-binding button. Options that are planned but not built yet are shown greyed out and do nothing. See docs/SETTINGS.md.
- **Profiles:** create, switch, copy from, delete, reset, and set as default for new characters. Existing settings become the "Default" profile.
- **NPC automation:** flight path (fly to the guide's destination), innkeeper bind on bind steps, skip single-option gossip, and trainer automation (off by default). Hold Shift to skip.
- **Quest auto rewards** (off by default): only a clear gear-score upgrade, or the most valuable reward when your class can use none of them.
- **Junk:** a junk list (modifier + right-click in bags), a key binding that deletes the cheapest junk item, and optional discarding when bags are full. A master *Inventory Manager* switch covers all of them.
- **Routing:** skip overleveled (grey) quest pickups unless a later quest needs them, and *Disable step skips* for debugging.
- **Include Dungeon Quests** (Guide Routing; on by default): off leaves dungeon quest steps out of the route, skips follow-ups that need them and moves straight on. Quests already in your log keep their steps. The only guide quest that needs an instance, Horde Ashenvale *Amongst the Ruins* (Blackfathom Deeps), is now tagged. The compiler warns about untagged quests whose objectives are only inside instances.
- **Targeting:** mark friendly quest NPCs, allow or forbid marking in groups, a "TBCGuide" targeting macro, a note when a step NPC comes into view, and maximum nameplate distance.
- **Tips:** drowning and low-health warnings (sound, screen flash, thresholds) and rare-mob alerts.
- **Look and feel:** step text colours, guide font size, step list toggle, arrow scale and update rate.
- **Other:** world map button, level-up announcements (emote/party/guild, off by default), and a warning when another leveling guide add-on is loaded.


## 0.4.1

### Added
- **Minimap button.** Left-click opens the TBCGuide settings, and clicking again closes them. Right-click shows or hides the guide window. Drag it around the minimap; the position is saved when you let go and kept across reloads. Square minimaps from other add-ons are supported. *Show the minimap button* on the settings page and `/tbcg minimap` hide or show it; `/tbcg options` always opens settings. Native code, no libraries.

### Fixed
- **Raid markers marked almost nothing.** Only 5 guide steps carried a `[mark]`, and marking a step's kill objectives was off by default. It is now on by default. Settings saved by older versions are switched on once, with a chat note; `/tbcg set autoMarkObjectives off` turns it off.
- **After the first marked mob died, no other mob of that step was marked.** The game removes a dead mob's icon without an icon event, and the add-on kept waiting for the dead mob. Deaths are now read from the combat log (`UNIT_DIED`, only for units TBCGuide marked). A held icon is also released when its mob is visible without it, or has not been seen for 60 seconds. A dead mob losing its icon no longer pauses marking for the step.
- **Kill steps done together are covered at once.** The current step and the open `complete` steps right after it each get their own icon: default marker first, then skull, cross, square, and so on, at most 4. Icons stay with their mob type when one step finishes, and still-valid icons are not cleared and re-set on a step change.
- `/tbcg debug marks` shows the settings, each icon's NPCs, why there is no rule, and the last marking decision. Attempts and refusals go to the debug log.


## 0.4.0

### Added
- **Gear scoring.** Item tooltips compare an item with what you wear. Quest reward choices are ranked in chat; you still choose, and a reward is never picked automatically. `/tbcg gear` (also `/tbcgear`) lists equipped items, empty slots and upgrades in your bags.
- **Researched profiles:** stat weights come from wowsims/tbc and Icy Veins TBC pages, with sources, assumptions and confidence recorded in docs/GEAR_RESEARCH.md. Specs and levels without published numbers get a stat-by-stat comparison instead of an invented score. Level-70 weights are never applied to leveling characters automatically.
- **Caps and slots:** hit and expertise count only up to the profile's cap. Two-handers, dual wielding, off-hands, rings and trinkets, and class armor and weapon types are handled. Weapon DPS, sockets, equip effects and set bonuses are listed as not scored.
- *Gear* settings page and `/tbcg gear profiles`, `/tbcg gear profile <id|auto>`. See docs/GEAR_SCORING.md.


## 0.3.2

### Fixed
- **Missing class quests in the starting guides.** *Verdant Note* (tauren druid) was missing because only the Human guide had the level-1 class letters. All seven starting guides now have them: the *Note*, *Sigil*, *Parchment*, *Tablet*, *Scroll*, *Rune* and *Memorandum* letters, plus the blood elf and draenei *… Training* quests.
- Warlock starting quests added: *The Stolen Tome* (Elwynn), *Beginnings* (Dun Morogh), *Piercing the Veil* (Tirisfal) and *Windows to the Source* (Eversong).
- Durotar warlocks now do *Vile Familiars* (1499), which unlocks *Burning Blade Medallion*. Before this, the route sent warlocks to a quest they could not take.
- Shaman *Call of Earth* (Earth Totem) chains added in Durotar, Mulgore and Azuremyst.
- New regression test: every level-1 class quest a starting guide's races can take there must be in that guide exactly once. Audit and reasoning: docs/CLASS_QUEST_AUDIT.md.


## 0.3.1

### Added
- `grind` guide step: which mobs to kill, where, and until which level. It completes on reaching the level, like a `level` step, and is never based on XP. The compiler checks every mob against the bundled database and the step's zone. Example: Elwynn's level-10 gate now names the Riverpaw gnolls south of Westbrook Garrison.

### Fixed
- The earlier grind-step work completed grind steps as soon as they appeared, because of an XP check. It also added text on every window redraw, and three unused settings. Grind steps now complete on level only; the redraw text and unused settings are removed.


## 0.3.0

### Added
- **Raid markers.** `/tbcg mark [icon]`, `/tbcg unmark`, `/tbcg marker <icon>`, a marker bar (`/tbcg markbar`, secure click buttons), a *Raid markers* settings page and `/tbcg debug marks`.
- **Guide-driven marking:** new step flag `[mark=icon]`, `[mark=icon:<npc id>]` or `[mark=icon:<exact name>]`. The compiler resolves NPC IDs from the bundled data and fails on ambiguous names. Units are matched only by NPC ID. Each unit gets one attempt per step. Existing icons are not replaced by default. Changes made by the player are respected (automatic marking pauses), only TBCGuide's own icons are cleared when the step changes, and results are verified before "Marked" is reported. Permission is checked in raids. If the client blocks marking, it falls back to the marker bar.
- Example marks in Elwynn, Westfall, Durotar and Eversong. Optional `autoMarkObjectives` marks kill objectives with the default icon.

### Fixed
- Durotar *Vanquish the Betrayers*: the note now describes the real objectives (Kul Tiras sailors and marines, Lieutenant Benedict at Tiragarde Keep).


## 0.2.0

### Added
- **Quest automation.** Accepts and turns in quests that have an open step in the active guide. Escort and scripted-event quests are never auto-accepted (multiple signals, unknown means manual; no setting overrides it). A reward is never chosen when there is more than one. Success is reported only after the game confirms it. Hold Shift to skip once. On by default for guide quests.
- **Junk selling** at vendors: Poor-quality items only, with protected items and categories, and quest, quest-starting and guide-needed items always kept. Sales are counted only when confirmed, with a running total. **Off by default.**
- **Orphaned quests:** an *Orphaned (N)* button on the quest log, and `/tbcg orphans`. Lists quests that the active guide and the rest of the route will never turn in, and abandons the selected ones after confirmation.
- *Automation* settings page; commands `automation`, `orphans`, `protect`/`unprotect`/`protected`, `escort add|remove`, `debug escort <id>`.
- *Maximum-speed route* option (hides optional side quests).
- Route optimization model: `tools/build.ps1 routes` writes `docs/ROUTE_AUDIT.md` and fails the build on impossible quest order or quest-log overflow.
- `docs/AUTOMATION.md`, `docs/ROUTE_OPTIMIZATION.md`.

### Changed
- Routes: 26 impossible quest orders fixed (Horde, Draenei, Blood Elf, Netherstorm). About 90 pickups that were never turned in removed. 13 breadcrumbs now turned in where the route passes the recipient. Level gate added for Horde Feralas. Unreachable level-gated pickups removed. Peak quest log on the worst route went from 65 to 10. Details in docs/ROUTE_OPTIMIZATION.md.
- Optional turn-ins of breadcrumbs from an earlier guide are skipped when the quest is not in your log.
- Quest data import also exports `questFlags`.

### Fixed
- Test mocks (`tinsert`), so the headless test suite runs; it now runs as part of development (284 checks).

## 0.1.0
- First release.
