# MLIR has no vcpkg registry port: the registry "llvm" port builds LLVM from
# source and does not enable the MLIR project. A source build of LLVM with MLIR
# costs hours per CI run, so this overlay installs LLVM's own prebuilt release.
#
# Only linux x64 is wired up. The release publishes one archive per platform and
# architecture, so adding another means another asset, another SHA512, and
# widening the `supports` expression in vcpkg.json.
#
# Two properties of the release drive the rest of this file:
#
#   * It is static-only. There is no libMLIR.so and no libLLVM.so, so consumers
#     link the component archives in lib/. Expect large binaries and slow links.
#   * It is unstripped and enormous: unpacked it is 12.1 GB, of which bin/ alone
#     is 9.5 GB across 172 tools. Installing all of it would not fit a CI runner
#     twice over, so bin/ is cut down to the tools a dialect project needs.

# Declared release-only: the archives are a prebuilt release build, not a debug
# variant, so this avoids a phantom debug tree.
set(VCPKG_BUILD_TYPE release)

set(MLIR_LLVM_VERSION "22.1.8")
set(MLIR_LLVM_ASSET "LLVM-${MLIR_LLVM_VERSION}-Linux-X64.tar.xz")
set(MLIR_LLVM_SHA512 "5e6efd6a5d4f355e4c0b4b95ff0d1075b1413e6fdca27884764d8e11b20eb246943bb4809a84dd1e32529ed18aaae8bc08b4d6b22a0a095f6796178f60e9f47e")
set(MLIR_LLVM_ROOT "LLVM-${MLIR_LLVM_VERSION}-Linux-X64")
set(MLIR_LLVM_URL
    "https://github.com/llvm/llvm-project/releases/download/llvmorg-${MLIR_LLVM_VERSION}/${MLIR_LLVM_ASSET}")

# Installed bin/ subset, kept deliberately small: every tool here is a static
# binary, and the wider MLIR toolset is not cheap. mlir-rewrite, mlir-reduce,
# mlir-query and mlir-transform-opt alone would add about 1.1 GB for tools a
# bridge project does not need; add them here if that changes.
#
# The release provides no FileCheck, not, count or split-file, because those come
# from llvm/utils and release builds do not enable utils. lit-based test suites
# therefore cannot be driven from this port alone.
#
# tar exits non-zero if any listed member is absent, so a version bump must
# re-verify this list against the new archive rather than assume it is unchanged.
set(MLIR_LLVM_TOOLS
    mlir-tblgen                 # tablegen for dialect definitions
    mlir-pdll                   # tablegen for PDLL patterns
    llvm-tblgen
    mlir-opt                    # IR round-tripping and lit checking
    mlir-translate
    mlir-runner                 # execution-engine tests
    mlir-cat
    llvm-config
)

vcpkg_download_distfile(
    _archive
    URLS "${MLIR_LLVM_URL}"
    FILENAME "${MLIR_LLVM_ASSET}"
    SHA512 "${MLIR_LLVM_SHA512}"
)

set(_extract_dir "${CURRENT_BUILDTREES_DIR}/src")
file(REMOVE_RECURSE "${_extract_dir}")
file(MAKE_DIRECTORY "${_extract_dir}")

# Extract selectively rather than with vcpkg_extract_source_archive. Unpacking
# the whole archive would write 9.5 GB of tool binaries that are then discarded,
# which is the difference between a CI runner fitting and not fitting.
# The release is a single build of LLVM, clang, lld, lldb, flang, polly and a
# bundled libc++, but find_package(MLIR) reaches only lib/cmake/{llvm,mlir} and
# the files those name. Verified against LLVMConfig, LLVMExports, MLIRConfig and
# MLIRTargets: nothing under clang/, flang/, lld/, lldb/, c++/, the libc++
# runtime directories, lib/clang, python3.11, libscanbuild or libear is
# referenced, so it is excluded at extraction time rather than copied and
# deleted. That is about 1.4 GB of the 3.2 GB an unfiltered install costs.
#
# Polly, LTO and Remarks stay despite looking like separate projects:
# LLVMExports.cmake references all three, and dropping them fails configuration.
# x86_64-unknown-linux-gnu is excluded even though LLVMConfig mentions the
# string, because that is LLVM_TARGET_TRIPLE's value, not a path.
set(MLIR_LLVM_EXCLUDES
    "*/include/clang" "*/include/clang/*"
    "*/include/clang-c" "*/include/clang-c/*"
    "*/include/clang-tidy" "*/include/clang-tidy/*"
    "*/include/c++" "*/include/c++/*"
    "*/include/flang" "*/include/flang/*"
    "*/include/flang-rt" "*/include/flang-rt/*"
    "*/include/lld" "*/include/lld/*"
    "*/include/lldb" "*/include/lldb/*"
    "*/include/mach-o" "*/include/mach-o/*"
    "*/include/x86_64-unknown-linux-gnu" "*/include/x86_64-unknown-linux-gnu/*"
    "*/lib/clang" "*/lib/clang/*"
    "*/lib/libscanbuild" "*/lib/libscanbuild/*"
    "*/lib/libear" "*/lib/libear/*"
    "*/lib/python3.11" "*/lib/python3.11/*"
    "*/lib/x86_64-unknown-linux-gnu" "*/lib/x86_64-unknown-linux-gnu/*"
    "*/lib/cmake/clang" "*/lib/cmake/clang/*"
    "*/lib/cmake/flang" "*/lib/cmake/flang/*"
    "*/lib/cmake/lld" "*/lib/cmake/lld/*"
    "*/lib/libclang*" "*/lib/liblld*" "*/lib/libFortran*" "*/lib/libFlang*"
)

