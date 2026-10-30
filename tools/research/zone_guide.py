# Generate a return-visit guide for a zone at a higher level band (docs/ROUTE_OPTIMIZATION.md).
# Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
# SPDX-License-Identifier: GPL-3.0-only
#
# Classic XP needs more quests than one visit per zone gives, and many zones hold quests well above the
# level of the route's visit. This writes a new guide source for one zone and level band from the quests no
# guide uses yet that:
#   - start at an NPC or object in the zone, with the finisher in the zone,
#   - have their objectives in the zone (no dungeon objectives) and no elite targets or elite-only drops,
#   - are open to the faction, not class, profession, reputation, repeatable or escort quests, not excluded
#     (quest_exclude.json), with quest XP, required level <= band max and quest level >= band min - 4,
#   - have every prerequisite turned in on the route already, or in this guide earlier.
# Steps come in waves: accept what is available (nearest-neighbour from the zone's flight master or first
# giver), do the objectives nearest-neighbour, turn everything in, then the follow-ups; at most 12 quests
# open at a time. Hardcore: with no elites the guide has no [hc=] marks of its own.
# The guide is ours (route selection and order are produced by this algorithm); step notes come from the
# compiler (NPC names and locations). Review the diff, then run guides + routes.
#
# Usage: python tools/research/zone_guide.py ClassicEra <after_guide_id> <faction|Both> <lo> <hi> [--dry-run]
#   The new guide is linked after <after_guide_id>: it takes over that guide's @next lines and that guide
#   points to it.
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from qdb import Target, centroid, dist, f, hsh, ids  # noqa: E402

a = [x for x in sys.argv[1:] if not x.startswith("--")]
T = Target(a[0])
AFTER, FAC, LO, HI = a[1], a[2], int(a[3]), int(a[4])
DRY = "--dry-run" in sys.argv
EXCLUDE = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "quest_exclude.json"), encoding="utf-8")).get(T.name, {})
MASK = {"Alliance": 77, "Horde": 178, "Both": 77 | 178}
WAVE = 12

base = T.guides[AFTER]
zone = base["zone"]
used = {s["q"] for g in T.guides.values() for s in g["steps"] if s["q"]}
# Turned in on routes of this faction before or at AFTER (by level): treat as done.
done = {s["q"] for g in T.guides.values() if g["faction"] in (FAC, "Both") or FAC == "Both"
        if g["min"] <= base["max"] for s in g["steps"] if s["kind"] == "turnin" and s["q"]}


def pts_npc(n):
    return T.npc_pts(n, zone)


def pos_giver(q):
    for n in ids(f(q, 6)):
        p = pts_npc(n)
        if p:
            return centroid(p), T.N[n][0]
    for o in ids(f(q, 7)):
        p = T.obj_pts(o, zone)
        if p:
            return centroid(p), T.O[o][0]
    return None, None


def pos_finisher(q):
    for n in ids(f(q, 9)):
        p = pts_npc(n)
        if p:
            return centroid(p)
    for o in ids(f(q, 10)):
        p = T.obj_pts(o, zone)
        if p:
            return centroid(p)
    return None


def pos_objectives(q):
    obj = hsh(f(q, 12))
    pts, bad = [], False
    for n in ids(obj.get("c")) + ids(obj.get("k")):
        if T.hostile_elite(n):
            return None, True
        pts += pts_npc(n)
    for o in ids(obj.get("o")):
        pts += T.obj_pts(o, zone)
    for it in ids(obj.get("i")):
        ir = T.I.get(it)
        dn = [n for n in ids(ir[1]) if pts_npc(n) and T.rank(n) not in (1, 2, 3)] if ir else []
        do = [o for o in ids(ir[2]) if T.obj_pts(o, zone)] if ir else []
        if not dn and not do:
            return None, True
        for n in dn:
            pts += pts_npc(n)
        for o in do:
            pts += T.obj_pts(o, zone)
    if obj and not pts:
        return None, True
    return (centroid(pts) if pts else None), bad


pool = {}
for qid, q in T.Q.items():
    if qid in used or str(qid) in EXCLUDE or not T.xp.get(qid):
        continue
    races = f(q, 4) or 0
    if races and not (races & MASK[FAC]):
        continue
    if (f(q, 5) or 0) or f(q, 22) or f(q, 23) or ((f(q, 19) or 0) & 1) or (f(q, 26) or 0) == 2:
        continue
    req, lvl = f(q, 2) or 0, f(q, 3) or 0
    if req > HI or lvl < LO - 4 or lvl > 60:
        continue
    gp, gname = pos_giver(q)
    fp = pos_finisher(q)
    if not gp or not fp:
        continue
    op, bad = pos_objectives(q)
    if bad:
        continue
    fac = None
    if FAC == "Both" and races:
        fac = "Alliance" if not (races & 178) else ("Horde" if not (races & 77) else None)
    pool[qid] = dict(q=q, gp=gp, op=op, fp=fp, req=req, xp=T.xp[qid], fac=fac,
                     pre_g=ids(f(q, 13)), pre_s=ids(f(q, 14)))


