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
