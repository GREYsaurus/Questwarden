# Find and fix "turn in far away, then come back" detours in the guides (docs/ROUTE_OPTIMIZATION.md).
# Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
# SPDX-License-Identifier: GPL-3.0-only
#
# The pattern: you finish quest A's objectives, the guide sends you to A's turn-in, and a few steps later
# sends you back to the same place for quest B's objectives, although B was already in your log. Example:
# Elwynn - Kobold Candles turned in at Goldshire between the Fargodeep Mine objectives (Kobold Candles,
# The Fargodeep Mine, Gold Dust Exchange).
#
# For every turn-in step that directly follows a complete step (position P = that complete's objectives):
# the later complete steps of quests accepted before the turn-in, whose objectives are near P while the
# turn-in is far from P, move up to just before the turn-in (keeping their order, their tags and the note
# lines right above them). A complete step does not move:
#   - past another step of the same quest, past a step that names one of the quest's objective items or
#     NPCs (a step that gives you what you need), or past a level step when the quest is above the level
#     the route expects at the turn-in (+1),
#   - when its objectives are unknown or in another zone (no positions in the guide's zone),
#   - when the quest has more than one complete step in the guide (split on purpose), has an elite target,
#     or is more than 2 levels above the level the route expects at the turn-in (and above the quest you
#     just finished there).
#   - past a step that takes you elsewhere (hearthstone, flight, boat, dungeon, a step in another zone).
# Distances are in map percent of the guide's zone (rough: zones differ in size): near <= NEAR, far >= FAR.
# Each move is kept only if it shortens the guide's modeled walk by at least GAIN: accept and turn-in steps
# at their NPCs, complete steps at the objective spot nearest to where you were (greedy). A quest whose
# objectives come from the same creatures as the one you just finished (Kobold Candles and Gold Dust
# Exchange: the same kobolds) moves when the walk does not get longer.
#
# Usage: python tools/research/cluster_objectives.py <Target> [--apply]
#   Without --apply: report only. With --apply: rewrite the guide sources, then run guides + routes and
#   tools/research/layout_map.py so saved progress follows the moved steps.
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from qdb import Target, arr, dist, f, hsh, ids  # noqa: E402

NEAR, FAR, GAIN = 9.0, 14.0, 3.0
AWAY_RE = re.compile(r"^(hs|fly|boat|zeppelin|portal|travel|dungeon)\b")
T = Target(sys.argv[1])
APPLY = "--apply" in sys.argv
STEP_RE = re.compile(r"^(accept|turnin|complete|level|note|train|bind|hs|fly|goto|vendor|repair|dungeon|"
                     r"use|buy|home|boat|zeppelin|portal|travel|learn)\b")
VERBS = ("accept", "turnin", "complete")


def objective_pts(qid, zone):
    """Every known spawn point of the quest's objectives in the zone (targets, droppers, objects, areas)."""
    q = T.Q.get(qid)
    if not q:
        return []
    obj = hsh(f(q, 12))
    pts = []
    for n in ids(obj.get("c")) + ids(obj.get("k")):
        pts += T.npc_pts(n, zone)
    for o in ids(obj.get("o")):
        pts += T.obj_pts(o, zone)
    for it in ids(obj.get("i")):
        ir = T.I.get(it)
        if ir:
            for n in ids(ir[1]):
                pts += T.npc_pts(n, zone)
            for o in ids(ir[2]):
                pts += T.obj_pts(o, zone)
    trig = arr(f(q, 21)) if f(q, 21) else []
    if len(trig) > 1:
        for p in arr(hsh(trig[1]).get(zone)):
            p = arr(p)
            if len(p) >= 2:
                pts.append((p[0], p[1]))
    return pts


def objective_mobs(qid):
    """Creatures that are the quest's targets or drop its objective items."""
    q = T.Q.get(qid)
    if not q:
        return set()
    obj = hsh(f(q, 12))
    mobs = set(ids(obj.get("c")) + ids(obj.get("k")))
    for it in ids(obj.get("i")):
        if T.I.get(it):
            mobs |= set(ids(T.I[it][1]))
    return mobs