def available(qid, have):
    p = pool[qid]
    return all(x in have for x in p["pre_g"]) and (not p["pre_s"] or any(x in have for x in p["pre_s"]))


def tour(start, items, key):
    out, cur, left = [], start, list(items)
    while left:
        nxt = min(left, key=lambda i: dist(cur, key(i)))
        out.append(nxt)
        cur = key(nxt)
        left.remove(nxt)
    return out, cur


have = set(done)
order_waves = []
remaining = set(pool)
fm = [n for n, r in T.N.items() if r and pts_npc(n) and False]
start = centroid([p["gp"] for p in pool.values()]) if pool else (50, 50)
while True:
    wave = [x for x in remaining if available(x, have)]
    if not wave:
        break
    wave.sort(key=lambda x: -pool[x]["xp"])
    wave = wave[:WAVE]
    order_waves.append(wave)
    for x in wave:
        have.add(x)
        remaining.discard(x)

lines = []
total = 0
cur = start
for wi, wave in enumerate(order_waves):
    acc, cur = tour(cur, wave, lambda x: pool[x]["gp"])
    lines.append("# wave %d: pick up" % (wi + 1))
    for x in acc:
        lines.append(("accept %d %s" % (x, pool[x]["q"][0])) + (" [faction=%s]" % pool[x]["fac"] if pool[x]["fac"] else ""))
    with_obj = [x for x in wave if pool[x]["op"]]
    comp, cur = tour(cur, with_obj, lambda x: pool[x]["op"])
    for x in comp:
        lines.append(("complete %d %s" % (x, pool[x]["q"][0])) + (" [faction=%s]" % pool[x]["fac"] if pool[x]["fac"] else ""))
    tin, cur = tour(cur, wave, lambda x: pool[x]["fp"])
    for x in tin:
        lines.append(("turnin %d %s" % (x, pool[x]["q"][0])) + (" [faction=%s]" % pool[x]["fac"] if pool[x]["fac"] else ""))
        total += pool[x]["xp"]

n = sum(len(w) for w in order_waves)
print("%s return visit %d-%d (%s): %d quests in %d waves, %d XP" % (base["id"], LO, HI, FAC, n, len(order_waves), total))
for w in order_waves:
    print("   ", "; ".join("%s (%d)" % (pool[x]["q"][0], pool[x]["xp"]) for x in w))
if DRY or not n:
    sys.exit(0)

src = open(base["file"], encoding="utf-8", newline="").read()
nl = "\r\n" if "\r\n" in src else "\n"
s0 = src.replace("\r\n", "\n")
zname = re.search(r"^@zone (.+)$", s0, re.M).group(1).strip()
chapter = re.search(r"^@chapter (.+)$", s0, re.M).group(1).strip()
nexts = re.findall(r"^@next .+$", s0, re.M)
new_id = base["id"] + "_Late"
pre = {"Alliance": "A", "Horde": "H", "Both": "Both"}[FAC]
head = ["# ClassicGuide - %s return visit (%d-%d), %s, WoW Classic Era" % (zname, LO, HI, FAC),
        "# Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus) - GPL-3.0-only. Original route.",
        "# GENERATED as a starting point by tools/research/zone_guide.py (quests no other guide uses, in waves);",
        "# edit freely: it is a normal guide source from here on.",
        "", "@guide " + new_id, "@name %s (return, %d-%d)" % (zname, LO, HI), "@faction " + FAC,
        "@levels %d-%d" % (LO, HI), "@zone " + zname, "@chapter " + chapter,
        "@desc A second pass through %s at %d-%d for the quests the first visit was too low for." % (zname, LO, HI)]
head += nexts
# No closing level step: a return visit adds quests; it must not force the next zone's starting level.
body = ["", "note Back in %s for the higher-level quests." % zname] + lines
folder = os.path.dirname(base["file"])
fn = os.path.join(folder, os.path.splitext(os.path.basename(base["file"]))[0] + "_late.guide")
open(fn, "w", encoding="utf-8", newline="").write(nl.join(head + body) + nl)
# Link: AFTER now leads to the new guide.
s1 = re.sub(r"^@next .+\n", "", s0, flags=re.M)
i = s1.index("\n", s1.index("@desc ")) + 1
s1 = s1[:i] + "@next " + new_id + "\n" + s1[i:]
open(base["file"], "w", encoding="utf-8", newline="").write(s1.replace("\n", nl))
print("wrote", os.path.relpath(fn), "and linked it after", base["id"])
