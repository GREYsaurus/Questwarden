# API audit: every name on tools/wow_api_allowlist.txt checked against Blizzard's own UI source for one
# client (docs/COMPATIBILITY.md, "API audit"). Research aid only: it reads, it never edits the allowlist.
# Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
# SPDX-License-Identifier: GPL-3.0-only
#
# Input: a checkout of https://github.com/Gethe/wow-ui-source at the branch for the client
#   (classic_era, forever, classic_anniversary), e.g. in .cache/wow-ui-source/<branch>. Nothing from it
#   is copied into the add-on; the report only records whether each name exists and how it is flagged.
# Usage: python tools/research/api_audit.py <ui-source-dir> <branch label> <out.md>
#
# For each allowlisted name the report says:
#   documented - in Blizzard_APIDocumentationGenerated (with its IsProtectedFunction / HasRestrictions flags)
#   used       - not documented, but referenced by Blizzard's own UI code on that client
#   not found  - neither; the name may still exist (C functions are not all documented), so every call
#                site must stay guarded, and it goes on the in-game check list
import os
import re
import sys
from collections import defaultdict


def load_allowlist(path):
    names = []
    with open(path, encoding="utf-8-sig") as f:
        for raw in f:
            line = raw.split("#", 1)
            name = line[0].strip()
            note = line[1].strip() if len(line) > 1 else ""
            if name and not name.startswith("write:"):
                names.append((name, note))
    return names


def load_docs(root):
    """name -> flags, where name is 'C_X.Func' or a global 'Func'."""
    docs = {}
    doc_dir = os.path.join(root, "Interface", "AddOns", "Blizzard_APIDocumentationGenerated")
    if not os.path.isdir(doc_dir):
        return docs
    for fn in os.listdir(doc_dir):
        if not fn.endswith(".lua"):
            continue
        text = open(os.path.join(doc_dir, fn), encoding="utf-8", errors="replace").read()
        ns_m = re.search(r'Namespace\s*=\s*"([^"]+)"', text)
        ns = ns_m.group(1) if ns_m else None
        fn_block = re.search(r"Functions\s*=\s*\{(.*?)\n\t\},", text, re.S)
        if not fn_block:
            continue
        for m in re.finditer(r'\{\s*Name\s*=\s*"(\w+)",\s*Type\s*=\s*"Function",(.*?)\n\t\t\}', fn_block.group(1), re.S):
            body = m.group(2)
            flags = []
            if "IsProtectedFunction = true" in body:
                flags.append("protected")
            if "HasRestrictions = true" in body:
                flags.append("restricted")
            key = (ns + "." + m.group(1)) if ns else m.group(1)
            docs[key] = flags
            if ns:
                docs.setdefault(ns, [])
    return docs


def load_words(root):
    words = defaultdict(int)
    rx = re.compile(r"[A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)?")
    for dirpath, _, files in os.walk(os.path.join(root, "Interface")):
        if "Blizzard_APIDocumentationGenerated" in dirpath:
            continue
        for fn in files:
            if fn.endswith((".lua", ".xml")):
                text = open(os.path.join(dirpath, fn), encoding="utf-8", errors="replace").read()
                for w in rx.findall(text.replace(":", ".")):  # Frame:Method() counts as Frame.Method
                    words[w] += 1
                    if "." in w:
                        words[w.split(".")[0]] += 1
    return words


def main():
    if len(sys.argv) != 4:
        sys.exit("usage: python tools/research/api_audit.py <ui-source-dir> <branch label> <out.md>")
    src, label, out = sys.argv[1:]
    here = os.path.dirname(os.path.abspath(__file__))
    allow = load_allowlist(os.path.join(here, "..", "wow_api_allowlist.txt"))
    docs, words = load_docs(src), load_words(src)
    # Names the add-on reaches by string through Compat.has / Compat.Has (the lint gate cannot see these).
    by_name = set()
    addon_dir = os.path.join(here, "..", "..", "addon")
    for dirpath, _, files in os.walk(addon_dir):
        for fn in files:
            if fn.endswith(".lua"):
                text = open(os.path.join(dirpath, fn), encoding="utf-8", errors="replace").read()
                by_name.update(re.findall(r'\b[Hh]as\("([A-Za-z_][A-Za-z0-9_.]*)"\)', text))
    listed = set(n for n, _ in allow)
    for n in sorted(by_name - listed):
        allow.append((n, "reached by name through Compat.has (NOT on the allowlist)"))
    rows, counts, flagged, missing = [], defaultdict(int), [], []
    for name, note in allow:
        if name in docs:
            status = "documented"
            fl = docs[name]
        elif words.get(name, 0) > 0:
            status, fl = "used", []
        elif "optional" in note.lower():
            status, fl = "optional add-on", []
        elif "globalstrings" in note.lower() or "global string" in note.lower():
            status, fl = "global string", []
        else:
            status, fl = "not found", []
        counts[status] += 1
        rows.append((name, status, ", ".join(fl), note))
        if fl:
            flagged.append((name, ", ".join(fl), note))
        if status == "not found":
            missing.append((name, note))
    lines = [
        "# API audit: %s" % label,
        "",
        "Generated by `tools/research/api_audit.py` from Blizzard's UI source for this client"
        " (github.com/Gethe/wow-ui-source, branch `%s`). Do not edit by hand." % label,
        "",
        "Every name on `tools/wow_api_allowlist.txt` (%d) is looked up in Blizzard's generated API documentation"
        " and in Blizzard's own UI code. **This is evidence, not an in-game test.** C functions are not all"
        " documented, so *not found* means \"unconfirmed\": the call site must be guarded and the name goes on the"
        " in-game checklist. Method and decisions: docs/COMPATIBILITY.md." % len(allow),
        "",
        "*optional add-on* names belong to other add-ons (always nil-checked); *global strings* come from the client's"
        " GlobalStrings, which the UI source does not include.",
        "",
        "| Result | Count |",
        "|---|---|",
    ]
    for k in ("documented", "used", "optional add-on", "global string", "not found"):
        lines.append("| %s | %d |" % (k, counts[k]))
    lines += ["", "## Protected or restricted on this client", "",
              "`protected`: Blizzard marks the function IsProtectedFunction (secure code only). "
              "`restricted`: HasRestrictions (it can be refused depending on combat, hardware events or group state).", ""]
    if flagged:
        lines += ["| API | Flags | Allowlist note |", "|---|---|---|"]
        lines += ["| `%s` | %s | %s |" % r for r in flagged]
    else:
        lines.append("None.")
    lines += ["", "## Not found (guard and check in game)", ""]
    if missing:
        lines += ["| API | Allowlist note |", "|---|---|"]
        lines += ["| `%s` | %s |" % r for r in missing]
    else:
        lines.append("None.")
    lines += ["", "## All names", "", "| API | Result | Flags | Allowlist note |", "|---|---|---|---|"]
    lines += ["| `%s` | %s | %s | %s |" % r for r in rows]
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines) + "\n")
    print("%s: %d names - %s" % (label, len(allow), ", ".join("%s %d" % (k, counts[k]) for k in ("documented", "used", "optional add-on", "global string", "not found"))))
    print("protected/restricted: %d, not found: %d -> %s" % (len(flagged), len(missing), out))


if __name__ == "__main__":
    main()
