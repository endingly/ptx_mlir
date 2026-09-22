# CI workflows and cache ownership

| Workflow | Events | Checks |
| --- | --- | --- |
| `linux-ci.yml` | PR opened/updated/reopened, monthly schedule, manual dispatch | Full GCC Debug and Release build/test presets; check names remain `Debug` and `Release`; formatting job remains `Formatting` |
| `integration-smoke.yml` | Push to `main` or `dev`; manual dispatch | Pushes refresh the normal Debug/Release production caches and retain trusted-main seeds |
| `pr-cache-maintenance.yml` | Completion of `Linux CI`, PR closed | Retains two ccache generations per PR lineage; deletes a closed PR's caches |

Normal Debug/Release coverage remains the regular merge check. No Python or
installed-package workflow exists yet; the reusable build components under
`cmake/` are not yet exercised by any tracked target.

## Formatting and naming

CI runs `clang-format-21 --dry-run --Werror` on tracked handwritten C and C++
sources. Generated and vendor-owned files are excluded: regenerate them through
their owning pipeline instead of formatting them by hand. New C++ interfaces use
`snake_case`. The check is vacuous while no C++ source is tracked, so it must not
be read as evidence that formatting was verified.

## Upstream dependency pinning

`.ports/ptx_frontend` is an overlay port that builds
[ptx_frontend](https://github.com/endingly/ptx_frontend) from a pinned commit.
`vcpkg-configuration.json` registers `.ports` as the overlay so the manifest's
`ptx_frontend` dependency resolves to it rather than to the registry.

The installed tree has two sibling directories under `share/`, and that is
expected rather than a packaging fault:

| Directory | Written by | Contents |
| --- | --- | --- |
| `share/ptx-frontend` | the vcpkg tool | `copyright`, `vcpkg_abi_info.txt`, `vcpkg.spdx.json`, `usage` |
| `share/ptx_frontend` | the upstream install | `ptx_frontendConfig.cmake`, targets, `ptx_spec`, the schema |

vcpkg derives its metadata directory from the port name, so the two merge only
when the port name and the CMake package name are spelled alike — which is why
`share/fmt` and `share/gtest` show a single directory. They cannot be merged
here: vcpkg rejects port names containing underscores ("must be lowercase
alphanumeric+hyphens"), and the CMake package must stay `ptx_frontend`, because
`find_package(ptx_frontend)` globs `share/ptx_frontend*` and would not match a
hyphenated spelling. Leave both directories alone.

`REF` and `SHA512` in the portfile must always describe the same revision, and
`port-version` must increase on every change to the port definition. To move the
pin:

```sh
curl -sSL -o ptx_frontend.tar.gz \
  "https://github.com/endingly/ptx_frontend/archive/<commit>.tar.gz"
sha512sum ptx_frontend.tar.gz
```

Then update `REF`, `SHA512`, and `port-version` together. GitHub's per-commit
archive hashes are stable for a fixed commit but change when the commit changes,
so a stale `SHA512` fails configuration rather than silently building a
different revision.

## Prebuilt MLIR

vcpkg has no `mlir` registry port. The registry's `llvm` port builds LLVM from
source and does not enable the MLIR project, and building LLVM with MLIR costs
hours per cold CI run. `.ports/mlir` therefore installs LLVM's own prebuilt
release instead of compiling anything.

It covers **linux x64 only**, pinned at LLVM `22.1.8`. The release publishes one
archive per platform and architecture, so another target means another asset,
another `SHA512`, and a wider `supports` expression.

### What the release costs

The release is a static build, and it is large:

| | |
| --- | --- |
| download | 1939 MB |
| unpacked | 12.1 GB |
| ... of which `bin/` | 9487 MB across 172 tools |
| ... of which `lib/` | 2432 MB |
| installed by this port | **1.8 GB** |

Four consequences shape the portfile:

- **clang, lld, lldb, flang and the bundled libc++ are excluded.** The release is
  one build of all of them, but `find_package(MLIR)` reaches only
  `lib/cmake/{llvm,mlir}` and the files those name. That was verified against
  `LLVMConfig`, `LLVMExports`, `MLIRConfig` and `MLIRTargets`, which reference
  none of `include/{clang,clang-c,clang-tidy,c++,flang,flang-rt,lld,lldb,mach-o}`,
  `lib/clang`, `lib/lib{clang,lldb,Fortran,Flang,lld}*`, `lib/python3.11`,
  `lib/libscanbuild` or `lib/libear`. `MLIR_LLVM_EXCLUDES` drops them at
  extraction time, which is 1.4 GB of the 3.2 GB an unfiltered install costs.
  **Polly, LTO and Remarks stay** despite looking like separate projects —
  `LLVMExports.cmake` references all three, and dropping them fails
  configuration. `x86_64-unknown-linux-gnu` is excluded even though `LLVMConfig`
  mentions the string, because that is `LLVM_TARGET_TRIPLE`'s value, not a path.

- **There is no `libMLIR.so` and no `libLLVM.so`.** Consumers link the component
  archives in `lib/`, which is the main difference from a distribution package.
  Measured on a consumer that only links `MLIRIR` and `MLIRSupport`, the linker
  pulls in what it needs rather than the whole archive: a 3.3 MB Release binary
  in 3 s, and 5.2 MB Debug in 3 s. Expect that to grow with how much of MLIR a
  target actually uses, but it is not the blanket penalty it first appears to be.
- **`bin/` is cut down.** 172 unstripped static binaries do not fit a CI runner
  twice over, so only the tools in `MLIR_LLVM_TOOLS` are installed. They are
  small except `mlir-opt` (431 MB); the omitted `mlir-rewrite`, `mlir-reduce`,
  `mlir-query` and `mlir-transform-opt` would add about 1.1 GB on their own.
- **`zlib` and `zstd` are dependencies.** The release was built with both
  enabled, and because a static build really does link `LLVMSupport`, its
  interface needs `ZLIB::ZLIB` and `zstd::libzstd_static` to exist before
  `LLVMExports.cmake` is processed — `find_package` alone is not enough. A dylib
  build would not need them, since nothing links `LLVMSupport`.

`tar --wildcards` extracts only the installed paths, so the 9.5 GB of discarded
tool binaries are never written to the buildtree. That is the difference between
a CI runner fitting and not fitting.

### Three edits the portfile makes

- It **prunes CMake's import-check entries** for the tools it does not install.
  `find_package(LLVM)` verifies that every file named by an imported target
  exists and aborts otherwise, so a deliberate subset cannot configure without
  this. The prune is derived from the packages tree rather than a hand-written
  list, so changing `MLIR_LLVM_TOOLS` needs no change to it, and every file that
  *is* installed stays checked.
- It points `MLIR_TABLEGEN_EXE` and `MLIR_PDLL_TABLEGEN_EXE` at this package's
  `bin/`, so tablegen does not have to be found on `PATH`.
- It installs a hand-written `usage` file, because the one vcpkg would generate
  describes the `share/<port>/cmake` layout this port deliberately does not use.
  Keep [.ports/mlir/usage](../.ports/mlir/usage) in step with the portfile.

It does **not** relocate the CMake configs. The release already ships
`lib/cmake/{llvm,mlir}`, which is the layout both configs require: each derives
its install prefix by walking four directories up from its own file and then
expects `include/` and `lib/` beside that prefix. `vcpkg_cmake_config_fixup`
would move them under `share/` and break `find_package`.

### Known gaps

The release ships no `FileCheck`, `not`, `count` or `split-file`: those are built
from `llvm/utils`, which release builds do not enable. A lit-based test suite
therefore cannot be driven from this port alone, so plan on supplying them
another way before adding lit tests.

### Consumers

Include paths come from the config variables; the exported targets deliberately
carry no `INTERFACE_INCLUDE_DIRECTORIES`:

```cmake
find_package(MLIR REQUIRED CONFIG)
include_directories(${MLIR_INCLUDE_DIRS} ${LLVM_INCLUDE_DIRS})
add_definitions(${LLVM_DEFINITIONS})
if(NOT LLVM_ENABLE_RTTI)
  add_compile_options(-fno-rtti)
endif()
```

### Moving the pin

Update `MLIR_LLVM_VERSION`, `MLIR_LLVM_ASSET`, `MLIR_LLVM_ROOT` and `SHA512`
together, bump the port version, and **re-verify `MLIR_LLVM_TOOLS` against the
new archive**. `tar` exits non-zero when a listed member is absent, so a renamed
or dropped tool fails the build rather than being silently skipped.

## Cache reuse and limitations

The workflows share `.github/actions/setup-linux` for system packages and vcpkg
setup. Cache identity includes the installed toolchain, build tools, OS release,
and `ImageOS`, but excludes `ImageVersion`: an image revision alone does not
invalidate caches. vcpkg uses the manifest's exact builtin baseline.

The build jobs set `cache-mode: write` explicitly. Trusted triggers default to
write access and low-trust triggers to read, but `linux-ci.yml` runs on both
`pull_request` and trusted events, so the job states its intent rather than
depending on the trigger that happened to fire. Jobs that only restore or only
delete caches stay on the default.

The vcpkg binary and source-download cache keys hash `.ports/**`, so changing the
overlay port invalidates both. Dependency archives are separate from source
downloads. Only Debug writes shared APT and vcpkg source-download caches.
Installed toolchains can differ within one matrix, so a fixed Debug writer cannot
populate every Release key. Jobs sharing a key may race to save; the cache action
handles duplicate saves without failing the job.

Integration and PR Debug jobs share a compiler-cache namespace; Release has its
own shared namespace. Trusted-main production jobs publish per-run snapshots so
caches can advance after source changes; this does not bypass ccache content
validation.

Prewarming covers the default build graph only while no module targets exist, and
does not promise hits for changed sources or headers, compiler flags, or objects
evicted from the cache. Matching build paths are intentional: ccache normally
hashes the working directory for Debug compilations. See the
[ccache path-hashing contract](https://ccache.dev/manual/latest.html#config_hash_dir).

GitHub allows PRs to restore default/base-branch caches, but PR merge-ref caches
cannot warm the default branch or sibling PRs. Keeping integration-branch cache
writes avoids relying on that impossible direction of reuse. See the
[GitHub cache access rules](https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching#restrictions-for-accessing-a-cache).
New cache-key namespaces initially miss; eviction and runner/toolchain changes
can also cause misses. Cache hits and end-to-end savings require observation on
hosted runs; local validation success alone does not prove them.

Third-party action references are pinned and checked across workflows and local
composite actions.
