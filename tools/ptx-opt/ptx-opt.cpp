#include "ptx_mlir/ptx_ir/Dialect/PTX/PTXDialect.h"

#include "mlir/IR/DialectRegistry.h"
#include "mlir/Tools/mlir-opt/MlirOptMain.h"

/** Run the MLIR optimizer with the PTX dialect available to the parser. */
int main(int argc, char** argv) {
  mlir::DialectRegistry registry;
  registry.insert<ptx_mlir::ptx::PTXDialect>();
  return mlir::asMainReturnCode(
      mlir::MlirOptMain(argc, argv, "ptx-opt", registry));
}
