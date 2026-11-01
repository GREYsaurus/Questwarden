# Route optimization

The route audit (`tools/build.ps1 routes`) works for every target. It walks every race/class route and checks for impossible quest order, quest-log overflow at the target's limit (Classic Era 20), pickups never turned in, level gates and travel. Reports: `docs/generated/<Target>/ROUTE_AUDIT.md`.

**Objectives before far turn-ins:** `python tools/research/cluster_objectives.py <Target> [--apply]` finds complete steps of quests already in your log whose objectives are next to the ones you just finished, placed after a turn-in far away, and moves them before that turn-in. Each move is kept only if it shortens the guide's modeled walk; it never moves a step past a hearthstone, flight, boat, dungeon or another-zone step, past another step of the same quest or a step that names its items, or onto a quest too high for the route's level there. After `--apply`, run `guides` and `routes`, then `python tools/research/layout_map.py <Target>` so saved progress follows the new order (Guides/Layouts.lua).

**Grind steps at dense spawns:** `python tools/research/grind_spots.py <Target> [--min-short 0.75] [--dry-run]` looks at every `level N` check in the guide sources. It acts only where the model character arrives at least 0.75 levels short (the lowest over all routes, from step-levels.csv), and adds one grind step for it:
- **Mobs:** non-elite, non-friendly NPCs of the bundled data whose level range touches N-2..N, with at least 5 spawn points in the zone. No rares.
- **Spot:** the densest cluster of their spawns (most points within 6 map percent) near one of the guide's last 25 quest steps in the zone. A later step wins unless an earlier spot is much denser. Steps before a hearthstone, flight, travel, level or grind step don't count.
- **Target:** at the check itself, the grind step replaces it and asks for N. Placed earlier, it asks only for the XP the remaining quests don't give, as a level and tenth (`grind 22.4`).

Smaller shortfalls keep the plain level check, because the model counts no rested, discovery or group XP. Grinding earlier makes the remaining quests worth less in the model's reduced-XP rule, so these steps add a little to the modelled total (Classic Era +0.3, TBC +0.4 levels).

**Optimization run (2026-11-01):** all figures below are levels of grinding in the route model.

| Step | Classic Era | TBC |
|---|---|---|
| Start | 50.31 | 53.47 |
| `quest_insert.py --min-grind 0.25` (only guides that still need at least 0.25 levels of grinding) | 1 quest | 93 quests |
| `chain_insert.py` | 14 quests | 105 quests |
| `zone_guide.py --fill` (Silverpine, Westfall, Loch Modan, Ashenvale, Hillsbrad) | none left | 22 quests |
| Quests added, before grind steps | 49.71 | 39.72 |
| `grind_spots.py` | 22 grind steps | 23 grind steps |
| End | 49.98 | 40.10 |

Removed by hand after the audit:
- **Not worth a step:** a 0-XP breadcrumb (Report to General Kirika).
- **Wrong race:** two race-locked quests, Replenishing the Healing Crystals and The Forsaken (the Draenei and Blood Elf starting areas use other versions).
- **Quest log too full:** three TBC Barrens quests (Deviate Hides, Smart Drinks, Trouble at the Docks). Without them the Barrens log peak stays at 23/25.
- **Wrong order:** Felnok Steelspring and Chillwind Horns. Their pickup was placed in Burning Steppes, after the Winterspring turn-in. `chain_insert.py` orders guides by level, not by `@next`.

Classic Era's zones on the route have no usable quests left (`zone_guide.py --fill` finds none). The zone order follows the user's chart, so no zones were added.

**Coming in Phase 2:** the Classic Era route research and results. The method and TBCGuide's results for TBC Classic are in [tbcguide/ROUTE_OPTIMIZATION.md](tbcguide/ROUTE_OPTIMIZATION.md).
