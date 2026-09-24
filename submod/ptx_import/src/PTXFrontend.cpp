#include "ptx_mlir/ptx_import/Import/PTXFrontend.h"

#include "mlir/IR/MLIRContext.h"
#include "ptx_mlir/ptx_ir/Dialect/PTX/PTXDialect.h"

namespace ptx_mlir::ptx_import {

ptx_frontend::resolved_ir::checker::CheckResult preflight_resolved_module(
    mlir::MLIRContext& context,
    const ptx_frontend::resolved_ir::ResolvedModule& module,
    ptx_frontend::resolved_ir::ModuleValidationPolicy policy) {
  auto result = ptx_frontend::resolved_ir::validateModule(module, policy);
  if (result)
    context.getOrLoadDialect<ptx::PTXDialect>();
  return result;
}

}  // namespace ptx_mlir::ptx_import
