# Completionist mode

Completionist is a per-character leveling **mode** next to the default **Speed** mode. Speed follows the leveling guides (`Guides/Compiled`), unchanged. Completionist routes the character through every eligible quest in the bundled quest database, lowest level first and zone by zone, and brings the character back to zones as more of their quests open up. Code: `addon/Core/Completionist.lua`.

## Choosing the mode

- **The setup wizard** (docs/SETUP.md) starts with the leveling mode: *Speed (the leveling guides)* or *Completionist (every eligible quest)*, each explained. Speed is preselected. Nothing is applied before **Finish Setup**; *Set Up Later* keeps the draft. Completionist is greyed out with the reason where it cannot run (unverified game version, no completion flags, no zone geography).
- **Settings → Guide Routing → Leveling mode** switches at any time. `/qw completionist on|off` does the same; `/qw completionist` prints the status, `/qw completionist replan` plans the next segment now.
- Saved per character (`ns.char.mode`); characters that never chose stay on Speed. Existing characters keep their setup and mode after an update.

## Switching keeps progress

- Quest completion is the game's (its completion flag); switching never marks or unmarks a quest.
- Turning Completionist on remembers the Speed guide in use (`ns.char.speedGuide`); turning it off loads that guide again with its own saved step progress.
- The Completionist route is planned from the character's current level, quest log, completion and position, so turning it on mid-level gives a catch-up route without replaying anything already done.

## How the route is planned

The planner works one **segment** (one visit to one zone) at a time and runs it through the normal engine as a generated guide, so step text, the arrow and automatic step completion (accept, objectives, turn-in) work as in the leveling guides. When a segment is finished, the next one is planned.

Fixed priorities, no weighted score:

1. **Eligibility and prerequisites.** Only quests this race and class can take, not completed, not the other branch of a choice, with every prerequisite done.
2. **Level.** Quests sit in level bands of 5 (`BAND`). A quest is actionable when its required level is reached and its quest level is at most 2 above the character (`AHEAD`). The lowest band with actionable work leads, so missed lower-level quests come back into the route.
3. **Geography.** The character stays in the current zone while that zone's lowest band is at most one band above the lowest band anywhere, so a level or two never causes a zone hop. Otherwise the route goes to a zone with work in the lowest band: the most work (zones with at least 2 items, `MIN_CLUSTER`, preferred), then the nearest by world distance (`Database/ZoneGeo.lua`, from the client's map table), then the lowest zone id.
4. **Inside the zone.** Every actionable quest up to one band above the lowest is picked up (finish local work before leaving), up to 10 pickups and leaving 3 free quest-log slots. Then come the objectives of quests in the log located in this zone, then the turn-ins, each in nearest-neighbour order. A travel step comes first when the zone changes.

A quest chain continues across segments: the next quest is actionable once the previous one is turned in, and multi-zone chains are planned where each part's giver, objectives and finisher are. Mutually exclusive quests are never both picked up; with neither chosen the route takes the lower quest id, and a branch the player already took decides.

**Return visits.** Every planned zone visit is logged (`ns.char.completionist.visits`: zone, band, level, quests, deferred count). A zone comes back whenever new quests there become actionable by level or prerequisite. If nothing is actionable, the route says so and adds a *reach level N* step for the next level that opens deferred quests; it never invents filler quests.

**Class training.** A segment in a zone with your class trainer gets one optional train step after its pickups when there is something to train (docs/TRAINER.md, "In the guides"). The route never travels just to train, and training is not counted as a quest.

## Categories

Each quest is classified for the character: *ready now*, *in your quest log*, *completed*, *later (level)*, *waiting on a prerequisite*, *other branch chosen*, *not for this character*, *missing location data*, *completion unknown*, and the special kinds below.

**Dungeon quests are always routed:** Completionist goes through every dungeon; the dungeon selection in setup applies to Speed only.
- A dungeon quest is picked up only from the dungeon's usual level (`Database/Dungeons.lua`), so it does not sit in the quest log for many levels.
- Open dungeon quests in the log become one **run step** per dungeon: time to find a group, with the arrow on the entrance. It ends when you enter the dungeon; inside, a dungeon segment lists the quests' objectives, and leaving plans the route again (docs/DUNGEONS.md, "Dungeon runs"). A run step never marks a quest complete: skip it to keep questing; it comes back in later segments.
- Their turn-ins are planned once the quest log says complete.

Counted but **not routed by default** (setup's Options step or Settings → Guide Routing turns each on): raid, group/elite (an elite objective target), profession, reputation, event/seasonal (QuestieDB's special categories) and repeatable quests. For characters that finished setup, group/elite follows the setup's group-quest choice. Turning a kind on puts its quests through the normal level and prerequisite rules. Excluding a kind never counts it as done.

`/qw completionist` reports progress against one denominator: eligible quests with routable data (completed + ready + in log + later + waiting), separately from excluded kinds, other branches, missing data and unknown completion. It never reports "all quests".

## Coverage

The route covers every quest in the bundled QuestieDB data for the game whose giver and finisher have positions. `tools/build.ps1 completionist-coverage -Target <Target>` writes the per-race/class matrix (`docs/generated/<Target>/completionist-coverage.md`) with the planner itself. Classic Era: 4,257 quests in the data, about 1,190-1,410 routable per character. TBC Classic Anniversary: 6,648 quests, about 1,890-2,150 routable per character (dungeon quests included).

Not covered: quests the database lacks; quests whose giver or finisher has no position (*missing data*, about 140 per Classic character); quests started by an item with no giver; content added after the pinned QuestieDB data.

## Limits and assumptions (not checked in game)

- Completion comes from `C_QuestLog.IsQuestFlaggedCompleted` (or `IsQuestFlaggedCompleted` / `GetQuestsCompleted`). Without any of them every quest is *completion unknown* and nothing is routed.
- Positions come from QuestieDB's spawn data, trimmed to a few points per zone; objectives far from those points are not found.
- Travel between zones is a straight world-distance estimate, not a path: no flight paths, boats or walls are considered.
- The plan is recalculated when a segment ends, at login and on request, not on every event; a level-up does not interrupt the current segment.
- Forever is not supported yet (unverified target).
