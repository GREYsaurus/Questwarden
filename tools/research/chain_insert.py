# Add whole quest chains to a target's guides, across guides (docs/ROUTE_OPTIMIZATION.md).
# Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
# SPDX-License-Identifier: GPL-3.0-only
#
# For each faction, the guides of that faction (and shared ones) are ordered by level. A chain from
# docs/generated/<Target>/chain-candidates.csv is placed member by member, in prerequisite order:
#   accept   - in the earliest guide (at or after the previous member's turn-in) whose zone has the giver
#              and whose level band fits; after the step nearest the giver, where the route audit's model
#              level meets the quest's required level;
#   complete - in the first guide from there whose zone holds the objectives, after the nearest step;
#   turnin   - in the first guide from there whose zone has the finisher, after the nearest step.
# Members already on a route count as done where they are turned in. A member that cannot be placed
# (elite targets, objectives in a dungeon or a zone without a guide, level too high, prerequisites not
# done, or a pickup held across more than MAX_SPAN guides) ends the chain there.
# Steps in a different guide from their accept are [optional], so routes that skipped the pickup
# guide skip them too. Shared guides get [faction=...]. Excluded quests: quest_exclude.json.
# Escorts are placed like any member, with a note before the accept saying the next quest is an escort and
# the complete step right after the accept (the escort starts at the giver); other scripted events are left out.
#
# Writes guide sources (our own content). Run guides + routes afterwards; the route audit is the judge.
# Usage: python tools/research/chain_insert.py ClassicEra [--dry-run] [--min-xp N]
import csv
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from qdb import ESCORT_STEP, ROOT, Target, VERB_RE, centroid, dist, escort, escort_note, event_only, f, hsh, ids  # noqa: E402

args = [a for a in sys.argv[1:] if not a.startswith("--")]
T = Target(args[0] if args else "ClassicEra")
DRY = "--dry-run" in sys.argv
MIN_XP = 0
for i, a in enumerate(sys.argv):
    if a == "--min-xp":
        MIN_XP = int(sys.argv[i + 1])
MAX_SPAN = 2  # a pickup may be turned in at most this many guides later
EXCLUDE = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "quest_exclude.json"), encoding="utf-8")).get(T.name, {})
MASK = {"Alliance": 77, "Horde": 178}

# ---- guides: aligned source lines and anchors ------------------------------------------------
G = {}
for gid, g in T.guides.items():
    if not g["file"]:
        continue
    src = open(g["file"], encoding="utf-8", newline="").read()
    lines = src.replace("\r\n", "\n").split("\n")
    src_q = [i for i, l in enumerate(lines) if VERB_RE.match(l)]
    cq = [s for s in g["steps"] if s["kind"] in ("accept", "turnin", "complete")]
    if len(src_q) != len(cq):
        print("skip %s: source/compiled quest steps differ (%d/%d)" % (gid, len(src_q), len(cq)))
        continue
    anchors = [(src_q[k], (s["x"], s["y"])) for k, s in enumerate(cq)
               if s["z"] == g["zone"] and s["x"] is not None and not s["filtered"]]
    turn = {s["q"]: src_q[k] for k, s in enumerate(cq) if s["kind"] == "turnin" and s["q"]}
    G[gid] = dict(g, lines=lines, nl="\r\n" if "\r\n" in src else "\n", anchors=anchors, turn=turn, inserts=[])

# ---- chains -------------------------------------------------------------------------------------
cands = [r for r in csv.DictReader(open(os.path.join(ROOT, "docs", "generated", T.name, "chain-candidates.csv"), encoding="utf-8"))
         if r["all_zones_on_route"] == "yes" and int(r["xp_new"]) >= MIN_XP]


def members_of(row):
    out = []
    for part in row["titles"].split("; "):
        head = part.split(" ", 1)[0]
        if head.isdigit():
            out.append(int(head))
    return out


