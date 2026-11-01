# Grind steps at dense spawns where the route model is still well short of a guide's level check
# (docs/ROUTE_OPTIMIZATION.md).
# Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
# SPDX-License-Identifier: GPL-3.0-only
#
# For every "level N" step in a guide source where the model character arrives at least MIN_SHORT levels
# below N (lowest model level over all routes, docs/generated/<Target>/step-levels.csv), this inserts one
# grind step before it:
#   - the mobs: non-elite, non-friendly NPCs of the bundled data that spawn in the guide's zone at about
#     the player's level there (their level range touches N-2..N) with at least 5 spawn points there, so
#     no rares or one-off named mobs (the compiler checks each name);
#   - the spot: the densest cluster of their spawns (most spawn points within RADIUS map percent) near one
#     of the guide's last quest steps in that zone, scored by density over distance. Steps before the
#     last hearthstone, flight, travel, level or grind step are not considered;
#   - the target: if the spot sits before some of the guide's remaining quests, the step asks only for
#     the XP those quests don't give, as level and tenth ("grind 22.4" = 40% through 22), so the
#     quests finish the job; otherwise the grind step replaces the check and asks for N.
# Smaller shortfalls are left to the level check: the model counts no rested, discovery or group XP.
# Existing grind steps and class-only level steps are left alone. Writes guide sources (our own
# content); run guides + routes afterwards and review the diff.
# Usage: python tools/research/grind_spots.py ClassicEra [--min-short 0.75] [--dry-run]
import math
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from qdb import Target, arr, dist, f, hsh, parse_lua  # noqa: E402

args = [a for a in sys.argv[1:] if not a.startswith("--")]
T = Target(args[0] if args else "ClassicEra")
DRY = "--dry-run" in sys.argv
MIN_SHORT = 0.75
for i, x in enumerate(sys.argv):
    if x == "--min-short":
        MIN_SHORT = float(sys.argv[i + 1])
RADIUS = 6.0       # map percent: spawns this close to a cluster centre count towards its density
MIN_SPAWNS = 8     # a spot needs at least this many spawn points of suitable mobs in RADIUS
MAX_DIST = 20.0    # map percent from the anchor step
LOOKBACK = 25      # quest steps before the check that may serve as the anchor
VERB_RE = re.compile(r"^(accept|turnin|complete)\s")
STOP_RE = re.compile(r"^(hs|fly|travel|guide|level|grind)\b")
LEVEL_RE = re.compile(r"^level (\d+)\s*(\|.*)?$")

# Bundled NPCs (the compiler only accepts these for grind steps): name, min, max, rank, zone, spawns, friendly
BN = {}
for line in open(os.path.join(T.qdir, "Npcs.lua"), encoding="utf-8"):
    m = re.match(r"^N\[(\d+)\]=(\{.*\})\s*$", line)
    if m:
        BN[int(m.group(1))] = arr(parse_lua(m.group(2)))


def spawn_points(zone, level):
    pts = []
    for r in BN.values():
        name, lo, hi, rank, friendly = r[0], f(r, 2) or 0, f(r, 3) or 0, f(r, 4) or 0, f(r, 7)
        if friendly or rank in (1, 2, 3, 4) or not lo or lo > level or hi < level - 2:
            continue
        sp = hsh(f(r, 6)).get(zone)
        if not sp or len(arr(sp)) < 5:
            continue
        for p in arr(sp):
            p = arr(p)
            pts.append((p[0], p[1], name))
    return pts


def best_spot(pts, anchors):
    """anchors: [(order, (x, y))], latest first. Returns (score, order, centre, names, count)."""
    best = None
    for c in pts:
        near = [p for p in pts if dist(p, c) <= RADIUS]
        if len(near) < MIN_SPAWNS:
            continue
        for order, pos in anchors:
            d = dist(c, pos)
            if d > MAX_DIST:
                continue
            # Later anchors win unless an earlier spot is much denser: grinding early makes the guide's
            # remaining quests worth less XP (the model's reduced-XP rule), so it costs more grinding overall.
            score = len(near) / (1 + d / 8.0) * 0.85 ** order
            if best is None or score > best[0]:
                best = (score, order, near, d)
    if not best:
        return None
    score, order, near, d = best
    cx, cy = sum(p[0] for p in near) / len(near), sum(p[1] for p in near) / len(near)
    counts = {}
    for p in near:
        counts[p[2]] = counts.get(p[2], 0) + 1
    names = [n for n, k in sorted(counts.items(), key=lambda kv: (-kv[1], kv[0])) if k >= 3][:3]
    return score, order, (cx, cy), names, len(near)


