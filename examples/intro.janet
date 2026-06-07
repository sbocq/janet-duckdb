# janet-duckdb introductory example
#
# Run: jpm -l janet examples/intro.janet

(import duckdb)
(use judge)

#==------------------------------------------------------------------------==#
# Database lifecycle
#==------------------------------------------------------------------------==#

(with [db (duckdb/open ":memory:")]
  (with [conn (duckdb/connect db)]

    #==--------------------------------------------------------------------==#
    # Convenience functions — manage results internally
    #==--------------------------------------------------------------------==#

    (duckdb/execute-sql conn "CREATE TABLE items (id INT, name VARCHAR, price DOUBLE)")
    (duckdb/execute-sql conn "INSERT INTO items VALUES (1, 'Widget', 9.99), (2, 'Gadget', 24.95)")

    (def rows (duckdb/query-rows conn "SELECT * FROM items"))
    (test rows @[{:id 1 :name "Widget" :price 9.99} {:id 2 :name "Gadget" :price 24.95}])

    (def row (duckdb/query-first conn "SELECT * FROM items WHERE id = 1"))
    (test row {:id 1 :name "Widget" :price 9.99})

    #==--------------------------------------------------------------------==#
    # Parameterized queries — uses prepared statements internally
    #==--------------------------------------------------------------------==#

    (def row (duckdb/query-first conn "SELECT * FROM items WHERE id = ?" [1]))
    (test row {:id 1 :name "Widget" :price 9.99})

    (def row (duckdb/query-first conn "SELECT * FROM items WHERE name = ?" ["Gadget"]))
    (test row {:id 2 :name "Gadget" :price 24.95})

    (def row (duckdb/query-first conn "SELECT * FROM items WHERE name = $name" {:name "Gadget"}))
    (test row {:id 2 :name "Gadget" :price 24.95})

    (def rows-changed (duckdb/execute-sql conn "INSERT INTO items VALUES (?, ?, ?)"
                                          [3 "NewItem" 5.00]))
    (test rows-changed 1)

    (def rows (duckdb/query-rows conn "SELECT * FROM items WHERE price > $min" {:min 10}))
    (test rows @[{:id 2 :name "Gadget" :price 24.95}])

    #==--------------------------------------------------------------------==#
    # Low-level result access
    #==--------------------------------------------------------------------==#

    (with [result (duckdb/query conn "SELECT name, price FROM items ORDER BY id")]
      (test (duckdb/return-type result) :query-result)
      (test (duckdb/statement-type result) :select)

      (def cols (duckdb/fetch-columns result))
      (def rows (duckdb/columns-to-rows cols))
      (test rows @[{:name "Widget" :price 9.99}
                   {:name "Gadget" :price 24.95}
                   {:name "NewItem" :price 5}]))))
