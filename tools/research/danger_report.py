# List the route steps that have a dangerous mob close by, for Hardcore review (docs/GUIDE_FORMAT.md,
# "Hardcore route flavor"). Read-only: it writes a report, not guide sources.
# Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
# SPDX-License-Identifier: GPL-3.0-only
#
# For every located accept, complete and turn-in step it looks for hostile mobs (QuestieDB NPC data, all of it,
# not only the bundled subset) with a spawn within RADIUS yards of the step's point, and keeps those that are:
#   elite      an elite or rare elite at most 2 levels under the step's model level, or higher;
#   rare       a rare at least 2 levels above it;
#   high       a normal mob at least HIGH levels above it.
# Mobs the step itself names (its quest's kill and talk targets, giver and finisher) are left out: the step
# already tells you about them. "patrols" = the mob has waypoints, so it walks through the area.
# Model levels come from docs/generated/<Target>/step-levels.csv (run the routes command first).
# "warned" = a Hardcore note ([hc=only]) stands up to WARN_LINES source lines before the step.
# Output: docs/generated/<Target>/danger-near-steps.csv, one row per step and mob, worst first.
# Usage: python tools/research/danger_report.py ClassicEra
import csv
import math
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from qdb import ROOT, Target, VERB_RE, arr, f, hsh, ids  # noqa: E402

RADIUS = 40.0   # yards from the step's point
HIGH = 5        # levels above the model level for a normal mob to count
WARN_LINES = 8  # a Hardcore note this many source lines before the step counts as its warning
KIND_ORDER = {"elite": 0, "rare": 1, "high": 2}

T = Target(sys.argv[1] if len(sys.argv) > 1 else "ClassicEra")


def zone_sizes():
    """zone id -> (width, height) in yards, from Zones.lua's uiMap ids and the client's UiMapAssignment table."""
    zones = open(os.path.join(T.qdir, "Zones.lua"), encoding="utf-8").read()
    ui = {int(a): int(b) for a, b in re.findall(r"^\[(\d+)\]=(\d+),$", zones.split("Z.names")[0], re.M)}
    p = os.path.join(ROOT, ".cache", "upstream", "db2", T.info["clientTables"]["build"], "UiMapAssignment.csv")
    box = {}
    for r in csv.DictReader(open(p, encoding="utf-8")):
        if r["UiMin_0"] == "0" and r["UiMin_1"] == "0" and r["UiMax_0"] == "1" and r["UiMax_1"] == "1":
            box.setdefault(int(r["UiMapID"]), (abs(float(r["Region_4"]) - float(r["Region_1"])),
                                               abs(float(r["Region_3"]) - float(r["Region_0"]))))
    return {z: box[u] for z, u in ui.items() if u in box}


SIZE = zone_sizes()
PATROL = {k for k, v in T._raw("NpcDB.lua", "QuestieDB.npcData").items() if len(v) > 7 and v[7]}

# zone -> [(npc id, (x, y))] for every hostile mob with spawns, plus rares friendly to one faction only (Watch
# Commander Zalaphil is dangerous to Horde). Other one-faction NPCs (flight masters, guards in their towns) are
# not route dangers. Each step keeps the ones hostile to its guide's faction. Invisible helper NPCs (event and
# spell triggers such as "Headless Horseman - Fire (DND)" or "Flame Bunny") are not mobs.
HELPER = re.compile(r"\(|\b(Bunny|Trigger|Invisible|Dummy)\b")
BY_ZONE = {}
for nid, r in T.N.items():
    if r[6] and ((r[3] or 0) not in (2, 4) or ("A" in r[6] and "H" in r[6])):
        continue
    if HELPER.search(r[0] or ""):
        continue
    for z, pts in hsh(r[5]).items():
        for p in arr(pts):
            p = arr(p)
            if len(p) >= 2:
                BY_ZONE.setdefault(z, []).append((nid, (p[0], p[1])))


def yd(size, a, b):
    return math.hypot((a[0] - b[0]) / 100 * size[0], (a[1] - b[1]) / 100 * size[1])


def own_npcs(q):
    """NPC ids the step's quest names: giver, finisher and objectives."""
    if not q:
        return set()
    out = set(ids(f(q, 6))) | set(ids(f(q, 9)))
    obj = hsh(f(q, 12))
    for key in ("c", "k"):
        out |= set(ids(obj.get(key)))
    return out


def classify(nid, lv):
    r = T.N[nid]
    rank, lo, hi = r[3] or 0, r[1] or 0, r[2] or r[1] or 0
    if rank in (1, 2) and hi >= lv - 2:
        return "elite"
    if rank == 4 and hi >= lv + 2:
        return "rare"
    if rank == 0 and lo >= lv + HIGH:
        return "high"
    return None


rows = []
steps_hit = 0
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
        size = SIZE.get(s["z"])
        lv = T.level_at(g["file"], src_q[k])
        if s["x"] is None or not size or lv is None:
            continue
        mine = own_npcs(T.Q.get(s["q"]))
        best = {}
        side = g["faction"][0]
        for nid, p in BY_ZONE.get(s["z"], ()):
            if nid in mine or side in (T.N[nid][6] or ""):
                continue
            d = yd(size, (s["x"], s["y"]), p)
            if d > RADIUS or (nid in best and best[nid] <= d):
                continue
            if classify(nid, lv):
                best[nid] = d
        if not best:
            continue
        steps_hit += 1
        hc = "skip" if "hc=skip" in lines[src_q[k]] else ""
        warned = "yes" if any(l.startswith("note") and "hc=only" in l for l in lines[max(0, src_q[k] - WARN_LINES):src_q[k]]) else ""
        for nid, d in best.items():
            r = T.N[nid]
            rows.append(dict(step="%s:%d" % (rel, src_q[k] + 1), guide=gid, text=lines[src_q[k]][:90],
                             modelLevel="%.1f" % lv, hc=hc, warned=warned, kind=classify(nid, lv), npc=nid, name=r[0],
                             rank=r[3] or 0, levels="%s-%s" % (r[1], r[2]), yards="%.0f" % d,
                             patrols="yes" if nid in PATROL else ""))

rows.sort(key=lambda r: (KIND_ORDER[r["kind"]], r["step"], float(r["yards"])))
out = os.path.join(ROOT, "docs", "generated", T.name, "danger-near-steps.csv")
with open(out, "w", newline="", encoding="utf-8") as fh:
    w = csv.DictWriter(fh, fieldnames=list(rows[0].keys()) if rows else ["step"])
    w.writeheader()
    w.writerows(rows)
kinds = {}
for r in rows:
    kinds[r["kind"]] = kinds.get(r["kind"], 0) + 1
print("%d steps with a dangerous mob within %d yards; %d rows %s; %d already [hc=skip]; %d with a Hardcore note; %d patrol"
      % (steps_hit, RADIUS, len(rows), kinds, sum(1 for r in rows if r["hc"]), sum(1 for r in rows if r["warned"]),
         sum(1 for r in rows if r["patrols"])))
print("wrote " + out)
