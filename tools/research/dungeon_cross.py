# Add dungeon quests and the chains that lead to them across a faction's guides: givers and finishers in
# cities and neighbouring zones, outdoor lead-ins, and follow-ups handed out inside the instance
# (docs/ROUTE_OPTIMIZATION.md).
# Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
# SPDX-License-Identifier: GPL-3.0-only
#
# group_insert.py only takes quests given and ended in the guide's own zone. Routes also pass through cities
# and neighbouring zones (every compiled step carries its own map zone), so here every step with a location
# is a possible anchor, whatever the guide's zone; inside a capital any step counts (a city is one short walk).
# Anchors are steps every character of the faction takes (not class/race-filtered, optional, Hardcore-flagged,
# elite or dungeon); the dungeon "complete" steps already on a route are runs. Guides follow their @next links: a faction's paths run from each start guide, so a quest
# picked up in one race's start zone is never turned in on another race's path.
#
# Roots are unused dungeon quests: XP, open to the faction, not a class/profession/reputation/repeatable/
# scripted-event quest, not excluded, and ALL objectives inside one dungeon (never a raid or a Season of
# Discovery instance). Escorts are fine: a note before the pickup says the next quest is an escort, and the
# escort's complete step follows the accept. Every unused prerequisite up the chain comes along as a member of one of three kinds:
#   dungeon - objectives inside one dungeon;   talk - no objectives;   outdoor - objectives outdoors only.
# Givers and finishers (NPC, object or the item that starts the quest) stand either outdoors or inside an
# instance. A dungeon visit is a "run": the steps inside one instance sit together at one point of the route.
# Placement, in prerequisite order (several passes, so chains follow on):
#   accept  - outdoors: first guide by level whose band meets the quest (required level <= band max + 1, quest
#             level >= band min - 2), after every prerequisite on every path into it, at a step near the giver
#             where the model level meets the required level. Inside: at the run of a prerequisite in that
#             instance (the follow-up is handed out while you are still there), or, for a quest without
#             prerequisites, at the first run into that instance already on the route;
#   complete- dungeon: the run. It is the inherited run, or else right after the accept when the finisher is
#             inside too, or else just before the turn-in. Outdoor: the first step near the objectives after
#             the accept;
#   turnin  - inside: the run. Outdoors: a step near the finisher after the accept/complete, in the same guide
#             or the next MAX_SPAN guides along @next, as long as every path into that guide passes the
#             pickup guide (a dungeon quest takes the last such step in its own guide, to leave time for the run).
# Every step of a chain is [dungeon=<instance>] (off unless "Include Dungeon Quests" is on, and never counted
# as solo XP); steps in a later guide than the accept are [optional]; shared guides get [faction=...].
# A chain member nothing dungeon-bound follows on from is dropped. At most MAX_PER dungeon quests per guide.
#
# --outdoor plans solo cross-zone chains the same way: roots are unused outdoor and talk-only quests (XP, no
# hostile elite among the objectives, giver and finisher outdoors, not a seasonal or event quest), with their
# unused outdoor/talk lead-ins.
# Their steps are ordinary solo steps (no [dungeon=], not optional: every path into the turn-in guide passes
# the pickup guide), the objectives must be reached at a model level of at least quest level - 2, and at
# most MAX_PER of them go into one guide. Unplaced roots: docs/generated/<target>/outdoor-unplaced.csv.
# Writes guide sources. Run guides + routes afterwards.
# Usage: python tools/research/dungeon_cross.py ClassicEra [--outdoor] [--dry-run] [--why]
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from qdb import ESCORT_STEP, Target, VERB_RE, centroid, dist, escort, escort_note, event_only, f, hsh, ids  # noqa: E402

args = [x for x in sys.argv[1:] if not x.startswith("--")]
T = Target(args[0] if args else "ClassicEra")
DRY = "--dry-run" in sys.argv
OUTDOOR = "--outdoor" in sys.argv
MAX_PER, MAX_SPAN, NEAR = 6, 2, 6.0
EXCLUDE = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "quest_exclude.json"), encoding="utf-8")).get(T.name, {})
MASK = {"Alliance": 77, "Horde": 178}

names = {}
for line in open(os.path.join(T.qdir, "Zones.lua"), encoding="utf-8"):
    for m in re.finditer(r'\[(\d+)\]="((?:[^"\\]|\\.)*)"', line):
        names[int(m.group(1))] = m.group(2)
CITY = {z for z, n in names.items() if n in ("Stormwind City", "Ironforge", "Darnassus", "Orgrimmar", "Thunder Bluff", "Undercity")}
BAD = object()  # a place we cannot use: a raid, a Season of Discovery zone, or two different instances


