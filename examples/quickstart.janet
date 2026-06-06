(import duckdb)

(with [db (duckdb/db/open)]
  (with [conn (duckdb/db/connect db)]
    (with [result (duckdb/db/query conn "SELECT 'Hello, DuckDB!' AS greeting")]

      (def row (first (duckdb/result/columns-to-rows (duckdb/result/fetch-columns result))))
      (printf "Result: %s" (row :greeting)))))
