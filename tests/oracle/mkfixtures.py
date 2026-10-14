#!/usr/bin/env python3
"""Cut the committed oracle fixtures from the big corpus listing.

  corpus.py > big.tsv; mkfixtures.py big.tsv [--per-lang 2] [--lines 120]

Writes tests/oracle/fixtures/<lang>/<n>.<ext> (the first --lines lines of a
file, at most 8 KB) and tests/oracle/fixtures.tsv. Run refresh.sh afterwards
to write the tree-sitter dumps beside them.
"""
import argparse, os, sys, collections

ap = argparse.ArgumentParser()
ap.add_argument("manifest")
ap.add_argument("--per-lang", type=int, default=2)
ap.add_argument("--lines", type=int, default=120)
ap.add_argument("--out", default=os.path.join(os.path.dirname(os.path.abspath(__file__))))
a = ap.parse_args()
by = collections.OrderedDict()
for line in open(a.manifest):
    line = line.rstrip("\n")
    if not line or line.startswith("#"):
        continue
    ours, ts, path = line.split("\t")
    by.setdefault((ours, ts), []).append(path)
rows = []
for (ours, ts), paths in by.items():
    n = 0
    for p in paths:
        try:
            text = open(p, "rb").read().decode("utf-8")
        except Exception:
            continue
        lines = text.split("\n")[:a.lines]
        body = "\n".join(lines) + "\n"
        if len(body) > 8192:
            body = body[:8192].rsplit("\n", 1)[0] + "\n"
        if len(body) < 200:
            continue
        ext = os.path.basename(p).rsplit(".", 1)[-1] if "." in os.path.basename(p) else "txt"
        if os.path.basename(p).lower() == "dockerfile":
            name = "Dockerfile"
        else:
            name = "%d.%s" % (n, ext)
        rel = os.path.join("tests/oracle/fixtures", ours, name)
        full = os.path.join(a.out, "..", "..", rel)
        os.makedirs(os.path.dirname(full), exist_ok=True)
        open(full, "w").write(body)
        rows.append("%s\t%s\t%s" % (ours, ts, rel))
        n += 1
        if n >= a.per_lang:
            break
open(os.path.join(a.out, "fixtures.tsv"), "w").write("\n".join(rows) + "\n")
print(len(rows), "fixtures")
