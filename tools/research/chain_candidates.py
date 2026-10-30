# Quest chains no route uses yet, per faction, with the zones each step needs (docs/ROUTE_OPTIMIZATION.md).
# Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
# SPDX-License-Identifier: GPL-3.0-only
#
# Research aid only (writes a CSV report). Groups the target's quests into chains through their
# prerequisite and follow-up links, keeps chains with at least one quest no guide uses, open to the faction,
# not class/profession quests, and reports for each: levels, total unused XP, the zones of every giver and
# finisher, and whether each of those zones has a guide of that faction (or a shared one) at a level that fits.
#
# Usage: python tools/research/chain_candidates.py ClassicEra
import csv
import glob
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
target = sys.argv[1] if len(sys.argv) > 1 else "ClassicEra"
tdir = os.path.join(ROOT, "targets", target)
info = json.load(open(os.path.join(tdir, "target.json"), encoding="utf-8"))

import importlib.util
spec = importlib.util.spec_from_file_location("qi_parse", os.path.join(os.path.dirname(os.path.abspath(__file__)), "quest_insert.py"))
# Reuse the Lua reader without running quest_insert's main work: copy the function by exec of its source head.
src = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "quest_insert.py"), encoding="utf-8").read()
head = src[src.index("# ---- minimal Lua literal reader"):src.index("Q = load(")]
ns = {"re": re, "os": os}
exec(head, ns)
parse_lua, arr, hsh = ns["parse_lua"], ns["arr"], ns["hsh"]

qdir = os.path.join(tdir, "addon", "Database", "Questie")
Q = {}
for line in open(os.path.join(qdir, "Quests.lua"), encoding="utf-8"):
    m = re.match(r"^Q\[(\d+)\]=(\{.*\})\s*$", line)
    if m:
        Q[int(m.group(1))] = arr(parse_lua(m.group(2)))


def f(r, i):
    return r[i - 1] if r and len(r) >= i else None


def ids(v):
    return list(arr(v)) if v else []


raw = os.path.join(ROOT, ".cache", "upstream", "questiedb", info["questie"]["dataDir"])
NZ, OZ = {}, {}  # npc/object -> zones with spawns
for fn, marker, store, spf in ((info["questie"]["prefix"] + "NpcDB.lua", "QuestieDB.npcData", NZ, 7),
                               (info["questie"]["prefix"] + "ObjectDB.lua", "QuestieDB.objectData", OZ, 4)):
    on = False
    for line in open(os.path.join(raw, fn), encoding="utf-8"):
        if not on:
            on = marker in line
            continue
        m = re.match(r"^\[(\d+)\] = (\{.*\}),\s*$", line)
        if not m:
            continue
        try:
            r = arr(parse_lua(m.group(1) and m.group(2)))
        except Exception:
            continue
        sp = hsh(r[spf - 1]) if len(r) >= spf else {}
        store[int(m.group(1))] = sorted(k for k in sp.keys() if isinstance(k, int))

xp = {}
xpf = os.path.join(ROOT, ".cache", "upstream", "questiedb", info["questie"]["xp"])
for line in open(xpf, encoding="utf-8"):
    m = re.match(r"^\s*\[(\d+)\]\s*=\s*\{\s*(-?\d+)\s*,\s*(\d+)\s*\}", line)
    if m:
        xp[int(m.group(1))] = int(m.group(3))

used = set()
guides = []
for p in glob.glob(os.path.join(tdir, "addon", "Guides", "Compiled", "*.lua")):
    t = open(p, encoding="utf-8").read()
    used.update(int(x) for x in re.findall(r"\bq=(\d+)", t))
    m = re.search(r'id="([^"]+)", name="[^"]*", faction="(\w+)".*?minLevel=(\d+), maxLevel=(\d+), zone=(\d+), zoneName="([^"]*)"', t, re.S)
    if m:
        guides.append(dict(id=m.group(1), faction=m.group(2), min=int(m.group(3)), max=int(m.group(4)), zone=int(m.group(5)), name=m.group(6)))

MASK = {"Alliance": 77, "Horde": 178}
# Chains: undirected components over pre/next links.
adj = {}
for qid, q in Q.items():
    for p in ids(f(q, 13)) + ids(f(q, 14)):
        if p in Q:
            adj.setdefault(qid, set()).add(p)
            adj.setdefault(p, set()).add(qid)
    n = f(q, 17)
    if isinstance(n, int) and n in Q:
        adj.setdefault(qid, set()).add(n)
        adj.setdefault(n, set()).add(qid)
seen, comps = set(), []
for qid in Q:
    if qid in seen:
        continue
    stack, comp = [qid], []
    seen.add(qid)
    while stack:
        x = stack.pop()
        comp.append(x)
        for y in adj.get(x, ()):
            if y not in seen:
                seen.add(y)
                stack.append(y)
    comps.append(sorted(comp))


def zones_of(q):
    z = set()
    for n in ids(f(q, 6)) + ids(f(q, 9)):
        z.update(NZ.get(n, []))
    for o in ids(f(q, 7)) + ids(f(q, 10)):
        z.update(OZ.get(o, []))
    return z


rows = []
for fac in ("Alliance", "Horde"):
    fg = [g for g in guides if g["faction"] in (fac, "Both")]
    for comp in comps:
        qs = [Q[x] for x in comp]
        ok = [x for x in comp if (f(Q[x], 4) or 0) in (0,) or ((f(Q[x], 4) or 0) & MASK[fac])]
        ok = [x for x in ok if (f(Q[x], 5) or 0) == 0 and (f(Q[x], 22) is None) and not ((f(Q[x], 19) or 0) & 1)
              and (f(Q[x], 3) or 0) > 0 and (f(Q[x], 3) or 0) <= 60 and not f(Q[x], 23)]
        new = [x for x in ok if x not in used]
        if not new:
            continue
        lv = [f(Q[x], 3) for x in ok]
        zs = set()
        for x in ok:
            zs |= zones_of(Q[x])
        lo, hi = min(lv), max(lv)
        covered = []
        for z in sorted(zs):
            gz = [g["id"] for g in fg if g["zone"] == z and g["min"] - 3 <= hi and g["max"] + 3 >= lo]
            covered.append("%d:%s" % (z, "+".join(gz) if gz else "-"))
        rows.append(dict(faction=fac, quests=len(ok), new=len(new), used=len(ok) - len(new),
                         levels="%d-%d" % (lo, hi), xp_new=sum(xp.get(x, 0) for x in new),
                         all_zones_on_route="yes" if all(not c.endswith(":-") for c in covered) else "no",
                         zones=" ".join(covered),
                         titles="; ".join("%d %s%s" % (x, Q[x][0], "" if x in new else " (used)") for x in ok)[:400]))
rows.sort(key=lambda r: (r["faction"], -r["xp_new"]))
out = os.path.join(ROOT, "docs", "generated", target, "chain-candidates.csv")
with open(out, "w", encoding="utf-8", newline="") as fh:
    w = csv.DictWriter(fh, fieldnames=list(rows[0].keys()))
    w.writeheader()
    w.writerows(rows)
for fac in ("Alliance", "Horde"):
    rr = [r for r in rows if r["faction"] == fac]
    on = [r for r in rr if r["all_zones_on_route"] == "yes"]
    print("%s: %d chains with unused quests, %d XP; all zones on route: %d chains, %d XP" % (
        fac, len(rr), sum(r["xp_new"] for r in rr), len(on), sum(r["xp_new"] for r in on)))
print("wrote", os.path.relpath(out, ROOT))
