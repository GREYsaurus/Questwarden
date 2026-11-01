# Add quests started by a mob-dropped item to the speed guides (docs/ITEM_STARTS.md, docs/ROUTE_OPTIMIZATION.md).
# Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
# SPDX-License-Identifier: GPL-3.0-only
#
# Takes the candidates of docs/generated/<Target>/item-starter-gaps.csv (guides that still need grinding; quests no
# guide uses, open to the faction and every class, no prerequisite, in the level band, dropped in the guide's zone)
# and keeps only the conservative ones:
#   - the item is dropped by ONE kind of NPC (a named mob), or the guide already has an objective step that kills
#     one of its droppers (the pickup then waits for those steps, Core/ItemStarts.lua);
#   - at most MAX_ITEM_DROPPERS kinds of NPC drop the item (more is a broad world drop, likely rare, and more than the
#     bundled data keeps);
#   - at least one dropper in the zone is not a hostile elite, rare elite or boss (the step points only at those);
#   - not an escort or scripted event, not repeatable, no reputation requirement, not in quest_exclude.json;
#   - the finisher stands in the guide's zone, and every objective (kill targets, objects, quest-item droppers) can be
#     done there without elites;
#   - the route model reaches the quest's required level where the pickup goes.
# Placement in the guide SOURCE: the pickup right before the guide's first objective step that kills a dropper, else
# after the step nearest the droppers; the objective after the step nearest the objective area (never before the
# pickup); the turn-in after the step nearest the finisher (never before the objective). Positions come from the
# compiled guide and QuestieDB's full spawn tables. Nothing about drop rates is known or written.
#
# --relaxed drops two of those rules: the objectives and the turn-in may be in another zone (they go into the first
# later guide of that zone, by level, for the same faction), and the pickup no longer waits for the required level
# (below it, the add-on skips the pickup with "needs level N" and takes it if you reach the level before moving on).
#
# Usage: python tools/research/item_starter_insert.py <Target> [--relaxed] [--dry-run] [--why]
# Run the compiler and the route audit afterwards; every added quest is reviewed in the diff.
import csv
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import qdb  # noqa: E402
from qdb import f, ids, hsh, dist, centroid, escort  # noqa: E402

target = [a for a in sys.argv[1:] if not a.startswith("--")]
target = target[0] if target else "ClassicEra"
DRY = "--dry-run" in sys.argv
VERBOSE = "--why" in sys.argv
RELAXED = "--relaxed" in sys.argv
T = qdb.Target(target)
EXCLUDE = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "quest_exclude.json"), encoding="utf-8")).get(target, {})
VERB_RE = re.compile(r"^(accept|turnin|complete)\s")
MAX_ITEM_DROPPERS = 12


def elite(n):
    return T.hostile_elite(n)


def objective_npcs(q):
    rec = T.Q.get(q)
    obj = hsh(f(rec, 12)) if rec else {}
    out = set(ids(obj.get("c"))) | set(ids(obj.get("k")))
    for it in ids(obj.get("i")):
        r = T.I.get(it)
        if r and len(ids(r[1])) <= MAX_ITEM_DROPPERS:  # as the compiler sees it (bundled items keep at most 12)
            out |= set(ids(r[1]))
    return out


def pts_by_zone(rec, field):
    """{zone: [(x, y)]} of a normalised NPC (spawns at field 6) or object (field 3) record."""
    if not rec:
        return {}
    return {z: [(qdb.arr(p)[0], qdb.arr(p)[1]) for p in qdb.arr(v)] for z, v in hsh(f(rec, field)).items()}


cands = {}
for r in csv.DictReader(open(os.path.join(qdb.ROOT, "docs", "generated", target, "item-starter-gaps.csv"), encoding="utf-8")):
    if r["quest"]:
        cands.setdefault(r["guide"], []).append(int(r["quest"]))
