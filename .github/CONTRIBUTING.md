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

`.ports/ptx-frontend` is an overlay port that builds
[ptx_frontend](https://github.com/endingly/ptx_frontend) from a pinned commit.
`vcpkg-configuration.json` registers `.ports` as the overlay so the manifest's
`ptx-frontend` dependency resolves to it rather than to the registry.

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

## Ubuntu MLIR 21.1.8

Linux CI uses MLIR/LLVM packages from the Ubuntu 26.04 (`resolute`) archive.
The manifest does not request `mlir` from vcpkg; `.ports/mlir/` remains in the
repository for reference but is inactive in this project's builds. The vcpkg
toolchain still supplies `ptx_frontend`, `fmt`, `magic-enum`, and `gtest`.

The minimal explicit APT development/tool set is:

```sh
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
  libmlir-21-dev llvm-21-dev mlir-21-tools
```

`libmlir-21-dev` supplies MLIR headers, libraries, and `MLIRConfig.cmake`;
`llvm-21-dev` supplies the LLVM development files that config requires;
`mlir-21-tools` supplies `mlir-tblgen` and `mlir-opt`. APT installs their
runtime and development dependencies automatically. On Ubuntu 26.04 amd64,
these three packages currently resolve to `1:21.1.8-6ubuntu1`; CI checks that
each installed version still has upstream version `21.1.8` and fails if the
archive changes it.

The Debug/Release presets set `MLIR_DIR` and `LLVM_DIR` to the configs under
`/usr/lib/llvm-21/lib/cmake/`. The top-level configure calls
`find_package(MLIR 21.1.8 EXACT CONFIG REQUIRED)`, so a missing or mismatched
installation fails immediately. MLIR's Ubuntu config uses LLVM's config from
the same prefix. No module target has been added to the project yet. The Debug
and Release build/test presets currently verify dependency resolution and the
empty project graph, not C++ compatibility between the frontend's resolved IR
and MLIR.

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
