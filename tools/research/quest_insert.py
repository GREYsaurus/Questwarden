# Add candidate quests to guides by nearest-step placement (docs/ROUTE_OPTIMIZATION.md).
# Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
# SPDX-License-Identifier: GPL-3.0-only
#
# For each guide of a target, takes the quests from docs/generated/<Target>/quest-candidates.csv that:
#   - are started by an NPC that stands in the guide's zone (not an item or object),
#   - are not escorts, not repeatable, not class quests,
#   - have at least one objective location (or the finisher) in the zone,
#   - have no elite, rare-elite or boss among their kill objectives,
#   - have every prerequisite turned in earlier in this guide, or in a guide of the same faction that
#     starts at a lower level,
# and inserts accept / complete / turnin lines into the guide SOURCE: the accept after the existing step
# nearest the quest giver, the complete after the step nearest the objective area (never before the
# accept), the turn-in after the step nearest the finisher (never before the complete). Positions come
# from the compiled guide (each step's x,y) and from the bundled NPC and object spawns.
#
# This writes guide sources, which are our own content. Run the compiler and the route audit afterwards:
# they reject impossible orders and quest-log overflow, and every added quest is reviewed in the diff.
#
# Usage: python tools/research/quest_insert.py ClassicEra [--max-per-guide N] [--dry-run]
import csv
import glob
import json
import math
import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
args = [a for a in sys.argv[1:] if not a.startswith("--")]
target = args[0] if args else "ClassicEra"
DRY = "--dry-run" in sys.argv
MAXPER = 999
for i, a in enumerate(sys.argv):
    if a == "--max-per-guide":
        MAXPER = int(sys.argv[i + 1])
tdir = os.path.join(ROOT, "targets", target)
qdir = os.path.join(tdir, "addon", "Database", "Questie")


# ---- minimal Lua literal reader (tables, strings, numbers, booleans, nil) -------------------------
def parse_lua(s, i=0):
    def ws(i):
        while i < len(s) and s[i] in " \t\r\n":
            i += 1
        return i

    def val(i):
        i = ws(i)
        c = s[i]
        if c == "{":
            i += 1
            arr, hsh, n = [], {}, 1
            while True:
                i = ws(i)
                if s[i] == "}":
                    return (arr, hsh), i + 1
                if s[i] == "[":
                    k, i = val(i + 1)
                    i = ws(i)
                    assert s[i] == "]"
                    i = ws(i + 1)
                    assert s[i] == "="
                    v, i = val(i + 1)
                    hsh[k] = v
                else:
                    m = re.match(r"([A-Za-z_]\w*)\s*=", s[i:])
                    if m and not s[i:].startswith(("nil", "true", "false")) or (m and s[i + len(m.group(0)) - 1] == "=" and m.group(1) not in ("nil", "true", "false")):
                        i += len(m.group(0))
                        v, i = val(i)
                        hsh[m.group(1)] = v
                    else:
                        v, i = val(i)
                        arr.append(v)
                        n += 1
                i = ws(i)
                if s[i] in ",;":
                    i += 1
        if c in "\"'":
            q = c
            j = i + 1
            out = []
            while s[j] != q:
                if s[j] == "\\":
                    out.append(s[j + 1])
                    j += 2
                else:
                    out.append(s[j])
                    j += 1
            return "".join(out), j + 1
        for kw, v in (("nil", None), ("true", True), ("false", False)):
            if s.startswith(kw, i):
                return v, i + len(kw)
        m = re.match(r"-?\d+(\.\d+)?", s[i:])
        return (float(m.group(0)) if m.group(1) else int(m.group(0))), i + len(m.group(0))
    return val(i)[0]


def arr(t):
    return t[0] if isinstance(t, tuple) else []


def hsh(t):
    return t[1] if isinstance(t, tuple) else {}


def load(fn, prefix):
    d = {}
    for line in open(os.path.join(qdir, fn), encoding="utf-8"):
        m = re.match(r"^%s\[(\d+)\]=(\{.*\})\s*$" % prefix, line)
        if m:
            d[int(m.group(1))] = arr(parse_lua(m.group(2)))
    return d


Q = load("Quests.lua", "Q")


