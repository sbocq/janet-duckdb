(import /src/db)
(import /src/result)

(use judge)

(deftest-type mem_db
  :setup (fn []
           (def db (db/open ":memory:"))
           (def conn (db/connect db))
           [db conn])
  :reset (fn [[_ conn]] (with [result (db/query conn "DROP TABLE IF EXISTS types_test")]))
  :teardown (fn [[db conn]]
              (:close conn)
              (:close db)))

#==------------------------------------------------------------------------==#
# Query test
#==------------------------------------------------------------------------==#
(deftest "simple query test"
  (test (with [db (db/open ":memory:")]
          (with [conn (db/connect db)]
            (def result (db/query conn "SELECT 1"))
            (:close result)))
    nil))

(deftest "simple result test"
  (with [db (db/open ":memory:")]
    (with [conn (db/connect db)]
      (with [result (db/query conn "SELECT 1")]
        (test (result/statement-type result) :DUCKDB_STATEMENT_TYPE_SELECT)
        (test (result/return-type result) :DUCKDB_RESULT_TYPE_QUERY_RESULT)
        (test (result/rows-changed result) 0)
        (test (result/describe-columns result :logical-type true)
          {:column-count 1
           :column-names ["1"]
           :column-types [:int]})
        (test (result/fetch-columns result)
          {:column @column-from-name
           :column-count 1
           :column-names ["1"]
           :column-types [:int]
           :columns @[@[1]]
           :row-count 1})
        )
      )))

#==------------------------------------------------------------------------==#
# Simple types
#==------------------------------------------------------------------------==#

