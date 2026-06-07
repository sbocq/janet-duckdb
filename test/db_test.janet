# Tests for convenience functions in db.janet
(import /src/db)
(import /src/result)

(use judge)

(deftest "query-rows convenience"
  (with [db (db/open ":memory:")]
    (with [conn (db/connect db)]
      (def rows (db/query-rows conn "SELECT 1 AS a, 'hello' AS b"))
      (test rows @[{:a 1 :b "hello"}]))))

(deftest "query-first convenience"
  (with [db (db/open ":memory:")]
    (with [conn (db/connect db)]
      (def row (db/query-first conn "SELECT 1 AS a"))
      (test row {:a 1}))))

(deftest "query-first returns nil for empty result"
  (with [db (db/open ":memory:")]
    (with [conn (db/connect db)]
      (def row (db/query-first conn "SELECT 1 WHERE false"))
      (test row nil))))

(deftest "execute-sql convenience"
  (with [db (db/open ":memory:")]
    (with [conn (db/connect db)]
      (db/execute-sql conn "CREATE TABLE t (id INT)")
      (db/execute-sql conn "INSERT INTO t VALUES (1), (2)")
      (def n (db/execute-sql conn "INSERT INTO t VALUES (3)"))
      (test n 1))))
