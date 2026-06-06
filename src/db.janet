#==----------------------------------------------------------------------------------------------==#
#
# All functions that deal directly with DuckDB databases and connections through the FFI.
#
#==----------------------------------------------------------------------------------------------==#

(import ./ffi)
(import ./prepare)
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
(defn- dbg [x] (pp [x (type x)]) x)

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

(defn prepare
  "Create a prepared statement object from a query. Free with :close.

The prepared statement object caches parameter metadata (:param-count, :param-names, :param-types)
for efficient access.
"
  [connection query]

  (def prepared-statement-ptr-ptr (ffi/write :ptr (ffi/write ffi/duckdb_prepared_statement [nil])))

  (when (= (ffi/duckdb_prepare (connection :ptr) query prepared-statement-ptr-ptr) ffi/DuckDBError)
    (error (ffi/duckdb_prepare_error (ffi/read :ptr prepared-statement-ptr-ptr))))

  (def prepared-ptr (ffi/read :ptr prepared-statement-ptr-ptr))

  # Cache parameter metadata for efficient access
  (def param-count (int/to-number (ffi/duckdb_nparams prepared-ptr)))
  (def param-names (array/new param-count))
  (def param-types (array/new param-count))

  (for i 1 (inc param-count)
    (def param-name-ptr (ffi/duckdb_parameter_name prepared-ptr i))
    (array/push param-names (defer (ffi/duckdb_free param-name-ptr)
                              (keyword (ffi/deref-c-string-ptr param-name-ptr))))

    (def logical-type-ptr (ffi/duckdb_param_logical_type prepared-ptr i))
    (defer (types/destroy-logical-type-ptr logical-type-ptr)
      (array/push param-types (-> (types/logical-type-from-ptr logical-type-ptr)
                                  (types/logical-type-simplify)))))

  {:ptr prepared-ptr
   :param-count param-count
   :param-names (tuple/slice param-names)
   :param-types (tuple/slice param-types)
   :close (fn [self] (ffi/duckdb_destroy_prepare prepared-statement-ptr-ptr))})

(defn execute-prepared
  "Execute a prepared statement. If params are provided, bind them first.

   Positional parameters:
     (db/execute-prepared stmt [1 \"Alice\"])

   Named parameters:
     (db/execute-prepared stmt {:id 1 :name \"Alice\"})

   No parameters:
     (db/execute-prepared stmt)
 Free with :close."
  
  [prepared-statement &opt params]
  (default params [])

  (cond
    (indexed? params)
    (eachp [i v] params
      (prepare/bind prepared-statement (inc i) v))

    (dictionary? params)
    (eachp [k v] params
      (prepare/bind-named prepared-statement (string k) v))

    (error (string/format "params must be an array/tuple or struct/table, got %T" params)))

  (def result-ptr (ffi/write ffi/duckdb_result [0 0 0 nil nil nil]))

  (when (= (ffi/duckdb_execute_prepared (prepared-statement :ptr) result-ptr)
            ffi/DuckDBError)
    (error (ffi/duckdb_result_error result-ptr)))

  (result/make-result result-ptr))

#==------------------------------------------------------------------------==#
# Prepared Statement Util Functions
#==------------------------------------------------------------------------==#

(defn clear-prepared-bindings
  "Clear all parameter bindings from a prepared statement."
  [prepared-statement]
  (ffi/duckdb_clear_bindings (prepared-statement :ptr)))
