# Changelog

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
