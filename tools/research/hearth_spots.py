# List the places where a guide walks back to town from the field, and whether the step window's hearthstone
# suggestion (Core/Hearth.lua) or death-skip suggestion (Core/DeathSkip.lua) would show there.
# Read-only; it changes nothing.
# Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
# SPDX-License-Identifier: GPL-3.0-only
#
# For every town step that follows a complete step: where you stand is the middle of that complete step's
# objective spots in the town's zone (or the last step with a position). The town run is that step and the ones
# right after it within TOWN_YARDS of the inn the route last set the hearthstone at (a "bind" step, carried from
# guide to guide in the faction's order). Times use the add-on's rules: straight line x PATH_FACTOR at RUN_SPEED,
# the hearth costs CAST + LOAD seconds plus the walk from the inn; a death skip costs DEATH seconds plus the walk
# from the zone's spirit healer nearest to you. The hearthstone cooldown and Hardcore are not modelled.
# Usage: python -I tools/research/hearth_spots.py <Target> [--min SECONDS]
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from qdb import Target, centroid, f, hsh, ids  # noqa: E402

RUN_SPEED, PATH_FACTOR, CAST, LOAD, DEATH = 7.0, 1.25, 10, 5, 45
TOWN_YARDS = 250
TOWN_KINDS = {"turnin", "accept", "train", "buy", "bind", "fp", "talk", "vendor", "repair"}
args = [a for a in sys.argv[1:] if not a.startswith("--")]
MIN_SHOW = 60
if "--min" in sys.argv:
    MIN_SHOW = int(sys.argv[sys.argv.index("--min") + 1])
T = Target(args[0] if args else "ClassicEra")


def spots(qid, zone):
    """Points of the quest's objectives in the zone: kill targets, item droppers, objects."""
    q = T.Q.get(qid)
    if not q:
        return []
    obj = hsh(f(q, 12))
    mobs = set(ids(obj.get("c")) + ids(obj.get("k")))
    objs = set(ids(obj.get("o")))
    for it in ids(obj.get("i")):
        if T.I.get(it):
            mobs |= set(ids(T.I[it][1]))
            objs |= set(ids(T.I[it][2]))
    return [p for n in mobs for p in T.npc_pts(n, zone)] + [p for o in objs for p in T.obj_pts(o, zone)]


def load_geo():
    geo = {}
    p = os.path.join(T.dir, "addon", "Database", "ZoneGeo.lua")
    for m in re.finditer(r"\[(\d+)\] = \{ (\d+), ([-\d.]+), ([-\d.]+), ([-\d.]+), ([-\d.]+) \}", open(p, encoding="utf-8").read()):
        geo[int(m.group(1))] = (int(m.group(2)),) + tuple(float(m.group(i)) for i in range(3, 7))
    return geo


def load_healers():
    out = {}
    p = os.path.join(T.qdir, "SpiritHealers.lua")
    # one line: [zone]={{x,y},{x,y}},...
    for m in re.finditer(r"\[(\d+)\]=\{((?:\{[-\d.]+,[-\d.]+\},?)*)\}", open(p, encoding="utf-8").read()):
        out[int(m.group(1))] = [(float(a), float(b)) for a, b in re.findall(r"\{([-\d.]+),([-\d.]+)\}", m.group(2))]
    return out


GEO, HEALERS = load_geo(), load_healers()


def world(z, x, y):
    g = GEO.get(z)
    if not g:
        return None
    c, minx, miny, maxx, maxy = g
    # zone map x runs along -Y, y along -X
    return (c, maxy - x / 100.0 * (maxy - miny), maxx - y / 100.0 * (maxx - minx))


def yards(a, b):
    if not (a and b) or a[0] != b[0]:
        return None
    return ((a[1] - b[1]) ** 2 + (a[2] - b[2]) ** 2) ** 0.5


def walk(d):
    return d * PATH_FACTOR / RUN_SPEED


