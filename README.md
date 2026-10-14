# syntax

Syntax highlighting and light structure for [m31](https://github.com/qrazil/m31),
shared by the editor and every terminal app. One tokenizer, one definition
per language (as data), per-line state for multi-line constructs, and a few
helpers on the token stream: bracket matching, comment toggling, indent hints
and an outline. No parser, no terminal: the result is a class per byte.

It replaces the two drifting copies in the editor (`MED_syntax`) and `tui`
(`TUI_syntax`), keeps their API ideas, and grows the language list to
about sixty.

## Use

In a consumer's `deps`, pinned to a commit or tag:

```
syntax https://github.com/qrazil/syntax <commit>
```

then

```
import syntax.core.SYN_detect;      // which language is this file
import syntax.core.SYN_highlight;   // lines in, classes out
import syntax.core.SYN_structure;   // brackets, comments, indent, outline
import syntax.core.SYN_class;       // the class constants and their names
```

```
str name = SYN_detect.language_of(path, first_line);      // "rust", "" if unknown
SYN_highlight.Highlighter view = SYN_highlight.Highlighter(language: name);
view.set_lines(lines);                    // the buffer's lines, by reference
List<int> classes = view.classes(row);    // one SYN_class value per byte of the line
// after an edit at `row`:
List<int> redraw = view.update(row, lines);   // [from, to): lines whose tokens may have changed
```

A class is a number; `SYN_class.palette(class, is_dark)` gives the 16-colour
index to draw it with (add 256 for bold), `SYN_class.name_of(class)` the
tree-sitter capture name it stands for, and `SYN_class.legacy(class)` folds it
onto the twelve classes the editor and tui always had.

## API

| Module | What |
|---|---|
| `SYN_detect` | `language_of(path, first_line)`, `alias_of(tag)` (fence names, `:set syntax=`) |
| `SYN_highlight` | `Highlighter` (`set_lines`, `add`, `classes`, `spans`, `state_at`, `update`), `classify(lang, line, state)` for one-off lines |
| `SYN_class` | classes `NORMAL .. MEMBER`, `name_of`, `from_capture`, `legacy`, `palette` |
| `SYN_structure` | `match_bracket`, `comment_leader`, `comment_line`/`uncomment_line`/`is_commented`, `is_block_opener`/`is_block_closer`/`indent_delta`, `symbols` |
| `SYN_registry` | `names()`, `id_of`, `name_of`, `load(name)` |
| `SYN_engine`, `SYN_scanner` | the line engine and its reusable token buffer, for callers that manage their own lines |

Details, the state model and incremental re-highlighting are in
[docs/design.md](docs/design.md). The language list and what is missing is
[docs/LANGUAGES.md](docs/LANGUAGES.md); how close the tokens are to
tree-sitter's is [docs/ORACLE.md](docs/ORACLE.md); speed is
[docs/PERF.md](docs/PERF.md).

## Adding a language

A language is one file in `langs/` that fills a `Lang` (word lists, comment
and string forms, a few flags) and calls `build()`, plus a line in
`SYN_registry` (`names`, `load`) and the extension, file name and alias entries
in `SYN_tables`. Add a block to `tests/t_langs.m31` (review the masks with
`tests/tools/show.m31`) and, if tree-sitter has a parser, a fixture in the
oracle (docs/ORACLE.md).

## Test

You need `m31c` and the m31 runtime (a checkout of qrazil/m31, or an extracted
release).

```
M31_ROOT=/path/to/m31 LANGC=/path/to/m31c bash tests/test.sh
```

Checks formatting (`m31c fmt --check -r .`), the naming lint (`m31c lint .`),
the unit tests in `tests/t_*.m31` and the oracle floors. CI runs the same on
Linux x86-64, Linux aarch64 and macOS arm64.

## Layout

```
core/                  engine, classes, detection, highlighter, structure
langs/                 one data file per language (SYN_l_NAME.m31)
tests/                 test.sh runs everything; t_*.m31 are the unit tests
tests/oracle/          tree-sitter comparison: dump_ts.lua, compare.py, fixtures, floors
docs/                  design notes, language list, oracle and perf numbers
deps                   project file: name, version, dependencies
RENAMES.md             renames and moves that break callers, by release
.github/workflows/     test.yml on every push, release.yml on a v* tag
```

Module names are global to a program, so every module here is prefixed
`SYN_`. Folders are for finding files.

## Release

Add an entry to `RENAMES.md`, bump `version` in `deps`, then:

```
git tag v0.1.0 && git push origin v0.1.0
```

A layout change that breaks callers is a minor-version bump before 1.0.
