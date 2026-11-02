# Third-party material in Questwarden

Questwarden's own code, guide routes, guide notes, talent builds and class advice are original work, licensed under **GPL-3.0-only** (see `LICENSE`).
The add-on also contains data derived from the third-party sources below. This file records what was taken, from where, at which exact version, what was changed, and what the licensing situation is.

> **Status in 0.1.0 (Phase 1):** the Classic Era release contains **no** QuestieDB-derived or client-table data yet. Sections 1 and 2 describe the TBC data kept as a test fixture (`targets/TBC/`, never shipped), inherited from TBCGuide. From Phase 2 they apply to Classic Era with the Classic file list and build, and will be updated then. Questwarden is a fork of TBCGuide (same author, GPL-3.0-only).

> **This is not legal advice.** The conclusions below are the project's reading of the upstream licence files. Get your own advice before redistributing commercially or if your jurisdiction recognises database rights (for example the EU *sui generis* database right).

---

## 1. QuestieDB (TBC quest, NPC, object, item and zone data)

| | |
|---|---|
| Upstream | https://github.com/Questie/QuestieDB |
| Parent project | https://github.com/Questie/Questie (QuestieDB's data, schema and corrections were imported from Questie; see `UPSTREAM_PROVENANCE.md`) |
| Exact version used | commit `7901fee2753cecb577a72c2e4b7126198e05baec` (QuestieDB **v1.0.9**, the database shipped in the Questie release bundle `bundle/v12.3.1+v1.0.9`, published 2026-10-26) |
| Archive checksum | SHA-256 `CB2330486A9BA5E041C8ADEE1B1A185B12C6BEE8FE4D0D2C94BF5BECB1100437` (GitHub source zip of that commit) |
| Files read | `data/TBC/tbcQuestDB.lua`, `tbcNpcDB.lua`, `tbcObjectDB.lua`, `tbcItemDB.lua`; `support/Zones/*.lua`; `src/corrections/Tbc/tbcQuestFixes.lua`; `src/corrections/enum/{zones,quests,factions,professions}.lua` |
| Dungeon entrances | `support/Zones/dungeons.lua` from commit `8f55e69de02e8a67229c4a54575f899244359cb8` (SHA-256 of the file `f36a9ef784322ed7da9916670b46bf76698f1f9a3cfede0895a49c6cbec64f60`), base Classic/TBC table only, written by `tools/research/dungeon_entrances.py` to `targets/<Target>/addon/Database/DungeonEntrances.lua` |
| Where it ends up | `targets/<Target>/addon/Database/Questie/*.lua` (generated), and the quest ids, NPC names and coordinates embedded in `targets/<Target>/addon/Guides/Compiled/*.lua` |
| Upstream licence files | `Database/Questie/UPSTREAM_LICENSE.md` (in each target's data) (verbatim copy of QuestieDB `LICENSE.md`), plus `gpl-3.0.md` in the upstream repo |

### Modifications made

`tools/src/QuestieImport.cs` and `tools/src/QuestieCorrections.cs` transform the upstream data:

- **Re-keyed and trimmed** records. Only the fields Questwarden uses are kept (see `addon/Database/Schema.lua`).
- **Applied the TBC quest corrections** statically: 4,440 field overrides applied and 5 skipped. Skipped corrections depend on the player's class, race or faction at runtime and are listed in `docs/generated/<Target>/questie-import.log`.
- **Reduced spawn lists** to a few points per zone, rounded to 0.1 map units.
- **Subset of entities.** NPCs, objects and items are kept only if a quest references them, or if they are trainers, flight masters or innkeepers.

Every generated file carries a header naming the upstream commit and pointing to this file.

### Licensing situation, as stated by upstream

QuestieDB's `LICENSE.md` (copied verbatim next to the data) says, in summary:

- Questie and QuestieDB historically had no licence. "When in doubt", content not otherwise covered should be considered **"all rights reserved"**.
- The Questie team is **"alright with others forking the repository or copying code from it under the GPLv3 terms"**, but **cannot promise that every historic contributor agrees**.
- A named list of contributors (including the data maintainers Muehe, Logon, TheCrux/BreakBB, Drejjmit, Cheeq, TechoHunter, Yttrium) has placed their contributions under GPLv3.
- Pull requests after 21.10.2026 count as consent to GPLv3.
- The permission **does not extend to the Questie name and logo**.

### What Questwarden does about it

1. The data is redistributed **under the GPLv3 terms the Questie team offers**, alongside the upstream licence text and provenance, unmodified.
2. Questwarden **does not use the Questie name or logo** for itself. Questie is named only for attribution.
3. Only **factual game data** is used: ids, names, levels, coordinates and prerequisites. No Questie code runs in the add-on, and no Questie UI, icons or localisation are shipped.
4. The data is **isolated and replaceable**. It lives in `Database/Questie/`, and the guide engine works without it, because compiled guides carry their own quest ids, NPC names and coordinates. The build can be pointed at a different, fully licensed data source by changing `tools/upstream.json` and the importer.
5. **Residual risk, stated plainly.** Upstream itself says not every historic contributor has consented. Distributors who need certainty should treat the bundled QuestieDB-derived data as having **unclear provenance for a minority of contributions**. See `docs/tbcguide/KNOWN_LIMITATIONS_0.9.5.md` for how to build a release without it.

---

## 2. World of Warcraft client tables (talent trees, race/class combinations)

| | |
|---|---|
| Source | DB2 exports of the game client (product `wow_anniversary`, build **2.5.6.70577**) via https://wago.tools |
| Tables | `Talent`, `TalentTab`, `SpellName`, `CharBaseInfo`, `ChrRaces`, `ChrClasses` (`Spell` was downloaded for reference but not used) |
| Where it ends up | `targets/<Target>/addon/Talents/Data/TalentTrees.lua`, `targets/<Target>/addon/Database/RaceClass.lua` (generated by `tools/src/ClientTables.cs`) |
| What is used | talent ids, names, tree, tier, column, rank count, spell id per rank, prerequisite; which races may be which classes |

These are factual game mechanics (talent positions and names), and they are what any WoW add-on reads from the client through the game's own API at runtime. **Talent descriptions are not copied.** The add-on shows the client's own tooltip for each spell id. World of Warcraft is a trademark of Blizzard Entertainment; Questwarden is not affiliated with or endorsed by Blizzard.

---

## 3. Sources consulted but NOT copied

| Source | Licence found | How it was used |
|---|---|---|
| Icy Veins (https://www.icy-veins.com/; Classic and TBC Classic leveling guides, read 2026-10-29) | Proprietary website content | Guide text, images and code not copied. The talent plans (`Talents/Builds/IcyVeins.lua` in each target's data) are the guides' talent allocations and point order, which are facts about the game: decoded from each guide's talent-calculator link (`tools/research/icyveins_classic_decoded.json` for Classic Era), matched to the client talent tables and checked against them (docs/TALENTS.md). Each plan names its source page. Chosen as the source by the project owner. |
| Warcraft Tavern (https://warcrafttavern.com/wow-classic/guides/mounts/ and https://www.warcrafttavern.com/tbc/guides/riding/, read 2026-11-01) | Proprietary website content | Not copied. Only facts were taken: the riding level and the gold price of riding training and the first mount, written by the project in `Database/Riding.lua` (Classic Era and TBC) with the source named. Approved as a source by the project owner on 2026-11-01. |
| wowforevertalents.com (https://wowforevertalents.com/; WoW: Forever talent calculator, read 2026-11-01) | Proprietary website content | Not copied. Only facts were taken: each Forever talent's tree, name, row, column, rank count, prerequisite and icon file name, written by `tools/research/forever_talents.py` to `tools/research/forever_talents.json` and by `tools/research/forever_talent_trees.py` to `targets/Forever/addon/Talents/Data/TalentTrees.lua` (`v=0`). No tooltip text. Checked against wowforever.gg (docs/FOREVER_PLAN.md). Chosen as the source by the project owner on 2026-11-01 (DATA_POLICY.md, Forever research). |
| Blizzard UI source (https://github.com/Gethe/wow-ui-source, branches `classic_era`, `forever`, `classic_anniversary`) | Blizzard Entertainment's code, no licence granted | Not copied and not shipped. `tools/research/api_audit.py` reads it locally (`.cache/`) to check whether each allowlisted API exists on a client (docs/COMPATIBILITY.md). |
| gnu.org | GPL text | `LICENSE` / `COPYING` are the verbatim GPLv3 text from https://www.gnu.org/licenses/gpl-3.0.txt (SHA-256 `3972DC9744F6499F0F9B2DBF76696F2AE7AD8AF9B23DDE66D6AF86C9DFB36986`). |

---

## 4. What's Training? (class-trainer spell lists and base prices)

| | |
|---|---|
| Upstream | https://github.com/fusionpit/WhatsTraining (by fusionpit) |
| Licence | MIT. The upstream `LICENSE` reads "Copyright (c) 2019" with no name; it is reproduced verbatim as `Classes/WhatsTraining_LICENSE.txt` in each target's data (Classic Era and TBC). |
| Exact version used | commit `26caff2fb3cb7d0bd5ed13c15b69be71a16dbafe` (branch `master`, 2026-10-07); its TOC lists Interface 20506 and 11509 and loads `Classes\[Game]\<Class>.lua` |
| Archive checksum | SHA-256 `f6c450080248113a60b00f2c9414e218b743318681ab4d79781f623199c8d59f` (GitHub source zip of that commit) |
| Files read | `Classes/Vanilla/<Class>.lua` (Classic Era), `Classes/TBC/<Class>.lua` (TBC), `Classes/<Game>/HunterPets.lua` (only to leave pet abilities out), `LICENSE` |
| Where it ends up | `targets/<Target>/addon/Classes/WhatsTrainingData.lua` (generated by `tools/research/whatstraining_import.py`; no Forever data) |
| What is kept | per spell: training level, base price (copper), required earlier ranks, required talent, faction, races, skill requirement |
| What is not | the add-on's code, interface, artwork, libraries, pet abilities, Warlock tomes and weapon skills |

The data is facts about the game (which trainer teaches which spell id at which level and price), collected by the What's Training? author; the MIT licence covers its use and redistribution with the notice.

---

## 5. CMaNGOS world databases (time limits of timed quests)

| | |
|---|---|
| Upstream | https://github.com/cmangos/classic-db and https://github.com/cmangos/tbc-db (the CMaNGOS project) |
| Licence | GPL-3.0 (each repository's `LICENSE.md`; licence checked 2026-11-01). Their `COPYRIGHT.md` adds that World of Warcraft content is Blizzard's and is used by CMaNGOS as non-commercial fair use. |
| Exact version used | classic-db commit `603ece109099ce44a5447a1b1cffd65c7272d71c` (2026-10-25), `Full_DB/ClassicDB_1_12_1_z2815.sql.gz`, SHA-256 `4f92db520868ab4e566726f68b5b2e380ae781209beaf22237b4f7f04600d0c0`; tbc-db commit `1c54acd200540076c3078d22a66fd417d0f6dd60` (2026-10-26), `Full_DB/TBCDB_1.11.0_Vengeance_One_A_Cmangos_Story.sql.gz`, SHA-256 `dfd269a33923debba9954dfe8d120a04ffef3a3d683a513a9a5634f98808d8fb` |
| Files read | the `quest_template` table: columns `entry`, `LimitTime` and `Title` |
| Where it ends up | `targets/<Target>/addon/Database/QuestTimers.lua` (generated by `tools/research/quest_timers.py`; Forever uses the classic-db values) |
| What is kept | per timed quest in the bundled quest data: quest id and time limit in seconds (the title only as a comment) |
| What is not | everything else in the databases: no other table, column, text or script |

The time limits are facts about the game. QuestieDB, the main quest source, has no time-limit field.

---

## 6. Optional integrations (not bundled)

None. Questwarden used to send waypoints to TomTom if it was installed; that was removed in 0.1.0-alpha.6, and its own arrow, world-map pin and minimap pin replace it.
