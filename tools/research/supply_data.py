# Food, drink and ammo vendors and weapon masters for one target, for the supply reminders and the weapon skill
# tips (Core/Supplies.lua, Core/WeaponSkills.lua).
# Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
# SPDX-License-Identifier: GPL-3.0-only
#
# From the CMaNGOS world database (tools/upstream.json "cmangos"; classic-db for ClassicEra and Forever, tbc-db for TBC):
#   * item_template: food (an item spell of category 11) and drink (category 59) among consumables (class 0), with the
#     level needed to use them; ammo (class 6): arrows (subclass 2) and bullets (subclass 3).
#   * npc_vendor and npc_vendor_template (through creature_template.VendorTemplateId): who sells those items.
#   * npc_trainer and npc_trainer_template (through creature_template.TrainerTemplateId): what each weapon master
#     teaches, with the cost and level. classic-db lists the trainer's teaching spell; the 1.15.9 client's SpellEffect
#     table (effect 36, learn spell) names the skill it teaches. tbc-db lists the skill itself.
# Where the NPCs stand and whom they serve come from the target's QuestieDB NPC data (spawns, friendlyToFaction,
# subName "Weapon Master"). Vendors no faction can use are left out.
#
# Usage: python -I tools/research/supply_data.py <Target>
# Writes targets/<Target>/addon/Database/Supplies.lua.
import csv
import gzip
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from qdb import Target, arr, hsh  # noqa: E402

TARGET = sys.argv[1]
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
UP = json.load(open(os.path.join(ROOT, "tools", "upstream.json"), encoding="utf-8"))["cmangos"]
SRC = UP["tbc" if TARGET == "TBC" else "classic"]
FOOD_CATEGORY, DRINK_CATEGORY = 11, 59
SELLS = {"food": 1, "drink": 2, "arrow": 4, "bullet": 8}
MAX_SPOTS = 3
# Weapon proficiency spell -> weapon subclass (item class 2). Spell names checked in the 1.15.9 client's SpellName table.
PROFICIENCY = {196: 0, 197: 1, 264: 2, 266: 3, 198: 4, 199: 5, 200: 6, 201: 7, 202: 8, 227: 10, 15590: 13,
               1180: 15, 2567: 16, 5011: 18}


def values(s, i):
    """Yield each tuple of an INSERT ... VALUES (...),(...); starting at s[i] == '('."""
    n = len(s)
    while i < n and s[i] == "(":
        row, i = [], i + 1
        while True:
            if s[i] == "'":
                j, out = i + 1, []
                while s[j] != "'":
                    if s[j] == "\\":
                        out.append(s[j + 1])
                        j += 2
                    elif s[j:j + 2] == "''":
                        out.append("'")
                        j += 2
                    else:
                        out.append(s[j])
                        j += 1
                row.append("".join(out))
                i = j + 1
            else:
                m = re.compile(r"[^,)]*").match(s, i)
                v = m.group(0).strip()
                row.append(None if v == "NULL" else v)
                i = m.end()
            if s[i] == ",":
                i += 1
                continue
            i += 1  # )
            break
        yield row
        while i < n and s[i] in ",\r\n\t ":
            i += 1


sql = gzip.open(os.path.join(ROOT, SRC["cache"]), "rt", encoding="utf-8", errors="replace").read()


def table(name):
    create = re.search(r"CREATE TABLE `%s` \((.*?)\n\)" % name, sql, re.S).group(1)
    cols = re.findall(r"^\s*`(\w+)`", create, re.M)
    rows = []
    for m in re.finditer(r"INSERT INTO `%s` (?:\([^)]*\) )?VALUES\s*" % name, sql):
        for row in values(sql, m.end()):
            if len(row) != len(cols):
                raise SystemExit("%s row with %d fields, expected %d" % (name, len(row), len(cols)))
            rows.append(dict(zip(cols, row)))
    return rows


def num(v):
    return int(float(v or 0))


# Items -----------------------------------------------------------------------------------------------------------
food, drink, ammo = {}, {}, {}
for r in table("item_template"):
    e, cls, sub = num(r["entry"]), num(r["class"]), num(r["subclass"])
    if cls == 0:
        cats = {num(r["spellcategory_%d" % k]) for k in range(1, 6)}
        if FOOD_CATEGORY in cats:
            food[e] = num(r["RequiredLevel"])
        if DRINK_CATEGORY in cats:
            drink[e] = num(r["RequiredLevel"])
    elif cls == 6 and sub in (2, 3):
        ammo[e] = "arrow" if sub == 2 else "bullet"

# Teaching spell -> the spell it teaches (client SpellEffect, effect 36 = learn spell).
LEARN = {}
with open(os.path.join(ROOT, ".cache", "upstream", "db2", "1.15.9.70576", "SpellEffect.csv"), encoding="utf-8") as fh:
    for r in csv.DictReader(fh):
        if r["Effect"] == "36" and r["EffectTriggerSpell"] not in ("", "0"):
            LEARN[int(r["SpellID"])] = int(r["EffectTriggerSpell"])

# Who sells and teaches what --------------------------------------------------------------------------------------
creature = {num(r["Entry"]): r for r in table("creature_template")}
vend_tpl, train_tpl = {}, {}
for r in table("npc_vendor_template"):
    vend_tpl.setdefault(num(r["entry"]), []).append(num(r["item"]))
