# Setup wizard

Each character sets up Questwarden once, in a window of five to seven pages. The first page asks whether the player is new to World of Warcraft, and the pages after it follow the answer (docs/NEW_PLAYERS.md). The code has two parts. The choices, validation, saving and route start are in `addon/Core/Setup.lua`. The window is `addon/UI/Welcome.lua`.

## When it shows

- **New characters.** The window opens by itself about two seconds after login. In combat, it waits until combat ends.
- **Saved per character** (`ns.char.setup`). Reloads, logouts and updates do not restart a finished setup.
- **Set Up Later, the close button or Escape.** Nothing is applied and setup is not marked done. The window does not open by itself again in that session.
  - A first setup keeps its choices as a draft (`ns.char.setup.draft`) and resumes at the same step next time.
  - Reopen it with `/qw setup` or *Settings → General → Run Setup Again*.
- **Existing characters** are not sent through setup after an update. The first time this version sees a character, any of these marks it as already set up (`legacy`): an active guide, guide progress, a leveling mode, a talent plan or a gear profile.
  - Such a character keeps using its settings profile for dungeons and group quests until it runs setup.
  - A character that had an unfinished setup draft from 0.1.0-alpha.2 resumes that draft.
- **Opening the window changes nothing.** The guide a new character gets at login (*Pick a guide on first login*) is the existing default, not a wizard choice.

The wizard does not ask for anything the game already reports: name, race, class, faction, level, game version, or whether this is a Hardcore realm.

## Steps

The window has a progress line, *Back*, *Next*, *Set Up Later* and, on the last step, *Finish Setup*. *Next* checks the current step first and explains what is missing. *Back* never loses a choice.

### Welcome

"Is this your first time playing World of Warcraft?" *Next* needs an answer. Saved as `ns.char.newPlayer` at *Finish Setup*.
- **Yes:** Welcome, Route, Talents, Dungeons, Helpers, Review. Route has no mode choice (Speed, the recommended guide) and plain wording. Talents first asks whether they want to tank, heal or deal damage (or don't know) and suggests a plan for it; no gear profile (it follows the plan), and the question whether to equip upgrades automatically (off unless ticked; not offered when the plan's tree has no gear profile). Dungeons explains them and suggests the dungeons the guides have quests for, all picked on a first setup. Options keep their defaults. Details: docs/NEW_PLAYERS.md.
- **No:** every page below, then Helpers and Review.

### 1. Route

**Leveling mode:**

| Choice | Effect |
|---|---|
| *Speed* (default) | Follows the leveling guides for the race and class. |
| *Completionist* | Every eligible quest, lowest level first, zone by zone (docs/COMPLETIONIST.md). |

- **Unavailable modes are greyed out with the reason.**
  - Completionist needs a verified game version, the game's quest-completion flags and the zone geography table.
  - Speed needs a guide for the race and class.
- **No silent fallback.** An unavailable mode is never replaced by the other one.

**Starting guide:**
- In Speed, this is the guide to load. In Completionist, it is the guide to return to.
- It defaults to the recommended guide for the character's level and zone (`Core/Selector.lua`).
- A guide keeps its saved progress, and quests already turned in count as done. A character above level 1 does not replay anything.

**Hardcore route** (Classic Era only). This is the character's Hardcore route flavor (`ns.char.hardcore`). It is always on, and locked, on a Hardcore realm.

### 2. Talents

**Talent plan:** the plans for the class in this game version, plus *No talent guidance*.
- **Where the plans come from:** `Talents/Builds` for that target. Classic Era and TBC have separate plans, even for specs with the same name.
- **What a plan drives:** the level-up reminder, the talent-window markers and the calculator.
- **Choosing a plan never changes your talents.** It never spends points or respecs. The step shows your current points separately.
- **Any level:** plans can be chosen before level 10.
- **No talent guidance** (`ns.char.noTalentPlan`) turns off plan picks in reminders and the talent window. The unspent-points reminder stays.

**Gear profile:** gear scoring for tooltips, quest rewards and bag markers.
- By default it follows the plan's talent tree: the spec profile for that tree (leveling first, then pre-raid, then raid; a tank profile only when a new player chose to tank), or *Automatic* when the class has no profile for that tree. A spec profile is what automatic upgrades need.
- Choosing a profile yourself keeps it.
- The review warns when the profile and the plan are for different trees.

**Role:** there is no role choice. Nothing in the add-on uses a dungeon role, and a talent plan is not treated as one.

### 3. Dungeons

**Speed:**

| Choice | Effect |
|---|---|
| *Questing only* | No dungeon quests are routed. |
| *Include selected dungeons* | The guides' dungeon quests for the picked dungeons are routed, where the guides place them, lead-ins and chains included. |

- **The dungeon list:** your faction's dungeons, each with its usual levels, its quest count in your guides and a status: *right for your level*, *planned for later*, *above its usual levels* or *no quests in the guides*.
  - Dungeons with no guide quests are greyed out and cannot be picked.
  - Dungeons above your level can be picked for later.
- **Buttons:** *Select All Supported* and *Clear Selection*.
- **Validation:** with *Include selected dungeons*, at least one dungeon must be picked. *Use Questing Only* switches back.
- **Picks are kept** while *Questing only* is chosen.

**Completionist:** routes the quests of **every** dungeon, so this step shows information only. The Speed selection is kept for Speed.

### 4. Options

