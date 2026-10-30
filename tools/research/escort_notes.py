# Put the escort note before every escort pickup in a target's guides (docs/GUIDE_FORMAT.md, "Escort quests").
# Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
# SPDX-License-Identifier: GPL-3.0-only
#
# An accept step is an escort when the quest data says so (qdb.escort: quest flag 2 plus escort wording).
# Each such accept without the note right before it gets one, carrying the accept's flags (class, race,
# faction, optional, Hardcore, dungeon...) so the note shows exactly when the pickup does. Steps whose text
# calls the quest an escort while the data does not are listed for review, not changed.
# Writes guide sources. Run guides + routes afterwards.
# Usage: python tools/research/escort_notes.py ClassicEra [--dry-run]
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from qdb import Target, VERB_RE, escort, escort_note, f  # noqa: E402


args = [x for x in sys.argv[1:] if not x.startswith("--")]
T = Target(args[0] if args else "ClassicEra")
DRY = "--dry-run" in sys.argv
FLAGS_RE = re.compile(r"^\w+\s+[^|\[]*\[([^\]]*)\]")

added, review = [], []
for gid, g in sorted(T.guides.items()):
    if not g["file"]:
        continue
    src = open(g["file"], encoding="utf-8", newline="").read()
    nl = "\r\n" if "\r\n" in src else "\n"
    lines = src.replace("\r\n", "\n").split("\n")
    src_q = [i for i, l in enumerate(lines) if VERB_RE.match(l)]
    cq = [s for s in g["steps"] if s["kind"] in ("accept", "turnin", "complete")]
    if len(src_q) != len(cq):
        print("skipped (source and compiled guide differ; compile first):", gid)
        continue
    notes = {}
    for k, s in enumerate(cq):
        ln = src_q[k]
        q = T.Q.get(s["q"])
        if s["kind"] != "accept" or not q:
            continue
        said = "escort" in lines[ln].split("|", 1)[-1].lower() if "|" in lines[ln] else False
        if said and not escort(q):
            review.append("%s:%d %s - the step says escort, the quest data does not (%s)" % (
                os.path.relpath(g["file"]), ln + 1, q[0], "flag 2, no escort wording" if (f(q, 26) or 0) & 2 else "no flag 2"))
            continue
        if not escort(q):
            continue
        prev = next((lines[i] for i in range(ln - 1, -1, -1) if lines[i].strip()), "")
        if prev.startswith("note") and "is an escort" in prev and q[0] in prev:
            continue
        m = FLAGS_RE.match(lines[ln])
        notes[ln] = escort_note(q, m.group(1).split("; ") if m else ())
        added.append("%s:%d %s" % (os.path.relpath(g["file"]), ln + 1, q[0]))
    if notes and not DRY:
        out = []
        for i, l in enumerate(lines):
            if i in notes:
                out.append(notes[i])
            out.append(l)
        open(g["file"], "w", encoding="utf-8", newline="").write(nl.join(out))

for a in added:
    print("note added:", a)
for r in review:
    print("review:", r)
print("escort notes added: %d; labelled escort without data support: %d" % (len(added), len(review)))