def closest(a, b):
    """(distance, point of a, point of b) for the closest pair of two point lists."""
    return min(((dist(p, q), p, q) for p in a for q in b), default=(None, None, None))


def objective_names(qid):
    q = T.Q.get(qid)
    if not q:
        return set()
    obj = hsh(f(q, 12))
    names = set()
    for it in ids(obj.get("i")):
        if T.I.get(it):
            names.add(T.I[it][0].lower())
    return names


def walk(seq, order, zone, cache):
    """Modeled walking distance (map percent) of the steps in this order."""
    d, pos = 0.0, None
    for k in order:
        s = seq[k]
        p = None
        if s["x"] is not None:
            if s["z"] != zone:
                pos = None
                continue
            p = (s["x"], s["y"])
        elif s["kind"] == "complete" and s["q"]:
            if s["q"] not in cache:
                cache[s["q"]] = objective_pts(s["q"], zone)
            pts = cache[s["q"]]
            if pts:
                p = min(pts, key=lambda a: dist(a, pos)) if pos else pts[0]
        if p:
            if pos:
                d += dist(pos, p)
            pos = p
    return d


def source_steps(path):
    """Source lines that compile to steps, in order: (line index, verb)."""
    out = []
    lines = open(path, encoding="utf-8").read().split("\n")
    for i, ln in enumerate(lines):
        s = ln.strip()
        if not s or s.startswith("@") or s.startswith("#") or s.startswith("--"):
            continue
        m = STEP_RE.match(s)
        if m:
            out.append((i, m.group(1)))
    return lines, out


def fix_guide(g):
    lines, src = source_steps(g["file"])
    steps = g["steps"]
    # Source verbs and compiled kinds must line up for accept/turnin/complete (compiled q ids are the truth).
    sv = [(i, v) for i, v in src if v in VERBS]
    cv = [s for s in steps if s["kind"] in VERBS]
    if len(sv) != len(cv) or any(v != s["kind"] for (_, v), s in zip(sv, cv)):
        return None, "source and compiled steps do not line up; skipped"
    seq = [dict(line=i, kind=v, q=s["q"], z=s["z"], x=s["x"], y=s["y"]) for (i, v), s in zip(sv, cv)]
    zone = g["zone"]
    ncomplete = {}
    for s in seq:
        if s["kind"] == "complete":
            ncomplete[s["q"]] = ncomplete.get(s["q"], 0) + 1
    moves = []
    moved = set()
    order = list(range(len(seq)))
    cache = {}
    best = walk(seq, order, zone, cache)
    for k, st in enumerate(seq):
        if st["kind"] != "turnin" or st["x"] is None or k == 0:
            continue
        prev = seq[k - 1]
        if prev["kind"] != "complete" or prev["line"] in moved:
            continue
        # Only lines between the complete and the turn-in that are not steps of other kinds (notes are fine).
        between = [ln for ln in lines[prev["line"] + 1:st["line"]] if ln.strip() and STEP_RE.match(ln.strip())
                   and not ln.strip().startswith("note")]
        if between:
            continue
        pset = objective_pts(prev["q"], zone)
        if not pset:
            continue
        tpos = (st["x"], st["y"])
        if st["z"] != zone:
            continue
        accepted = {s["q"] for s in seq[:k] if s["kind"] == "accept"}
        level_here = T.level_at(g["file"], st["line"])
        grab = []
        for j in range(k + 1, len(seq)):
            b = seq[j]
            if b["kind"] != "complete" or b["q"] not in accepted or b["line"] in moved or ncomplete[b["q"]] > 1:
                continue
            obj = hsh(f(T.Q[b["q"]], 12))
            if any(T.hostile_elite(n) for n in ids(obj.get("c")) + ids(obj.get("k"))):
                continue
            # Near: some objective spot of B is close to some objective spot of A (where you are), and that
            # spot is far from the turn-in.
            d, P, bp = closest(pset, objective_pts(b["q"], zone))
            if d is None or d > NEAR or dist(P, tpos) < FAR or dist(tpos, bp) < FAR:
                continue
            # Blockers between the turn-in and this step.
            blocked = None
            needs = objective_names(b["q"])
            qlvl = f(T.Q[b["q"]], 3) or 0
            if level_here is not None and qlvl > max(level_here + 2, f(T.Q[prev["q"]], 3) or 0):
                continue
            for ln in lines[st["line"]:b["line"]]:
                s = ln.strip()
                m = re.match(r"^(accept|turnin|complete)\s+(\d+\s+)?(.*?)\s*(\[|\||$)", s)
                if m and (m.group(2) and int(m.group(2)) == b["q"]):
                    blocked = "another step of the quest"
                if m and not m.group(2) and m.group(3) == T.Q[b["q"]][0] and not s.startswith("complete"):
                    blocked = "another step of the quest"
                if any(n in s.lower() for n in needs):
                    blocked = "a step names an objective item"
                if s.startswith("level") and level_here is not None and qlvl > level_here + 1:
                    blocked = "level step (quest %d, route level %.1f)" % (qlvl, level_here)
                if AWAY_RE.match(s):
                    blocked = "a step takes you elsewhere"
            if any(seq[x]["x"] is not None and seq[x]["z"] != zone for x in range(k, j)):
                blocked = "a step in another zone"
            if not blocked:
                # Just before the turn-in, after anything already moved there.
                trial = [x for x in order if x != j]
                trial.insert(trial.index(k), j)
                w = walk(seq, trial, zone, cache)
                same = objective_mobs(b["q"]) & objective_mobs(prev["q"])
                if w > (best if same else best - GAIN):
                    blocked = "no shorter walk (%.1f -> %.1f)" % (best, w)
                else:
                    gain, best, order = best - w, w, trial
            if blocked:
                moves.append(dict(skip=True, why=blocked, b=b, t=st))
                continue
            moves.append(dict(skip=False, b=b, t=st, d=gain))
            moved.add(b["line"])
    return (lines, moves), None


