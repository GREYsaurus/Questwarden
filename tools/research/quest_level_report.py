# List the route's quest objectives whose mobs are well above the level the route model expects at that step, so
# the quest can be moved later in its guide (lower-level quests first). Read-only: it writes a report, not guide
# sources.
# Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
# SPDX-License-Identifier: GPL-3.0-only
#
# For every complete step of a guide (not dungeon, elite, optional or class/race-only steps) it works out the
# objective's mob level: for each kill objective (not NPCs friendly to the guide's faction: those are talked to) the lowest level of that mob, for each item objective the
# lowest level of the NPCs worth hunting for it (non-elite droppers within DROPPER_LEVEL_GAP of the quest level,
# as the add-on picks them; all droppers if none fit; none if objects also give it), and keeps the hardest objective. A step is listed when that
# level is at least GAP above the step's model level (docs/generated/<Target>/step-levels.csv: run the routes
# command first). Example: Wanted: Maggot Eye (level 11) at a model level of 6.
# Output: docs/generated/<Target>/quest-level-gaps.csv, worst first.
# Usage: python -I tools/research/quest_level_report.py ClassicEra
import csv
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from qdb import ROOT, Target, VERB_RE, f, hsh, ids  # noqa: E402

GAP = 3                 # mob levels above the model level that count
DROPPER_LEVEL_GAP = 3   # as DB.QuestItemDroppers in addon/Database/QuestDB.lua

T = Target(sys.argv[1] if len(sys.argv) > 1 else "ClassicEra")


def droppers(item, qlevel):
    it = T.I.get(item)
    if it and ids(it[2]):
        return []  # also picked up from objects: no mob needed
    drops = [n for n in ids(it[1]) if n in T.N] if it else []
    fit = [n for n in drops if (T.N[n][3] or 0) == 0 and (not qlevel or (T.N[n][1] or 0) <= qlevel + DROPPER_LEVEL_GAP)]
    return fit or drops


def objective_level(q, side):
    """(level, mob name) of the quest's hardest objective, or (None, None) without mob objectives."""
    obj = hsh(f(q, 12))
    qlevel = f(q, 3) or 0
    best = (None, None)
    groups = [[n] for n in ids(obj.get("c")) if n in T.N and side not in (T.N[n][6] or "")] + [droppers(i, qlevel) for i in ids(obj.get("i"))]
    for g in groups:
        if not g:
            continue
        n = min(g, key=lambda x: T.N[x][1] or 0)  # the easiest way to do this objective
        lv = T.N[n][1] or 0
        if best[0] is None or lv > best[0]:
            best = (lv, T.N[n][0])
    return best


rows = []
for gid, g in sorted(T.guides.items()):
    if not g["file"]:
        continue
    lines = open(g["file"], encoding="utf-8", newline="").read().replace("\r\n", "\n").split("\n")
    src_q = [i for i, l in enumerate(lines) if VERB_RE.match(l)]
    cq = [s for s in g["steps"] if s["kind"] in ("accept", "turnin", "complete")]
    if len(src_q) != len(cq):
        print("skipped %s: source and compiled steps do not line up" % gid)
        continue
    rel = os.path.relpath(g["file"], os.path.join(T.dir, "guides-src")).replace("\\", "/")
    for k, s in enumerate(cq):
        if s["kind"] != "complete" or s["opt"] or s["filtered"] or s["dungeon"]:
            continue
        q = T.Q.get(s["q"])
        lv = T.level_at(g["file"], src_q[k])
        if not q or lv is None:
            continue
        mob, name = objective_level(q, "H" if rel.startswith("horde/") else "A")
        if mob is None or mob - lv < GAP:
            continue
        rows.append(dict(step="%s:%d" % (rel, src_q[k] + 1), guide=gid, quest=s["q"], title=f(q, 1),
                         questLevel=f(q, 3) or 0, mob=name, mobLevel=mob, modelLevel="%.1f" % lv,
                         gap="%.1f" % (mob - lv), text=lines[src_q[k]][:90]))

rows.sort(key=lambda r: -float(r["gap"]))
out = os.path.join(ROOT, "docs", "generated", T.name, "quest-level-gaps.csv")
with open(out, "w", newline="", encoding="utf-8") as fh:
    w = csv.DictWriter(fh, fieldnames=list(rows[0].keys()) if rows else ["step"])
    w.writeheader()
    w.writerows(rows)
print("%d complete steps with mobs %d+ levels above the model level -> %s" % (len(rows), GAP, os.path.relpath(out, ROOT)))