def needed(turnins, worth, floor):
    return max(floor, worth / turnins) if turnins else float("inf")


def faction_order(fac):
    return sorted((g for g in T.guides.values() if g["faction"] == fac and g["file"]), key=lambda g: os.path.basename(g["file"]))


def run(fac):
    inn = None
    rows = []
    for g in faction_order(fac):
        steps = g["steps"]
        here = None
        for i, s in enumerate(steps):
            if s["kind"] == "bind" and s["z"] is not None:
                inn = (s["z"], world(s["z"], s["x"], s["y"]))
            if s["kind"] in ("hs", "fly", "boat", "zeppelin", "portal"):
                here = None
                continue
            if s["kind"] == "complete" and s["q"]:
                pts = spots(s["q"], s["z"] or g["zone"])
                c = centroid(pts) if pts else None
                if c:
                    here = (s["z"] or g["zone"], c)
                continue
            if s["kind"] not in TOWN_KINDS or s["z"] is None:
                if s["z"] is not None:
                    here = (s["z"], (s["x"], s["y"]))
                continue
            prev = steps[i - 1] if i else None
            p = world(s["z"], s["x"], s["y"])
            if prev and prev["kind"] == "complete" and here and inn and yards(p, inn[1]) is not None and yards(p, inn[1]) <= TOWN_YARDS:
                me = world(here[0], here[1][0], here[1][1])
                d = yards(me, p)
                if d is not None:
                    # the town run: this step and the following ones near the inn
                    turnins, n = 0, 0
                    for t in steps[i:i + 16]:
                        if t["kind"] == "hs" or t["z"] is None:
                            break
                        dt = yards(world(t["z"], t["x"], t["y"]), inn[1])
                        if dt is None or dt > TOWN_YARDS:
                            break
                        n += 1
                        if t["kind"] == "turnin":
                            turnins += 1
                    hearth = CAST + LOAD + walk(yards(inn[1], p) or 0)
                    saved = walk(d) - hearth
                    hz = HEALERS.get(here[0], [])
                    hp = [world(here[0], x, y) for x, y in hz]
                    hp = [w for w in hp if w and yards(w, me) is not None]
                    dskip = None
                    if hp:
                        near = min(hp, key=lambda w: yards(w, me))
                        dg = yards(near, p)
                        if dg is not None and dg < d:
                            dskip = walk(d) - DEATH - walk(dg)
                    rows.append(dict(gid=g["id"], step=i + 1, kind=s["kind"], q=s["q"], yards=d, walk=walk(d), saved=saved,
                                     turnins=turnins, n=n, dskip=dskip))
            here = (s["z"], (s["x"], s["y"]))
    return rows


for fac in ("Horde", "Alliance"):
    print("== %s ==" % fac)
    for r in run(fac):
        if r["saved"] < MIN_SHOW and (r["dskip"] or 0) < MIN_SHOW:
            continue
        old = r["saved"] >= needed(r["turnins"], 300, 60)
        new = r["saved"] >= needed(r["turnins"], 180, 60)
        q = T.Q.get(r["q"]) if r["q"] else None
        print("%-34s step %3d %-7s %-34s walk %4.0f yd %3.0fs  hearth saves %4.0fs (%d turn-ins) %s%s  death skip %s" % (
            r["gid"], r["step"], r["kind"], (q[0] if q else "")[:34], r["yards"], r["walk"], r["saved"], r["turnins"],
            "OLD" if old else "   ", " NEW" if new and not old else ("    " if not new else " NEW"),
            ("%4.0fs" % r["dskip"]) if r["dskip"] is not None else "  -"))


