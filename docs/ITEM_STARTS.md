# Quests started by a dropped item

Some quests have no quest giver: a mob drops an item, and using the item starts the quest (for example *The Collector*, from the Gold Pickup Schedule that Defias drop in Elwynn Forest). Code: `Core/ItemStarts.lua`, the compiler in `tools/src/GuideCompiler.cs`, the engine in `Core/Engine.lua`. Tests: `tests/test_item_starts.lua`.

## What the guide knows

For a pickup step whose quest starts from an item, the guide compiler adds, from the bundled QuestieDB data only:
- `starter`: the item.
- `drops`: the NPCs that drop it, preferring those that spawn in the guide's zone (at most 8). Left out when no NPC drops it in the data (an object, a vendor, or nothing known); the step then only names the item.
- `via`: the later steps of the same guide whose objectives (kill targets, kill credit, quest-item droppers) or grind mobs include one of those NPCs.

The step has no fixed waypoint; the arrow goes to the nearest dropper while you still need the item. Drop rates are not in the data, and no step claims one.

## States

Each such step is in one state, read from your quest log and your bags only:

| State | When | The step shows |
|---|---|---|
| Done | the quest is turned in | done |
| Accepted | the quest is in your log | done |
| Have | the item is in your bags, the quest is not taken | "Use [item] to accept ...": click it in the active item window (it gets the first button there) or right-click it in your bags, then click Accept. No arrow. |
| Waiting | no item, and a `via` step is still ahead | not current: the kill steps go first, and they say their mobs can drop the item |
| Farm | no item, no kill step left | "Get [item] from ... to accept ...", the droppers, the arrow on the nearest one, and that you can skip |
| Not available | race, class, level, another branch | auto-skipped with the reason, like any pickup |
| Not found yet (`[iffound]`) | no item, quest not taken | hidden: not shown, not counted, never waited for or farmed |

Having the item, or opening its quest window, isn't acceptance: the step is done only when the quest is in your log.

While a pickup is waiting, its quest's objective and turn-in steps wait with it, so the guide never shows "Turn in ..." for a quest you don't have. When the item arrives, the guide goes back to the pickup. When the kill steps are done and there's still no item, the pickup comes back as a farm step.

The current step also mentions a starter item in your bags that a later pickup of the guide uses.

## Steps that appear only if you find the item

Some start items are dropped by dozens of kinds of mob, or by mobs the guide never fights. Examples:
- the OOX distress beacons;
- the Pendant of Myzrael;
- Brann Bronzebeard's Lost Letter.

A guide can't send you to farm these, so their quests are written with `[iffound]` on the pickup, objective and turn-in. The steps stay hidden until the item is in your bags or the quest is in your log:
- **Item in your bags:** the pickup appears ("Use [item] to accept ...") and notes it showed up because you found the item.
- **Quest taken:** its objective and turn-in join the route.
- **Abandoned without the item:** the steps hide again.

They are never counted in the guide's progress or in the route audit's level model.

They're placed in the guide for the zone where the quest's objectives are, or the finisher's zone when it has none, for each faction. You may find the item anywhere; the steps show once the route reaches that zone.

## Skipping

Skip is never completion. A skipped pickup skips its quest's objective and turn-in steps. If you take the quest later anyway (the item dropped after all), the pickup counts as done and those steps come back.

## Completionist

- A quest with no giver that starts from an item is placed at the nearest NPC that drops the item, outside instances.
- Its pickup comes after the zone's other objectives, so the item may drop on the way. Its own objectives and turn-in follow.
- If you skip such a pickup, it's remembered for the character (category *Item pickup skipped*). It isn't planned again until the item is in your bags.
- Items no NPC drops in the data stay *missing location data*.

## Events

- Bags are read on `BAG_UPDATE_DELAYED`.
- The guide refreshes only when a starter item of the active guide comes or goes.
- Quest log changes refresh it as before.
- Nothing is checked per frame.

## Audit

