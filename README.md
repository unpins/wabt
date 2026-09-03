# wabt

The [WebAssembly Binary Toolkit](https://github.com/WebAssembly/wabt) — the
reference programs for translating between the WebAssembly text and binary
formats, and for inspecting, validating and running `.wasm` files. A single
self-contained binary, built natively for Linux, macOS, and Windows.

[![CI](https://github.com/unpins/wabt/actions/workflows/wabt.yml/badge.svg)](https://github.com/unpins/wabt/actions)
![Linux](https://img.shields.io/badge/Linux-✓-success?logo=linux&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-✓-success?logo=apple&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-✓-success?logo=windows&logoColor=white)

Part of the [unpins](https://unpins.org) catalog; install it with [`unpin`](https://github.com/unpins/unpin): `unpin install wabt`.

## Usage

Run one of the programs with [unpin](https://github.com/unpins/unpin):

```bash
unpin wabt --unpin-program=wat2wasm module.wat -o module.wasm   # text -> binary
unpin wabt --unpin-program=wasm2wat module.wasm                 # binary -> text
unpin wabt --unpin-program=wasm-validate module.wasm            # check against the spec
unpin wabt --unpin-program=wasm-objdump -x module.wasm          # sections, imports, exports
```

`wabt` is the name of the collection, not of a program, so running it on its own
lists what is inside instead of picking one for you.

To put every command — `wat2wasm`, `wasm2wat`, `wasm-objdump`, `wasm-decompile`
and the eight others — onto your PATH:

```bash
unpin install wabt
wat2wasm module.wat -o module.wasm
```

`unpin info wabt` lists them all.

## Programs

| command | what it does |
| --- | --- |
| `wat2wasm` | assemble WebAssembly text (`.wat`) into a binary module |
| `wasm2wat` | disassemble a binary module back to text |
| `wast2json` | assemble a spec test script into `.wasm` files plus a JSON manifest |
| `wasm2c` | translate a binary module into C source you can compile and link |
| `wasm-decompile` | render a module as readable C-like pseudocode |
| `wasm-interp` | run a module in a stack-based interpreter |
| `wasm-objdump` | print sections, imports, exports and disassembly, like `objdump` |
| `wasm-stats` | report opcode and section statistics for a module |
| `wasm-strip` | remove custom sections (names, debug info) from a module |
| `wasm-validate` | validate a binary module against the spec |
| `wat-desugar` | rewrite folded/mixed `.wat` syntax into canonical flat form |
| `spectest-interp` | run a `wast2json` spec test manifest |

## Man pages

Each program's man page is embedded — read one with
`unpin man wabt <program>` (e.g. `unpin man wabt wat2wasm`).

## Build locally

```bash
nix build github:unpins/wabt
./result/bin/wabt --unpin-program=wat2wasm --version
```

Or run directly:

```bash
nix run github:unpins/wabt -- --unpin-program=wat2wasm --version
```

A plain `./result/bin/wabt` prints the list of programs it holds.

The first invocation will offer to add the [unpins.cachix.org](https://unpins.cachix.org) substituter so most pulls come pre-built.

## Manual download

The [Releases](https://github.com/unpins/wabt/releases) page has standalone binaries for manual download.

## Build notes

- All twelve programs live in one binary and share the single copy of libwabt
  they all link. `wabt` itself is not one of them: run bare, it lists what it
  carries.
- **Windows** is built with mingw: wabt is portable C++17 with no external
  dependency, so it cross-compiles as-is.
