#!/usr/bin/env python3
"""List a corpus of real source files per language for the oracle.

  corpus.py [--per-lang N] [--max-kb K] [--lang L ...] > manifest.tsv

Prints `OURLANG<TAB>TSLANG<TAB>PATH` lines, picking files from the repos under
/home/nox/homelab, the system (/usr/share, /usr/include, /usr/lib/python3*,
/usr/lib/golang, ~/.cargo/registry/src, ~/.config, /etc) and nvim's runtime.
Selection is deterministic (a hash of the path), so two runs agree. Nothing
is copied: the big corpus is a listing, not a fixture.
"""
import argparse, glob, hashlib, os, sys

HOME = os.path.expanduser("~")
ROOTS = [
    "/home/nox/homelab", "/usr/share", "/usr/include", "/usr/lib/python3*",
    "/usr/lib/golang/src", HOME + "/.cargo/registry/src", HOME + "/.config",
    "/etc", "/usr/share/nvim/runtime", HOME + "/.local/share/nvim/lazy",
    "/usr/lib/node_modules", "/usr/lib64/python3*",
]
SKIP = ("/.git/", "/node_modules/", "/target/", "/.m31-deps/", "/testdata/", "/__pycache__/",
        "/syntax/tests/oracle", "/syntax/langs", ".min.", "/vendor/")

# ours, tree-sitter parser, extensions
LANGS = [
    ("c", "c", ["c", "h"]),
    ("cpp", "cpp", ["cpp", "cc", "cxx", "hpp", "hh"]),
    ("go", "go", ["go"]),
    ("javascript", "javascript", ["js", "mjs", "cjs"]),
    ("typescript", "typescript", ["ts"]),
    ("json", "json", ["json"]),
    ("jsonc", "jsonc", ["jsonc"]),
    ("python", "python", ["py"]),
    ("rust", "rust", ["rs"]),
    ("sh", "bash", ["sh", "bash"]),
    ("toml", "toml", ["toml"]),
    ("yaml", "yaml", ["yaml", "yml"]),
    ("markdown", "markdown", ["md"]),
    ("java", "java", ["java"]),
    ("lua", "lua", ["lua"]),
    ("css", "css", ["css"]),
    ("html", "html", ["html", "htm"]),
    ("xml", "xml", ["xml", "svg", "xsl", "xsd"]),
    ("sql", "sql", ["sql"]),
    ("vim", "vim", ["vim"]),
    ("diff", "diff", ["diff", "patch"]),
    ("dockerfile", "dockerfile", ["dockerfile"]),
    ("ini", "ini", ["ini", "conf", "cfg"]),
    ("groovy", "groovy", ["groovy", "gradle"]),
    ("asm", "asm", ["s", "asm"]),
]

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--per-lang", type=int, default=12)
    ap.add_argument("--max-kb", type=int, default=48)
    ap.add_argument("--min-bytes", type=int, default=300)
    ap.add_argument("--lang", action="append", default=[])
    args = ap.parse_args()
    want = {}
    for ours, ts, exts in LANGS:
        if args.lang and ours not in args.lang:
            continue
        for e in exts:
            want[e] = (ours, ts)
    found = {}
    seen = set()
    for pattern in ROOTS:
        for root in glob.glob(pattern):
            for dirpath, dirs, files in os.walk(root, followlinks=False):
                if any(s in dirpath + "/" for s in SKIP):
                    dirs[:] = []
                    continue
                for f in files:
                    ext = f.rsplit(".", 1)[-1].lower() if "." in f else ""
                    key = f.lower() if f.lower() == "dockerfile" else ext
                    if key == "dockerfile":
                        ext = "dockerfile"
                    if ext not in want:
                        continue
                    p = os.path.join(dirpath, f)
                    if p in seen or any(s in p for s in SKIP):
                        continue
                    seen.add(p)
                    try:
                        size = os.path.getsize(p)
                    except OSError:
                        continue
                    if size < args.min_bytes or size > args.max_kb * 1024:
                        continue
                    ours, ts = want[ext]
                    found.setdefault((ours, ts), []).append(p)
    for (ours, ts), paths in sorted(found.items()):
        paths.sort(key=lambda p: hashlib.sha1(p.encode()).hexdigest())
        # spread: at most 3 files from one directory
        per_dir = {}
        picked = []
        for p in paths:
            d = os.path.dirname(p)
            if per_dir.get(d, 0) >= 3:
                continue
            per_dir[d] = per_dir.get(d, 0) + 1
            picked.append(p)
            if len(picked) >= args.per_lang:
                break
        for p in picked:
            print("%s\t%s\t%s" % (ours, ts, p))

main()
