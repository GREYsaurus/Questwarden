# Timed quests: turn them in first (docs/ROUTE_OPTIMIZATION.md, "Timed quests").
# Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
# SPDX-License-Identifier: GPL-3.0-only
#
# A timed quest (targets/<Target>/addon/Database/QuestTimers.lua) fails when its clock runs out, so the guide goes
# from its pickup straight to its objective and turn-in. Between the two only stay:
#   - the quest's own steps, notes, and travel (fly, boat, hearthstone, ...) toward the turn-in;
#   - easy turn-ins on the way: a turn-in whose quest is already done (no pickup or objective step of it in between),
#     at an NPC in the same zone that adds at most DETOUR map percent to the walk, while the estimated time stays
#     within SHARE of the limit.
# Everything else in between is fixed in one of two ways, in this order (a turn-in in another zone than the guide's
# is only fixed this way after an escort, which ends at the turn-in NPC, or when the pickup can move; else reported):
#   1. the pickup moves down to the last point before the turn-in where the guide passes the quest giver anyway
#      (within NEAR map percent), so the clock starts later;
#   2. the other steps still in between move to right after the turn-in, in their order. This is only done when no
#      travel step lies in between (otherwise they would move to another place); such cases are reported.
# The estimate: straight lines between the steps' NPCs in world yards (Database/ZoneGeo.lua) x 1.25, at 7 yards a
# second (running, no mount), plus 10 seconds a step. The time the quest's own objective takes is not known.
#
# Usage: python tools/research/timed_order.py <Target> [--apply]
#   With --apply: rewrite the guide sources; then run guides + routes and tools/research/layout_map.py.
import math
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from qdb import ROOT, Target, dist  # noqa: E402

DETOUR = 3.0
NEAR = 4.0
SHARE = 0.5
SPEED, PATH, PER_STEP = 7.0, 1.25, 10.0
STEP_RE = re.compile(r"^(accept|turnin|complete|level|note|train|bind|hs|fly|goto|vendor|repair|dungeon|"
                     r"use|buy|home|boat|zeppelin|portal|travel|learn|talk|collect|fp|grind|guide)\b")
VERBS = ("accept", "turnin", "complete")
TRAVEL = ("hs", "fly", "boat", "zeppelin", "portal", "travel", "goto", "home")
T = Target(sys.argv[1])
APPLY = "--apply" in sys.argv
LIMITS = {int(a): int(b) for a, b in re.findall(r"\[(\d+)\] = (\d+),", open(os.path.join(
    T.dir, "addon", "Database", "QuestTimers.lua"), encoding="utf-8").read())}
GEO = {int(m[0]): [float(v) for v in m[1:]] for m in re.findall(
    r"\[(\d+)\] = \{ (\d+), ([-\d.]+), ([-\d.]+), ([-\d.]+), ([-\d.]+) \}",
    open(os.path.join(T.dir, "addon", "Database", "ZoneGeo.lua"), encoding="utf-8").read())}


def world(z, x, y):
    g = GEO.get(z)
    if not g:
        return None
    cont, minx, miny, maxx, maxy = g
    return cont, maxx - y / 100 * (maxx - minx), maxy - x / 100 * (maxy - miny)


def seconds(points):
    """Estimated walk through (z, x, y) points, in seconds; None when two are not on one continent."""
    total, prev = 0.0, None
    for p in points:
        w = world(*p)
        if w is None:
            return None
        if prev is not None:
            if prev[0] != w[0]:
                return None
            total += math.hypot(w[1] - prev[1], w[2] - prev[2]) * PATH / SPEED
        prev = w
    return total + PER_STEP * len(points)


def note_block(lines, i):
    s = i
    while s > 0 and lines[s - 1].strip().startswith("note"):
        s -= 1
    return s