# NPCs, objects and items come from QuestieDB's FULL tables for the target (in .cache after
# tools/build.ps1 fetch), because the bundled subset leaves out the mobs that only drop quest items.
# Records are normalised to the bundled layout: NPC {name, min, max, rank, zone, spawns},
# object {name, zone, spawns}, item {name, npcDrops, objectDrops}.
def load_raw(fn, marker):
    info = json.load(open(os.path.join(tdir, "target.json"), encoding="utf-8"))["questie"]
    path = os.path.join(ROOT, ".cache", "upstream", "questiedb", info["dataDir"], info["prefix"] + fn)
    d = {}
    started = False
    for line in open(path, encoding="utf-8"):
        if not started:
            started = marker in line
            continue
        m = re.match(r"^\[(\d+)\] = (\{.*\}),\s*$", line)
        if m:
            try:
                d[int(m.group(1))] = arr(parse_lua(m.group(2)))
            except Exception:
                pass
    return d


def norm_npc(r):
    return [r[0], r[3], r[4], r[5], r[8] if len(r) > 8 else None, r[6]]


def norm_obj(r):
    return [r[0], r[4] if len(r) > 4 else None, r[3]]


N = {k: norm_npc(v) for k, v in load_raw("NpcDB.lua", "QuestieDB.npcData").items() if len(v) >= 7}
O = {k: norm_obj(v) for k, v in load_raw("ObjectDB.lua", "QuestieDB.objectData").items() if len(v) >= 4}
I = {k: [v[0], v[1], v[2]] for k, v in load_raw("ItemDB.lua", "QuestieDB.itemData").items() if len(v) >= 3}
print("full tables: %d npcs, %d objects, %d items" % (len(N), len(O), len(I)))

# Quests never added automatically, each with its reason (world events, endgame turn-ins).
EXCLUDE = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "quest_exclude.json"), encoding="utf-8")).get(target, {})


def f(rec, i):  # 1-based field
    return rec[i - 1] if len(rec) >= i else None


def ids(v):
    return [x for x in arr(v)] if v else []


def spawns(rec, field, zone):
    sp = hsh(f(rec, field))
    return [(p[0][0], p[0][1]) if False else (arr(p)[0], arr(p)[1]) for p in arr(sp.get(zone))] if sp.get(zone) else []


def npc_pts(nid, zone):
    r = N.get(nid)
    return spawns(r, 6, zone) if r else []


def obj_pts(oid, zone):
    r = O.get(oid)
    return spawns(r, 3, zone) if r else []


# ---- compiled guides: per guide, quest steps with coordinates ------------------------------------
comp = {}
for p in glob.glob(os.path.join(tdir, "addon", "Guides", "Compiled", "*.lua")):
    t = open(p, encoding="utf-8").read()
    m = re.search(r'id="([^"]+)", name="[^"]*", faction="(\w+)".*?minLevel=(\d+), maxLevel=(\d+), zone=(\d+)', t, re.S)
    if not m:
        continue
    gid = m.group(1)
    steps = []
    for sm in re.finditer(r'^    \{"(\w+)"(.*)\},\s*$', t, re.M):
        body = sm.group(2)
        q = re.search(r"\bq=(\d+)", body)
        z = re.search(r"\bz=(\d+),x=([\d.]+),y=([\d.]+)", body)
        steps.append(dict(kind=sm.group(1), q=int(q.group(1)) if q else None,
                          z=int(z.group(1)) if z else None, x=float(z.group(2)) if z else None, y=float(z.group(3)) if z else None,
                          classes="classes=" in body or "races=" in body))
    comp[gid] = dict(faction=m.group(2), min=int(m.group(3)), max=int(m.group(4)), zone=int(m.group(5)), steps=steps,
                     file=None)

# Guide id -> source file
for p in glob.glob(os.path.join(tdir, "guides-src", "*", "*.guide")):
    for line in open(p, encoding="utf-8"):
        m = re.match(r"^@guide\s+(\S+)", line)
        if m and m.group(1) in comp:
            comp[m.group(1)]["file"] = p
            break

turned_by = {}  # quest -> set of guides that turn it in
for gid, g in comp.items():
    for s in g["steps"]:
        if s["kind"] == "turnin" and s["q"]:
            turned_by.setdefault(s["q"], set()).add(gid)