def inst(z):
    n = names.get(z, "")
    if "SoD" in n or "Raid" in n:
        return BAD
    if " - Dungeon" in n or "Scholomance" in n:
        return n.split(" - ")[0].strip()
    if "(fake ID for " in n:
        return n.split("(fake ID for ", 1)[1].rstrip(")").strip()
    return None


def npc_zones(n):
    r = T.N.get(n)
    return {z: T.npc_pts(n, z) for z in hsh(r[5]).keys()} if r else {}


def obj_zones(o):
    r = T.O.get(o)
    if not r:
        return {}
    zs = {z: T.obj_pts(o, z) for z in hsh(r[2]).keys()}
    return zs or ({r[1]: []} if r[1] else {})


def where(npcs, objs, items=()):
    """{zone: [points]} for NPCs, objects and the drop sources of items."""
    out = {}
    srcs = [npc_zones(n) for n in npcs] + [obj_zones(o) for o in objs]
    for it in items:
        ir = T.I.get(it)
        if ir:
            srcs += [npc_zones(n) for n in ids(ir[1])] + [obj_zones(o) for o in ids(ir[2])]
    for s in srcs:
        for z, p in s.items():
            if isinstance(z, int):
                out.setdefault(z, []).extend(p)
    return out


def split(zp):
    """(outdoor {zone: centroid}, instance name or None); BAD when unusable."""
    ins = {inst(z) for z in zp} - {None}
    out = {z: centroid(p) for z, p in zp.items() if inst(z) is None and p}
    if BAD in ins or len(ins) > 1:
        return BAD
    if ins and out:
        return out, None  # someone who stands both outside and inside: use the outside
    if ins:
        return {}, ins.pop()
    return (out, None) if out else BAD


def objectives(q):
    obj = hsh(f(q, 12))
    return where(ids(obj.get("c")) + ids(obj.get("k")), ids(obj.get("o")), ids(obj.get("i")))


def near(an, pts):
    return an[1] in pts and (an[1] in CITY or dist(an[2], pts[an[1]]) <= NEAR)


def near_any(an, zp):
    return any(dist(an[2], p) <= NEAR for p in zp.get(an[1], []))


def plain(q):
    """Not a class, profession, reputation or repeatable quest, nor a scripted event (escorts are fine)."""
    return not ((f(q, 5) or 0) or f(q, 22) or f(q, 23) or ((f(q, 19) or 0) & 1) or event_only(q))


# Guides with aligned source lines; anchors = every located step every character of the faction takes.
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
    dng_runs = [(s["dungeon"], src_q[k]) for k, s in enumerate(cq) if s["kind"] == "complete" and s["dungeon"] and not s["filtered"]]
    G[gid] = dict(g, lines=lines, nl="\r\n" if "\r\n" in src else "\n", anchors=anchors, inserts=[], added=0, dng_runs=dng_runs,
                  turn={s["q"]: src_q[k] for k, s in enumerate(cq) if s["kind"] == "turnin" and s["q"]})

NEXT = {}
for g in G.values():
    for line in g["lines"]:
        m = re.match(r"^@next\s+(\S+)(?:\s*\[faction=(\w+)\])?", line)
        if m:
            for fac in ([m.group(2)] if m.group(2) else ["Alliance", "Horde"]):
                NEXT.setdefault(g["id"], {})[fac] = m.group(1)

used = {s["q"] for g in T.guides.values() for s in g["steps"] if s["q"]}


def member(qid, d):
    q = T.Q.get(qid)
    if not q or qid in used or str(qid) in EXCLUDE or not plain(q) or not 0 < (f(q, 3) or 0) <= 60:
        return None
    giv = split(where(ids(f(q, 6)), ids(f(q, 7)), ids(f(q, 8))))
    fin = split(where(ids(f(q, 9)), ids(f(q, 10))))
    if giv is BAD or fin is BAD:
        return None
    m = dict(q=q, d=d, giv=giv[0], giv_in=giv[1], fin=fin[0], fin_in=fin[1])
    if not f(q, 12):
        m["kind"] = "talk"
    else:
        zp = objectives(q)
        ins = {inst(z) for z in zp}
        if ins == {None} and zp:
            m.update(kind="outdoor", obj=zp)
        elif len(ins) == 1 and None not in ins and BAD not in ins:
            m.update(kind="dungeon", d=ins.pop())
        else:
            return None
    for x in (m["giv_in"], m["fin_in"]):
        if x and x != m["d"]:
            return None  # an NPC in a different instance than the chain's
    if m["kind"] == "outdoor" and (m["giv_in"] or m["fin_in"]):
        return None
    if OUTDOOR and (m["kind"] == "dungeon" or m["giv_in"] or m["fin_in"]):
        return None  # solo chains stay outdoors
    if OUTDOOR and (f(q, 15) or 0) < 0:
        return None  # a negative zone/sort is a category: seasonal events (-22), the Ahn'Qiraj war effort (-365)...
    if OUTDOOR and m["kind"] == "outdoor" and any(T.hostile_elite(n) for n in ids(hsh(f(q, 12)).get("c")) + ids(hsh(f(q, 12)).get("k"))):
        return None  # elite targets are group content
    return m


