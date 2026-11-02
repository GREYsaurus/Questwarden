# Data pipeline: refreshing the bundled database and talent data

Players never run any of this. The released add-on already contains the generated files.

> **Per target.** Every command takes `-Target`. Which QuestieDB files a target imports (data folder, file prefix, corrections file and module, XP table, NPC flag values) and which client build its tables come from are set in `targets/<Target>/target.json` (`questie`, `clientTables`). Client tables are cached per build in `.cache/upstream/db2/<build>/`.
>
> - **Classic Era:** QuestieDB `data/Classic/classic*DB.lua` with `src/corrections/Era/classicQuestFixes.lua`; client product `wow_classic_era` 1.15.9.70576. NPC flags use the vanilla numbers (flight master 8, innkeeper 128). The 1.15 client tables also carry Season of Discovery and seasonal spells (ids 400000 and up, with no other marker), so `clientTables.excludeSpellIdsFrom = 400000` leaves them out of the trainer and pet data and lists each one in `docs/generated/ClassicEra/client-excluded-spells.csv`.
> - **TBC fixture:** QuestieDB `data/TBC` with `tbcQuestFixes.lua`; client product `wow_anniversary` 2.5.6.70577. Re-importing it reproduces TBCGuide 0.9.5's data.
> - Every record of a generated file comes from one source, so `src` and `v` are stated once in the file header (`src = questie` or `src = client`, `v = 1`) rather than on each of thousands of records. Records from mixed sources (overrides, captures) carry their own.

```
tools/upstream.json  --fetch-->  .cache/  --import-questie-->  targets/<Target>/addon/Database/Questie/*.lua
                                          --import-client--->  targets/<Target>/addon/Talents/Data/TalentTrees.lua
                                                               targets/<Target>/addon/Classes/TrainingData.lua
                                                               targets/<Target>/addon/Database/RaceClass.lua
                                                               targets/<Target>/addon/Database/Flights.lua (clientTables.flights)
targets/<Target>/guides-src/*.guide  --guides (uses the generated DB)-->  targets/<Target>/addon/Guides/Compiled/*.lua
```

## 1. Pin the upstream version

Edit `tools/upstream.json`:

- `questiedb.commit`: a specific QuestieDB commit or release, never `master`/`latest`. To find the commit Questie shipped, open the `release.json` asset of a Questie release (`bundle/vX+vY`) and read `questiedb.producerCommit`.
- `questiedb.archiveSha256`: SHA-256 of `https://codeload.github.com/Questie/QuestieDB/zip/<commit>`. The build refuses a mismatched archive. When you change the commit, download the zip once, run `Get-FileHash`, and record the value.
- `clientTables.build`: the client build to export talent and race tables from (see https://wago.tools/api/builds, product `wow_anniversary`).

## 2. Fetch and verify

```bash
powershell -ExecutionPolicy Bypass -File tools/build.ps1 fetch
```

This downloads the pinned QuestieDB source archive into `.cache/`, verifies its SHA-256, extracts only the files listed in `upstream.json` (missing files are an error), and downloads the client CSV tables.

## 3. Import

```bash
powershell -ExecutionPolicy Bypass -File tools/build.ps1 import-questie
powershell -ExecutionPolicy Bypass -File tools/build.ps1 import-client
```

`import-questie`:

- parses the upstream Lua data with a literal-only reader. **No upstream code is executed.**
- applies `tbcQuestFixes.lua` with a restricted static evaluator. It accepts literals, enum constants, `l10n("...")` and `+`/`-`; anything runtime-dependent is skipped and logged.
- writes the trimmed data and `docs/generated/<Target>/questie-import.log`, which has record counts, applied and skipped corrections, and dangling references.

`import-client` writes the talent trees (positions, ranks, prerequisites and spell ids per rank) and the race/class table. On targets with `clientTables.flights` it also writes the flight graph: every faction flight node with at least one flight, its zone and map position (from `UiMapAssignment`), its flight master (the nearest flight-master NPC of that faction in the bundled data, within 3% of the map) and its direct flights. Transports, quest-only paths and battleground nodes are left out. Flight times are not in the client tables.

## 4. Re-validate everything

```bash
powershell -ExecutionPolicy Bypass -File tools/build.ps1 all
```

If quests changed upstream, the guide compiler reports any guide step whose quest no longer exists, changed name or changed faction.

## 5. Licence housekeeping when updating

- Copy the upstream `LICENSE.md` and `PROVENANCE.md` into `targets/<Target>/addon/Database/Questie/UPSTREAM_*.md` again. `fetch` puts them in `.cache/upstream/questiedb/`.
- Update the commit, version and checksum in `THIRD_PARTY_LICENSES.md` and `NOTICE.md`.
- Re-read the upstream licence for changes before releasing.

## Data provenance of each generated file

| File | Source | Generator |
|---|---|---|
| `Database/Questie/Quests.lua` | QuestieDB `data/TBC/tbcQuestDB.lua` + `tbcQuestFixes.lua` | `QuestieImport.cs`, `QuestieCorrections.cs` |
| `Database/Questie/Npcs.lua`, `Objects.lua`, `Items.lua` | QuestieDB TBC entity tables | `QuestieImport.cs` |
| `Database/Questie/Zones.lua` | QuestieDB `support/Zones/*` | `QuestieImport.cs` |
| `Database/Questie/SpiritHealers.lua` | QuestieDB NPC table: every spawn of NPCs named Spirit Healer (`questie.spiritHealers`) | `QuestieImport.cs` |
| `Database/Questie/Patrols.lua` | QuestieDB NPC table: waypoints of the bundled NPCs, small paths dropped and the rest simplified (docs/PATROLS.md) | `QuestieImport.cs` |
| `Talents/Data/TalentTrees.lua` | client DB2 `Talent`, `TalentTab`, `SpellName` | `ClientTables.cs` |
| `Classes/TrainingData.lua` | client DB2 `SkillLine`, `SkillRaceClassInfo`, `SkillLineAbility`, `SpellLevels`, `Spell`, `SpellName`, `Talent` | `TrainingTables.cs` (rules: docs/TRAINER.md) |
| `Database/RaceClass.lua` | client DB2 `CharBaseInfo`, `ChrRaces` | `ClientTables.cs` |
| `Database/Flights.lua` | client DB2 `TaxiNodes`, `TaxiPath`, `UiMapAssignment` + bundled `Npcs.lua`, `Zones.lua` | `FlightTables.cs` |
| `Guides/Compiled/*.lua` | `guides-src/*.guide` + the files above | `GuideCompiler.cs` |
| `Classes/WhatsTrainingData.lua` | What's Training? `Classes/Vanilla` or `Classes/TBC` at commit `26caff2` (`tools/upstream.json` `whatstraining`), MIT | `tools/research/whatstraining_import.py <Target> <checkout> <commit>`; also writes `docs/generated/<Target>/whatstraining-crosscheck.md` |
| `Database/QuestTimers.lua` | CMaNGOS `quest_template.LimitTime`: classic-db commit `603ece1` (Classic Era, Forever), tbc-db commit `1c54acd` (TBC) (`tools/upstream.json` `cmangos`), GPL-3.0 | `tools/research/quest_timers.py <Target> <Full_DB .sql.gz> <repository> <commit>` |
| `Database/DungeonEntrances.lua` | QuestieDB `support/Zones/dungeons.lua` at commit `8f55e69` (`tools/upstream.json` `questiedbDungeons`), base Classic/TBC table, limited to the target's `Database/Dungeons.lua` | `tools/research/dungeon_entrances.py <Target> <dungeons.lua> <commit>` |

## Quest flags (0.2.0)

The importer now also exports QuestieDB `questFlags` as quest field 26 (`ns.QDB.QUEST.FLAGS`). Bit 2 (`PARTY_ACCEPT`) is one of the escort signals used by the quest automation (`DB.GetEscortStatus`, docs/AUTOMATION.md). Re-importing at the pinned commit changes only `Quests.lua`, and only by appending that field.

Quest field 27 (`ns.QDB.QUEST.REQ_SOURCE`) is QuestieDB's `requiredSourceItems`: items the objectives need that are not objectives themselves (117 Classic Era quests, 154 TBC, 124 Forever). While such an item is not in the bags, a quest's complete step points the arrow at where it drops before the objective (`DB.GetObjectiveLocation`); for example *Marla's Last Wish* sends you to Samuel Fipps for his remains before Marla's Grave. Items the quest giver hands out are left out. Those items also count as quest items (`DB.GetQuestItems`). Re-importing at the pinned commit changes only `Quests.lua`, by appending that field.
