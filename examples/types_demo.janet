(import ../src/db)
(import ../src/result)

(use judge)

(with [db (db/open ":memory:")]
  (with [conn (db/connect db)]
    (with [result (db/query conn `
          CREATE TABLE types_test (
              id INTEGER,
              name VARCHAR,
              float FLOAT,
              double DOUBLE,
              int32 INTEGER,
              int64 BIGINT,
              decimal DECIMAL(5, 3),
              blob BLOB,
              date DATE,
              time TIME,
              timestamp TIMESTAMP_S,
              interval INTERVAL,
              list INTEGER[],
              arr INTEGER[3],
              struct STRUCT(col1 INTEGER, col2 VARCHAR),
              array_of_struct STRUCT(col1 INTEGER, col2 VARCHAR)[2],
              map MAP(INTEGER, DECIMAL),
              enum ENUM('sad', 'ok', 'happy'),
              u UNION(num INTEGER, str VARCHAR)
          )
        `)]
      (test (result/statement-type result) :DUCKDB_STATEMENT_TYPE_CREATE)
      (test (result/return-type result) :DUCKDB_RESULT_TYPE_NOTHING)
      (test (result/rows-changed result) 0)
      (test (result/describe-columns result :logical-type true)
            {:column-count 1
             :column-names ["Count"]
             :column-types [:bigint]})
      )
    (with [result (db/query conn `
          INSERT INTO types_test
          VALUES (1, 'Item 1', 10.5, 0.33333, 2, 6876786, 32.1, '\xAA', '2003-03-25', '11:30:00.123456', '1992-09-20 11:30:00.123456789', '1 YEAR', [42, NULL, 83], [1, 2, 3], {'col1': 1, 'col2': 'ha'}, [{'col1': 1, 'col2': 'ha'}, {'col1': 10, 'col2': 'he'}], MAP {3: -32.1}, 'happy', 1),
                 (2, 'Item 2', 20.75, 0.6786788,  3, 69870870970909, 2.32, '\xAA\xAB\xAC', '-infinity', '11:31:00.123456', '1992-09-20 11:31:00.123456789', '1 month 1 day', [1], [4, 5, NULL], {'col1': 2, 'col2': 'ho'}, [{'col1': 2, 'col2': 'ho'}, NULL], NULL, 'sad', 2),
                 (3, 'Item 3', 30.25, 0.6796980, 4, 716988600123456789, -3.1, 'AB', 'infinity', '11:33:00.123456', '1992-09-20 11:34:00.123456789', '48:00:00', [8, 9], [7, 8, 9], {'col1': NULL, 'col2': 'oops'}, [{'col1': NULL, 'col2': 'oops'}, {'col1': 30, 'col2': NULL}], MAP {1: 42.001, 5: -32.1}, 'ok', 'three')
        `)]
      (test (result/rows-changed result) 3)
      (test (result/describe-columns result :logical-type true)
            {:column-count 1
             :column-names ["Count"]
             :column-types [:bigint]})
      )

    (with [result (db/query conn "SELECT * FROM types_test")]
      (test (result/statement-type result) :DUCKDB_STATEMENT_TYPE_SELECT)
      (test (result/return-type result) :DUCKDB_RESULT_TYPE_QUERY_RESULT)
      (test (result/rows-changed result) 0)
      (test (result/describe-columns result :logical-type true)
            {:column-count 19
             :column-names ["id"
                            "name"
                            "float"
                            "double"
                            "int32"
                            "int64"
                            "decimal"
                            "blob"
                            "date"
                            "time"
                            "timestamp"
                            "interval"
                            "list"
                            "arr"
                            "struct"
                            "array_of_struct"
                            "map"
                            "enum"
                            "u"]
             :column-types [:int
                            :varchar
                            :float
                            :double
                            :int
                            :bigint
                            :decimal
                            :blob
                            :date
                            :time
                            :timestamp_s
                            :interval
                            [:list :int]
                            [:array [:int 3]]
                            [:struct {"col1" :int "col2" :varchar}]
                            [:array
                             [[:struct {"col1" :int "col2" :varchar}]
                              2]]
                            [:map {:int :decimal}]
                            [:enum {:members ["sad" "ok" "happy"]}]
                            [:union {:num :int :str :varchar}]]})

      (let [columns (result/fetch-columns result)]
        (test columns
          {:column @column-from-name
           :column-count 19
           :column-names ["id"
                          "name"
                          "float"
                          "double"
                          "int32"
                          "int64"
                          "decimal"
                          "blob"
                          "date"
                          "time"
                          "timestamp"
                          "interval"
                          "list"
                          "arr"
                          "struct"
                          "array_of_struct"
                          "map"
                          "enum"
                          "u"]
           :column-types [:int
                          :varchar
                          :float
                          :double
                          :int
                          :bigint
                          :decimal
                          :blob
                          :date
                          :time
                          :timestamp_s
                          :interval
                          :list
                          :array
                          :struct
                          :array
                          :map
                          :enum
                          :union]
           :columns @[@[1 2 3]
                      @["Item 1" "Item 2" "Item 3"]
                      @[10.5 20.75 30.25]
                      @[0.33333 0.6786788 0.679698]
                      @[2 3 4]
                      @[6876786
                        69870870970909
                        "716988600123456789"]
                      @[32.1 2.32 -3.1]
                      @[[-86] [-86 -85 -84] [65 66]]
                      @[{:month 2 :month-day 24 :year 2003}
                        {:month 5 :month-day 23 :year -5877641}
                        {:month 6 :month-day 10 :year 5881580}]
                      @[{:hours 11
                         :micros 123456
                         :minutes 30
                         :seconds 0}
                        {:hours 11
                         :micros 123456
                         :minutes 31
                         :seconds 0}
                        {:hours 11
                         :micros 123456
                         :minutes 33
                         :seconds 0}]
                      @[716988600 716988660 716988840]
                      @[{:days 0 :micros 0 :months 12}
                        {:days 1 :micros 0 :months 1}
                        {:days 0 :micros 172800000000 :months 0}]
                      @[@[42 nil 83] @[1] @[8 9]]
                      @[[1 2 3] [4 5 nil] [7 8 9]]
                      @[{:col1 1 :col2 "ha"}
                        {:col1 2 :col2 "ho"}
                        {:col2 "oops"}]
                      @[[{:col1 1 :col2 "ha"}
                         {:col1 10 :col2 "he"}]
                        [{:col1 2 :col2 "ho"} nil]
                        [{:col2 "oops"} {:col1 30}]]
                      @[@{3 -32.1} nil @{1 42.001 5 -32.1}]
                      @["happy" "sad" "ok"]
                      @[[:num 1] [:num 2] [:str "three"]]]
           :row-count 3})

        (test (result/columns-to-rows columns)
          @[{:arr [1 2 3]
             :array_of_struct [{:col1 1 :col2 "ha"}
                               {:col1 10 :col2 "he"}]
             :blob [-86]
             :date {:month 2 :month-day 24 :year 2003}
             :decimal 32.1
             :double 0.33333
             :enum "happy"
             :float 10.5
             :id 1
             :int32 2
             :int64 6876786
             :interval {:days 0 :micros 0 :months 12}
             :list @[42 nil 83]
             :map @{3 -32.1}
             :name "Item 1"
             :struct {:col1 1 :col2 "ha"}
             :time {:hours 11
                    :micros 123456
                    :minutes 30
                    :seconds 0}
             :timestamp 716988600
             :u [:num 1]}
            {:arr [4 5 nil]
             :array_of_struct [{:col1 2 :col2 "ho"} nil]
             :blob [-86 -85 -84]
             :date {:month 5 :month-day 23 :year -5877641}
             :decimal 2.32
             :double 0.6786788
             :enum "sad"
             :float 20.75
             :id 2
             :int32 3
             :int64 69870870970909
             :interval {:days 1 :micros 0 :months 1}
             :list @[1]
             :name "Item 2"
             :struct {:col1 2 :col2 "ho"}
             :time {:hours 11
                    :micros 123456
                    :minutes 31
                    :seconds 0}
             :timestamp 716988660
             :u [:num 2]}
            {:arr [7 8 9]
             :array_of_struct [{:col2 "oops"} {:col1 30}]
             :blob [65 66]
             :date {:month 6 :month-day 10 :year 5881580}
             :decimal -3.1
             :double 0.679698
             :enum "ok"
             :float 30.25
             :id 3
             :int32 4
             :int64 "716988600123456789"
             :interval {:days 0 :micros 172800000000 :months 0}
             :list @[8 9]
             :map @{1 42.001 5 -32.1}
             :name "Item 3"
             :struct {:col2 "oops"}
             :time {:hours 11
                    :micros 123456
                    :minutes 33
                    :seconds 0}
             :timestamp 716988840
             :u [:str "three"]}])
        )
      )
    ))
