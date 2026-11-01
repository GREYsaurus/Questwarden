# Order back-to-back pickups and turn-ins so the nearest NPC comes first (docs/ROUTE_OPTIMIZATION.md).
# Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
# SPDX-License-Identifier: GPL-3.0-only
#
# The mistake: two NPCs next to each other in the guide, and the guide sends you to the farther one first. Example:
# Dun Morogh - you appear next to Sten Stoutarm (Dwarven Outfitters), but the guide started with Talin Keeneye
# (The Boar Hunter), farther west, and then came back.
#
# A run is a stretch of accept and turn-in steps with nothing else in between (note lines go with the step below
# them), all at NPCs in the guide's zone. Steps at the same NPC (same coordinates, one after another) stay together
# in their order. The run is reordered to the shortest walk from where you are before it (the last step with a known
# position; at the start of a starting guide, the NPC you appear next to, see SPAWN) to where you go after it (the
# next step's NPC, or the nearest objective spawn of the next complete step). Never reordered:
#   - an accept after the turn-in of one of its prerequisites, or a turn-in before its own accept;
#   - an accept whose required level is above the route model's level at the run (step-levels.csv) ahead of the
#     turn-ins before it: their XP may be what gets you the level;
#   - steps without coordinates (item-started pickups), or in another zone: they end the run.
# A new order is kept only when it saves at least GAIN map percent of walking.
#
# Usage: python tools/research/npc_order.py <Target> [--apply]
#   Without --apply: report only. With --apply: rewrite the guide sources; then run guides + routes and
#   tools/research/layout_map.py so saved progress follows the moved steps.
import itertools
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from qdb import Target, dist, f, hsh, ids  # noqa: E402

GAIN = 2.0
MAX_NODES = 9  # exact search up to this many NPC stops per run; longer runs are left alone
# Starting guides: the NPC standing where the race's characters appear (the giver of the race's first quest).
SPAWN = {
    "A_Human_Elwynn": "Deputy Willem",
    "A_DwarfGnome_DunMorogh": "Sten Stoutarm",
    "A_NightElf_Teldrassil": "Conservator Ilthalaine",
    "A_Draenei_Azuremyst": "Megelon",
    "H_OrcTroll_Durotar": "Kaltunk",
    "H_Tauren_Mulgore": "Grull Hawkwind",
    "H_Undead_Tirisfal": "Undertaker Mordo",
    "H_BloodElf_Eversong": "Magistrix Erona",
}
STEP_RE = re.compile(r"^(accept|turnin|complete|level|note|train|bind|hs|fly|goto|vendor|repair|dungeon|"
                     r"use|buy|home|boat|zeppelin|portal|travel|learn|talk|collect|fp|grind|guide)\b")
VERBS = ("accept", "turnin", "complete")
T = Target(sys.argv[1])
APPLY = "--apply" in sys.argv


def spawn_point(gid, zone):
    name = SPAWN.get(gid)
    if not name:
        return None
    for n, r in T.N.items():
        if r and r[0] == name:
            pts = T.npc_pts(n, zone)
            if pts:
                return pts[0]
    return None


def objective_pts(qid, zone):
    q = T.Q.get(qid)
    if not q:
        return []
    obj = hsh(f(q, 12))
    mobs = set(ids(obj.get("c")) + ids(obj.get("k")))
    for it in ids(obj.get("i")):
        if T.I.get(it):
            mobs |= set(ids(T.I[it][1]))
    pts = [p for n in mobs for p in T.npc_pts(n, zone)]
    for o in ids(obj.get("o")):
        pts += T.obj_pts(o, zone)
    return pts


def prereqs(qid):
    q = T.Q.get(qid)
    return set(ids(f(q, 13)) + ids(f(q, 14))) if q else set()


def walk(start, nodes, end_pts):
    d, pos = 0.0, start
    for nd in nodes:
        if pos:
            d += dist(pos, nd["pos"])
        pos = nd["pos"]
    if end_pts and pos:
        d += min(dist(pos, p) for p in end_pts)
    return d


