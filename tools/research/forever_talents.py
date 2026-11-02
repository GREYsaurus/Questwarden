"""Questwarden - WoW: Forever talent trees from a public talent calculator (research, v=0).

Forever's talent trees are not in the client's base DB2 tables (those still hold Classic Era's 433 talents);
the game's trees come from server hotfixes (docs/FOREVER_PLAN.md). Until a hotfix source exists, the
maintainer chose (2026-11-01) to take them from an up-to-date online calculator: wowforevertalents.com,
which reads the Forever client's hotfix cache (build 1.60.1.70707). Only facts are kept: tree, name,
ranks, row, column, the prerequisite talent, the icon file name and whether the site marks the talent new
or changed. No tooltip text is copied.

Usage: python -I tools/research/forever_talents.py [--refresh]
Writes tools/research/forever_talents.json; pages are cached in .cache/research/wft/ (--refresh refetches).
"""
import html
import json
import os
import re
import sys
import time
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SITE = "https://wowforevertalents.com"
CACHE = os.path.join(ROOT, ".cache", "research", "wft")
OUT = os.path.join(ROOT, "tools", "research", "forever_talents.json")
CLASSES = ["warrior", "paladin", "hunter", "rogue", "priest", "shaman", "mage", "warlock", "druid"]
REFRESH = "--refresh" in sys.argv


def fetch(path):
    os.makedirs(CACHE, exist_ok=True)
    f = os.path.join(CACHE, path.strip("/").replace("/", "_") + ".html")
    if REFRESH or not os.path.exists(f):
        req = urllib.request.Request(SITE + path, headers={"User-Agent": "Questwarden research (github.com/GREYsaurus/Questwarden)"})
        with urllib.request.urlopen(req, timeout=30) as r:
            data = r.read().decode("utf-8")
        with open(f, "w", encoding="utf-8") as fh:
            fh.write(data)
        time.sleep(0.25)  # be polite
    with open(f, encoding="utf-8") as fh:
        return fh.read()


NODE = re.compile(r'<div class="node" style="grid-row:(\d+);grid-column:(\d+)">(.*?)</div></div>', re.S)
LABEL = re.compile(r'aria-label="([^"]*), rank \d+ of (\d+)')
FLAG = re.compile(r'class="flag (\w+)"')
ICON = re.compile(r'icons/large/([^"/]+)\.jpg')


def parse_class(cls):
    page = fetch("/" + cls + "/")
    slugs = {html.unescape(n).strip(): s for s, n in re.findall(r'href="/' + cls + r'/talents/([^/"]+)/"[^>]*>([^<]+)</a>', page)}
    trees = []
    for part in page.split('<article class="tree"')[1:]:
        name = html.unescape(re.search(r"<h2>(.*?)</h2>", part).group(1)).strip()
        talents = []
        for row, col, body in NODE.findall(part):
            m = LABEL.search(body)
            t = {"name": html.unescape(m.group(1)).strip(), "ranks": int(m.group(2)), "tier": int(row), "column": int(col)}
            fl = FLAG.search(body)
            t["flag"] = fl.group(1) if fl else "same"
            ic = ICON.search(body)
            if ic:
                t["icon"] = ic.group(1)
            slug = slugs.get(t["name"])
            if slug:
                t["page"] = "/" + cls + "/talents/" + slug + "/"
                req = re.search(r'Requires: <a href="/' + cls + r'/talents/[^/"]+/"[^>]*>([^<]+)</a>', fetch(t["page"]))
                if req:
                    t["requires"] = html.unescape(req.group(1)).strip()
            talents.append(t)
        trees.append({"name": name, "talents": talents})
    return trees


def main():
    out = {
        "_source": SITE + " (reads the WoW: Forever client's hotfix cache, build 1.60.1.70707; see " + SITE + "/about/)",
        "_read": time.strftime("%Y-%m-%d"),
        "_policy": "research facts, v=0 (docs/DATA_POLICY.md, Forever research); no tooltip text",
        "classes": {},
    }
    total = 0
    for cls in CLASSES:
        trees = parse_class(cls)
        n = sum(len(t["talents"]) for t in trees)
        total += n
        print("%s: %s" % (cls, ", ".join("%s %d" % (t["name"], len(t["talents"])) for t in trees)))
        out["classes"][cls.upper()] = trees
    with open(OUT, "w", encoding="utf-8", newline="\n") as fh:
        json.dump(out, fh, indent=1, ensure_ascii=False)
        fh.write("\n")
    print("total: %d talents -> %s" % (total, os.path.relpath(OUT, ROOT)))


if __name__ == "__main__":
    main()
