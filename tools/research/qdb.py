# Shared readers for the research tools: the target's bundled quest data, QuestieDB's full NPC/object/item
# tables, the quest XP table, compiled guides and the route audit's step levels.
# Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
# SPDX-License-Identifier: GPL-3.0-only
import csv
import glob
import json
import math
import os
import re

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))


def parse_lua(s, i=0):
    """Minimal Lua literal reader: tables (array part, [k]=v, name=v), strings, numbers, booleans, nil.
    Tables come back as (array_list, hash_dict)."""
    def ws(i):
        while i < len(s) and s[i] in " \t\r\n":
            i += 1
        return i

    def val(i):
        i = ws(i)
        c = s[i]
        if c == "{":
            i += 1
            arr_, hsh_ = [], {}
            while True:
                i = ws(i)
                if s[i] == "}":
                    return (arr_, hsh_), i + 1
                if s[i] == "[":
                    k, i = val(i + 1)
                    i = ws(i)
                    i = ws(i + 1)  # ]
                    i = ws(i + 1)  # =
                    v, i = val(i)
                    hsh_[k] = v
                else:
                    m = re.match(r"([A-Za-z_]\w*)\s*=(?!=)", s[i:])
                    if m and m.group(1) not in ("nil", "true", "false"):
                        i += len(m.group(0))
                        v, i = val(i)
                        hsh_[m.group(1)] = v
                    else:
                        v, i = val(i)
                        arr_.append(v)
                i = ws(i)
                if s[i] in ",;":
                    i += 1
        if c in "\"'":
            j = i + 1
            out = []
            while s[j] != c:
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


def ids(v):
    return list(arr(v)) if v else []


def f(rec, i):
    """1-based field of a positional record."""
    return rec[i - 1] if rec and len(rec) >= i else None


