# Zeppelins, boats and zone borders for one target, for routing "travel <zone>" steps (Core/Travel.lua).
# Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
# SPDX-License-Identifier: GPL-3.0-only
#
# Transports come from the game client's taxi tables (tools/upstream.json "clientTables", the target's build):
#   * TaxiNodes: the transport nodes ("Transport, ..." and "Generic, World target for Zeppelin Paths");
#   * TaxiPath: the paths that start or end at one of them;
#   * TaxiPathNode: each path's stops (the points where the ship waits, Delay > 0), in world yards.
# A path with two stops in different zones is one transport. Each stop is placed on a zone map with the target's
# Database/ZoneGeo.lua boxes (the smallest box that holds it) and named after the nearest flight path within
# NAME_YARDS (Database/Flights.lua), else "near <flight path>" within NEAR_YARDS, else its zone. Zeppelins stop on towers (Z above ZEPPELIN_Z); boats at sea level.
# The faction is that of the flight paths nearest both stops (within NEAR_YARDS), when they agree; else anyone.
#
# Zone borders are hand-written in tools/research/zone_borders.json (from the in-game world map, maintainer-approved
# 2026-11-02): pairs of zones you can walk between.
#
# Usage: python -I tools/research/travel_data.py <Target>
# Writes targets/<Target>/addon/Database/Travel.lua.
import csv
import json
import math
import os
import re
import sys

TARGET = sys.argv[1]
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
INFO = json.load(open(os.path.join(ROOT, "targets", TARGET, "target.json"), encoding="utf-8"))
BUILD = INFO["clientTables"]["build"]
DB2 = os.path.join(ROOT, ".cache", "upstream", "db2", BUILD)
ADDON = os.path.join(ROOT, "targets", TARGET, "addon")
NAME_YARDS = 400
NEAR_YARDS = 1500
MAX_ZONE_YARDS = 8000
ZEPPELIN_Z = 30


def read(name):
    return list(csv.DictReader(open(os.path.join(DB2, name + ".csv"), encoding="utf-8")))


def lua(path):
    return open(os.path.join(ADDON, "Database", path), encoding="utf-8").read()


# Zone boxes and names ---------------------------------------------------------------------------------------------
geo = {}
for m in re.finditer(r"\[(\d+)\] = \{ (-?\d+), (-?[\d.]+), (-?[\d.]+), (-?[\d.]+), (-?[\d.]+) \}", lua("ZoneGeo.lua")):
    box = (int(m.group(2)),) + tuple(float(m.group(k)) for k in range(3, 7))
    if box[3] - box[1] < MAX_ZONE_YARDS:  # leave out whole-continent maps
        geo[int(m.group(1))] = box
zones_src = lua(os.path.join("Questie", "Zones.lua"))
names_block = zones_src[zones_src.index("Z.names = {"):]
names_block = names_block[:names_block.index("\n}")]
names = {int(i): n for i, n in re.findall(r'\[(\d+)\]="([^"]*)"', names_block)}
by_name = {}
for i, n in sorted(names.items()):
    if i in geo:
        by_name.setdefault(n, i)


# NPC spawns by zone (QuestieDB, Database/Questie/Npcs.lua): their zone tags say which zone a spot belongs to, where the
# rectangular zone maps overlap.
spawns = {}
for zm, pts in re.findall(r"\[(\d+)\]=\{((?:\{[\d.]+,[\d.]+\},?)+)\}", lua(os.path.join("Questie", "Npcs.lua"))):
    spawns.setdefault(int(zm), []).extend((float(a), float(b)) for a, b in re.findall(r"\{([\d.]+),([\d.]+)\}", pts))


def to_world(z, x, y):
    c, x0, y0, x1, y1 = geo[z]
    return x1 - y / 100 * (x1 - x0), y1 - x / 100 * (y1 - y0)


def place(cont, wx, wy):
    """World position -> (zone, x, y): of the zone maps that hold it, the one with an NPC spawn nearest to it."""
    best = None
    for z, (c, x0, y0, x1, y1) in geo.items():
        if c == cont and x0 <= wx <= x1 and y0 <= wy <= y1:
            x, y = (y1 - wy) / (y1 - y0) * 100, (x1 - wx) / (x1 - x0) * 100
            near = min((math.hypot(*(a - b for a, b in zip(to_world(z, sx, sy), (wx, wy)))) for sx, sy in spawns.get(z, [])),
                       default=math.inf)
            if not best or near < best[0]:
                best = (near, z, x, y)
    return best and best[1:]


# Flight paths, for names and factions -----------------------------------------------------------------------------
flights = []
for m in re.finditer(r'N\[(\d+)\]=\{name="([^"]*)",full="[^"]*",zone=(\d+),x=([\d.]+),y=([\d.]+),faction="(\w+)"', lua("Flights.lua")):
    flights.append((m.group(2), int(m.group(3)), float(m.group(4)), float(m.group(5)), m.group(6)))


