"""Kill-pack spot audit (docs/ROAMING.md, "Kill packs").

For every kill pack in the compiled guides (steps with pack=<first step>), finds the spot where the mobs of all
its steps meet, the same way the add-on does (Core/Roam.lua, R.PackSpot): the known spawn with mobs of the most
steps within PACK_SPOT map percent, then the most of the step with the fewest there, then the most in all. Then it checks the
hunting routes (Guides/Compiled/Routes.lua) of the pack's quests: a route that never comes within PACK_NEAR map
percent of the spot is not used for that step in game (the arrow shows the spot, or the nearest spawn), and is
listed here so the route can be redrawn. Packs with no spot that has mobs of every step near it are listed too
(the arrow then uses the spot shared by the most steps).

Writes docs/generated/<Target>/kill-pack-spots.csv and prints a summary. Run after `tools/build.ps1 guides`.

usage: python -I tools/research/pack_spots.py <Target> [--strict]    (--strict: exit 1 when a route is far)
"""
import collections
import csv
import glob
import math
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from qdb import ROOT, Target, arr, f, hsh, ids  # noqa: E402

PACK_SPOT = 4   # map percent, Core/Roam.lua
PACK_NEAR = 8   # map percent, Core/Roam.lua (the compiler's PackRadius)
GAP = 3         # DB.QuestItemDroppers' DROPPER_LEVEL_GAP


def droppers(T, item, lvl):
    drops = ids(T.I[item][1]) if T.I.get(item) else []
    fit = [n for n in drops if T.N.get(n) and (T.N[n][3] or 0) == 0 and (lvl <= 0 or (T.N[n][1] or 0) <= lvl + GAP)]
    return fit or drops


def spawns(T, q, zone):
    """DB.ObjectiveSpawns: every spawn in zone of the quest's objectives."""
    rec = T.Q.get(q)
    if not rec:
        return []
    o, lvl, pts = hsh(f(rec, 12)), f(rec, 3) or 0, []
    for n in ids(o.get("c")) + ids(o.get("k")):
        pts += T.npc_pts(n, zone)
    for ob in ids(o.get("o")):
        pts += T.obj_pts(ob, zone)
    for it in ids(o.get("i")):
        for n in droppers(T, it, lvl):
            pts += T.npc_pts(n, zone)
        for ob in (ids(T.I[it][2]) if T.I.get(it) else []):
            pts += T.obj_pts(ob, zone)
    return pts


def pack_spot(lists):
    """R.PackSpot: (x, y, steps, fewest, total) or None."""
    if len(lists) < 2:
        return None
    grid = collections.defaultdict(list)
    for li, l in enumerate(lists):
        for p in l:
            grid[(math.floor(p[0] / PACK_SPOT), math.floor(p[1] / PACK_SPOT))].append((p, li))
    best = None
    for l in lists:
        for c in l:
            n = collections.Counter()
            gx, gy = math.floor(c[0] / PACK_SPOT), math.floor(c[1] / PACK_SPOT)
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    for p, li in grid.get((gx + dx, gy + dy), ()):
                        if (p[0] - c[0]) ** 2 + (p[1] - c[1]) ** 2 <= PACK_SPOT ** 2:
                            n[li] += 1
            s = (len(n), min(n.values()), sum(n.values()))
            if best is None or s > best[2:]:
                best = (c[0], c[1]) + s
    return best if best and best[2] >= 2 else None


def compiled_packs(T):
    """{guide id: [(pack, [(step, quest, title)])]} from the compiled guides."""
    out = {}
    for p in glob.glob(os.path.join(T.dir, "addon", "Guides", "Compiled", "*.lua")):
        t = open(p, encoding="utf-8").read()
        m = re.search(r'id="([^"]+)"', t)
        if not m:
            continue
        packs = collections.OrderedDict()
        for i, sm in enumerate(re.finditer(r'^    \{"(\w+)"(.*)\},\s*$', t, re.M), 1):
            body = sm.group(2)
            pk, q = re.search(r"\bpack=(\d+)", body), re.search(r"\bq=(\d+)", body)
            if sm.group(1) == "complete" and pk and q:
                title = re.search(r'\btitle="((?:[^"\\]|\\.)*)"', body)
                packs.setdefault(int(pk.group(1)), []).append((i, int(q.group(1)), title.group(1) if title else ""))
        if packs:
            out[m.group(1)] = list(packs.items())
    return out


