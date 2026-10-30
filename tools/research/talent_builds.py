# Talent plans for a target from decoded Icy Veins builds (docs/TALENTS.md).
# Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
# SPDX-License-Identifier: GPL-3.0-only
#
# Input: tools/research/icyveins_classic_decoded.json (the allocations, in the source's point order) and
# the target's generated Talents/Data/TalentTrees.lua (client talent data). Each point is matched to a
# client talent by its rank-1 spell id, and its tree, tier and column must agree with the client data;
# anything that does not match stops the script. Output: targets/<Target>/addon/Talents/Builds/IcyVeins.lua,
# Builds.xml and ProfileBuilds.lua. tools/build.ps1 validate then re-checks every plan point by point.
#
# Usage: python tools/research/talent_builds.py ClassicEra
import json
import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
target = sys.argv[1] if len(sys.argv) > 1 else "ClassicEra"
tdir = os.path.join(ROOT, "targets", target, "addon", "Talents")
src = json.load(open(os.path.join(ROOT, "tools", "research", "icyveins_classic_decoded.json"), encoding="utf-8"))
BASE = "https://www.icy-veins.com/wow-classic/"

# slug -> (build id, display name, role, client tree name). Within a class, the first entry is the
# default leveling plan (ns.Talents:ActiveBuild picks the first leveling build registered).
SPECS = {
    "warrior": [("arms-warrior-leveling-guide-1-60", "warrior_arms_iv", "Arms", "Melee DPS", "Arms"),
                ("fury-warrior-leveling-guide-1-60", "warrior_fury_iv", "Fury", "Melee DPS", "Fury"),
                ("protection-warrior-leveling-guide-1-60", "warrior_prot_iv", "Protection", "Tank", "Protection")],
    "paladin": [("retribution-paladin-leveling-talent-build-from-1-to-60", "paladin_ret_iv", "Retribution", "Melee DPS", "Retribution"),
                ("holy-paladin-leveling-talent-build-from-1-to-60", "paladin_holy_iv", "Holy", "Healer", "Holy"),
                ("protection-paladin-leveling-talent-build-from-1-to-60", "paladin_prot_iv", "Protection", "Tank", "Protection")],
    "hunter": [("beast-mastery-hunter-leveling-guide-1-60", "hunter_bm_iv", "Beast Mastery", "Ranged DPS", "Beast Mastery"),
               ("marksmanship-hunter-leveling-guide-1-60", "hunter_mm_iv", "Marksmanship", "Ranged DPS", "Marksmanship"),
               ("survival-hunter-leveling-guide-1-60", "hunter_sv_iv", "Survival", "Ranged DPS", "Survival")],
    "rogue": [("sword-rogue-leveling-talent-build-from-1-to-60", "rogue_combat_swords_iv", "Combat (swords)", "Melee DPS", "Combat"),
              ("dagger-rogue-leveling-talent-build-from-1-to-60", "rogue_combat_daggers_iv", "Combat (daggers)", "Melee DPS", "Combat"),
              ("subtlety-rogue-leveling-talent-build-from-1-to-60", "rogue_sub_iv", "Subtlety", "Melee DPS", "Subtlety")],
    "priest": [("shadow-priest-leveling-talent-build-from-1-to-60", "priest_shadow_iv", "Shadow", "Ranged DPS", "Shadow"),
               ("holy-priest-leveling-talent-build-from-1-to-60", "priest_holy_iv", "Holy", "Healer", "Holy"),
               ("discipline-priest-leveling-talent-build-from-1-to-60", "priest_disc_iv", "Discipline", "Healer", "Discipline")],
    "shaman": [("enhancement-shaman-leveling-guide-1-60", "shaman_enh_iv", "Enhancement", "Melee DPS", "Enhancement"),
               ("elemental-shaman-leveling-guide-1-60", "shaman_ele_iv", "Elemental", "Ranged DPS", "Elemental"),
               ("restoration-shaman-leveling-guide-1-60", "shaman_resto_iv", "Restoration", "Healer", "Restoration")],
    "mage": [("aoe-grinding-frost-mage-leveling-talent-build-from-1-to-60", "mage_frost_aoe_iv", "Frost (AoE grinding)", "Ranged DPS", "Frost"),
             ("single-target-frost-mage-leveling-talent-build-from-1-to-60", "mage_frost_st_iv", "Frost (single target)", "Ranged DPS", "Frost"),
             ("fire-mage-leveling-talent-build-from-1-to-60", "mage_fire_iv", "Fire", "Ranged DPS", "Fire"),
             ("arcane-mage-leveling-talent-build-from-1-to-60", "mage_arcane_iv", "Arcane", "Ranged DPS", "Arcane")],
    "warlock": [("affliction-warlock-leveling-talent-build-from-1-to-60", "warlock_aff_iv", "Affliction", "Ranged DPS", "Affliction"),
                ("demonology-warlock-leveling-talent-build-from-1-to-60", "warlock_demo_iv", "Demonology", "Ranged DPS", "Demonology"),
                ("destruction-warlock-leveling-talent-build-from-1-to-60", "warlock_destro_iv", "Destruction", "Ranged DPS", "Destruction")],
    "druid": [("feral-druid-leveling-talent-build-from-1-to-60", "druid_feral_iv", "Feral", "Melee DPS / Tank", "Feral Combat"),
              ("balance-druid-leveling-talent-build-from-1-to-60", "druid_balance_iv", "Balance", "Ranged DPS", "Balance"),
              ("restoration-druid-leveling-talent-build-from-1-to-60", "druid_resto_iv", "Restoration", "Healer", "Restoration")],
}

