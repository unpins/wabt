# Changelog

## [Unreleased]

Initial release — `wabt` 1.0.41 as a single self-contained binary, built
natively for Linux, macOS, and Windows.

### Added

- Builds for Linux (x86_64, aarch64, armv7l, i686, ppc64le, riscv64), macOS
  (x86_64, aarch64), and Windows.
- All twelve programs in one binary: `wat2wasm`, `wasm2wat`, `wast2json`,
  `wasm2c`, `wasm-decompile`, `wasm-interp`, `wasm-objdump`, `wasm-stats`,
  `wasm-strip`, `wasm-validate`, `wat-desugar` and `spectest-interp`.
- All twelve man pages embedded in the binary — read one with
  `unpin man wabt <program>`.
