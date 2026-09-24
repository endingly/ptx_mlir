# ptx_mlir

`ptx_mlir` is an experimental project for bringing NVIDIA PTX into the
[MLIR](https://mlir.llvm.org/) ecosystem. Its intended input is the resolved
semantic IR produced by [ptx_frontend](https://github.com/endingly/ptx_frontend).
The goal is to provide a PTX dialect and an importer that preserve the relevant
instruction and architectural semantics, creating a foundation for analysis,
transformation, and eventual lowering to other representations.

**Status: experimental.** The repository currently contains dependency
pinning, Linux CI presets, and reusable CMake helpers. It does not yet define a
PTX dialect, importer, lowering pipeline, command-line tool, or C++ build
target. A successful build therefore confirms that the toolchain and declared
dependencies can be configured; it does not produce a usable PTX-to-MLIR
converter or establish frontend/MLIR API compatibility.

## Dependencies

The supported development setup currently follows the Ubuntu 26.04 Linux CI
presets. The project uses C++23, CMake 3.28 or newer, GCC, Ninja, Git, Flex,
Python 3 with `pip` and `venv`, and vcpkg in manifest mode.

| Dependency | Source | Purpose |
| --- | --- | --- |
| MLIR and LLVM 21.1.8 | Ubuntu packages `libmlir-21-dev`, `llvm-21-dev`, `mlir-21-tools` | CMake packages, headers, libraries, and MLIR tools |
| `ptx_frontend` | Pinned `ptx-frontend` vcpkg overlay port | PTX parsing and resolved semantic IR |
| `fmt`, `magic-enum`, `gtest` | vcpkg manifest | Planned C++ dependencies and tests |
| `benchmark` | Optional vcpkg `benchmarks` feature | Future benchmarks; no benchmark target exists yet |

APT resolves the runtime dependencies of the three MLIR/LLVM packages. The
checked-in `.ports/mlir/` port is retained for reference but is **not** enabled
by this project's vcpkg manifest. The frontend pin is recorded in
[the overlay portfile](.ports/ptx-frontend/portfile.cmake), while the vcpkg
registry baseline and other packages are declared in [vcpkg.json](vcpkg.json).

## Build on Ubuntu 26.04

Install the system dependencies from the Ubuntu repositories (including the
`universe` component):

```sh
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
  build-essential ccache cmake curl flex git ninja-build pkg-config \
  python3 python3-pip python3-venv tar unzip zip \
  libmlir-21-dev llvm-21-dev mlir-21-tools
```

Set up vcpkg if it is not already available:

```sh
git clone https://github.com/microsoft/vcpkg.git "$HOME/vcpkg"
(cd "$HOME/vcpkg" && ./bootstrap-vcpkg.sh)
export VCPKG_ROOT="$HOME/vcpkg"
```

From the root of this repository, configure and build the Debug preset:

```sh
cmake --preset ci-linux-gcc-debug
cmake --build --preset ci-linux-gcc-debug
ctest --preset ci-linux-gcc-debug
```

For a Release configuration, replace `ci-linux-gcc-debug` with
`ci-linux-gcc-release`. Configuration installs the manifest dependencies through
vcpkg and requires the Ubuntu MLIR/LLVM 21.1.8 CMake packages under
`/usr/lib/llvm-21/lib/cmake/`. The first configure may take several minutes
while vcpkg builds the pinned frontend. The build directories are under
`out/build/`.

There are currently no project build targets or registered tests, so the build
and CTest steps may report no work or no tests. See
[CI and dependency notes](.github/CONTRIBUTING.md) for the current CI workflow
and package details.

## License

This project is licensed under the [MIT License](LICENSE).
