# Prepared statement example for janet-duckdb
#
# Run: jpm -l janet examples/prepared.janet

(import duckdb)

(with [db (duckdb/db/open ":memory:")]
  (with [conn (duckdb/db/connect db)]

    # Create a table and insert data
    (duckdb/db/query conn "CREATE TABLE users (id INT, name VARCHAR)")
    (duckdb/db/query conn "INSERT INTO users VALUES (1, 'Alice'), (2, 'Bob')")

    # Prepared SELECT with positional parameters
    (with [stmt (duckdb/prepare/prepare conn "SELECT * FROM users WHERE id = ?")]
      (with [result (duckdb/prepare/execute stmt [1])]
        (def row (first (duckdb/result/columns-to-rows (duckdb/result/fetch-columns result))))
        (printf "User 1: %n" row)))

    # Prepared SELECT with named parameters
    (with [stmt (duckdb/prepare/prepare conn "SELECT * FROM users WHERE name = $n")]
      (with [result (duckdb/prepare/execute stmt {:n "Bob"})]
        (def row (first (duckdb/result/columns-to-rows (duckdb/result/fetch-columns result))))
        (printf "Bob: %n" row)))))
