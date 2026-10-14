# syntax: design

A small lexical highlighter, shared. This is how it is put together and why.

## The model

A buffer is lines. A language turns one line, given the **state** the line
before it ended in, into **spans** (start, end, class) and the state it ends in.
A state is one `int`; 0 means "plain". An open block comment, a triple-quoted
string, a heredoc, a markdown fence, an HTML `<script>` body each leave a
non-zero state, so a line can be classified knowing nothing but its text and
one number.

Classes (`SYN_class`) are numbered 0..11 as the editor and tui had them
(NORMAL, COMMENT, STRING, NUMBER, KEYWORD, TYPE, FUNCTION, PREPROC, CONSTANT,
OPERATOR, SPECIAL, TITLE) and extended (PROPERTY, TAG, ATTRIBUTE, PUNCTUATION,
CALL, ADDED, REMOVED, LINK, EMPHASIS, STRONG, RAW, BUILTIN_VAR, MEMBER). Each has
the name of the tree-sitter capture it stands for (`name_of`, `from_capture`),
so a parser-backed engine can fill the same classes and the oracle comparison
is a direct mapping. The tokenizer produces a subset (it never emits
PUNCTUATION or OPERATOR; it has no scopes, so MEMBER and parameters are rare).

## Languages are data

`core/SYN_lang.m31` defines `Lang`: word lists (keywords, types, constants,
builtins, specials, declaration words), comment forms (line, block, nesting
block, Lua-style long brackets, line-start-only), string forms (open, close,
escape, flags: multi-line, char literal, raw with `#`s, long bracket,
interpolating), attribute forms, a handful of flags, and the comment leader
and indentation style the structure helpers use. A file in `langs/` fills one
and calls `build()`.

`build()` compiles the lists once:

- `start`: 256 masks, one per byte, saying which token kinds that byte can
  begin (word, digit, string, comment, sigil, attribute, preprocessor). The
  hot loop reads one table entry per byte, and a byte that begins nothing
  (most of them: spaces, operators, punctuation) costs that one load.
- `table`/`blob`: an open-addressing hash table of the word lists keyed on an
  identifier's bytes (FNV-ish, case-folded for SQL and friends). A lookup
  allocates nothing; it hashes the bytes in place and compares against the
  blob.

Modes are the exception, for formats that are not "code": `markdown`,
`markup` (HTML, XML, Vue, Svelte), `diff`, `gitcommit`, `gitrebase` and `yaml`
(block scalars). They are small scanners of their own that reuse the engine
for what lies inside them.

## State packing and injection

```
bits 0..11    the language's own state: kind, form index, nesting level
bits 12..19   id of an injected language (SYN_registry.id_of), 0 = none
bits 20..     that language's own state, which may itself carry an injection
```

A host mode (markdown, markup) decides per line what is inside a foreign
language and says so through the scanner (`inj_lang`, `inj_from`, `inj_to`,
`inj_state`); `SYN_engine.scan` runs the inner language over that range,
shifts its spans into the line and packs its end state above the host's. So a
fenced `rust` block in markdown, a `<script lang="ts">` in a Vue file, and a
python triple-quoted string spanning lines inside a fence all carry state the
same way. Three levels fit comfortably in 63 bits.

## Incremental re-highlighting

`Highlighter` caches the state at the start of every line it has walked
(`starts`). Asking for the classes of line *i* walks the lines not yet visited
(states only, tokens are not kept), then tokenizes line *i* alone. After an
edit the caller passes the first changed line and the buffer's new lines:

```
update(first_changed, lines) -> [from, to)
```

Inserted or removed lines shift the cached states with them; the walk restarts
at `first_changed` and **stops at the first later line whose start state
equals the cached one** (everything after is unchanged). `[from, to)` is the
range to redraw. Typing in a line that does not open or close a construct
costs one line; opening a `/*` costs the lines until it closes.

The highlighter holds the caller's `List<str>` by reference, so a caller
edits its list and then calls `update`; the highlighter remembers how many
lines its cache describes (`synced`) to tell inserted from removed lines.

## Structure helpers

On top of the token stream, no parser (`SYN_structure`): bracket matching
that skips strings and comments (it asks the highlighter for the classes of
each line it crosses), the comment leader per language for `gc` toggles,
block opener/closer hints for auto-indent (by bracket, trailing colon, or
keyword, per the language's `indent_style`), and symbol extraction by token
patterns (a declaration word then a name; and for C-like languages a
`type name(` header at the declaration depth).

## What it does not do

No parse tree, so no scopes, no "this identifier is a parameter", no
distinguishing a type from a variable by position. Regex literals in
JavaScript are not strings; template interpolation is part of the string;
macro bodies are code. When that matters, the long-term answer is a real
parser filling the same classes (see experiments/ts-runtime, if present).

## Why not the editor's or tui's copy

Both were one 900-line function per concern with per-language `if` chains
and `List<str>` scans per identifier: adding a language meant editing the
engine, and the two copies drifted (the editor's markdown grew inline
emphasis and fence injection; tui's did not). One engine and per-language
data removes the drift, the tables make it fast (100k lines classify in well
under a tenth of a second cold), and the oracle makes "better" a number.