# Model level at each guide source line (docs/generated/<Target>/step-levels.csv, written by the route audit
# BEFORE this run). A pickup goes only where the model says the character meets the quest's required level.
step_level = {}
for r in csv.DictReader(open(os.path.join(ROOT, "docs", "generated", target, "step-levels.csv"), encoding="utf-8-sig")):
    f_, ln = r["step"].rsplit(":", 1)
    step_level.setdefault(f_.replace("\\", "/"), {})[int(ln)] = float(r["modelLevel"])


def level_at(guide_file, line_index):
    rel = os.path.relpath(guide_file, os.path.join(tdir, "guides-src")).replace("\\", "/")
    d = step_level.get(rel, {})
    best = None
    for ln, lv in d.items():
        if ln <= line_index + 1 and (best is None or ln > best[0]):
            best = (ln, lv)
    return best[1] if best else None


cands = {}
for r in csv.DictReader(open(os.path.join(ROOT, "docs", "generated", target, "quest-candidates.csv"), encoding="utf-8")):
    cands.setdefault(r["guide"], []).append(r)


def dist(a, b):
    return math.hypot(a[0] - b[0], a[1] - b[1])


def centroid(pts):
    return (sum(p[0] for p in pts) / len(pts), sum(p[1] for p in pts) / len(pts)) if pts else None