def topo(ms):
    ms = [m for m in ms if m in T.Q]
    order, done = [], set()
    while len(order) < len(ms):
        progressed = False
        for m in ms:
            if m in done:
                continue
            pre = [p for p in ids(f(T.Q[m], 13)) + ids(f(T.Q[m], 14)) if p in ms]
            if all(p in done for p in pre):
                order.append(m)
                done.add(m)
                progressed = True
        if not progressed:
            break
    return order


def place_zone_pts(q, kind):
    """{zone: [points]} for a quest's giver ('a'), objectives ('c') or finisher ('t')."""
    out = {}
    if kind == "a":
        for n in ids(f(q, 6)):
            for z, pts in hsh(T.N[n][5]).items() if T.N.get(n) else []:
                out.setdefault(z, []).extend(T.npc_pts(n, z))
        for o in ids(f(q, 7)):
            for z in hsh(T.O[o][2]).keys() if T.O.get(o) else []:
                out.setdefault(z, []).extend(T.obj_pts(o, z))
    elif kind == "t":
        for n in ids(f(q, 9)):
            for z in hsh(T.N[n][5]).keys() if T.N.get(n) else []:
                out.setdefault(z, []).extend(T.npc_pts(n, z))
        for o in ids(f(q, 10)):
            for z in hsh(T.O[o][2]).keys() if T.O.get(o) else []:
                out.setdefault(z, []).extend(T.obj_pts(o, z))
    else:
        obj = hsh(f(q, 12))
        for n in ids(obj.get("c")) + ids(obj.get("k")):
            for z in hsh(T.N[n][5]).keys() if T.N.get(n) else []:
                out.setdefault(z, []).extend(T.npc_pts(n, z))
        for o in ids(obj.get("o")):
            for z in hsh(T.O[o][2]).keys() if T.O.get(o) else []:
                out.setdefault(z, []).extend(T.obj_pts(o, z))
        for it in ids(obj.get("i")):
            ir = T.I.get(it)
            if not ir:
                continue
            for n in ids(ir[1]):
                if T.hostile_elite(n):
                    continue
                for z in hsh(T.N[n][5]).keys() if T.N.get(n) else []:
                    out.setdefault(z, []).extend(T.npc_pts(n, z))
            for o in ids(ir[2]):
                for z in hsh(T.O[o][2]).keys() if T.O.get(o) else []:
                    out.setdefault(z, []).extend(T.obj_pts(o, z))
    return {z: p for z, p in out.items() if p}


report, WHY = [], {}


def why(k):
    WHY[k] = WHY.get(k, 0) + 1


