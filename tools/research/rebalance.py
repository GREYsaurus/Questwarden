# Re-balance routes for Classic XP: grind stops before quests the character is too low for, and guide
# level ranges from the route model (docs/ROUTE_OPTIMIZATION.md).
# Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
# SPDX-License-Identifier: GPL-3.0-only
#
#   grind  For every pickup in docs/generated/<Target>/level-gates.csv where the model character is at most
#          MAX_GAP levels short (lowest model level over all routes), insert a grind step just before it:
#          "grind <required level> <mobs> | ...". The mobs are non-elite hostile NPCs of the bundled data
#          that spawn in the guide's zone, near the pickup, at about the target level (the compiler checks
#          that each one exists and spawns there). A grind step is skipped when the guide already lifts the
#          model to that level shortly before. Larger gaps are reported, not patched.
#   levels Rewrite each guide's @levels to the model's level on entering and leaving it
#          (docs/generated/<Target>/guide-xp.csv), so the guide browser and guide selection match.
# Writes guide sources (our own content). Run guides + routes afterwards.
# Usage: python tools/research/rebalance.py ClassicEra grind|levels [--dry-run]
import csv
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from qdb import ROOT, Target, VERB_RE, centroid, dist, f, hsh, ids  # noqa: E402

args = [a for a in sys.argv[1:] if not a.startswith("--")]
T = Target(args[0] if args else "ClassicEra")
MODE = args[1] if len(args) > 1 else "grind"
DRY = "--dry-run" in sys.argv
MAX_GAP = 1.5  # grind stops only for small gaps; bigger ones are moved to a later pickup or dropped ('move')
for i, x in enumerate(sys.argv):
    if x == "--max-gap":
        MAX_GAP = float(sys.argv[i + 1])
SRC = os.path.join(T.dir, "guides-src")
GEN = os.path.join(ROOT, "docs", "generated", T.name)

# Bundled NPCs (the compiler only accepts these for grind steps): name, min, max, rank, zone, spawns, friendly
BN = {}
for line in open(os.path.join(T.qdir, "Npcs.lua"), encoding="utf-8"):
    m = re.match(r"^N\[(\d+)\]=(\{.*\})\s*$", line)
    if m:
        from qdb import parse_lua, arr  # noqa: E402
        BN[int(m.group(1))] = arr(parse_lua(m.group(2)))


def mobs_near(zone, pos, level):
    out = []
    for nid, r in BN.items():
        name, lo, hi, rank, friendly = r[0], f(r, 2) or 0, f(r, 3) or 0, f(r, 4) or 0, f(r, 7)
        if friendly or rank in (1, 2, 3) or not lo:
            continue
        if not (lo <= level + 1 and hi >= level - 2):
            continue
        sp = hsh(f(r, 6)).get(zone)
        if not sp:
            continue
        pts = [(p[0][0], p[0][1]) if False else (pp[0][0], pp[0][1]) if False else (arr(pp)[0], arr(pp)[1]) for pp in arr(sp)]
        d = min(dist(p, pos) for p in pts) if pos else 0
        out.append((d, name, nid))
    out.sort()
    names = []
    for d, name, nid in out:
        if name not in names and d <= 25:
            names.append(name)
        if len(names) == 2:
            break
    return names


def file_of(rel):
    return os.path.join(SRC, rel.replace("/", os.sep))


