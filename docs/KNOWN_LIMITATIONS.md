# Known limitations

Stated plainly, so nobody mistakes "files exist" for "finished and tested". This is 0.1.0 in development, after Phase 1.

## Not done yet

- **No Classic Era content.** There are no guides, quest data, talent trees, trainer spells, class tips, talent builds or gear profiles for Classic Era yet. The add-on loads and its windows work, but they are empty. All of this is Phase 2 (docs/DATA_GAPS.md).
- **No Hardcore route flavor yet.** The *Hardcore character* setting exists and is saved per character, but no guide uses it until the Phase 2 guides have Hardcore marks.
- **Hardcore realms are not detected.** Detection needs `C_GameRules.IsHardcoreActive`, which is not on the API allowlist yet.
- **Season of Discovery is not supported or detected.** Out of scope.
- **WoW: Forever is a skeleton.** Its rules are unverified, its data is empty, and the add-on refuses to load guides on it. 21 APIs the add-on uses on Classic Era are missing from the Forever client's UI code, so talents, orphan abandoning, hearth binding, the auction tab, parts of gear scoring and pet skills need adapters there (Phase 3).
- **Route audit XP model:** for Classic Era the audit estimates levels by interpolation between guide checkpoints; the TBC XP model is not used for it, and the Classic XP tables are Phase 2.
- **Data importers** (`import-questie`, `import-client`) still read the TBC upstream files. They write to the chosen target's folder, but must not be run for Classic Era until Phase 2 makes them target-aware.

## Testing

- **Nothing in ClassicGuide has been run in the game client.** Everything is checked offline: Lua 5.1 lint, the guide compiler, the validator, the route audit, the build-tool self-test (21 checks), the full engine suite on the TBC fixture (4,420 checks) and the smoke suites on the Classic Era (33) and Forever (29) targets, all under a real Lua 5.1 interpreter with mocked client APIs. The mocks model the APIs as documented; the real client may differ. Checklist: docs/COMPATIBILITY.md.
- **API availability on 1.15.9** comes from Blizzard's UI source, not from the client. 35 audited names were not found there (docs/generated/ClassicEra/api-audit.md); the call sites are guarded, but `GetPlayerFacing` (arrow), `GetMacroIndexByName` (targeting macro) and `GetItemStats` (gear scoring) need a check in the game.
- **32 APIs reached by name through `Compat.has` are not on the API allowlist** (inherited from TBCGuide; lint warns about them). They wait for review.

## Carried over from TBCGuide

The engine is TBCGuide 0.9.5's. Its limitations apply once Classic Era data exists, and are listed in [tbcguide/KNOWN_LIMITATIONS_0.9.5.md](tbcguide/KNOWN_LIMITATIONS_0.9.5.md): conservative escort detection, old-style greeting windows, grey-only junk selling, raid-marker rules, steps without a navigation target, alternative prerequisite chains, and the untested talent-window and bag add-on integrations.
