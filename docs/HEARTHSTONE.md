# Hearthstone suggestions

When hearthing back to town would save time over walking, the current step says so, for example: "Hearthstone ready: hearth to Goldshire for 3 turn-ins there; saves about 4 min over walking." It's only a suggestion: Questwarden never uses the hearthstone.

Setting: **Hearthstone Suggestions** (Settings → General → Automation, on by default). Code: `Core/Hearth.lua`.

## When it shows

All of these must hold:
- Your hearthstone is in your bags and **off cooldown**. You're not on a flight or inside an instance.
- The current step, and the steps right after it, are in the town your hearthstone is set to (within 250 yards of the inn). At least one of them turns in a quest that's in your log.
- Hearthing saves enough time for those turn-ins. The hearthstone has a long cooldown, so the fewer the turn-ins, the more it has to save:

  | Turn-ins in town | Time hearthing must save |
  |---|---|
  | 1 | 5 minutes |
  | 2 | 2.5 minutes |
  | 3 | 100 seconds |
  | 4 | 75 seconds |
  | 5 or more | 1 minute |

- The current step isn't itself a guide step to hearth or to set the hearthstone.

It's checked every 5 seconds and when the step or your quests change, so it comes and goes as you move.

## How the time is worked out

- **Walking:** the straight line to the first step in town, times 1.25 for roads and hills, at your run speed. If you're mounted or in a travel form, that faster speed is used.
- **Hearthing:** 10 seconds to cast, 5 for a loading screen, then the walk from the inn to that step.
- **Another continent:** walking isn't compared; the hearthstone is always the shorter trip. The step says "instead of the long trip".

Flight paths aren't compared. A flight may still be quicker than walking; the suggestion compares hearthing with walking only.

## Where the inn is

- Where you were when you last set your hearthstone, or where you landed the last time you hearthed. This is saved per character.
- Before either has happened, the innkeeper of the guide's "set your hearthstone" step for that town.

If neither is known (the hearthstone is set at an inn no guide uses, and you haven't hearthed there yet), there's no suggestion until you hearth once.

## Death skips

When dying on purpose would get you to the next town step faster, the step suggests it, for example: "Death skip: the graveyard is near this step. Dying to a mob and taking the spirit healer's resurrection saves about 3 min of walking." It's only a suggestion.

Setting: **Death Skip Suggestions** (Settings → General → Automation, on by default). Code: `Core/DeathSkip.lua`.

It shows when all of these hold:
- **Never on Hardcore:** the character doesn't play Hardcore, where a death is permanent.
- **A town step:** the current step is a turn-in, pick-up, trainer, vendor, inn, flight path or talk step with a position.
- **The graveyard is near it:** of the spirit healers in the zone you're in (QuestieDB's spirit healer list), the one nearest to you is nearer the step than you are. That's the graveyard the game sends your ghost to.
- **It saves enough:** the walk to the step, minus 45 seconds for finding a mob, dying and the resurrection, minus the walk from the graveyard. Below level 10 it must save a minute: the spirit healer gives no resurrection sickness up to level 10 ([Warcraft Wiki](https://warcraft.wiki.gg/wiki/Resurrection_sickness), unverified in game). From level 10 it must save 5 minutes, and the line warns about resurrection sickness.
- **Nothing better:** you're alive, not on a flight or in an instance, and no hearthstone suggestion is showing.

Gear loses durability when you die and again at the spirit healer, at any level; the line says so. Walking is worked out as for the hearthstone. Not known: whether a graveyard is closed to your faction (the data doesn't say), so the suggestion may name a graveyard you can't use.
