# Help for new players

Questwarden can help players who have never played World of Warcraft. Every helper below is **off by default**. The setup wizard asks on its first page whether the player is new and offers the helpers on its *Helpers* page; they are also in the settings window. None of them does anything for you: they add tips and hints. The tips of the first three helpers below open in a small window (see *Tip window*).

None of this has been tested in the game client yet.

## Setup wizard

The first page asks **"Is this your first time playing World of Warcraft?"** (`ns.char.newPlayer`). The pages after it follow the answer (`Setup.PATHS` in `addon/Core/Setup.lua`):

| Answer | Pages |
|---|---|
| Yes | Welcome, Route, Talents, Dungeons, Helpers, Review |
| No | Welcome, Route, Talents, Dungeons, Options, Helpers, Review |

For new players:
- **Route:** no leveling-mode choice; they follow the leveling guides (Speed) from the recommended guide. The Hardcore switch is explained in plain words. Where there is no Speed guide for the character, the normal route page is shown.
- **Talents:** first "What would you like to do in a group?": *Tank*, *Heal*, *Deal damage* or *I don't know yet* (`Setup.ROLES`; *Next* needs an answer). The answer picks the suggested plan (`Setup:SuggestedPlan`): the class default plan when it fits the role (it is the spec the class's leveling advice in `Classes/ClassAdvice.lua` names, and its summary is shown), else the first plan of that role. When the class has no plan for the role (for example a Mage who wants to heal), the class default is suggested and the page says another class can do that. All plans stay listed with their role in plain words. The gear profile follows the plan and is not asked. Last on the page: *Put on better gear automatically?* (automatic upgrades, off unless ticked; greyed out when the plan's tree has no gear profile).
- **Dungeons:** what dungeons are and how a dungeon step works (find a group; skip the step to keep questing). *Include the recommended dungeons* (suggested) or *Questing only*. Recommended = the dungeons the leveling guides have quests for; on a first setup they are all picked, so new players learn to run dungeons. Each can be unticked. A re-run keeps the saved choice.
- **No Options page.** Class training, automatic training and upgrades keep their defaults.
- **Helpers:** each helper with one line on what it does, plus *Turn On All* and *Turn Off All*. All start unticked.

Experienced players get the same Helpers page at the end. Running setup again starts from the saved answer.

## The helpers

| Setting | Where in the settings | What it does |
|---|---|---|
| `newPlayerTips` | Tips → New Players | The first time each kind of step comes up (pick up, kill, turn in, fly, train, hearth...), a tip says what to do and which key opens what. Also: the useful keys (read from your key bindings), full bags (2 free slots or fewer, at most every 10 minutes), your first death, and talent points at level 10. Each explanation shows once per character (`ns.char.explained`); `/qw newplayer reset` shows them again. |
| `spellCoach` | Tips → New Players | When you learn a spell: its name and the first sentence of the game's own description, then whether it is on your action bars. If not: open the spellbook and drag it there ("unless it is passive", since the game does not say which spells are passive). Every 4 levels from 4: a leveling tip for your class (`Classes/ClassAdvice.lua`), the first not shown yet whose level you have reached. A tip's level is the first one it names, such as *Overpower (12)* or *at 10*, so a tip never talks about a spell you can't learn yet. |
| `professionTips` | Tips → New Players | Once per character, at level 5: which professions suit a new character and the profession trainers in your zone. `/qw professions` lists the nearest trainers; `/qw professions mining` points the arrow at one. |
| `mountGoal` | Tips → New Players | From 10 levels before the riding level until you can ride (or 5 levels after it on Classic Era): the price of your first mount against your gold, under the current step, and a chat line at each level-up. Paladins and Warlocks are told to see their class trainer. `/qw mount` shows it any time. Not on Forever (no prices). |
| `sessionRecap` | Tips → New Players | At login, one chat line about your last session (if it lasted 2 minutes or more): play time, levels, experience, quests turned in, zones, deaths and gold. `/qw recap` shows this session so far. The counts are kept for every session. |
| `playTogether` | Communications → Play Together | Needs *Enable Group Settings* (the wizard turns it on with this). Party members running Questwarden with this switch on send their guide and step to the party (hidden add-on messages, about once a minute and when the step changes). Under your current step: where each one is ("on this step too", "2 steps ahead", "on another guide"), and **Wait for <name>** when they are behind on a pick-up, turn-in, flight or hearth step. Never in raids. |
| `playFollowLeader` | Communications → Play Together | Your guide goes to the party leader's guide and step whenever theirs changes. Going back keeps your progress; going forward marks the steps in between *skipped* (not completed; `/qw prev` reopens them). `/qw follow` does it once. |
| `tipWindows` | Tips → New Players | **On by default.** The tips of `newPlayerTips`, `spellCoach` and `professionTips` open in a small window (`addon/UI/TipWindow.lua`) with an **OK** button, one at a time; OK (or Escape) shows the next, and the button says how many more are waiting. Tips that come during a fight wait until it ends. The window can be dragged and keeps its place. Off: the tips go to chat, and any still waiting are printed there. The other helpers stay in chat or the guide window. |
| `simpleSettings` | General | The settings window hides the Advanced Settings and Profiles tabs and options flagged as rarely needed (`more = true` in `addon/UI/ConfigOptions.lua`). Hidden options keep working as they are set. |

## Data and game functions

- **Mount prices** (`targets/<Target>/addon/Database/Riding.lua`): Warcraft Tavern's mount guides, read 2026-11-01, approved as a source by the project owner. Classic Era: riding at 40, 20 gold training and 80 gold mount. TBC: Apprentice Riding at 30, 35 gold, and a 10 gold mount. Only these facts were taken. Class mount prices come from the What's Training? data.
- **Game functions** added for spell coaching (approved 2026-11-01): `HasAction`, `GetActionInfo`, `GetSpellDescription`. All are guarded: without them the lines are shorter, never an error.
- **Profession trainers** come from the bundled NPC data by their English sub-name, as the class trainer search does.

## Code

- `addon/Core/NewPlayer.lua`, `addon/UI/TipWindow.lua`, `addon/Classes/SpellCoach.lua`, `addon/Core/ProfessionTips.lua`, `addon/Core/MountGoal.lua`, `addon/Core/SessionRecap.lua`, `addon/Core/PlayTogether.lua` (messages through `ns.Group:Handle` / `ns.Group:Send`, tag `P`).
- The simple view: `CF:Simple`, `CF:VisibleTabs`, `CF:LayoutTabs` and `CF:Rebuild` in `addon/UI/Config.lua`.
- Tests: `tests/test_new_players.lua` (every helper on and off, the tip window and its queue, the simple view, both wizard paths) and `tests/test_setup.lua`.
