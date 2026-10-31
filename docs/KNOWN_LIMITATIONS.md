# Known limitations

Stated plainly, so nobody mistakes "files exist" for "finished and tested". This is 0.1.0 in development, after Phase 1.

## Not done yet

- **Classic Era content is partial (Phase 2 in progress).** The quest database, talent trees, trainer and pet data exist. Guides exist only for Human (Elwynn) and Orc/Troll (Durotar) from 1 to 12. Other races, levels 12-60, class tips, talent builds and gear profiles come next (docs/DATA_GAPS.md).
- **Hardcore route flavor:** the 1-12 routes carry Hardcore marks (`[hc=skip]`, `[hc=only]` warnings), chosen from NPC levels and ranks in the data. They are judgement, not play-tested.
- **Hardcore realms are not detected.** Detection needs `C_GameRules.IsHardcoreActive`, which is not on the API allowlist yet.
- **Season of Discovery is not supported or detected.** Out of scope.
- **WoW: Forever is a skeleton.** Its rules are unverified, its data is empty, and the add-on refuses to load guides on it. 21 APIs the add-on uses on Classic Era are missing from the Forever client's UI code, so talents, orphan abandoning, hearth binding, the auction tab, parts of gear scoring and pet skills need adapters there (Phase 3).
- **Route audit XP model:** for Classic Era the audit estimates levels by interpolation between guide checkpoints; the TBC XP model is not used for it, and the Classic XP tables are Phase 2.

## Testing

- **Nothing in Questwarden has been run in the game client.** Everything is checked offline: Lua 5.1 lint, the guide compiler, the validator, the route audit, the build-tool self-test (21 checks), the full engine suite on the TBC fixture (4,420 checks) and the smoke suites on the Classic Era (33) and Forever (29) targets, all under a real Lua 5.1 interpreter with mocked client APIs. The mocks model the APIs as documented; the real client may differ. Checklist: docs/COMPATIBILITY.md.
- **API availability on 1.15.9** comes from Blizzard's UI source, not from the client. 35 audited names were not found there (docs/generated/ClassicEra/api-audit.md); the call sites are guarded, but `GetPlayerFacing` (arrow), `GetMacroIndexByName` (targeting macro) and `GetItemStats` (gear scoring) need a check in the game.
- **32 APIs reached by name through `Compat.has` are not on the API allowlist** (inherited from TBCGuide; lint warns about them). They wait for review.

## Carried over from TBCGuide

The engine is TBCGuide 0.9.5's. Its limitations apply once Classic Era data exists, and are listed in [tbcguide/KNOWN_LIMITATIONS_0.9.5.md](tbcguide/KNOWN_LIMITATIONS_0.9.5.md): conservative escort detection, old-style greeting windows, grey-only junk selling, raid-marker rules, steps without a navigation target, alternative prerequisite chains, and the untested talent-window and bag add-on integrations.
