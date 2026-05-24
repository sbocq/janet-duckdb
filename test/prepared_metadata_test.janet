(import ../src/db)
(import ../src/ffi)
(import ../src/types)
(use judge)

#==------------------------------------------------------------------------==#
# Prepared Statement Metadata Tests
#==------------------------------------------------------------------------==#

(deftest-type prepared-metadata-db
  :setup (fn []
           (def db (db/open ":memory:"))
           (def conn (db/connect db))
           [db conn])
  :teardown (fn [[db conn]]
              (:close conn)
              (:close db)))

(deftest "prepared statement object has cached metadata"
  (with [db (db/open ":memory:")]
    (with [conn (db/connect db)]
      (with [stmt (db/prepare conn "SELECT ?::INT, ?::VARCHAR")]

        # Check that cached metadata exists
        (test (stmt :param-count) 2)
        (test (length (stmt :param-names)) 2)
        (test (length (stmt :param-types)) 2)

        # Check parameter names (DuckDB uses ? for unnamed parameters)
        (test ((stmt :param-names) 0) :1)
        (test ((stmt :param-names) 1) :2)

        # Check parameter types
        (test ((stmt :param-types) 0) :int)
        (test ((stmt :param-types) 1) :varchar)))))


(deftest "describe-prepared with complex types"
  (with [db (db/open ":memory:")]
    (with [conn (db/connect db)]
      # Create a struct type first
      (with [result (db/query conn "CREATE TYPE person AS STRUCT(name VARCHAR, age INTEGER)")])

      (with [stmt (db/prepare conn "SELECT ?::person")]

        (test (stmt :param-count) 1)

        # Check parameter names (DuckDB uses ? for unnamed parameters)
        (test ((stmt :param-names) 0) :1)

        # Check parameter types
        (test ((stmt :param-types) 0)
          [:struct
           {:key-types [:varchar :int]
            :keys [:name :age]}])))))

(deftest "prepared-clear-bindings function"
  (with [db (db/open ":memory:")]
    (with [conn (db/connect db)]
      (with [stmt (db/prepare conn "SELECT ?::INT")]
        # Clear bindings (should not error even with no bindings)
        (test (db/prepared-clear-bindings stmt) 0)))))