# Second report (--hubs): long walks back to a town the hearthstone is not set to. Town steps are grouped into
# hubs (within TOWN_YARDS of the hub's first step); a hub with many long returns is a place to set the hearthstone.
def hubs(fac, long_s=120):
    inn = None
    out = []
    for g in faction_order(fac):
        steps = g["steps"]
        here = None
        groups = []
        for i, s in enumerate(steps):
            if s["kind"] == "bind" and s["z"] is not None:
                inn = (s["z"], world(s["z"], s["x"], s["y"]))
            if s["kind"] in ("hs", "fly", "boat", "zeppelin", "portal"):
                here = None
                continue
            if s["kind"] == "complete" and s["q"]:
                pts = spots(s["q"], s["z"] or g["zone"])
                c = centroid(pts) if pts else None
                if c:
                    here = (s["z"] or g["zone"], c)
                continue
            if s["z"] is None:
                continue
            p = world(s["z"], s["x"], s["y"])
            prev = steps[i - 1] if i else None
            if s["kind"] in TOWN_KINDS and prev and prev["kind"] == "complete" and here:
                d = yards(world(here[0], here[1][0], here[1][1]), p)
                bound = inn and yards(p, inn[1]) is not None and yards(p, inn[1]) <= TOWN_YARDS
                if d is not None and walk(d) >= long_s and not bound:
                    for grp in groups:
                        if yards(grp["p"], p) is not None and yards(grp["p"], p) <= TOWN_YARDS:
                            grp["n"] += 1
                            grp["secs"] += walk(d)
                            break
                    else:
                        groups.append(dict(p=p, z=s["z"], x=s["x"], y=s["y"], n=1, secs=walk(d), step=i + 1))
            here = (s["z"], (s["x"], s["y"]))
        for grp in groups:
            out.append((g["id"], grp))
    return out


if "--hubs" in sys.argv:
    for fac in ("Horde", "Alliance"):
        print("== %s: long walks back to towns the hearthstone is not set to ==" % fac)
        for gid, grp in hubs(fac):
            if grp["n"] >= 2:
                print("%-34s zone %4d at %5.1f,%5.1f (first step %3d): %d returns, %4.0f s walking" % (
                    gid, grp["z"], grp["x"], grp["y"], grp["step"], grp["n"], grp["secs"]))


def innkeepers():
    """{zone: [(name, x, y, friendlyTo)]} of NPCs whose subname is Innkeeper (raw QuestieDB)."""
    out = {}
    q = T.info["questie"]
    path = os.path.join(os.path.dirname(T.dir), "..", ".cache", "upstream", "questiedb", q["dataDir"], q["prefix"] + "NpcDB.lua")
    from qdb import arr, parse_lua
    on = False
    for line in open(os.path.normpath(path), encoding="utf-8"):
        if not on:
            on = "QuestieDB.npcData" in line
            continue
        if "Innkeeper" not in line:
            continue
        m = re.match(r"^\[(\d+)\] = (\{.*\}),\s*$", line)
        if not m:
            continue
        try:
            v = arr(parse_lua(m.group(2)))
        except Exception:
            continue
        if len(v) < 14 or v[13] != "Innkeeper":
            continue
        sp = hsh(v[6]) if v[6] else {}
        for z, pts in sp.items():
            for p in arr(pts):
                p = arr(p)
                out.setdefault(int(z), []).append((v[0], p[0], p[1], v[12] or ""))
    return out


if "--inns" in sys.argv:
    INNS = innkeepers()
    for fac in ("Horde", "Alliance"):
        side = "H" if fac == "Horde" else "A"
        print("== %s: hubs with an inn ==" % fac)
        for gid, grp in hubs(fac):
            best = None
            for name, x, y, fr in INNS.get(grp["z"], []):
                if side not in fr:
                    continue
                d = yards(world(grp["z"], x, y), grp["p"])
                if d is not None and d <= 400 and (best is None or d < best[0]):
                    best = (d, name, x, y)
            print("%-30s zone %4d at %5.1f,%5.1f step %3d: %d returns %4.0f s | %s" % (
                gid, grp["z"], grp["x"], grp["y"], grp["step"], grp["n"], grp["secs"],
                ("%s %.1f,%.1f (%.0f yd)" % (best[1], best[2], best[3], best[0])) if best else "no inn"))
