find_package(ptx_frontend CONFIG REQUIRED)

add_library(ptx_import STATIC src/PTXFrontend.cpp)
add_library(ptx_mlir::ptx_import ALIAS ptx_import)

include(register_headers)
register_headers(TARGET ptx_import MODULE_NAME ptx_import
    PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/include")

target_link_libraries(ptx_import PUBLIC ptx_mlir::ptx_ir ptx_frontend::resolved_ir)
set_target_properties(ptx_import PROPERTIES EXPORT_NAME ptx_import)
