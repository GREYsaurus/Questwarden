# Publishing on CurseForge

Questwarden releases are built and checked locally (`tools/build.ps1 package`) and published as GitHub releases. The workflow `.github/workflows/curseforge.yml` then uploads **the same zip** to CurseForge whenever a GitHub release is published. The zip serves both games: it holds `Questwarden_Vanilla.toc` (Classic Era) and `Questwarden_TBC.toc` (TBC Classic Anniversary), and each client loads its own. A tag containing `alpha` goes up as **alpha**, other pre-releases as **beta**.

The one-time setup below needs the project owner's CurseForge account; it cannot be done for you.

## 1. Create the project (once)

Sign in at <https://authors.curseforge.com> and start a new project:

| Field | Value |
|---|---|
| Game / class | World of Warcraft, Addons |
| Name | Questwarden |
| Summary | Free 1-60 leveling guide for Classic Era and 1-70 for TBC Classic Anniversary, with built-in quest data, talents and quest automation. |
| Description | paste `docs/curseforge/DESCRIPTION.md` |
| Main category | Quests & Leveling |
| Other categories (optional) | Map & Minimap, Class |
| License | GNU General Public License version 3 (GPLv3) |
| Logo / avatar | `docs/curseforge/logo.png` (400×400, original artwork: a shield holding a dotted route and a waypoint arrow; source `docs/curseforge/logo.py`) |
| Source URL | https://github.com/GREYsaurus/Questwarden |
| Issues URL | https://github.com/GREYsaurus/Questwarden/issues |

New projects, and each uploaded file, are reviewed by CurseForge moderation before they become public.

## 2. Connect GitHub (once)

1. Note the **project ID** shown on the new project's page. Questwarden's is **1776364** (https://www.curseforge.com/wow/addons/questwarden, created 2026-10-31); it is set as the repository variable `CURSEFORGE_PROJECT_ID`.
2. Create an API token: CurseForge account settings, then **API tokens**.
3. In GitHub, open the repository's **Settings > Secrets and variables > Actions**:
   - add the **secret** `CF_API_KEY` with the token;
   - add the **variable** `CURSEFORGE_PROJECT_ID` with the project ID.
   - Optional variable `CURSEFORGE_GAME_VERSIONS` (default `1.15.9,2.5.6`). The workflow looks up each CurseForge game version by exact name and stops with a list of candidates if a name does not match exactly one.

## 3. Release

1. Load the add-on once in each game (Classic Era and TBC Anniversary) and check `/qw debug`: no errors, the right target shown.
2. Run `powershell -ExecutionPolicy Bypass -File tools/build.ps1 package`. It tests the folder through both TOCs and writes `dist/Questwarden-<version>.zip` and the source zip.
3. On GitHub, create a release with the tag `v<version>` (for example `v0.1.0-alpha.1`), mark it as a **pre-release**, and attach both zips. Publishing it triggers the upload.

- **Re-run for an existing release:** **Actions > Publish to CurseForge > Run workflow**, then enter the tag.
- **By hand (alternative):** on the CurseForge project, upload `Questwarden-<version>.zip`, choose game versions *1.15.9* and *2.5.6*, release type *Alpha*.

Without the secret and variable, the workflow skips the upload with a notice instead of failing.
