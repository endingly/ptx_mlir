add_library(ptx_ir STATIC src/PTXDialect.cpp)
add_library(ptx_mlir::ptx_ir ALIAS ptx_ir)

include(register_headers)
register_headers(TARGET ptx_ir MODULE_NAME ptx_ir
    PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/include")

target_include_directories(ptx_ir SYSTEM PUBLIC
    $<BUILD_INTERFACE:${MLIR_INCLUDE_DIRS}>)
target_link_libraries(ptx_ir PUBLIC MLIRIR)
set_target_properties(ptx_ir PROPERTIES EXPORT_NAME ptx_ir)
