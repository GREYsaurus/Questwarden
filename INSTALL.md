# Installing ClassicGuide

> 0.1.0 is in development and has **no guides yet** (Phase 1). These steps are for testing builds.

## Players (WoW Classic Era)

1. Download `ClassicGuide-<version>-ClassicEra.zip` from the GitHub **Releases** page, or build it yourself (it lands in `dist/`). The zip already contains the right folder. Do **not** copy the repository's `addon/` folder: it is not a complete add-on until the build has staged it.
2. Close World of Warcraft.
3. Extract the zip so that this file exists:
   ```
   World of Warcraft\_classic_era_\Interface\AddOns\ClassicGuide\ClassicGuide.toc
   ```
   Create `Interface\AddOns` if it does not exist yet. The folder must be named exactly `ClassicGuide`.
4. Start the game. On the character screen, open **AddOns** and make sure **ClassicGuide** is enabled.
5. Log in. Type `/cg help` for commands, and `/cg debug` to see which client the build was made for.

Optional: install **TomTom** for its waypoint arrow as well as the built-in one.

**World of Warcraft: Forever:** there is no Forever build yet. The Forever AddOns folder will be confirmed after launch (2026-11-04). The Classic Era build will not load guides on a Forever client: it says so at login.

### Upgrading

Delete the old `Interface\AddOns\ClassicGuide` folder before extracting the new one. Settings and progress are stored separately in `WTF\Account\<account>\SavedVariables\ClassicGuide.lua` and `...\<realm>\<character>\SavedVariables\ClassicGuide.lua`, so they survive upgrades.

### Uninstalling

Delete `Interface\AddOns\ClassicGuide`. You can also delete the `ClassicGuide.lua` files under `WTF` to remove saved settings.

## Building from source (Windows)

Requirements: Windows PowerShell 5.1+ (built into Windows 10/11); the build tools are C# compiled on the fly by PowerShell. For the tests: a Lua 5.1 interpreter (`lua5.1`) or Python with the `lupa` package (`python -m pip install lupa`).

```bash
powershell -ExecutionPolicy Bypass -File tools/build.ps1 all
```

This stages the Classic Era add-on in `build/ClassicEra/ClassicGuide/`, compiles the guides, lints all Lua, validates the content, runs the route audit and the tests, writes reports to `docs/generated/ClassicEra/`, and produces:

- `dist/ClassicGuide-<version>-ClassicEra.zip`: the installable add-on (licence and notices included)
- `dist/ClassicGuide-<version>-source.zip`: the corresponding source (shared code, all targets, tools, tests, docs)

For development, point the game at the staged folder instead of copying zips: run `tools/build.ps1 stage`, then copy (or link) `build\ClassicEra\ClassicGuide` into `Interface\AddOns`.

Other targets: `-Target Forever` (skeleton, never packaged) and `-Target TBC` (test fixture, never packaged). The data import steps (`fetch`, `import-questie`, `import-client`) only run when refreshing upstream data: docs/DATA_PIPELINE.md.