`python tools/research/item_starters.py <Target>` writes `docs/generated/<Target>/item-starters.csv`. It lists every item-started quest in the data with:
- how its item is obtained (mob, object, or none in the data);
- the droppers;
- whether a guide picks the quest up;
- which steps of that guide kill a dropper.

## Added to the speed guides

`python tools/research/item_starter_gaps.py <Target>` lists, for every guide whose route model still needs grinding (`guide-xp.csv`), the item-started quests no guide uses yet. A candidate must:
- be open to the guide's faction and every class;
- have no prerequisite;
- fit the guide's level band;
- be dropped by mobs in the guide's zone.

`python tools/research/item_starter_insert.py <Target>` adds the conservative ones to the guide sources, with the same placement rules as `quest_insert.py`. A quest is added only when:
- its item is dropped by one kind of NPC (a named mob), or the guide already has an objective step that kills a dropper;
- no dropper is a hostile elite, rare elite or boss;
- it isn't an escort, an event, repeatable or reputation-gated;
- its finisher and objectives are in the zone;
- the route model reaches its required level where the pickup goes.

The pickup goes right before the guide's first step that kills a dropper, else after the step nearest the droppers. Being dropped by one named mob doesn't mean the drop is certain; drop rates aren't in the data.

First batch (2026-11-01):
- **Classic Era (7 quests):**
  - Horde: A Letter Undelivered (Tirisfal); The Runed Scroll and The Harvester (Barrens); The Corrupter (Desolace).
  - Alliance: Noboru the Cudgel (Swamp of Sorrows); Deadwood Ritual Totem and Flute of Xavaric (Felwood).
  - Grinding in the route model: 50.94 → 50.42 levels.
- **TBC (24 quests):** the same kinds in Tirisfal, the Barrens, Ashenvale, Swamp of Sorrows, Felwood and Winterspring, plus 15 in Outland (Hellfire, Zangarmarsh, Nagrand, Blade's Edge, Netherstorm, Shadowmoon). Grinding: 54.81 → 53.80 levels.

Second batch (`--relaxed`):
- The objectives and turn-in may be in another zone. They go into the first later guide of that zone, by level, for the same faction, and the pickup says where it's turned in.
- The pickup no longer waits for the required level. Below it, the add-on skips it with "needs level N" and picks it up if you reach the level before moving on.
- Every guide whose zone has the droppers is considered, not only those that still need grinding.
- Prerequisites are allowed when the route turns them in first.
- Elite droppers no longer rule a quest out when non-elite mobs drop the item too. The step then points only at the non-elite ones; the compiler does the same for every item pickup.
- Items more than 12 kinds of mob drop are left out: a broad world drop, likely rare, and more droppers than the bundled data keeps.
- Classic Era got The Key to Freedom (Searing Gorge) and Winterfall Ritual Totem (Winterspring, turned in in Felwood).
- TBC got 6 quests: Rune Covered Tablet, Captain Sander's Hidden Treasure, Resting in Pieces, The Key to Freedom, Drain Schematics and Did You Get The Note?.
- Grinding in the route model, after both batches: Classic Era 50.94 → 50.31 levels; TBC 54.81 → 53.47.

Third batch (`--iffound`):
- Classic Era: 5 quests in each faction's guides. These are the three OOX beacons, Crystal in the Mountains (Pendant of Myzrael) and Brann Bronzebeard's Lost Letter.
- TBC: 19 placements of 12 quests. They also cover the Runed Scroll, Williden's Journal, Guarding Secrets, A Strange Red Key, Winterfall Ritual Totem, Missing Missive, Diabolical Plans and The Truth Unorbed.
- They don't change the route model's numbers: they're bonuses when the item drops.

Still left out:
- escorts and events (the OOX escorts that follow the beacon quests among them);
- items only elites or instance mobs drop;
- quests with no guide in the zone of their objectives or finisher.

## Not checked in the game

Everything above is checked offline with the test suite, not in the live client.
