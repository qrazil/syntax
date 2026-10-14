#!/usr/bin/env python3
"""Compare this library's tokens with tree-sitter's highlight captures.

  compare.py --dump BIN --manifest MANIFEST [--ts-dir DIR] [--floors FILE]
             [--update-floors] [--top N] [--check]

MANIFEST: lines `OURLANG<TAB>TSLANG<TAB>PATH` (`#` comments). For each file
the tree-sitter side is read from DIR/<basename-with-slashes-replaced>.ts
(produced by dump_ts.lua; see refresh.sh), our side by running BIN.

Agreement: the share of non-whitespace bytes whose class is the same on both
sides after folding (see FOLD). Operators, punctuation and plain variables
are NORMAL on both sides: the tokenizer does not classify them.
"""
import argparse, collections, json, os, subprocess, sys

NAMES = ["variable", "comment", "string", "number", "keyword", "type", "function",
         "keyword.directive", "constant", "operator", "string.special", "markup.heading",
         "property", "tag", "attribute", "punctuation.special", "function.call", "diff.plus",
         "diff.minus", "markup.link", "markup.italic", "markup.strong", "markup.raw",
         "variable.builtin", "variable.member"]

def from_capture(name):
    """Mirror of SYN_class.from_capture, kept in step by tests/oracle/README."""
    n = name.lstrip("@")
    pre = lambda *ps: any(n.startswith(p) for p in ps)
    if pre("string.escape", "string.special", "character.special"):
        return "string.special"
    if pre("string.regexp", "string.regex"):
        return "string"
    if pre("keyword.directive", "preproc", "include", "define", "keyword.preproc"):
        return "keyword.directive"
    if pre("markup.list"):
        return "string.special"
    if pre("markup.quote", "markup.strikethrough"):
        return "comment"
    if pre("markup.heading", "text.title"):
        return "markup.heading"
    if pre("markup.link", "text.uri", "text.reference", "string.special.url"):
        return "markup.link"
    if pre("markup.italic", "text.emphasis"):
        return "markup.italic"
    if pre("markup.strong", "text.strong"):
        return "markup.strong"
    if pre("markup.raw", "text.literal"):
        return "markup.raw"
    if pre("diff.plus", "text.diff.add"):
        return "diff.plus"
    if pre("diff.minus", "text.diff.delete"):
        return "diff.minus"
    if pre("keyword", "conditional", "repeat", "exception", "storageclass"):
        return "keyword"
    if pre("function.call", "function.method", "function.macro", "function.builtin", "method", "constructor"):
        return "function.call"
    if pre("function"):
        return "function"
    if pre("type"):
        return "type"
    if pre("string", "character"):
        return "string"
    if pre("comment"):
        return "comment"
    if pre("boolean"):
        return "constant"
    if pre("number", "float"):
        return "number"
    if pre("constant"):
        return "constant"
    if pre("variable.builtin"):
        return "variable.builtin"
    if pre("variable.member"):
        return "variable.member"
    if pre("property", "field"):
        return "property"
    if pre("tag.attribute", "attribute"):
        return "attribute"
    if pre("tag"):
        return "tag"
    return "variable"

# classes folded together before comparing
FOLD = {
    "variable": "-", "operator": "-", "punctuation.special": "-", "function": "function",
    "function.call": "function", "variable.builtin": "-", "tag.delimiter": "-",
    # tree-sitter grammars use @property and @variable.member for the same
    # thing (a field); we emit MEMBER for field access and PROPERTY for keys.
    # A member on their side agrees with plain or MEMBER on ours (it needs
    # scope knowledge a tokenizer lacks), a property with PROPERTY or MEMBER.
    "variable.member": "member?",
}

# captures that carry no colour at all
IGNORED = ("conceal", "spell", "nospell", "injection", "markup.heading.marker.conceal")

def fold(c):
    return FOLD.get(c, c)

def agrees(theirs, ours, ours_raw):
    if theirs == "member?":
        return ours in ("-", "property")
    if theirs == "property":
        return ours_raw == "variable.member"
    return False

def read_ts(path):
    spans = collections.defaultdict(list)
    ok = False
    for line in open(path, errors="replace"):
        line = line.rstrip("\n")
        if line.startswith("@@") or line.startswith("!!"):
            if line.startswith("!!"):
                return None
            ok = True
            continue
        r, a, b, cap = line.split(" ", 3)
        if cap.lstrip("@").split(".")[0] in IGNORED or cap.startswith("_"):
            continue
        cls = from_capture(cap)
        # the `comment` parser injected into comments paints the whole range
        # @variable over the comment capture: not a highlight
        if cls == "variable" and spans[int(r)] and spans[int(r)][-1][:2] == (int(a), int(b)) \
                and spans[int(r)][-1][2] == "comment":
            continue
        spans[int(r)].append((int(a), int(b), cls))
    return spans if ok else None

def read_ours(text):
    out = {}
    files = {}
    cur = None
    for line in text.split("\n"):
        if line.startswith("@@ "):
            parts = line.split(" ", 2)
            cur = parts[2]
            files[cur] = collections.defaultdict(list)
        elif line.startswith("!! "):
            cur = None
        elif cur is not None and line:
            r, a, b, cap = line.split(" ", 3)
            files[cur][int(r)].append((int(a), int(b), cap))
    return files

