# Leveling gaps and the item-started quests that could fill them: for every guide whose route model still needs
# grinding (docs/generated/<Target>/guide-xp.csv, grindLevels), the quests started by a mob-dropped item that no
# guide uses yet, open to the guide's faction and every class, with no prerequisite, in the guide's level band,
# and dropped by NPCs that spawn in the guide's zone. Quest XP from the target's QuestieDB XP table.
#   python tools/research/item_starter_gaps.py <Target>
# Writes docs/generated/<Target>/item-starter-gaps.csv. Research aid only: a person reviews each candidate (travel,
# where its objectives and turn-in are, how rare the drop is) before it goes into a guide. Needs item_starters.py
# to have run first.
# Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
# SPDX-License-Identifier: GPL-3.0-only
import csv
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import qdb  # noqa: E402


def main(name):
    T = qdb.Target(name)
    gen = os.path.join(qdb.ROOT, "docs", "generated", name)
    xp_need = (T.info.get("xpPerLevel") or {}).get("values") or []  # [N-1] = XP from level N to N+1
    gxp = {r["guide"]: r for r in csv.DictReader(open(os.path.join(gen, "guide-xp.csv"), encoding="utf-8-sig"))}
    starters = list(csv.DictReader(open(os.path.join(gen, "item-starters.csv"), encoding="utf-8")))
    rows, total_gap, total_xp = [], 0.0, 0
    for gid, g in sorted(T.guides.items(), key=lambda kv: (kv[1]["min"], kv[0])):
        r = gxp.get(gid)
        gap = float(r["grindLevels"]) if r else 0.0
        if gap <= 0:
            continue
        total_gap += gap
        lo, hi = float(r["modelOut"]) - gap, float(r["modelOut"])
        # XP the grind stands for: the levels between where quests alone leave you and the guide's exit level.
        need, lv = 0, lo
        while lv < hi - 1e-6 and xp_need:
            step = min(1.0, hi - lv, int(lv) + 1 - lv)
            need += step * (xp_need[int(lv) - 1] if 1 <= int(lv) <= len(xp_need) else 0)
            lv += step
        cands = []
        for s in starters:
            if s["source"] != "mob" or s["guideAccepts"] or s["classes"] not in ("0", ""):
                continue
            if s["prereqs"] not in ("0", ""):
                continue
            if g["faction"] != "Both" and s["faction"] not in ("Both", g["faction"]):
                continue
            req, lvl = int(s["reqLevel"] or 0), int(s["level"] or 0)
            if lvl <= 0 or req > g["max"] or lvl < g["min"] - 2 or lvl > g["max"] + 2:
                continue
            if str(g["zone"]) not in s["dropZones"].split():
                continue
            q = int(s["quest"])
            cands.append(dict(quest=q, title=s["title"], item=s["itemName"], droppers=s["dropperNames"], level=lvl,
                              req=req, xp=T.xp.get(q, 0)))
        cxp = sum(c["xp"] for c in cands)
        total_xp += cxp
        for c in sorted(cands, key=lambda c: -c["xp"]) or [None]:
            row = dict(guide=gid, levels="%d-%d" % (g["min"], g["max"]), grindLevels="%.2f" % gap, grindXp=int(need),
                       candidateXp=cxp, quest="", title="", item="", droppers="", level="", req="", xp="")
            if c:
                row.update({k: c[k] for k in ("quest", "title", "item", "droppers", "level", "req", "xp")})
            rows.append(row)
        print("%-30s grind %.2f levels (~%6d XP)  item-started candidates: %2d, %6d XP%s" % (
            gid, gap, need, len(cands), cxp, ("  (%.0f%% of the grind)" % (100.0 * cxp / need)) if need else ""))
    out = os.path.join(gen, "item-starter-gaps.csv")
    with open(out, "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=["guide", "levels", "grindLevels", "grindXp", "candidateXp", "quest", "title",
                                           "item", "droppers", "level", "req", "xp"])
        w.writeheader()
        w.writerows(rows)
    print("%s: %.1f grind levels across guides; unguided item-started candidates add %d quest XP -> %s"
          % (name, total_gap, total_xp, os.path.relpath(out, qdb.ROOT)))


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "ClassicEra")
