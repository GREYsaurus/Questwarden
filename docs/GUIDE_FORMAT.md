# Writing guides (`targets/<Target>/guides-src/*.guide`)

Guides are plain text, one step per line. `tools/build.ps1 guides` compiles them into `targets/<Target>/addon/Guides/Compiled/*.lua` and checks them against the bundled quest database. **Never edit the compiled files.**

Each target has its own sources (`targets/ClassicEra/guides-src/`, ...): quest ids, NPCs and coordinates differ between game versions, so a guide is never shared between targets.

Files are compiled in path order (`alliance/`, `horde/`, `outland/`, `shared/`, then file name). That order matters for the route checks: a turn-in in a later file can match an accept in an earlier one.

## Header

```
@guide A_Westfall                  unique id
@name Westfall                     display name
@faction Alliance                  Alliance | Horde | Both
@races Human,Dwarf                 optional; Night Elf / NightElf, Undead / Scourge, Blood Elf / BloodElf accepted
@classes Warrior                   optional; usually omitted
@levels 10-16                      intended level range (up to the target's level cap)
@zone Westfall                     zone name exactly as in the bundled zone table
@chapter Azeroth                   one of the target's chapters (Classic Era: Azeroth)
@start                             marks a racial starting guide (requires @races)
@desc Free text, can repeat to continue.
@next A_Redridge                   next guide; repeatable, first match wins
@next H_Feralas [faction=Horde]    conditions: [race=..] [class=..] [faction=..]
```

## Text: the add-on's name

Never write the add-on's name or slash command in a note: write `{name}` and `{slash}`. They are filled in when the guide loads (`{name} skips it` → *ClassicGuide skips it*, `/{slash} talents` → */cg talents*), so a rename needs no guide edits. The lint gate rejects the spelled-out name.

## Group content

On Classic Era, `[elite]`/`[group]` steps and `[dungeon=...]` steps are **off by default** (`contentDefaults` in `Target.ClassicEra.lua`); players turn them on in Settings. Mark every step of an elite quest `[elite; group; hc=skip]`. Tag dungeon quests' steps `[dungeon=<instance>]` by hand when the compiler's automatic tag may not catch them. The route audit gives no XP for either, so solo level gates hold.

## Escort quests

Escorts belong in routes. Put a `note` right before the pickup saying the next quest is an escort, then the accept, then the escort's `complete` step at once (the NPC starts walking from the giver), with *Escort: stay close; it fails if the NPC dies.* One escort at a time:

```
note The next quest, Tooga's Quest, is an escort: pick it up only when you are ready to follow the NPC.
accept 1560 Tooga's Quest
complete 1560 Tooga's Quest | Escort: stay close; it fails if the NPC dies.
```

The research tools write exactly this. They recognise an escort by quest flag 2 plus escort wording in the quest text, and leave out the other flag-2 quests (scripted events, duels, timed tasks).

## Hardcore route flavor

Each zone has one guide source. Hardcore characters (Settings → Guide Routing → *Hardcore character*, per character) follow the same file with two step flags:

| Flag | Meaning |
|---|---|
| `[hc=skip]` | left out of the Hardcore route (an elite, a mob well above the route's level, a risky pull) |
| `[hc=only]` | only on the Hardcore route: usually a `note` warning before a risky step |

```
note [hc=only] | Hardcore: Fizzle Darkstorm is level 12. Clear the cultists around him, then fight him alone at full health and mana.
accept Wanted: "Hogger" [elite; group=3; hc=skip] | ...
```

Mark every step of a quest you leave out (accept, complete and turn-in). Base each warning on the bundled data (NPC level, rank, nearby mobs) and write it in your own words. `python tools/research/danger_report.py ClassicEra` (after `routes`) lists steps with a hostile elite, a higher-level rare or a much higher mob within 40 yards, and whether a Hardcore note already stands before them (`docs/generated/<Target>/danger-near-steps.csv`). The flags are only allowed on targets with a Hardcore ruleset (`hardcore = true` in `Target.<Target>.lua`). The route audit walks every race/class route twice, as Speed and as Hardcore, and both must pass.

## Steps

```
<verb> <arguments> [flags] | <note text> [flags]
```

| Verb | Arguments | Completes when |
|---|---|---|
| `accept` | quest | quest is in the log or already turned in |
| `turnin` | quest | quest-completed flag / `QUEST_TURNED_IN` |
| `complete` | quest (`[obj=N]` for one objective) | quest log reports complete |
| `goto` | `x,y` (zone = guide zone, or `[zone=...]`) | arrow arrives within 12 yards, or manual |
| `talk` | NPC name or id | manual |
| `train` | - (expands to one step per class, with that class's trainer from the database) | trainer window closed |
| `fp` | place name | "New flight path discovered" or taxi map opened |
| `fly` / `hs` / `travel` | destination zone/subzone name | zone change to the destination, or manual |
| `bind` | inn location name, plus required `[area=<id>,...]` | `GetBindLocation()` equals one of the areas' names in the client's language, or a bind ClassicGuide verified at this step's innkeeper |
| `level` | level | player level reached |
| `grind` | `<level> <Mob>[, <Mob>...] [@ location]` | player level reached (same as `level`). Each mob must exist in the database and spawn in the step's zone, or the build fails. The arrow points at the spawn nearest the previous step unless `[at=x,y]` is given. Example: `grind 10 Riverpaw Outrunner, Riverpaw Runt @ south of Westbrook Garrison [at=27.8,81.2] \| note` |
| `note` / `buy` / `use` / `collect` | text | manual (`buy` also completes on closing a vendor) |
| `guide` | guide id | manual |

### Quest references

- `accept A Threat Within` - by name. The compiler finds the quest that fits the guide's faction and races, is not yet done on the route, and has its prerequisites met.
- `accept 783` - by id.
- `accept 783 A Threat Within` - id plus name. The compiler fails if they disagree, which catches typos.

If a name is ambiguous (e.g. the three "Rite of Vision" quests), the compiler stops and lists the candidate ids. Write the id.

### Flags

`[optional]`, `[elite]`, `[group]` or `[group=3]`, `[dungeon=Shadowfang Keep]`, `[class=Warrior,Paladin]`, `[race=Human]`, `[faction=Horde]` (in a `Both` guide: the step is for that faction only, and quest names resolve as in that faction's guides), `[zone=Orgrimmar]`, `[at=x,y]` (explicit coordinates; marked unverified), `[obj=2]`, `[unverified]`, `[mark=skull]` / `[mark=cross:Lieutenant Benedict]` / `[mark=star:1234]` (raid marker; see docs/RAID_MARKERS.md). Separate several flags with `;` inside one bracket: `[elite; group=3; optional]`.

**Dungeon quests:** tag every step (accept, complete, turn-in) of a quest that can only be done inside an instance with `[dungeon=<instance>]`. The *Include Dungeon Quests* setting leaves tagged steps out of the route. Follow-up quests that need an excluded dungeon quest are skipped automatically, so don't tag those. Don't tag an outdoor quest that only sends you towards a dungeon (a breadcrumb, or objectives at the entrance). You rarely need to write the tag: the compiler tags a quest's steps itself when the bundled data puts every objective inside one dungeon or raid (the one authoritative mapping; audit in `docs/generated/<Target>/dungeon-quests.csv`). A hand-written tag wins, for quests the data cannot place. Quests with only some objectives inside are listed in `docs/generated/<Target>/dungeon-mixed.csv` and are not tagged.

### What the compiler adds for you

- the quest title, giver/finisher NPC name and coordinates (the spawn nearest the previous step);
- trainers, flight masters and innkeepers, looked up by NPC flags in the zone;
- a verification flag: `v=1` for database-derived data, `v=0` for hand-written coordinates.

### What the compiler checks

Errors (the build fails): unknown or ambiguous quests, quests not available to the guide's faction or races, class quests without `[class=]`, unknown zones or guides, malformed lines.

Warnings (`docs/generated/<Target>/guide-warnings.log`): prerequisites not turned in anywhere on the route, turn-ins without an accept, quests whose required level is above the guide's range, repeatable quests, and complete-steps with no objective location in the data.

Write notes only when you are sure of them. For complete-steps, the add-on already shows the quest log objectives and the database objective text.

## Route checks (`tools/build.ps1 routes`)

After compiling, every race/class route is walked step by step (docs/ROUTE_OPTIMIZATION.md). The build fails if a quest is accepted before one of its prerequisites is turned in on that route, if a complete-step comes before its accept, or if the quest log would exceed the target's size (Classic Era 20). Accept a quest after the turn-in that unlocks it, and give every pickup a turn-in somewhere on the route.

An `[optional]` turn-in of a quest accepted in an **earlier** guide (a breadcrumb) is skipped automatically for players who do not have it in their log. A non-optional one is never auto-skipped.

### Bind steps

`bind Kharanos [area=131,2102]`. The place name is shown to the player; the `area` ids decide completion.
- **Area ids** are AreaTable ids from the client (wago.tools, product `wow_anniversary`). `GetBindLocation()` reports the area the inn stands in, which is not always the town: Kharanos reports *Thunderbrew Distillery* (2102), Thelsamar *Stoutlager Inn* (2101), Menethil Harbor *Deepwater Tavern* (2104), Brill *Gallows' End Tavern* (2119), Aerie Peak *Wildhammer Keep* (349). List the town and, where it has one, its inn area.
- **Why ids:** `C_Map.GetAreaInfo(id)` names the area in the client's language, so the check works on every client. The compiler rejects a bind step without `[area=]`.
- **Innkeeper:** the compiler picks the nearest innkeeper of the guide's faction (NPC flag) and stores its NPC id; bind automation only acts at that innkeeper or another innkeeper of the same town.

### Roaming hunting routes

Routes for kill and kill-for-drop objectives live in `targets/<Target>/guides-src/routes/*.routes`, not in the guide files: they attach to a quest and its quest-log objective index, so guide steps, ids and saved progress do not change. Format, compiler checks and the research method: docs/ROAMING.md.