def yards(z1, x1, y1, z2, x2, y2):
    a, b = geo[z1], geo[z2]
    if a[0] != b[0]:
        return math.inf
    ax, ay = a[3] - y1 / 100 * (a[3] - a[1]), a[4] - x1 / 100 * (a[4] - a[2])
    bx, by = b[3] - y2 / 100 * (b[3] - b[1]), b[4] - x2 / 100 * (b[4] - b[2])
    return math.hypot(ax - bx, ay - by)


def near_flight(z, x, y, limit):
    best = None
    for f in flights:
        if f[1] in geo:
            d = yards(z, x, y, f[1], f[2], f[3])
            if d <= limit and (not best or d < best[0]):
                best = (d, f)
    return best and best[1]


# Transports -------------------------------------------------------------------------------------------------------
tnodes = {int(r["ID"]) for r in read("TaxiNodes") if r["Name_lang"].startswith(("Transport", "Generic, World target"))}
paths = {int(r["ID"]) for r in read("TaxiPath") if int(r["FromTaxiNode"]) in tnodes or int(r["ToTaxiNode"]) in tnodes}
stops = {}
for r in read("TaxiPathNode"):
    p = int(r["PathID"])
    if p in paths and int(r["Delay"] or 0) > 0:
        stops.setdefault(p, []).append((int(r["NodeIndex"]), int(r["ContinentID"]), float(r["Loc_0"]), float(r["Loc_1"]), float(r["Loc_2"])))
transports, report = [], []
for p in sorted(stops):
    ends = []
    for _, cont, wx, wy, wz in sorted(stops[p]):
        pl = place(cont, wx, wy)
        if pl and not any(e[0] == pl[0] for e in ends):
            ends.append(pl + (wz,))
    if len(ends) != 2:
        report.append("path %d: %d stops in different zones, left out" % (p, len(ends)))
        continue
    kind = "zeppelin" if min(e[3] for e in ends) > ZEPPELIN_Z else "boat"
    sides, facs = [], []
    for z, x, y, _ in ends:
        f = near_flight(z, x, y, NAME_YARDS)
        g = f or near_flight(z, x, y, NEAR_YARDS)
        label = f[0] if f else ("near " + g[0]) if g else names.get(z, "?")
        sides.append((z, round(x, 1), round(y, 1), label))
        # A town with flight paths for both factions (Booty Bay) serves both.
        here = {c for fl in flights if fl[1] in geo and yards(z, x, y, fl[1], fl[2], fl[3]) <= NAME_YARDS for c in fl[4]}
        facs.append(here or (set(g[4]) if g else {"A", "H"}))
    fac = facs[0] & facs[1] or {"A", "H"}
    transports.append((p, kind, "".join(sorted(fac)), sides))

# Borders ----------------------------------------------------------------------------------------------------------
borders = json.load(open(os.path.join(ROOT, "tools", "research", "zone_borders.json"), encoding="utf-8"))
pairs = []
for a, b in borders["pairs"]:
    if a in by_name and b in by_name:
        pairs.append((by_name[a], by_name[b]))
    elif borders.get("expansion", {}).get(a) is None and borders.get("expansion", {}).get(b) is None:
        report.append("border %s - %s: zone not in this target's data" % (a, b))

# Output -----------------------------------------------------------------------------------------------------------
def s(v):
    return '"' + v.replace("\\", "\\\\").replace('"', '\\"') + '"'


out = ["-- Questwarden - zeppelins, boats and zone borders for %s (src = client + hand-written borders, v = 1)" % INFO.get("name", TARGET),
       "-- GENERATED by tools/research/travel_data.py from client TaxiNodes/TaxiPath/TaxiPathNode (build %s)" % BUILD,
       "-- and tools/research/zone_borders.json. DO NOT EDIT.",
       "-- transports[i] = { kind (\"zeppelin\", \"boat\"), faction (\"A\", \"H\", \"AH\"), { zone, x, y, name }, { zone, x, y, name } }",
       "-- borders[i] = { zone, zone }: zones you can walk between",
       "local _, ns = ...",
       "ns.TravelData = { transports = {}, borders = {} }",
       "local T, B = ns.TravelData.transports, ns.TravelData.borders"]
for p, kind, fac, (a, b) in transports:
    out.append("T[#T+1]={%s,%s,{%d,%s,%s,%s},{%d,%s,%s,%s}} -- path %d" % (
        s(kind), s(fac), a[0], a[1], a[2], s(a[3]), b[0], b[1], b[2], s(b[3]), p))
for a, b in pairs:
    out.append("B[#B+1]={%d,%d}" % (a, b))
open(os.path.join(ADDON, "Database", "Travel.lua"), "w", encoding="utf-8", newline="\n").write("\n".join(out) + "\n")
for p, kind, fac, (a, b) in transports:
    print("%s %s: %s (%s) <-> %s (%s)" % (kind, fac, a[3], names.get(a[0]), b[3], names.get(b[0])))
print("borders: %d" % len(pairs))
for r in report:
    print("note: " + r)
