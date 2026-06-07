(import duckdb)

(with [db (duckdb/db/open ":memory:")]

  (with [conn (duckdb/db/connect db)]
    (duckdb/db/query conn "CREATE TABLE items (id INT, name VARCHAR, price DOUBLE)")
    (duckdb/db/query conn "INSERT INTO items VALUES (1, 'Widget', 9.99), (2, 'Gadget', 24.95)")

    (with [stmt (duckdb/prepare/prepare conn "SELECT * FROM items WHERE id = ?")]
      (def row (first (duckdb/result/columns-to-rows (duckdb/result/fetch-columns (duckdb/prepare/execute stmt [1])))))
      (printf "Item 1: id=%d name=%s price=%.2f" (row :id) (row :name) (row :price)))

    (with [stmt (duckdb/prepare/prepare conn "SELECT * FROM items WHERE price > ?")]
      (def row (first (duckdb/result/columns-to-rows (duckdb/result/fetch-columns (duckdb/prepare/execute stmt [10])))))
      (printf "Expensive: id=%d name=%s price=%.2f" (row :id) (row :name) (row :price)))))
