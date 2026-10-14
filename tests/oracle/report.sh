#!/usr/bin/env bash
# The big-corpus number per language: real files from the repos and the
# system (tests/oracle/corpus.py), tree-sitter's highlights from nvim, ours
# from tests/oracle/dump.m31. Prints the table docs/ORACLE.md records, and the
# top disagreements per language with --top N.
#
#   M31_ROOT=... LANGC=... bash tests/oracle/report.sh [--top N] [--lang L]
set -euo pipefail
cd "$(dirname "$0")/../.."
: "${LANGC:?set LANGC}" "${M31_ROOT:?set M31_ROOT}"
. "$M31_ROOT/runtime/arch.sh"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
python3 tests/oracle/corpus.py > "$work/corpus.tsv"
mkdir -p "$work/ts"
awk -F'\t' '{ print $2 "\t" $3 }' "$work/corpus.tsv" > "$work/ts.tsv"
nvim -u NONE --headless -l tests/oracle/dump_ts.lua "$work/ts.tsv" "$work/ts"
"$LANGC" --emit-c tests/oracle/dump.m31 -o "$work/dump.c"
cc -O2 -w -I "$M31_ROOT/runtime" -pthread -o "$work/dump" "$work/dump.c" \
    "$M31_ROOT/runtime/rt.c" "$M31_ROOT/runtime/scheduler.c" \
    "$M31_ROOT/$RT_REACTOR_C" "$M31_ROOT/$RT_CTX_ASM"
python3 tests/oracle/compare.py --dump "$work/dump" --manifest "$work/corpus.tsv" \
    --ts-dir "$work/ts" "$@"
