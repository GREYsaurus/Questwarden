# NOTICE

**Questwarden**: free leveling and talent guide add-on for World of Warcraft Classic Era, prepared for World of Warcraft: Forever. A fork of TBCGuide (https://github.com/GREYsaurus/TBCGuide, same author).

Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus).

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3 (GPL-3.0-only). The complete licence text is in `LICENSE` (identical copy in `COPYING`).

## Third-party material

Releases include data derived from **QuestieDB** (from Phase 2; the 0.1.0 development builds contain none yet) (https://github.com/Questie/QuestieDB), which was imported from **Questie** (https://github.com/Questie/Questie):

- Upstream commit `7901fee2753cecb577a72c2e4b7126198e05baec` (QuestieDB v1.0.9). Dungeon entrance positions (`support/Zones/dungeons.lua`) come from the later commit `8f55e69de02e8a67229c4a54575f899244359cb8`, which added that file.
- Data authors as credited upstream: Muehe, TheCrux (BreakBB), Drejjmit, Dyaxler, Cheeq, TechnoHunter, Yttrium and many other Questie contributors. Code by Logonz.
- Redistributed under the GPLv3 terms the Questie team offers. The upstream licence statement is reproduced verbatim in `Database/Questie/UPSTREAM_LICENSE.md` (in each target's data), and the import history in `UPSTREAM_PROVENANCE.md`.
- The data was transformed (trimmed, re-keyed and corrections applied) by `tools/src/QuestieImport.cs` and `tools/src/QuestieCorrections.cs`.

Questwarden is not affiliated with the Questie project and does not use the Questie name or logo as its own.

Releases also include the class-trainer spell lists of **What's Training?** (https://github.com/fusionpit/WhatsTraining) by fusionpit, under the MIT License:

- Upstream commit `26caff2fb3cb7d0bd5ed13c15b69be71a16dbafe` (branch `master`): `Classes/Vanilla/<Class>.lua` for Classic Era and `Classes/TBC/<Class>.lua` for TBC Classic Anniversary.
- The MIT licence text (upstream: "Copyright (c) 2019") is reproduced verbatim in `Classes/WhatsTraining_LICENSE.txt` in each target's data.
- Transformed by `tools/research/whatstraining_import.py`: the spell ids, levels, base prices and requirements are kept, hunter pet abilities are left out, race ids are turned into race names. No code, interface or artwork of What's Training? is included, and it does not need to be installed.

Questwarden is not affiliated with What's Training? or its author.

Talent-tree layouts and race/class combinations are read from World of Warcraft client tables for each target's build (Classic Era 1.15.9 from Phase 2). World of Warcraft and The Burning Crusade are trademarks of Blizzard Entertainment, Inc. This add-on is not affiliated with or endorsed by Blizzard Entertainment.

See `THIRD_PARTY_LICENSES.md` for details, including the residual licensing uncertainty upstream documents for some historic Questie contributions.
