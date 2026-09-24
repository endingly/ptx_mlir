cmake_minimum_required(VERSION 3.28)
project(ptx_mlir_installed_consumer LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(ptx_mlir CONFIG REQUIRED COMPONENTS ${PTX_CONSUMER_COMPONENT})

if(PTX_CONSUMER_COMPONENT STREQUAL "ptx_ir")
    if(TARGET ptx_frontend::resolved_ir)
        message(FATAL_ERROR "IR-only component loaded the frontend")
    endif()
    add_executable(consumer ir.cpp)
else()
    add_executable(consumer import.cpp)
endif()
target_link_libraries(consumer PRIVATE ptx_mlir::${PTX_CONSUMER_COMPONENT})
