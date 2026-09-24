get_target_property(_ir_links ptx_ir INTERFACE_LINK_LIBRARIES)
get_target_property(_ir_build_links ptx_ir LINK_LIBRARIES)
get_target_property(_import_links ptx_import INTERFACE_LINK_LIBRARIES)
get_target_property(_opt_links ptx-opt LINK_LIBRARIES)

list(FIND _ir_links MLIRIR _ir_mlir_index)
if(_ir_mlir_index EQUAL -1)
    message(FATAL_ERROR "ptx_ir must expose its MLIR IR dependency")
endif()
foreach(_ir_link IN LISTS _ir_links _ir_build_links)
    string(TOLOWER "${_ir_link}" _ir_link_lower)
    if(_ir_link_lower MATCHES "frontend|ptx_import|parser|optlib|transform|conversion|_to_" OR
       _ir_link MATCHES "MLIR[A-Za-z0-9]*To[A-Z]")
        message(FATAL_ERROR "ptx_ir has a forbidden dependency: ${_ir_link}")
    endif()
endforeach()

list(FIND _import_links ptx_mlir::ptx_ir _import_ir_index)
list(FIND _import_links ptx_frontend::resolved_ir _import_frontend_index)
if(_import_ir_index EQUAL -1 OR _import_frontend_index EQUAL -1)
    message(FATAL_ERROR
        "ptx_import must publicly link ptx_ir and pinned resolved_ir")
endif()

list(FIND _opt_links ptx_mlir::ptx_ir _opt_ir_index)
list(FIND _opt_links MLIROptLib _opt_mlir_index)
if(_opt_ir_index EQUAL -1 OR _opt_mlir_index EQUAL -1)
    message(FATAL_ERROR "ptx-opt must link ptx_ir and MLIROptLib")
endif()
foreach(_opt_link IN LISTS _opt_links)
    string(TOLOWER "${_opt_link}" _opt_link_lower)
    if(_opt_link_lower MATCHES "ptx_import|ptx_frontend")
        message(FATAL_ERROR "ptx-opt must not link the frontend adapter")
    endif()
endforeach()

add_executable(ptx_boundary_smoke boundary_smoke.cpp)
target_link_libraries(ptx_boundary_smoke PRIVATE ptx_mlir::ptx_import)
add_test(NAME ptx_boundary_smoke COMMAND ptx_boundary_smoke)

add_test(NAME ptx_opt_help COMMAND ptx-opt --help)
add_test(NAME ptx_opt_empty_module
    COMMAND ptx-opt "${CMAKE_CURRENT_SOURCE_DIR}/empty.mlir")

add_test(NAME installed_consumers
    COMMAND "${CMAKE_COMMAND}"
        "-DPTX_BUILD_DIR=${PROJECT_BINARY_DIR}"
        "-DPTX_SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}/installed_consumer"
        "-DPTX_TEST_DIR=${PROJECT_BINARY_DIR}/installed_consumer_test"
        "-DPTX_MLIR_DIR=${MLIR_DIR}"
        "-DPTX_LLVM_DIR=${LLVM_DIR}"
        "-DPTX_VCPKG_PREFIX=${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}"
        "-DPTX_CXX_COMPILER=${CMAKE_CXX_COMPILER}"
        -P "${CMAKE_CURRENT_SOURCE_DIR}/installed_consumer_test.cmake")
