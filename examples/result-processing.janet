(import duckdb)

(with [db (duckdb/db/open)]
  (with [conn (duckdb/db/connect db)]
    (with [result (duckdb/db/query conn "SELECT 1 AS a, 'hello' AS b, 3.14 AS c")]
      (def rows (duckdb/result/columns-to-rows (duckdb/result/fetch-columns result)))
      (pp (first rows)))))
