cmake_minimum_required(VERSION 3.28.0)
list(PREPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

# Select optional manifest dependencies before project() loads the vcpkg toolchain.
option(PTX_MLIR_BUILD_BENCHMARKS "Build PTX-to-MLIR bridge benchmarks" OFF)
if(PTX_MLIR_BUILD_BENCHMARKS)
    list(APPEND VCPKG_MANIFEST_FEATURES benchmarks)
    list(REMOVE_DUPLICATES VCPKG_MANIFEST_FEATURES)
endif()

project(ptx_mlir VERSION 0.0.1 LANGUAGES C CXX)

# CI presets select the Ubuntu LLVM/MLIR 21 installation alongside the vcpkg
# toolchain used for ptx_frontend and the other C++ dependencies.
find_package(MLIR 21.1.8 EXACT CONFIG REQUIRED)

include(GNUInstallDirs)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS ON)
set(CMAKE_CXX_SCAN_FOR_MODULES OFF)

option(PTX_USE_CCACHE "Use ccache to speed up compilation" ON)
option(BUILD_TESTING "enable test program building" OFF)

if(PTX_USE_CCACHE)
    find_program(CCACHE_EXECUTABLE ccache)
    if(CCACHE_EXECUTABLE)
        set(CMAKE_C_COMPILER_LAUNCHER ${CCACHE_EXECUTABLE})
        set(CMAKE_CXX_COMPILER_LAUNCHER ${CCACHE_EXECUTABLE})
    else()
        message(WARNING "PTX_USE_CCACHE is ON, but ccache was not found")
    endif()
endif()

if(BUILD_TESTING)
    include(CTest)
    enable_testing()
    include(GoogleTest)
endif()

# ptx_frontend is supplied by the "ptx-frontend" overlay port in .ports/ and is
# available to module targets as:
#
#     find_package(ptx_frontend CONFIG REQUIRED)
#     target_link_libraries(<target> PRIVATE ptx_frontend::resolved_ir)
#
# No module targets are defined yet. Reusable build components live in cmake/:
#
#   register_headers()         module include-root layout for module targets
#   install_project_targets()  relocatable install/export of the package
#
# When the first module lands under submod/<module>/, add
#
#     add_subdirectory(submod)
#
# next to this comment and call install_project_targets() with the module
# targets, components, and include destinations.