starters = {int(r["quest"]): r for r in csv.DictReader(open(os.path.join(qdb.ROOT, "docs", "generated", target, "item-starters.csv"), encoding="utf-8"))}
if RELAXED:
    # Every guide whose zone has the droppers, not only those that still need grinding; prerequisites allowed when the
    # route turns them in first (checked below).
    cands = {}
    for gid, g in T.guides.items():
        for qid, s in starters.items():
            if s["source"] != "mob" or s["guideAccepts"] or s["classes"] not in ("0", ""):
                continue
            if g["faction"] != "Both" and s["faction"] not in ("Both", g["faction"]):
                continue
            req, lvl = int(s["reqLevel"] or 0), int(s["level"] or 0)
            if lvl <= 0 or req > g["max"] or lvl < g["min"] - 2 or lvl > g["max"] + 2:
                continue
            if str(g["zone"]) in s["dropZones"].split():
                cands.setdefault(gid, []).append(qid)
zone_names = {}
for p in os.listdir(os.path.join(T.dir, "addon", "Guides", "Compiled")):
    t = open(os.path.join(T.dir, "addon", "Guides", "Compiled", p), encoding="utf-8").read()
    for m in re.finditer(r'id="([^"]+)",.*?zoneName="([^"]*)"', t, re.S):
        zone_names[m.group(1)] = m.group(2)

report, why, used = [], {}, set()


CUR = [None]


def reject(reason):
    why[reason] = why.get(reason, 0) + 1
    if VERBOSE:
        print("  - %s %s: %s" % (CUR[0][0], CUR[0][1], reason))


# Every guide's source lines and quest-step anchors (source line, position), loaded once; inserts collect per guide.
ctx = {}
for gid, g in T.guides.items():
    if not g["file"]:
        continue
    src = open(g["file"], encoding="utf-8", newline="").read()
    lines = src.replace("\r\n", "\n").split("\n")
    src_q = [i for i, l in enumerate(lines) if VERB_RE.match(l)]
    cq = [s for s in g["steps"] if s["kind"] in ("accept", "turnin", "complete")]
    if len(src_q) != len(cq):
        report.append("%s: source/compiled quest steps differ (%d/%d); skipped" % (gid, len(src_q), len(cq)))
        continue
    anchors = [(src_q[k], (s["x"], s["y"])) for k, s in enumerate(cq) if s["z"] == g["zone"] and s["x"] is not None and not s["filtered"]]
    ctx[gid] = dict(g=g, nl="\r\n" if "\r\n" in src else "\n", lines=lines, src_q=src_q, cq=cq, anchors=anchors, inserts=[])
ORDER = sorted(ctx, key=lambda k: (ctx[k]["g"]["min"], k))
turned = {}  # quest -> guides that turn it in
for gid, c in ctx.items():
    for k, s in enumerate(c["cq"]):
        if s["kind"] == "turnin" and s["q"]:
            turned.setdefault(s["q"], []).append((gid, c["src_q"][k]))


def prereq_done(q, gid, line):
    """Every required prerequisite (and one of the alternatives) is turned in earlier in this guide, or in a guide of
    the same faction that starts at a lower level."""
    g = ctx[gid]["g"]

    def done(p):
        for og, ln in turned.get(p, []):
            h = ctx[og]["g"]
            if (og == gid and ln < line) or (h["min"] < g["min"] and h["faction"] in (g["faction"], "Both")):
                return True
        return False
    group, single = ids(f(q, 13)), ids(f(q, 14))
    return all(done(p) for p in group) and (not single or any(done(p) for p in single))


def later_guide(gid, zones, faction):
    """This guide when its zone is in `zones`, else (--relaxed only) the first guide after it by level, of the quest's
    faction, whose zone is in `zones`."""
    g = ctx[gid]["g"]
    if g["zone"] in zones:
        return gid
    if not RELAXED:
        return None
    for k in ORDER[ORDER.index(gid) + 1:]:
        h = ctx[k]["g"]
        if h["min"] < g["min"] or h["zone"] not in zones or len(ctx[k]["anchors"]) < 3:
            continue
        if h["faction"] == "Both" or h["faction"] == faction:
            return k
    return None