def classes_of(spans, row, size):
    arr = ["variable"] * size
    for a, b, c in spans.get(row, []):
        for i in range(a, min(b, size)):
            arr[i] = c
    return arr

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dump", required=True)
    ap.add_argument("--manifest", required=True)
    ap.add_argument("--ts-dir", required=True)
    ap.add_argument("--floors")
    ap.add_argument("--update-floors", action="store_true")
    ap.add_argument("--top", type=int, default=0)
    ap.add_argument("--lang", action="append", default=[])
    ap.add_argument("--check", action="store_true")
    args = ap.parse_args()

    entries = []
    for line in open(args.manifest):
        line = line.rstrip("\n")
        if not line or line.startswith("#"):
            continue
        ours, ts, path = line.split("\t")
        if args.lang and ours not in args.lang:
            continue
        entries.append((ours, ts, path))

    # run our dumper once for all files
    cmd = [args.dump]
    for ours, ts, path in entries:
        cmd += [ours, path]
    res = subprocess.run(cmd, capture_output=True, text=True, errors="replace")
    ours_files = read_ours(res.stdout)

    stats = collections.defaultdict(lambda: [0, 0, 0])  # lang -> [agree, total, files]
    confusion = collections.defaultdict(collections.Counter)
    samples = collections.defaultdict(lambda: collections.defaultdict(collections.Counter))
    for ours, ts, path in entries:
        tsfile = os.path.join(args.ts_dir, path.replace("/", "__") + ".ts")
        if not os.path.exists(tsfile):
            continue
        theirs = read_ts(tsfile)
        mine = ours_files.get(path)
        if theirs is None or mine is None:
            continue
        try:
            lines = open(path, "rb").read().split(b"\n")
        except OSError:
            continue
        st = stats[ours]
        st[2] += 1
        for row, raw in enumerate(lines):
            if not raw.strip():
                continue
            a = classes_of(theirs, row, len(raw))
            b = classes_of(mine, row, len(raw))
            for i, ch in enumerate(raw):
                if ch in b" \t\r":
                    continue
                ta, tb = fold(a[i]), fold(b[i])
                st[1] += 1
                if ta == tb or agrees(ta, tb, b[i]):
                    st[0] += 1
                else:
                    confusion[ours][(ta, tb)] += 1
            # samples where we classify and tree-sitter does not
            for sa, sb, c in mine.get(row, []):
                fc = fold(c)
                if fc == "-":
                    continue
                if all(fold(a[i]) == "-" for i in range(sa, min(sb, len(raw))) if raw[i] not in b" \t"):
                    word = raw[sa:sb].decode("utf-8", "replace")[:24]
                    samples[ours][("-", fc)][word] += 1
            # token-level samples of disagreements, by their span starts
            for sa, sb, c in theirs.get(row, []):
                fc = fold(c)
                if fc == "-":
                    continue
                if any(fold(b[i]) != fc for i in range(sa, min(sb, len(raw))) if raw[i] not in b" \t"):
                    word = raw[sa:sb].decode("utf-8", "replace")[:24]
                    mine_c = collections.Counter(fold(b[i]) for i in range(sa, min(sb, len(raw))))
                    samples[ours][(fc, mine_c.most_common(1)[0][0])][word] += 1

    result = {}
    print("%-12s %6s %9s %8s" % ("language", "files", "bytes", "agree"))
    for lang in sorted(stats):
        ag, tot, nf = stats[lang]
        pct = 100.0 * ag / tot if tot else 0.0
        result[lang] = round(pct, 2)
        print("%-12s %6d %9d %7.2f%%" % (lang, nf, tot, pct))
        if args.top:
            for (ta, tb), n in confusion[lang].most_common(args.top):
                words = ", ".join("%s x%d" % (w, c) for w, c in samples[lang][(ta, tb)].most_common(5))
                print("    theirs %-16s ours %-16s %6d  %s" % (ta if ta != "-" else "plain", tb if tb != "-" else "plain", n, words))
    if args.update_floors and args.floors:
        old = {}
        if os.path.exists(args.floors):
            old = json.load(open(args.floors))
        for lang, pct in result.items():
            # a floor sits a little under the measured number (a tenth of a
            # point), and only ever goes up
            floor = round(max(old.get(lang, 0.0), pct - 0.1), 1)
            old[lang] = floor
        json.dump(old, open(args.floors, "w"), indent=2, sort_keys=True)
        open(args.floors, "a").write("\n")
    failed = 0
    if args.check and args.floors:
        floors = json.load(open(args.floors))
        for lang, pct in result.items():
            floor = floors.get(lang)
            if floor is not None and pct + 1e-9 < floor:
                print("FAIL %s: agreement %.2f%% is below its floor %.1f%%" % (lang, pct, floor))
                failed += 1
        for lang in floors:
            if lang not in result:
                print("FAIL %s: no files compared" % lang)
                failed += 1
        print("%d languages checked, %d failed" % (len(floors), failed))
    sys.exit(1 if failed else 0)

main()
