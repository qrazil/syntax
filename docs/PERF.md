# Performance

`bash tests/test.sh --bench` builds and runs `tests/bench.m31` (a 100 000-line
C file made of repeated realistic lines, gcc -O2, the m31 runtime without
RC_DEBUG, one core). Numbers from the machine this was developed on
(x86-64 Linux); a time is not a fixture, so nothing compares them.

| what | time |
|---|---|
| cold: states of all 100 000 lines | ~55 ms |
| a 60-line viewport, warm (states cached) | < 1 ms |
| edit at line 1 that opens a `/*` (walk until it closes, 11 lines) | < 1 ms |
| edit in the middle of 100 000 lines | < 1 ms |
| the same, opening a comment (10 lines) | < 1 ms |

`classify(lang, line, state)` builds the scanner and compiles the language on
every call: fine for one-off lines (tests, a diff header), wrong for a file.
Use a `Highlighter`, which compiles once and keeps the state per line.

## Why it is fast

- A 256-entry byte table per language: most bytes start nothing and cost one
  load; no per-byte string compares and no regular expressions.
- Identifiers are hashed in place and looked up in an open-addressing table
  over a blob of words; no substring is allocated per token.
- Tokens are written as flat (start, end, class) triples into one reusable
  list; nothing is allocated per token. `classes(i)` is the only call that
  builds a per-byte list, and only for the line asked for.
- States are cached at line starts; an edit re-runs from the changed line until
  the state converges.
