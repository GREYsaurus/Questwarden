# Add dungeon quests whose giver or finisher is outside the guide's zone (cities, neighbouring zones),
# across a faction's guides (docs/ROUTE_OPTIMIZATION.md).
# Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
# SPDX-License-Identifier: GPL-3.0-only
#
# group_insert.py only takes quests given and ended in the guide's own zone. Routes also pass through cities
# and neighbouring zones (every compiled step carries its own map zone), so here every step with a location
# is a possible anchor, whatever the guide's zone; inside a capital any step counts (a city is one short walk).
# Guides follow their @next links: a faction's paths run from each start guide, so a quest picked up in one
# race's start zone is never turned in in another's. A quest qualifies when it is unused, open to the faction,
# has XP, is not a class/profession/reputation/repeatable/escort quest, not excluded, and ALL its objectives
# are inside one dungeon (never a raid or a Season of Discovery instance). Unused talk-only lead-ins to such a
# quest (no objectives; given and ended by someone outdoors) come with it, tagged with the same dungeon.
# Placement, in prerequisite order (several passes, so chains follow on):
#   accept  - first guide by level whose band meets the quest (required level <= band max + 1, quest level >=
#             band min - 2), after every prerequisite on every path into it, at a step near the giver where
#             the model level meets the required level;
#   turnin  - the last step near the finisher in that guide, or the first one in the next MAX_SPAN guides
#             along @next, as long as every path into that guide passes the pickup guide;
#   complete- just before the turn-in (not for lead-ins).
# Every step is [dungeon=<instance>] (off unless "Include Dungeon Quests" is on); steps in a later guide than
# the accept are [optional]; shared guides get [faction=...]. At most MAX_PER new quests per guide.
# Writes guide sources. Run guides + routes afterwards.
# Usage: python tools/research/dungeon_cross.py ClassicEra [--dry-run]
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from qdb import Target, VERB_RE, centroid, dist, f, hsh, ids  # noqa: E402

args = [x for x in sys.argv[1:] if not x.startswith("--")]
T = Target(args[0] if args else "ClassicEra")
DRY = "--dry-run" in sys.argv
MAX_PER, MAX_SPAN, NEAR = 6, 2, 6.0
EXCLUDE = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "quest_exclude.json"), encoding="utf-8")).get(T.name, {})
MASK = {"Alliance": 77, "Horde": 178}

names = {}
for line in open(os.path.join(T.qdir, "Zones.lua"), encoding="utf-8"):
    for m in re.finditer(r'\[(\d+)\]="((?:[^"\\]|\\.)*)"', line):
        names[int(m.group(1))] = m.group(2)
CITY = {z for z, n in names.items() if n in ("Stormwind City", "Ironforge", "Darnassus", "Orgrimmar", "Thunder Bluff", "Undercity")}


def inst(z):
    n = names.get(z, "")
    if "SoD" in n or "Raid" in n:
        return None
    if " - Dungeon" in n or "Scholomance" in n:
        return n.split(" - ")[0].strip()
    if "(fake ID for " in n:
        return n.split("(fake ID for ", 1)[1].rstrip(")").strip()
    return None


def obj_zones(r):
    return set(hsh(r[2]).keys()) or ({r[1]} if r[1] else set())


def dungeon_of(q):
    """Instance holding ALL objective places, or None."""
    zones = set()
    obj = hsh(f(q, 12))
    for n in ids(obj.get("c")) + ids(obj.get("k")):
        r = T.N.get(n)
        zones |= set(hsh(r[5]).keys()) if r else set()
    for o in ids(obj.get("o")):
        r = T.O.get(o)
        zones |= obj_zones(r) if r else set()
    for it in ids(obj.get("i")):
        ir = T.I.get(it)
        if not ir:
            continue
        for n in ids(ir[1]):
            r = T.N.get(n)
            zones |= set(hsh(r[5]).keys()) if r else set()
        for o in ids(ir[2]):
            r = T.O.get(o)
            zones |= obj_zones(r) if r else set()
    zones = {z for z in zones if isinstance(z, int)}
    if not zones:
        return None
    ins = {inst(z) for z in zones}
    if None in ins or len(ins) != 1:
        return None
    return ins.pop()


def places(npcs, objs):
    out = {}
    for n in npcs:
        r = T.N.get(n)
        for z in (hsh(r[5]).keys() if r else []):
            out.setdefault(z, []).extend(T.npc_pts(n, z))
    for o in objs:
        r = T.O.get(o)
        for z in (hsh(r[2]).keys() if r else []):
            out.setdefault(z, []).extend(T.obj_pts(o, z))
    return {z: centroid(p) for z, p in out.items() if p}