def allowed(order):
    """Accepts before their turn-ins, prerequisites turned in before the accepts that need them."""
    seen_turnin, seen_accept = set(), set()
    for nd in order:
        for s in nd["steps"]:
            if s["kind"] == "accept":
                if s["need"] - seen_turnin:
                    return False
                seen_accept.add(s["q"])
            else:
                if s["q"] in s["run_accepts"] and s["q"] not in seen_accept:
                    return False
                seen_turnin.add(s["q"])
    return True


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
    # Source lines between two steps that are steps of another kind end a run.
    def between_ok(a, b):
        return not any(STEP_RE.match(ln.strip()) and not ln.strip().startswith("note")
                       for ln in lines[a["line"] + 1:b["line"]])
    runs, cur = [], []
    for k, s in enumerate(seq):
        npc = s["kind"] in ("accept", "turnin") and s["x"] is not None and s["z"] == zone and not s["starter"]
        if npc and cur and between_ok(seq[cur[-1]], s):
            cur.append(k)
            continue
        if len(cur) > 1:
            runs.append(cur)
        cur = [k] if npc else []
    if len(cur) > 1:
        runs.append(cur)
    out, report = [], []
    for run in runs:
        first = run[0]
        # Where you are before the run: the last earlier step with coordinates in this zone.
        start = None
        for k in range(first - 1, -1, -1):
            s = seq[k]
            if s["x"] is not None:
                start = (s["x"], s["y"]) if s["z"] == zone else None
                break
            if s["kind"] == "complete":
                pts = objective_pts(s["q"], zone)
                if pts:
                    nxt = (seq[first]["x"], seq[first]["y"])
                    start = min(pts, key=lambda p: dist(p, nxt))  # you finish its objectives nearest the run
                break
        if start is None and first == 0:
            start = spawn_point(g["id"], zone)
        if start is None:
            continue
        end_pts = []
        if run[-1] + 1 < len(seq):
            s = seq[run[-1] + 1]
            if s["x"] is not None and s["z"] == zone:
                end_pts = [(s["x"], s["y"])]
            elif s["kind"] == "complete":
                end_pts = objective_pts(s["q"], zone)
        run_accepts = {seq[k]["q"] for k in run if seq[k]["kind"] == "accept"}
        run_turnins = {seq[k]["q"] for k in run if seq[k]["kind"] == "turnin"}
        level = T.level_at(g["file"], seq[first]["line"])
        nodes, before = [], set()
        for k in run:
            s = dict(seq[k])
            s["run_accepts"] = run_accepts
            s["need"] = (prereqs(s["q"]) & run_turnins) if s["kind"] == "accept" else set()
            # A pickup you may not have the level for yet keeps the turn-ins (their XP) before it.
            if s["kind"] == "accept" and (level is None or int(level) < (f(T.Q[s["q"]], 2) or 0)):
                s["need"] |= before
            if s["kind"] == "turnin":
                before.add(s["q"])
            pos = (s["x"], s["y"])
            if nodes and nodes[-1]["pos"] == pos:
                nodes[-1]["steps"].append(s)
            else:
                nodes.append(dict(pos=pos, steps=[s]))
        if len(nodes) < 2 or len(nodes) > MAX_NODES:
            continue
        base = walk(start, nodes, end_pts)
        best, best_d = nodes, base
        for perm in itertools.permutations(nodes):
            if perm[0] is nodes[0] and list(perm) == nodes:
                continue
            d = walk(start, perm, end_pts)
            if d < best_d - 1e-9 and allowed(perm):
                best, best_d = list(perm), d
        if base - best_d < GAIN:
            continue
        titles = lambda ns: " > ".join("%s %s" % (st["kind"], T.Q[st["q"]][0]) for nd in ns for st in nd["steps"])
        report.append("line %d: walk %.1f -> %.1f map%%\n    was: %s\n    now: %s" % (
            seq[first]["line"] + 1, base, best_d, titles(nodes), titles(best)))
        out.append((run, best))
    return (lines, seq, out, report), None


def note_block(lines, i):
    s = i
    while s > 0 and lines[s - 1].strip().startswith("note"):
        s -= 1
    return s


total = 0
for gid, g in sorted(T.guides.items()):
    if not g["file"]:
        continue
    g["id"] = gid
    res, err = plan(g)
    if err:
        print("%s: %s" % (gid, err))
        continue
    lines, seq, out, report = res
    for r in report:
        print("%s: %s" % (gid, r))
    total += len(out)
    if APPLY and out:
        new = list(lines)
        for run, best in out:
            # The run's lines (each step with the notes above it) are rewritten in the new order, in place.
            lo = note_block(lines, seq[run[0]]["line"])
            hi = seq[run[-1]]["line"]
            blocks = {}
            for k in run:
                ln = seq[k]["line"]
                blocks[ln] = lines[note_block(lines, ln):ln + 1]
            body = [x for nd in best for st in nd["steps"] for x in blocks[st["line"]]]
            if len(body) != hi - lo + 1:
                print("%s: line %d: other lines inside the run; left alone" % (gid, lo + 1))
                continue
            new[lo:hi + 1] = body
        raw = open(g["file"], "rb").read()
        nl = "\r\n" if b"\r\n" in raw else "\n"
        open(g["file"], "wb").write(nl.join(new).encode("utf-8"))
print("%d run(s) %s" % (total, "reordered" if APPLY else "to reorder"))