- **Route group and elite quests.** Steps marked `[elite]` in Speed; quests with an elite target in Completionist.
- **Completionist only:** raid, profession, reputation, event/seasonal and repeatable quests. Each is off by default: counted, not routed.
- **Class training:** *Suggest important spells* (default), *Suggest all spells* or *Off*, saved for the character (docs/TRAINER.md). Built in; What's Training? does not need to be installed.
- **Learn recommended spells automatically** (opt-in, off by default): at your class trainer, the listed ranks you can afford are learned. Spends gold; one summary chat line per trainer visit; hold Shift to skip. Settings → *Automatic Training* also offers "everything I can afford".
- **Automatic upgrades.** Off unless ticked, and only with a gear profile. This one switch is part of the settings profile, not the character.

### Helpers

The new-player helpers (docs/NEW_PLAYERS.md), all unticked unless already on, with *Turn On All* and *Turn Off All*. They are profile settings; *Play together* also turns on *Enable Group Settings*. *Mount savings goal* is only offered where there are mount prices.

### 5. Review

The review shows:
- **Character and game version.**
- **Route:** the mode and guide, plus Hardcore on Classic Era.
- **Talent plan** and **gear profile.**
- **Dungeons** and **group quests.**
- **Completionist categories** and **automatic upgrades.**
- **New to World of Warcraft** (once answered) and the **helpers** turned on.
- **Notes:** coverage limits, replaced saved values, a gear profile that doesn't match the plan.
- **Anything that still blocks finishing.**

## Finish Setup

What happens, in order:
1. The whole draft is checked again.
2. A snapshot of everything Finish may change is taken.
3. The choices are written:
   - mode and guide (`ns.char.mode`, `activeGuide`, `speedGuide`);
   - `ns.char.hardcore`;
   - talent plan (`talentBuild`, `noTalentPlan`) and `gearProfile`;
   - the Completionist categories;
   - `ns.char.routing`;
   - the profile's `autoEquip`;
   - `ns.char.newPlayer` and the helper settings in the profile.
4. The route starts. Speed loads the guide with its progress; Completionist plans its first segment.
5. Only then is setup marked done, with its version.

**If any step fails:**
- Everything from the snapshot is put back and the error is shown.
- The draft stays and setup stays unfinished, so the player can correct and retry.

**Run Setup Again** starts from the current choices. Nothing changes until *Finish Setup*, and *Set Up Later* cancels it.

Changing the mode or guide never touches quest history or guide progress. Each Speed guide keeps its own progress.

## Dungeon routing rules

**Speed (Core/Engine.lua):**
- **A dungeon quest in your log** whose dungeon is not selected, or whose run (`complete` step) you skipped, is set aside: its objective and turn-in steps are *skipped* with a reason.
  - Nothing is marked complete.
  - The turn-in comes back by itself once the quest log says the quest is complete.
  - Questing goes on in the meantime.
- **Deselecting a dungeon** removes its pickups and runs from the route right away.
- **A follow-up quest** that needs an excluded dungeon quest is skipped, as before (docs/DUNGEONS.md).

**Completionist (Core/Completionist.lua):**
- **Every dungeon's quests are routed.** They are picked up from the dungeon's usual level (`Database/Dungeons.lua`), not earlier, so they do not fill the log.
- **Open dungeon quests** become one run step per dungeon: find a group, arrow to the entrance, done when you enter (docs/DUNGEONS.md). Skipping it keeps you questing; it comes back in later segments.
- **Turn-ins** are planned only once a quest is complete.

## Saved data

| Field | Contents |
|---|---|
| `ns.char.setup` | `version` (1), `done`, `legacy`, `draft`, `at`, `lastError` |
| `ns.char.routing` | `dungeons` (`"questing"` or `"selected"`), `selected` (`{ [dungeon] = true }`), `elite` |
| `ns.char.noTalentPlan` | `true` when *No talent guidance* is chosen |
| `ns.char.newPlayer` | the answer to the first page: `true`, `false`, or absent before it was answered |

- **Identifiers.** Dungeons are identified by their name in `Database/Dungeons.lua`. That is the same string the guides' `[dungeon=...]` tags use, from the bundled data rather than the client's language. Guides and plans are identified by their ids.
- **Repairs:**
  - A wrong-typed `setup` or `routing` record is dropped at load (`Core/SavedVars.lua`).
  - A damaged routing record is repaired to safe values: questing only, no group quests.
- **Replaced on load, each with a note on the review screen:**
  - a removed guide;
  - another class's plan, or a plan not in this game version;
  - an unknown dungeon name.

The old `setupDone` / `setupDraft` fields from 0.1.0-alpha.2 are moved into `ns.char.setup`.

Characters with a routing record use it for *Include Dungeon Quests*, the dungeon switches and *Show Group Quests*, wherever they are changed: the settings window, the Interface options panel or `/qw set`. Characters without one use the settings profile, as before.

## Commands

- `/qw setup`: opens the wizard. It resumes an unfinished setup; after setup, it runs it again from the current choices.
- `/qw setup status`: shows whether setup is done and the current choices.

## Tests

- **`tests/test_setup.lua`** (TBC fixture) covers:
  - first-time display, the first page's question, Back/Next, Set Up Later, the same-session rule and resume after reload;
  - invalid choices, a failed route start and Finish;
  - separate characters, Standard and Completionist activation, an unavailable mode, mid-level reconciliation;
  - plans by class, *No talent guidance*, learned talents unchanged;
  - questing only, selected and future dungeons, run deferral and deselection;
  - legacy, alpha.2 and corrupt saved data, re-run prefill, cancel, quest history.
- **`tests/test_completionist.lua`:** dungeon level gating, run steps and turn-ins.
- **`tests/test_new_players.lua`:** the new-player path, the helpers page, a failed finish putting the helpers back.
- **`tests/run_smoke.lua`:** Classic Era defaults, plans, dungeon counts and the Hardcore choice.

These are headless tests against a mock client. The window layout has not been checked in the game client.