VERB_RE = re.compile(r"^(accept|turnin|complete)\s")
report = []
WHY = {}
for gid, g in sorted(comp.items(), key=lambda kv: kv[1]["min"]):
    if not g["file"] or gid not in cands:
        continue
    zone = g["zone"]
    src = open(g["file"], encoding="utf-8", newline="").read()
    nl = "\r\n" if "\r\n" in src else "\n"
    lines = src.replace("\r\n", "\n").split("\n")
    # Source quest-step line indices align 1:1 with compiled quest steps (same order).
    src_q = [i for i, l in enumerate(lines) if VERB_RE.match(l)]
    cq = [s for s in g["steps"] if s["kind"] in ("accept", "turnin", "complete")]
    if len(src_q) != len(cq):
        report.append("%s: source/compiled quest steps differ (%d/%d); skipped" % (gid, len(src_q), len(cq)))
        continue
    anchors = [(src_q[k], (s["x"], s["y"])) for k, s in enumerate(cq) if s["z"] == zone and s["x"] is not None and not s["classes"]]
    if len(anchors) < 3:
        continue
    done_before = {}  # quest -> source line index of its turnin in this guide
    for k, s in enumerate(cq):
        if s["kind"] == "turnin" and s["q"]:
            done_before[s["q"]] = src_q[k]
    lower = {x for x, gs in turned_by.items() for og in gs
             if comp[og]["min"] < g["min"] and comp[og]["faction"] in (g["faction"], "Both")}
    inserts = []  # (after_line_index, order, text)
    added = 0
    taken = set()
    pending = list(cands[gid])
    progress = True
    while progress:
      progress = False
      for c in list(pending):
          if added >= MAXPER:
              break
          qid = int(c["quest"])
          if qid in taken:
              continue
          q = Q.get(qid)
          if not q or c["escort"] or str(qid) in EXCLUDE or (c["start"] != "npc" and not [o for o in ids(f(q, 7)) if obj_pts(o, zone)]):
              WHY["escort/item-start/excluded"] = WHY.get("escort/item-start/excluded", 0) + 1; continue
          if (f(q, 19) or 0) & 1:  # repeatable
              WHY["repeatable"] = WHY.get("repeatable", 0) + 1; continue
          givers = [("n", n) for n in ids(f(q, 6)) if npc_pts(n, zone)] + [("o", o) for o in ids(f(q, 7)) if obj_pts(o, zone)]
          enders = [n for n in ids(f(q, 9)) if npc_pts(n, zone)]
          if not givers or not enders:
              WHY["giver or finisher not in zone"] = WHY.get("giver or finisher not in zone", 0) + 1; continue
          obj = hsh(f(q, 12))
          kill = ids(obj.get("c")) + ids(obj.get("k"))
          if any((N.get(n) and (f(N[n], 4) or 0) in (1, 2, 3)) for n in kill):
              WHY["elite kill objective"] = WHY.get("elite kill objective", 0) + 1; continue
          opts = []
          for n in kill:
              opts += npc_pts(n, zone)
          for o in ids(obj.get("o")):
              opts += obj_pts(o, zone)
          if f(q, 23):  # requires reputation: endgame or faction grinds, not leveling quests
              WHY["reputation"] = WHY.get("reputation", 0) + 1; continue
          bad_item = False
          for it in ids(obj.get("i")):
              ir = I.get(it)
              dn = [n for n in ids(f(ir, 2)) if npc_pts(n, zone)] if ir else []
              do = [o for o in ids(f(ir, 3)) if obj_pts(o, zone)] if ir else []
              if not dn and not do:
                  bad_item = True  # not dropped in this zone: raid drops, crafted items, items from elsewhere
                  break
              if any(N.get(n) and (f(N[n], 4) or 0) in (1, 2, 3) for n in dn) and not do and                     all(N.get(n) and (f(N[n], 4) or 0) in (1, 2, 3) for n in dn):
                  bad_item = True  # only elites drop it
                  break
              for n in dn:
                  opts += npc_pts(n, zone)
              for o in do:
                  opts += obj_pts(o, zone)
          if bad_item:
              WHY["item not dropped in zone"] = WHY.get("item not dropped in zone", 0) + 1; continue
          gpos = centroid(npc_pts(givers[0][1], zone) if givers[0][0] == "n" else obj_pts(givers[0][1], zone))
          epos = centroid(npc_pts(enders[0], zone))
          opos = centroid(opts) if opts else None
          if (obj.get("c") or obj.get("o") or obj.get("k") or obj.get("i")) and not opos:
              WHY["objectives outside zone"] = WHY.get("objectives outside zone", 0) + 1; continue
          pre = ids(f(q, 13)) + ids(f(q, 14))
          preg, pres = ids(f(q, 13)), ids(f(q, 14))
          ia = min(anchors, key=lambda a: dist(a[1], gpos))[0]
          req = f(q, 2) or 0
          lv = level_at(g["file"], ia)
          if lv is not None and req > lv + 0.25:
              # Too early here: the next visit near the giver where the model level is high enough.
              near = min(dist(a[1], gpos) for a in anchors)
              later = [a for a in anchors if a[0] > ia and dist(a[1], gpos) <= near + 8
                       and (level_at(g["file"], a[0]) or 0) + 0.25 >= req]
              if not later:
                  WHY["level not reached near giver"] = WHY.get("level not reached near giver", 0) + 1
                  continue
              ia = later[0][0]
          ok_pre = all((p in lower) or (p in done_before and done_before[p] < ia) for p in preg)
          if pres:
              ok_pre = ok_pre and any((p in lower) or (p in done_before and done_before[p] < ia) for p in pres)
          if not ok_pre:
              WHY["prerequisite not earlier"] = WHY.get("prerequisite not earlier", 0) + 1; continue
          after_a = [a for a in anchors if a[0] >= ia]
          ic = min(after_a, key=lambda a: dist(a[1], opos))[0] if opos else ia
          after_c = [a for a in anchors if a[0] >= ic]
          it_ = min(after_c, key=lambda a: dist(a[1], epos))[0]
          title = q[0].replace('"', "'")
          flag = ""
          if g["faction"] == "Both":
              races = f(q, 4) or 0
              if races and not (races & 178):
                  flag = " [faction=Alliance]"
              elif races and not (races & 77):
                  flag = " [faction=Horde]"
          inserts.append((ia, 0, "accept %d %s%s" % (qid, q[0], flag)))
          if obj:
              inserts.append((ic, 1, "complete %d %s%s" % (qid, q[0], flag)))
          inserts.append((it_, 2, "turnin %d %s%s" % (qid, q[0], flag)))
          done_before[qid] = it_
          added += 1
          taken.add(qid)
          pending.remove(c)
          progress = True
          report.append("%s: + %d %s (%s XP)" % (gid, qid, q[0], c["xp"]))
    if not inserts or DRY:
        continue
    out = []
    by_line = {}
    for ln, order, text in inserts:
        by_line.setdefault(ln, []).append((order, text))
    for i, l in enumerate(lines):
        out.append(l)
        for order, text in sorted(by_line.get(i, []), key=lambda x: x[0]):
            out.append(text)
    open(g["file"], "w", encoding="utf-8", newline="").write(nl.join(out))

for r in report:
    print(r)
print("added", sum(1 for r in report if ": + " in r), "quests")
for k, v in sorted(WHY.items(), key=lambda kv: -kv[1]): print("  rejected: %-32s %d" % (k, v))