for fac in ("Alliance", "Horde"):
    seq = sorted([g for g in G.values() if g["faction"] in (fac, "Both")], key=lambda g: (g["min"], g["max"], g["id"]))
    pos_of = {g["id"]: i for i, g in enumerate(seq)}
    # quests turned in on this faction's guides -> earliest (seq, line)
    done = {}
    for i, g in enumerate(seq):
        for qid, ln in g["turn"].items():
            if qid not in done:
                done[qid] = (i, ln)

    def find(zone_pts, after, req=None, lvl_check=False, max_seq=None):
        """Earliest (seq, line) at or after `after` in a guide of the right zone; nearest anchor there."""
        for i in range(after[0], len(seq) if max_seq is None else min(len(seq), max_seq + 1)):
            g = seq[i]
            if g["zone"] not in zone_pts:
                continue
            if req is not None and g["max"] + 2 < req:
                continue
            c = centroid(zone_pts[g["zone"]])
            cand = [a for a in g["anchors"] if i > after[0] or a[0] > after[1]]
            if not cand:
                continue
            best = min(cand, key=lambda a: dist(a[1], c))
            if lvl_check and req:
                lv = T.level_at(g["file"], best[0])
                if lv is not None and lv + 0.25 < req:
                    near = dist(best[1], c)
                    later = [a for a in cand if a[0] > best[0] and dist(a[1], c) <= near + 8
                             and (T.level_at(g["file"], a[0]) or 0) + 0.25 >= req]
                    if not later:
                        continue
                    best = later[0]
            return (i, best[0])
        return None

    for row in [r for r in cands if r["faction"] == fac]:
        for m in topo(members_of(row)):
            q = T.Q[m]
            if m in done:
                continue
            if str(m) in EXCLUDE:
                why("excluded")
                break
            if not T.xp.get(m) and not any(m in ids(f(T.Q[x], 13)) + ids(f(T.Q[x], 14)) for x in members_of(row) if x in T.Q):
                why("no XP and nothing after it (seasonal events, notes)")
                break
            races = f(q, 4) or 0
            if races and not (races & MASK[fac]):
                break
            if (f(q, 5) or 0) or ((f(q, 19) or 0) & 1) or f(q, 23) or event_only(q):
                why("class/repeatable/reputation/scripted event")
                break
            obj = hsh(f(q, 12))
            if any(T.hostile_elite(n) for n in ids(obj.get("c")) + ids(obj.get("k"))):
                why("elite target")
                break
            pg, ps = ids(f(q, 13)), ids(f(q, 14))
            if not all(p in done for p in pg) or (ps and not any(p in done for p in ps)):
                why("prerequisite not on route")
                break
            after = max([done[p] for p in pg] + ([min(done[p] for p in ps if p in done)] if ps else []) + [(0, -1)])
            req = f(q, 2) or 0
            a = find(place_zone_pts(q, "a"), after, req, lvl_check=True)
            if not a:
                why("no pickup spot at the right level")
                break
            c = a
            if obj and not escort(q):
                c = find(place_zone_pts(q, "c"), a, max_seq=a[0] + MAX_SPAN)
                if not c:
                    why("objectives not on a guide (dungeon or other zone)")
                    break
            t = find(place_zone_pts(q, "t"), c, max_seq=a[0] + MAX_SPAN)
            if not t:
                why("finisher not reachable within %d guides" % MAX_SPAN)
                break
            name = q[0]
            for (si, ln), order, verb in ((a, 0, "accept"), (c, 1, "complete"), (t, 2, "turnin")):
                if verb == "complete" and not obj and not escort(q):
                    continue
                g = seq[si]
                flags = []
                if g["faction"] == "Both":
                    flags.append("faction=" + fac)
                if verb != "accept" and si != a[0]:
                    flags.append("optional")
                txt = "%s %d %s%s" % (verb, m, name, (" [" + "; ".join(flags) + "]") if flags else "")
                if escort(q) and verb == "accept":
                    g["inserts"].append((ln, len(g["inserts"]), escort_note(q, flags)))
                if escort(q) and verb == "complete":
                    txt += " | " + ESCORT_STEP
                g["inserts"].append((ln, len(g["inserts"]), txt))
            done[m] = t
            report.append("%s %s: + %d %s (%s XP) accept in %s, turn-in in %s" % (
                fac, row["levels"], m, name, T.xp.get(m, 0), seq[a[0]]["id"], seq[t[0]]["id"]))

added = 0
for g in G.values():
    if not g["inserts"] or DRY:
        continue
    by = {}
    for ln, k, txt in g["inserts"]:
        by.setdefault(ln, []).append((k, txt))
    out = []
    for i, l in enumerate(g["lines"]):
        out.append(l)
        for k, txt in sorted(by.get(i, [])):
            out.append(txt)
            added += txt.startswith("accept")
    open(g["file"], "w", encoding="utf-8", newline="").write(g["nl"].join(out))
for r in report:
    print(r)
print("chain quests placed:", len(report), "XP", sum(T.xp.get(int(r.split("+ ")[1].split(" ")[0]), 0) for r in report))
for k, v in sorted(WHY.items(), key=lambda kv: -kv[1]):
    print("  chain stopped: %-48s %d" % (k, v))
