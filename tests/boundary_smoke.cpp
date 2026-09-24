#include "ptx_mlir/ptx_import/Import/PTXFrontend.h"
#include "ptx_mlir/ptx_ir/Dialect/PTX/PTXDialect.h"

#include "mlir/IR/MLIRContext.h"

/** Check that validation gates dialect loading and preserves diagnostics. */
int main() {
  mlir::MLIRContext context;
  ptx_frontend::resolved_ir::ResolvedModule module;
  if (context.getLoadedDialect<ptx_mlir::ptx::PTXDialect>())
    return 1;

  const auto invalid =
      ptx_mlir::ptx_import::preflight_resolved_module(context, module);
  const auto expected = ptx_frontend::resolved_ir::validateModule(module);
  if (invalid || invalid.error().empty() ||
      context.getLoadedDialect<ptx_mlir::ptx::PTXDialect>())
    return 2;
  if (expected || invalid.error().size() != expected.error().size() ||
      invalid.error().front().kind != expected.error().front().kind ||
      invalid.error().front().message != expected.error().front().message)
    return 4;

  module.header.regions.emplace_back();
  const auto valid = ptx_mlir::ptx_import::preflight_resolved_module(
      context, module,
      ptx_frontend::resolved_ir::ModuleValidationPolicy::AvailableContext);
  if (!valid || !context.getLoadedDialect<ptx_mlir::ptx::PTXDialect>())
    return 3;

  return 0;
}