def routes(T):
    """{quest: [(name, zone, [(x, y)])]} from Routes.lua."""
    p = os.path.join(T.dir, "addon", "Guides", "Compiled", "Routes.lua")
    out = collections.defaultdict(list)
    if not os.path.exists(p):
        return out
    t = open(p, encoding="utf-8").read()
    for qm in re.finditer(r"^  \[(\d+)\] = \{(.*?)^  \},", t, re.M | re.S):
        for rm in re.finditer(r'\{ name="((?:[^"\\]|\\.)*)", zone=(\d+).*?pts=\{(.*?)\}\s*\}', qm.group(2), re.S):
            pts = [(float(x), float(y)) for x, y in re.findall(r"\{(-?[\d.]+),(-?[\d.]+)", rm.group(3))]
            out[int(qm.group(1))].append((rm.group(1), int(rm.group(2)), pts))
    return out


def main():
    target = sys.argv[1] if len(sys.argv) > 1 and not sys.argv[1].startswith("-") else "ClassicEra"
    strict = "--strict" in sys.argv
    T = Target(target)
    R = routes(T)
    rows, far, apart, partial, n = [], [], [], [], 0
    for gid, packs in sorted(compiled_packs(T).items()):
        zone = T.guides[gid]["zone"] if gid in T.guides else None
        for first, steps in packs:
            n += 1
            # The pack's zone: the guide's, else the zone with the most spawns of its steps.
            zones = collections.Counter()
            for _, q, _ in steps:
                rec = T.Q.get(q)
                for n_ in (ids(hsh(f(rec, 12)).get("c")) if rec else []):
                    for z in hsh(T.N[n_][5]).keys() if T.N.get(n_) else []:
                        zones[z] += 1
            zs = [zone] + [z for z, _ in zones.most_common()] if zone else [z for z, _ in zones.most_common()]
            spot, lists, pz = None, [], None
            for z in zs:
                lists = [l for l in (spawns(T, q, z) for _, q, _ in steps) if l]
                spot = pack_spot(lists)
                if spot:
                    pz = z
                    break
            titles = " + ".join(t for _, _, t in steps)
            if not spot:
                apart.append("%s step %d: %s" % (gid, first, titles))
                rows.append(dict(guide=gid, pack=first, quests=titles, zone="", x="", y="", steps=0, fewest=0, total=0,
                                 route="", route_zone="", nearest="", verdict="no spot where two of its steps' mobs meet: each step keeps its own waypoint"))
                continue
            x, y, nsteps, fewest, total = spot
            if nsteps < len(lists):
                partial.append("%s step %d: %d of %d steps at %.1f, %.1f (%s)" % (gid, first, nsteps, len(lists), x, y, titles))
            base = dict(guide=gid, pack=first, quests=titles, zone=pz, x="%.2f" % x, y="%.2f" % y, steps=nsteps, fewest=fewest, total=total)
            had = False
            for _, q, _ in steps:
                for name, rz, pts in R.get(q, []):
                    had = True
                    d = min(math.hypot(px - x, py - y) for px, py in pts) if rz == pz and pts else None
                    ok = d is not None and d <= PACK_NEAR
                    verdict = "used" if ok else "not used for this pack: far from the spot"
                    if not ok:
                        far.append("%s step %d (%s): route '%s' %s" % (gid, first, titles, name,
                                   "%.1f map %% from %.1f, %.1f" % (d, x, y) if d is not None else "in another zone"))
                    rows.append(dict(base, route=name, route_zone=rz, nearest="%.1f" % d if d is not None else "", verdict=verdict))
            if not had:
                rows.append(dict(base, route="", route_zone="", nearest="", verdict="no hunting route"))
    out = os.path.join(ROOT, "docs", "generated", target, "kill-pack-spots.csv")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=["guide", "pack", "quests", "zone", "x", "y", "steps", "fewest", "total", "route", "route_zone", "nearest", "verdict"])
        w.writeheader()
        w.writerows(rows)
    print("%s: %d kill packs, %d hunting routes far from their pack's spot, %d packs whose spot misses a step, %d without a shared spot"
          % (target, n, len(far), len(partial), len(apart)))
    for line in far:
        print("  far    " + line)
    for line in partial:
        print("  part   " + line)
    for line in apart:
        print("  apart  " + line)
    print("Wrote " + os.path.relpath(out, ROOT))
    if strict and far:
        sys.exit(1)


if __name__ == "__main__":
    main()
