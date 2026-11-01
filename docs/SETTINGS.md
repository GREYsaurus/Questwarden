# Settings window

`/qw options`, or left-click the minimap button, opens the Questwarden settings window. It has one row of tabs: **General, Guide Routing, Targeting, Leveling Tracker, Communications, Tips, Advanced Settings, Profiles, Help**. Escape closes it. Changes apply immediately and are saved in your current profile.

Under the title bar are five buttons:
- **Guide Browser** opens the guide browser.
- **Talent Guide** opens the talent guide.
- **Leveling Report** shows time per level and XP per hour.
- **Report an Issue** shows a link to copy.
- **Choose the Best Guide for Me** loads the guide that fits your race, class and level.

Every option in the window works; none is a greyed-out placeholder.

None of this has been tested in the game client yet.

**Look:** every Questwarden window shares one flat dark style with a blue accent. The colours are in one table, `W.THEME` in `addon/UI/Widgets.lua`.

## What each tab controls

### General
- **Setup wizard** (docs/SETUP.md): a new character gets a five-step setup: route and leveling mode, talent plan and gear profile, dungeons, options (group quests, Completionist categories, automatic upgrades), review. Saved per character; nothing applies before *Finish Setup*. *Set Up Later* keeps the draft and does not finish setup. *Run Setup Again* (General) or `/qw setup` reopens it from the current choices. Characters that already used Questwarden are not asked.
- **Window Management:** *Show all Enabled Frames* hides the guide window and arrow together when off. *Lock Frames* and *Autohide in Raids* do what they say.
- **Features:** minimap button, world map button (opens the guide browser), *Hide Window* and *Hide waypoint arrow*.
- **Automatically Navigate to Corpse** (on): after you release your spirit, the arrow points to your corpse until you are alive again, then returns to the guide. It uses the game's own corpse position and asks the map you died on, then your current map and its parents, without opening or changing the map. No position means no arrow (never a guessed one). After a death inside a dungeon the arrow points to that dungeon's entrance (docs/DUNGEONS.md, "Dungeon runs"). Inside raids and battlegrounds, or a dungeon without an entrance in the data, there is no outdoor position: you get a note, not an arrow. `/qw corpse off` hands the arrow back to the guide; `/qw corpse on` brings it back.
- **Roaming Waypoints for Kill Objectives** (on): cycles through verified hunting-area waypoints until the objective is complete. The points cover where the mobs are known to spawn, not where they are now. Only quests with a verified route use it; the others keep their normal waypoint. *Next patrol point* moves the arrow to the next point (also `/qw route next` and a key binding); *Normal objective waypoint* turns the route off for the current step (`/qw route off`, back with `/qw route on`). Details: docs/ROAMING.md.
- **Follow Patrolling NPCs** (on): when a step needs an NPC that walks a known path (a quest giver, a turn-in NPC or a named mob with at most 2 spawns), the arrow goes to the nearer end of the path and then along it until the step is done. The path is dotted on the world map and minimap. The path data comes from QuestieDB and shows where the NPC walks, not where it is now. Details: docs/PATROLS.md.
- **Automation:**

  | Option | Default | What it does |
  |---|---|---|
  | Quest auto accept/turn in | on | Guide quests only. More options: `/qw automation` |
  | Quest auto rewards | off | Takes a reward only when gear scoring shows one clear upgrade, or when your class can use none of them (then the most valuable). Otherwise you choose |
  | Class Trainer Suggestions | Important only | Off / Important only / All: what your trainer has for you, checked against your spellbook; train steps with nothing new are skipped. Never buys (docs/TRAINER.md) |
  | Automatic Training | Off | Per character, also in the setup wizard (opt-in). *Recommended spells*: when you open your class trainer, learns the ranks the suggestions list for you that you can afford; *Everything I can afford*: all of them. Spends gold, one summary chat line when you close the trainer, hold Shift to skip. Characters that had the old *Trainer automation* switch on keep "everything" until they choose |
  | Flight Path automation | on | On a "fly to" step, takes that flight when the flight map opens |
  | Innkeeper Bind automation | on | On a "set your hearthstone" step, when you talk to that town's innkeeper: picks the bind option, confirms it only if the game names the step's inn, and completes the step once the game reports the new home. Never at other inns. Hold Shift to skip |
  | Skip Gossip | on | Picks the only option when an NPC has one option and no quests (never a bind option outside a bind step) |

  Hold **Shift** while talking to an NPC to skip all of these once.
