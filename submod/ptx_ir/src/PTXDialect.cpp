#include "ptx_mlir/ptx_ir/Dialect/PTX/PTXDialect.h"

MLIR_DEFINE_EXPLICIT_TYPE_ID(ptx_mlir::ptx::PTXDialect)

namespace ptx_mlir::ptx {

PTXDialect::PTXDialect(mlir::MLIRContext* context)
    : mlir::Dialect(getDialectNamespace(), context,
                    mlir::TypeID::get<PTXDialect>()) {}

}  // namespace ptx_mlir::ptx
