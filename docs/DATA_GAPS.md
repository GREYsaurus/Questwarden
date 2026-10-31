# Data gaps: what we do not know yet

Facts ClassicGuide could not rebuild from its own sources (docs/DATA_POLICY.md), and values we hold but have not verified. Nothing here is filled in from another add-on's data. Each entry says how to close it. Update this page whenever data is generated, cross-checked or checked in the game.

Status: **0.1.0 development, Phase 2 in progress.** The Classic Era quest database, talent trees, race/class table, trainer and pet data are generated; the first two routes (Human and Orc/Troll, 1-12) are written.

## Classic Era (1.15.9)

| Item | Status | How to close it |
|---|---|---|
| Quest, NPC, object, item and zone data | **Built**: 4,257 quests, 4,835 NPCs, 852 objects, 2,865 items; 3,041 corrections applied | 23 corrections skipped (profession specializations and one rank expression; `docs/generated/ClassicEra/questie-import.log`); only quest corrections are applied, not QuestieDB's NPC, object or item fixes |
| Talent trees (51 points), race/class table | **Built**: 432 talents in 27 trees (7 tiers), 8 races, 40 combinations | check in game with `/cg debug talents` |
| Trainer spells, pet and demon skills | **Built**: 1,329 trainer ranks, 19 hunter pet families, 63 demon skills. Trainer notes (`Classes/TrainingNotes.lua`) mark 22 class-quest spells and list important and optional spells. The escort safeguard list (`Database/EscortQuests.lua`) holds 52 quests | Seasonal spells (ids 400000+) are left out by rule, and so is Mangle (22570): the 1.15.9 tables list it at druid level 6, but Classic Era has no Mangle. Spot-check `docs/generated/ClassicEra/client-excluded-spells.csv` in game. The quest-spell bundles come from the client's own teaching spells; the quest names and levels are unverified in game. *Summon Incubus* (level 20) is in the client tables, so it is kept; check in game that Era warlocks can learn it |
| Flight-path graph | **Built** from the client's `TaxiNodes`/`TaxiPath` (`Database/Flights.lua`): 64 nodes, 268 direct flights; 61 nodes tied to their flight master. Every `fp` step resolves to a node; the route audit checks `fly` steps against the paths learned on each route; 10 visits now start with a flight | The two druid-only Nighthaven nodes and Plaguewood Tower have no flight master in the data. Flight **times** are measured in game (`Core/FlightTimer.lua`). *Flight to Auberdine*: the Night Elf route flies Rut'theran to Auberdine before learning Auberdine, as the quest text says; marked unverified, check in game. Flight paths learned in the start zones are not counted when adding fly steps (they differ by race) |
| Spirit healers | Not built | QuestieDB has only 14 Spirit Healer records; graveyard positions are in the client table `WorldSafeLocs` (not fetched yet) |
| Gear stat priorities | **Built**, priority-only (`Gear/Profiles.lua`, GEAR_RESEARCH_CLASSIC.md): 14 leveling profiles for 7 classes and 19 level-60 profiles for every spec Icy Veins covers. No Classic source publishes numeric weights | **Rogue and Hunter have no leveling profile:** no usable source ranks their leveling stats. **Warlock leveling** comes from the Hardcore page. Check in game how `GetItemStats` reports Classic hit and crit (percent) |
| Rares and dangerous mobs | **Built** from QuestieDB NPC data: every hostile elite, rare elite and rare with spawns is bundled (`questie.allDangerousMobs`), patrols flagged from waypoints. `danger_report.py` checks route steps against them (elite, rare 2+ levels above, normal mob 5+ above, within 40 yards); all 13 steps found have Hardcore notes | QuestieDB spawn points are not complete for every rare, and roaming rares move. Check the pins and notes in game; re-run the report after route changes |
| XP model for the route audit (quest XP, XP per level) | Missing | QuestieDB `support/QuestXP` Classic table plus the Classic XP-per-level table from a citable source |
| Interface 11509 | Verified from sources (wago.tools build list, Questie release.json, Blizzard UI source), **not yet loaded in the client** | load the add-on in the client |
| Quest log size 20 | From Blizzard's UI source (`Blizzard_FrameXMLBase/Vanilla/Constants.lua`) | confirm in game |
| API availability | 35 of the 284 audited names are not found in Blizzard's Classic Era UI source (docs/generated/ClassicEra/api-audit.md). Nearly all are guarded legacy fallbacks; `GetPlayerFacing` (arrow), `GetMacroIndexByName` (targeting macro) and `GetItemStats` (gear scoring) need an in-game check. 32 APIs reached by name through Compat are not on the allowlist (awaiting review) | `/cg debug api` in the client |
| Hardcore realm detection | Manual per-character setting only | needs `C_GameRules.IsHardcoreActive` on the allowlist (awaiting approval) |
| Group content | 43 elite/group and dungeon quests (plus 2 lead-ins) are opt-in content: 26 given in the guide's own zone, 13 at city and neighbouring-zone visits, 4 in chains through Blackrock Spire and Blackfathom Deeps. 59 dungeon quests are still missing (`docs/generated/ClassicEra/dungeon-unplaced.csv`): late pickups in zones the routes leave earlier (Dire Maul, Maraudon, Blackrock), lead-ins that are escorts or whose objective NPCs have no spawn data (Overmaster Pyron, Screecher Spirits), and quests given inside instances no route enters | a level 55-60 return pass (Feralas, Desolace, Badlands and Burning Steppes) would reach most; spawn data needs in-game capture |
| Quest XP left for solo outdoor routes | Zone-order routes (2026-10-30): quests carry about 28 levels after the start zones. The model leaves about 20 levels to grinding and dungeons (Alliance 20.1, Horde 20.3) at the assumed kill XP; less if kills give more. Elite/group and dungeon quests are opt-in and not counted | play-test the zone order; measure kill XP |
| Kill XP share in the route model | Assumed 0.5 x quest XP (TBCGuide's rule of thumb); the grind estimate moves from about 24 to about 15 levels if it is 1.0 | measure XP from kills vs quests on a few zones in game |
| Routes 1-60, all 40 race/class combinations | Rebuilt to the maintainer's zone order (`targets/ClassicEra/zone-order.json`, one guide per visit, 107 guides); audited offline (Speed and Hardcore): 0 order errors, quest log at most 15/20 | **7 empty visits:** each holds only a note and a level step, after quests were spread across repeat visits (`spread_visits.py`).
- Alliance: Darkshore 23-24, Alterac 37, Felwood 58, Azshara 58 and Tanaris 58.
- Horde: Dustwallow 49 and Burning Steppes 53.

The data has no unused or better-fitting quests for them. About 10 more visits hold only 1-2 quests. **Westfall, Redridge and Silverpine** are not in the order, so their quests are gone (`zone-order-dropped.csv`). Hunting routes (`guides-src/routes`) were generated from TBC spawn data; the compiler re-checks every drop and spawn against Classic data, but they have not been regenerated from Classic spawns. Not timed or played |
| Warrior Defensive Stance | **Answered from client data:** *Path of Defense* (8121), the level-10 class quest's teaching spell, teaches Defensive Stance, Taunt and Sunder Armor together. *Path of the Berserker* (8616) teaches Berserker Stance and Intercept. All are marked as quest spells | confirm in game |

## WoW: Forever (not launched; launch 2026-11-04)

Everything below is **unverified** and stays `v=0` until checked in the live client.

| Item | What we have | Source / why unverified |
|---|---|---|
| Interface 16001, build 1.60.1 | from Questie release.json (flavor `forever`), wago.tools product `wowf` 1.60.1.70685, Blizzard UI source branch `forever` 1.60.1 (70532) | beta-era sources; `wowf` = Forever is an assumption |
| Quest log size | 40 in the Forever UI's generated API docs (`QuestLogConsts.MAXIMUM_NUM_QUESTS_LOG_CAN_ACCEPT`) | that is the modern client's constant; may not be what Forever enforces |
| Client API | The Forever UI source is the modern client code with a Camelot (Forever) overlay. 21 APIs the add-on uses on Classic Era are not found there, including `GetNumTalentTabs`, `UnitCharacterPoints`, `AbandonQuest`, `ConfirmBinder`, the old auction functions, some item functions, pet training points and the craft APIs (docs/generated/Forever/api-audit.md) | talents, orphan abandoning, hearth binding, the auction tab and pet skills need Forever adapters (Phase 3) |
| Map coordinates | QuestieDB's Forever data converted 13,691 coordinate pairs from Era to Forever map frames (its docs/forever.md) | Classic Era coordinates **cannot** be reused as they are |
| Talent points from level 10, 51 at 60 | assumed | Forever announces new talents |
| New zones (4, including Zephras Isle), 9 new dungeons, Skyborne race, new race/class combinations, new skills and talents | names only, from announcements and as a checklist; no IDs held | capture in game (recorder module, Phase 3) |
| AddOns folder | unknown | confirm after launch |

## Cross-check results

None yet. `tools/build.ps1 crosscheck` arrives with the Phase 2 data pipeline; its report will be `docs/generated/CROSSCHECK.md`, and disagreements will be listed here.