set(_patterns "${MLIR_LLVM_ROOT}/include" "${MLIR_LLVM_ROOT}/lib")
foreach(_tool IN LISTS MLIR_LLVM_TOOLS)
    list(APPEND _patterns "${MLIR_LLVM_ROOT}/bin/${_tool}")
endforeach()
set(_exclude_arguments)
foreach(_pattern IN LISTS MLIR_LLVM_EXCLUDES)
    list(APPEND _exclude_arguments "--exclude=${_pattern}")
endforeach()
vcpkg_execute_required_process(
    COMMAND tar -xJf "${_archive}" -C "${_extract_dir}" --wildcards
            ${_exclude_arguments} ${_patterns}
    WORKING_DIRECTORY "${_extract_dir}"
    LOGNAME "extract-${PORT}"
)

set(_root "${_extract_dir}/${MLIR_LLVM_ROOT}")
foreach(_subdir IN ITEMS include lib)
    if(NOT EXISTS "${_root}/${_subdir}")
        message(FATAL_ERROR
            "${MLIR_LLVM_ASSET} has no ${_subdir} directory; the release layout changed")
    endif()
    file(COPY "${_root}/${_subdir}/"
         DESTINATION "${CURRENT_PACKAGES_DIR}/${_subdir}")
endforeach()
file(MAKE_DIRECTORY "${CURRENT_PACKAGES_DIR}/bin")
foreach(_tool IN LISTS MLIR_LLVM_TOOLS)
    if(EXISTS "${_root}/bin/${_tool}")
        file(COPY "${_root}/bin/${_tool}"
             DESTINATION "${CURRENT_PACKAGES_DIR}/bin")
    endif()
endforeach()

# MLIRConfig.cmake and LLVMConfig.cmake derive their install prefix by walking
# four directories up from their own file and then expect include/ and lib/ to
# be siblings of that prefix. The release already ships lib/cmake/{llvm,mlir} in
# that shape, so they are copied through untouched: relocating them to
# share/<name>/cmake, as vcpkg_cmake_config_fixup would, makes the prefix
# computation walk above the package and breaks find_package.

# CMake verifies that every file named by an imported target exists and aborts
# otherwise. Because bin/ is deliberately a subset, drop exactly the check
# entries whose file was not installed, and leave the rest checked so a genuinely
# broken install still fails loudly. This is derived from the tree rather than a
# hand-maintained list, so changing MLIR_LLVM_TOOLS needs no change here.
file(GLOB _export_files
     "${CURRENT_PACKAGES_DIR}/lib/cmake/llvm/LLVMExports*.cmake"
     "${CURRENT_PACKAGES_DIR}/lib/cmake/mlir/MLIRTargets*.cmake")
