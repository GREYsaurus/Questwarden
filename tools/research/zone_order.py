# Rebuild a target's routes to a zone order: one guide per visit (docs/ROUTE_OPTIMIZATION.md).
# Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
# SPDX-License-Identifier: GPL-3.0-only
#
# targets/<Target>/zone-order.json lists, per faction, the race start guides (kept as they are) and then the
# visits: zone, level range (and an optional area label). Every quest step of the current guides (except the
# start guides) is re-cut into those visits, quest by quest, in the order of the current routes:
#   accept   - the first visit to the step's zone (the zone of the guide it is in now) that comes after the
#              quest's prerequisites and whose top level meets the required level; of those, the first whose
#              top level is at least the quest level - 2 (else the last one);
#   complete - the first visit to its own zone at or after the accept's visit;
#   turnin   - the first visit to its own zone at or after the complete's visit.
# Inside a visit, steps keep their current relative order. Each quest step keeps its own line (flags, text)
# and the note/goto/talk/use/collect/buy/fp lines right before it. A quest picked up only in race start
# guides keeps the rest of its steps for those races ([race=...]). bind, hs, fly, travel, train, level and
# grind lines are dropped; each visit starts with "travel <zone>", visits that start on an even level from
# 12 up get a "train" step, and each visit ends with "level <next visit's first level>" (the zone order's
# levels include grinding and dungeons; the step says so). A quest whose step has no visit (its zone is not in the order, or no visit
# is late enough) is dropped, and with it every quest that needs it; the list goes to
# docs/generated/<Target>/zone-order-dropped.csv. A visit with no steps gets a placeholder note; fill it with
# zone_guide.py --fill.
# Writes guide sources (deletes the old non-start guides). Run guides + routes afterwards.
# Usage: python tools/research/zone_order.py ClassicEra [--dry-run]
import csv
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from qdb import ROOT, Target, VERB_RE, f, ids  # noqa: E402

args = [x for x in sys.argv[1:] if not x.startswith("--")]
T = Target(args[0] if args else "ClassicEra")
DRY = "--dry-run" in sys.argv
ORDER = json.load(open(os.path.join(T.dir, "zone-order.json"), encoding="utf-8"))
SRC = os.path.join(T.dir, "guides-src")
ATTACH = ("note", "goto", "talk", "use", "collect", "buy", "fp")
DROP = ("bind", "hs", "fly", "travel", "train", "level", "grind", "guide")
PRE = {"Alliance": "A", "Horde": "H"}


def slug(s):
    return re.sub(r"[^A-Za-z]", "", s.replace("The ", ""))


def flags_of(line):
    m = re.match(r"^(\w+)\s+([^|\[]*?)\s*\[([^\]]*)\](.*)$", line)
    return m


def for_faction(line, fac):
    """None if the line is for the other faction; else the line without a faction flag."""
    m = flags_of(line)
    if not m:
        return line
    fl = [x.strip() for x in m.group(3).split(";")]
    fx = [x for x in fl if x.startswith("faction=")]
    if fx and fx[0] != "faction=" + fac:
        return None
    rest = [x for x in fl if not x.startswith("faction=")]
    return "%s %s%s%s" % (m.group(1), m.group(2), (" [" + "; ".join(rest) + "]") if rest else "", m.group(4))


RACE_NAMES = {"NightElf": "Night Elf", "Scourge": "Undead"}


def races_of(line):
    m = flags_of(line)
    fl = [x.strip() for x in m.group(3).split(";")] if m else []
    r = [x[5:] for x in fl if x.startswith("race=")]
    return set(x.strip() for x in r[0].split(",")) if r else None


def with_races(line, races):
    """The line limited to these races (intersected with its own race flag); None if nothing is left."""
    own = races_of(line)
    keep = races if own is None else own & races
    if not keep:
        return None
    m = flags_of(line)
    flag = "race=" + ",".join(sorted(keep))
    if not m:
        verb, rest = line.split(" ", 1)
        body, _, text = rest.partition(" | ")
        return "%s %s [%s]%s" % (verb, body.rstrip(), flag, (" | " + text) if text else "")
    fl = [x.strip() for x in m.group(3).split(";") if not x.strip().startswith("race=")] + [flag]
    return "%s %s [%s]%s" % (m.group(1), m.group(2), "; ".join(fl), m.group(4))


def with_id(line, qid):
    verb, rest = line.split(" ", 1)
    return line if re.match(r"^\d+\b", rest) else "%s %d %s" % (verb, qid, rest)


