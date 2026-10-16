#!/usr/bin/env bash
# The command lines of the two developer tools this repository has (the library
# itself has no executable): tests/oracle/dump.m31 and tests/tools/show.m31.
# Help, refusals, errors and their exit status, and one real run each. The
# grammar is Oro's `args` (m31's docs/cli-conventions.md).
#
#   M31_ROOT=/path/to/m31 LANGC=/path/to/m31c bash tests/test_cli.sh
#
# macOS-safe: bash 3.2, BSD tools, mktemp, no GNU timeout.
set -uo pipefail
cd "$(dirname "$0")/.."

if [ -z "${M31_ROOT:-}" ] || [ ! -f "$M31_ROOT/config.sh" ] || [ ! -d "$M31_ROOT/runtime" ]; then
    echo "M31_ROOT is not set to an m31 checkout or release" >&2
    exit 1
fi
. "$M31_ROOT/runtime/arch.sh"
LANGC=${LANGC:-./m31c}

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
pass=0
fail=0
note() { printf '\033[32mok\033[0m   %s\n' "$1"; pass=$((pass + 1)); }
bad() { printf '\033[31mFAIL\033[0m %s\n' "$1"; shift; printf '%s\n' "$@" | sed 's/^/     /'; fail=$((fail + 1)); }

build() {
    local name=$1 src=$2
    if ! "$LANGC" --emit-c "$src" -o "$WORK/$name.c" 2>"$WORK/$name.diag"; then
        bad "compile $name" "$(head -5 "$WORK/$name.diag")"
        return 1
    fi
    if ! cc -O2 -w -I "$M31_ROOT/runtime" -pthread -o "$WORK/$name" "$WORK/$name.c" \
        "$M31_ROOT/runtime/rt.c" "$M31_ROOT/runtime/scheduler.c" "$M31_ROOT/$RT_REACTOR_C" "$M31_ROOT/$RT_CTX_ASM" 2>"$WORK/$name.cc"; then
        bad "cc $name" "$(head -5 "$WORK/$name.cc")"
        return 1
    fi
}

# run TOOL ARGS... -> $out $err $code
run() {
    local tool=$1
    shift
    "$WORK/$tool" "$@" >"$WORK/out" 2>"$WORK/err" </dev/null
    code=$?
    out=$(cat "$WORK/out")
    err=$(cat "$WORK/err")
}
expect() {
    local label=$1 want=$2 so=${3:-} se=${4:-}
    if [ "$code" != "$want" ]; then
        bad "$label" "exit $code, want $want" "stdout: $out" "stderr: $err"
    elif [ -n "$so" ] && [[ "$out" != *"$so"* ]]; then
        bad "$label" "stdout lacks: $so" "stdout: $out"
    elif [ -n "$se" ] && [[ "$err" != *"$se"* ]]; then
        bad "$label" "stderr lacks: $se" "stderr: $err"
    else
        note "$label"
    fi
}

printf 'local x = 1\n' >"$WORK/a.lua"
printf '%%%% lua\nlocal y = 2\n' >"$WORK/samples.txt"

if build dump tests/oracle/dump.m31; then
    run dump --help;   expect "dump --help" 0 "usage: dump [<LANG PATH>...]"
    run dump lua;      expect "dump: a language with no file" 2 "" "'lua' has no file: arguments come as LANG PATH pairs"
    run dump --nope;   expect "dump: unknown option" 2 "" "dump: unknown option '--nope'"
run dump -h;       expect "dump: -h is refused" 2 "" "write '--help'"
run dump --;       expect "dump: a lone -- is refused" 2 "" "has no meaning here"
run dump --version; expect "dump: no --version (a dev tool)" 2 "" "unknown option '--version'"
    run dump lua "$WORK/a.lua"
    expect "dump LANG PATH" 0 "@@ lua $WORK/a.lua"
    first=$out
    run dump - "$WORK/a.lua"
    expect "dump - detects the language" 0 "@@ lua $WORK/a.lua"
    run dump lua "$WORK/a.lua" lua "$WORK/a.lua"
    [ "$(printf '%s\n' "$out" | grep -c '^@@ ')" = 2 ] && note "dump: two pairs, two files" || bad "dump pairs" "$out"
    run dump lua "$WORK/missing.lua"
    expect "dump: an unreadable file is a !! line" 0 "!! $WORK/missing.lua"
    fi

if build show tests/tools/show.m31; then
    run show --help;   expect "show --help" 0 "usage: show <SAMPLES>"
    run show;          expect "show: no file" 2 "" "missing <SAMPLES>"
    run show --nope x; expect "show: unknown option" 2 "" "show: unknown option '--nope'"
    run show a b;      expect "show: two files" 2 "" "unexpected argument 'b'"
    run show "$WORK/missing.txt"; expect "show: an unreadable file exits 1" 1 "" "show: $WORK/missing.txt"
    run show "$WORK/samples.txt"; expect "show SAMPLES" 0 "%% lua"
fi

echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
