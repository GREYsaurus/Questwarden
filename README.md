# ClassicGuide

A **free** leveling guide and talent add-on for **World of Warcraft Classic Era** (client 1.15.9, interface `11509`) and **TBC Classic Anniversary** (client 2.5.6, interface `20506`), in one download, built so it can also target **World of Warcraft: Forever** once that game is live and its data has been checked.

ClassicGuide is a sibling of [TBCGuide](https://github.com/GREYsaurus/TBCGuide) (the TBC Classic Anniversary guide). It forks TBCGuide's engine, interface, compatibility layer, tests and build tools, and adds its own data for each game version.

> **Status: 0.1.0 in development, Phase 1 of 3.** The multi-target build, wrong-client detection and test harness are done. **There are no Classic Era guides, quest data or talent trees yet**; they arrive in Phase 2. Nothing has been loaded in the game client yet. Plan and progress: [CHANGELOG.md](CHANGELOG.md), [docs/DATA_GAPS.md](docs/DATA_GAPS.md).

## What it will do (from TBCGuide, rebuilt for Classic Era)

- **Level 1-60 guides for every Classic race/class combination** (8 races, 9 classes, Alliance and Horde), covering every racial start and leveling zone.
- **Two route flavors:** Speed (default), and Hardcore/Survival, which avoids dangerous mobs and risky pulls, adds warnings, and never relies on a soulstone or Reincarnation.
- **Every step can be completed or skipped by hand**, so you never get stuck. Automatic progression from the quest log, quest-completion flags, level, hearthstone and flight paths.
- **Bundled quest database** derived from QuestieDB, so Questie is not required.
- **Navigation:** built-in arrow, world-map pin and optional TomTom waypoints.
- **Talent guide and calculator** from client data, with leveling and level-60 builds (tank, healer and DPS where relevant), each checked point by point against the 51-point Classic trees.
- **Quest automation** that never auto-accepts escort quests and never picks rewards for you, junk selling (off by default), orphaned-quest finder, raid markers, gear scoring with researched stat weights, auto-equip (never Bind-on-Equip), bag-addon markers, an auction house Upgrades tab, flight/inn/gossip automation, a leveling tracker, and a settings window with profiles.

**One download, two games.** The add-on folder has a `ClassicGuide_Vanilla.toc` for Classic Era and a `ClassicGuide_TBC.toc` for TBC Classic Anniversary; each client loads its own file, with its own quest data, guides (1-60 on Classic Era, TBCGuide's 1-70 routes on TBC) and talent trees. The TBC data and guides are those of TBCGuide 0.9.5; do not run TBCGuide and ClassicGuide together: both would act on the same quests and NPCs. If a build still meets the wrong client, it says so at login and loads no guides.

## Install

See [INSTALL.md](INSTALL.md). In short: copy the `ClassicGuide` folder (the one containing `ClassicGuide_Vanilla.toc` and `ClassicGuide_TBC.toc`) into the game's `Interface\AddOns` folder, for example

```
World of Warcraft\_classic_era_\Interface\AddOns\ClassicGuide\ClassicGuide_Vanilla.toc
```

## Use

| Command | Action |
|---|---|
| `/cg` (or `/classicguide`) | Show/hide the guide window |
| `/cg guide` | Guide browser |
| `/cg talents` | Talent guide and calculator |
| `/cg next` / `/cg prev` / `/cg skip` | Manual step control |
| `/cg options` | Settings window |
| `/cg gear` (or `/cggear`) | Equipped gear and upgrades |
| `/cg debug` / `debug api` / `debug errors` | Diagnostics, including which client the build was made for |
| `/cg help` | All commands |

In the guide window, **left-click** a step to mark it done and **right-click** it to skip it.

## Licence

ClassicGuide is free software under the **GNU General Public License v3.0 only** (`LICENSE`, `COPYING`). The full corresponding source is this repository; each release also ships a `-source.zip`.

Bundled third-party data and its licensing are described in [NOTICE.md](NOTICE.md) and [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md). Where the data comes from, and what we never copy, is in [docs/DATA_POLICY.md](docs/DATA_POLICY.md).

## For developers

- [docs/DEVELOPER.md](docs/DEVELOPER.md): layout, targets, build and test commands
- [docs/DATA_POLICY.md](docs/DATA_POLICY.md): allowed data sources and the cross-check process (read this before adding data)
- [docs/DATA_GAPS.md](docs/DATA_GAPS.md): what is not known or not verified yet
- [docs/GUIDE_FORMAT.md](docs/GUIDE_FORMAT.md): how to write guides
- [docs/DATA_PIPELINE.md](docs/DATA_PIPELINE.md): refreshing the bundled data
- [docs/COMPATIBILITY.md](docs/COMPATIBILITY.md): target clients, wrong-client detection, API audit, in-game checklist
- [docs/KNOWN_LIMITATIONS.md](docs/KNOWN_LIMITATIONS.md)
- [docs/tbcguide/](docs/tbcguide/): TBCGuide's TBC-specific research and reports, kept for reference
- [CHANGELOG.md](CHANGELOG.md)