def plan(g, lines):
    src = []
    for i, ln in enumerate(lines):
        m = STEP_RE.match(ln.strip())
        if m:
            src.append((i, m.group(1)))
    quest = [(i, v) for i, v in src if v in VERBS]
    cv = [s for s in g["steps"] if s["kind"] in VERBS]
    if len(quest) != len(cv) or any(v != s["kind"] for (_, v), s in zip(quest, cv)):
        return None, ["source and compiled steps do not line up; skipped"]
    info = {i: s for (i, _), s in zip(quest, cv)}
    seq = [dict(line=i, kind=v, **({k: info[i][k] for k in ("q", "z", "x", "y")} if i in info else
                                   dict(q=None, z=None, x=None, y=None))) for i, v in src]
    report = []
    for ai, a in enumerate(seq):
        if a["kind"] != "accept" or a["q"] not in LIMITS:
            continue
        q = a["q"]
        limit = LIMITS[q]
        # Pickups of one quest for different races or classes, one after another, are one pickup (and the same
        # for their turn-ins).
        prev = next((k for k in range(ai - 1, -1, -1) if seq[k]["kind"] != "note"), None)
        if prev is not None and seq[prev]["kind"] == "accept" and seq[prev]["q"] == q:
            continue
        group = [ai]
        for k in range(ai + 1, len(seq)):
            if seq[k]["kind"] == "note":
                continue
            if seq[k]["kind"] != "accept" or seq[k]["q"] != q:
                break
            group.append(k)
        ti = next((k for k in range(group[-1] + 1, len(seq)) if seq[k]["q"] == q and seq[k]["kind"] == "turnin"), None)
        title = T.Q[q][0]
        if ti is None:
            report.append(("%s (%d s): turn-in not in this guide" % (title, limit), None))
            continue
        tlast = ti
        for k in range(ti + 1, len(seq)):
            if seq[k]["kind"] == "note":
                continue
            if seq[k]["kind"] != "turnin" or seq[k]["q"] != q:
                break
            tlast = k
        own = [k for k in range(group[-1] + 1, ti) if seq[k]["q"] == q]
        # 1. Start the clock later: the last step before the turn-in (and before the quest's own steps) at the giver.
        newa = ai
        if a["x"] is not None:
            stop = own[0] if own else ti
            for k in range(stop - 1, group[-1], -1):
                s = seq[k]
                if s["x"] is not None and s["z"] == a["z"] and dist((s["x"], s["y"]), (a["x"], a["y"])) <= NEAR:
                    newa = k
                    break
        win = [k for k in range(max(newa, group[-1]) + 1, ti) if seq[k]["kind"] != "note"]
        inwin = {(seq[k]["q"], seq[k]["kind"]) for k in win}
        travel = [k for k in win if seq[k]["kind"] in TRAVEL]
        # 2. What may stay: own steps, travel, and turn-ins on the way.
        keep, move = [], []
        pos = (a["z"], a["x"], a["y"]) if a["x"] is not None else None
        tpos = (seq[ti]["z"], seq[ti]["x"], seq[ti]["y"]) if seq[ti]["x"] is not None else None
        for k in win:
            s = seq[k]
            if s["q"] == q or s["kind"] in TRAVEL:
                keep.append(k)
            elif (s["kind"] == "turnin" and (s["q"], "accept") not in inwin and (s["q"], "complete") not in inwin
                  and s["x"] is not None and pos and tpos and s["z"] == pos[0] == tpos[0]
                  and dist(pos[1:], (s["x"], s["y"])) + dist((s["x"], s["y"]), tpos[1:]) - dist(pos[1:], tpos[1:]) <= DETOUR):
                keep.append(k)
                pos = (s["z"], s["x"], s["y"])
            else:
                move.append(k)
        pts = [p for p in [(a["z"], a["x"], a["y"]) if a["x"] is not None else None]
               + [(seq[k]["z"], seq[k]["x"], seq[k]["y"]) for k in keep if seq[k]["x"] is not None] + [tpos] if p]
        est = seconds(pts) if not travel else None
        # Too slow with the turn-ins kept: drop them (the farthest walk first) until it fits.
        while est is not None and est > SHARE * limit:
            ks = [k for k in keep if seq[k]["kind"] == "turnin" and seq[k]["q"] != q]
            if not ks:
                break
            keep.remove(ks[-1])
            move.append(ks[-1])
            move.sort()
            pts = [p for p in [(a["z"], a["x"], a["y"]) if a["x"] is not None else None]
                   + [(seq[k]["z"], seq[k]["x"], seq[k]["y"]) for k in keep if seq[k]["x"] is not None] + [tpos] if p]
            est = seconds(pts)
        msg = "%s (%s): " % (title, "%d min" % round(limit / 60))
        if newa == ai and not move:
            report.append((msg + "ok, %d step(s) between%s" % (len(win), "" if est is None else ", about %d s of walking" % est), None))
            continue
        # A turn-in in another zone (the guide has no travel steps for it): moving the steps in between after it
        # would send you back. Only an escort, which ends at the turn-in NPC, or a later pickup is safe.
        cross = tpos and tpos[0] != g["zone"] and not any("Escort" in lines[seq[k]["line"]] for k in own)
        if move and (travel or (cross and newa == ai)):
            report.append((msg + "MANUAL: %d step(s) between with travel (%s)" % (len(move), ", ".join(
                "%s %s" % (seq[k]["kind"], T.Q[seq[k]["q"]][0] if seq[k]["q"] in T.Q else "") for k in move[:6])), None))
            continue
        what = []
        if newa != ai:
            what.append("pickup moved down %d step(s)" % (newa - group[-1]))
        if move:
            what.append("%d step(s) moved after the turn-in" % len(move))
        if "-v" in sys.argv:
            what.append("moved: " + ", ".join("%s %s" % (seq[k]["kind"], T.Q[seq[k]["q"]][0] if seq[k]["q"] in T.Q else "") for k in move))
        report.append((msg + "; ".join(what) + ("" if est is None else ", about %d s of walking" % est),
                       dict(group=group, newa=newa if newa != ai else None, ti=tlast, move=move)))
    return seq, report


