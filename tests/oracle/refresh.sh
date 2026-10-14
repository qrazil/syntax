#!/usr/bin/env bash
# Regenerate the tree-sitter side of the oracle (tests/oracle/ts/*.ts) for
# every file in a manifest, with the local nvim and nvim-treesitter parsers.
#
#   bash tests/oracle/refresh.sh [MANIFEST]      (default: tests/oracle/fixtures.tsv)
#
# Needs nvim >= 0.10 and nvim-treesitter's parser/ and queries/ on the
# runtime path (NVIM_TS_RTP, default: lazy.nvim's checkout). Only the .ts
# dumps under tests/oracle/ts are written.
set -euo pipefail
cd "$(dirname "$0")/../.."
MANIFEST=${1:-tests/oracle/fixtures.tsv}
OUT=${TS_DIR:-tests/oracle/ts}
mkdir -p "$OUT"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
awk -F'\t' '!/^#/ && NF >= 3 { print $2 "\t" $3 }' "$MANIFEST" > "$work/ts.tsv"
nvim -u NONE --headless -l tests/oracle/dump_ts.lua "$work/ts.tsv" "$OUT"
echo "dumped $(wc -l < "$work/ts.tsv") files into $OUT"