def near(an, pts):
    return an[1] in pts and (an[1] in CITY or dist(an[2], pts[an[1]]) <= NEAR)


def plain(q):
    """Not a class, profession, reputation, repeatable or escort quest."""
    return not ((f(q, 5) or 0) or f(q, 22) or f(q, 23) or ((f(q, 19) or 0) & 1) or (f(q, 26) or 0) == 2)


# Guides with aligned source lines; anchors = every located quest step every character of the faction takes
# (any map zone; not class/race-filtered, optional, Hardcore-flagged, elite or dungeon).
G = {}
for gid, g in T.guides.items():
    if not g["file"]:
        continue
    src = open(g["file"], encoding="utf-8", newline="").read()
    lines = src.replace("\r\n", "\n").split("\n")
    src_q = [i for i, l in enumerate(lines) if VERB_RE.match(l)]
    cq = [s for s in g["steps"] if s["kind"] in ("accept", "turnin", "complete")]
    if len(src_q) != len(cq):
        continue
    anchors = [(src_q[k], s["z"], (s["x"], s["y"])) for k, s in enumerate(cq) if s["x"] is not None and not s["filtered"] and not s["opt"]]
    G[gid] = dict(g, lines=lines, nl="\r\n" if "\r\n" in src else "\n", anchors=anchors, inserts=[], added=0,
                  turn={s["q"]: src_q[k] for k, s in enumerate(cq) if s["kind"] == "turnin" and s["q"]})

# @next links per faction.
NEXT = {}
for g in G.values():
    for line in g["lines"]:
        m = re.match(r"^@next\s+(\S+)(?:\s*\[faction=(\w+)\])?", line)
        if m:
            for fac in ([m.group(2)] if m.group(2) else ["Alliance", "Horde"]):
                NEXT.setdefault(g["id"], {})[fac] = m.group(1)

used = {s["q"] for g in T.guides.values() for s in g["steps"] if s["q"]}
pool = {}
for qid, q in T.Q.items():
    if qid in used or str(qid) in EXCLUDE or not T.xp.get(qid) or not plain(q):
        continue
    lvl = f(q, 3) or 0
    if lvl <= 0 or lvl > 60:
        continue
    d = dungeon_of(q)
    if not d:
        continue
    giv = places(ids(f(q, 6)), ids(f(q, 7)))
    fin = places(ids(f(q, 9)), ids(f(q, 10)))
    if giv and fin:
        pool[qid] = dict(q=q, d=d, giv=giv, fin=fin, lead=False)
print("dungeon quests with outdoor giver and finisher, not on any route:", len(pool))


def lead_ins(qid, d, depth=0):
    """Unused talk-only prerequisites of a pool quest, recursively (a short breadcrumb chain)."""
    if depth > 4:
        return
    for x in ids(f(T.Q[qid], 13)) + ids(f(T.Q[qid], 14)):
        r = T.Q.get(x)
        if not r or x in used or x in pool or str(x) in EXCLUDE or not T.xp.get(x) or f(r, 12) or not plain(r):
            continue
        giv = places(ids(f(r, 6)), ids(f(r, 7)))
        fin = places(ids(f(r, 9)), ids(f(r, 10)))
        if giv and fin and not any(inst(z) for z in list(giv) + list(fin)):
            pool[x] = dict(q=r, d=d, giv=giv, fin=fin, lead=True)
            lead_ins(x, d, depth + 1)


for qid in [k for k, v in pool.items() if not v["lead"]]:
    lead_ins(qid, pool[qid]["d"])
print("with talk-only lead-ins:", len(pool))

