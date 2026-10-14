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

Big corpus, tokenizer at the first release (12 files per language, up to 48 KB
each; bytes are the non-whitespace bytes compared):

| language | files | bytes | agreement |
|---|---:|---:|---:|
| asm | 12 | 45085 | 84.1% |
| c | 12 | 32861 | 84.6% |
| cpp | 12 | 31769 | 90.9% |
| css | 12 | 16812 | 76.8% |
| diff | 12 | 59999 | 90.0% |
| dockerfile | 12 | 13784 | 63.7% |
| go | 12 | 34589 | 98.7% |
| html | 12 | 44011 | 81.0% |
| ini | 11 | 9107 | 83.9% |
| java | 7 | 36900 | 89.2% |
| javascript | 12 | 98524 | 56.2% |
| json | 12 | 97519 | 89.7% |
| jsonc | 1 | 620 | 90.3% |
| lua | 12 | 36441 | 89.2% |
| markdown | 12 | 122783 | 82.1% |
| python | 12 | 53039 | 97.3% |
| rust | 12 | 118211 | 94.3% |
| sh | 11 | 46395 | 75.2% |
| sql | 4 | 10380 | 87.1% |
| toml | 12 | 18960 | 97.6% |
| typescript | 12 | 10262 | 87.6% |
| vim | 11 | 38544 | 46.1% |
| xml | 12 | 21732 | 94.1% |
| yaml | 12 | 36969 | 70.7% |

(The dockerfile, javascript, vim and yaml numbers are the ones to read the
disagreement lists for: they are dominated by a few constructs, listed in the
"Known gaps" below.)

## Known gaps, from the disagreement lists

- javascript: the corpus is dominated by tree-sitter grammar files and
  generated parsers; regex literals and `//` inside template strings are the
  main mismatches.
- vim: `syn`, `hi`, `match` and `keyword` commands are keywords on tree-sitter's
  side; the tokenizer's vim keywords are the scripting ones.
- yaml: `yes`/`no` and block-scalar markers are strings in tree-sitter's yaml.
- sh: functions called by name (`bad`, `note`) and `$VAR` names are
  `@function.call`/`@constant` in tree-sitter's bash.
- c/cpp: member access (`->x`, `.x`) is `@property` there; types declared
  elsewhere are `@type` (the tokenizer guesses by spelling).
