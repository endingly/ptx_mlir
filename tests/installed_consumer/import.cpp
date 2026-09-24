#include "ptx_mlir/ptx_import/Import/PTXFrontend.h"
#include "ptx_mlir/ptx_ir/Dialect/PTX/PTXDialect.h"

#include "mlir/IR/MLIRContext.h"

/** Verify that an installed import client links and calls preflight. */
int main() {
  mlir::MLIRContext context;
  ptx_frontend::resolved_ir::ResolvedModule module;
  module.header.regions.emplace_back();
  const auto result = ptx_mlir::ptx_import::preflight_resolved_module(
      context, module,
      ptx_frontend::resolved_ir::ModuleValidationPolicy::AvailableContext);
  return result && context.getLoadedDialect<ptx_mlir::ptx::PTXDialect>() ? 0
                                                                         : 1;
}
