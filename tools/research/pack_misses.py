# List objective steps that could be done together with an earlier one but are not: the quest's objectives
# (mobs, item droppers, or objects you loot or use) are in the same area as an earlier complete step's, and its
# pickup could come before that step. Read-only; the moves are made by hand in the guide sources.
# Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
# SPDX-License-Identifier: GPL-3.0-only
#
# tools/research/kill_packs.py joins complete steps of quests already in your log whose MOBS spawn together. It
# misses two cases, which this lists:
#   - "in log": the quest is in your log at C, but its objectives are objects (Doom Weed plants, crates): no mobs;
#   - "pick up first": the quest is picked up after C, though its giver stands within NEAR map percent of a step
#     you reach before C in the same visit (same zone, no hearthstone, flight or travel in between). Example:
#     Tirisfal - Doom Weed (Junior Apothecary Holland, Brill) after Graverobbers, though the weed grows among the
#     Rot Hide gnolls and Holland stands where you pick up Graverobbers.
# "Same area": at least SHARE of the quest's objective spots lie within AREA map percent of C's, or the same mobs.
# Skipped: quests above the route's level at C + 2, quests with an elite target, item-started or escort quests,
# quests with more than one complete step, pickups whose prerequisites are not done or whose
# required level is above the route's level at C, and pairs where a step of the same quest, or a step that takes you
# elsewhere, lies between the giver step and C.
# Usage: python -I tools/research/pack_misses.py <Target>
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from qdb import Target, dist, escort, f, hsh, ids  # noqa: E402

NEAR, AREA, SHARE = 3.0, 5.0, 0.6
AWAY_RE = re.compile(r"^(hs|fly|boat|zeppelin|portal|travel|dungeon)\b")
STEP_RE = re.compile(r"^(accept|turnin|complete)\b")
T = Target(sys.argv[1] if len(sys.argv) > 1 else "ClassicEra")


def spots(qid, zone):
    """(mob ids, points) of the quest's objectives in the zone: kill targets, item droppers, item and use objects."""
    q = T.Q.get(qid)
    if not q:
        return set(), []
    obj = hsh(f(q, 12))
    mobs = set(ids(obj.get("c")) + ids(obj.get("k")))
    objs = set(ids(obj.get("o")))
    for it in ids(obj.get("i")):
        if T.I.get(it):
            mobs |= set(ids(T.I[it][1]))
            objs |= set(ids(T.I[it][2]))
    pts = [p for n in mobs for p in T.npc_pts(n, zone)] + [p for o in objs for p in T.obj_pts(o, zone)]
    return mobs, pts, bool(objs)


def near(a, b, r):
    return any(dist(p, q) <= r for p in a for q in b)


def share(a, b):
    """Part of b's points within AREA of one of a's: how much of b is done where a is."""
    return sum(1 for q in b if any(dist(p, q) <= AREA for p in a)) / float(len(b)) if b else 0.0


rows = 0
for gid, g in sorted(T.guides.items()):
    if not g["file"]:
        continue
    lines = open(g["file"], encoding="utf-8").read().split("\n")
    src = [i for i, ln in enumerate(lines) if STEP_RE.match(ln.strip())]
    cv = [s for s in g["steps"] if s["kind"] in ("accept", "turnin", "complete")]
    if len(src) != len(cv):
        print("%s: source and compiled steps do not line up; skipped" % gid)
        continue
    seq = [dict(s, line=i) for i, s in zip(src, cv)]
    zone = g["zone"]
    info, ncomplete = {}, {}
    for k, s in enumerate(seq):
        if s["kind"] == "complete" and s["q"] in T.Q:
            ncomplete[s["q"]] = ncomplete.get(s["q"], 0) + 1
            info[k] = spots(s["q"], zone)
    # The first source line of the current visit: no step that takes you elsewhere after it.
    def visit_start(line):
        i = line
        while i > 0 and not AWAY_RE.match(lines[i - 1].strip()):
            i -= 1
        return i
    seen, best = set(), {}
    for k, c in enumerate(seq):
        if k not in info or not info[k][1]:
            continue
        before = seq[:k]
        in_log = {s["q"] for s in before if s["kind"] == "accept"} - {s["q"] for s in before if s["kind"] == "turnin"}
        lvl = T.level_at(g["file"], c["line"])
        start = visit_start(c["line"])
        for j in range(k + 1, len(seq)):
            b = seq[j]
            if j not in info or b["q"] == c["q"] or (b["q"], k) in seen or not info[j][1]:
                continue
            if ncomplete.get(b["q"], 0) > 1 or b.get("opt") or b.get("filtered"):
                continue
            ov = share(info[k][1], info[j][1])
            if not (info[k][0] & info[j][0]) and ov < SHARE:
                continue
            # Already next to C (only other complete steps in between)?
            if all(seq[x]["kind"] == "complete" for x in range(k + 1, j)):
                continue
            q = T.Q[b["q"]]
            qlvl = f(q, 3) or 0
            if lvl is not None and qlvl > lvl + 2:
                continue
            if any(T.hostile_elite(n) for n in info[j][0]) or escort(q):
                continue
            if b["q"] in in_log:
                if not info[j][2]:
                    continue  # mobs only: kill_packs.py handles these
                why = "in log, objects"
                where = ""
            else:
                acc = [x for x in range(k, len(seq)) if seq[x]["kind"] == "accept" and seq[x]["q"] == b["q"]]
                if not acc or seq[acc[0]].get("starter"):
                    continue
                givers = ids(f(q, 6))
                gpts = [p for n in givers for p in T.npc_pts(n, zone)]
                if not gpts:
                    continue
                earlier = [x for x in range(k) if seq[x]["line"] >= start and seq[x]["x"] is not None
                           and seq[x]["z"] == zone and near([(seq[x]["x"], seq[x]["y"])], gpts, NEAR)]
                if not earlier:
                    continue
                if any(seq[y]["q"] == b["q"] for y in range(earlier[-1], k)):
                    continue
                done = {s["q"] for s in before if s["kind"] == "turnin"}
                pre = ids(f(q, 14)) + ids(f(q, 13))
                if (ids(f(q, 14)) and not set(ids(f(q, 14))) <= done) or (ids(f(q, 13)) and not set(ids(f(q, 13))) & done):
                    continue  # its prerequisites are not done yet at C
                if lvl is not None and (f(q, 2) or 0) > lvl:
                    continue  # needs a higher level than the route has at C
                why = "pick up first"
                where = " (giver at line %d)" % (seq[earlier[-1]]["line"] + 1)
            seen.add((b["q"], k))
            if b["q"] in best and best[b["q"]][0] >= ov:
                continue
            best[b["q"]] = (ov, "%s: %s line %d -> with %s line %d [%s%s] %d%% of its spots there, lvl %s q%d" % (
                gid, q[0], b["line"] + 1, T.Q[c["q"]][0], c["line"] + 1, why, where, round(ov * 100),
                "%.1f" % lvl if lvl is not None else "?", qlvl))
    for _, line in sorted(best.values(), key=lambda v: v[1]):
        print(line)
        rows += 1
print("%d candidate(s)" % rows)
