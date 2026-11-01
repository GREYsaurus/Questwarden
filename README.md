# Questwarden

Questwarden is a **free** leveling guide and talent add-on, in one download, for two games:
- **WoW Classic Era** (client 1.15.9, interface `11509`), levels 1-60;
- **TBC Classic Anniversary** (client 2.5.6, interface `20506`), levels 1-70.

It's built to also target **World of Warcraft: Forever** once that game is live and its data has been checked.

Questwarden grew out of [TBCGuide](https://github.com/GREYsaurus/TBCGuide). It forks TBCGuide's engine, interface, compatibility layer, tests and build tools, and ships TBCGuide's TBC data and 1-70 routes. The Classic Era data and routes are its own.

> **Status: alpha (0.1.0-alpha.26).** Routes and data are built and checked offline:
> - Classic Era 1-60 routes for all 40 race/class combinations (Speed and Hardcore), and TBC 1-70 routes;
> - the route audit walks every route, and the engine tests and smoke tests pass.
>
> Testing in the live game is under way on Classic Era, and players' reports drive the alpha releases:
> - **Confirmed in game:** the raid markers, and the map and minimap waypoint pins.
> - **Checked offline only so far:** newer features, such as item-started quests, grind steps, hearthstone suggestions and patrolling NPCs.
>
> Expect rough edges, and please report problems on the [issue tracker](https://github.com/GREYsaurus/Questwarden/issues). Forever support is in progress ([docs/FOREVER_PLAN.md](docs/FOREVER_PLAN.md)). Changes per release are in [CHANGELOG.md](CHANGELOG.md), and open questions in [docs/DATA_GAPS.md](docs/DATA_GAPS.md).

## Download

- **CurseForge:** https://www.curseforge.com/wow/addons/questwarden. Alpha files appear once CurseForge has approved them.
- **GitHub releases:** https://github.com/GREYsaurus/Questwarden/releases. These are pre-releases: `Questwarden-<version>.zip` is the add-on.

## What it does

### Guides and routes

- **A 1-60 route for every Classic race and class** (8 races, 9 classes, Alliance and Horde), from every starting zone. TBC Classic Anniversary gets TBCGuide's 1-70 routes.
- **Two route types:**
  - **Speed** (the default).
  - **Hardcore/Survival:** avoids dangerous mobs and risky pulls, adds warnings, and never relies on a soulstone or Reincarnation.
- **Speed routes tuned against an XP model** ([docs/ROUTE_OPTIMIZATION.md](docs/ROUTE_OPTIMIZATION.md)). Quests and quest chains are added where the model is short of the next zone's level. Where questing still falls short, a **grind step** sends you to the densest group of non-elite mobs near your level, near where you already are. The step stops at the level you need, or part of one ("until level 16 (20% through)") when the quests left in the zone will cover the rest.
- **Quests started by dropped items** ([docs/ITEM_STARTS.md](docs/ITEM_STARTS.md)):
  - The step knows which item starts the quest and which mobs drop it.
  - It lets the guide's kill steps for those mobs go first, since the item may drop there.
  - It tells you to right-click the item once it's in your bags.
  - Items that dozens of kinds of mob drop, such as the OOX distress beacons, get steps that appear only if you find the item.
- **Completionist mode** ([docs/COMPLETIONIST.md](docs/COMPLETIONIST.md)): in place of the Speed route, every quest the bundled data knows for your character. It goes lowest level first, zone by zone, comes back to zones as more quests open up, and includes dungeons.
- **Setup wizard** ([docs/SETUP.md](docs/SETUP.md)): it first asks whether you are new to World of Warcraft.
  - **New players** get six pages in plain words: where to start, whether they want to tank, heal or deal damage (with a suggested talent plan for it), the recommended dungeons (picked, so they learn to run them), and the helpers below.
  - **Experienced players** choose route and mode, talent plan and gear profile, dungeons, training and upgrades, and helpers.
  - Nothing changes until *Finish Setup*, and you can run it again any time with `/qw setup`.
- **Dungeon runs** ([docs/DUNGEONS.md](docs/DUNGEONS.md)): pick the dungeons you want in your route.
  - When a quest sends you into one, the step tells you to find a group and the arrow leads to the entrance. The step moves on when you enter.
  - Skip a run to keep questing; nothing is marked complete.
  - If you die inside, the arrow leads back to the entrance.
- **Objectives before far turn-ins:** you finish the quests in one place before travelling back to turn them in. Reordered steps keep your saved progress.
- **Hearthstone suggestions** ([docs/HEARTHSTONE.md](docs/HEARTHSTONE.md)): when hearthing to turn-ins in town beats walking, the step says so and how much time it saves. It never uses the hearthstone for you.
- **Every step can be completed or skipped by hand**, so you never get stuck. Steps also complete on their own from the quest log, quest flags, your level, the hearthstone and flight paths.
- **Bundled quest database** taken from QuestieDB, so you don't need Questie.

### Help for new players

See [docs/NEW_PLAYERS.md](docs/NEW_PLAYERS.md). All off by default; the setup wizard offers them.

- **Explanations:** the first time each kind of step comes up (pick up, kill, turn in, fly, train...), one chat line says what to do and which key opens what. Also full bags, your first death and talent points.
- **New spells:** what a spell you just learned does, and how to put it on your action bars; every few levels, a leveling tip for your class.
- **Play together:** party members running Questwarden see where each other are in the guide, with "Wait for <name>" when someone still has to pick up or turn in. Optionally, everyone follows the party leader's step (`/qw follow`).
- **Mount savings goal**, **session recap** at login, and **profession starter tips** with the nearest trainers.
- **Simple settings view:** hides the rarely needed options.

### Navigation

- **Built-in arrow** with the distance and time to arrival, plus a **world-map pin** and a **minimap pin**. No other add-on needed.
- **Patrolling NPCs** ([docs/PATROLS.md](docs/PATROLS.md)): for a quest NPC or named mob that walks a path, the arrow follows the path and the path is dotted on the maps.
- **City, building and cave hints:** the arrow points in a straight line, so the guide tells you when to follow a capital's streets, leave a building first, or look for the entrance of a cave or mine. It remembers where you've stood indoors and outdoors, so the hints get more precise as you play.

### Targets and raid markers

- **Target list and targeting macro** for the current step's NPCs, including the mobs that drop its quest items.
- **Automatic raid markers** on the step's mobs ([docs/RAID_MARKERS.md](docs/RAID_MARKERS.md)):
  - in priority order: your target, then the mob under your mouse, then one in view;
  - the icon moves on when the marked mob dies or leaves your view;
  - quest givers and your trainer are marked too.

### Class training

See [docs/TRAINER.md](docs/TRAINER.md).

- **Training suggestions:** what your class trainer has for you now, with prices. The spell lists come from What's Training?, bundled, so you don't need to install it.
- **Automatic training** (opt-in, per character): at your class trainer, learns the recommended ranks you can afford. Hold Shift to skip.
- **The nearest trainer:** training steps send you to your nearest class trainer. With none in your zone, they suggest the cheapest flight you know to one.

### Talents and gear

- **Talent guide and calculator** from client data, with leveling plans per spec. It reminds you and marks the talent window, but never spends points for you.
- **Gear scoring** with researched stat weights.
- **Automatic upgrades** (opt-in, never Bind-on-Equip items):
  - includes armor-only upgrades, and weapons with more DPS and the same other stats;
  - a chat line and the level-up sound when something is equipped.

### Everything else

- Quest automation that never auto-accepts escort quests or picks rewards for you.
- Junk selling and auto repair, both off by default.
- An orphaned-quest finder.
- Bag-addon markers and an auction house Upgrades tab.
- Flight, inn and gossip automation, and flight timers.
- A leveling tracker.
- A settings window with a sidebar, search, switches and profiles, and a choice of accent colour.

### One download, two games

The add-on folder has a `Questwarden_Vanilla.toc` for Classic Era and a `Questwarden_TBC.toc` for TBC Classic Anniversary. Each client loads its own file, with its own quest data, guides and talent trees. If a build meets the wrong client, it says so at login and loads no guides.

The TBC data and guides are those of TBCGuide 0.9.5. Don't run TBCGuide and Questwarden together: both would act on the same quests and NPCs.

## Install

See [INSTALL.md](INSTALL.md). In short: copy the `Questwarden` folder (the one that holds `Questwarden_Vanilla.toc` and `Questwarden_TBC.toc`) into the game's `Interface\AddOns` folder. For example:

```
World of Warcraft\_classic_era_\Interface\AddOns\Questwarden\Questwarden_Vanilla.toc
```

## Use

| Command | Action |
|---|---|
| `/qw` (or `/questwarden`) | Show or hide the guide window |
| `/qw setup` | Setup wizard (`/qw setup status`: your current choices) |
| `/qw guide` | Guide browser |
| `/qw completionist` | Completionist progress (`on`, `off`, `replan`) |
| `/qw talents` | Talent guide and calculator |
| `/qw train` | Class training suggestions (`waypoint`: arrow to your trainer; `defer`: hide until your next level) |
| `/qw next` / `/qw prev` / `/qw skip` | Move between steps by hand |
| `/qw options` | Settings window |
| `/qw follow` | Play together: go to the party leader's guide and step |
| `/qw mount` / `/qw recap` / `/qw professions [name]` | Mount savings goal / this session's recap / profession trainers |
| `/qw gear` (or `/qwgear`) | Equipped gear and upgrades |
| `/qw mark` / `/qw markbar` | Mark your target / show the raid marker bar |
| `/qw debug` / `debug nav` / `debug marks` / `debug errors` | Diagnostics: client and build, waypoint pins, raid markers, captured errors |
| `/qw help` | All commands |

In the guide window, **left-click** a step to mark it done and **right-click** it to skip it.

## Licence

Questwarden is free software under the **GNU General Public License v3.0 only** (`LICENSE`, `COPYING`). The full corresponding source is this repository, and each release also ships a `-source.zip`.

The bundled third-party data and its licensing are described in [NOTICE.md](NOTICE.md) and [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md). Where the data comes from, and what is never copied, is in [docs/DATA_POLICY.md](docs/DATA_POLICY.md).

## For developers

- [docs/DEVELOPER.md](docs/DEVELOPER.md): layout, targets, build and test commands.
- [docs/DATA_POLICY.md](docs/DATA_POLICY.md): allowed data sources and the cross-check process. Read this before adding data.
- [docs/DATA_GAPS.md](docs/DATA_GAPS.md): what isn't known or verified yet.
- [docs/GUIDE_FORMAT.md](docs/GUIDE_FORMAT.md): how to write guides.
- [docs/ROUTE_OPTIMIZATION.md](docs/ROUTE_OPTIMIZATION.md): the route audit, XP model and optimization tools.
- [docs/DATA_PIPELINE.md](docs/DATA_PIPELINE.md): refreshing the bundled data.
- [docs/COMPATIBILITY.md](docs/COMPATIBILITY.md): target clients, wrong-client detection, API audit and in-game checklist.
- [docs/KNOWN_LIMITATIONS.md](docs/KNOWN_LIMITATIONS.md).
- [docs/tbcguide/](docs/tbcguide/): TBCGuide's TBC-specific research and reports, kept for reference.
- [CHANGELOG.md](CHANGELOG.md).