# These files contain ';' inside quoted paths (the IMPORTED_OBJECTS lists), and
# a CMake list separates on ';'. Escaping before splitting on newlines is what
# keeps a line with several object files from being torn into fragments, which
# would otherwise leave stray ';' behind and produce an unparseable file.
foreach(_exports IN LISTS _export_files)
    file(READ "${_exports}" _content)
    string(REPLACE ";" "\\;" _escaped "${_content}")
    string(REPLACE "\n" ";" _lines "${_escaped}")
    set(_kept "")
    set(_pruned 0)
    foreach(_line IN LISTS _lines)
        set(_drop FALSE)
        # Only bin/ entries are ever missing: lib/ and include/ are installed
        # whole, and a tool path never contains ';', so this test cannot be
        # confused by the object-library lists.
        if(_line MATCHES "check_files_for_[^ ]+ \".*/bin/([^\"]+)\" \\)")
            if(NOT EXISTS "${CURRENT_PACKAGES_DIR}/bin/${CMAKE_MATCH_1}")
                set(_drop TRUE)
            endif()
        endif()
        if(_drop)
            math(EXPR _pruned "${_pruned} + 1")
        else()
            string(APPEND _kept "${_line}\n")
        endif()
    endforeach()
    if(_pruned GREATER 0)
        string(REPLACE "\\;" ";" _restored "${_kept}")
        file(WRITE "${_exports}" "${_restored}")
        message(STATUS
            "Pruned ${_pruned} import-check entr(ies) for tools this port does "
            "not install from ${_exports}")
    endif()
endforeach()

# LLVM was released with zlib and zstd enabled, and in a static build LLVMSupport
# is actually linked, so its interface needs ZLIB::ZLIB and zstd::libzstd_static
# to exist before LLVMExports.cmake is processed. LLVMConfig.cmake calls
# find_package for both, which is why this port depends on the zlib and zstd
# ports rather than leaving them to the consumer. A dylib build does not need
# this, because nothing links LLVMSupport.

# MLIRConfig.cmake names its tablegen executables as bare commands, which a
# consumer would otherwise have to find on PATH. Point them at this package's
# bin/ instead; MLIR_INSTALL_PREFIX is computed at the top of the same file, so
# the result stays relocatable.
vcpkg_replace_string(
    "${CURRENT_PACKAGES_DIR}/lib/cmake/mlir/MLIRConfig.cmake"
    "set(MLIR_TABLEGEN_EXE \"mlir-tblgen\")"
    "set(MLIR_TABLEGEN_EXE \"\${MLIR_INSTALL_PREFIX}/bin/mlir-tblgen\")"
)
vcpkg_replace_string(
    "${CURRENT_PACKAGES_DIR}/lib/cmake/mlir/MLIRConfig.cmake"
    "set(MLIR_PDLL_TABLEGEN_EXE \"mlir-pdll\")"
    "set(MLIR_PDLL_TABLEGEN_EXE \"\${MLIR_INSTALL_PREFIX}/bin/mlir-pdll\")"
)

# Upstream installs 18 directories that hold nothing (clang-tidy and flang
# CMakeFiles leftovers). A binary cache cannot represent an empty directory, so
# remove them rather than suppress the check. Repeated because a directory that
# contained only empty directories becomes empty itself.
foreach(_pass RANGE 1 6)
    file(GLOB_RECURSE _candidates LIST_DIRECTORIES true
         "${CURRENT_PACKAGES_DIR}/include/*")
    set(_removed 0)
    foreach(_candidate IN LISTS _candidates)
        if(IS_DIRECTORY "${_candidate}")
            file(GLOB _children "${_candidate}/*")
            if(NOT _children)
                file(REMOVE_RECURSE "${_candidate}")
                math(EXPR _removed "${_removed} + 1")
            endif()
        endif()
    endforeach()
    if(_removed EQUAL 0)
        break()
    endif()
endforeach()

# Three post-build checks fire on choices this port makes deliberately, so
# suppress them explicitly rather than leave permanent noise in every CI log.
#
# The first two concern lib/cmake/{llvm,mlir}, which stays where upstream put it:
# both configs compute their install prefix by walking four directories up from
# their own file, so relocating them to share/<name>/cmake would break
# find_package. The third compares installed binaries against the triplet rather
# than this portfile's VCPKG_BUILD_TYPE, and a prebuilt release has no debug
# variant to pair with the release one.
set(VCPKG_POLICY_SKIP_MISPLACED_CMAKE_FILES_CHECK enabled)
set(VCPKG_POLICY_SKIP_LIB_CMAKE_MERGE_CHECK enabled)
set(VCPKG_POLICY_MISMATCHED_NUMBER_OF_BINARIES enabled)

vcpkg_install_copyright(FILE_LIST "${CURRENT_PORT_DIR}/LICENSE")

# vcpkg prints this on install. It is maintained by hand because the port does
# not use vcpkg_cmake_config_fixup, so the generated usage text would not
# describe the layout this port actually installs.
file(INSTALL "${CURRENT_PORT_DIR}/usage"
     DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
