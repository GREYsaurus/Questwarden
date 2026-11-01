# Route optimization

The route audit (`tools/build.ps1 routes`) works for every target. It walks every race/class route and checks for impossible quest order, quest-log overflow at the target's limit (Classic Era 20), pickups never turned in, level gates and travel. Reports: `docs/generated/<Target>/ROUTE_AUDIT.md`.

**Objectives before far turn-ins:** `python tools/research/cluster_objectives.py <Target> [--apply]` finds complete steps of quests already in your log whose objectives are next to the ones you just finished, placed after a turn-in far away, and moves them before that turn-in. Each move is kept only if it shortens the guide's modeled walk; it never moves a step past a hearthstone, flight, boat, dungeon or another-zone step, past another step of the same quest or a step that names its items, or onto a quest too high for the route's level there. After `--apply`, run `guides` and `routes`, then `python tools/research/layout_map.py <Target>` so saved progress follows the new order (Guides/Layouts.lua).

**Nearest NPC first:** `python tools/research/npc_order.py <Target> [--apply]` reorders stretches of back-to-back pickups and turn-ins in the guide's zone (note lines move with their step) to the shortest walk. The walk starts where you are before the stretch: the previous step's NPC, or the nearest spawn of the previous kill step's objectives. At the start of a starting guide, it starts at the NPC who stands where the race appears (SPAWN in the tool). The walk ends where you go next: the next step's NPC, or the nearest objective spawn of the next kill step.

Steps at the same NPC stay together, in their order. The tool never puts:
- a pickup before the turn-in of one of its prerequisites;
- a turn-in before its pickup;
- a pickup whose required level is above the route model's level there ahead of the turn-ins before it.

A new order is kept only when it saves at least 2 map percent. Run it again after `guides` and `routes` until it finds nothing: NPCs with several spawns can be placed differently after a reorder. Then run `layout_map.py`, which ignores the fields the compiler derives from order (coordinates, chosen NPC, packs).

The route audit's Distance column counts NPC steps only, not the walk to kill objectives in between. A reorder can raise that number and still shorten the real walk: for example, turning in the far-west quest first when the next objectives are in the east. The first run (2026-11-01) reordered 88 stretches in Classic Era and 103 in TBC.

**Kill packs:** `python tools/research/kill_packs.py <Target> [--apply]` moves complete steps of quests already in your log up next to a complete step whose mobs spawn in the same area: within 8 map percent, or the same mobs, kill targets or item droppers. The compiler then links them into a kill pack that the add-on shows as one ([GUIDE_FORMAT.md](GUIDE_FORMAT.md#kill-packs)). Any number of steps can join.

A step doesn't move:
- past another step of its quest, a step that names its items, an item-started pickup, or a step that takes you elsewhere or into another zone;
- when its quest has more than one complete step or only elite targets;
- when its quest is more than 2 levels above the route's level there;
- when the modeled walk gets more than 1 map percent longer. In this model, a complete step costs no walk when its mobs are within 8 map percent of where you are.

After `--apply`, run `guides` and `routes`, then `layout_map.py`. The first run (2026-11-01) moved 39 Classic Era and 94 TBC steps. That gave 100 and 184 packs, with up to 7 and 8 quests in one pack.

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
