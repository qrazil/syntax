# Changes that break callers

Renames, moves and removed names, newest first. A release that changes a name
or a module path adds an entry here.

## 0.3.0

No name or module changed. Added and changed behaviour, again from the oracle:

- A Makefile is scanned as one: `NAME :=` is a PROPERTY, rule targets
  FUNCTION (special targets CALL), recipe lines are shell.
- Vim script `syn`/`hi` lines: group names TYPE, keyword lists and patterns
  STRING, attributes PROPERTY with CONSTANT values.
- JavaScript/TypeScript: `key:` in an object literal is a PROPERTY, and
  FUNCTION when its value is a function or arrow; `@tag` and `{Type}` in
  `/** */` comments are KEYWORD and TYPE.
- Rust: `#[derive(Debug)]` highlights its names (CALL, TYPE) and leaves the
  brackets plain; `crate` and `super` are plain; a `"` string may span lines.
  Strings span lines in ruby, php, perl, ocaml, fsharp, nix, powershell, r,
  fish, elixir, erlang, cmake and sh as well.
- A shell command continued with a trailing backslash does not make the next
  line's first word a command.

## 0.2.0

No name or module changed. Behaviour changed where the tree-sitter oracle
showed the tokenizer disagreeing with a real parser; a consumer that compares
class numbers (rather than drawing them) should note:

- New class `MEMBER` (24, `variable.member`), emitted for `a.b` / `a->b`
  fields; it folds to NORMAL with `SYN_class.legacy`. `PUNCTUATION` now folds
  to SPECIAL (table pipes, block-quote markers, thematic breaks in markdown).
- `#include` is a KEYWORD (was PREPROC); `#define`, `#ifdef`... stay PREPROC
  and the macro name after them is a CONSTANT (a CALL for `#define F(x)`).
- Escapes inside strings (`\n`, `\x41`, `\u{..}`) are SPECIAL.
- Shell: commands are calls (`echo`, `printf`, `set` and user functions),
  `export`/`declare`/`local` stay keywords, `$` and lowercase names are
  plain and `$NAME` is a CONSTANT, redirect targets are SPECIAL, `NAME=value`
  values are strings, `$(...)` inside a string is code, the shebang is
  PREPROC.
- Markdown: ATX headings are TITLE all the way through (the `#` marker is no
  longer SPECIAL); a link's text and url are both LINK (the url was COMMENT);
  list markers and task boxes are SPECIAL; fenced code is RAW wherever its own
  language leaves it plain (fence delimiters are RAW, the info string plain);
  indented code is RAW; `===` underlines are TITLE.
- YAML: keys are PROPERTY, plain scalars are STRING, numbers NUMBER,
  booleans/null CONSTANT; `run:` block scalars are shell.
- INI: section names are TITLE, values STRING; diff headers, hunks and
  `+`/`-` lines follow the diff grammar (the leading marker is plain).
- CSS/SCSS/Less: tags are TAG, classes TYPE, ids CONSTANT, units STRING.
- HTML: link/heading/emphasis/code text takes its element's class; `href`
  and `src` values are SPECIAL.
- JavaScript/TypeScript: regex literals are STRING (they were broken by a
  quote or backtick inside them).

## 0.1.0

First version. It replaces `MED_syntax` (the editor) and `TUI_syntax` (tui);
nothing is renamed from this library, since it is new. For a consumer coming
from either of those:

- `language_of(path, first_line)` is `SYN_detect.language_of`; TypeScript and
  TSX are the language `typescript` (they were `javascript`), and `.jsonc` is
  `jsonc` (it was `json`).
- `classify(lang, line, state)` is `SYN_highlight.classify`; the class numbers
  0..11 are the same, and `SYN_class.legacy(class)` folds the new classes
  (PROPERTY, CALL, TAG, ...) onto them. The `state` values are opaque and were
  never stable: do not store them.
- The cached per-file object is `SYN_highlight.Highlighter` (`set_lines`,
  `classes`, `update`).
