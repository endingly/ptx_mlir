# Configure, build, and run external clients against an installed package.
# PTX_BUILD_DIR is the built project, PTX_SOURCE_DIR contains the clients,
# PTX_TEST_DIR is disposable output, and the remaining PTX_* values locate
# the compiler and external package dependencies used by the parent build.

set(_prefix "${PTX_TEST_DIR}/prefix")
execute_process(
    COMMAND "${CMAKE_COMMAND}" --install "${PTX_BUILD_DIR}" --prefix "${_prefix}"
    RESULT_VARIABLE _result
    OUTPUT_VARIABLE _output
    ERROR_VARIABLE _error)
if(NOT _result EQUAL 0)
    message(FATAL_ERROR "Package installation failed:\n${_output}${_error}")
endif()

foreach(_component IN ITEMS ptx_ir ptx_import)
    set(_build "${PTX_TEST_DIR}/${_component}")
    set(_configure_args
        -S "${PTX_SOURCE_DIR}"
        -B "${_build}"
        "-DPTX_CONSUMER_COMPONENT=${_component}"
        "-Dptx_mlir_DIR=${_prefix}/lib/cmake/ptx_mlir"
        "-DMLIR_DIR=${PTX_MLIR_DIR}"
        "-DLLVM_DIR=${PTX_LLVM_DIR}"
        "-DCMAKE_CXX_COMPILER=${PTX_CXX_COMPILER}")
    if(_component STREQUAL "ptx_ir")
        list(APPEND _configure_args
            -DCMAKE_DISABLE_FIND_PACKAGE_ptx_frontend=TRUE)
    else()
        list(APPEND _configure_args
            "-DCMAKE_PREFIX_PATH=${PTX_VCPKG_PREFIX}")
    endif()
    execute_process(
        COMMAND "${CMAKE_COMMAND}" ${_configure_args}
        RESULT_VARIABLE _result
        OUTPUT_VARIABLE _output
        ERROR_VARIABLE _error)
    if(NOT _result EQUAL 0)
        message(FATAL_ERROR "${_component} configure failed:\n${_output}${_error}")
    endif()
    execute_process(
        COMMAND "${CMAKE_COMMAND}" --build "${_build}"
        RESULT_VARIABLE _result
        OUTPUT_VARIABLE _output
        ERROR_VARIABLE _error)
    if(NOT _result EQUAL 0)
        message(FATAL_ERROR "${_component} build failed:\n${_output}${_error}")
    endif()
    execute_process(
        COMMAND "${_build}/consumer"
        RESULT_VARIABLE _result
        OUTPUT_VARIABLE _output
        ERROR_VARIABLE _error)
    if(NOT _result EQUAL 0)
        message(FATAL_ERROR "${_component} run failed:\n${_output}${_error}")
    endif()
endforeach()
