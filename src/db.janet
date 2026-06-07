#==----------------------------------------------------------------------------------------------==#
#
# All functions that deal directly with DuckDB databases and connections through the FFI.
#
#==----------------------------------------------------------------------------------------------==#

(import ./ffi)
(import ./result)
(import ./types)
(use judge)

(defn library-version
  "Get the version of the DuckDB library"
  []
  (ffi/duckdb_library_version))

#==------------------------------------------------------------------------==#
# Configuration Functions
#==------------------------------------------------------------------------==#

(defn config-flags-table
  "Get a table of all available configuration flags and their descriptions"
  []
  (let [name-string-ptr (ffi/write :string "")
        description-string-ptr (ffi/write :string "")]
    (-> (seq [i :range [0 (int/to-number (ffi/duckdb_config_count))]]
          (ffi/duckdb_get_config_flag i name-string-ptr description-string-ptr)
          [(ffi/read :string name-string-ptr) (ffi/read :string description-string-ptr)])
        (from-pairs))))

(comment
  (config-flags-table))

(defn config-flags-show
  "Print all available configuration flags and their descriptions"
  []
  (each [k v] (sort-by first (pairs (config-flags-table)))
    (-> (string/format "%Q%s : %s"
                          (keyword k)
                          (string/repeat " " (max 0 (- 40 (length k))))
                       v)
        (print))))

(comment
  (config-flags-show))

#==------------------------------------------------------------------------==#
# Database Management Functions
#==------------------------------------------------------------------------==#

(defn open "Open a DuckDB database. Accepts an optional `path` and `config` map, e.g.
  {:access_mode :READ_ONLY}. Defaults to \":memory:\" if path is not specified.
  Free with :close."
  [&opt path config-map]

  (default path ":memory:")
  (default config-map {})

  (def config-ptr-ptr (ffi/write :ptr (ffi/write ffi/duckdb_config [nil])))
  (when (= (ffi/duckdb_create_config config-ptr-ptr) ffi/DuckDBError)
    (error "failed to allocate fresh duckdb config"))

  (def database-ptr-ptr (ffi/write :ptr (ffi/write ffi/duckdb_database [nil])))
  (defer (ffi/duckdb_destroy_config config-ptr-ptr)
    (def config-ptr (ffi/read :ptr config-ptr-ptr))
    (eachp [k v] config-map
      (when (= (ffi/duckdb_set_config config-ptr (string k) (string v)) ffi/DuckDBError)
        (error (string/format "cannot set option %q=%q" k v))))

    (def err-string-ptr (ffi/write :string ""))

    (edefer (ffi/duckdb_free err-string-ptr)
      (when (= (ffi/duckdb_open_ext path database-ptr-ptr config-ptr err-string-ptr) ffi/DuckDBError)
        (error (ffi/read :string err-string-ptr)))))

  {:ptr (ffi/read :ptr database-ptr-ptr)
   :close (fn [_] (ffi/duckdb_close database-ptr-ptr))})

(defn connect
  "Create a connection to a database. Free with :close."
  [database]

  (def conn-ptr-ptr (ffi/write :ptr (ffi/write ffi/duckdb_connection [nil])))
  (when (= (ffi/duckdb_connect (database :ptr) conn-ptr-ptr) ffi/DuckDBError)
    (error "failed to create connection to duckdb database"))

  {:ptr (ffi/read :ptr conn-ptr-ptr)
   :close (fn [_] (ffi/duckdb_disconnect conn-ptr-ptr))})

#==------------------------------------------------------------------------==#
# Query Execution Functions
#==------------------------------------------------------------------------==#

(defn interrupt
  "Interrupt a query to the specified connection"
  [connection]
  (ffi/duckdb_interrupt (connection :ptr)))

(defn query-progress
  "Get the progress of the current query for the specified connection"
  [connection]
  (ffi/duckdb_query_progress (connection :ptr)))

(defn query
  "Execute a SQL query on a DuckDB connection and return the result. Free with :close."
  [connection query-string]

  (def result-ptr (ffi/write ffi/duckdb_result [0 0 0 nil nil nil]))

  (when (= (ffi/duckdb_query (connection :ptr) query-string result-ptr) ffi/DuckDBError)
    (error (string
              (ffi/duckdb_error_type_key (ffi/duckdb_result_error_type result-ptr))
              ":"
              (ffi/duckdb_result_error result-ptr))))

  (result/make-result result-ptr))


#==------------------------------------------------------------------------==#
# Convenience Functions
#==------------------------------------------------------------------------==#

(defn query-rows
  "Execute a SQL query and return results as an array of rows (structs by default).
   Supports keyword arguments from result/columns-to-rows
   (:keywordize default true, :coll-type default :struct)."
  [connection query-string &keys {:keywordize keywordize :coll-type coll-type}]
  (default keywordize true)
  (default coll-type :struct)
  (with [result (query connection query-string)]
    (result/columns-to-rows (result/fetch-columns result)
                            :keywordize keywordize
                            :coll-type coll-type)))

(defn query-first
  "Execute a SQL query and return the first row, or nil if no rows.
   Accepts same keyword args as query-rows."
  [connection query-string &keys {:keywordize keywordize :coll-type coll-type}]
  (default keywordize true)
  (default coll-type :struct)
  (first (query-rows connection query-string
                     :keywordize keywordize
                     :coll-type coll-type)))

(defn execute-sql
  "Execute a SQL statement (DDL/DML) and return the number of rows changed."
  [connection sql-string]
  (with [result (query connection sql-string)]
    (result/rows-changed result)))
