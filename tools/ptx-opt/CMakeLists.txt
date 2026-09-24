add_executable(ptx-opt ptx-opt.cpp)
target_link_libraries(ptx-opt PRIVATE ptx_mlir::ptx_ir MLIROptLib)
