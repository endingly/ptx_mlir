#pragma once

#include "mlir/IR/Dialect.h"

namespace ptx_mlir::ptx {

/** Registers the PTX namespace; operations, types, and attributes follow later. */
class PTXDialect final : public mlir::Dialect {
 public:
  /** Construct the dialect in the owning MLIR context. */
  explicit PTXDialect(mlir::MLIRContext* context);

  /** Return the stable assembly namespace for PTX IR. */
  static llvm::StringRef getDialectNamespace() { return "ptx"; }
};

}  // namespace ptx_mlir::ptx

MLIR_DECLARE_EXPLICIT_TYPE_ID(ptx_mlir::ptx::PTXDialect)
