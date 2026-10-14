# ts-runtime: a tree-sitter-compatible runtime in m31 (spike)

**Status: not built. The input the spike needed is not on this machine.**

The plan was to take tree-sitter's generated `parser.c` for the JSON grammar
from the local nvim parsers' sources, transpile its static tables and its
`ts_lex` state machine to m31 data and an m31 LR runtime, parse real JSON
files, and compare node ranges with nvim's tree-sitter. What exists locally
(`~/.local/share/nvim/lazy/nvim-treesitter/parser/*.so`, plus
`parser-info/*.revision`) is compiled parsers only:

- no `parser.c`, `grammar.json` or `node-types.json` anywhere on the machine
  (`find / -name parser.c` is empty; the cargo registry has no tree-sitter
  grammar crates either);
- the `.so` files hold the same tables (`ts_parse_table`, `ts_small_parse_table`,
  `ts_parse_actions`, `ts_lex_modes`, `ts_symbol_names`...) in `.rodata`, which
  could be read back through the ELF symbol table and relocations, but
  `ts_lex` and `ts_lex_keywords` are machine code, not a table: they cannot
  be transpiled, only re-derived from the grammar. Without `grammar.json`
  there is nothing to derive them from.

The brief said to skip the spike in that case and say so; this is that
statement. The sources are one `git clone` of `tree-sitter/tree-sitter-json`
away (`src/parser.c` is checked in there), so the experiment is cheap to run
the day the sources are allowed in.

## What was measured instead

Whether m31 can hold a parser-sized static table at all, since that is the
part of the design that could have been a wall (`tabletest.py`):

| | |
|---|---|
| table | one `const Array<int>` of 1 000 000 entries (3.4 MB of source) |
| `m31c --emit-c` | 0.9 s, 13 MB of C |
| `cc -O2` | 5.2 s |
| executable | 8.1 MB (an m31 `int` is 8 bytes) |
| 1 000 000 lookups | 10 ms |

So: compile time and memory are acceptable for a grammar the size of JSON
(a few thousand parse-table cells), and workable for a large one. The
constraints that matter, from the language reference:

- a collection constant holds at most 2^20 (1 048 576) elements, so a large
  grammar's parse table (rust: about 1.5 M cells) must be split into rows or
  chunks, e.g. `Array<Array<int>>` constants;
- every element is an 8-byte `int`; the 16-bit tables of `parser.c` cost 4x
  their size (rust: about 12 MB of static data), fine for a desktop program;
- there is no pointer-to-function table (m31 has callbacks by name, not
  function pointers in constants), so the lexer's `switch` per lex state
  would be one big generated function with an `if` chain per state, or a
  table-driven DFA built from the grammar's regexes: the latter is what a
  generator written in m31 or Python would emit anyway.

## What the runtime would be

- LR(1) table interpreter with tree-sitter's actions (shift, reduce, accept,
  recover), `ts_parse_table` for large states and `small_parse_table` for the
  rest: about 400 lines of m31.
- Lexer as generated code per grammar (or a DFA table), with the external
  scanner (JSON has none; most real grammars do, and those are C code that
  has to be ported by hand).
- Node output as (symbol, start, end, field) triples; highlight queries are a
  separate matter (`highlights.scm` needs the query language: S-expressions,
  predicates, captures).

The honest estimate: the LR core and the JSON-only lexer are a day's work;
reading arbitrary grammars needs the external scanners ported, which is where
the cost is, not in the tables. The oracle keeps the tokenizer honest in the
meantime (docs/ORACLE.md): where it plateaus is where a parser would be needed.
