# Put kill steps whose mobs spawn in the same area next to each other, so they are done together (kill packs).
# Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
# SPDX-License-Identifier: GPL-3.0-only
#
# The compiler links back-to-back complete steps whose mobs (kill targets, kill credit, droppers of the quest's
# items) spawn within PACK map percent of each other into a kill pack (GuideCompiler.LinkKillPacks), and the
# add-on shows the whole pack as current. This tool makes the packs: for every complete step C, the later complete
# steps of quests already in your log at C whose mobs spawn near the mobs of C's pack (or are the same mobs) move up
# to just after the pack, with the note lines right above them. Example: Dun Morogh - The Boar Hunter (Small Crag
# Boars) moves next to Dwarven Outfitters (wolves around Anvilmar). Any number of steps can join one pack.
#
# A complete step does not move:
#   - past another step of the same quest, past a step that names one of its objective items, past the pickup of a
#     quest that starts from a dropped item (it waits on the kill steps after it), past a step that takes you
#     elsewhere (hearthstone, flight, boat, dungeon, travel), or past a step in another zone;
#   - when the quest has more than one complete step in the guide (split on purpose), only elite targets, or is more
#     than 2 levels above the level the route expects at C;
#   - when the guide's modeled walk (see walk) would get more than SLACK map percent longer.
#
# Usage: python tools/research/kill_packs.py <Target> [--apply]
#   Without --apply: report only. With --apply: rewrite the guide sources; then run guides + routes and
#   tools/research/layout_map.py so saved progress follows the moved steps.
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from qdb import Target, dist, f, hsh, ids  # noqa: E402

PACK, SLACK = 8.0, 1.0  # PACK = GuideCompiler.PackRadius
AWAY_RE = re.compile(r"^(hs|fly|boat|zeppelin|portal|travel|dungeon)\b")
STEP_RE = re.compile(r"^(accept|turnin|complete|level|note|train|bind|hs|fly|goto|vendor|repair|dungeon|"
                     r"use|buy|home|boat|zeppelin|portal|travel|learn|talk|collect|fp|grind|guide)\b")
VERBS = ("accept", "turnin", "complete")
T = Target(sys.argv[1])
APPLY = "--apply" in sys.argv


def mobs_of(qid):
    """Creatures that are the quest's targets or kill credit, or drop its objective items."""
    q = T.Q.get(qid)
    if not q:
        return set()
    obj = hsh(f(q, 12))
    mobs = set(ids(obj.get("c")) + ids(obj.get("k")))
    for it in ids(obj.get("i")):
        if T.I.get(it):
            mobs |= set(ids(T.I[it][1]))
    return mobs


def item_names(qid):
    obj = hsh(f(T.Q[qid], 12))
    return {T.I[it][0].lower() for it in ids(obj.get("i")) if T.I.get(it)}


def near(a, b):
    return any(dist(p, q) <= PACK for p in a for q in b)


def walk(seq, order, zone, pts):
    """Modeled walk (map percent): steps with coordinates at them, complete steps at the nearest mob spawn (none
    when that is within PACK of where you are)."""
    d, pos = 0.0, None
    for k in order:
        s = seq[k]
        p = None
        if s["x"] is not None:
            if s["z"] != zone:
                pos = None
                continue
            p = (s["x"], s["y"])
        elif s["kind"] == "complete" and pts.get(k):
            p = min(pts[k], key=lambda a: dist(a, pos)) if pos else pts[k][0]
            if pos and dist(p, pos) <= PACK:
                continue  # mobs in the area you are in: killed there, no walk
        if p:
            if pos:
                d += dist(pos, p)
            pos = p
    return d


def note_block(lines, i):
    s = i
    while s > 0 and lines[s - 1].strip().startswith("note"):
        s -= 1
    return s


