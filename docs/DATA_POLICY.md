# Data policy: facts only, rebuilt from our own sources

ClassicGuide is GPL-3.0-only. Everything it ships must be either our own work or come from a source whose licence lets us ship it under the GPL. This page says where data may come from, what is never allowed, and how we check our data against other people's without copying it. **Contributors follow it too.** It is a cautious project policy, not legal advice.

## The short version

- We ship **facts** (quest IDs, NPC IDs, spell IDs, coordinates, flight times, mob levels), each rebuilt from a source listed below.
- Every generated record says where it came from (`src`) and whether it is verified (`v=1`) or not (`v=0`).
- A fact we cannot rebuild from these sources is **left out** and listed in [DATA_GAPS.md](DATA_GAPS.md).
- Text a player reads (step notes, tips, warnings, dangerous-mob notes) is written fresh, in our own words.
- Other add-ons' data files may be used as a **checklist** and a **cross-check**, never as a source.
- When unsure whether something is a fact or someone's expression, leave it out and ask the maintainer.

## Where facts come from, in order of preference

| # | Source | What it gives | `src` value |
|---|---|---|---|
| 1 | **QuestieDB** export for the target (GPL-3.0, pinned in `tools/upstream.json`) | quests, NPCs, objects, items, coordinates, prerequisites | `questie` |
| 2 | **Client data**: DB2/DBC table exports for the target build (wago.tools) | spells, trainer lists, talents, flight nodes, map IDs, spirit healer positions | `client` |
| 3 | **Our own in-game captures** from the recorder module (planned, docs/FOREVER_PLAN.md) | IDs, coordinates, patrol paths, flight times, saved to SavedVariables | `capture` |
| 4 | **Published, citable research** for stat weights (class Discords, theorycraft sheets, Wowhead, Icy Veins) | numbers with a citation and a confidence level each | `research:<url>` |

**Route research.** Leveling guides on the web may be read for facts about routes: which zones to level in, at which levels, where to set the hearthstone, where grinding is needed, which elites and quests are risky. Approved so far: **Joana's Classic speedrun guides** (joanasworld.com, approved by the maintainer 2026-10-29). We do not copy their text, notes or step-by-step order: our step order comes from QuestieDB prerequisites and our own route model, and every note is our own. Each guide file that used one says so in its header.

Our own reasoning on top of these (which mobs count as dangerous, which steps a Hardcore route leaves out, stat priorities where nobody publishes numbers) is our own work, and says so.

**Verification.** `v=1` means the value came straight from source 1, 2 or 3 for the target build. Anything typed by hand, estimated, or carried over from another game version is `v=0` until checked in the game. Nothing from Classic Era is assumed to hold on WoW: Forever without a source or an in-game check.

**Adding a source** to this table is a reviewed decision (ask the maintainer first), like adding a WoW API to the allowlist.

## Reference files: checklist and cross-check only

The maintainer holds sixteen data files from the **RestedXP (RXPGuides)** add-on, Classic Era and Forever variants: database tables, quest tables, trainer spells, stat weights, flight data, spirit healers, rares and dangerous mobs. RXPGuides is published under **CC BY-NC-SA 4.0**, which is not compatible with the GPL. We avoid the conflict by never shipping anything of theirs. RestedXP is **not an upstream** of this project and is not credited as a source of data.

Allowed:
- **Finding out what needs coverage:** which zones, rares, dangerous mobs, trainer spells, flight paths and stat-weight level bands exist.
- **Cross-checking** our own data after it has been generated from our sources, and listing disagreements in DATA_GAPS.md so they can be checked in the game.
- **Learning the kinds of data** a guide needs, to design our own schemas (`addon/Database/Schema.lua`).

Not allowed:
- Copying, pasting, converting or loading their tables, files or code into anything we ship, including "temporarily" or as seed data.
- Reusing their wording: notes, comments, guide text, step text or guide names.
- Reusing their selection and arrangement: patrol paths, their choice of which mobs count as dangerous, their stat-weight numbers, their table layouts. We build our own lists from our own criteria.
- A script that reads their files and writes our data. Cross-check scripts may read both, but write only a comparison report under `docs/generated/`.
- Anything from RestedXP's paid guide content, in any form.

The reference files are **never committed** to this repository. `tools/build.ps1 crosscheck` (Phase 2) reads them from a folder outside the repository and writes only `docs/generated/CROSSCHECK.md`.

The same rules apply to any other guide add-on's data, whatever its licence says, unless the maintainer has added it to the source table above.

## The cross-check process

1. Generate our table from our own sources (`tools/build.ps1 import-questie`, `import-client`, or a capture import).
2. Run `tools/build.ps1 crosscheck -Reference <folder outside the repo>`. It lists entries they have and we lack, entries we have and they lack, and values that differ.
3. For each difference, do one of these:
   - find the fact in one of **our** sources and fix our generator or add an override with that source;
   - add it to the in-game check list in DATA_GAPS.md;
   - leave it, if our source is authoritative (for example, client tables beat anyone's hand-made list).
4. **Never** fill a gap with their value.

## Reference material used for checks, not shipped

- **Blizzard's UI source** for each client (github.com/Gethe/wow-ui-source, branches `classic_era`, `forever`, `classic_anniversary`), kept in `.cache/`. `tools/research/api_audit.py` reads it to report whether each allowlisted API exists on that client and whether Blizzard marks it protected or restricted (docs/COMPATIBILITY.md). Nothing from it is copied into the add-on.
- **wago.tools build list** and **Questie's release.json**, to confirm client builds and interface numbers.

## Records and files

- Every generated table keeps `src` and `v` per record (`Database/Schema.lua` documents the layout). The TBCGuide-era tables do not have these fields yet; the Phase 2 importers add them for Classic Era.
- Generated files say in their header which source and which pinned version they came from.
- Licence and attribution for every real upstream: [NOTICE.md](../NOTICE.md) and [THIRD_PARTY_LICENSES.md](../THIRD_PARTY_LICENSES.md).
