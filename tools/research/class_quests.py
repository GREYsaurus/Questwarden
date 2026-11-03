# List class quests (quests only some classes can take) that no guide of the faction has, by class and level.
# Read-only; the guide steps are written by hand.
# Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
# SPDX-License-Identifier: GPL-3.0-only
#
# A class quest here: its class mask names some but not all classes, it is not repeatable, and its races include
# one of the faction's. "In a guide": any compiled guide step of that faction names the quest id. Each row shows the
# quest, its levels, races, giver (and the giver's zone), the quest before it and the one after it, so chains can be
# read top to bottom.
# Usage: python -I tools/research/class_quests.py <Target> [--max LEVEL] [--class NAME]
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from qdb import Target, f, ids  # noqa: E402

CLASSES = {1: "Warrior", 2: "Paladin", 4: "Hunter", 8: "Rogue", 16: "Priest", 64: "Shaman", 128: "Mage", 256: "Warlock",
           1024: "Druid"}
ALL_CLASSES = sum(CLASSES)
RACES = {1: "Human", 2: "Orc", 4: "Dwarf", 8: "NightElf", 16: "Undead", 32: "Tauren", 64: "Gnome", 128: "Troll"}
SIDE = {"Alliance": 1 | 4 | 8 | 64, "Horde": 2 | 16 | 32 | 128}
args = [a for a in sys.argv[1:] if not a.startswith("--")]
T = Target(args[0] if args else "ClassicEra")
MAX = int(sys.argv[sys.argv.index("--max") + 1]) if "--max" in sys.argv else 60
ONLY = sys.argv[sys.argv.index("--class") + 1] if "--class" in sys.argv else None


def names(mask, table):
    return ",".join(n for b, n in sorted(table.items()) if mask & b)


def zone_name(z):
    return str(z)


for fac in ("Horde", "Alliance"):
    have = set()
    for g in T.guides.values():
        if g["faction"] in (fac, "Both"):
            have |= {s["q"] for s in g["steps"] if s["q"]}
    rows = []
    for qid, q in T.Q.items():
        cls = f(q, 5) or 0
        races = f(q, 4) or 0
        if not cls or (cls & ALL_CLASSES) == ALL_CLASSES:
            continue
        if races and not (races & SIDE[fac]):
            continue
        if ((f(q, 26) or 0) & 1) or qid in have:
            continue
        lvl = f(q, 3) or 0
        if lvl > MAX or lvl <= 0:
            continue
        cn = names(cls, CLASSES)
        if ONLY and ONLY not in cn.split(","):
            continue
        givers = ids(f(q, 6))
        gz = [T.N[n][4] for n in givers if n in T.N]
        gname = [T.N[n][0] for n in givers if n in T.N]
        rows.append((cn, lvl, qid, q[0], f(q, 2) or 0, names(races & SIDE[fac], RACES) if races else "all",
                     "/".join(gname[:2]) or "(item or object)", gz[0] if gz else "?", ids(f(q, 14)) + ids(f(q, 13)), f(q, 17)))
    print("== %s: %d class quests not in any guide (level <= %d) ==" % (fac, len(rows), MAX))
    for r in sorted(rows):
        print("%-22s L%2d q%-5d %-34s req%2d %-28s giver %-26s zone %-5s pre %-14s next %s" % (
            r[0][:22], r[1], r[2], r[3][:34], r[4], r[5][:28], r[6][:26], r[7], r[8] or "-", r[9] or "-"))
