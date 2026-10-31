# Put a "fly" step before each zone visit's "travel" step when the route can fly there (docs/GUIDE_FORMAT.md).
# Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
# SPDX-License-Identifier: GPL-3.0-only
#
# Walks each faction's zone-order visits (guides A_NN_* / H_NN_*, NN >= 10, in order; the start-zone guides are
# race-specific, so their flight paths are not counted). A flight path counts as learned once an fp step every
# character takes (no class, race, optional, elite, dungeon or Hardcore flag) has come before. At a visit that
# starts with "travel <zone>", the fly step is added when:
#   - the previous visit ended in another zone, and that zone has a learned flight path;
#   - the new zone has a learned flight path (the one nearest the visit's first located step);
#   - learned flight paths connect the two (Database/Flights.lua).
# The route audit then checks every race/class route again. Writes guide sources: run guides + routes after.
# Usage: python tools/research/fly_steps.py ClassicEra [--dry-run]
import collections
import math
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from qdb import Target  # noqa: E402

T = Target(sys.argv[1] if len(sys.argv) > 1 else "ClassicEra")
DRY = "--dry-run" in sys.argv

NODES, LINKS = {}, {}
for line in open(os.path.join(T.dir, "addon", "Database", "Flights.lua"), encoding="utf-8"):
    m = re.match(r'^N\[(\d+)\]=\{name="([^"]*)",full="([^"]*)",zone=(\d+),x=([\d.]+),y=([\d.]+),faction="(\w+)"', line)
    if m:
        NODES[int(m.group(1))] = dict(id=int(m.group(1)), name=m.group(2), zone=int(m.group(4)),
                                      x=float(m.group(5)), y=float(m.group(6)), faction=m.group(7))
    m = re.match(r"^L\[(\d+)\]=\{([\d,]*)\}", line)
    if m:
        LINKS[int(m.group(1))] = [int(x) for x in m.group(2).split(",") if x]

PARENT = {}
for a, b in re.findall(r"^\[(\d+)\]=(\d+),$", open(os.path.join(T.qdir, "Zones.lua"), encoding="utf-8").read().split("Z.parent")[1], re.M):
    PARENT[int(a)] = int(b)


def top(z):
    return PARENT.get(z, z)


def fp_nodes(gid):
    """Flight nodes of a compiled guide's fp steps that every character takes."""
    t = open(os.path.join(T.dir, "addon", "Guides", "Compiled", COMPILED[gid]), encoding="utf-8").read()
    out = []
    for m in re.finditer(r'^    \{"fp"(.*)\},\s*$', t, re.M):
        body = m.group(1)
        n = re.search(r"\bnode=(\d+)", body)
        if n and not re.search(r"\b(classes|races)=|\b(optional|hcSkip|hcOnly|elite)=true|\bdungeon=", body):
            out.append(int(n.group(1)))
    return out


COMPILED = {}
for fn in os.listdir(os.path.join(T.dir, "addon", "Guides", "Compiled")):
    if fn.endswith(".lua"):
        m = re.search(r'id="([^"]+)"', open(os.path.join(T.dir, "addon", "Guides", "Compiled", fn), encoding="utf-8").read(2000))
        if m:
            COMPILED[m.group(1)] = fn


def reachable(learned, a, b):
    seen, q = {a}, collections.deque([a])
    while q:
        n = q.popleft()
        if n == b:
            return True
        for m in LINKS.get(n, ()):
            if m in learned and m not in seen:
                seen.add(m)
                q.append(m)
    return False


def nearest(cands, pt):
    if not pt:
        return cands[0]
    return min(cands, key=lambda n: math.hypot(n["x"] - pt[0], n["y"] - pt[1]))


added = 0
for fac, pre in (("Alliance", "A"), ("Horde", "H")):
    fc = fac[0]
    visits = sorted((gid for gid in T.guides if re.match(r"^%s_(\d\d)_" % pre, gid) and int(gid[2:4]) >= 10), key=lambda g: int(g[2:4]))
    learned = set()
    prev = None
    for gid in visits:
        g = T.guides[gid]
        located = [s for s in g["steps"] if s["z"] and s["x"] is not None]
        if prev and g["file"]:
            src = open(g["file"], encoding="utf-8", newline="").read()
            nl = "\r\n" if "\r\n" in src else "\n"
            lines = src.split(nl)
            ti = next((i for i, l in enumerate(lines) if re.match(r"^(travel|fly|accept|turnin|complete|goto|fp|train)\b", l)), None)
            plast = [s for s in T.guides[prev]["steps"] if s["z"] and s["x"] is not None]
            if ti is not None and lines[ti].startswith("travel ") and "[" not in lines[ti] and plast and \
                    not (ti > 0 and lines[ti - 1].startswith("fly ")):
                oz, dz = plast[-1]["z"], g["zone"]
                mine = [NODES[n] for n in learned if fc in NODES[n]["faction"]]
                dest = [n for n in mine if top(n["zone"]) == top(dz) or n["zone"] == dz]
                orig = [n for n in mine if top(n["zone"]) == top(oz) or n["zone"] == oz]
                if top(oz) != top(dz) and dest and orig:
                    d = nearest(dest, (located[0]["x"], located[0]["y"]) if located else None)
                    o = nearest(orig, (plast[-1]["x"], plast[-1]["y"]))
                    if d["id"] != o["id"] and reachable(learned, o["id"], d["id"]):
                        lines.insert(ti, "fly %s | Take the flight from %s." % (d["name"], o["name"]))
                        added += 1
                        print("%s: fly %s (from %s)" % (gid, d["name"], o["name"]))
                        if not DRY:
                            open(g["file"], "w", encoding="utf-8", newline="").write(nl.join(lines))
        learned |= set(fp_nodes(gid))
        prev = gid
print("%d fly steps %s" % (added, "found (dry run)" if DRY else "added"))
