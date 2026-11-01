# Class trainer suggestions

Setting: **Class Trainer Suggestions** (General → Automation, or the setup wizard's Options step): *Off*, *Important only* (default) or *All*. Saved per character; a character that never chose keeps the settings profile's value. Command: `/qw train` (list), `/qw train defer` (hide until your next level), `/qw train waypoint` (arrow to the nearest class trainer of your faction).

Built in: the trainer data comes from **What's Training?**, bundled in Questwarden; that add-on does not need to be installed, and if it is, the two do not interact.

## What it does

- **Where train steps send you:** to your class trainer nearest to where you stand in your zone, on the arrow, in the step title and for the raid marker; when your zone has none, to the trainer the guide names (and with no name, your capital's).
- **Train steps** list what the trainer has for you now, grouped per spell ("Rend (Rank 2, 3)"). A train step with nothing new for the chosen setting is skipped with the reason ("nothing important to train yet"). *Off* keeps the old train steps unchanged.
- **Level-up:** when new **important** ranks become available, one chat line names them and the next train step on your route (or points to `/qw train waypoint` when the route has none).
- **Live eligibility:** every rank is checked against your spellbook with `IsSpellKnown` when the list is built, and again when you learn a spell (`LEARNED_SPELL_IN_TAB`) or level up. Known ranks are never suggested again.
- **Talent ranks** (Mortal Strike 2+, Pyroblast 2+, ...) are listed only once you know the rank before them, so only after you take the talent.
- **Class quest spells** (Defensive Stance, Bear Form, Summon Voidwalker, ...) are listed apart, "from a class quest", and are never a reason to visit the trainer.
- **Race-only spells** (priest racials, faction portals) are listed only for races that get them.
- **Names** come from the client (`GetSpellInfo`), so they show in your client's language. The word "Rank" in the grouped line is English.
- **Suggestions never spend gold.** Only the opt-in *Automatic Training* (below) buys at a trainer.
- **Defer and view again:** `/qw train defer` hides the lists until your next level; `/qw train` shows them again at once. Saved per character.

## What the trainer sells (What's Training?)

**Data:** for each class, the class-trainer spell list of What's Training? (fusionpit, MIT) at commit `26caff2` (`Classes/WhatsTrainingData.lua`). Its `Classes/Vanilla` data serves Classic Era and its `Classes/TBC` data serves TBC Classic Anniversary; upstream's own TOC (Interface 11509 and 20506) uses them for exactly these clients. Forever has none and keeps the behaviour below unchanged.

**Combined with the client tables** (`Classes/TrainingData.lua`, which give names, ranks and the talent families):
- **Sold by the class trainer:** the rank is in the What's Training list. It takes that list's level, base price, earlier-rank and talent requirements, and its faction and race limits.
- **From a class quest:** our notes (`Classes/TrainingNotes.lua`), as before.
- **Not from the class trainer:** in the client tables but not in the What's Training list, and not a known class quest: books (Classic's rank-11 Healing Touch, Frostbolt and others), the shaman totem quests, mounts, some race spells. Listed apart as "not from the class trainer (a book, drop, vendor or quest)": how exactly is not known here, and they are never a reason to visit the trainer.
- **Trainer-only additions:** trainer services the client-table import leaves out (passives such as Parry, Dual Wield, Plate Mail; a few level-1 ranks). Names come from the client.

**Requirements:**
- An earlier rank you do not know yet holds back a rank, unless that earlier rank is ready too: then both are listed, to buy in order in the same visit.
- Talent ranks need the talent (What's Training's `requiredTalentId`).
- Faction spells (mage teleports and portals) are only listed for your faction; race spells only for your race.
- Rogue poisons carry a Poisons skill requirement in the data; it is not checked against your skill.

**Not imported:** hunter pet abilities (taught to the pet), Warlock tomes and weapon skills.

The comparison of both sources is generated per target in `docs/generated/<Target>/whatstraining-crosscheck.md`. Classic Era: 1,250 spells in both, with no level differences. TBC: 1,670 in both, 2 with a different level (the What's Training level is used).

## Training costs

Each listed spell shows its price when one is known, and the list ends with a total. With *All*, there are also separate totals for important spells and for the rest.

The client tables have no trainer prices. A price comes from, in this order:

| Price shown | Comes from |
|---|---|
| current | The class trainer you have open (`GetTrainerServiceCost`). It already includes any reputation discount there. |
| last seen | What a class trainer charged a character on this account before (`QuestwardenDB.trainCosts`, in copper). Another trainer or reputation can change it. |
| listed | The base price in What's Training's data. A reputation discount can make the real price lower; totals say how many prices are listed ones. |
| unknown | Never guessed (only ranks without a listed price, such as Forever's). |

**How totals work:**
- **Partial totals:** a total that includes unknown prices is marked **partial** and never claims you can afford it.
- **Affordability:** a complete total says whether your gold covers it.
- **What's counted:** known ranks and spells above your level are never in the total.
- **Profession trainers** are not read.
- **Buying:** only with *Automatic Training* on (below). Questwarden has no gold-reserve setting, so none is applied.

**Pet and demon skills:** train steps also list a few pet or demon skills; see docs/PETS.md.

## Automatic training (opt-in)

Setting **Automatic Training** (General → Automation, and the setup wizard's Options step: *Learn recommended spells automatically*). Off by default, saved per character.

| Choice | When you open your class trainer |
|---|---|
| Off | Nothing is bought. |
| Recommended spells | Learns the ranks the training suggestions list for you: the important ones, or all of them with suggestions set to All. Matched by the spell's name and rank in the trainer window. |
| Everything I can afford | Learns every spell the trainer offers that you can afford (the old *Trainer automation*). |

- **Spends gold:** only what you can afford at that moment, one spell at a time, in the order the trainer lists them; the next one waits until the server has confirmed the last. The game announces each spell; when you close the trainer, one chat line says how many were learned and what they cost.
- **Order:** a rank and the earlier rank it needs are both bought, earlier rank first, because the trainer lists the earlier one first and the next appears once it is learned.
- **Never:** at a profession trainer in *Recommended*, pet skills, or while you hold **Shift** (skips buying for that visit).
- **Learned** means the game says you know it; buying is the only thing that changes that.
- **Existing characters:** one that had the old profile switch *Trainer automation* on keeps "everything" until a choice is made for it; the choice then wins.

## In the guides

- **Speed and Hardcore routes:** the guides' own train steps are where training is suggested; nothing is added to a guide and the route order never changes. A train step lists what is ready and is skipped when nothing is (or while suggestions are deferred). A new important rank at level-up gives one chat line naming the next train step, or `/qw train waypoint` when the route has none: an optional trip, never inserted.
- **Completionist:** a planned segment gets one optional train step, after its pickups, only when suggestions are on and not deferred, something is ready to train, and your class trainer is in that segment's zone (bundled NPC data). The route never travels just to train, and the step is not a quest: it is not counted in Completionist's quest totals.
- **No trainer in the data:** the list is still shown; `/qw train waypoint` says there is no position, and no waypoint is made up.
- **Learning:** a rank counts as learned only when the game says you know it (`IsSpellKnown`), checked again when you learn a spell or level up. Opening a trainer, completing or skipping a train step, and deferring never mark anything learned.
- **Build:** the talent plan or gear profile you chose does not change which ranks are listed. The *important* and *optional* lists are Questwarden's general leveling judgement per class (`TrainingNotes.lua`), not a per-build recommendation; the list shows what you can train, not an optimised plan.

## Where the data comes from

`addon/Classes/TrainingData.lua` is generated by `tools/build.ps1 import-client` (`tools/src/TrainingTables.cs`) from the client's own DB2 tables, build 2.5.6.70577, exported by wago.tools:

| Table | Used for |
|---|---|
| SkillLine | the class spell lines (category 7, class-spec flag) plus Poisons |
| SkillRaceClassInfo | the class of each line, for rows whose own class mask is 0 |
| SkillLineAbility | spell, class, race mask |
| SpellLevels | the level a rank becomes available (BaseLevel, or SpellLevel when BaseLevel is 0: Innervate on Classic Era and every rogue poison recipe carry only SpellLevel) |
| Spell, SpellName | rank text and English name |
| Talent | talent spells: rank 1 comes from the talent, higher ranks need the talent |

**Left out:**

- level-1 spells (known from character creation);
- helper and effect spells the trainer never lists (passives, "... Effect", judgement effects and a short named list in `TrainingTables.cs`);
- rank 1 of talent spells;
- pet, weapon and profession skills.

Rogue poison recipes (the Poisons skill line) are listed since 2026-10-31: their level is in `SpellLevel`.

**Kept by hand** (`addon/Classes/TrainingNotes.lua`):

- **Which spells come from class quests.** The client tables do not say. Every listed spell has a client "teach" spell (Path of Defense, Path of the Berserker, Tame Beast, Beast Training, Teach Summon ...), and the tests check each id exists.
- **The important and optional lists**, which are Questwarden's own leveling judgement. Everything else counts as useful.

### Inventory (this build)

| Class | Ranks | Spells | Talent ranks | Race-only ranks | Quest spells | Important spells | Optional spells |
|---|---|---|---|---|---|---|---|
| Druid | 239 | 58 | 15 | 0 | 5 | 28 | 9 |
| Hunter | 147 | 54 | 15 | 0 | 5 | 18 | 17 |
| Mage | 224 | 66 | 23 | 24 | 0 | 24 | 13 |
| Paladin | 186 | 58 | 18 | 8 | 1 | 25 | 14 |
| Priest | 255 | 53 | 25 | 66 | 0 | 20 | 10 |
| Rogue | 113 | 34 | 6 | 0 | 1 | 18 | 10 |
| Shaman | 207 | 53 | 2 | 2 | 0 | 20 | 11 |
| Warlock | 201 | 56 | 24 | 0 | 6 | 22 | 16 |
| Warrior | 135 | 39 | 18 | 0 | 5 | 22 | 10 |

Optional by pattern for every class: teleports, portals, Greater Blessings, tracking.

## Limitations

- **Training costs** come only from trainer windows; prices for spells never seen at a trainer are unknown.
- **Class-quest spells beyond the list above** may show as trainer spells. For example, whether paladin and warlock mounts come from the trainer or a quest has not been checked in 2.5.6. In-game check: `docs/COMPATIBILITY.md` → Trainer.
- **Hunter pet skills and warlock demon grimoires** are not covered.
- **Not run in the game yet.** Tested headless: `tests/test_trainer.lua`, with data checks and a mocked spellbook.