- **Inventory:**
  - *Enable Inventory Manager* is the master switch for everything below it.
  - *Toggle junk with modified right click*: modifier + right-click a bag item adds it to, or removes it from, your junk list. You pick the modifier.
  - *Auto Sell Junk*.
  - *Discard junk if bag is full* (off by default): when your bags are full, the junk item worth least at a vendor is destroyed (gone, not sold) on your next click in the game world, key press or loot-window click. One item per click or key press; there is no confirmation.
    - **Why it waits for your input:** WoW only lets add-ons destroy an item during a click or key press, one item each time (`DeleteCursorItem` needs a hardware event on every Classic-engine client, TBC 2.5 included). Questwarden listens to your own clicks and key presses (key presses still reach the game as normal); it never simulates input.
    - **Checks before each item:** each attempt re-reads the bag slot (same item, same stack, not locked) and re-checks the junk rules: grey or on your junk list; never quest, quest-starting, guide-needed or protected items; never items whose data is not loaded.
    - **When it waits:** in combat, with something on the cursor, or with a merchant, trade, bank, mail or auction window open, the item stays chosen and is destroyed on your first input after that.
    - **Failures:** a failed item is not tried again this session.
    - **Feedback:** "Destroyed (not sold)" is printed only after the bags confirm it.
  - *Delete Cheapest Junk Item Keybind* (click, then press a key; right-click unbinds): the same destroy-one-item action from the keyboard, with the same checks.
  - *Reset Junk List*.
  - Junk means grey items plus your junk list. Quest, quest-starting, guide-needed and protected items are never sold or deleted, and nothing is deleted in combat.
- **Features:**
  - *Hide Active Item window* (off by default): buttons for usable quest items in your bags. Click one to use the item. They update after combat, because secure buttons can't change in combat.
  - *Enable Vendor Treasures* (on): when a merchant opens, lists and marks items it sells that are upgrades for your spec profile, the same estimate as automatic upgrades. Needs a spec profile.
  - *Show Flight Timers* (on): a bar with the time left on a flight. Questwarden ships no flight data, so each route is timed the first time you fly it and counts down after that.
  - *Enable Group Settings* (off): master switch for the party features on the Communications tab and the leader's target on the Targeting tab.
- **Window:**
  - *Guide Window Scale* (60-160%);
  - *Guide Font Size* (9-18);
  - *Arrow Scale* (50-200%).

  These apply as you drag, and the window and arrow stay where they are on screen. *Reset Window Settings* puts just these three back to their defaults.
- **Inventory:** *Show junk item indicator* (off) puts a coin on bag items the inventory manager would sell.
- **Talents:**
  - *Show Talent Suggestions* (on): markers, a panel and tooltip lines in the default talent window for your spec profile's plan. Never spends points (docs/tbcguide/TALENTS.md).
  - *Enable Talents Guides* turns on the chat reminders to spend talent points.
  - *Enable Talent Plan* and *Talent Plan Number* add your build's next picks to those reminders. `/qw talents plan` shows them any time.

### Guide Routing
- **Leveling mode** (per character): *Speed* (the leveling guides, default) or *Completionist* (every eligible quest, lowest level first, zone by zone, with return visits; docs/COMPLETIONIST.md). Also chosen in first-time setup. *Completionist status* prints progress; *Plan next Completionist segment* replans now.
- *Completionist: route dungeon / group and elite / raid / profession / reputation / event quests* (all off): these quests are always counted, and routed only when switched on.
- *Skip overleveled steps* (on) skips picking up quests that are grey for your level, unless a later quest in the guide needs them.
- *Show Group Quests*, *Maximum-speed route*, *Advance steps automatically* and *Pick a guide on first login*.
- **Include Dungeon Quests** (on by default). Off leaves out every step tagged as a dungeon quest: its pickup, objective and turn-in. After setup this, the dungeon switches and *Show Group Quests* are saved for the character (docs/SETUP.md).
  - **Follow-ups** that need an excluded dungeon quest are skipped too, with the reason shown, and the guide continues with the next step.
  - **Already in your log:** a dungeon quest you have already accepted keeps its steps, and Questwarden never abandons quests.
  - **Applies immediately,** and turning it back on restores the steps without touching your progress.
  - **Tagged today:** only Horde Ashenvale *Amongst the Ruins* (Blackfathom Deeps), because it's the only guide quest that needs an instance.