report, skipped = [], []
for gid, g in sorted(T.guides.items(), key=lambda kv: kv[1]["min"]):
    if not g["file"]:
        continue
    zone = g["zone"]
    rel = os.path.relpath(g["file"], os.path.join(T.dir, "guides-src")).replace("\\", "/")
    levels = T.step_level.get(rel, {})
    src = open(g["file"], encoding="utf-8", newline="").read()
    nl = "\r\n" if "\r\n" in src else "\n"
    lines = src.replace("\r\n", "\n").split("\n")
    src_q = [i for i, l in enumerate(lines) if VERB_RE.match(l)]
    cq = [s for s in g["steps"] if s["kind"] in ("accept", "turnin", "complete")]
    if len(src_q) != len(cq):
        skipped.append("%s: source/compiled quest steps differ" % gid)
        continue
    pos_of = {src_q[k]: (s["x"], s["y"]) for k, s in enumerate(cq)
              if s["z"] == zone and s["x"] is not None and not s["filtered"] and not s["opt"]}
    inserts = []
    for k, l in enumerate(lines):
        m = LEVEL_RE.match(l)
        if not m or k + 1 not in levels:
            continue
        need = int(m.group(1))
        arrive = levels[k + 1]
        short = need - arrive
        if short < MIN_SHORT:
            continue
        anchors = []  # (order, source line, position), latest first
        for j in range(k - 1, -1, -1):
            if STOP_RE.match(lines[j]) or len(anchors) >= LOOKBACK:
                break
            if j in pos_of:
                anchors.append((len(anchors), j, pos_of[j]))
        pts = spawn_points(zone, need)
        spot = best_spot(pts, [(o, p) for o, _, p in anchors]) if anchors else None
        if not spot or not spot[3]:
            skipped.append("%s line %d: level %d, %.2f short - no dense non-elite spawns near the last steps" % (gid, k + 1, need, short))
            continue
        score, order, (cx, cy), names, count = spot
        after = anchors[order][1]
        # the model level just after the anchor: the closest recorded step after it
        later = [ln for ln in levels if after + 1 < ln <= k + 1]
        base = levels[min(later)] if later else arrive
        gain = max(0.0, arrive - base)
        target = need - gain
        tenth = math.ceil(target * 10 - 1e-6) / 10.0
        if tenth >= need - 0.05:
            lvl_txt, what = str(need), "level %d" % need
        else:
            lvl_txt = "%.1f" % tenth
            if lvl_txt.endswith(".0"):
                lvl_txt = lvl_txt[:-2]
                what = "level %s" % lvl_txt
            else:
                what = "%d%% through level %d" % (round((tenth % 1) * 100), int(tenth))
        nxt = re.search(r"\|\s*(.+?) starts at \d+", l)
        why = ("%s starts at %d" % (nxt.group(1), need)) if nxt else ("The next steps expect level %d" % need)
        if lvl_txt == str(need):
            text = "%s and the quests here don't quite get you there: grind these until you reach it." % why
        else:
            text = "%s: grind these to %s, and the quests left here bring you the rest of the way." % (why, what)
        step = "grind %s %s [at=%.1f,%.1f] | %s" % (lvl_txt, ", ".join(names), cx, cy, text)
        if lvl_txt == str(need):
            inserts.append((k, step, True))
            report.append("%s: %.2f short of %d -> replaces line %d: %s (%d spawns)" % (gid, short, need, k + 1, step.split(" |")[0], count))
        else:
            inserts.append((after, step, False))
            report.append("%s: %.2f short of %d -> after line %d: %s (%d spawns)" % (gid, short, need, after + 1, step.split(" |")[0], count))
    if inserts and not DRY:
        for at, step, replace in sorted(inserts, reverse=True):
            if replace:
                lines[at] = step
            else:
                lines.insert(at + 1, step)
        open(g["file"], "w", encoding="utf-8", newline="").write(nl.join(lines))

for r in report:
    print(r)
print("grind steps: %d (shortfall >= %.2f levels)" % (len(report), MIN_SHORT))
for s in skipped:
    print("  skipped:", s)
