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

(deftest "result-rows from query"
  (with [db (db/open ":memory:")]
    (with [conn (db/connect db)]
      (with [result (db/query conn "SELECT 1 AS a, 'hello' AS b")]
        (def rows (result/result-rows result))
        (test rows @[{:a 1 :b "hello"}])))))

(deftest "result-first from query"
  (with [db (db/open ":memory:")]
    (with [conn (db/connect db)]
      (with [result (db/query conn "SELECT 1 AS a")]
        (def row (result/result-first result))
        (test row {:a 1})))))

(deftest "result-first returns nil for empty result"
  (with [db (db/open ":memory:")]
    (with [conn (db/connect db)]
      (with [result (db/query conn "SELECT 1 WHERE false")]
        (def row (result/result-first result))
        (test row nil)))))

(deftest "query-rows with positional params"
  (with [db (db/open ":memory:")]
    (with [conn (db/connect db)]
      (db/execute-sql conn "CREATE TABLE t (id INT)")
      (db/execute-sql conn "INSERT INTO t VALUES (1), (2), (3)")
      (def rows (db/query-rows conn "SELECT * FROM t WHERE id > ?" [1]))
      (test rows @[{:id 2} {:id 3}]))))

(deftest "query-first with positional params"
  (with [db (db/open ":memory:")]
    (with [conn (db/connect db)]
      (db/execute-sql conn "CREATE TABLE t (id INT)")
      (db/execute-sql conn "INSERT INTO t VALUES (42)")
      (def row (db/query-first conn "SELECT * FROM t WHERE id = ?" [42]))
      (test row {:id 42}))))

(deftest "execute-sql with params"
  (with [db (db/open ":memory:")]
    (with [conn (db/connect db)]
      (db/execute-sql conn "CREATE TABLE t (id INT, name VARCHAR)")
      (def n (db/execute-sql conn "INSERT INTO t VALUES (?, ?)" [1 "hello"]))
      (test n 1)
      (def rows (db/query-rows conn "SELECT * FROM t"))
      (test rows @[{:id 1 :name "hello"}]))))

(deftest "query-rows with coll-type :tuple"
  (with [db (db/open ":memory:")]
    (with [conn (db/connect db)]
      (def rows (db/query-rows conn "SELECT 1 AS a, 2 AS b" :coll-type :tuple))
      (test rows @[[1 2]]))))

(deftest "query-first with coll-type :tuple"
  (with [db (db/open ":memory:")]
    (with [conn (db/connect db)]
      (def row (db/query-first conn "SELECT 1 AS a, 2 AS b" :coll-type :tuple))
      (test row [1 2]))))

(deftest "query-rows with params and coll-type :tuple"
  (with [db (db/open ":memory:")]
    (with [conn (db/connect db)]
      (db/execute-sql conn "CREATE TABLE t (a INT, b INT)")
      (db/execute-sql conn "INSERT INTO t VALUES (1, 2)")
      (def rows (db/query-rows conn "SELECT * FROM t WHERE a = ?" [1] :coll-type :tuple))
      (test rows @[[1 2]]))))

(deftest "query-first with params and coll-type :tuple"
  (with [db (db/open ":memory:")]
    (with [conn (db/connect db)]
      (db/execute-sql conn "CREATE TABLE t (a INT, b INT)")
      (db/execute-sql conn "INSERT INTO t VALUES (1, 2)")
      (def row (db/query-first conn "SELECT * FROM t WHERE a = ?" [1] :coll-type :tuple))
      (test row [1 2]))))

(deftest "query-rows with keywordize false"
  (with [db (db/open ":memory:")]
    (with [conn (db/connect db)]
      (def rows (db/query-rows conn "SELECT 1 AS a" :keywordize false))
      (test rows @[{"a" 1}]))))
