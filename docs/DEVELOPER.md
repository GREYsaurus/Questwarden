# Developer guide

## Layout

```
addon/                          SHARED add-on code (every target). Not installable on its own: the build stages it.
  addon.toc.in                  TOC template: load order, {{NAME}}/{{INTERFACE}}/... filled per target
  Bindings.xml.in               key bindings template
  Core/Init.lua                 namespace, event bus, helpers; derives every global name from the folder name
  Core/TargetCheck.lua          is this the client the build is for? refuses guides on any other (docs/COMPATIBILITY.md)
  Compat/Compat.lua             every game API call goes through here; missing APIs degrade, never error
  Core/SavedVars.lua            <name>DB (account) / <name>CharDB (character), defaults, validation
  Database/Schema.lua           field layout of the bundled data
  Database/QuestDB.lua          query API: GetQuestByID, GetNPCPosition, IsQuestAvailable, ... (+ overrides, dungeon helpers)
  Guides/Registry.lua           guide registration, filtering, route resolution, {name}/{slash} text
  Classes/Advice.lua            class tips lookup (the tips are target data)
  Talents/Talents.lua           build expansion/validation, live talent reading, talent points per level
  Core/ UI/ Gear/ Classes/      engine, windows, gear scoring, trainer and pet helpers
targets/<Target>/               EVERYTHING that differs between game versions
  target.json                   build metadata: interface, title, shipped?, coverage switches (require), evidence
  Target.<Target>.lua           game rules, shipped as Config/Target.lua (level cap, talent points, quest log, chapters, detection)
  addon/                        target data, staged over addon/: Database/Questie/*, RaceClass, Overrides, EscortQuests,
                                Dungeons, Guides/Compiled/*, Guides/Layouts, Classes/{ClassAdvice,TrainingData,TrainingNotes,PetData},
                                Talents/{Data,Builds,ProfileBuilds}, Gear/Profiles
  guides-src/                   guide SOURCES for this target (edit these)
tools/                          build tooling (PowerShell + C#), addon.json (the name), allowlist, upstream pins, research scripts
tests/                          headless Lua 5.1 harness with WoW API mocks
docs/                           documentation; docs/generated/<Target>/ holds build reports; docs/tbcguide/ is TBCGuide history
build/<Target>/<name>/          the staged add-on (generated, git-ignored): what lint, tests and packaging use
```

### Targets

| Target | What it is |
|---|---|
| `ClassicEra` | WoW Classic Era 1.15.9. The default and the shipped target. Phase 1: rules, detection and empty data. |
| `Forever` | WoW: Forever skeleton: unverified rules, empty data, `verified = false` so no guide ever loads. Never packaged until verified in the live client (docs/FOREVER_PLAN.md, Phase 3). |
| `TBC` | TBC Classic Anniversary: TBCGuide 0.9.5's data and guides (1-70). Shipped in the same download as Classic Era (TOC suffix `_TBC`), and the data the full engine suite runs on. |

Shared code never asks which target it is. It reads the target's rules from `ns.Target` (`Config/Target.lua`) and goes through `Compat.lua` for the game API. The build tools read the same `Target.<Target>.lua` (`tools/src/Ctx.cs`), so a limit such as the quest-log size is written once.

`target.json` `require` switches (`database`, `talents`, `routes`) tell the validator which coverage to enforce. A target being built turns each on once its data exists. Off is reported as "not required yet", never as a pass.

### The add-on's name

The name and slash command live in **`tools/addon.json`** and nowhere else. The build names the staged folder, the TOC, `Bindings.xml`, the SavedVariables and the zips after it, and writes the slash word into `Config/Brand.lua`. Lua code derives everything from the folder name at runtime: `ns.name`, `ns.key` (upper case, for global names), `ns.slash`, `ns.slashLong`, `ns.svAccount`, `ns.svChar`. Guide and talent-build text says `{name}` and `{slash}`. The lint gate fails on the name (or the old TBCGuide name) spelled in shipped code.

