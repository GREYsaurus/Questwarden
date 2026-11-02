# Phase 3: World of Warcraft: Forever

Plan and status for the Forever target (`targets/Forever/`). Forever launches on 2026-11-04. Until its data has been checked in the live client, `Target.Forever.lua` keeps `verified = false`: the add-on loads no guides on Forever, the target is not packaged, and its route audit only reports. Everything below marked *unverified* stays that way until checked in game (docs/DATA_POLICY.md).

## Sources

| Source | What it gives | Status |
|---|---|---|
| **QuestieDB Forever** (`data/Forever`, same GPL-3.0 repository and pinned commit as the Classic data) | quests, NPCs, objects, items; Forever's quest corrections | **approved** by the maintainer (2026-10-31). It is Classic Era's data with every coordinate converted to Forever's map frames (QuestieDB `docs/forever.md`, `docs/forever-data.md`: 13,691 pairs converted, 6 left unresolved), plus a generated "delta base" and traces taken from Forever client snapshots and play sessions. Not complete new content |
| **Client tables** (wago.tools product `wowf`, build 1.60.1.70685) | race/class table, flight graph, talents, trainer and pet spells | the product is *assumed* to be Forever: its build matches QuestieDB's conversion target (1.60.1.69893) and Blizzard's `forever` UI source (1.60.1) |
| **Blizzard's UI source**, branch `forever` | which APIs exist; the project id (`WOW_PROJECT_CAMELOT = 18`) | reference only (`tools/research/api_audit.py`) |
| **Our own captures** (recorder module, below) | positions, givers, finishers, flight times, patrols | to build |

## Done (2026-10-31)

- **Quest data imported** (`tools/build.ps1 import-questie -Target Forever`): 5,232 quests (975 more than Classic Era), 5,470 NPCs, 854 objects, 3,007 items. QuestieDB's quest-correction layers are applied in its own order (`target.json questie.fixList`): inherited Classic fixes, the generated delta base, traces, then Forever's own fixes. 16,549 corrections applied, 25 skipped (profession specialisations). The importer gained per-target zone support folders, ordered fix layers, `*_add`/`*_remove` correction keys (merged into the field, as QuestieDB does), the Skyborne race masks (bits 33 and 34) and race masks wider than 32 bits.
- **Gaps in that data:** 600 items, 308 NPCs and 78 objects that new delta-base quests refer to are not in QuestieDB's Forever tables (`docs/generated/Forever/questie-import.log`).
- **Classic Era routes compile on Forever** (`target.json guidesFrom: ClassicEra`): 107 guides, 1,309 quests, 0 errors, 66 warnings. With borrowed guide sources a renamed quest is a warning (the id decides: Forever calls three bounties "WANTED: …"), and a hunting route that no longer fits Forever's spawns is left out (one in Mulgore).
- **Route audit:** 92 race/class routes walked; 6 errors, all Forever data differences: *Call of Earth* (shaman) gained a new prerequisite (92466), and the new Orc Mage meets *Hidden Enemies*' complete step without its pickup. The audit reports these without failing the build, because the target is unverified.
- **Client tables:** the race/class table has 46 combinations (Classic Era 40), with Forever's new ones (Dwarf Shaman, Undead Paladin, Orc Mage, Troll Warlock …). The flight graph has 68 nodes, including new zones (Mount Hyjal, Riverglades).
- **Client detection:** builds refuse the wrong client by project id as well as interface number (`WOW_PROJECT_CAMELOT` exists only on Forever). Hardcore realms are detected automatically (`C_GameRules.IsHardcoreActive`, present on Forever too).

## Client tables (2026-11-01)

