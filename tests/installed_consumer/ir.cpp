#include "ptx_mlir/ptx_ir/Dialect/PTX/PTXDialect.h"

#include "mlir/IR/MLIRContext.h"

/** Verify that the installed IR library provides a loadable PTX dialect. */
int main() {
  mlir::MLIRContext context;
  const auto* dialect = context.getOrLoadDialect<ptx_mlir::ptx::PTXDialect>();
  return dialect && dialect->getNamespace() == "ptx" ? 0 : 1;
}