def apply(lines, seq, fix):
    """Rewrites the lines: the pickup (with its notes) after step newa, the moved steps (with notes) after the
    turn-in. Returns the new list of lines."""
    def block(k):
        ln = seq[k]["line"]
        return list(range(note_block(lines, ln), ln + 1))
    newa, ti, move = fix["newa"], fix["ti"], fix["move"]
    taken = set()
    acc = [i for k in fix["group"] for i in block(k)] if newa is not None else []
    taken |= set(acc)
    mv = [i for k in move for i in block(k)]
    taken |= set(mv)
    out = []
    for i, ln in enumerate(lines):
        if i in taken:
            continue
        out.append(ln)
        if newa is not None and i == seq[newa]["line"]:
            out += [lines[j] for j in acc]
        if i == seq[ti]["line"]:
            out += [lines[j] for j in mv]
    return out


total = 0
for gid, g in sorted(T.guides.items()):
    if not g["file"]:
        continue
    raw = open(g["file"], "rb").read()
    nl = "\r\n" if b"\r\n" in raw else "\n"
    lines = raw.decode("utf-8").split(nl)
    seq, report = plan(g, lines)
    if seq is None:
        print("%s: %s" % (gid, report[0]))
        continue
    for r, _ in report:
        print("%s: %s" % (gid, r))
    fixes = [f for _, f in report if f]
    total += len(fixes)
    if APPLY and fixes:
        # One fix per guide and run: it changes the line numbers, and the compiled steps no longer match until the
        # guides are rebuilt. Rebuild and run again until nothing is left.
        lines = apply(lines, seq, fixes[0])
        open(g["file"], "wb").write(nl.join(lines).encode("utf-8"))
print("%d fix(es) %s" % (total, "found (one per guide applied; rebuild and run again)" if APPLY else "to apply"))
