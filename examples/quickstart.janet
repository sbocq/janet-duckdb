(import duckdb)

(with [db (duckdb/open)]
  (with [conn (duckdb/connect db)]
    (def row (duckdb/query-first conn "SELECT 'Hello, DuckDB!' AS greeting"))
    (printf "Result: %s" (row :greeting))))
