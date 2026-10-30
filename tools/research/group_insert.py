# Add elite/group and dungeon quests to guides as optional content (docs/ROUTE_OPTIMIZATION.md).
# Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
# SPDX-License-Identifier: GPL-3.0-only
#
# The solo tools (quest_insert, chain_insert, zone_guide) leave these out. Here, per guide, quests no guide
# uses yet that start and end in the guide's zone (NPC or object), are open to the guide's faction, have quest
# XP, are not class/profession/reputation/repeatable/escort quests, not excluded, with prerequisites already
# done earlier, and whose objectives are either
#   elite   - outdoors in the zone, with at least one hostile elite target (or an item only elites drop):
#             every step gets [elite; group; hc=skip], so the default route and Hardcore leave it out
#             (Classic Era: Settings -> "show elite" is off by default);
#   dungeon - all inside one dungeon (never a raid): the compiler tags every step [dungeon=...], which the
#             "Include Dungeon Quests" setting controls (off by default on Classic Era).
# Placement: accept after the step nearest the giver where the model level meets the required level; elite
# objectives after the nearest step to them; dungeon objectives and the turn-in at the LAST visit near the
# finisher in the guide (so the run fits between). At most MAX_PER guide.
#
# Writes guide sources. Run guides + routes afterwards (the route audit counts these quests for the quest
# log but gives no XP for them, so solo level gates are unaffected).
# Usage: python tools/research/group_insert.py ClassicEra [--dry-run]
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from qdb import Target, VERB_RE, centroid, dist, f, hsh, ids  # noqa: E402

args = [x for x in sys.argv[1:] if not x.startswith("--")]
T = Target(args[0] if args else "ClassicEra")
DRY = "--dry-run" in sys.argv
MAX_PER = 6
EXCLUDE = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "quest_exclude.json"), encoding="utf-8")).get(T.name, {})
MASK = {"Alliance": 77, "Horde": 178, "Both": 77 | 178}

# Instance / raid zones from the bundled zone names, as the compiler recognises them.
names = {}
for line in open(os.path.join(T.qdir, "Zones.lua"), encoding="utf-8"):
    for m in re.finditer(r'\[(\d+)\]="((?:[^"\\]|\\.)*)"', line):
        names[int(m.group(1))] = m.group(2)
INST_WORDS = ("Dungeon", "Scholomance", "fake ID for")


def is_instance(z):
    n = names.get(z, "")
    return any(w in n for w in INST_WORDS) and "Raid" not in n and "SoD" not in n


def instance_name(z):
    n = names[z].split(" - ")[0]
    if "(fake ID for " in n:
        n = n.split("(fake ID for ", 1)[1].rstrip(")")
    return n.strip()


def is_raid(z):
    return "Raid" in names.get(z, "")


used = {s["q"] for g in T.guides.values() for s in g["steps"] if s["q"]}
turned = {}
for g in T.guides.values():
    for s in g["steps"]:
        if s["kind"] == "turnin" and s["q"]:
            turned.setdefault(s["q"], []).append(g)


def zones_of_objectives(q):
    """{zone: [points]} of every objective place (kill targets, objects, droppers of quest items)."""
    out, elite = {}, False
    obj = hsh(f(q, 12))

    def add_npc(n):
        nonlocal elite
        r = T.N.get(n)
        if not r:
            return
        if T.hostile_elite(n):
            elite = True
        for z in hsh(r[5]).keys():
            out.setdefault(z, []).extend(T.npc_pts(n, z))

    def add_obj(o):
        r = T.O.get(o)
        if not r:
            return
        for z in hsh(r[2]).keys():
            out.setdefault(z, []).extend(T.obj_pts(o, z))
        if not hsh(r[2]) and r[1]:
            out.setdefault(r[1], [])

    for n in ids(obj.get("c")) + ids(obj.get("k")):
        add_npc(n)
    for o in ids(obj.get("o")):
        add_obj(o)
    for it in ids(obj.get("i")):
        ir = T.I.get(it)
        if not ir:
            continue
        for n in ids(ir[1]):
            add_npc(n)
        for o in ids(ir[2]):
            add_obj(o)
    return out, elite


