# Talents (WoW Classic Era)

Questwarden's talent calculator and talent-window suggestions use the 51-point Classic Era trees, generated from the 1.15.9 client tables (`targets/ClassicEra/addon/Talents/Data/TalentTrees.lua`: 432 talents in 27 trees, 7 tiers). How the calculator and the talent-window markers work is unchanged from TBCGuide ([tbcguide/TALENTS.md](tbcguide/TALENTS.md)).

## Talent plans

There are **28 plans**, one for every spec Icy Veins publishes a Classic leveling build for. Each runs from the first talent point (level 10) to 60 without a respec, so it is also that spec's level-60 build: tank (Protection Warrior and Paladin, Feral), healer (Holy and Discipline Priest, Holy Paladin, Restoration Shaman and Druid) and damage.

| Class | Plans (default first) |
|---|---|
| Warrior | Arms (31/20/0), Fury (20/31/0), Protection (11/4/36) |
| Paladin | Retribution (16/0/35), Holy (32/7/12), Protection (11/31/9) |
| Hunter | Beast Mastery (31/20/0), Marksmanship (20/31/0), Survival (0/20/31) |
| Rogue | Combat swords (19/32/0), Combat daggers (15/31/5), Subtlety (21/0/30) |
| Priest | Shadow (14/0/37), Holy (14/32/5), Discipline (33/13/5) |
| Shaman | Enhancement (0/38/13), Elemental (31/0/20), Restoration (19/0/32) |
| Mage | Frost AoE grinding (19/0/32), Frost single target (17/0/34), Fire (11/37/3), Arcane (31/0/20) |
| Warlock | Affliction (30/21/0), Demonology (16/35/0), Destruction (17/0/34) |
| Druid | Feral (14/32/5), Balance (36/0/15), Restoration (19/0/32) |

The default plan for a class (used until you pick another in `/qw talents`) is the first in its row.

## Sources

- **Icy Veins** WoW Classic leveling guides ([index](https://www.icy-veins.com/wow-classic/wow-classic-leveling-guides), read 2026-10-29), chosen by the maintainer as the main source. Every plan above comes from it.
- **Wowhead** is the fallback for any spec Icy Veins does not list. Only **Assassination Rogue** is missing there, and Wowhead's Classic rogue leveling guide has no Assassination build either (it lists Combat swords, Combat daggers and Subtlety/Hemo). So there is **no Assassination plan**: nothing is invented, and Assassination rogues see "no plan" and can choose any rogue plan.
- Builds a source labels PvP are treated as leveling builds (maintainer's rule). None of the Icy Veins leveling pages used here is a PvP build.

## How the plans were made

1. Each Icy Veins build page carries a talent-calculator point string (`data-talentcalculator-pointsurl`, `#tc-...`), one character per point in the order the points were added. The pages and the calculator files were read in a browser.
2. The calculator script maps characters `0-9`, `a-z`, `A-Z` to the non-empty talent slots of its per-class JSON in order, across the three trees. Decoding gives each point's talent, its rank-1 spell id, tree, row and column (`tools/research/icyveins_classic_decoded.json`, facts only).
3. `tools/research/talent_builds.py ClassicEra` matches every point to a client talent by its rank-1 spell id and stops if the tree, tier or column differ from the client data, or a talent gets more ranks than it has. All 1,428 points matched; no correction was needed.
4. `tools/build.ps1 validate` re-checks every plan against the client trees: tier gating (5 points per tier), prerequisites, and the 51-point budget. The smoke tests check that every class has a leveling plan.

Plans are the source's allocation and order. Whether a plan suits a given player is the source's judgement, not tested by us.