if MODE == "grind":
    gates = {}
    for r in csv.DictReader(open(os.path.join(GEN, "level-gates.csv"), encoding="utf-8-sig")):
        key = r["source"]
        lv = float(r["modelLevel"])
        if key not in gates or lv < gates[key][1]:
            gates[key] = (int(r["requiredLevel"]), lv, r["guide"], r["quest"], r["title"])
    by_file, big = {}, []
    for src, (req, lv, gid, qid, title) in gates.items():
        rel, ln = src.rsplit(":", 1)
        gap = req - lv
        if gap > MAX_GAP:
            big.append("%s %s (needs %d, model %.1f)" % (src, title, req, lv))
            continue
        by_file.setdefault(rel, []).append((int(ln), req, gid, int(qid), title))
    added = 0
    for rel, items in sorted(by_file.items()):
        p = file_of(rel)
        s = open(p, encoding="utf-8", newline="").read()
        nl = "\r\n" if "\r\n" in s else "\n"
        lines = s.replace("\r\n", "\n").split("\n")
        g = T.guides.get(items[0][2])
        zone = g["zone"] if g else None
        inserts = {}
        lifted = 0
        for ln, req, gid, qid, title in sorted(items):
            i = ln - 1  # 1-based source line -> index
            if i < 0 or i >= len(lines) or not lines[i].startswith("accept"):
                continue
            # an existing level/grind step for >= req within the 6 lines before makes it unnecessary
            near = [l for l in lines[max(0, i - 6):i] if re.match(r"^(level|grind) (\d+)", l) and int(re.match(r"^(level|grind) (\d+)", l).group(2)) >= req]
            if near or req <= lifted:
                continue
            q = T.Q.get(qid)
            pos = None
            for n in ids(f(q, 6)) if q else []:
                pts = T.npc_pts(n, zone)
                if pts:
                    pos = centroid(pts)
                    break
            mobs = mobs_near(zone, pos, req) if zone else []
            if mobs:
                txt = "grind %d %s | %s needs level %d: kill these nearby until you reach it." % (req, ", ".join(mobs), title, req)
            else:
                txt = "level %d | %s needs level %d: kill monsters nearby until you reach it." % (req, title, req)
            inserts.setdefault(i, []).append(txt)
            lifted = req
            added += 1
        if inserts and not DRY:
            out = []
            for i, l in enumerate(lines):
                for txt in inserts.get(i, []):
                    out.append(txt)
                out.append(l)
            open(p, "w", encoding="utf-8", newline="").write(nl.join(out))
    print("grind stops added:", added)
    print("gaps over %.0f levels left as they are: %d" % (MAX_GAP, len(big)))
    for b in big[:40]:
        print("  ", b)

elif MODE == "levels":
    rows = {r["guide"]: r for r in csv.DictReader(open(os.path.join(GEN, "guide-xp.csv"), encoding="utf-8-sig"))}
    changed = 0
    for gid, g in T.guides.items():
        r = rows.get(gid)
        if not r or not g["file"]:
            continue
        lo = max(1, int(float(r["modelIn"]) + 0.0001))
        hi = max(lo + 1, int(round(float(r["modelOut"]))))
        hi = min(hi, 60)
        p = g["file"]
        s = open(p, encoding="utf-8", newline="").read()
        m = re.search(r"^@levels (\d+)-(\d+)", s, re.M)
        if not m:
            continue
        if g.get("min") == 1 or "@start" in s:
            lo = 1
        new = "@levels %d-%d" % (lo, hi)
        if m.group(0) != new:
            print("%-28s %s -> %s" % (gid, m.group(0)[8:], new[8:]))
            if not DRY:
                s = s[:m.start()] + new + s[m.end():]
                open(p, "w", encoding="utf-8", newline="").write(s)
            changed += 1
    print("guides re-ranged:", changed)