report, total = [], 0
for gid, g in sorted(T.guides.items(), key=lambda kv: kv[1]["min"]):
    if not g["file"]:
        continue
    zone = g["zone"]
    src = open(g["file"], encoding="utf-8", newline="").read()
    nl = "\r\n" if "\r\n" in src else "\n"
    lines = src.replace("\r\n", "\n").split("\n")
    src_q = [i for i, l in enumerate(lines) if VERB_RE.match(l)]
    cq = [s for s in g["steps"] if s["kind"] in ("accept", "turnin", "complete")]
    if len(src_q) != len(cq):
        continue
    anchors = [(src_q[k], (s["x"], s["y"])) for k, s in enumerate(cq) if s["z"] == zone and s["x"] is not None and not s["filtered"]]
    if len(anchors) < 3:
        continue
    done_here = {s["q"]: src_q[k] for k, s in enumerate(cq) if s["kind"] == "turnin" and s["q"]}
    lower = {q for q, gs in turned.items() for og in gs if og["min"] < g["min"] and og["faction"] in (g["faction"], "Both")}
    inserts, n_added = [], 0
    cands = []
    for qid, q in T.Q.items():
        if qid in used or str(qid) in EXCLUDE or not T.xp.get(qid):
            continue
        races = f(q, 4) or 0
        if races and not (races & MASK[g["faction"]]):
            continue
        if (f(q, 5) or 0) or f(q, 22) or f(q, 23) or ((f(q, 19) or 0) & 1) or (f(q, 26) or 0) == 2:
            continue
        req, lvl = f(q, 2) or 0, f(q, 3) or 0
        if req > g["max"] + 1 or lvl < g["min"] - 2 or lvl > 60:
            continue
        giver = [T.npc_pts(n, zone) for n in ids(f(q, 6))] + [T.obj_pts(o, zone) for o in ids(f(q, 7))]
        giver = [p for p in giver if p]
        fin = [T.npc_pts(n, zone) for n in ids(f(q, 9))] + [T.obj_pts(o, zone) for o in ids(f(q, 10))]
        fin = [p for p in fin if p]
        if not giver or not fin:
            continue
        oz, elite = zones_of_objectives(q)
        if not oz:
            continue
        if any(is_raid(z) for z in oz):
            continue
        if all(is_instance(z) for z in oz) and len({instance_name(z) for z in oz}) == 1:
            kind = "dungeon:" + instance_name(next(iter(oz)))
        elif elite and set(oz) == {zone}:
            kind = "elite"
        else:
            continue
        cands.append((T.xp[qid], qid, q, kind, centroid(giver[0]), centroid(fin[0]), centroid(oz.get(zone, [])) if kind == "elite" else None))
    # (dungeon quests carry an explicit [dungeon=<instance>] tag: the compiler's own tagging only sees the
    # bundled NPC subset, which can miss the dungeon mobs that drop quest items)
    cands.sort(key=lambda c: -c[0])
    for xp, qid, q, kind, gpos, fpos, opos in cands:
        if n_added >= MAX_PER:
            break
        pg, ps = ids(f(q, 13)), ids(f(q, 14))
        ia = min(anchors, key=lambda a: dist(a[1], gpos))[0]
        req = f(q, 2) or 0
        lv = T.level_at(g["file"], ia)
        if lv is not None and lv + 0.25 < req:
            near = min(dist(a[1], gpos) for a in anchors)
            later = [a for a in anchors if a[0] > ia and dist(a[1], gpos) <= near + 8 and (T.level_at(g["file"], a[0]) or 0) + 0.25 >= req]
            if not later:
                continue
            ia = later[0][0]
        ok = all(p in lower or (p in done_here and done_here[p] < ia) for p in pg) and \
            (not ps or any(p in lower or (p in done_here and done_here[p] < ia) for p in ps))
        if not ok:
            continue
        after = [a for a in anchors if a[0] > ia]
        if not after:
            continue
        flag = ""
        if g["faction"] == "Both":
            races = f(q, 4) or 0
            if races and not (races & 178):
                flag = "faction=Alliance"
            elif races and not (races & 77):
                flag = "faction=Horde"
        if kind == "elite":
            ic = min(after, key=lambda a: dist(a[1], opos))[0]
            it_ = min([a for a in anchors if a[0] >= ic], key=lambda a: dist(a[1], fpos))[0]
            fl = "[elite; group; hc=skip%s]" % ("; " + flag if flag else "")
        else:
            nearest = min(dist(a[1], fpos) for a in after)
            it_ = max([a for a in after if dist(a[1], fpos) <= nearest + 4], key=lambda a: a[0])[0]
            ic = it_
            fl = "[dungeon=%s%s]" % (kind.split(":", 1)[1], "; " + flag if flag else "")
        name = q[0]
        inserts.append((ia, 0, ("accept %d %s %s" % (qid, name, fl)).rstrip()))
        inserts.append((ic, 1, ("complete %d %s %s" % (qid, name, fl)).rstrip()))
        inserts.append((it_, 2, ("turnin %d %s %s" % (qid, name, fl)).rstrip()))
        done_here[qid] = it_
        used.add(qid)
        n_added += 1
        total += xp
        report.append("%s: + %s %d %s (%d XP)" % (gid, kind.split(":")[0], qid, name, xp))
    if inserts and not DRY:
        by = {}
        for ln, k, txt in inserts:
            by.setdefault(ln, []).append((k, txt))
        out = []
        for i, l in enumerate(lines):
            out.append(l)
            for k, txt in sorted(by.get(i, [])):
                out.append(txt)
        open(g["file"], "w", encoding="utf-8", newline="").write(nl.join(out))
for r in report:
    print(r)
print("group content added: %d quests (%d elite/group, %d dungeon), %d XP" % (
    len(report), sum(" elite " in r for r in report), sum(" dungeon " in r for r in report), total))
