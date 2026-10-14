# The tree-sitter oracle

nvim 0.11 with the nvim-treesitter parsers is on the development machine, so
tree-sitter's highlight captures are a free, independent reference for how
good a tokenizer is. `tests/oracle/` turns that into a number per language
that only goes up.

## How it works

- `tests/oracle/dump_ts.lua` (run with `nvim -u NONE --headless -l`) parses
  files with the installed parser, runs the language's `highlights` query
  (injections included) and writes `row start end capture` lines, in the order
  a highlighter applies them. It adds nvim-treesitter's checkout to the runtime
  path read-only and installs nothing.
- `tests/oracle/dump.m31` writes the same shape from this library, with the
  tree-sitter name of each class.
- `tests/oracle/compare.py` maps capture names to classes (`SYN_class.from_capture`,
  mirrored in Python), folds the classes the tokenizer cannot know (operators,
  punctuation, plain variables, members, builtin variables) to "plain" on both
  sides, and counts the share of **non-whitespace bytes** whose class is the same.
  With `--top N` it lists the biggest disagreements with sample words.
- Two corpora. The **fixtures** (`tests/oracle/fixtures`, about 50 files cut to
  at most 120 lines, with tree-sitter's dumps committed in `tests/oracle/ts`)
  run in `tests/test.sh` on every platform with python3: each language must
  stay at or above its floor in `tests/oracle/floors.json` (a tenth of a point
  under the measured number; floors only go up). `refresh.sh` regenerates the
  dumps after a fixture changes. The **big corpus** (`corpus.py`: a listing of
  real files from the repos and the system, deterministic) is run by
  `report.sh`; nothing from it is committed.
- Languages without an installed parser (kotlin, swift, ruby, php and most
  others) are covered by the snapshot fixtures in `tests/t_langs.m31` only.

The metric is deliberately blunt: a keyword highlighter will not match a
parser on `@variable.parameter` or on a type used far from its declaration,
and does not try to. The number is for finding mistakes (a whole language's
numbers moving) and for the disagreements list, not for 100%.

## Numbers

Big corpus (12 files per language, up to 48 KB each; bytes are the
non-whitespace bytes compared), by release. 0.2.0 changed what the tokenizer
emits where tree-sitter's choices were measurably different (see RENAMES.md):
`#include` is the import keyword, string escapes and list markers are
special, a link is all link, `$name` is plain and `$NAME` a constant, shell
commands are calls, YAML plain scalars are strings, fenced code is raw
under its language's own tokens, diff headers and hunks follow the diff
grammar; and CSS, YAML, INI, Dockerfile and markup got scanners of their own.
It also changed the metric (conceal and `_`-private captures are ignored;
`variable.member` agrees with plain or MEMBER, `property` with MEMBER).

| language | files | bytes | 0.1.0 | 0.2.0 |
|---|---:|---:|---:|---:|
| asm | 12 | 45085 | 84.1% | 95.86% |
| c | 12 | 32861 | 84.6% | 89.85% |
| cpp | 12 | 31769 | 90.9% | 95.03% |
| css | 12 | 16812 | 76.8% | 98.95% |
| diff | 12 | 59999 | 90.0% | 99.56% |
| dockerfile | 12 | 13784 | 63.7% | 67.23% |
| go | 12 | 34589 | 98.7% | 99.32% |
| html | 12 | 44011 | 81.0% | 98.92% |
| ini | 11 | 9107 | 83.9% | 93.17% |
| java | 7 | 36900 | 89.2% | 88.51% |
| javascript | 12 | 98524 | 56.2% | 87.81% |
| json | 12 | 97519 | 89.7% | 100.00% |
| jsonc | 1 | 620 | 90.3% | 100.00% |
| lua | 12 | 36441 | 89.2% | 90.15% |
| markdown | 12 | 122783 | 82.1% | 95.31% |
| python | 12 | 53039 | 97.3% | 98.80% |
| rust | 12 | 118211 | 94.3% | 94.47% |
| sh | 11 | 46395 | 75.2% | 94.83% |
| sql | 4 | 10380 | 87.1% | 87.12% |
| toml | 12 | 18960 | 97.6% | 97.64% |
| typescript | 12 | 10262 | 87.6% | 89.29% |
| vim | 11 | 38544 | 46.1% | 50.45% |
| xml | 12 | 21732 | 94.1% | 94.46% |
| yaml | 12 | 36969 | 70.7% | 97.76% |

vim, dockerfile, javascript, sql and typescript are the languages to read the
disagreement lists for (`report.sh --top 6 --lang vim`):

- vim: `syn match name /pattern/` patterns are strings and `syn`/`hi`/`match`
  commands keywords in tree-sitter's vim; the tokenizer does not parse
  commands.
- dockerfile: comment lines inside a multi-line `RUN` are plain there, and
  heredoc bodies are shell.
- javascript/typescript: object-literal keys (`{ a: 1 }`), shorthand
  methods and parameters are `@property`/`@variable.parameter` on a parse,
  indistinguishable from labels by tokens alone.
- sql: column and table names are `@property`/`@type` (the tokenizer has no
  schema), `NULL` and `DEFAULT` are types / attributes.
- c/cpp: field declarations are `@property`; typedef'd names are `@type`.

