# Questwarden

**A free leveling guide for WoW Classic Era (1-60) and TBC Classic Anniversary (1-70), in one download.**

> **Alpha.** Questwarden is new and updated often. Its routes and data are built and checked offline. Testing in the live game is under way on Classic Era: the raid markers and the map and minimap waypoint pins are confirmed working, and newer features are checked offline only so far. Please report anything wrong on the issue tracker.

> **A note from the author:** the routes are not perfect, and they are constantly being improved. I made Questwarden for my wife and friends first. Thank you for downloading it and trying it out, though! Please leave comments on this page with any issues you run into or suggestions you have.

## What it does

**Guides and routes**
- **Step-by-step routes for every race and class**, from your starting zone to the level cap, in a planned zone order.
- **Two route types:**
  - **Speed.**
  - **Hardcore:** leaves out risky pulls and warns you before dangerous spots. It turns on by itself on Hardcore realms.
- **Tuned for leveling speed:** quests and quest chains are added where the route would leave you short of the next zone's level.
- **Grind steps only where needed:** where questing still falls short, a grind step sends you to the densest group of mobs near your level, close to where you already are. It stops at the level you need, or part of one when the quests you have left will cover the rest.
- **Class quests** that teach spells, such as Defensive Stance, the warlock pets, the druid's Aquatic Form and the shaman totems, at the level they open. Each shows only for the classes and races that can take it.
- **Easier quests first:** quests whose targets are well above your level come after easier ones.
- **Quests from objects:** when a quest starts or ends at a wanted poster, a notice board or a grave, the step says so and what to click.
- **Quests started by dropped items:** the guide knows which mobs drop the item. It lets you kill them on the way, and tells you to right-click the item once you have it. Rare drops like the OOX distress beacons show up only if you find one.
- **Completionist mode:** every quest the bundled data knows for your character, zone by zone, dungeons included.
- **Setup wizard:** it first asks whether you are new to World of Warcraft. New players get a short, plain-words setup: where to start, whether you want to tank, heal or deal damage (with a suggested talent plan), and the recommended dungeons. Experienced players get every option. Run it again any time with `/qw setup`.
- **Dungeon runs:** when a quest sends you into a dungeon, the step tells you to find a group and the arrow leads to the entrance. If you die inside, it leads you back.
- **Quests in one place are done together:** you finish them before travelling back to turn them in.
- **Hearthstone suggestions:** the guides tell you where to set your hearthstone, and the step tells you when hearthing to your turn-ins beats walking.
- **Death skip suggestions:** when the graveyard is much nearer your next step in town, the step suggests a quicker way back. Never on Hardcore characters.
- **Built-in quest database** (from QuestieDB), so you don't need Questie.
- **Every step can be completed or skipped by hand**, so you never get stuck.

**New to WoW? Built for you** (all optional, off until you turn them on)
- **Explanations** of each kind of step, the useful keys, full bags and your first death, once each, in a small window you close with OK.
- **New spells explained**, with a nudge to put them on your action bars, and class tips as you level.
- **Play together:** see where your friends are in the guide, get a "wait for" hint, or follow the party leader's step.
- **Mount savings goal**, a **session recap** at login and **profession starter tips**.
- **Simple settings view** that hides the rarely needed options.

**Navigation**
- **Built-in arrow** with distance and time to arrival, a world-map pin and a minimap pin. No other add-on needed.
- **Patrolling NPCs:** the arrow follows quest NPCs and named mobs that walk a path.
- **Capital city hints** where a straight-line arrow would get you lost.

**Targets and raid markers**
- **Automatic raid markers** on the mobs your step needs: your target first, then the mob under your mouse, then one in view. Quest givers and your trainer are marked too.
- **Target list and targeting macro** for the current step.

**Class training**
- **Training suggestions** with prices. The spell lists come from What's Training?, bundled, so you don't need to install it.
- **Automatic training** (opt-in): learns the recommended spells you can afford when you visit your trainer.
- **The nearest trainer**, or, with none in your zone, the cheapest flight you know to one.

**Talents and gear**
- **Talent calculator and leveling builds** for each class. The next talent to take is highlighted in the talent window.
- **Automatic gear upgrades** (opt-in, never Bind-on-Equip items). This includes armor-only upgrades and weapons with more DPS. Each upgrade gets a chat line and the level-up sound. Bigger bags are equipped too.

**Quality of life**
- Quest automation that never auto-accepts escorts or picks rewards for you.
- Junk selling and auto repair, both off by default.
- A low durability warning when your gear drops below 30%.
- Flight and inn automation, and flight timers.
- Optional map pins for rares, elites and spirit healers.
- A clean, modern look: the current step as a card with an objective progress bar, settings with a sidebar, search and switches, and a choice of accent colour.

## Which game?

Install the same folder for either game:
- Classic Era loads `Questwarden_Vanilla.toc` with Classic data.
- TBC Classic Anniversary loads `Questwarden_TBC.toc` with TBC data.

Don't run it together with TBCGuide.

Type `/qw help` in game for the commands.

## Licence and sources

GPL-3.0. Data sources:
- **Quest data:** QuestieDB (GPL-3.0).
- **Class-trainer spell lists:** What's Training? (MIT).
- **Spell, talent and map data:** the game client's own tables.

Source code: https://github.com/GREYsaurus/Questwarden
