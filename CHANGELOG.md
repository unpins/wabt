# Changelog

## [Unreleased]

## [1.0.41-1] - 2026-09-26

Initial release — `wabt` 1.0.41 as a single self-contained binary, built
natively for Linux, macOS, and Windows.

### Fixed

- On Windows, `wat2wasm module.wat -o -` wrote a corrupted module: every line
  feed in the binary became a carriage return plus a line feed. Reading a module
  from standard input (`wasm2wat -`) was broken the same way in reverse, and
  reported `invalid section size` on a perfectly good file. Named files were
  always fine.
- On Windows, text output now uses line feeds, matching every other platform
  and upstream's own Windows build.

### Added

- Builds for Linux (x86_64, aarch64, armv7l, i686, ppc64le, riscv64), macOS
  (x86_64, aarch64), and Windows.
- All twelve programs in one binary: `wat2wasm`, `wasm2wat`, `wast2json`,
  `wasm2c`, `wasm-decompile`, `wasm-interp`, `wasm-objdump`, `wasm-stats`,
  `wasm-strip`, `wasm-validate`, `wat-desugar` and `spectest-interp`.
- All twelve man pages embedded in the binary — read one with
  `unpin man wabt <program>`.
- Upstream's test suite runs during the build on the 64-bit platforms that can
  execute what they built. It is skipped on 32-bit x86, where NaN results carry
  a different bit pattern because floats go through the x87 stack.