# Client talent data: class -> list of trees {id, name, talents {id, name, tier, column, ranks, spells}}
tt = open(os.path.join(tdir, "Data", "TalentTrees.lua"), encoding="utf-8").read()
trees = {}
for cm in re.finditer(r"^T\.(\w+) = \{(.*?)^\}", tt, re.S | re.M):
    cls = cm.group(1)
    trees[cls] = []
    for tm in re.finditer(r'\{id=(\d+),name="([^"]+)",background="[^"]*",icon=\d+,talents=\{(.*?)\n  \}\}', cm.group(2), re.S):
        tree = {"id": int(tm.group(1)), "name": tm.group(2), "talents": []}
        for t in re.finditer(r'\{id=(\d+),name="((?:[^"\\]|\\.)*)",tier=(\d+),column=(\d+),ranks=(\d+),spells=\{([\d,]+)\}', tm.group(3)):
            tree["talents"].append({"id": int(t.group(1)), "name": t.group(2), "tier": int(t.group(3)), "column": int(t.group(4)),
                                    "ranks": int(t.group(5)), "spells": [int(x) for x in t.group(6).split(",")]})
        trees[cls].append(tree)
    assert len(trees[cls]) == 3, (cls, len(trees[cls]))

lines = ["-- ClassicGuide - talent plans from the Icy Veins WoW Classic leveling guides",
         "-- GENERATED by tools/research/talent_builds.py from tools/research/icyveins_classic_decoded.json (docs/TALENTS.md).",
         "-- One entry per run of points, in the order the source's talent calculator records them; picks are client",
         "-- talent ids {talentId, points}. Talent allocations: Icy Veins (" + src["source"] + "wow-classic-leveling-guides,",
         "-- read " + src["read"] + "). No guide text is copied; names in the comments are for reading this file only.",
         "local _, ns = ...", ""]
