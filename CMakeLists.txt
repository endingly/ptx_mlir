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

add_subdirectory(submod)
add_subdirectory(tools/ptx-opt)

if(BUILD_TESTING)
    add_subdirectory(tests)
endif()

include(install_project_targets)
install_project_targets(
    PROJECT ptx_mlir
    VERSION ${PROJECT_VERSION}
    NAMESPACE ptx_mlir
    TARGETS ptx_ir ptx_import
    COMPONENTS ptx_ir ptx_import
    INCLUDE_DIRS
        "${CMAKE_CURRENT_SOURCE_DIR}/submod/ptx_ir/include"
        "${CMAKE_CURRENT_SOURCE_DIR}/submod/ptx_import/include"
    INCLUDE_DESTINATIONS
        "${CMAKE_INSTALL_INCLUDEDIR}/ptx_mlir/ptx_ir"
        "${CMAKE_INSTALL_INCLUDEDIR}/ptx_mlir/ptx_import"
    DEPENDENCIES "MLIR 21.1.8 EXACT CONFIG"
)
