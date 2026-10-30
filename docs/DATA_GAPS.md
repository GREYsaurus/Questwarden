# Data gaps: what we do not know yet

Facts ClassicGuide could not rebuild from its own sources (docs/DATA_POLICY.md), and values we hold but have not verified. Nothing here is filled in from another add-on's data. Each entry says how to close it. Update this page whenever data is generated, cross-checked or checked in the game.

Status: **0.1.0 development, Phase 1** (multi-target scaffolding). No Classic Era data has been generated yet, so most of the Classic Era list is "not built yet" rather than "missing".

## Classic Era (1.15.9)

| Item | Status | How to close it |
|---|---|---|
| Quest, NPC, object, item and zone data | Not built yet (Phase 2) | `import-questie` from the pinned QuestieDB `data/Classic` files |
| Talent trees (51 points), race/class table (8 races, 9 classes) | Not built yet (Phase 2) | `import-client` from the 1.15.9.70576 client tables |
| Trainer spells, flight-path graph, spirit healers | Not built yet (Phase 2) | client tables; flight **times** need in-game captures |
| Rares and dangerous mobs | Not built yet (Phase 2) | QuestieDB NPC data plus our own criteria (elite, rare, level above the route's expected level, patrols) |
| XP model for the route audit (quest XP, XP per level) | Missing | QuestieDB `support/QuestXP` Classic table plus the Classic XP-per-level table from a citable source |
| Interface 11509 | Verified from sources (wago.tools build list, Questie release.json, Blizzard UI source), **not yet loaded in the client** | load the add-on in the client |
| Quest log size 20 | From Blizzard's UI source (`Blizzard_FrameXMLBase/Vanilla/Constants.lua`) | confirm in game |
| API availability | 35 of the 284 audited names are not found in Blizzard's Classic Era UI source (docs/generated/ClassicEra/api-audit.md). Nearly all are guarded legacy fallbacks; `GetPlayerFacing` (arrow), `GetMacroIndexByName` (targeting macro) and `GetItemStats` (gear scoring) need an in-game check. 32 APIs reached by name through Compat are not on the allowlist (awaiting review) | `/cg debug api` in the client |
| Hardcore realm detection | Manual per-character setting only | needs `C_GameRules.IsHardcoreActive` on the allowlist (awaiting approval) |

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