spec_map = {}
total_builds = 0
for cls, specs in SPECS.items():
    CLS = cls.upper()
    decoded = {b["slug"]: b for b in src["builds"][cls]}
    byspell = {}
    for ti, tree in enumerate(trees[CLS]):
        for t in tree["talents"]:
            byspell[t["spells"][0]] = (ti, tree, t)
    lines.append('ns.RegisterTalentBuilds("%s", {' % CLS)
    for slug, bid, name, role, treeName in specs:
        b = decoded[slug]
        ranks, per_tree, runs = {}, [0, 0, 0], []
        for spell, sname, gi, row, col in b["picks"]:
            if spell not in byspell:
                sys.exit("%s %s: spell %s (%s) is not a rank-1 talent spell in the client data" % (cls, slug, spell, sname))
            ti, tree, t = byspell[spell]
            if t["tier"] != row or t["column"] != col:
                sys.exit("%s %s: %s is tier %d column %d in the client, %d/%d in the source" % (cls, slug, t["name"], t["tier"], t["column"], row, col))
            ranks[t["id"]] = ranks.get(t["id"], 0) + 1
            if ranks[t["id"]] > t["ranks"]:
                sys.exit("%s %s: %s gets more than %d ranks" % (cls, slug, t["name"], t["ranks"]))
            per_tree[ti] += 1
            if runs and runs[-1][0] == t["id"]:
                runs[-1][1] += 1
            else:
                runs.append([t["id"], 1, t["name"]])
        n = sum(per_tree)
        assert n == 51, (slug, n)
        assert any(tr["name"] == treeName for tr in trees[CLS]), (cls, treeName)
        split = "/".join(str(x) for x in per_tree)
        lines += ["    {",
                  '        id = "%s", name = "%s (Icy Veins leveling)", kind = "leveling", role = "%s",' % (bid, name, role),
                  '        summary = "Icy Veins %s, in the source\'s point order (51 points: %s).",' % (name, split),
                  '        source = { site = "Icy Veins", url = "%s%s", build = "Leveling Talent Build 1-60", order = "source" },' % (BASE, slug),
                  "        picks = {"]
        for tid, pts, tname in runs:
            lines.append("            { %d, %d }, -- %s" % (tid, pts, tname))
        lines += ["        },", "    },"]
        spec_map.setdefault(CLS, {}).setdefault(treeName, []).append(bid)
        total_builds += 1
    lines += ["})", ""]

os.makedirs(os.path.join(tdir, "Builds"), exist_ok=True)
open(os.path.join(tdir, "Builds", "IcyVeins.lua"), "w", encoding="utf-8", newline="\r\n").write("\n".join(lines))
open(os.path.join(tdir, "Builds", "Builds.xml"), "w", encoding="utf-8", newline="\r\n").write(
    '<Ui xmlns="http://www.blizzard.com/wow/ui/">\n<!-- Talent plans (docs/TALENTS.md). -->\n  <Script file="IcyVeins.lua"/>\n</Ui>\n')

pb = ["-- ClassicGuide - spec profile -> talent plan for WoW Classic Era",
      "-- Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)",
      "-- SPDX-License-Identifier: GPL-3.0-only",
      "-- GENERATED by tools/research/talent_builds.py. Specs are the client's talent tree names. Every plan runs from",
      "-- the first talent point (level 10) to 60 without a respec, and is validated against Talents/Data/TalentTrees.lua.",
      "local _, ns = ...", "", "ns.TalentProfileBuilds = {", "    specs = {"]
for CLS, m in spec_map.items():
    parts = []
    for tree, ids in m.items():
        e = 'plan = "%s"' % ids[0]
        if len(ids) > 1:
            e += ", variants = { " + ", ".join('"%s"' % i for i in ids[1:]) + " }"
        parts.append('["%s"] = { %s }' % (tree, e))
    pb.append("        %s = { %s }," % (CLS, ", ".join(parts)))
pb += ["    },",
       "    -- How the talent window names each source (ns.Talents:SourceLine). $NAME is the add-on's name.",
       "    sourceLines = {",
       '        ["Icy Veins"] = "Talents: Icy Veins WoW Classic leveling guide (point order from its talent calculator).",',
       "    },", "}", ""]
open(os.path.join(tdir, "ProfileBuilds.lua"), "w", encoding="utf-8", newline="\r\n").write("\n".join(pb))
print("wrote %d plans for %d classes" % (total_builds, len(SPECS)))