(deftest: mem_db "simple types" [[_ conn]]
  (with [result (db/query conn `
          CREATE TABLE types_test (
              id INTEGER,
              name VARCHAR,
              site_admin BOOL,
              value DOUBLE,
              int32 INTEGER,
              int64 BIGINT,
              decimal DECIMAL(5, 3)
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

  # Test inlined (<= 12 bytes) and non inlined strings.
  (with [result (db/query conn `
          INSERT INTO types_test
          VALUES (1, 'Organizatio', true, 10.5, 2, 6876786, 32.1),
                 (2, 'Organization', false, 20.75, 3, 69870870970909, 2.32),
                 (3, 'Organizatione', true, 30.25, 4, 716988600123456789, -3.1)
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
      {:column-count 7
       :column-names ["id"
                      "name"
                      "site_admin"
                      "value"
                      "int32"
                      "int64"
                      "decimal"]
       :column-types [:int
                      :varchar
                      :bool
                      :double
                      :int
                      :bigint
                      :decimal]})
    (let [columns (result/fetch-columns result)]
      (test columns
        {:column @column-from-name
         :column-count 7
         :column-names ["id"
                        "name"
                        "site_admin"
                        "value"
                        "int32"
                        "int64"
                        "decimal"]
         :column-types [:int
                        :varchar
                        :bool
                        :double
                        :int
                        :bigint
                        :decimal]
         :columns @[@[1 2 3]
                    @["Organizatio"
                      "Organization"
                      "Organizatione"]
                    @[true false true]
                    @[10.5 20.75 30.25]
                    @[2 3 4]
                    @[6876786
                      69870870970909
                      "716988600123456789"]
                    @[32.1 2.32 -3.1]]
         :row-count 3})
      (test (result/columns-to-rows columns)
        @[{:decimal 32.1
           :id 1
           :int32 2
           :int64 6876786
           :name "Organizatio"
           :site_admin true
           :value 10.5}
          {:decimal 2.32
           :id 2
           :int32 3
           :int64 69870870970909
           :name "Organization"
           :site_admin false
           :value 20.75}
          {:decimal -3.1
           :id 3
           :int32 4
           :int64 "716988600123456789"
           :name "Organizatione"
           :site_admin true
           :value 30.25}])
      (test (result/columns-to-rows columns :coll-type :table)
        @[@{:decimal 32.1
            :id 1
            :int32 2
            :int64 6876786
            :name "Organizatio"
            :site_admin true
            :value 10.5}
          @{:decimal 2.32
            :id 2
            :int32 3
            :int64 69870870970909
            :name "Organization"
            :site_admin false
            :value 20.75}
          @{:decimal -3.1
            :id 3
            :int32 4
            :int64 "716988600123456789"
            :name "Organizatione"
            :site_admin true
            :value 30.25}])
      (test (result/columns-to-rows columns :coll-type :tuple)
        @[[1
           "Organizatio"
           true
           10.5
           2
           6876786
           32.1]
          [2
           "Organization"
           false
           20.75
           3
           69870870970909
           2.32]
          [3
           "Organizatione"
           true
           30.25
           4
           "716988600123456789"
           -3.1]])
      (test (result/columns-to-rows columns :coll-type :array)
        @[@[1
            "Organizatio"
            true
            10.5
            2
            6876786
            32.1]
          @[2
            "Organization"
            false
            20.75
            3
            69870870970909
            2.32]
          @[3
            "Organizatione"
            true
            30.25
            4
            "716988600123456789"
            -3.1]])
      )
    )

  (with [result (db/query conn "SELECT * FROM types_test")]
    (let [g (result/generate-columns result)
          r @[]]
      (each chunk g
        (array/push r chunk))
      (test r
        @[{:chunk-offset 0
           :column @column-from-name
           :column-count 7
           :column-names ["id"
                          "name"
                          "site_admin"
                          "value"
                          "int32"
                          "int64"
                          "decimal"]
           :column-types [:int
                          :varchar
                          :bool
                          :double
                          :int
                          :bigint
                          :decimal]
           :columns @[@[1 2 3]
                      @["Organizatio"
                        "Organization"
                        "Organizatione"]
                      @[true false true]
                      @[10.5 20.75 30.25]
                      @[2 3 4]
                      @[6876786
                        69870870970909
                        "716988600123456789"]
                      @[32.1 2.32 -3.1]]
           :row-count 3}])
      (test (:column (r 0) "id") @[1 2 3])
      (test (mapcat result/columns-to-rows r)
        @[{:decimal 32.1
           :id 1
           :int32 2
           :int64 6876786
           :name "Organizatio"
           :site_admin true
           :value 10.5}
          {:decimal 2.32
           :id 2
           :int32 3
           :int64 69870870970909
           :name "Organization"
           :site_admin false
           :value 20.75}
          {:decimal -3.1
           :id 3
           :int32 4
           :int64 "716988600123456789"
           :name "Organizatione"
           :site_admin true
           :value 30.25}]))
    )
  )

#==------------------------------------------------------------------------==#
# Blob type
#==------------------------------------------------------------------------==#

(deftest: mem_db "Blob type test" [[_ conn]]
  (with [result (db/query conn `
          SELECT
              '\xAA'::BLOB,
              '\xAA\xAB\xAC'::BLOB,
              'AB'::BLOB
        `)]
    (test (result/describe-columns result :logical-type true)
      {:column-count 3
       :column-names ["'\\xAA'::BLOB"
                      "'\\xAA\\xAB\\xAC'::BLOB"
                      "'AB'::BLOB"]
       :column-types [:blob :blob :blob]})
    (let [columns (result/fetch-columns result)]
      (test columns
        {:column @column-from-name
         :column-count 3
         :column-names ["'\\xAA'::BLOB"
                        "'\\xAA\\xAB\\xAC'::BLOB"
                        "'AB'::BLOB"]
         :column-types [:blob :blob :blob]
         :columns @[@[[-86]] @[[-86 -85 -84]] @[[65 66]]]
         :row-count 1})
      ))
  )

#==------------------------------------------------------------------------==#
# Date time types
#==------------------------------------------------------------------------==#

(deftest: mem_db "date type test" [[_ conn]]
  (with [result (db/query conn `
          SELECT
              '-infinity'::DATE AS negative,
              'epoch'::DATE AS epoch,
              'infinity'::DATE AS positive
        `)]
    (test (result/describe-columns result :logical-type true)
      {:column-count 3
       :column-names ["negative" "epoch" "positive"]
       :column-types [:date :date :date]})
    (let [columns (result/fetch-columns result)]
      (test columns
        {:column @column-from-name
         :column-count 3
         :column-names ["negative" "epoch" "positive"]
         :column-types [:date :date :date]
         :columns @[@[{:month 5 :month-day 23 :year -5877641}]
                    @[{:month 0 :month-day 0 :year 1970}]
                    @[{:month 6 :month-day 10 :year 5881580}]]
         :row-count 1})

      ))
  )

(deftest: mem_db "time type test" [[_ conn]]
  (with [result (db/query conn `
          SELECT
              TIME '1992-09-20 11:30:00.123456',
              TIMETZ '1992-09-20 11:30:00.123456',
              TIMETZ '1992-09-20 11:30:00.123456-02:00',
              TIMETZ '1992-09-20 11:30:00.123456+05:30'
        `)]
    (test (result/describe-columns result :logical-type true)
      {:column-count 4
       :column-names ["CAST('1992-09-20 11:30:00.123456' AS TIME)"
                      "CAST('1992-09-20 11:30:00.123456' AS TIME WITH TIME ZONE)"
                      "CAST('1992-09-20 11:30:00.123456-02:00' AS TIME WITH TIME ZONE)"
                      "CAST('1992-09-20 11:30:00.123456+05:30' AS TIME WITH TIME ZONE)"]
       :column-types [:time :time-tz :time-tz :time-tz]})
    (let [columns (result/fetch-columns result)]
      (test columns
        {:column @column-from-name
         :column-count 4
         :column-names ["CAST('1992-09-20 11:30:00.123456' AS TIME)"
                        "CAST('1992-09-20 11:30:00.123456' AS TIME WITH TIME ZONE)"
                        "CAST('1992-09-20 11:30:00.123456-02:00' AS TIME WITH TIME ZONE)"
                        "CAST('1992-09-20 11:30:00.123456+05:30' AS TIME WITH TIME ZONE)"]
         :column-types [:time :time-tz :time-tz :time-tz]
         :columns @[@[{:hours 11
                       :micros 123456
                       :minutes 30
                       :seconds 0}]
                    @[{:hours 63
                       :micros 28895
                       :minutes 20
                       :seconds 48}]
                    @[{:hours 63
                       :micros 28895
                       :minutes 20
                       :seconds 48}]
                    @[{:hours 63
                       :micros 28895
                       :minutes 20
                       :seconds 48}]]
         :row-count 1})

      ))
  )

(deftest: mem_db "timestamp type test" [[_ conn]]
  (with [result (db/query conn `
          SELECT
              TIMESTAMP_NS '1992-09-20 11:30:00.123456789',
              TIMESTAMP '1992-09-20 11:30:00.123456789',
              TIMESTAMP_MS '1992-09-20 11:30:00.123456789',
              TIMESTAMP_S '1992-09-20 11:30:00.123456789',
              TIMESTAMPTZ '1992-09-20 11:30:00.123456789',
              TIMESTAMPTZ '1992-09-20 12:30:00.123456789+01:00'
        `)]
    (test (result/describe-columns result :logical-type true)
      {:column-count 6
       :column-names ["CAST('1992-09-20 11:30:00.123456789' AS TIMESTAMP_NS)"
                      "CAST('1992-09-20 11:30:00.123456789' AS TIMESTAMP)"
                      "CAST('1992-09-20 11:30:00.123456789' AS TIMESTAMP_MS)"
                      "CAST('1992-09-20 11:30:00.123456789' AS TIMESTAMP_S)"
                      "CAST('1992-09-20 11:30:00.123456789' AS TIMESTAMP WITH TIME ZONE)"
                      "CAST('1992-09-20 12:30:00.123456789+01:00' AS TIMESTAMP WITH TIME ZONE)"]
       :column-types [:timestamp_ns
                      :timestamp
                      :timestamp_ms
                      :timestamp_s
                      :timestampz
                      :timestampz]})
    (let [columns (result/fetch-columns result)]
      (test columns
        {:column @column-from-name
         :column-count 6
         :column-names ["CAST('1992-09-20 11:30:00.123456789' AS TIMESTAMP_NS)"
                        "CAST('1992-09-20 11:30:00.123456789' AS TIMESTAMP)"
                        "CAST('1992-09-20 11:30:00.123456789' AS TIMESTAMP_MS)"
                        "CAST('1992-09-20 11:30:00.123456789' AS TIMESTAMP_S)"
                        "CAST('1992-09-20 11:30:00.123456789' AS TIMESTAMP WITH TIME ZONE)"
                        "CAST('1992-09-20 12:30:00.123456789+01:00' AS TIMESTAMP WITH TIME ZONE)"]
         :column-types [:timestamp_ns
                        :timestamp
                        :timestamp_ms
                        :timestamp_s
                        :timestampz
                        :timestampz]
         :columns @[@["716988600123456789"]
                    @[716988600123456]
                    @[716988600123]
                    @[716988600]
                    @[716981400123456]
                    @[716988600123456]]
         :row-count 1})
      (test (type (get-in columns [:columns 0 0])) :core/s64)
      (test (type (get-in columns [:columns 1 0])) :number)
      ))
  )

(deftest: mem_db "interval type test" [[_ conn]]
  (with [result (db/query conn `
          SELECT
              INTERVAL 1 YEAR, -- single unit using YEAR keyword; stored as 12 months
              INTERVAL (36.78 * 10) YEAR, -- parentheses necessary for variable amounts;
                                             -- stored as integer number of months
              INTERVAL '1 month 1 day', -- string type necessary for multiple units; stored as (1 month, 1 day)
                       '16 months'::INTERVAL, -- string cast supported; stored as 16 months
              '48:00:00'::INTERVAL, -- HH::MM::SS string supported; stored as (48 * 60 * 60 * 1e6 microseconds)
        `)]
    (test (result/describe-columns result :logical-type true)
      {:column-count 5
       :column-names ["to_years(CAST(trunc(CAST(1 AS DOUBLE)) AS INTEGER))"
                      "to_years(CAST(trunc(CAST((36.78 * 10) AS DOUBLE)) AS INTEGER))"
                      "CAST('1 month 1 day' AS INTERVAL)"
                      "CAST('16 months' AS INTERVAL)"
                      "CAST('48:00:00' AS INTERVAL)"]
       :column-types [:interval
                      :interval
                      :interval
                      :interval
                      :interval]})
    (let [columns (result/fetch-columns result)]
      (test columns
        {:column @column-from-name
         :column-count 5
         :column-names ["to_years(CAST(trunc(CAST(1 AS DOUBLE)) AS INTEGER))"
                        "to_years(CAST(trunc(CAST((36.78 * 10) AS DOUBLE)) AS INTEGER))"
                        "CAST('1 month 1 day' AS INTERVAL)"
                        "CAST('16 months' AS INTERVAL)"
                        "CAST('48:00:00' AS INTERVAL)"]
         :column-types [:interval
                        :interval
                        :interval
                        :interval
                        :interval]
         :columns @[@[{:days 0 :micros 0 :months 12}]
                    @[{:days 0 :micros 0 :months 4404}]
                    @[{:days 1 :micros 0 :months 1}]
                    @[{:days 0 :micros 0 :months 16}]
                    @[{:days 0 :micros 172800000000 :months 0}]]
         :row-count 1})
      ))
  )

#==------------------------------------------------------------------------==#
# Basic vector types with NULL values
#==------------------------------------------------------------------------==#

(deftest: mem_db "reading a int64 vector with NULL values" [[_ conn]]

  (with [result (db/query conn `
          SELECT CASE WHEN i%2=0 THEN NULL ELSE i END res_col FROM range(10) t(i)
        `)]
    (test (result/describe-columns result :logical-type true)
      {:column-count 1
       :column-names ["res_col"]
       :column-types [:bigint]})
    (let [columns (result/fetch-columns result)]
      (test columns
        {:column @column-from-name
         :column-count 1
         :column-names ["res_col"]
         :column-types [:bigint]
         :columns @[@[nil 1 nil 3 nil 5 nil 7 nil 9]]
         :row-count 10})
      (test (result/columns-to-rows columns)
        @[{}
          {:res_col 1}
          {}
          {:res_col 3}
          {}
          {:res_col 5}
          {}
          {:res_col 7}
          {}
          {:res_col 9}])
      (test (result/columns-to-rows columns :coll-type :table)
        @[@{}
          @{:res_col 1}
          @{}
          @{:res_col 3}
          @{}
          @{:res_col 5}
          @{}
          @{:res_col 7}
          @{}
          @{:res_col 9}])
      (test (result/columns-to-rows columns :coll-type :tuple)
        @[[nil]
          [1]
          [nil]
          [3]
          [nil]
          [5]
          [nil]
          [7]
          [nil]
          [9]])
      (test (result/columns-to-rows columns :coll-type :array)
        @[@[nil]
          @[1]
          @[nil]
          @[3]
          @[nil]
          @[5]
          @[nil]
          @[7]
          @[nil]
          @[9]]))
    )
  )

(deftest: mem_db "reading a string vector" [[_ conn]]
  (with [result (db/query conn `
          SELECT CASE WHEN i%2=0 THEN CONCAT('short_', i)
                 ELSE CONCAT('longstringprefix', i)
                 END s
          FROM range(10) t(i)
        `)]
    (test (result/describe-columns result :logical-type true)
      {:column-count 1
       :column-names ["s"]
       :column-types [:varchar]})
    (let [columns (result/fetch-columns result)]
      (test columns
        {:column @column-from-name
         :column-count 1
         :column-names ["s"]
         :column-types [:varchar]
         :columns @[@["short_0"
                      "longstringprefix1"
                      "short_2"
                      "longstringprefix3"
                      "short_4"
                      "longstringprefix5"
                      "short_6"
                      "longstringprefix7"
                      "short_8"
                      "longstringprefix9"]]
         :row-count 10})
      (test (result/columns-to-rows columns)
        @[{:s "short_0"}
          {:s "longstringprefix1"}
          {:s "short_2"}
          {:s "longstringprefix3"}
          {:s "short_4"}
          {:s "longstringprefix5"}
          {:s "short_6"}
          {:s "longstringprefix7"}
          {:s "short_8"}
          {:s "longstringprefix9"}])
      (test (result/columns-to-rows columns :coll-type :table)
        @[@{:s "short_0"}
          @{:s "longstringprefix1"}
          @{:s "short_2"}
          @{:s "longstringprefix3"}
          @{:s "short_4"}
          @{:s "longstringprefix5"}
          @{:s "short_6"}
          @{:s "longstringprefix7"}
          @{:s "short_8"}
          @{:s "longstringprefix9"}])
      (test (result/columns-to-rows columns :coll-type :tuple)
        @[["short_0"]
          ["longstringprefix1"]
          ["short_2"]
          ["longstringprefix3"]
          ["short_4"]
          ["longstringprefix5"]
          ["short_6"]
          ["longstringprefix7"]
          ["short_8"]
          ["longstringprefix9"]])
      (test (result/columns-to-rows columns :coll-type :array)
        @[@["short_0"]
          @["longstringprefix1"]
          @["short_2"]
          @["longstringprefix3"]
          @["short_4"]
          @["longstringprefix5"]
          @["short_6"]
          @["longstringprefix7"]
          @["short_8"]
          @["longstringprefix9"]]))
    )
  )

#==------------------------------------------------------------------------==#
# Complex vector types with NULL values
#==------------------------------------------------------------------------==#

(deftest: mem_db "reading a list vector" [[_ conn]]

  (with [result (db/query conn `
          SELECT CASE WHEN i % 5 = 0 THEN NULL
                      WHEN i % 2 = 0 THEN [i, i + 1]
                      ELSE [i * 42, NULL, i * 84]
                 END l
          FROM range(10) t(i)
        `)]
    (test (result/describe-columns result :logical-type true)
      {:column-count 1
       :column-names ["l"]
       :column-types [[:list :bigint]]})
    (let [columns (result/fetch-columns result)]
      (test columns
        {:column @column-from-name
         :column-count 1
         :column-names ["l"]
         :column-types [:list]
         :columns @[@[nil
                      @[42 nil 84]
                      @[2 3]
                      @[126 nil 252]
                      @[4 5]
                      nil
                      @[6 7]
                      @[294 nil 588]
                      @[8 9]
                      @[378 nil 756]]]
         :row-count 10})
      (test (result/columns-to-rows columns)
        @[{}
          {:l @[42 nil 84]}
          {:l @[2 3]}
          {:l @[126 nil 252]}
          {:l @[4 5]}
          {}
          {:l @[6 7]}
          {:l @[294 nil 588]}
          {:l @[8 9]}
          {:l @[378 nil 756]}])
      (test (result/columns-to-rows columns :coll-type :table)
        @[@{}
          @{:l @[42 nil 84]}
          @{:l @[2 3]}
          @{:l @[126 nil 252]}
          @{:l @[4 5]}
          @{}
          @{:l @[6 7]}
          @{:l @[294 nil 588]}
          @{:l @[8 9]}
          @{:l @[378 nil 756]}])
      (test (result/columns-to-rows columns :coll-type :tuple)
        @[[nil]
          [@[42 nil 84]]
          [@[2 3]]
          [@[126 nil 252]]
          [@[4 5]]
          [nil]
          [@[6 7]]
          [@[294 nil 588]]
          [@[8 9]]
          [@[378 nil 756]]])
      (test (result/columns-to-rows columns :coll-type :array)
        @[@[nil]
          @[@[42 nil 84]]
          @[@[2 3]]
          @[@[126 nil 252]]
          @[@[4 5]]
          @[nil]
          @[@[6 7]]
          @[@[294 nil 588]]
          @[@[8 9]]
          @[@[378 nil 756]]]))
    )
  )

(deftest: mem_db "reading an array vector" [[_ conn]]

  (with [result (db/query conn `
          SELECT *
          FROM (VALUES (array_value(1, 2, 3)),
                       (NULL),
                       (array_value(2, NULL, 4))) t
        `)]
    (test (result/describe-columns result :logical-type true)
      {:column-count 1
       :column-names ["col0"]
       :column-types [[:array [:int 3]]]})
    (let [columns (result/fetch-columns result)]
      (test columns
        {:column @column-from-name
         :column-count 1
         :column-names ["col0"]
         :column-types [:array]
         :columns @[@[[1 2 3] nil [2 nil 4]]]
         :row-count 3})
      (test (result/columns-to-rows columns)
        @[{:col0 [1 2 3]} {} {:col0 [2 nil 4]}])
      (test (result/columns-to-rows columns :coll-type :table)
        @[@{:col0 [1 2 3]}
          @{}
          @{:col0 [2 nil 4]}])
      (test (result/columns-to-rows columns :coll-type :tuple) @[[[1 2 3]] [nil] [[2 nil 4]]])
      (test (result/columns-to-rows columns :coll-type :array) @[@[[1 2 3]] @[nil] @[[2 nil 4]]]))
    )
  )


(deftest: mem_db "reading a struct vector" [[_ conn]]

  (with [result (db/query conn `
          SELECT CASE WHEN i%5=0 THEN NULL
                      ELSE {'col1': i, 'col2': CASE WHEN i%2=0 THEN NULL ELSE 100 + i * 42 END}
                      END s
          FROM range(10) t(i)
        `)]
    (test (result/describe-columns result :logical-type true)
      {:column-count 1
       :column-names ["s"]
       :column-types [[:struct
                       {"col1" :bigint "col2" :bigint}]]})
    (let [columns (result/fetch-columns result)]
      (test columns
        {:column @column-from-name
         :column-count 1
         :column-names ["s"]
         :column-types [:struct]
         :columns @[@[nil
                      {:col1 1 :col2 142}
                      {:col1 2}
                      {:col1 3 :col2 226}
                      {:col1 4}
                      nil
                      {:col1 6}
                      {:col1 7 :col2 394}
                      {:col1 8}
                      {:col1 9 :col2 478}]]
         :row-count 10})
      (test (result/columns-to-rows columns)
        @[{}
          {:s {:col1 1 :col2 142}}
          {:s {:col1 2}}
          {:s {:col1 3 :col2 226}}
          {:s {:col1 4}}
          {}
          {:s {:col1 6}}
          {:s {:col1 7 :col2 394}}
          {:s {:col1 8}}
          {:s {:col1 9 :col2 478}}])
      (test (result/columns-to-rows columns :coll-type :table)
        @[@{}
          @{:s {:col1 1 :col2 142}}
          @{:s {:col1 2}}
          @{:s {:col1 3 :col2 226}}
          @{:s {:col1 4}}
          @{}
          @{:s {:col1 6}}
          @{:s {:col1 7 :col2 394}}
          @{:s {:col1 8}}
          @{:s {:col1 9 :col2 478}}])
      (test (result/columns-to-rows columns :coll-type :tuple)
        @[[nil]
          [{:col1 1 :col2 142}]
          [{:col1 2}]
          [{:col1 3 :col2 226}]
          [{:col1 4}]
          [nil]
          [{:col1 6}]
          [{:col1 7 :col2 394}]
          [{:col1 8}]
          [{:col1 9 :col2 478}]])
      (test (result/columns-to-rows columns :coll-type :array)
        @[@[nil]
          @[{:col1 1 :col2 142}]
          @[{:col1 2}]
          @[{:col1 3 :col2 226}]
          @[{:col1 4}]
          @[nil]
          @[{:col1 6}]
          @[{:col1 7 :col2 394}]
          @[{:col1 8}]
          @[{:col1 9 :col2 478}]]))
    )
  )

(deftest: mem_db "reading a struct vector 2" [[_ conn]]

  (with [result (db/query conn `
          SELECT *
          FROM (VALUES ({'col1': 1, 'col2': 'hi', 'col3': 3}),
                       (NULL),
                       ({'col1': 4, 'col2': NULL, 'col3': 5}),
                       ({'col1': 4, 'col2': 'ho'})) t
        `)]
    (test (result/describe-columns result :logical-type true)
      {:column-count 1
       :column-names ["col0"]
       :column-types [[:struct
                       {"col1" :int
                        "col2" :varchar
                        "col3" :int}]]})
    (let [columns (result/fetch-columns result)]
      (test columns
        {:column @column-from-name
         :column-count 1
         :column-names ["col0"]
         :column-types [:struct]
         :columns @[@[{:col1 1 :col2 "hi" :col3 3}
                      nil
                      {:col1 4 :col3 5}
                      {:col1 4 :col2 "ho"}]]
         :row-count 4})
      (test (result/columns-to-rows columns)
        @[{:col0 {:col1 1 :col2 "hi" :col3 3}}
          {}
          {:col0 {:col1 4 :col3 5}}
          {:col0 {:col1 4 :col2 "ho"}}])
      (test (result/columns-to-rows columns :coll-type :table)
        @[@{:col0 {:col1 1 :col2 "hi" :col3 3}}
          @{}
          @{:col0 {:col1 4 :col3 5}}
          @{:col0 {:col1 4 :col2 "ho"}}])
      (test (result/columns-to-rows columns :coll-type :tuple)
        @[[{:col1 1 :col2 "hi" :col3 3}]
          [nil]
          [{:col1 4 :col3 5}]
          [{:col1 4 :col2 "ho"}]])
      (test (result/columns-to-rows columns :coll-type :array)
        @[@[{:col1 1 :col2 "hi" :col3 3}]
          @[nil]
          @[{:col1 4 :col3 5}]
          @[{:col1 4 :col2 "ho"}]]))
    )
  )

(deftest: mem_db "reading an array of structs" [[_ conn]]

  (with [result (db/query conn `
          SELECT *
          FROM (VALUES (array_value({'col1': 1, 'col2': 'hi', 'col3': 3},
                                    {'col1': 3, 'col2': 'ho', 'col3': 3})),
                       (NULL),
                       (array_value({'col1': 4, 'col2': NULL, 'col3': 5},
                                    {'col1': NULL,  'col3': NULL}))) t
        `)]
    (test (result/describe-columns result :logical-type true)
      {:column-count 1
       :column-names ["col0"]
       :column-types [[:array
                       [[:struct
                         {"col1" :int
                          "col2" :varchar
                          "col3" :int}]
                        2]]]})
    (let [columns (result/fetch-columns result)]
      (test columns
        {:column @column-from-name
         :column-count 1
         :column-names ["col0"]
         :column-types [:array]
         :columns @[@[[{:col1 1 :col2 "hi" :col3 3}
                       {:col1 3 :col2 "ho" :col3 3}]
                      nil
                      [{:col1 4 :col3 5} {}]]]
         :row-count 3})
      (test (result/columns-to-rows columns)
        @[{:col0 [{:col1 1 :col2 "hi" :col3 3}
                  {:col1 3 :col2 "ho" :col3 3}]}
          {}
          {:col0 [{:col1 4 :col3 5} {}]}])
      (test (result/columns-to-rows columns :coll-type :table)
        @[@{:col0 [{:col1 1 :col2 "hi" :col3 3}
                   {:col1 3 :col2 "ho" :col3 3}]}
          @{}
          @{:col0 [{:col1 4 :col3 5} {}]}])
      (test (result/columns-to-rows columns :coll-type :tuple)
        @[[[{:col1 1 :col2 "hi" :col3 3}
            {:col1 3 :col2 "ho" :col3 3}]]
          [nil]
          [[{:col1 4 :col3 5} {}]]])
      (test (result/columns-to-rows columns :coll-type :array)
        @[@[[{:col1 1 :col2 "hi" :col3 3}
             {:col1 3 :col2 "ho" :col3 3}]]
          @[nil]
          @[[{:col1 4 :col3 5} {}]]]))
    )
  )

(deftest: mem_db "reading a list of structs" [[_ conn]]

  (with [result (db/query conn `
          SELECT *
          FROM (VALUES ([{'key': 3, 'value': 3}, {'key': 4, 'value': 4}]),
                       (NULL),
                       ([{'key': 1, 'value': 2},
                         {'key': 5, 'value': 3}])) t
        `)]
    (test (result/describe-columns result :logical-type true)
      {:column-count 1
       :column-names ["col0"]
       :column-types [[:list
                       [:struct {"key" :int "value" :int}]]]})
    (let [columns (result/fetch-columns result)]
      (test columns
        {:column @column-from-name
         :column-count 1
         :column-names ["col0"]
         :column-types [:list]
         :columns @[@[@[{:key 3 :value 3} {:key 4 :value 4}]
                      nil
                      @[{:key 1 :value 2} {:key 5 :value 3}]]]
         :row-count 3})
      (test (result/columns-to-rows columns)
        @[{:col0 @[{:key 3 :value 3} {:key 4 :value 4}]}
          {}
          {:col0 @[{:key 1 :value 2} {:key 5 :value 3}]}])
      (test (result/columns-to-rows columns :coll-type :table)
        @[@{:col0 @[{:key 3 :value 3} {:key 4 :value 4}]}
          @{}
          @{:col0 @[{:key 1 :value 2} {:key 5 :value 3}]}])
      (test (result/columns-to-rows columns :coll-type :tuple)
        @[[@[{:key 3 :value 3} {:key 4 :value 4}]]
          [nil]
          [@[{:key 1 :value 2} {:key 5 :value 3}]]])
      (test (result/columns-to-rows columns :coll-type :array)
        @[@[@[{:key 3 :value 3} {:key 4 :value 4}]]
          @[nil]
          @[@[{:key 1 :value 2} {:key 5 :value 3}]]]))
    )
  )

(deftest: mem_db "reading a map vector" [[_ conn]]

  (with [result (db/query conn `
          SELECT *
          FROM (VALUES (MAP {3: -32.1}),
                       (NULL),
                       (MAP {1: 42.001, 5: -32.1})) t
        `)]
    (test (result/describe-columns result :logical-type true)
      {:column-count 1
       :column-names ["col0"]
       :column-types [[:map {:int :decimal}]]})
    (let [columns (result/fetch-columns result)]
      (test columns
        {:column @column-from-name
         :column-count 1
         :column-names ["col0"]
         :column-types [:map]
         :columns @[@[@{3 -32.1} nil @{1 42.001 5 -32.1}]]
         :row-count 3})
      (test (result/columns-to-rows columns)
        @[{:col0 @{3 -32.1}}
          {}
          {:col0 @{1 42.001 5 -32.1}}])
      (test (result/columns-to-rows columns :coll-type :table)
        @[@{:col0 @{3 -32.1}}
          @{}
          @{:col0 @{1 42.001 5 -32.1}}])
      (test (result/columns-to-rows columns :coll-type :tuple)
        @[[@{3 -32.1}]
          [nil]
          [@{1 42.001 5 -32.1}]])
      (test (result/columns-to-rows columns :coll-type :array)
        @[@[@{3 -32.1}]
          @[nil]
          @[@{1 42.001 5 -32.1}]]))
    )
  )

(deftest: mem_db "reading an enum" [[_ conn]]
  (with [result (db/query conn `
          CREATE TABLE types_test (
                                   name TEXT,
            mood ENUM ('sad', 'ok', 'happy')
                                        )
        `)])

  (with [result (db/query conn `
          INSERT INTO types_test
          VALUES ('Pedro', 'happy'),
                 ('Mark', NULL),
                 ('Pagliacci', 'sad'),
                 ('Mr. Mackey', 'ok')
        `)]
    (test (result/return-type result) :DUCKDB_RESULT_TYPE_CHANGED_ROWS)
    (test (result/rows-changed result) 4)
    )

  (with [result (db/query conn "SELECT * FROM types_test")]
    (test (result/describe-columns result :logical-type true)
      {:column-count 2
       :column-names ["name" "mood"]
       :column-types [:varchar
                      [:enum {:members ["sad" "ok" "happy"]}]]})
    (let [columns (result/fetch-columns result)]
      (test columns
        {:column @column-from-name
         :column-count 2
         :column-names ["name" "mood"]
         :column-types [:varchar :enum]
         :columns @[@["Pedro"
                      "Mark"
                      "Pagliacci"
                      "Mr. Mackey"]
                    @["happy" nil "sad" "ok"]]
         :row-count 4})
      (test (result/columns-to-rows columns)
        @[{:mood "happy" :name "Pedro"}
          {:name "Mark"}
          {:mood "sad" :name "Pagliacci"}
          {:mood "ok" :name "Mr. Mackey"}])
      (test (result/columns-to-rows columns :coll-type :table)
        @[@{:mood "happy" :name "Pedro"}
          @{:name "Mark"}
          @{:mood "sad" :name "Pagliacci"}
          @{:mood "ok" :name "Mr. Mackey"}])
      (test (result/columns-to-rows columns :coll-type :tuple)
        @[["Pedro" "happy"]
          ["Mark" nil]
          ["Pagliacci" "sad"]
          ["Mr. Mackey" "ok"]])
      (test (result/columns-to-rows columns :coll-type :array)
        @[@["Pedro" "happy"]
          @["Mark" nil]
          @["Pagliacci" "sad"]
          @["Mr. Mackey" "ok"]]))
    )
  )

(deftest: mem_db "reading an union" [[_ conn]]
  (with [result (db/query conn "CREATE TABLE types_test (
    u UNION(num INTEGER, str VARCHAR)
  )")])

  (with [result (db/query conn `
          INSERT INTO types_test
          VALUES (1), ('two'), (union_value(str := 'three'))
        `)]
    (test (result/return-type result) :DUCKDB_RESULT_TYPE_CHANGED_ROWS)
    (test (result/rows-changed result) 3)
  )

  (with [result (db/query conn "SELECT * FROM types_test")]
    (test (result/describe-columns result :logical-type true)
      {:column-count 1
       :column-names ["u"]
       :column-types [[:union {:num :int :str :varchar}]]})
    (let [columns (result/fetch-columns result)]
      (test columns
        {:column @column-from-name
         :column-count 1
         :column-names ["u"]
         :column-types [:union]
         :columns @[@[[:num 1] [:str "two"] [:str "three"]]]
         :row-count 3})
      (test (result/columns-to-rows columns)
        @[{:u [:num 1]}
          {:u [:str "two"]}
          {:u [:str "three"]}])
      (test (result/columns-to-rows columns :coll-type :table)
        @[@{:u [:num 1]}
          @{:u [:str "two"]}
          @{:u [:str "three"]}])
      (test (result/columns-to-rows columns :coll-type :tuple)
        @[[[:num 1]]
          [[:str "two"]]
          [[:str "three"]]])
      (test (result/columns-to-rows columns :coll-type :array)
        @[@[[:num 1]]
          @[[:str "two"]]
          @[[:str "three"]]]))
    )
  )
