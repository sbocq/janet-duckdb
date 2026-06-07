# Prepared statement example for janet-duckdb
#
# Run: jpm -l janet examples/prepared.janet

(import duckdb)

(with [db (duckdb/open ":memory:")]
  (with [conn (duckdb/connect db)]

    # Create a table and insert data
    (duckdb/query conn "CREATE TABLE users (id INT, name VARCHAR)")
    (duckdb/query conn "INSERT INTO users VALUES (1, 'Alice'), (2, 'Bob')")

    # Prepared SELECT with positional parameters
    (with [stmt (duckdb/prepare conn "SELECT * FROM users WHERE id = ?")]
      (with [result (duckdb/execute stmt [1])]
        (def row (first (duckdb/columns-to-rows (duckdb/fetch-columns result))))
        (printf "User 1: %n" row)))

    # Prepared SELECT with named parameters
    (with [stmt (duckdb/prepare conn "SELECT * FROM users WHERE name = $n")]
      (with [result (duckdb/execute stmt {:n "Bob"})]
        (def row (first (duckdb/columns-to-rows (duckdb/fetch-columns result))))
        (printf "Bob: %n" row)))))