pool = {}
for qid, q in T.Q.items():
    if qid in used or not T.xp.get(qid):
        continue
    m = member(qid, None)
    if m and (m["kind"] != "dungeon" if OUTDOOR else m["kind"] == "dungeon"):
        pool[qid] = m
ROOTS = set(pool)
roots = len(pool)


def lead_ins(qid, d, depth=0):
    if depth > 8:
        return
    for x in ids(f(T.Q[qid], 13)) + ids(f(T.Q[qid], 14)):
        if x in pool or x in used:
            continue
        m = member(x, d)
        if m:
            pool[x] = m
            lead_ins(x, m["d"], depth + 1)


for qid in list(pool):
    lead_ins(qid, pool[qid]["d"])
print("unused %s quests:" % ("outdoor/talk" if OUTDOOR else "dungeon"), roots, "- with chain members:", len(pool))

report, WHY = [], {}
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
    done, runs = {}, {}  # quest -> [(guide, line)]; quest -> (instance, guide, line, order) of its run
    for g in seq:
        for qid, ln in g["turn"].items():
            done.setdefault(qid, []).append((g["id"], ln))
    order = [0.0]

    def before(pos, gid, ln):
        return any(p[0] in dom[gid] or (p[0] == gid and p[1] <= ln) for p in pos)

    def ahead(gid, ln):
        """Anchors after (gid, ln): the rest of that guide, then the next MAX_SPAN guides along @next."""
        out = [(gid, an) for an in mine[gid]["anchors"] if an[0] > ln]
        cur = gid
        for _ in range(MAX_SPAN):
            cur = NEXT.get(cur, {}).get(fac)
            if cur not in mine or gid not in dom[cur]:
                break
            out += [(cur, an) for an in mine[cur]["anchors"]]
        return out

    def slot(run=None):
        """A sort key for an insert: after everything so far, or just after a run's inside steps."""
        if run:
            run[3][0] += 0.001
            return run[3][0]
        order[0] += 1
        return order[0]

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
                WHY[(fac, qid)] = "prerequisite not placed"
                continue
            prev = [x for x in pg + ps if x in done]
            inherited = next((runs[x] for x in prev if x in runs and runs[x][0] == p["d"]), None)
            # accept
            a = run = None
            if p["giv_in"]:
                if not inherited and not pg and not ps:
                    # no lead-in: picked up on a run the route already makes into that instance
                    inherited = next(((p["d"], g["id"], ln, [slot()]) for g in seq if g["faction"] == fac
                                      for d, ln in g["dng_runs"] if d == p["d"]
                                      and (T.level_at(g["file"], ln) or 0) + 0.25 >= req), None)
                if not inherited:
                    WHY[(fac, qid)] = "giver inside, no run of a prerequisite"
                    continue
                run = inherited
                a = (run[1], run[2])
                if (T.level_at(mine[a[0]]["file"], a[1]) or 0) + 0.25 < req:
                    continue
            else:
                for g in seq:
                    if ((p["kind"] == "dungeon" or OUTDOOR) and g["added"] >= MAX_PER) or req > g["max"] + 1 or lvl < g["min"] - 2:
                        continue
                    cand = [an for an in g["anchors"] if near(an, p["giv"])
                            and all(before(done[x], g["id"], an[0]) for x in pg)
                            and (not ps or any(x in done and before(done[x], g["id"], an[0]) for x in ps))
                            and (T.level_at(g["file"], an[0]) or 0) + 0.25 >= req]
                    if cand:
                        a = (g["id"], cand[0][0])
                        break
                if not a:
                    WHY[(fac, qid)] = "no pickup point (giver not visited at that level)"
                    continue
            # complete and turn-in
            c = t = None
            if not run and p["fin_in"]:
                run = "new"  # the finisher is inside: go in right after the pickup
            if escort(q) and p["kind"] != "dungeon":
                c = a  # an escort starts at the giver
            elif p["kind"] == "outdoor":
                c = next(((gid, an[0]) for gid, an in ahead(*a) if near_any(an, p["obj"])
                          and (not OUTDOOR or (T.level_at(mine[gid]["file"], an[0]) or 0) + 2 >= lvl)), None)
                if not c:
                    WHY[(fac, qid)] = "objectives not visited after the pickup"
                    continue
            if p["fin_in"]:
                t = "run"
            else:
                after = c or a
                cand = [(gid, an[0]) for gid, an in ahead(*after) if near(an, p["fin"])]
                if p["kind"] == "dungeon" and run is None:
                    same = [x for x in cand if x[0] == a[0]]
                    cand = [same[-1]] if same else cand
                if not cand:
                    WHY[(fac, qid)] = "finisher not visited after the pickup"
                    continue
                t = cand[0]
            # write
            steps = []
            if run is None and p["kind"] == "dungeon":  # outdoor giver and finisher: the run sits before the turn-in
                k = slot()
                steps = [(a, slot(), "accept"), (t, k + 0.5, "complete"), (t, k + 0.6, "turnin")]
                runs[qid] = (p["d"], t[0], t[1], [k + 0.5])
            else:
                if run == "new":
                    k = slot()
                    run = (p["d"], a[0], a[1], [k])
                    steps.append((a, k, "accept"))
                else:
                    steps.append((a, slot(run if p["giv_in"] else None), "accept"))
                if p["kind"] == "dungeon":
                    if not run:
                        continue
                    steps.append(((run[1], run[2]), slot(run), "complete"))
                elif c:
                    steps.append((c, slot(), "complete"))
                if t == "run":
                    if not run:
                        continue
                    t = (run[1], run[2])
                    steps.append((t, slot(run), "turnin"))
                else:
                    steps.append((t, slot(), "turnin"))
                if run:
                    runs[qid] = run
            for (gid, ln), k, verb in steps:
                gg = mine[gid]
                flags = ["dungeon=" + p["d"]] if p["d"] else []
                if gg["faction"] == "Both":
                    flags.append("faction=" + fac)
                if verb != "accept" and gid != a[0] and not OUTDOOR:
                    flags.append("optional")
                txt = "%s %d %s" % (verb, qid, q[0]) + (" [%s]" % "; ".join(flags) if flags else "")
                if escort(q) and verb == "accept":
                    gg["inserts"].append((ln, k - 0.0005, escort_note(q, flags), fac, qid))
                if escort(q) and verb == "complete":
                    txt += " | " + ESCORT_STEP
                gg["inserts"].append((ln, k, txt, fac, qid))
            if (p["kind"] == "dungeon" or OUTDOOR) and not p["giv_in"]:
                mine[a[0]]["added"] += 1
            done[qid] = [t]
            WHY.pop((fac, qid), None)
            todo.remove(qid)
            progress = True
            report.append((fac, qid, "%s: %d %s (%d XP) - %s %s; pick up in %s, turn in in %s" % (
                fac, qid, q[0], T.xp.get(qid, 0), p["d"] or "outdoors", p["kind"], a[0], t[0])))

