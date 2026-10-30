# Quest candidates per guide: quests a route could add to cut grinding (docs/ROUTE_OPTIMIZATION.md).
# Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
# SPDX-License-Identifier: GPL-3.0-only
#
# Research aid only: reads the target's generated data and compiled guides, writes a CSV report.
# For every guide it lists the quests that start in the guide's zone, are open to its faction, fit its
# level band (required level <= guide max, quest level >= guide min - 2) and are used by NO guide yet,
# with the quest XP from the target's QuestieDB XP table. It does not judge travel, chains or danger:
# a person reviews each candidate before it goes into a guide.
#
# Usage (repository root, after tools/build.ps1 fetch and guides):
#   python tools/research/quest_candidates.py ClassicEra
# Output: docs/generated/<Target>/quest-candidates.csv and a per-guide summary on stdout.
import csv
import glob
import json
import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
target = sys.argv[1] if len(sys.argv) > 1 else "ClassicEra"
tdir = os.path.join(ROOT, "targets", target)
info = json.load(open(os.path.join(tdir, "target.json"), encoding="utf-8"))
qdir = os.path.join(tdir, "addon", "Database", "Questie")

# Quests: Q[id]={"name",req,level,races,classes,{startNpcs},{startObjs},{startItems},...,zone at 15}
quests = {}
for line in open(os.path.join(qdir, "Quests.lua"), encoding="utf-8"):
    m = re.match(r'^Q\[(\d+)\]=\{"((?:[^"\\]|\\.)*)",(\d+),(-?\d+),(\d+),(\d+),', line)
    if not m:
        continue
    qid, name, req, lvl, races, classes = int(m.group(1)), m.group(2), int(m.group(3)), int(m.group(4)), int(m.group(5)), int(m.group(6))
    # zone is field 15: count top-level fields
    body, depth, field, cur, fields = line[line.index("{") + 1:], 0, 1, "", []
    instr = False
    for ch in body:
        if instr:
            cur += ch
            if ch == '"' and not cur.endswith('\\"'):
                instr = False
            continue
        if ch == '"':
            instr = True
            cur += ch
        elif ch == "{":
            depth += 1
            cur += ch
        elif ch == "}":
            if depth == 0:
                fields.append(cur)
                break
            depth -= 1
            cur += ch
        elif ch == "," and depth == 0:
            fields.append(cur)
            cur = ""
        else:
            cur += ch
    zone = int(fields[14]) if len(fields) > 14 and re.match(r"^-?\d+$", fields[14] or "") else 0
    starts = fields[5] if len(fields) > 5 else "nil"
    quests[qid] = dict(name=name, req=req, level=lvl, races=races, classes=classes, zone=zone,
                       starts=starts, flags=fields[25] if len(fields) > 25 else "")

# Quest XP from the target's QuestieDB table (Classic: [id] = {level, xp}).
xp = {}
xpfile = os.path.join(ROOT, ".cache", "upstream", "questiedb", info["questie"]["xp"])
if os.path.exists(xpfile):
    for line in open(xpfile, encoding="utf-8"):
        m = re.match(r"^\s*\[(\d+)\]\s*=\s*\{\s*(-?\d+)\s*,\s*(\d+)\s*\}", line)
        if m:
            xp[int(m.group(1))] = int(m.group(3))

# Quests already used by any guide, and each guide's header.
used, guides = set(), []
for p in glob.glob(os.path.join(tdir, "addon", "Guides", "Compiled", "*.lua")):
    t = open(p, encoding="utf-8").read()
    used.update(int(x) for x in re.findall(r"\bq=(\d+)", t))
    for g in re.finditer(r'Register\(\{\s*id="([^"]+)".*?faction="(\w+)".*?minLevel=(\d+), maxLevel=(\d+), zone=(\d+), zoneName="([^"]*)"', t, re.S):
        guides.append(dict(id=g.group(1), faction=g.group(2), min=int(g.group(3)), max=int(g.group(4)), zone=int(g.group(5)), zoneName=g.group(6)))

MASK = {"Alliance": 77, "Horde": 178}
rows = []
for g in sorted(guides, key=lambda g: (g["min"], g["id"])):
    fac = [g["faction"]] if g["faction"] in MASK else ["Alliance", "Horde"]
    for qid, q in quests.items():
        if qid in used or q["zone"] != g["zone"] or q["classes"] != 0:
            continue
        if q["req"] > g["max"] or q["level"] < g["min"] - 2 or q["level"] <= 0:
            continue
        if not any(q["races"] == 0 or (q["races"] & MASK[f]) for f in fac):
            continue
        rows.append(dict(guide=g["id"], levels="%d-%d" % (g["min"], g["max"]), quest=qid, title=q["name"].replace('\\"', '"'),
                         req=q["req"], level=q["level"], xp=xp.get(qid, 0),
                         escort="yes" if q["flags"].strip() == "2" else "", start="item/object" if q["starts"] == "nil" else "npc"))

out = os.path.join(ROOT, "docs", "generated", target, "quest-candidates.csv")
os.makedirs(os.path.dirname(out), exist_ok=True)
rows.sort(key=lambda r: (r["guide"], -r["xp"]))
with open(out, "w", encoding="utf-8", newline="") as f:
    w = csv.DictWriter(f, fieldnames=["guide", "levels", "quest", "title", "req", "level", "xp", "escort", "start"])
    w.writeheader()
    w.writerows(rows)
tot = {}
for r in rows:
    tot.setdefault(r["guide"], [0, 0])
    tot[r["guide"]][0] += 1
    tot[r["guide"]][1] += r["xp"]
for g in sorted(guides, key=lambda g: (g["min"], g["id"])):
    n, x = tot.get(g["id"], [0, 0])
    print("%-28s %-6s %3d candidates  %7d XP" % (g["id"], "%d-%d" % (g["min"], g["max"]), n, x))
print("wrote", os.path.relpath(out, ROOT), "-", len(rows), "candidates")