To rename: `tools/build.ps1 rename <NewName> [<slash>]`, then update the prose in README.md, INSTALL.md and docs/. Players' saved settings are keyed by the name, so a rename after a release starts them fresh.

## Build commands

```bash
powershell -ExecutionPolicy Bypass -File tools/build.ps1 all                 # ClassicEra
powershell -ExecutionPolicy Bypass -File tools/build.ps1 all -Target Forever
powershell -ExecutionPolicy Bypass -File tools/build.ps1 all -Target TBC     # the engine regression suite
```

`all` runs `stage`, `guides`, `lint`, `validate`, `routes`, `report`, `test` and, for a shipped target, `package`. **`package` builds one download for every shipped target** (`"shipped": true`): the shared code once at the root of the add-on folder, each target's data under `Targets/<Target>/`, and one `<name>_<tocSuffix>.toc` per target (`tocSuffix` in `target.json`: `Vanilla` for Classic Era, `TBC` for TBC Anniversary) listing the shared files plus that target's data. The client loads the TOC for its game type, as Blizzard's own UI does with `_Vanilla.toc` / `_TBC.toc`. A plain `<name>.toc`, a copy of the Vanilla one, is added because the CurseForge app refuses a zip whose root folder has no TOC of the same name; a client with no suffixed TOC of its own (Forever, until it gets a `tocSuffix`) would load it. The assembled folder (`build/Package/<name>/`) is tested through each TOC before it is zipped. Individual commands are listed at the top of `tools/build.ps1`. `zonequests "<Zone>" <Faction>` is an authoring aid that lists every quest in a zone from the bundled data.

## The lint gate

`tools/build.ps1 lint` parses every shipped `.lua` file of the staged add-on as Lua 5.1 and fails on:

- syntax errors;
- assignments to undeclared globals (a missing `local`). Our own globals are created through `_G[...]` from runtime names;
- reads of globals that are neither Lua builtins nor listed in `tools/wow_api_allowlist.txt`;
- the add-on's name spelled in an identifier or string (comments may mention it).

The allowlist is deliberately small and annotated. **Adding a WoW API is a reviewed decision**, which is how we keep Retail-only APIs out. If an API may be missing on some client, wrap it in `Compat.lua` and nil-check it. `tools/research/api_audit.py` checks the whole allowlist against Blizzard's UI source for a client (docs/COMPATIBILITY.md).

## Principles

- **Never block the player.** Every step can be marked done or skipped by hand. Auto-completion uses only reliable signals.
- **Database optional at runtime.** Compiled guides carry their own quest ids, NPC names and coordinates. `QuestDB.lua` returns nil or empty when records are missing, and every window works with no data at all (the smoke tests check this).
- **No fabricated data.** Quest ids, NPCs and coordinates come from the database or are explicitly marked unverified (`v=0`). Where data may come from: [DATA_POLICY.md](DATA_POLICY.md).
- **Client specifics live in `Config/Target.lua` (targets/) and `Compat/Compat.lua`.**

## Tests

`tools/build.ps1 test [-Target X]` stages the add-on, runs the build-tool self-test (`tests/tools-selftest.ps1`), then the Lua suite for that target:

- **TBC:** `tests/run_tests.lua`, the full headless harness (4,420 checks). It loads the staged add-on in TOC order against mock WoW APIs (`tests/mock_wow.lua`) and exercises boot, guide loading, progression, manual controls, saved-variable recovery, the talent engine, automation, markers, gear, routes and more.
- **ClassicEra, Forever:** `tests/run_smoke.lua`: the add-on boots with its own (empty) data without errors, the rules come from the target, the right client is accepted, other clients are refused, guide text placeholders expand, and the commands and windows work without data.

The test runners find the staged add-on through `build/<Target>/stage.lua` (`GUIDE_TARGET` picks the target; `stage.lua` also names the TOC and where the target's data sits, which is how `package` runs them against `build/Package/<Target>/stage.lua`). Any Lua 5.1 interpreter works. Without one, `tools/lua51.py` runs them with the Lua 5.1 runtime in Python's `lupa` package (`python -m pip install lupa`).