# Keep the roots (dungeon quests, or with --outdoor the cross-zone quests) and every chain member something kept
# follows on from.
kept = {(fac, qid) for fac, qid, _ in report if qid in ROOTS}
changed = True
while changed:
    changed = False
    for fac, qid, _ in report:
        if (fac, qid) in kept:
            continue
        if any((fac, y) in kept and qid in ids(f(T.Q[y], 13)) + ids(f(T.Q[y], 14)) for y in pool):
            kept.add((fac, qid))
            changed = True

if not DRY:
    for g in G.values():
        by = {}
        for ln, k, txt, fac, qid in g["inserts"]:
            if (fac, qid) in kept:
                by.setdefault(ln, []).append((k, txt))
        if not by:
            continue
        out = []
        for i, l in enumerate(g["lines"]):
            out.append(l)
            for k, txt in sorted(by.get(i, [])):
                out.append(txt)
        open(g["file"], "w", encoding="utf-8", newline="").write(g["nl"].join(out))
xp = 0
for fac, qid, r in report:
    if (fac, qid) in kept:
        print(r)
        xp += T.xp.get(qid, 0)
print("placed: %d %s quests, %d chain members, XP %d" % (
    sum(1 for fac, qid in kept if qid in ROOTS), "outdoor" if OUTDOOR else "dungeon", sum(1 for fac, qid in kept if qid not in ROOTS), xp))
# Why the rest is not on a route (docs/generated/<target>/dungeon-unplaced.csv; --why also prints it).
rows = sorted(((fac, f(pool[qid]["q"], 3) or 0, qid, pool[qid]["q"][0], pool[qid]["d"] or "outdoors", w) for (fac, qid), w in WHY.items()
               if qid in ROOTS))
if not DRY:
    with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "docs", "generated", T.name, "outdoor-unplaced.csv" if OUTDOOR else "dungeon-unplaced.csv"),
              "w", encoding="utf-8", newline="") as out:
        out.write("faction,level,quest,title,dungeon,reason\n")
        for r in rows:
            out.write('%s,%d,%d,"%s","%s","%s"\n' % (r[0], r[1], r[2], r[3].replace('"', '""'), r[4], r[5]))
if "--why" in sys.argv:
    for r in rows:
        print("not placed: %s %d %s (%s) - %s" % (r[0], r[2], r[3], r[4], r[5]))