def plan(g):
    lines = open(g["file"], encoding="utf-8").read().split("\n")
    src = []
    for i, ln in enumerate(lines):
        m = STEP_RE.match(ln.strip())
        if m and m.group(1) in VERBS:
            src.append((i, m.group(1)))
    cv = [s for s in g["steps"] if s["kind"] in VERBS]
    if len(src) != len(cv) or any(v != s["kind"] for (_, v), s in zip(src, cv)):
        return None, "source and compiled steps do not line up; skipped"
    seq = [dict(line=i, kind=v, q=s["q"], z=s["z"], x=s["x"], y=s["y"], starter=s["starter"])
           for (i, v), s in zip(src, cv)]
    zone = g["zone"]
    mobs, pts, ncomplete = {}, {}, {}
    for k, s in enumerate(seq):
        if s["kind"] == "complete" and s["q"] in T.Q:
            ncomplete[s["q"]] = ncomplete.get(s["q"], 0) + 1
            mobs[k] = mobs_of(s["q"])
            pts[k] = [p for n in mobs[k] for p in T.npc_pts(n, zone)]
    order = list(range(len(seq)))
    best = walk(seq, order, zone, pts)
    moved, packs, report = set(), {}, []
    for k, c in enumerate(seq):
        if c["kind"] != "complete" or not pts.get(k) or k in moved:
            continue
        pack = [k]
        before = seq[:k]
        in_log = {s["q"] for s in before if s["kind"] == "accept"} - {s["q"] for s in before if s["kind"] == "turnin"}
        level_here = T.level_at(g["file"], c["line"])
        for j in range(k + 1, len(seq)):
            b = seq[j]
            if b["kind"] != "complete" or j in moved or not pts.get(j) or b["q"] not in in_log:
                continue
            if not any(mobs[m] & mobs[j] or near(pts[m], pts[j]) for m in pack):
                continue
            # Already right behind the pack (nothing but other pack members in between)?
            if all(x in pack or x in moved for x in range(k, j)):
                pack.append(j)
                continue
            why = None
            qlvl = f(T.Q[b["q"]], 3) or 0
            if ncomplete[b["q"]] > 1:
                why = "quest has more than one complete step"
            elif all(T.hostile_elite(n) for n in mobs[j]):
                why = "elite target"
            elif level_here is not None and qlvl > level_here + 2:
                why = "quest level %d, route level %.1f" % (qlvl, level_here)
            else:
                names = item_names(b["q"])
                for x in range(k + 1, j):
                    s = seq[x]
                    if x in moved:
                        continue
                    if s["q"] == b["q"]:
                        why = "another step of the quest"
                    elif s["kind"] == "accept" and s["starter"]:
                        why = "an item-started pickup"
                    elif s["x"] is not None and s["z"] != zone:
                        why = "a step in another zone"
                for ln in lines[c["line"] + 1:b["line"]]:
                    t = ln.strip()
                    if AWAY_RE.match(t):
                        why = why or "a step takes you elsewhere"
                    elif STEP_RE.match(t) and any(n in t.lower() for n in names):
                        why = why or "a step names an objective item"
            if not why:
                trial = [x for x in order if x != j]
                trial.insert(trial.index((packs.get(k) or [k])[-1]) + 1, j)
                w = walk(seq, trial, zone, pts)
                if w > best + SLACK:
                    why = "longer walk (%.1f -> %.1f)" % (best, w)
                else:
                    best, order = w, trial
            title = T.Q[b["q"]][0]
            if why:
                report.append("SKIP %s (line %d) next to %s - %s" % (title, b["line"] + 1, T.Q[c["q"]][0], why))
                continue
            report.append("move %s (line %d) next to %s (line %d)" % (title, b["line"] + 1, T.Q[c["q"]][0], c["line"] + 1))
            moved.add(j)
            packs.setdefault(k, []).append(j)
            pack.append(j)
    return (lines, seq, packs, report), None


total = 0
for gid, g in sorted(T.guides.items()):
    if not g["file"]:
        continue
    res, err = plan(g)
    if err:
        print("%s: %s" % (gid, err))
        continue
    lines, seq, packs, report = res
    for r in report:
        print("%s: %s" % (gid, r))
    n = sum(len(v) for v in packs.values())
    total += n
    if APPLY and n:
        # Each moved step (with its notes) goes right after its pack's first step, then the members before it.
        after = {}
        drop = set()
        for k, js in packs.items():
            block = []
            for j in js:
                bl = seq[j]["line"]
                rng = list(range(note_block(lines, bl), bl + 1))
                block += rng
                drop |= set(rng)
            after[seq[k]["line"]] = block
        out = []
        for i, ln in enumerate(lines):
            if i not in drop:
                out.append(ln)
            if i in after:
                out += [lines[x] for x in after[i]]
        raw = open(g["file"], "rb").read()
        nl = "\r\n" if b"\r\n" in raw else "\n"
        open(g["file"], "wb").write(nl.join(out).encode("utf-8"))
print("%d step(s) %s" % (total, "moved" if APPLY else "to move"))
