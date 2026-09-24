#pragma once

#include <ptx_frontend/resolved_ir/ptx_resolved_ir_resolution.hpp>

namespace mlir {
class MLIRContext;
}

namespace ptx_mlir::ptx_import {

/**
 * Validate owned frontend IR and load the PTX dialect on success.
 *
 * This preflight does not create MLIR operations. Diagnostics are returned
 * unchanged from the pinned frontend's module validator. With
 * ModuleValidationPolicy::AvailableContext, success covers only checks possible
 * from the available source context; it does not establish full instruction
 * validity or that the module can be imported into MLIR.
 */
ptx_frontend::resolved_ir::checker::CheckResult preflight_resolved_module(
    mlir::MLIRContext& context,
    const ptx_frontend::resolved_ir::ResolvedModule& module,
    ptx_frontend::resolved_ir::ModuleValidationPolicy policy = ptx_frontend::
        resolved_ir::ModuleValidationPolicy::RequireCompleteContext);

}  // namespace ptx_mlir::ptx_import