- **Trainer lists imported** (`targets/Forever/addon/Classes/TrainingData.lua`, 1,451 ranks, unverified). The importers now read Forever's columns: class skill lines carry an extra flag bit (1040 instead of 16), talents name no class (it comes from their tab), and `SkillLineAbility.RaceMask_0` is `RaceMasks_0`. Classic Era and TBC output is unchanged. Not yet handled: race bits above 32 (`RaceMasks_1`, the Skyborne races), and spells with no level row (174 left out as "level 1", against 112 on Classic Era); both need a check in game.
- **Talent trees: not in the client tables.** The base tables of builds 1.60.1.70685 and 70707 still hold Classic Era's 433 talents, unchanged. The game's Forever trees (about 466 talents, 116 new, per the trackers below) come from **server hotfixes** held in the client's hotfix cache, which the wago.tools table exports do not include. So `target.json clientTables.talents` is `false`: the importer leaves `Talents/Data/TalentTrees.lua` empty for Forever instead of writing Classic's trees. Most new talents' spells are in the client spell tables already (Spearing Strike, Raging Blows, Arcane Wrath, Shifting Power, Dark Inspiration); some are not (Oath of Light, Stoicism, Boundless Light, Shieldsworn).
- **Sources for the trees** (research, 2026-11-01): wowforevertalents.com (read from the Forever client's hotfix cache of 30 October, build 70707; lists every new, changed and dropped talent), the Wowhead Forever talent calculator, wowforever.gg, maxroll.gg's class deep dives. Two ways to get them: parse the hotfix cache (`DBCache.bin`) of the maintainer's own Forever client (src `client`), or enter the trees from the calculators by hand (src `research:<url>`, v=0).
- **Demon Grimoires:** none found in Forever's item table (0 of 63 demon skills taught by a Grimoire; Classic Era 59). Unverified whether Forever changed how demon spells are learned.

## To do, in order

1. **Forever talent trees** from the hotfix cache or the calculators (above), then talent plans for them.
2. **Skyborne and the new race/class combinations.** Add the Skyborne races to the race tables (client race ids, `RaceClass.lua`), to `Database/Schema.lua` race bits and to every race check in the add-on. The add-on's race masks must not go through the 32-bit `bit` library (Skyborne is bit 33/34). Then route the new combinations (Orc Mage, Undead Paladin …) and a Skyborne start.
3. **Forever-specific guide fixes.** A way for a target that borrows guide sources to override single steps (an overlay guide folder, or a `[target=Forever]` flag), then fix the 6 audit errors, the renamed quests and the dropped Mulgore route.
4. **API adapters.** 49 allowlisted names are not found in the Forever UI source (`docs/generated/Forever/api-audit.md`): the old talent API (`GetNumTalentTabs`, `UnitCharacterPoints`), `AbandonQuest`, `ConfirmBinder`, the old gossip and auction functions, `GetQuestsCompleted`, pet training points and the craft API, `InterfaceOptions_*` (Forever has `Settings`). Each needs a Compat adapter to the modern API or a guarded fallback; the talent window and auction tab need the most work.
5. **Recorder module.** An opt-in module that records what the player sees into SavedVariables: quest givers and finishers with positions, objective NPC and object positions, flight times, patrols, and Skyborne/new-zone quests that QuestieDB lacks. A build step imports the captures as source `capture` (DATA_POLICY.md), never overriding QuestieDB without review.
6. **New content.** Routes for the new zones (Mount Hyjal, Riverglades, Zephras Isle …) and dungeons, once quest data exists (QuestieDB updates or captures).
7. **Launch checks, then ship.** In the live client: the AddOns folder; which TOC suffix Forever loads (QuestieDB uses the game types `camelot` and `forever`; Blizzard's own add-ons are not suffixed for it yet); the quest log size (40 in the UI constants); talent points from level 10; the API list. Then set `verified = true`, give Forever a `tocSuffix`, mark it `"shipped": true` and add it to the one download.

## What cannot be settled before launch

The TOC suffix, the AddOns path, whether `wowf` is Forever, quest-log size, how much of Classic's routes still hold (QuestieDB's conversion assumes no world positions moved), and everything about new content.
