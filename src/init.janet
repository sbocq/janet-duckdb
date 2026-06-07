#==----------------------------------------------------------------------------------------------==#
#
# Curated public API for janet-duckdb.
#
# db, result, and prepare are merged flat using :prefix "".
# This means (import duckdb) gives you duckdb/query instead of duckdb/db/query.
#
# types and ffi are NOT flattened — they remain behind submodule access for advanced users.
#
# Usage:
#   (import duckdb)            # → duckdb/query, duckdb/fetch-columns, duckdb/bind, ...
#   (import duckdb/types)      # Full types module (advanced)
#   (import duckdb/ffi)        # Raw FFI (advanced)
#
# Submodule access still works:
#   (import duckdb/db)         # → duckdb/db/query, duckdb/db/open
#
#==----------------------------------------------------------------------------------------------==#

(import ./db :prefix "" :export true)
(import ./result :prefix "" :export true)
(import ./prepare :prefix "" :export true)
