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

      wabtFor = pkgs: scope:
        let
          # Run upstream's own suite wherever the build host can execute what it
          # just built — never under qemu, so the crosses skip it — and only on
          # a 64-bit host. i686 is the one cross an x86_64 box can still
          # execute, and it fails the suite for three reasons that are the
          # platform and not the build: the C that wasm2c emits for `v128` will
          # not compile for baseline i686 (`SSE vector return without SSE
          # enabled changes the ABI`, -Werror=psabi); two of 1822 interpreter
          # cases disagree on NaN payloads because x87 rounds them through 80
          # bits (`0xffe00000` where the spec wants `0xffc00000`); and a couple
          # of golden files bake in a 64-bit offset (`@0x100000001`). The first
          # and third are upstream's tests assuming a 64-bit host; the second is
          # real and belongs in the README, not hidden behind a skipped test.
          doCheck = scope.stdenv.buildPlatform.canExecute scope.stdenv.hostPlatform
            && scope.stdenv.hostPlatform.is64bit;
        in
        scope.wabt.overrideAttrs (old: ({
          inherit doCheck;

          # nixpkgs builds with `-DBUILD_TESTS=OFF`; the suite needs them.
          #
          # `libwasm` (the wasm C API) is `add_library(wasm SHARED …)` —
          # hardcoded, so it ignores BUILD_SHARED_LIBS and a static set still
          # builds a .so. It is a library, not one of the twelve programs;
          # nothing we ship links it, and the shared object is dropped from the
          # artifact anyway. Building it compiles the whole of libwabt a second
          # time, and on i686 the link fails outright (`R_386_PC32 cannot be
          # used against symbol '_start_c'` — the static-PIE musl CRT is not
          # PIC).
          cmakeFlags = builtins.filter (f: f != "-DBUILD_TESTS=OFF") (old.cmakeFlags or [ ])
            ++ [ "-DBUILD_LIBWASM=OFF" "-DBUILD_TESTS=${if doCheck then "ON" else "OFF"}" ];

          # Upstream assumes BUILD_TESTS implies libwasm: the `c_api_example`
          # programs sit inside the BUILD_TESTS block and link the `wasm`
          # target, so with libwasm off they break the default `all` target
          # (`fatal error: 'wasm.h' file not found`) before a single test runs.
          # They exercise only the library we do not build; drop them, and the
          # `run-c-api-tests` target that gathers them goes empty.
          postPatch = (old.postPatch or "") + pkgs.lib.optionalString doCheck ''
            sed -i '/^ *c_api_example(/d' CMakeLists.txt
          '';

          # The driver is a BUILD tool, but `pkgsStatic` is a native set, so a
          # `nativeCheckInputs` python3 would be resolved inside it — and a
          # musl-static python3 fails to configure under the engine's clang
          # (`llvm-ar is required for a --with-lto build`). Take it from the
          # ordinary set; it only has to run here.
          nativeCheckInputs = [ pkgs.python3 ];

        } // pkgs.lib.optionalAttrs doCheck {
          # Upstream's `check` also depends on `run-c-api-tests`, which drives
          # the libwasm we turned off. The other two are the real suite: the
          # gtest unit tests, and the golden-file run over all twelve
          # programs. Spelled out here rather than via `checkTarget` because the
          # second one needs a compiler the CMake target hardcodes.
          #
          # The wasm2c cases compile the C that wasm2c emits and diff the run's
          # stderr against a golden file, so ANY extra line fails them. Built
          # through the engine every object is bitcode, vectorization happens in
          # the linker, and lld prints `loop not vectorized` remarks for the
          # simde headers that output includes — six of them, failing simd_lane
          # and simd_load. Upstream anticipates those remarks and silences them
          # with `-Wno-pass-failed`, but only as a compile flag, which never
          # reaches an LTO link; `-fno-lto` does not help either, since the
          # wrapper appends `-flto` after our flags. Compile that C with the
          # ordinary cc, which is what a user of wasm2c would do: the case under
          # test is wasm2c's output, not our toolchain. CMake bakes
          # `WASM2C_CC=${CMAKE_C_COMPILER}` into the `run-tests` target through
          # `cmake -E env`, which overrides the environment, so the driver is
          # invoked directly instead.
          checkPhase = ''
            runHook preCheck
            make -j''${NIX_BUILD_CORES} run-unittests
            # 120 s per test is the harness default and it is tuned for a fast
            # Linux box: on the Intel Mac the whole suite takes 1209 s against
            # 224 s here, and `wasm2c/spec/simd_const` — which compiles a large
            # generated C file — runs out of it. A build machine's speed is not
            # a property of the code under test.
            ( cd .. && WASM2C_CC=${pkgs.stdenv.cc}/bin/cc \
                python3 test/run-tests.py --bindir build --timeout 600 )
            runHook postCheck
          '';
        }));
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

      build = pkgs: wabtFor pkgs pkgs.pkgsStatic;
      windowsBuild = pkgs: wabtFor pkgs (ulib.mingwStaticCross pkgs);
    };
}
