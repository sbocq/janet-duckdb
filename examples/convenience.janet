# Convenience functions example for janet-duckdb
#
# Run: jpm -l janet examples/convenience.janet

(import duckdb)

(with [db (duckdb/open ":memory:")]
  (with [conn (duckdb/connect db)]

    (duckdb/execute-sql conn "CREATE TABLE items (id INT, name VARCHAR, price DOUBLE)")
    (duckdb/execute-sql conn "INSERT INTO items VALUES (1, 'Widget', 9.99), (2, 'Gadget', 24.95)")

    (def rows (duckdb/query-rows conn "SELECT * FROM items"))
    (printf "All items: %n" rows)

    (def row (duckdb/query-first conn "SELECT * FROM items WHERE id = 1"))
    (printf "First item: %n" row)

    (printf "Updated %d rows" (duckdb/execute-sql conn "UPDATE items SET price = 19.99 WHERE id = 2"))))
