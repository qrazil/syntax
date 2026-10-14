# Changes that break callers

Renames, moves and removed names, newest first. A release that changes a name
or a module path adds an entry here.

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
