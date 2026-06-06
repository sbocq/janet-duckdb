(import ../src/db)
(import ../src/ffi)
(import ../src/prepare)
(import ../src/result)
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

(deftest "clear-prepared-bindings function"
  (with [db (db/open ":memory:")]
    (with [conn (db/connect db)]
      (with [stmt (db/prepare conn "SELECT ?::INT")]
        # Clear bindings (should not error even with no bindings)
        (test (db/clear-prepared-bindings stmt) 0)))))

#==------------------------------------------------------------------------==#
# bind / bind-named Tests
#==------------------------------------------------------------------------==#

(deftest "bind int parameter"
  (with [db (db/open ":memory:")]
    (with [conn (db/connect db)]
      (with [stmt (db/prepare conn "SELECT ?::INT")]
        (prepare/bind stmt 1 42)
        (with [result (db/execute-prepared stmt)]
          (def cols ((result/fetch-columns result) :columns))
          (test ((cols 0) 0) 42))))))

(deftest "bind string parameter"
  (with [db (db/open ":memory:")]
    (with [conn (db/connect db)]
      (with [stmt (db/prepare conn "SELECT ?::VARCHAR")]
        (prepare/bind stmt 1 "hello")
        (with [result (db/execute-prepared stmt)]
          (def cols ((result/fetch-columns result) :columns))
          (test ((cols 0) 0) "hello"))))))

(deftest "bind boolean parameter"
  (with [db (db/open ":memory:")]
    (with [conn (db/connect db)]
      (with [stmt (db/prepare conn "SELECT ?::BOOLEAN")]
        (prepare/bind stmt 1 true)
        (with [result (db/execute-prepared stmt)]
          (def cols ((result/fetch-columns result) :columns))
          (test ((cols 0) 0) true))))))

(deftest "bind NULL parameter"
  (with [db (db/open ":memory:")]
    (with [conn (db/connect db)]
      (with [stmt (db/prepare conn "SELECT ?::INT IS NULL")]
        (prepare/bind stmt 1 nil)
        (with [result (db/execute-prepared stmt)]
          (def cols ((result/fetch-columns result) :columns))
          (test ((cols 0) 0) true))))))

(deftest "bind multiple parameters"
  (with [db (db/open ":memory:")]
    (with [conn (db/connect db)]
      (with [stmt (db/prepare conn "SELECT ?::INT + ?::INT")]
        (prepare/bind stmt 1 10)
        (prepare/bind stmt 2 32)
        (with [result (db/execute-prepared stmt)]
          (def cols ((result/fetch-columns result) :columns))
          (test ((cols 0) 0) 42))))))

(deftest "bind-named named parameter"
  (with [db (db/open ":memory:")]
    (with [conn (db/connect db)]
      (with [stmt (db/prepare conn "SELECT $1::INT")]
        (prepare/bind-named stmt :1 42)
        (with [result (db/execute-prepared stmt)]
          (def cols ((result/fetch-columns result) :columns))
          (test ((cols 0) 0) 42))))))

(deftest "bind-named with non-existent name errors"
  (with [db (db/open ":memory:")]
    (with [conn (db/connect db)]
      (with [stmt (db/prepare conn "SELECT ?::INT")]
        (test (try (prepare/bind-named stmt "nonexistent" 42) ([_] true)) true)))))

(deftest "bind with out of range index errors"
  (with [db (db/open ":memory:")]
    (with [conn (db/connect db)]
      (with [stmt (db/prepare conn "SELECT ?::INT")]
        (test (try (prepare/bind stmt 5 42) ([_] true)) true)))))

(deftest "bind and execute-prepared round-trip"
  (with [db (db/open ":memory:")]
    (with [conn (db/connect db)]
      (with [stmt (db/prepare conn "SELECT ?::INT, ?::VARCHAR, ?::BOOLEAN")]
        (prepare/bind stmt 1 99)
        (prepare/bind stmt 2 "test")
        (prepare/bind stmt 3 false)
        (with [result (db/execute-prepared stmt)]
          (def cols ((result/fetch-columns result) :columns))
          (test ((cols 0) 0) 99)
          (test ((cols 1) 0) "test")
          (test ((cols 2) 0) false))))))