for r in table("npc_trainer_template"):
    train_tpl.setdefault(num(r["entry"]), []).append(r)
sold = {}
for r in table("npc_vendor"):
    sold.setdefault(num(r["entry"]), []).append(num(r["item"]))
taught = {}
for r in table("npc_trainer"):
    taught.setdefault(num(r["entry"]), []).append(r)
for e, c in creature.items():
    if num(c.get("VendorTemplateId")):
        sold.setdefault(e, []).extend(vend_tpl.get(num(c["VendorTemplateId"]), []))
    if num(c.get("TrainerTemplateId")):
        taught.setdefault(e, []).extend(train_tpl.get(num(c["TrainerTemplateId"]), []))

# Positions from QuestieDB ----------------------------------------------------------------------------------------
T = Target(TARGET)
raw = T._raw("NpcDB.lua", "QuestieDB.npcData")


def place(n):
    """(name, subName, faction, zone, [(x, y)...]) or None without a friendly faction or a spawn."""
    v = raw.get(n)
    if not v or len(v) < 13:
        return None
    friendly = v[12] if isinstance(v[12], str) else None
    if friendly not in ("A", "H", "AH"):
        return None
    spawns = hsh(v[6]) if v[6] else {}
    zone = v[8] if isinstance(v[8], int) and spawns.get(v[8]) else next((z for z in spawns if spawns.get(z)), None)
    if zone is None:
        return None
    pts = [(round(arr(p)[0], 1), round(arr(p)[1], 1)) for p in arr(spawns[zone]) if arr(p) and arr(p)[0] >= 0][:MAX_SPOTS]
    if not pts:
        return None
    sub = v[13] if len(v) > 13 and isinstance(v[13], str) else None
    return v[0], sub, friendly, zone, pts


def lua_str(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


vendors = []
for n in sorted(sold):
    bits = 0
    for it in sold[n]:
        if it in food:
            bits |= SELLS["food"]
        if it in drink:
            bits |= SELLS["drink"]
        if it in ammo:
            bits |= SELLS[ammo[it]]
    p = bits and place(n)
    if p:
        vendors.append((n, bits, p))

masters = []
for n in sorted(taught):
    v = raw.get(n)
    if not v or len(v) < 14 or v[13] != "Weapon Master":
        continue
    teach = {}
    for r in taught[n]:
        sp = num(r["spell"])
        sub = PROFICIENCY.get(sp, PROFICIENCY.get(LEARN.get(sp)))
        if sub is not None:
            teach[sub] = (num(r["spellcost"]), num(r["reqlevel"]))
    p = teach and place(n)
    if p:
        masters.append((n, teach, p))

out = [
    "-- Questwarden - food, drink and ammo vendors and weapon masters for " + TARGET,
    "-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)",
    "-- SPDX-License-Identifier: GPL-3.0-only",
    "-- GENERATED by tools/research/supply_data.py from the CMaNGOS world database (" + SRC["repository"] + ", commit",
    "-- " + SRC["commit"] + ", GPL-3.0): item_template, npc_vendor, npc_trainer and their templates. Positions and",
    "-- factions from the target's QuestieDB NPC data. Read by Core/Supplies.lua and Core/WeaponSkills.lua.",
    "local _, ns = ...",
    "",
    "ns.SupplyData = {",
    "    -- [item id] = level needed to use it",
    "    food = { " + ", ".join("[%d] = %d" % (k, food[k]) for k in sorted(food)) + " },",
    "    drink = { " + ", ".join("[%d] = %d" % (k, drink[k]) for k in sorted(drink)) + " },",
    "    -- [item id] = \"arrow\" or \"bullet\"",
    "    ammo = { " + ", ".join('[%d] = "%s"' % (k, ammo[k]) for k in sorted(ammo)) + " },",
    "    -- [npc id] = { name, subName or false, faction (\"A\", \"H\", \"AH\"), sells (1 food, 2 drink, 4 arrows,",
    "    -- 8 bullets, added), zone, { x, y }, ... }",
    "    vendors = {",
]
for n, bits, (name, sub, fac, zone, pts) in vendors:
    out.append("        [%d] = { %s, %s, \"%s\", %d, %d, %s }," % (
        n, lua_str(name), lua_str(sub) if sub else "false", fac, bits, zone,
        ", ".join("{ %s, %s }" % (x, y) for x, y in pts)))
out += [
    "    },",
    "    -- [npc id] = { name, faction, zone, x, y, { [weapon subclass] = { copper, level }, ... } }",
    "    weaponMasters = {",
]
for n, teach, (name, sub, fac, zone, pts) in masters:
    out.append("        [%d] = { %s, \"%s\", %d, %s, %s, { %s } }," % (
        n, lua_str(name), fac, zone, pts[0][0], pts[0][1],
        ", ".join("[%d] = { %d, %d }" % (s, c, l) for s, (c, l) in sorted(teach.items()))))
out += ["    },", "}", ""]
dest = os.path.join(ROOT, "targets", TARGET, "addon", "Database", "Supplies.lua")
open(dest, "w", encoding="utf-8", newline="\n").write("\n".join(out))
print("%s: %d food, %d drink, %d ammo items; %d vendors; %d weapon masters -> %s" % (
    TARGET, len(food), len(drink), len(ammo), len(vendors), len(masters), os.path.relpath(dest, ROOT)))
