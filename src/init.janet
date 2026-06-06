#==----------------------------------------------------------------------------------------------==#
#
# Curated public API for janet-duckdb.
#
# Re-exports all public functions from each sub-module using :export true.
# Raw FFI bindings are excluded — they live in src/ffi.janet and are not imported here.
# Internal helpers marked defn- are also excluded.
#
# Usage:
#   (import duckdb)            # → duckdb/db/query, duckdb/result/fetch-columns, ...
#   (import duckdb/db)         # Direct sub-module access
#   (import duckdb/ffi)        # Raw FFI (advanced)
#
#==----------------------------------------------------------------------------------------------==#

(import ./db :export true)
(import ./result :export true)
(import ./types :export true)
(import ./prepare :export true)