report = []
for fac in ("Alliance", "Horde"):
    mine = {g["id"]: g for g in G.values() if g["faction"] in (fac, "Both")}
    pointed = {NEXT[x][fac] for x in mine if fac in NEXT.get(x, {})}
    paths = []
    for st in sorted(x for x in mine if x not in pointed and mine[x]["faction"] != "Both"):
        path, cur = [], st
        while cur in mine and cur not in path:
            path.append(cur)
            cur = NEXT.get(cur, {}).get(fac)
        paths.append(path)
    dom = {}  # guides before this one on every path into it
    for path in paths:
        for i, x in enumerate(path):
            dom[x] = set(path[:i]) if x not in dom else dom[x] & set(path[:i])
    seq = sorted([mine[x] for x in dom], key=lambda g: (g["min"], g["max"], g["id"]))
    done = {}
    for g in seq:
        for qid, ln in g["turn"].items():
            done.setdefault(qid, []).append((g["id"], ln))

    def before(pos, gid, ln):
        return any(p[0] in dom[gid] or (p[0] == gid and p[1] < ln) for p in pos)

    todo = [x for x in pool if not (f(pool[x]["q"], 4) or 0) or (f(pool[x]["q"], 4) & MASK[fac])]
    progress = True
    while progress:
        progress = False
        for qid in sorted(todo, key=lambda x: (f(pool[x]["q"], 2) or 0, x)):
            p = pool[qid]
            q = p["q"]
            req, lvl = f(q, 2) or 0, f(q, 3) or 0
            pg, ps = ids(f(q, 13)), ids(f(q, 14))
            if not all(x in done for x in pg) or (ps and not any(x in done for x in ps)):
                continue
            a = None
            for g in seq:
                if g["added"] >= MAX_PER or req > g["max"] + 1 or lvl < g["min"] - 2:
                    continue
                cand = [an for an in g["anchors"] if near(an, p["giv"])
                        and all(before(done[x], g["id"], an[0]) for x in pg)
                        and (not ps or any(x in done and before(done[x], g["id"], an[0]) for x in ps))
                        and (T.level_at(g["file"], an[0]) or 0) + 0.25 >= req]
                if cand:
                    a = (g["id"], cand[0][0])
                    break
            if not a:
                continue
            t = None
            here = [an for an in mine[a[0]]["anchors"] if an[0] > a[1] and near(an, p["fin"])]
            if here:
                t = (a[0], here[-1][0])
            else:
                cur = a[0]
                for _ in range(MAX_SPAN):
                    cur = NEXT.get(cur, {}).get(fac)
                    if cur not in mine or a[0] not in dom[cur]:  # every path into it must pass the pickup
                        break
                    later = [an for an in mine[cur]["anchors"] if near(an, p["fin"])]
                    if later:
                        t = (cur, later[0][0])
                        break
            if not t:
                continue
            steps = ((a, 0, "accept"), (t, 2, "turnin")) if p["lead"] else ((a, 0, "accept"), (t, 1, "complete"), (t, 2, "turnin"))
            for (gid, ln), order, verb in steps:
                gg = mine[gid]
                flags = ["dungeon=" + p["d"]]
                if gg["faction"] == "Both":
                    flags.append("faction=" + fac)
                if verb != "accept" and gid != a[0]:
                    flags.append("optional")
                gg["inserts"].append((ln, order, "%s %d %s [%s]" % (verb, qid, q[0], "; ".join(flags))))
            if not p["lead"]:
                mine[a[0]]["added"] += 1
            done[qid] = [t]
            todo.remove(qid)
            progress = True
            report.append((fac, qid, "%s: %d %s (%d XP) - %s%s; pick up in %s, turn in in %s" % (
                fac, qid, q[0], T.xp[qid], p["d"], " lead-in" if p["lead"] else "", a[0], t[0])))

# A lead-in nothing follows on from is dropped (it only made sense as the way into its dungeon quest).
kept = {(fac, qid) for fac, qid, _ in report if not pool[qid]["lead"]}
changed = True
while changed:
    changed = False
    for fac, qid, _ in report:
        if (fac, qid) in kept:
            continue
        if any((fac, y) in kept and qid in ids(f(T.Q[y], 13)) + ids(f(T.Q[y], 14)) for y in pool):
            kept.add((fac, qid))
            changed = True
drop = {(fac, qid) for fac, qid, _ in report} - kept

if not DRY:
    for g in G.values():
        if not g["inserts"]:
            continue
        by = {}
        for ln, k, txt in g["inserts"]:
            qid = int(txt.split(" ")[1])
            fac = re.search(r"faction=(\w+)", txt)
            facs = [fac.group(1)] if fac else [g["faction"]]
            if all((x, qid) in drop for x in facs):
                continue
            by.setdefault(ln, []).append((k, txt))
        out = []
        for i, l in enumerate(g["lines"]):
            out.append(l)
            for k, txt in sorted(by.get(i, [])):
                out.append(txt)
        open(g["file"], "w", encoding="utf-8", newline="").write(g["nl"].join(out))
xp = 0
for fac, qid, r in report:
    if (fac, qid) not in drop:
        print(r)
        xp += T.xp[qid]
print("cross-zone dungeon quests placed:", sum(1 for fac, qid, _ in report if (fac, qid) not in drop and not pool[qid]["lead"]),
      "lead-ins:", sum(1 for fac, qid, _ in report if (fac, qid) not in drop and pool[qid]["lead"]), "XP", xp)