if MODE == "move":
    # Pickups more than MAX_GAP levels early: move each to a later step near its giver where the model level
    # is high enough. If one of its objective/turn-in steps would then come before the pickup, the quest is
    # taken out of this guide instead (its steps there are removed), so no step is left without its pickup.
    gates = {}
    for r in csv.DictReader(open(os.path.join(GEN, "level-gates.csv"), encoding="utf-8-sig")):
        lv = float(r["modelLevel"])
        if r["source"] not in gates or lv < gates[r["source"]][1]:
            gates[r["source"]] = (int(r["requiredLevel"]), lv, r["guide"], int(r["quest"]), r["title"])
    work = {}
    for src, (req, lv, gid, qid, title) in gates.items():
        if req - lv > MAX_GAP:
            rel, ln = src.rsplit(":", 1)
            work.setdefault(rel, []).append((int(ln) - 1, req, gid, qid, title))
    moved = removed = 0
    dropped_ids = set()
    for rel, items in sorted(work.items()):
        p = file_of(rel)
        s = open(p, encoding="utf-8", newline="").read()
        nl = "\r\n" if "\r\n" in s else "\n"
        lines = s.replace("\r\n", "\n").split("\n")
        g = T.guides.get(items[0][2])
        src_q = [i for i, l in enumerate(lines) if VERB_RE.match(l)]
        cq = [st for st in g["steps"] if st["kind"] in ("accept", "turnin", "complete")]
        if len(src_q) != len(cq):
            print("skip", rel, "(source/compiled differ)")
            continue
        anchors = [(src_q[k], (st["x"], st["y"])) for k, st in enumerate(cq) if st["z"] == g["zone"] and st["x"] is not None]
        drop, move_to = set(), {}
        for i, req, gid, qid, title in items:
            if i >= len(lines) or not lines[i].startswith("accept"):
                continue
            q = T.Q.get(qid)
            gpos = None
            for n in ids(f(q, 6)) if q else []:
                pts = T.npc_pts(n, g["zone"])
                if pts:
                    gpos = centroid(pts)
                    break
            mine = [k for k, l in enumerate(lines) if VERB_RE.match(l) and re.match(r"^\w+ %d\b" % qid, l)]
            if not mine:
                head = lines[i].split("|")[0].split("[")[0].strip()[len("accept "):]
                mine = [k for k, l in enumerate(lines) if VERB_RE.match(l) and l.split("|")[0].split("[")[0].strip().split(" ", 1)[-1] == head]
            target = None
            if gpos:
                near = min(dist(a[1], gpos) for a in anchors) if anchors else 99
                later = [a for a in anchors if a[0] > i and dist(a[1], gpos) <= near + 8
                         and (T.level_at(p, a[0]) or 0) + 0.25 >= req]
                if later:
                    target = later[0][0]
            others = [k for k in mine if k != i]
            if target is not None and all(k > target for k in others):
                move_to[i] = target
                moved += 1
                print("move  %s:%d %s -> after line %d" % (rel, i + 1, title, target + 1))
            else:
                drop.update(mine)
                dropped_ids.add(qid)
                removed += 1
                print("drop  %s:%d %s (needs %d; no later pickup spot before its other steps)" % (rel, i + 1, title, req))
        if DRY:
            continue
        out = []
        pending = {}
        for i, tgt in move_to.items():
            pending.setdefault(tgt, []).append(lines[i])
        for i, l in enumerate(lines):
            if i in drop or i in move_to:
                pass
            else:
                out.append(l)
            for moved_line in pending.get(i, []):
                out.append(moved_line)
        open(p, "w", encoding="utf-8", newline="").write(nl.join(out))
    # A dropped quest's steps in OTHER guides go too (matched by quest id through the compiled guides),
    # so no later guide asks for a turn-in of a quest the route no longer picks up.
    elsewhere = 0
    for gid, g2 in T.guides.items():
        if not g2["file"] or DRY:
            continue
        s2 = open(g2["file"], encoding="utf-8", newline="").read()
        nl2 = "\r\n" if "\r\n" in s2 else "\n"
        L2 = s2.replace("\r\n", "\n").split("\n")
        sq = [i for i, l in enumerate(L2) if VERB_RE.match(l)]
        cq2 = [st for st in g2["steps"] if st["kind"] in ("accept", "turnin", "complete")]
        if len(sq) != len(cq2):
            continue
        kill = {sq[k] for k, st in enumerate(cq2) if st["q"] in dropped_ids}
        # lines this run already removed or moved in this file are handled above
        if kill:
            elsewhere += len(kill)
            open(g2["file"], "w", encoding="utf-8", newline="").write(nl2.join(l for i, l in enumerate(L2) if i not in kill))
    print("moved %d pickups, removed %d quests from guides where they came too early (%d steps in other guides)" % (moved, removed, elsewhere))
