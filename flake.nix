{
  description = "the WebAssembly Binary Toolkit (wabt) programs as a single self-contained binary";

  nixConfig = {
    extra-substituters = [ "https://unpins.cachix.org" ];
    extra-trusted-public-keys = [ "unpins.cachix.org-1:DDaShjbZ8VvcqxeTcAU3kV9vxZQBlyb7V/uLBHfTynI=" ];
  };

  inputs.unpins-lib.url = "github:unpins/nix-lib";

  # wabt ships twelve executables (wat2wasm, wasm2wat, wasm-objdump, …) and no
  # flagship among them, so the dispatcher carries the package name and a bare
  # `wabt` lists — the naming rule, not a `defaultProgram`.
  #
  # Upstream publishes release tarballs for Linux/macOS/Windows, but they are
  # dynamically linked against the build host's glibc and libstdc++ (measured on
  # 1.0.41: wat2wasm needs libstdc++.so.6, libc.so.6, libm.so.6, libgcc_s.so.1),
  # so they are not the portable single binaries `unpin install <owner>/<repo>`
  # is for.
  #
  # Plain portable C++17 CMake with no external dependency, so every target
  # builds from the same expression. Upstream's own submodules are all test- or
  # opt-in-only for the tools build.
  outputs = { self, unpins-lib }:
    let
      ulib = unpins-lib.lib;

      wabtFor = scope: scope.wabt.overrideAttrs (old: {
        # `libwasm` (the wasm C API) is `add_library(wasm SHARED …)` — hardcoded,
        # so it ignores BUILD_SHARED_LIBS and a static set still builds a .so. It
        # is a library, not one of the twelve programs; nothing we ship links it,
        # and the shared object is dropped from the artifact anyway. Building it
        # compiles the whole of libwabt a second time, and on i686 the link fails
        # outright (`R_386_PC32 cannot be used against symbol '_start_c'` — the
        # static-PIE musl CRT is not PIC).
        cmakeFlags = (old.cmakeFlags or [ ]) ++ [ "-DBUILD_LIBWASM=OFF" ];
      });
    in
    ulib.mkStandaloneFlake {
      inherit self;
      name = "wabt";

      # Multicall: no applet is named `wabt`, so CI smokes through the explicit
      # selector on the canonical binary.
      smoke = [ "--unpin-program=wat2wasm" "--version" ];
      smokePattern = "^1\\.0\\.";

      engine = "unpin-llvm";
      multicall = {
        windows = true;
        programs = [
          { name = "wat2wasm"; }
          { name = "wasm2wat"; }
          { name = "wast2json"; }
          { name = "wasm2c"; }
          { name = "wasm-decompile"; }
          { name = "wasm-interp"; }
          { name = "wasm-objdump"; }
          { name = "wasm-stats"; }
          { name = "wasm-strip"; }
          { name = "wasm-validate"; }
          { name = "wat-desugar"; }
          { name = "spectest-interp"; }
        ];
        # C++17 throughout; requires.cxx folds libc++ into the multicall link.
        requires.cxx = true;
      };

      build = pkgs: wabtFor pkgs.pkgsStatic;
      windowsBuild = pkgs: wabtFor (ulib.mingwStaticCross pkgs);
    };
}
