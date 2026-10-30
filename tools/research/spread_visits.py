# Spread quests across a zone's repeat visits (zone-order routes, docs/ROUTE_OPTIMIZATION.md).
# Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
# SPDX-License-Identifier: GPL-3.0-only
#
# zone_order.py puts each quest in the first visit of its zone that fits, so later visits to the same zone
# can end up empty. This moves a group of quests from a visit A to a later visit B of the same zone when:
#   - the group is a quest plus everything in A that needs it (recursively), and every step of every member
#     is in A (accept, complete, turn-in);
#   - the group's lowest quest level is nearer the middle of B's level range than of A's, and B's top level
#     meets every member's required level;
#   - no other quest that needs a member is picked up before the end of B;
#   - A keeps at least KEEP quests.
# Moved lines keep their order, flags and the note/goto/talk/use/collect/buy/fp lines right before them, and
# go before B's closing level step (or in place of its "No quests are written" note). Groups are tried from
# the highest quest level down, in passes until nothing moves.
# Writes guide sources. Run guides + routes afterwards.
# Usage: python tools/research/spread_visits.py ClassicEra [--dry-run]
import glob
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from qdb import Target, f, ids  # noqa: E402

args = [x for x in sys.argv[1:] if not x.startswith("--")]
T = Target(args[0] if args else "ClassicEra")
DRY = "--dry-run" in sys.argv
KEEP = 3
ATTACH = ("note", "goto", "talk", "use", "collect", "buy", "fp")
QLINE = re.compile(r"^(accept|complete|turnin) (\d+)\b")
PLACEHOLDER = "note No quests are written for this visit yet."

deps = {}
for qid, q in T.Q.items():
    for p in ids(f(q, 13)) + ids(f(q, 14)):
        deps.setdefault(p, set()).add(qid)


def load(fn):
    raw = open(fn, encoding="utf-8", newline="").read()
    text = raw.replace("\r\n", "\n")
    return dict(file=fn, nl="\r\n" if "\r\n" in raw else "\n", lines=text.rstrip("\n").split("\n"),
                zone=re.search(r"^@zone (.+)$", text, re.M).group(1).strip(),
                lo=int(re.search(r"^@levels (\d+)-(\d+)", text, re.M).group(1)),
                hi=int(re.search(r"^@levels (\d+)-(\d+)", text, re.M).group(2)),
                gid=re.search(r"^@guide (\S+)", text, re.M).group(1))


def blocks(v):
    """{qid: [(start, end)]}: each quest line with the attached lines right before it."""
    out = {}
    for i, l in enumerate(v["lines"]):
        m = QLINE.match(l)
        if not m:
            continue
        s = i
        while s > 0 and v["lines"][s - 1].split(" ", 1)[0] in ATTACH and not QLINE.match(v["lines"][s - 1]):
            s -= 1
        out.setdefault(int(m.group(2)), []).append((s, i + 1))
    return out


report = []
for fac in ("alliance", "horde"):
    files = sorted(glob.glob(os.path.join(T.dir, "guides-src", fac, "[1-6][0-9]_*.guide")))
    V = [load(fn) for fn in files]
    moved = True
    while moved:
        moved = False
        B = [blocks(v) for v in V]
        where = {}
        for i, b in enumerate(B):
            for q in b:
                where.setdefault(q, set()).add(i)
        accept_at = {}
        for i, v in enumerate(V):
            for l in v["lines"]:
                m = QLINE.match(l)
                if m and m.group(1) == "accept":
                    accept_at.setdefault(int(m.group(2)), []).append(i)
        for a, v in enumerate(V):
            later = [b for b in range(a + 1, len(V)) if V[b]["zone"] == v["zone"]]
            if not later:
                continue
            for q in sorted(B[a], key=lambda x: -(f(T.Q.get(x), 3) or 0)):
                if q not in B[a] or where.get(q) != {a}:
                    continue
                group, todo = {q}, [q]
                while todo:
                    x = todo.pop()
                    for d in deps.get(x, ()):
                        if d in B[a] and d not in group:
                            group.add(d)
                            todo.append(d)
                if any(where.get(x) != {a} for x in group) or len(B[a]) - len(group) < KEEP:
                    continue
                lvl = min(f(T.Q[x], 3) or 0 for x in group if x in T.Q)
                req = max(f(T.Q[x], 2) or 0 for x in group if x in T.Q)
                mid = lambda w: (V[w]["lo"] + V[w]["hi"]) / 2.0
                best = None
                for b in later:
                    if V[b]["hi"] < req or abs(lvl - mid(b)) >= abs(lvl - mid(a)):
                        continue
                    outside = {d for x in group for d in deps.get(x, ()) if d not in group}
                    if any(i <= b for d in outside for i in accept_at.get(d, [])):
                        continue
                    if best is None or abs(lvl - mid(b)) < abs(lvl - mid(best)):
                        best = b
                if best is None:
                    continue
                spans = sorted(s for x in group for s in B[a][x])
                take = [ln for s, e in spans for ln in v["lines"][s:e]]
                drop = {ln for s, e in spans for ln in range(s, e)}
                v["lines"] = [l for i, l in enumerate(v["lines"]) if i not in drop]
                w = V[best]["lines"]
                if PLACEHOLDER in w:
                    k = w.index(PLACEHOLDER)
                    w[k:k + 1] = take
                else:
                    k = max(i for i, l in enumerate(w) if l.startswith("level ")) if any(l.startswith("level ") for l in w) else len(w)
                    w[k:k] = take
                report.append("%s -> %s: %s" % (v["gid"], V[best]["gid"], ", ".join("%d %s" % (x, T.Q[x][0]) for x in sorted(group))))
                moved = True
                break
            if moved:
                break
    if not DRY:
        for v in V:
            open(v["file"], "w", encoding="utf-8", newline="").write(v["nl"].join(v["lines"]) + v["nl"])
    for v in V:
        n = len(blocks(v))
        if n < 3:
            report.append("still thin: %s (%d quests)" % (v["gid"], n))
for r in report:
    print(r)
print("moves:", sum(1 for r in report if "->" in r))