def note_block(lines, i):
    """Index of the first line of the step at i, including note lines right above it."""
    s = i
    while s > 0 and lines[s - 1].strip().startswith("note"):
        s -= 1
    return s


total = 0
for gid, g in sorted(T.guides.items()):
    if not g["file"]:
        continue
    res, err = fix_guide(g)
    if err:
        print("%s: %s" % (gid, err))
        continue
    lines, moves = res
    real = [m for m in moves if not m["skip"]]
    for m in moves:
        b, t = m["b"], m["t"]
        print("%s: %s complete %s (line %d) before turnin %s (line %d)%s" % (
            gid, "SKIP" if m["skip"] else "move", T.Q[b["q"]][0], b["line"] + 1, T.Q[t["q"]][0], t["line"] + 1,
            (" - " + m["why"]) if m["skip"] else " - walk %.1f map%% shorter" % m["d"]))
    total += len(real)
    if APPLY and real:
        # Group moves by their turn-in line; move each complete block (with its notes) above the turn-in.
        by_t = {}
        for m in real:
            by_t.setdefault(m["t"]["line"], []).append(m["b"]["line"])
        take = {}
        for tl, bls in by_t.items():
            for bl in bls:
                take[bl] = tl
        by_t = {note_block(lines, tl): bls for tl, bls in by_t.items()}  # above the turn-in's own notes
        blocks = {bl: list(range(note_block(lines, bl), bl + 1)) for bl in take}
        drop = {i for b in blocks.values() for i in b}
        out = []
        for i, ln in enumerate(lines):
            if i in by_t:
                for bl in by_t[i]:
                    out += [lines[x] for x in blocks[bl]]
            if i not in drop:
                out.append(ln)
        raw = open(g["file"], "rb").read()
        nl = "\r\n" if b"\r\n" in raw else "\n"
        open(g["file"], "wb").write(nl.join(out).encode("utf-8"))
print("%d step(s) %s" % (total, "moved" if APPLY else "to move"))