- **Single dungeons:** one switch per dungeon of your faction. A dungeon marked * has quests in the guides; today that's only Blackfathom Deeps.
  - **Select Recommended Dungeons** keeps the ones you haven't outleveled that start at most 8 levels above you.
  - **Select all Dungeons** turns them all back on.
  - Level ranges are the usual approximate ones (`addon/Database/Dungeons.lua`).

### Targeting
- *Enable Targeting* turns raid markers on or off.
- *Maximize Nameplate Distance* sets the game's nameplate distance to 41 yards and restores your old value when turned off.
- **Target Markers:**
  - *Mark Enemy Targets*: guide `[mark]` NPCs.
  - *Mark Enemy Mobs*: kill objectives.
  - *Mark Friendly Targets*: the quest giver or finisher.
  - *Enable Target Markers (Group)*.
  - Replace and clear options, and the default marker. See [RAID_MARKERS.md](RAID_MARKERS.md).
- **Targeting Macro:**
  - *Create Targeting Macro* keeps a "Questwarden" macro with `/tar` lines for the current step's NPCs. Drag it to an action bar from the Macros window, General tab. It's never edited in combat.
  - *Mark with the Targeting Macro* (off): each press of that macro also marks the nearest visible mob of each kind, instead of the automatic marking. Automatic marking (the default) moves icons to the mob you target or mouse over, and on to the next visible mob when one dies or leaves your view (docs/RAID_MARKERS.md).
  - *Notify on new target* prints one chat line when a current-step NPC first comes into view.
- **Raid Marker Bar:** shows or hides the marker bar.
- **Active Target Frame:** click-to-target buttons (`/tar <name>`) for the current step's NPCs.
  - **Who:** enemies in red, quest givers and finishers in green.
  - **Party leader:** *Follow Party Leader Target* adds your party leader's target. It needs *Enable Group Settings*.
  - **Look:** background on or off, scale, and *Reset Window Position*.
  - **Combat:** it updates after combat.

### Leveling Tracker
- **What it tracks:** how long each level takes, using played time from the server (asked for quietly at login), and your XP per hour this session.
  - Levels finished before this version show as `-`.
- **Leveling report:** `/qw tracker` or the button at the top of the window. It shows:
  - the current level's time;
  - XP per hour, and an estimate of when you'll level;
  - total played time;
  - your average time per level.

  *Always Open Leveling Report With Character Panel* opens it with the character window.
- **Level Splits:** a small window with the time each recent level took.
  - *History* sets how many levels it shows.
  - *Compare Next Level* compares the running level with the previous one.
  - Also: total time, font size, opacity and hiding the background.

### Communications
- **Enable Addon Version Checks** (on): tells you once when a group or guild member runs a newer Questwarden.
  - Uses hidden add-on messages; nothing appears in chat.
  - It's also how Questwarden knows which party members use it.
- **Level-up announcements** to emote, party or guild chat. All are off by default.
- **Party announcements** (all off by default, and all need *Enable Group Settings*):
  - *Announce Step completion*: a guide quest's objectives are all done.
  - *Announce Step collection*: progress, such as *Wolf Meat: 3/8*.
  - *Announce Step flying timers*: you took a flight, with the arrival time once the route is known.
  - *Don't announce when Questie is loaded*: avoids double messages, since Questie can announce progress itself.
  - **Never in raids.** They are only sent when another party member runs Questwarden, unless *Send announcements without another Questwarden user in group* is on.
- *Automatic quest sharing*: shares a guide quest with your party right after you accept it.

### Tips
- **Drowning:** warning, sound, threshold, screen-edge flash.
- **Emergency Actions:** low-health warning, threshold, sound, flash.
- **Rare mobs:** *Track Rare Mobs* gives a chat alert and sound when a rare's nameplate appears (rares from the bundled database: on Classic Era, every rare hostile to your faction). It can skip rares this character already killed.
- **Map pins:** both come from the bundled data. On Classic Era it has every hostile elite and rare with spawns; on other targets, only quest NPCs and mobs. Rares are listed first, and patrolling mobs say so in their tooltip.
  - *Track Mobs on Map*: world map pins for elite and rare mobs in the zone shown.
  - *Track Treasures*: pins for treasure chests.
  - *Track Spirit Healers* (off by default): pins for the spirit healers, one per graveyard, where you appear as a ghost. On Classic Era from QuestieDB's spirit healer spawns; other targets have none yet.
