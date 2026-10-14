# Languages

Every language the library knows, by name (the name `SYN_detect.language_of`
answers and `SYN_registry.load` takes). The file extensions and file names are
the detection keys in `core/SYN_tables.m31`; `#!` interpreters and modelines
(`vim: ft=...`, `-*- mode: ... -*-`) are detected too.

| name | title | extensions | file names |
|---|---|---|---|
| `c` | c | .c .h |  |
| `cpp` | cpp | .cpp .cc .cxx .c++ .hpp .hh .hxx .h++ .ipp .tpp |  |
| `go` | go | .go |  |
| `javascript` | javascript | .js .mjs .cjs .jsx .es6 .jsm |  |
| `typescript` | typescript | .ts .tsx .mts .cts |  |
| `json` | json | .json .geojson .webmanifest .har .ipynb | package-lock.json composer.lock .babelrc .eslintrc .prettierrc |
| `jsonc` | jsonc | .jsonc .json5 .code-workspace |  |
| `m31` | m31 | .m31 |  |
| `python` | python | .py .pyw .pyi .pyx .gyp .gypi |  |
| `rust` | rust | .rs |  |
| `sh` | sh | .sh .bash .zsh .ksh .bashrc .zshrc .profile .bash_profile .zprofile .envrc |  |
| `toml` | toml | .toml | Cargo.lock Pipfile poetry.lock Gopkg.lock uv.lock |
| `yaml` | yaml | .yaml .yml |  |
| `markdown` | markdown | .md .markdown .mkd .mdx .rmd | README CONTRIBUTING CHANGELOG |
| `java` | java | .java |  |
| `csharp` | C# | .cs .csx |  |
| `kotlin` | kotlin | .kt .kts |  |
| `swift` | swift | .swift |  |
| `php` | php | .php .phtml .php3 .php4 .php5 .phps .inc | composer.lock |
| `ruby` | ruby | .rb .rake .gemspec .ru .erb .builder .jbuilder .podspec | Rakefile Gemfile Guardfile Vagrantfile Podfile Brewfile Capfile Gemfile.lock .irbrc |
| `lua` | lua | .lua .rockspec | .luacheckrc |
| `perl` | perl | .pl .pm .t .pod .psgi |  |
| `r` | R | .r .rmd .rprofile | .Rprofile |
| `dart` | dart | .dart |  |
| `scala` | scala | .scala .sc .sbt |  |
| `groovy` | groovy | .groovy .gvy .gy .gsh .gradle | Jenkinsfile build.gradle settings.gradle |
| `haskell` | haskell | .hs .lhs .hsc |  |
| `elixir` | elixir | .ex .exs .heex .leex | mix.lock |
| `erlang` | erlang | .erl .hrl .escript | rebar.config rebar.lock |
| `clojure` | clojure | .clj .cljs .cljc .edn .bb | project.clj deps.edn |
| `ocaml` | OCaml | .ml .mli .mll .mly |  |
| `fsharp` | F# | .fs .fsi .fsx .fsscript |  |
| `zig` | zig | .zig .zon |  |
| `nim` | nim | .nim .nims .nimble |  |
| `julia` | julia | .jl |  |
| `sql` | SQL | .sql .ddl .dml .psql .mysql .pgsql .sqlite |  |
| `css` | css | .css .pcss .postcss |  |
| `scss` | SCSS | .scss .sass |  |
| `less` | less | .less |  |
| `dockerfile` | dockerfile | .dockerfile .containerfile | Dockerfile Containerfile |
| `makefile` | makefile | .mk .mak .make | Makefile makefile GNUmakefile |
| `cmake` | CMake | .cmake | CMakeLists.txt |
| `nix` | nix | .nix |  |
| `powershell` | PowerShell | .ps1 .psm1 .psd1 |  |
| `bat` | Batch | .bat .cmd |  |
| `fish` | fish | .fish |  |
| `vim` | Vim script | .vim .vimrc | .vimrc _vimrc init.vim |
| `awk` | awk | .awk .gawk |  |
| `hcl` | HCL / Terraform | .tf .tfvars .hcl .nomad | .terraformrc |
| `protobuf` | Protocol Buffers | .proto |  |
| `graphql` | GraphQL | .graphql .gql .graphqls |  |
| `html` | HTML | .html .htm .xhtml .shtml .jsp .aspx .cshtml .erb .ejs .hbs |  |
| `xml` | XML | .xml .xsd .xsl .xslt .svg .rss .atom .plist .csproj .vbproj |  |
| `vue` | Vue | .vue |  |
| `svelte` | Svelte | .svelte |  |
| `diff` | Diff | .diff .patch .rej |  |
| `gitcommit` | Git commit |  | COMMIT_EDITMSG MERGE_MSG TAG_EDITMSG SQUASH_MSG |
| `gitrebase` | Git rebase todo |  | git-rebase-todo |
| `gitignore` | gitignore | .gitignore | .gitignore .dockerignore .npmignore .eslintignore .prettierignore .gitattributes .helmignore |
| `ini` | INI | .ini .cfg .conf .properties .desktop .service .socket .timer .mount .editorconfig | .editorconfig .gitconfig .npmrc .pylintrc setup.cfg tox.ini .flake8 .env |
| `csv` | CSV | .csv .tsv .psv |  |
| `latex` | LaTeX | .tex .sty .cls .latex .ltx .bib .dtx |  |
| `asm` | Assembly | .s .asm .nasm .masm .inc |  |
| `gomod` | go.mod | .gomod | go.mod go.work go.sum |
| `nginx` | nginx | .nginx | nginx.conf |
| `verilog` | Verilog / SystemVerilog | .v .sv .svh .vh |  |
| `vhdl` | VHDL | .vhd .vhdl |  |
| `objc` | Objective-C | .m .mm |  |
| `matlab` | MATLAB / Octave | .mat .oct |  |
| `fortran` | Fortran | .f .f90 .f95 .f03 .f08 .for .ftn |  |
| `pascal` | Pascal | .pas .pp .lpr .dpr |  |
| `scheme` | Scheme / Lisp | .scm .ss .sld .rkt .lisp .lsp .el .cl .fnl | .emacs |
| `tcl` | Tcl | .tcl .tk |  |
| `crystal` | Crystal | .cr |  |
| `solidity` | Solidity | .sol |  |
| `d` | D | .d .di |  |
| `glsl` | GLSL / HLSL | .glsl .vert .frag .geom .comp .tesc .tese .hlsl .fx .wgsl |  |

`plain` (no classes) is the answer for anything unknown. `tsx` is
`typescript`, `jsx` is `javascript`, `gradle` is `groovy`, `terraform` is
`hcl`, `json5` is `jsonc`.

## How well each one is done

All of them are tokenizers: comments, strings, numbers, keywords, builtin
types and constants, declarations (`def x`, `class X`, `fn x`), calls
(`name(`), and for the data formats keys. None of them parses, so what needs
a grammar is not attempted: a type used before it is declared is a type only
if it is spelled like one (CamelCase), a regex literal is not a string, an
interpolation inside a string is part of the string. docs/ORACLE.md has the
measured agreement with tree-sitter for the languages that have a parser on
the oracle machine.

## What is not there

Everything in the original list is there (verilog and vhdl came in 0.4.0).
Not in the table: ada, cobol, prolog, smalltalk, wasm text, kconfig, gettext
`.po`, and anything else. Shell
heredocs are tracked for `sh`, `php`, `ruby`, `perl` and `hcl`; Ruby's `%w()`
literals, Perl's `qw()`/regex quoting, Lisp reader macros, Haskell's layout and
Lua's `[[ ]]` inside other languages are not.
