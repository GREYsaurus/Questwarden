# Questwarden

A **free** leveling guide and talent add-on for **World of Warcraft Classic Era** (client 1.15.9, interface `11509`) and **TBC Classic Anniversary** (client 2.5.6, interface `20506`), in one download, built so it can also target **World of Warcraft: Forever** once that game is live and its data has been checked.

Questwarden grew out of [TBCGuide](https://github.com/GREYsaurus/TBCGuide): it forks TBCGuide's engine, interface, compatibility layer, tests and build tools, ships TBCGuide's TBC data and 1-70 routes for TBC Classic Anniversary, and adds its own data and routes for Classic Era.

> **Status: alpha (0.1.0-alpha.16).** Classic Era 1-60 routes for all 40 race/class combinations (Speed and Hardcore) and TBC 1-70 routes are built and checked offline: every route walked by the route audit, the engine test suite and smoke tests passing. Testing in the live game is under way on Classic Era, and players' reports drive the alpha releases: the raid markers and the map and minimap waypoint pins have been confirmed working in game; newer features (automatic training, the nearest-trainer and flight suggestions, the reordered routes) are checked offline only so far. Expect rough edges and please report problems on the [issue tracker](https://github.com/GREYsaurus/Questwarden/issues). Forever support is in progress (docs/FOREVER_PLAN.md). Changes per release: [CHANGELOG.md](CHANGELOG.md); open questions: [docs/DATA_GAPS.md](docs/DATA_GAPS.md).

## Download

- **CurseForge:** https://www.curseforge.com/wow/addons/questwarden (alpha files are listed once CurseForge has approved them)
- **GitHub releases:** https://github.com/GREYsaurus/Questwarden/releases (pre-releases; `Questwarden-<version>.zip` is the add-on, `-source.zip` the full source)

## What it does

**Guides and routes**
- **Level 1-60 guides for every Classic race/class combination** (8 races, 9 classes, Alliance and Horde), covering every racial start and leveling zone; TBC Classic Anniversary gets TBCGuide's 1-70 routes.
- **Two route flavors:** Speed (default), and Hardcore/Survival, which avoids dangerous mobs and risky pulls, adds warnings, and never relies on a soulstone or Reincarnation.
- **Completionist mode** ([docs/COMPLETIONIST.md](docs/COMPLETIONIST.md)): instead of the Speed route, every eligible quest the bundled data knows for your character, lowest level first and zone by zone, coming back to zones as more quests open up, dungeons included.
- **Setup wizard** ([docs/SETUP.md](docs/SETUP.md)): each new character chooses route and mode, a talent plan, dungeons and options in five steps; nothing changes until *Finish Setup*. Run it again any time (`/qw setup`).
- **Dungeon runs** ([docs/DUNGEONS.md](docs/DUNGEONS.md)): pick the dungeons you want routed. When a quest sends you into one, the step says it is time to find a group and the arrow leads to the entrance; it moves on when you enter. Skip a run to keep questing, nothing is marked complete. Die inside and the arrow leads back to the entrance.
- **Objectives before far turn-ins:** steps are ordered so you finish the quests whose objectives are in the same place before travelling back to turn them in (for example, all the Fargodeep Mine quests in Elwynn before returning to Goldshire). Reordering keeps your saved progress.
- **Every step can be completed or skipped by hand**, so you never get stuck. Automatic progression from the quest log, quest-completion flags, level, hearthstone and flight paths.
- **Bundled quest database** derived from QuestieDB, so Questie is not required.

**Navigation**
- **Built-in arrow** with the distance and an estimated time to arrival, plus a **world-map pin** and a **minimap pin**; no other add-on needed.
- **City, building and cave hints:** the arrow points in a straight line, so the guide tells you when to follow the streets of a capital, leave a city or building first, or look for the entrance of a building, cave or mine. Spots where you have stood indoors or outdoors are remembered, so the hints get more precise as you play.

**Targets and raid markers**
- **Target list and targeting macro** for the current step's NPCs, including the mobs that drop its quest items.
- **Automatic raid markers** on the step's mobs, in priority order: your target, then the mob under your mouse, then one in view; the icon moves on when the marked mob dies or leaves your view. Quest givers on accept and turn-in steps, and your trainer on training steps, are marked too (*Mark Friendly Targets*). Optional: let the targeting macro mark instead.

**Class training** ([docs/TRAINER.md](docs/TRAINER.md))
- **Training suggestions:** what your class trainer has for you now (important ranks or all), with prices, from the bundled What's Training? spell lists (no need to install it).
- **Automatic training** (opt-in, per character): at your class trainer, learn the recommended ranks you can afford, one at a time, with one summary line when you close the trainer. Hold Shift to skip.
- **The nearest trainer:** training steps send you to your class trainer nearest to where you stand. With none in your zone, the cheapest flight you know to a zone with one, learned from the flight map (a price you have not seen yet is never guessed).

**Talents and gear**
- **Talent guide and calculator** from client data, with leveling plans per spec, each checked point by point against the talent trees; reminders and talent-window markers never spend points for you.
- **Gear scoring** with researched stat weights and **automatic upgrades** (opt-in; never Bind-on-Equip items), including armor-only upgrades and weapons with more DPS and the same other stats, with a chat line and the level-up sound when something is equipped.

**Everything else:** quest automation that never auto-accepts escort quests and never picks rewards for you, junk selling (off by default), orphaned-quest finder, bag-addon markers, an auction house Upgrades tab, flight/inn/gossip automation, flight timers, a leveling tracker, and a settings window with profiles.

**One download, two games.** The add-on folder has a `Questwarden_Vanilla.toc` for Classic Era and a `Questwarden_TBC.toc` for TBC Classic Anniversary; each client loads its own file, with its own quest data, guides (1-60 on Classic Era, TBCGuide's 1-70 routes on TBC) and talent trees. The TBC data and guides are those of TBCGuide 0.9.5; do not run TBCGuide and Questwarden together: both would act on the same quests and NPCs. If a build still meets the wrong client, it says so at login and loads no guides.

## Install

See [INSTALL.md](INSTALL.md). In short: copy the `Questwarden` folder (the one containing `Questwarden_Vanilla.toc` and `Questwarden_TBC.toc`) into the game's `Interface\AddOns` folder, for example

```
World of Warcraft\_classic_era_\Interface\AddOns\Questwarden\Questwarden_Vanilla.toc
```

## Use

| Command | Action |
|---|---|
| `/qw` (or `/questwarden`) | Show/hide the guide window |
| `/qw setup` | Setup wizard (`/qw setup status`: your current choices) |
| `/qw guide` | Guide browser |
| `/qw completionist` | Completionist progress (`on`, `off`, `replan`) |
| `/qw talents` | Talent guide and calculator |
| `/qw train` | Class training suggestions (`waypoint`: arrow to your trainer, `defer`: hide until your next level) |
| `/qw next` / `/qw prev` / `/qw skip` | Manual step control |
| `/qw options` | Settings window |
| `/qw gear` (or `/qwgear`) | Equipped gear and upgrades |
| `/qw mark` / `/qw markbar` | Mark your target / raid marker bar |
| `/qw debug` / `debug nav` / `debug marks` / `debug errors` | Diagnostics: client and build, waypoint pins, raid markers, captured errors |
| `/qw help` | All commands |

In the guide window, **left-click** a step to mark it done and **right-click** it to skip it.

## Licence

Questwarden is free software under the **GNU General Public License v3.0 only** (`LICENSE`, `COPYING`). The full corresponding source is this repository; each release also ships a `-source.zip`.

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