def faction_flag(guide, qfaction):
    return " [faction=%s]" % qfaction if guide["faction"] == "Both" and qfaction != "Both" else ""


for gid in ORDER:
    c = ctx[gid]
    g, zone, cq, src_q, anchors = c["g"], c["g"]["zone"], c["cq"], c["src_q"], c["anchors"]
    if gid not in cands or len(anchors) < 3:
        continue
    for qid in cands[gid]:
        if qid in used:
            continue  # one guide per quest (the first, lowest-level one)
        q = T.Q.get(qid)
        st = starters.get(qid)
        CUR[0] = (gid, "%d %s" % (qid, q[0] if q else "?"))
        if not q or not st:
            reject("no record"); continue
        if str(qid) in EXCLUDE or escort(q) or (f(q, 26) or 0) & 2 or (f(q, 19) or 0) & 1 or f(q, 23):
            reject("escort/event/repeatable/reputation/excluded"); continue
        item = int(st["item"])
        if item in T.I and len(set(ids(T.I[item][1]))) > MAX_ITEM_DROPPERS:
            reject("world drop (more than %d kinds of dropper)" % MAX_ITEM_DROPPERS); continue
        here = [n for n in ids(T.I[item][1]) if T.npc_pts(n, zone)] if item in T.I else []
        drops = [n for n in here if not elite(n)]
        if not drops:
            reject("only elites drop it here" if here else "no dropper in zone"); continue
        kills = [k for k, s in enumerate(cq) if s["kind"] == "complete" and s["q"] and objective_npcs(s["q"]) & set(drops)]
        if len(set(ids(T.I[item][1]))) != 1 and not kills:
            reject("many kinds of dropper, none killed by the guide"); continue
        races = f(q, 4) or 0
        qfaction = "Alliance" if races and not (races & 178) else ("Horde" if races and not (races & 77) else g["faction"])
        # Objectives: the zones where every one of them can be done (kill targets, objects, quest-item droppers).
        obj = hsh(f(q, 12))
        kill = ids(obj.get("c")) + ids(obj.get("k"))
        if any(elite(n) for n in kill):
            reject("elite objective"); continue
        parts, bad = [], False  # one {zone: points} per objective
        for n in kill:
            parts.append(pts_by_zone(T.N.get(n), 6))
        for o in ids(obj.get("o")):
            parts.append(pts_by_zone(T.O.get(o), 3))
        for it in ids(obj.get("i")):
            ir = T.I.get(it)
            if not ir or (ids(ir[1]) and not ids(ir[2]) and all(elite(n) for n in ids(ir[1]))):
                bad = True
                break
            d = {}
            for n in ids(ir[1]):
                if not elite(n):
                    for z, pts in pts_by_zone(T.N.get(n), 6).items():
                        d.setdefault(z, []).extend(pts)
            for o in ids(ir[2]):
                for z, pts in pts_by_zone(T.O.get(o), 3).items():
                    d.setdefault(z, []).extend(pts)
            parts.append(d)
        has_obj = bool(obj and (obj.get("c") or obj.get("k") or obj.get("o") or obj.get("i")))
        ozones = set.intersection(*[set(z for z, v in d.items() if v) for d in parts]) if parts else set()
        if bad or (has_obj and not ozones):
            reject("objectives not doable in one zone"); continue
        ezones = {}
        for n in ids(f(q, 9)):
            for z, pts in pts_by_zone(T.N.get(n), 6).items():
                ezones.setdefault(z, []).extend(pts)
        for o in ids(f(q, 10)):
            for z, pts in pts_by_zone(T.O.get(o), 3).items():
                ezones.setdefault(z, []).extend(pts)
        ezones = {z: v for z, v in ezones.items() if v}
        # Where the steps go: the objective in this guide or (relaxed) a later one in its zone; the turn-in in the
        # objective's guide or (relaxed) a later one in the finisher's zone.
        og = later_guide(gid, ozones, qfaction) if has_obj else gid
        if not og:
            reject("objectives not in zone" if not RELAXED else "no later guide where the objectives are"); continue
        tg = later_guide(og, set(ezones), qfaction)
        if not tg:
            reject("finisher not in zone" if not RELAXED else "no later guide where the finisher is"); continue
        dpos = centroid([p for n in drops for p in T.npc_pts(n, zone)])
        req = f(q, 2) or 0
        ia = src_q[kills[0]] - 1 if kills else min(anchors, key=lambda a: dist(a[1], dpos))[0]
        if not RELAXED:
            lv = T.level_at(g["file"], ia)
            if lv is not None and req > lv + 0.25:
                later = [a for a in anchors if a[0] > ia and (T.level_at(g["file"], a[0]) or 0) + 0.25 >= req]
                if not later:
                    reject("level not reached"); continue
                ia = min(later, key=lambda a: dist(a[1], dpos))[0] if not kills else later[0][0]
        if not prereq_done(q, gid, ia):
            reject("prerequisite not turned in first"); continue
        ic = ia
        if has_obj:
            oc = ctx[og]
            opos = centroid([p for d in parts for p in d.get(oc["g"]["zone"], [])])
            pool = [a for a in oc["anchors"] if og != gid or a[0] >= ia] or [oc["anchors"][-1]]
            ic = min(pool, key=lambda a: dist(a[1], opos))[0]
        tc = ctx[tg]
        epos = centroid(ezones[tc["g"]["zone"]])
        pool = [a for a in tc["anchors"] if tg != og or a[0] >= ic] or [tc["anchors"][-1]]
        it_ = min(pool, key=lambda a: dist(a[1], epos))[0]
        title = q[0]
        note = ""
        if tg != gid:
            note = " | Turned in later in the route, in %s." % (zone_names.get(tg) or tg)
        c["inserts"].append((ia, 0, "accept %d %s%s%s" % (qid, title, faction_flag(g, qfaction), note)))
        if has_obj:
            ctx[og]["inserts"].append((ic, 1, "complete %d %s%s" % (qid, title, faction_flag(ctx[og]["g"], qfaction))))
        tc["inserts"].append((it_, 2, "turnin %d %s%s" % (qid, title, faction_flag(tc["g"], qfaction))))
        used.add(qid)
        lv = T.level_at(g["file"], ia)
        where = "" if (og, tg) == (gid, gid) else " -> objective in %s, turn-in in %s" % (og if has_obj else "-", tg)
        report.append("%s: + %d %s (item %s; %s; needs %d, model %s)%s" % (
            gid, qid, title, st["itemName"], "before the guide's kill steps" if kills else "named dropper",
            req, "%.1f" % lv if lv is not None else "?", where))

for gid, c in ctx.items():
    if not c["inserts"] or DRY:
        continue
    by_line = {}
    for ln, order, text in c["inserts"]:
        by_line.setdefault(ln, []).append((order, text))
    out = []
    for order, text in sorted(by_line.get(-1, []), key=lambda x: x[0]):
        out.append(text)
    for i, l in enumerate(c["lines"]):
        out.append(l)
        for order, text in sorted(by_line.get(i, []), key=lambda x: x[0]):
            out.append(text)
    open(c["g"]["file"], "w", encoding="utf-8", newline="").write(c["nl"].join(out))

for r in report:
    print(r)
print("added", sum(1 for r in report if ": + " in r), "quests")
for k, v in sorted(why.items(), key=lambda kv: -kv[1]):
    print("  rejected: %-48s %d" % (k, v))
