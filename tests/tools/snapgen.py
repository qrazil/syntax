#!/usr/bin/env python3
"""Turn the output of tests/tools/show.m31 into `check.snap` calls.

  snapgen.py SHOW_OUTPUT > fragment.m31

Review the masks first: what is frozen here is what the tests will demand.
"""
import sys

def esc(s):
    return '"' + s.replace('\\', '\\\\').replace('"', '\\"') + '"'

lang, src, masks, out = None, [], [], []
lines = open(sys.argv[1]).read().split("\n")
if lines and lines[-1] == "":
    lines.pop()

def flush():
    if lang is not None and src:
        out.append('check.snap(%s, [%s], [%s]);' % (esc(lang), ", ".join(esc(s) for s in src), ", ".join(esc(m) for m in masks)))

i = 0
while i < len(lines):
    if lines[i].startswith("%% "):
        flush()
        lang, src, masks = lines[i][3:], [], []
        i += 1
        continue
    src.append(lines[i])
    m = lines[i + 1]
    assert m.endswith("|"), m
    masks.append(m[:-1].rstrip())
    i += 2
flush()
print("\n".join(out))
