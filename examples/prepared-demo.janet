(import duckdb)

(with [db (duckdb/open ":memory:")]

  (with [conn (duckdb/connect db)]
    (duckdb/query conn "CREATE TABLE items (id INT, name VARCHAR, price DOUBLE)")
    (duckdb/query conn "INSERT INTO items VALUES (1, 'Widget', 9.99), (2, 'Gadget', 24.95)")

    (with [stmt (duckdb/prepare conn "SELECT * FROM items WHERE id = ?")]
      (def row (first (duckdb/columns-to-rows (duckdb/fetch-columns (duckdb/execute stmt [1])))))
      (printf "Item 1: id=%d name=%s price=%.2f" (row :id) (row :name) (row :price)))

    (with [stmt (duckdb/prepare conn "SELECT * FROM items WHERE price > ?")]
      (def row (first (duckdb/columns-to-rows (duckdb/fetch-columns (duckdb/execute stmt [10])))))
      (printf "Expensive: id=%d name=%s price=%.2f" (row :id) (row :name) (row :price)))))
