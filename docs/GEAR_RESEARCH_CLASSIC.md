# Gear research: WoW Classic Era stat priorities

Sources behind `targets/ClassicEra/addon/Gear/Profiles.lua`. All were read on 2026-10-31 in a browser. They are source tier 4 in [DATA_POLICY.md](DATA_POLICY.md): published, citable research. We take only the order of stats. The wording and explanations stay on the source pages.

## Result in one line

**No Classic Era source we may use publishes numeric stat weights.** The Icy Veins pages give priority lists and a few rules of thumb (1 Strength = 2 AP for warriors, 14 AP = 1 weapon DPS, hit caps). Every Classic profile is therefore priority-only, scored stat by stat (GEAR_SCORING.md). Automatic upgrades turn the order into estimated weights and label them as estimates (AUTO_EQUIP.md).

## Sources

| Key | Source | Context | Used for |
|---|---|---|---|
| S1 | Icy Veins, WoW Classic spec leveling pages, "Leveling Stats" section (`icy-veins.com/wow-classic/<spec>-leveling-talent-build-from-1-to-60`) | 1-60 leveling | Paladin Holy, Retribution, Protection; Druid Feral, Balance, Restoration |
| S2 | Icy Veins, WoW Classic class leveling guides, "Gear Options" / "Preferred Gear and Stats Options" (`icy-veins.com/wow-classic/classic-<class>-leveling-guide`) | 1-60 leveling, prose | Warrior, Mage, Priest, Shaman |
| S3 | Icy Veins, WoW Classic Hardcore class overviews, "Stat Priority" (`icy-veins.com/wow-classic/hardcore-<class>-class-overview`) | Hardcore leveling | Warlock |
| S4 | Icy Veins, WoW Classic PvE stat priority pages (`icy-veins.com/wow-classic/<spec>-<role>-pve-stat-priority`) | level 60 PvE (raids) | every level-60 profile |
| S5 | Wowhead, Classic Rogue DPS stat guide (`wowhead.com/classic/guide/classes/rogue/dps-stat-priority-attributes-pve`) | level 60 PvE | agrees with S4 on the Rogue order |

## Leveling (levels 1-59)

| Profile | Priority (best first) | Notes | Confidence |
|---|---|---|---|
| warrior_leveling_early (1-29) | Str, Agi, Spi, Sta, Armor | Weapon first (high damage, slow). Spirit matters early; by 30, food, bandages and potions take over. Prose, so the order between Strength and Agility is as written | low |
| warrior_leveling (30-59) | Str, Agi, Sta, Armor | as above | low |
| paladin_holy_leveling | +Holy dmg, Spi, Int, Sta, Str | listed | medium |
| paladin_retribution_leveling | Str, Spi, Agi, Int, Sta | listed; Agility is weak before Vengeance | medium |
| paladin_protection_leveling | Str, Spi, Int, Sta, Agi | listed | medium |
| mage_leveling | Int, Spi, SP, Sta | prose: Intellect first, Spirit useful, spell damage of little use while leveling | low |
| priest_shadow_leveling | SP, Mp5, Int, Spi | prose; the wand matters most | low |
| priest_leveling (Holy, Disc) | Int, Spi, Mp5 | prose | low |
| shaman_enhancement_leveling | Agi, Crit, Str, Sta, Int | prose; the weapon matters most | low |
| shaman_leveling (Elemental, Resto) | Int | prose: "Intellect first and foremost"; nothing else is ranked | low |
| warlock_leveling | Sta, Int, Spi | the Hardcore page (S3); no Classic leveling page ranks Warlock stats | low |
| druid_feral_leveling | Agi, Str, Spi, Sta, Int | listed | medium |
| druid_balance_leveling | +Nature/Arcane dmg, Int, Spi, Sta | listed | medium |
| druid_restoration_leveling | +Nature dmg, Int, Spi, Sta | listed | medium |

**No leveling profile for Rogue or Hunter.** Their Icy Veins spec leveling pages have no stat section. Their class leveling guides and Hardcore overviews point to a "Gear" section that is not on the page. Wowhead has no Classic leveling guide for them. Below 60 these two classes get no score, and the tooltip says there is no researched leveling profile.

## Level 60 (S4)

Each profile lists the page's main priority in order. Stats the scorer has no key for are named in the profile's `assumptions`:
- weapon damage and speed, and weapon skill (warrior, enhancement shaman, rogue);
- resistances and spell penetration (mage, warlock, elemental shaman).

The hit caps the pages give are in the assumptions too: 9% melee or ranged, about 6% with 305 weapon skill, 16% spell, and 6% from gear for a Shadow Focus priest. They are not enforced as `caps`, because a priority-only profile never adds hit up.

## Not verified

- **How the client reports hit and crit:** whether Classic Era's `GetItemStats` reports "Improves your chance to hit by 1%" as `ITEM_MOD_HIT_RATING_SHORT = 1` needs a check in the game (DATA_GAPS.md, API availability).
- **The `heuristic` budget for hit, crit, dodge, parry and block:** 10 primary points per 1%. It is our own estimate for automatic upgrades only, not from a source.
