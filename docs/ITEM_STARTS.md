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
| Have | the item is in your bags, the quest is not taken | "Use [item] to accept ...": right-click it, then click Accept. No arrow. |
| Waiting | no item, and a `via` step is still ahead | not current: the kill steps go first, and they say their mobs can drop the item |
| Farm | no item, no kill step left | "Get [item] from ... to accept ...", the droppers, the arrow on the nearest one, and that you can skip |
| Not available | race, class, level, another branch | auto-skipped with the reason, like any pickup |

Having the item, or opening its quest window, isn't acceptance: the step is done only when the quest is in your log.

While a pickup is waiting, its quest's objective and turn-in steps wait with it, so the guide never shows "Turn in ..." for a quest you don't have. When the item arrives, the guide goes back to the pickup. When the kill steps are done and there's still no item, the pickup comes back as a farm step.

The current step also mentions a starter item in your bags that a later pickup of the guide uses.

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

## Not checked in the game

Everything above is checked offline with the test suite, not in the live client.
