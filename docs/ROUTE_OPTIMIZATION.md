# Route optimization

The route audit (`tools/build.ps1 routes`) works for every target. It walks every race/class route and checks for impossible quest order, quest-log overflow at the target's limit (Classic Era 20), pickups never turned in, level gates and travel. Reports: `docs/generated/<Target>/ROUTE_AUDIT.md`.

**Objectives before far turn-ins:** `python tools/research/cluster_objectives.py <Target> [--apply]` finds complete steps of quests already in your log whose objectives are next to the ones you just finished, placed after a turn-in far away, and moves them before that turn-in. Each move is kept only if it shortens the guide's modeled walk; it never moves a step past a hearthstone, flight, boat, dungeon or another-zone step, past another step of the same quest or a step that names its items, or onto a quest too high for the route's level there. After `--apply`, run `guides` and `routes`, then `python tools/research/layout_map.py <Target>` so saved progress follows the new order (Guides/Layouts.lua).

**Coming in Phase 2:** the Classic Era route research and results. The method and TBCGuide's results for TBC Classic are in [tbcguide/ROUTE_OPTIMIZATION.md](tbcguide/ROUTE_OPTIMIZATION.md).