# Current guides: source lines aligned with compiled quest steps.
GUIDES = {}
for gid, g in T.guides.items():
    if not g["file"]:
        continue
    text = open(g["file"], encoding="utf-8", newline="").read()
    lines = text.replace("\r\n", "\n").split("\n")
    src_q = [i for i, l in enumerate(lines) if VERB_RE.match(l)]
    cq = [s for s in g["steps"] if s["kind"] in ("accept", "turnin", "complete")]
    if len(src_q) != len(cq):
        sys.exit("source and compiled guide differ, compile first: " + gid)
    zone = re.search(r"^@zone (.+)$", text, re.M).group(1).strip()
    GUIDES[gid] = dict(g, lines=lines, qline={src_q[k]: s for k, s in enumerate(cq)}, zname=zone,
                       nl="\r\n" if "\r\n" in text else "\n")

report, dropped_rows, written, removed = [], [], [], set()
for fac in ("Alliance", "Horde"):
    spec = ORDER[fac]
    starts = spec["start"]
    visits = [dict(i=i, zone=v[0], lo=v[1], hi=v[2], label=v[3] if len(v) > 3 else None, items=[]) for i, v in enumerate(spec["visits"])]
    old = sorted([g for g in GUIDES.values() if g["faction"] in (fac, "Both") and g["id"] not in starts],
                 key=lambda g: (g["min"], g["max"], g["id"]))
    # Items: one per quest step line, with the lines before it attached.
    items, order = [], 0
    for g in old:
        buf = []
        for i, raw in enumerate(g["lines"]):
            line = raw.rstrip()
            if not line or line.startswith("#") or line.startswith("@"):
                continue
            verb = line.split(" ", 1)[0]
            if i in g["qline"]:
                s = g["qline"][i]
                own = for_faction(line, fac)
                att = [x for x in (for_faction(b, fac) for b in buf) if x]
                buf = []
                if own is None or not s["q"]:
                    continue
                order += 1
                items.append(dict(q=s["q"], kind=s["kind"], line=with_id(own, s["q"]), att=att, zone=g["zname"], order=order, src=g["id"]))
            elif verb in ATTACH:
                buf.append(line)
            elif verb in DROP:
                continue
    # Quest steps already done in the start guides, and the races each start guide is for.
    start_races = {}
    for sid in starts:
        m = re.search(r"^@races (.+)$", "\n".join(GUIDES[sid]["lines"]), re.M)
        start_races[sid] = {RACE_NAMES.get(r.strip(), r.strip()) for r in m.group(1).split(",")}
    done = {}
    for gid in starts:
        for s in GUIDES[gid]["steps"]:
            if s["kind"] == "turnin" and s["q"]:
                done[s["q"]] = -1
    byq = {}
    for it in items:
        byq.setdefault(it["q"], []).append(it)
    first = sorted(byq, key=lambda q: min(it["order"] for it in byq[q]))
    dropped = {}

    def visit_for(zone, mini, req=None, qlvl=None):
        cand = [v for v in visits if v["zone"] == zone and v["i"] >= mini and (req is None or v["hi"] >= req)]
        if not cand:
            return None
        if qlvl is None:
            return cand[0]["i"]
        good = [v for v in cand if v["hi"] >= qlvl - 2]
        return (good[0] if good else cand[-1])["i"]

    for qid in first:
        q = T.Q.get(qid)
        its = byq[qid]
        req, lvl = (f(q, 2) or 0, f(q, 3) or 0) if q else (0, 0)
        pg, ps = (ids(f(q, 13)), ids(f(q, 14))) if q else ([], [])
        why = None
        need = [x for x in pg if x in byq or x in done]  # prerequisites this faction's routes have at all
        if any(x in dropped for x in pg):
            why = "needs %s, which was dropped" % next(x for x in pg if x in dropped)
        elif ps and all(x in dropped for x in ps if x in byq) and any(x in byq for x in ps) and not any(x in done for x in ps):
            why = "needs one of %s, all dropped" % ps
        mini = max([done.get(x, -1) for x in need if x in done] + [-1])
        alts = [done[x] for x in ps if x in done]
        if alts:
            mini = max(mini, min(alts))
        seg = {}
        if not why:
            for kind in ("accept", "complete", "turnin"):
                for it in [x for x in its if x["kind"] == kind]:
                    if kind == "accept":
                        v = visit_for(it["zone"], max(mini, 0) if mini >= 0 else 0, req, lvl)
                    else:
                        prev = max([seg[id(x)] for x in its if x["kind"] in (("accept",) if kind == "complete" else ("accept", "complete")) and id(x) in seg] + [mini, 0])
                        v = visit_for(it["zone"], prev)
                    if v is None:
                        why = "no %s visit to %s%s" % (kind, it["zone"], "" if kind != "accept" else " late enough for level %d" % req)
                        break
                    seg[id(it)] = v
                if why:
                    break
        if why:
            dropped[qid] = why
            dropped_rows.append(dict(faction=fac, quest=qid, title=q[0] if q else "?", reason=why))
            continue
        # Picked up only in race start guides: the rest of the quest is for those races only.
        if not any(x["kind"] == "accept" for x in its):
            races = set()
            for sid in starts:
                if any(s["kind"] == "accept" and s["q"] == qid for s in GUIDES[sid]["steps"]):
                    races |= start_races[sid]
            if races:
                for it in its:
                    it["line"] = with_races(it["line"], races)
                    it["att"] = [y for y in (with_races(a, races) if not a.startswith("fp ") else a for a in it["att"]) if y]
                its = [x for x in its if x["line"]]
        for it in its:
            visits[seg[id(it)]]["items"].append(it)
        tis = [seg[id(x)] for x in its if x["kind"] == "turnin"]
        if tis:
            done[qid] = max(tis)
    # Emit.
    folder = os.path.join(SRC, fac.lower())
    for g in old:
        removed.add(g["file"])
    ids_ = ["%s_%02d_%s" % (PRE[fac], v["i"] + 10, slug(v["label"] or v["zone"])) for v in visits]
    count = {}
    for v in visits:
        count[v["zone"]] = count.get(v["zone"], 0) + 1
    seen = {}
    for v, gid in zip(visits, ids_):
        seen[v["zone"]] = seen.get(v["zone"], 0) + 1
        name = v["label"] or v["zone"]
        lv = "%d-%d" % (v["lo"], v["hi"]) if v["lo"] != v["hi"] else str(v["lo"])
        nxt = ids_[v["i"] + 1] if v["i"] + 1 < len(ids_) else None
        head = ["# Questwarden - %s (%s), %s, WoW Classic Era" % (name, lv, fac),
                "# Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus) - GPL-3.0-only. Original route and notes.",
                "# Zone and level range from targets/ClassicEra/zone-order.json (maintainer-supplied zone order);",
                "# quest steps re-cut from the earlier Questwarden routes by tools/research/zone_order.py.",
                "", "@guide " + gid, "@name %s (%s)" % (name, lv), "@faction " + fac, "@levels %d-%d" % (v["lo"], v["hi"]),
                "@zone " + v["zone"], "@chapter Azeroth",
                "@desc %s, visit %d of %d on the %s route, levels %s." % (name, seen[v["zone"]], count[v["zone"]], fac, lv)]
        if nxt:
            head.append("@next " + nxt)
        body = ["", "travel " + v["zone"]]
        if v["lo"] >= 12 and v["lo"] % 2 == 0:
            body.append("train")
        steps = sorted(v["items"], key=lambda it: it["order"])
        for it in steps:
            body += it["att"] + [it["line"]]
        if not steps:
            body.append("note No quests are written for this visit yet.")
        # The zone order's levels include grinding and dungeons; say where the next stop expects you to be.
        if nxt:
            nv = visits[v["i"] + 1]
            body.append("level %d | %s starts at %d. If you are lower, kill what is around you here (or run a dungeon) until you reach it." % (
                nv["lo"], nv["label"] or nv["zone"], nv["lo"]))
        else:
            body.append("level 60")
        fn = os.path.join(folder, "%02d_%s.guide" % (v["i"] + 10, slug(v["label"] or v["zone"]).lower()))
        written.append((fn, "\n".join(head + body) + "\n"))
        report.append("%s %-28s %6s  %3d steps  (%s)" % (gid, name, lv, len(steps), ", ".join(sorted({it["src"] for it in steps}))[:90]))
    # Start guides lead to the first visit.
    for sid in starts:
        written.append((GUIDES[sid]["file"], re.sub(r"^@next .*$", "@next " + ids_[0], "\n".join(GUIDES[sid]["lines"]), count=1, flags=re.M)))
    report.append("%s: %d quests placed, %d dropped" % (fac, len({it["q"] for v in visits for it in v["items"]}), len([r for r in dropped_rows if r["faction"] == fac])))

for r in report:
    print(r)
if not DRY:
    keep = {fn for fn, _ in written}
    for fn in removed - keep:
        os.remove(fn)
    for fn, text in written:
        open(fn, "w", encoding="utf-8", newline="").write(text.replace("\r\n", "\n").replace("\n", "\r\n"))
    out = os.path.join(ROOT, "docs", "generated", T.name, "zone-order-dropped.csv")
    with open(out, "w", encoding="utf-8", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=["faction", "quest", "title", "reason"])
        w.writeheader()
        w.writerows(dropped_rows)
    print("wrote", len(written), "guide files; removed", len(removed - keep), "; dropped list:", os.path.relpath(out, ROOT))
