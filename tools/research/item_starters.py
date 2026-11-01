# Audit of quests started by an item: how the starter is obtained (mob drop, object, neither in the data), whether a
# guide accepts the quest, and which steps of that guide already kill the mobs that drop the item.
#   python tools/research/item_starters.py <Target>
# Writes docs/generated/<Target>/item-starters.csv. Data: the target's bundled quests (Quests.lua) and QuestieDB's full
# item and NPC tables in .cache (tools/build.ps1 fetch). Nothing here is guessed: a source missing from the data is
# reported as missing.
# Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
# SPDX-License-Identifier: GPL-3.0-only
import csv
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import qdb  # noqa: E402

ALLIANCE, HORDE = 1101, 690


def faction(races):
    races = races or 0
    if races == 0:
        return "Both"
    a, h = races & ALLIANCE, races & HORDE
    return "Both" if a and h else ("Alliance" if a else ("Horde" if h else "?"))


def objective_npcs(T, q):
    """NPC ids a quest's objectives kill: creatures, kill credit and the droppers of its items."""
    rec = T.Q.get(q)
    obj = qdb.hsh(qdb.f(rec, 12)) if rec else {}
    out = set(qdb.ids(obj.get("c"))) | set(qdb.ids(obj.get("k")))
    for item in qdb.ids(obj.get("i")):
        it = T.I.get(item)
        if it:
            out |= set(qdb.ids(it[1]))
    return out


def main(name):
    T = qdb.Target(name)
    accepts = {}  # quest -> [(guide id, step index)]
    for gid, g in T.guides.items():
        for i, s in enumerate(g["steps"]):
            if s["kind"] == "accept" and s["q"]:
                accepts.setdefault(s["q"], []).append((gid, i))
    rows = []
    for q, rec in sorted(T.Q.items()):
        items = qdb.ids(qdb.f(rec, 8))
        if not items:
            continue
        item = items[0]
        it = T.I.get(item)
        drops = qdb.ids(it[1]) if it else []
        odrops = qdb.ids(it[2]) if it else []
        source = "mob" if drops else ("object" if odrops else "none in data")
        guided = accepts.get(q, [])
        overlap, where = [], []
        for gid, i in guided:
            g = T.guides[gid]
            for j, s in enumerate(g["steps"]):
                if s["kind"] == "complete" and s["q"] and objective_npcs(T, s["q"]) & set(drops):
                    overlap.append("%s#%d(q%d)%s" % (gid, j + 1, s["q"], "<" if j < i else ">"))
            where.append("%s#%d" % (gid, i + 1))
        zones = sorted({z for n in drops if T.N.get(n) for z in qdb.hsh(T.N[n][5]).keys()})
        rows.append(dict(quest=q, title=rec[0], item=item, itemName=it[0] if it else "", source=source,
                         droppers=len(drops), dropperNames="; ".join(sorted({T.N[n][0] for n in drops if n in T.N}))[:200],
                         dropZones=" ".join(str(z) for z in zones[:8]), faction=faction(qdb.f(rec, 4)),
                         reqLevel=qdb.f(rec, 2) or 0, level=qdb.f(rec, 3) or 0, classes=qdb.f(rec, 5) or 0,
                         prereqs=len(qdb.ids(qdb.f(rec, 13))) + len(qdb.ids(qdb.f(rec, 14))),
                         guideAccepts=" ".join(where), killStepsInGuide=" ".join(overlap)))
    out = os.path.join(qdb.ROOT, "docs", "generated", name, "item-starters.csv")
    with open(out, "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)
    by = {}
    for r in rows:
        k = (r["source"], "guided" if r["guideAccepts"] else "not guided")
        by[k] = by.get(k, 0) + 1
    print("%s: %d item-started quests -> %s" % (name, len(rows), out))
    for k in sorted(by):
        print("  %-14s %-11s %d" % (k[0], k[1], by[k]))
    mob_guided = [r for r in rows if r["source"] == "mob" and r["guideAccepts"]]
    print("  mob-dropped and guided: %d, with kill steps for the droppers in the same guide: %d"
          % (len(mob_guided), sum(1 for r in mob_guided if r["killStepsInGuide"])))


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "ClassicEra")
