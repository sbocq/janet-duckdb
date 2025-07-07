#==----------------------------------------------------------------------------------------------==#
#
# All functions that deal directly with DuckDB databases and connections through the FFI.
#
#==----------------------------------------------------------------------------------------------==#

(import ./ffi)
(import ./result)
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
  (let [out-name (ffi/write :ptr nil)
        out-description (ffi/write :ptr nil)]
    (-> (seq [i :range [0 (int/to-number (ffi/duckdb_config_count))]]
          (ffi/duckdb_get_config_flag i out-name out-description)
          [(ffi/read :string out-name) (ffi/read :string out-description)])
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
(defn dbg [x] (pp [x (type x)]) x)

(defn open "Open a DuckDB database. Accepts an optional `path` and `config` map e.g.  {:access_mode
  :READ_ONLY}. Deafults to \":memory:\" id path is not sepcified. The caller is responsible to use
  :close method to close the DB."
  [&opt path config-map]

  (default path ":memory:")
  (default config-map {})

  (def config-ptr (ffi/write ffi/duckdb_config [nil]))
  (when (= (ffi/duckdb_create_config config-ptr) ffi/DuckDBError)
    (error "Failed to allocate fresh duckdb config"))

  (def db-ptr (ffi/write ffi/duckdb_database [nil]))
  (defer (ffi/duckdb_destroy_config config-ptr)
    (def duckdb-config (ffi/read ffi/duckdb_config config-ptr))

    (eachp [k v] config-map
      (when (= (ffi/duckdb_set_config duckdb-config (string k) (string v)) ffi/DuckDBError)
        (error (string/format "Cannot set option %q=%q" k v))))

    (def err-ptr (ffi/write :ptr nil))

    (edefer (ffi/duckdb_free err-ptr)
      (when (= (ffi/duckdb_open_ext path db-ptr duckdb-config err-ptr) ffi/DuckDBError)
        (error (ffi/read :string err-ptr)))))

  {:ptr db-ptr
   :struct (ffi/read ffi/duckdb_database db-ptr)
   :close (fn [self] (ffi/duckdb_close (self :ptr)))})

(defn connect
  "Create a connection to a database.Caller is responsible to use :close method to disconnect"
  [database]

  (def conn-ptr (ffi/write :ptr nil))
  (when (= (ffi/duckdb_connect (database :struct) conn-ptr) ffi/DuckDBError)
    (error "Failed to create connection to DuckDB database"))

  {:ptr conn-ptr
   :struct (ffi/read ffi/duckdb_connection conn-ptr)
   :close (fn [self] (ffi/duckdb_disconnect (self :ptr)))})

#==------------------------------------------------------------------------==#
# Query Execution Functions
#==------------------------------------------------------------------------==#

(defn interrupt
  "Interrupt a query to the specified connection"
  [connection]
  (ffi/duckdb_interrupt (connection :struct)))

(defn query-progress
  "Get the progress of the current query for the specified connection"
  [connection]
  (ffi/duckdb_query_progress (connection :struct)))

(defn query
  "Execute a SQL query on a DuckDB connection and return the result.
   Caller is responsible to use :close method to destroy the result."
  [connection query-string]

  (def result-ptr (ffi/write ffi/duckdb_result [0 0 0 nil nil nil]))

  (edefer (ffi/duckdb_destroy_result result-ptr)
    (when (= (ffi/duckdb_query (connection :struct) query-string result-ptr) ffi/DuckDBError)
      (error (string
               (ffi/duckdb_error_type_key (ffi/duckdb_result_error_type result-ptr))
               ":"
               (ffi/duckdb_result_error result-ptr)))))

  (result/make-result result-ptr))

#TODO: Bind values...
(defn prepare
  "Create a prepared statement object from a query. Caller is responsible to use :close method to
 destroy the prepared statement.
A prepared statement is a parameterized query that allows you to bind parameters to it.
* This is useful to easily supply parameters to functions and avoid SQL injection attacks.
* This is useful to speed up queries that you will execute several times with different parameters.
Because the query will only be parsed, bound, optimized and planned once during the prepare stage,
rather than once per execution.
"
  [connection query]

  (def prepared-statement-ptr (ffi/write ffi/duckdb_prepared_statement [nil]))

  (edefer (ffi/duckdb_destroy_prepare prepared-statement-ptr)
    (when (= (ffi/duckdb_prepare (connection :struct) query prepared-statement-ptr) ffi/DuckDBError)
      (error (ffi/duckdb_prepare-error
               (ffi/read ffi/duckdb_prepared_statement prepared-statement-ptr)))))

  {:ptr prepared-statement-ptr
   :struct (ffi/read ffi/duckdb_prepared_statement prepared-statement-ptr)
   :close (fn [self] (ffi/duckdb_destroy_prepare (self :ptr)))})

(defn execute-prepared
  "Executes the prepared statement with the given bound parameters, and returns a materialized query result.
This method can be called multiple times for each prepared statement, and the parameters can be modified
between calls to this function.
   Caller is responsible to use :close method to destroy the result."
  [prepared-statement]

  (def result-ptr (ffi/write ffi/duckdb_result [0 0 0 nil nil nil]))

  (edefer (ffi/duckdb_destroy_result result-ptr)
    (when (= (ffi/duckdb_execute_prepared (prepared-statement :struct) result-ptr)
             ffi/DuckDBError)
      (error (ffi/duckdb_result_error result-ptr))))

  (result/make-result result-ptr))