- **Item Upgrade:**
  - gear scoring switches;
  - the **Spec profile** (per character; your class's profiles only);
  - quest reward recommendation and automation.

  See [GEAR_SCORING.md](GEAR_SCORING.md).
- **Automatic Upgrades** (opt-in): see [AUTO_EQUIP.md](AUTO_EQUIP.md).
  - **Equipping:** *Enable automatic upgrades* asks first and needs a spec profile. Unbound Bind-on-Equip items are never equipped automatically, and no setting changes that.
  - **Other options:**
    - *Fill empty gear slots*;
    - *Minimum upgrade* (%);
    - on-screen and chat equip messages;
    - *Mark Bind-on-Equip upgrades in bags*;
    - *Clear excluded items*.
- **Protected Slots:** one switch per gear slot. Automatic upgrades never change a protected slot.

### Advanced Settings
- *Enable Debug*.
- **Navigation hints** (`Core/NavHints.lua`). The arrow points in a straight line, and Questwarden has no paths through cities or buildings. Instead, the step text (and a short line under the arrow) says when the straight line will mislead you:
  - the target is in a capital city: follow the streets;
  - you are in a capital and the target is outside it: leave the city first;
  - you are indoors (the game's indoor flag) and the target is more than 15 yards away: "find the way out first" only when the target is known to be outside (you stood at it outdoors before); otherwise "the arrow shows only the direction", since the target may be outside or in another room of the same building;
  - the target is inside a building, cave or mine: look for the entrance. This comes from the step's own text when it puts the target inside (*inside*, *upstairs*, or "in"/"into" a cave, mine, inn, tower and so on, or "top of the tower"; a place only named, such as "Echo Ridge Mine is north of the abbey", does not count), shown as "may be inside", or from standing within 5 yards of the target indoors before (remembered for all characters). A spot ever seen outdoors, such as an NPC by a door, never counts as inside.
- *Update Frequency (ms)*: how often the arrow redraws. Under the arrow: the distance and, while you are closing on the waypoint, an estimated time to arrival (from your speed toward it, smoothed).
- *Low Quality Settings*: the arrow redraws at most every 150 ms, and the map shows fewer pins.
- *Pre load all data*: at login, and when you change guide, asks the game for the item data your guide's quests and your bags use, so tooltips and scoring don't wait.
- *Check for Addon Incompatibility*: warns at login when another leveling guide add-on is loaded.
- **Debug section:**
  - *Disable step skips*: nothing is skipped automatically.
  - *Display Lua Errors*: the game's own error pop-up.
  - *Disable Map Pins*.
  - *Show Minimap Waypoint* (on by default): a pin for the current waypoint on the minimap; on the minimap edge while out of range.

### Profiles
- **Profiles hold settings.** Guide progress, talents and junk-sale totals always stay with the character.
- **Current Profile** shows which one this character uses. A **new** profile starts from the defaults.
- **Existing Profiles** switches profile.
- **Copy From** copies another profile's settings into the active one.
- **Delete a Profile** removes one; the active and default profiles cannot be deleted. Characters that used a deleted profile fall back to the default.
- **Reset Profile** restores the defaults.
- **Set current profile as default** makes new characters start with it.
- Settings saved before 0.5.0 become the **Default** profile automatically.
- *Reload guides and UI* and *Reset Guide Progress* (asks first) are at the top.

## Removed

**The Look and Feel tab** is gone. Its settings keep their current values but can no longer be changed in the window:
- text colours;
- guide window scale, font size, steps shown and step list;
- arrow scale;
- map pin (TomTom support was removed in 0.1.0-alpha.6; the minimap pin is next to *Disable Map Pins*).

**Options with nothing to act on in Questwarden** were removed:
- *Detect Rate* and *Experience rates*;
- *Solo Self Found Mode*;
- *Enable Beta Features*;
- *Hearthstone batching* and its window size;
- *Quest Log Size*: the TBC quest log is fixed at 25.

**Removed before 1.0:** three placeholders that were never built:
- *Follow Party Leader Macro*;
- *Quest Sellable Recommendation*;
- *Always Show Total EP*.

Gear scoring itself is unchanged.

**Enable Auctioneer** (Tips → Item Upgrade, on): adds the auction house **Upgrades** tab. See [AUCTION.md](AUCTION.md).
- **Scanning:** you start each scan yourself while the auction house is open.
- **Prices:** they are the cheapest buyouts that scan saw, so old or partial scans may no longer match what's for sale.
- **Never automatic:** nothing is ever bought.
