# Client compatibility

## Targets

Questwarden is built for one client at a time (`tools/build.ps1 -Target <name>`, docs/DEVELOPER.md). Each target's game rules live in `targets/<Target>/Target.<Target>.lua`, which the build ships as `Config/Target.lua`.

| Target | Client | Interface | Shipped | Evidence (checked 2026-10-29) |
|---|---|---|---|---|
| **ClassicEra** | WoW Classic Era 1.15.9 (build 70576) | 11509 | yes | wago.tools lists `wow_classic_era` at 1.15.9.70576 (2026-10-26); Questie v12.3.1 release.json lists flavor `classic` at 11508 and 11509; Blizzard UI source branch `classic_era` is 1.15.9 (70576) |
| **Forever** | World of Warcraft: Forever 1.60.1 | 16001 | **no** (skeleton) | **unverified**: Questie release.json flavor `forever` 16001; wago.tools product `wowf` 1.60.1.70685; Blizzard UI source branch `forever` 1.60.1 (70532) |
| TBC | TBC Anniversary 2.5.6 | 20506 | never | TBCGuide 0.9.5's data, kept only as a test fixture |

Classic Era rules from these sources: level cap 60, 51 talent points (first at 10), quest log 20 (`MAX_QUESTLOG_QUESTS` in Blizzard's `Vanilla/Constants.lua`), no flying, Azeroth only. Mount at 40 is game knowledge, not machine-checked.

## Wrong-client detection

`Core/TargetCheck.lua` runs while the add-on loads, before the compiled guides register:

- It compares `GetBuildInfo()`'s interface number and version string with the target's `minInterface`/`maxInterface` and `versionPrefix`. **Any other client:** no guide is registered, and login prints one line naming both versions (for example, the Classic Era build loaded on a Forever client). The talent calculator, settings and other tools still load.
- **Interface 0** (client did not report one): a warning only.
- **Unverified target** (`verified = false`, as for Forever now): guides are refused with a message saying the data has not been checked in the live game.
- `/qw debug` repeats the result.

Not used yet, because they are not on the API allowlist (awaiting approval): `WOW_PROJECT_ID` and the Forever-only `WOW_PROJECT_CAMELOT` (a second detection signal), and `C_GameRules.IsHardcoreActive` (Hardcore realms). Blizzard's UI calls all three on both clients. Until approved, Hardcore is a per-character setting (Settings → Guide Routing → *Hardcore character*), and Season of Discovery is not detected (out of scope).

## API audit

`python tools/research/api_audit.py .cache/wow-ui-source/<branch> <branch> docs/generated/<Target>/api-audit.md` checks every name on `tools/wow_api_allowlist.txt` (and every API the add-on reaches by name through `Compat.has`) against Blizzard's UI source for that client. It reports whether Blizzard documents the name, whether its UI code uses it, and whether it is flagged `IsProtectedFunction` or `HasRestrictions`. **This is evidence, not an in-game test**: C functions are not all documented, so "not found" means "unconfirmed".

| Client | Documented | Used by Blizzard UI | Other add-on | Global string | Not found |
|---|---|---|---|---|---|
| Classic Era 1.15.9 | 65 | 174 | 5 | 5 | 35 |
| Forever 1.60.1 | 81 | 146 | 5 | 3 | 49 |

284 names: the 252 on the allowlist plus **32 that the code reaches by name through `Compat.has` / `Compat.Has` and that are not on the allowlist**. That gap was inherited from TBCGuide: the lint gate only sees global reads, so these were never reviewed. `tools/build.ps1 lint` now warns about each one (39 warnings). They are item, container, auction, equipment and add-on-metadata functions used by gear scoring, junk selling, the auction tab and auto-equip, each with a fallback. Adding them to the allowlist is a reviewed decision and waits for approval.

Reports: [Classic Era](generated/ClassicEra/api-audit.md), [Forever](generated/Forever/api-audit.md), [TBC 2.5.6](generated/TBC/api-audit.md).

### Protected and restricted APIs (1.15.x)

On Classic Era, Blizzard flags two allowlisted APIs, and both were already handled:

| API | Flag | How Questwarden uses it |
|---|---|---|
| `SetRaidTarget` | restricted | automatic marking through Compat with `pcall`; if refused, automatic marking switches off and the click-driven marker bar (secure buttons) stays (docs/RAID_MARKERS.md) |
| `DeleteCursorItem` | restricted | junk discard only runs during the player's own click or key press, re-checks the slot first, and waits in combat (0.9.3) |

- **`TargetUnit`** (which patch 1.15.8 made fire `ADDON_ACTION_FORBIDDEN` from insecure code) is **not** on the allowlist, and nothing calls it. Targeting uses a macro the player clicks (`Core/Assist.lua`), and the Active Targets window uses secure buttons.
- **Other automation** (quest accept and turn-in, gossip, flights, inn binding, trainer, junk selling, auto-equip) uses APIs Blizzard does not flag on 1.15.9. Escort quests are never auto-accepted, rewards are never chosen for you unless you turn that on, and Bind-on-Equip items are never auto-equipped.

### Not found on Classic Era

Nearly all are guarded legacy fallbacks (old gossip, container and options functions), methods of Blizzard frames, or other add-ons' globals. Three need a check in the game because a feature relies on them: `GetPlayerFacing` (the arrow; without it the arrow shows plain coordinates), `GetMacroIndexByName` (the targeting macro) and `GetItemStats` (gear scoring; neither it nor `C_Item.GetItemStats` appears in the Classic Era UI source).

### Forever

The Forever UI source is the modern client's code with a Camelot (Forever) overlay. 21 APIs that Questwarden uses on Classic Era are absent there, including the classic talent functions, `AbandonQuest`, `ConfirmBinder`, the old auction house, some item functions (`GetItemSpell`, `GetItemCooldown`, `IsEquippableItem`), pet training points and crafting. Phase 3 adds Forever adapters in `Compat/Compat.lua` (docs/DATA_GAPS.md).

## In-game verification checklist (Classic Era)

None of these has been done yet. Tick them off on a real 1.15.9 client:

- [ ] The add-on appears in the AddOns list as up to date (interface 11509) and loads with no Lua errors (`/console scriptErrors 1`); `/qw debug errors` is empty.
- [ ] `/qw debug` reports the client as 1.15.9 / 11509 and no target warning.
- [ ] `/qw debug api`: every listed API reports `yes`, or its fallback works. Check `GetPlayerFacing`, `GetMacroIndexByName` and `GetItemStats` especially.
- [ ] Loading the Classic Era build on another client (for example TBC Anniversary with "Load out of date AddOns") prints the wrong-client message and loads no guides.
- [ ] `/qw`, `/questwarden` and `/qwgear` open the right windows; key bindings show under *Questwarden*.
- [ ] Settings → Guide Routing shows *Hardcore character*, and the choice survives `/reload` on that character only.
- [ ] The talent calculator shows 51 points at 60 (simulated mode works without talent data).
- [ ] `/reload` and logout/login keep settings (SavedVariables `QuestwardenDB` / `QuestwardenCharDB`).

The TBCGuide 2.5.6 checklist (automation, markers, binding, hunting routes, active items, corpse arrow) is in [tbcguide/COMPATIBILITY_2.5.6.md](tbcguide/COMPATIBILITY_2.5.6.md). It applies again once Classic Era guides exist (Phase 2).