class Target:
    def __init__(self, name):
        self.name = name
        self.dir = os.path.join(ROOT, "targets", name)
        self.info = json.load(open(os.path.join(self.dir, "target.json"), encoding="utf-8"))
        self.qdir = os.path.join(self.dir, "addon", "Database", "Questie")
        self.Q = self._bundled("Quests.lua", "Q")
        self.N, self.O, self.I = self._raw_tables()
        self.xp = self._xp()
        self.guides = self._guides()
        self.step_level = self._step_levels()

    def _bundled(self, fn, prefix):
        d = {}
        for line in open(os.path.join(self.qdir, fn), encoding="utf-8"):
            m = re.match(r"^%s\[(\d+)\]=(\{.*\})\s*$" % prefix, line)
            if m:
                d[int(m.group(1))] = arr(parse_lua(m.group(2)))
        return d

    def _raw(self, fn, marker):
        q = self.info["questie"]
        path = os.path.join(ROOT, ".cache", "upstream", "questiedb", q["dataDir"], q["prefix"] + fn)
        d, on = {}, False
        for line in open(path, encoding="utf-8"):
            if not on:
                on = marker in line
                continue
            m = re.match(r"^\[(\d+)\] = (\{.*\}),\s*$", line)
            if m:
                try:
                    d[int(m.group(1))] = arr(parse_lua(m.group(2)))
                except Exception:
                    pass
        return d

    def _raw_tables(self):
        # Normalised: NPC [name, min, max, rank, zone, spawns, friendlyTo]; object [name, zone, spawns]; item [name, npcDrops, objectDrops]
        N = {k: [v[0], v[3], v[4], v[5], v[8] if len(v) > 8 else None, v[6], v[12] if len(v) > 12 else None] for k, v in self._raw("NpcDB.lua", "QuestieDB.npcData").items() if len(v) >= 7}
        O = {k: [v[0], v[4] if len(v) > 4 else None, v[3]] for k, v in self._raw("ObjectDB.lua", "QuestieDB.objectData").items() if len(v) >= 4}
        I = {k: [v[0], v[1], v[2]] for k, v in self._raw("ItemDB.lua", "QuestieDB.itemData").items() if len(v) >= 3}
        return N, O, I

    def _xp(self):
        d = {}
        p = os.path.join(ROOT, ".cache", "upstream", "questiedb", self.info["questie"]["xp"])
        if os.path.exists(p):
            for line in open(p, encoding="utf-8"):
                m = re.match(r"^\s*\[(\d+)\]\s*=\s*\{\s*(-?\d+)\s*,\s*(\d+)\s*\}", line)
                if m:
                    d[int(m.group(1))] = int(m.group(3))
        return d

    def _guides(self):
        gs = {}
        for p in glob.glob(os.path.join(self.dir, "addon", "Guides", "Compiled", "*.lua")):
            t = open(p, encoding="utf-8").read()
            m = re.search(r'id="([^"]+)", name="[^"]*", faction="(\w+)".*?minLevel=(\d+), maxLevel=(\d+), zone=(\d+)', t, re.S)
            if not m:
                continue
            steps = []
            for sm in re.finditer(r'^    \{"(\w+)"(.*)\},\s*$', t, re.M):
                body = sm.group(2)
                q = re.search(r"\bq=(\d+)", body)
                z = re.search(r"\bz=(\d+),x=([\d.]+),y=([\d.]+)", body)
                dng = re.search(r'\bdungeon="([^"]+)"', body)
                steps.append(dict(kind=sm.group(1), q=int(q.group(1)) if q else None,
                                  z=int(z.group(1)) if z else None, x=float(z.group(2)) if z else None,
                                  y=float(z.group(3)) if z else None, filtered=("classes=" in body or "races=" in body),
                                  opt=bool(re.search(r"\b(optional|hcSkip|hcOnly|elite)=true|\bdungeon=", body)),
                                  dungeon=dng.group(1) if dng else None))
            gs[m.group(1)] = dict(id=m.group(1), faction=m.group(2), min=int(m.group(3)), max=int(m.group(4)),
                                  zone=int(m.group(5)), steps=steps, file=None)
        for p in glob.glob(os.path.join(self.dir, "guides-src", "*", "*.guide")):
            for line in open(p, encoding="utf-8"):
                m = re.match(r"^@guide\s+(\S+)", line)
                if m and m.group(1) in gs:
                    gs[m.group(1)]["file"] = p
                    break
        return gs

    def _step_levels(self):
        d = {}
        p = os.path.join(ROOT, "docs", "generated", self.name, "step-levels.csv")
        if os.path.exists(p):
            for r in csv.DictReader(open(p, encoding="utf-8-sig")):
                fn, ln = r["step"].rsplit(":", 1)
                d.setdefault(fn.replace("\\", "/"), {})[int(ln)] = float(r["modelLevel"])
        return d

    def level_at(self, guide_file, line_index):
        rel = os.path.relpath(guide_file, os.path.join(self.dir, "guides-src")).replace("\\", "/")
        best = None
        for ln, lv in self.step_level.get(rel, {}).items():
            if ln <= line_index + 1 and (best is None or ln > best[0]):
                best = (ln, lv)
        return best[1] if best else None

    # spawn helpers
    def npc_pts(self, nid, zone):
        r = self.N.get(nid)
        sp = hsh(r[5]) if r else {}
        return [(arr(p)[0], arr(p)[1]) for p in arr(sp.get(zone))] if sp.get(zone) else []

    def obj_pts(self, oid, zone):
        r = self.O.get(oid)
        sp = hsh(r[2]) if r else {}
        return [(arr(p)[0], arr(p)[1]) for p in arr(sp.get(zone))] if sp.get(zone) else []

    def rank(self, nid):
        r = self.N.get(nid)
        return (r[3] or 0) if r else 0

    def hostile_elite(self, nid):
        """Elite, rare elite or boss AND not friendly to anyone: a fight. Friendly elites (quest NPCs you
        talk to, like Tirion Fordring) are not."""
        r = self.N.get(nid)
        return bool(r) and (r[3] or 0) in (1, 2, 3) and not (len(r) > 6 and r[6])


def dist(a, b):
    return math.hypot(a[0] - b[0], a[1] - b[1])


def centroid(pts):
    return (sum(p[0] for p in pts) / len(pts), sum(p[1] for p in pts) / len(pts)) if pts else None


VERB_RE = re.compile(r"^(accept|turnin|complete)\s")

# Escorts: quest flag 2 (party-accept: escorts, scripted events, duels) AND escort wording in the quest text.
# The other flag-2 quests (events, duels, timed tasks) stay out of generated routes.
ESCORT_RE = re.compile(r"\b(escort|protect|accompany|safely|show .{0,40}the way|ensure .{0,60}(arrive|reach)"
                       r"|lead .{0,40}(to|back|out)|guide .{0,40}to)\b", re.I)
ESCORT_STEP = "Escort: stay close; it fails if the NPC dies."


def escort(q):
    return bool(((f(q, 26) or 0) & 2) and ESCORT_RE.search(f(q, 11) or ""))


def event_only(q):
    """Flag-2 quest that is not an escort (generated routes leave these out)."""
    return (f(q, 26) or 0) == 2 and not escort(q)


def escort_note(q, flags=()):
    """The note line placed right before an escort's accept step."""
    text = "The next quest, %s, is an escort: pick it up only when you are ready to follow the NPC." % q[0]
    flags = [x for x in flags if x]
    return "note [%s] | %s" % ("; ".join(flags), text) if flags else "note " + text
