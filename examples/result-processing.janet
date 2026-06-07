(import duckdb)

(with [db (duckdb/open)]
  (with [conn (duckdb/connect db)]
    (with [result (duckdb/query conn "SELECT 1 AS a, 'hello' AS b, 3.14 AS c")]
      (def rows (duckdb/columns-to-rows (duckdb/fetch-columns result)))
      (pp (first rows)))))