#==------------------------------------------------------------------------==#
# Complex Type Binding Tests
#==------------------------------------------------------------------------==#

(deftest "bind struct parameter"
  (with [db (db/open ":memory:")]
    (with [conn (db/connect db)]
      (with [r (db/query conn "CREATE TYPE person AS STRUCT(name VARCHAR, age INTEGER)")]
        (with [stmt (db/prepare conn "SELECT ?::person")]
          (prepare/bind stmt 1 {:name "Alice" :age 42})
          (with [result (db/execute-prepared stmt)]
            (def cols ((result/fetch-columns result) :columns))
            (test ((cols 0) 0) {:name "Alice" :age 42})))))))

(deftest "bind list parameter"
  (with [db (db/open ":memory:")]
    (with [conn (db/connect db)]
      (with [stmt (db/prepare conn "SELECT ?::INT[]")]
        (prepare/bind stmt 1 [1 2 3])
        (with [result (db/execute-prepared stmt)]
          (def cols ((result/fetch-columns result) :columns))
          (test ((cols 0) 0) @[1 2 3]))))))

(deftest "bind map parameter"
  (with [db (db/open ":memory:")]
    (with [conn (db/connect db)]
      (with [stmt (db/prepare conn "SELECT ?::MAP(VARCHAR, INT)")]
        (prepare/bind stmt 1 {"a" 1 "b" 2})
        (with [result (db/execute-prepared stmt)]
          (def cols ((result/fetch-columns result) :columns))
          (test ((cols 0) 0) @{"a" 1 "b" 2}))))))

(deftest "bind array parameter"
  (with [db (db/open ":memory:")]
    (with [conn (db/connect db)]
      (with [stmt (db/prepare conn "SELECT ?::INT[3]")]
        (prepare/bind stmt 1 [4 5 6])
        (with [result (db/execute-prepared stmt)]
          (def cols ((result/fetch-columns result) :columns))
          (test ((cols 0) 0) [4 5 6]))))))

(deftest "bind list of structs"
  (with [db (db/open ":memory:")]
    (with [conn (db/connect db)]
      (with [r (db/query conn "CREATE TYPE item AS STRUCT(name VARCHAR, qty INTEGER)")])
      (with [stmt (db/prepare conn "SELECT ?::item[]")]
        (prepare/bind stmt 1 [{:name "foo" :qty 1} {:name "bar" :qty 2}])
        (with [result (db/execute-prepared stmt)]
          (def cols ((result/fetch-columns result) :columns))
          (test ((cols 0) 0) @[{:name "foo" :qty 1} {:name "bar" :qty 2}]))))))

(deftest "bind empty list"
  (with [db (db/open ":memory:")]
    (with [conn (db/connect db)]
      (with [stmt (db/prepare conn "SELECT ?::INT[]")]
        (prepare/bind stmt 1 [])
        (with [result (db/execute-prepared stmt)]
          (def cols ((result/fetch-columns result) :columns))
          (test ((cols 0) 0) @[]))))))

(deftest "bind empty map"
  (with [db (db/open ":memory:")]
    (with [conn (db/connect db)]
      (with [stmt (db/prepare conn "SELECT ?::MAP(VARCHAR, INT)")]
        (prepare/bind stmt 1 {})
        (with [result (db/execute-prepared stmt)]
          (def cols ((result/fetch-columns result) :columns))
          (test ((cols 0) 0) @{}))))))

(deftest "bind union parameter"
  (with [db (db/open ":memory:")]
    (with [conn (db/connect db)]
      (with [r (db/query conn "CREATE TYPE status AS UNION(val INT, msg VARCHAR)")]
        (with [stmt (db/prepare conn "SELECT ?::status")]
          (prepare/bind stmt 1 [:val 42])
          (with [result (db/execute-prepared stmt)]
            (def cols ((result/fetch-columns result) :columns))
            (test ((cols 0) 0) [:val 42])))))))
