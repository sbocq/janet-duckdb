#==----------------------------------------------------------------------------------------------==#
#
# All functions that deal directly with DuckDB results.
#
#==----------------------------------------------------------------------------------------------==#

(import ./ffi)
(import ./types)

#==------------------------------------------------------------------------==#
# Result Functions
#==------------------------------------------------------------------------==#

#==------------------------------------------------------------------------==#
# Clean keyword mappings for DuckDB enum types
#==------------------------------------------------------------------------==#

(def result-type-map
  # Map DuckDB result type integers to clean Janet keywords
  {ffi/DUCKDB_RESULT_TYPE_INVALID      :invalid
   ffi/DUCKDB_RESULT_TYPE_CHANGED_ROWS :changed-rows
   ffi/DUCKDB_RESULT_TYPE_NOTHING      :nothing
   ffi/DUCKDB_RESULT_TYPE_QUERY_RESULT :query-result})

(def statement-type-map
  # Map DuckDB statement type integers to clean Janet keywords
  {ffi/DUCKDB_STATEMENT_TYPE_INVALID     :invalid
   ffi/DUCKDB_STATEMENT_TYPE_SELECT      :select
   ffi/DUCKDB_STATEMENT_TYPE_INSERT      :insert
   ffi/DUCKDB_STATEMENT_TYPE_UPDATE      :update
   ffi/DUCKDB_STATEMENT_TYPE_DELETE      :delete
   ffi/DUCKDB_STATEMENT_TYPE_CREATE      :create
   ffi/DUCKDB_STATEMENT_TYPE_EXPLAIN     :explain
   ffi/DUCKDB_STATEMENT_TYPE_PREPARE     :prepare
   ffi/DUCKDB_STATEMENT_TYPE_EXECUTE     :execute
   ffi/DUCKDB_STATEMENT_TYPE_ALTER       :alter
   ffi/DUCKDB_STATEMENT_TYPE_TRANSACTION :transaction
   ffi/DUCKDB_STATEMENT_TYPE_COPY        :copy
   ffi/DUCKDB_STATEMENT_TYPE_ANALYZE     :analyze
   ffi/DUCKDB_STATEMENT_TYPE_DROP        :drop
   ffi/DUCKDB_STATEMENT_TYPE_EXPORT      :export
   ffi/DUCKDB_STATEMENT_TYPE_PRAGMA      :pragma
   ffi/DUCKDB_STATEMENT_TYPE_VACUUM      :vacuum
   ffi/DUCKDB_STATEMENT_TYPE_CALL        :call
   ffi/DUCKDB_STATEMENT_TYPE_SET         :set
   ffi/DUCKDB_STATEMENT_TYPE_LOAD        :load
   ffi/DUCKDB_STATEMENT_TYPE_RELATION    :relation
   ffi/DUCKDB_STATEMENT_TYPE_EXTENSION   :extension
   ffi/DUCKDB_STATEMENT_TYPE_LOGICAL_PLAN :logical-plan
   ffi/DUCKDB_STATEMENT_TYPE_ATTACH      :attach
   ffi/DUCKDB_STATEMENT_TYPE_DETACH      :detach
   ffi/DUCKDB_STATEMENT_TYPE_MULTI       :multi})


(defn make-result
  "Create a result object from a DuckDB result pointer.
  Free with :close."
  [result-ptr]
  (def column-count (int/to-number (ffi/duckdb_column_count result-ptr)))
  (def column-names (array/new column-count))
  (def column-types (array/new column-count))

  # cache names and simple types. Names are needed anyway later to fetch columns while simple type
  # info is cheap and useful for debugging.
  (loop [i :range [0 column-count]]
    (array/push column-names (ffi/duckdb_column_name result-ptr i))
    (array/push column-types (-> (ffi/duckdb_column_type result-ptr i)
                                 (types/type-id-to-key))))

  (var valid true)

  {:column-count column-count
   :column-names (tuple/slice column-names)
   :column-types (tuple/slice column-types)
   :ptr result-ptr
   :struct (ffi/read ffi/duckdb_result result-ptr)
   :close (fn [self]
            (:assert-valid self)
            (ffi/duckdb_destroy_result (self :ptr))
            (set valid false)
            nil)
   :assert-valid (fn [self]
                   (unless valid
                     (error "result already closed")))})

(defn rows-changed
  "Get the number of rows changed in a DuckDB result"
  [result]
  (:assert-valid result)
  (int/to-number (ffi/duckdb_rows_changed (result :ptr))))

(defn return-type
  "Get the return type of a DuckDB result — :query-result, :changed-rows, :nothing, or :invalid."
  [result]
  (:assert-valid result)
  (get result-type-map (ffi/duckdb_result_return_type (result :struct))))

(defn statement-type
  "Get the statement type of a DuckDB result — :select, :insert, :create, etc."
  [result]
  (:assert-valid result)
  (get statement-type-map (ffi/duckdb_result_statement_type (result :struct))))

(defn describe-columns
  "Fetch count, names and types of the columns of a `result`. By default, it returns the simple
  types. Pass `:logical-type true` as an extra keyword argument to have it retrieve the full logical
  types of the columns."

  [result &keys {:logical-type logical-type}]

  (:assert-valid result)

  (default logical-type false)

  (def {:column-count column-count
        :column-names column-names
        :column-types column-types} result)

  {:column-count column-count
   :column-names column-names
   :column-types (if logical-type
                   (-> (let [result-ptr (result :ptr)]
                         (seq [i :range [0 column-count]]
                           (def logical-type-ptr (ffi/duckdb_column_logical_type result-ptr i))
                           (defer (types/destroy-logical-type-ptr logical-type-ptr)
                             (-> (types/logical-type-from-ptr logical-type-ptr)
                                 (types/logical-type-simplify)))))
                       (tuple/slice))
                   column-types)})

(defn- make-columns-result [column-count column-names column-types columns row-count]
  {:column-count column-count
   :column-names column-names
   :column-types column-types
   :columns columns
   :row-count row-count
   :column (let [name-to-column (struct ;(mapcat array column-names columns))]
             (fn :column-from-name [self name] (name-to-column name)))})

(defn fetch-columns
  "Fetch all column values from a DuckDB result."
  [result]

  (:assert-valid result)

  (def {:column-count column-count
        :column-names column-names
        :column-types column-types
        :struct result-struct} result)

  (def columns (array/new column-count))

  # Prepare table with arrays that we will append to
  (for i 0 column-count
    (array/push columns @[]))

  # Process data chunks
  (loop [data-chunk-ptr :iterate (ffi/duckdb_fetch_chunk result-struct)
         :until (nil? data-chunk-ptr)]
    (defer (ffi/duckdb_destroy_data_chunk (ffi/write :ptr data-chunk-ptr))
      (def chunk-size (int/to-number (ffi/duckdb_data_chunk_get_size data-chunk-ptr)))

      # Process each column in the chunk
      (for col-idx 0 column-count
        (let [col-vector-ptr (ffi/duckdb_data_chunk_get_vector data-chunk-ptr col-idx)]
          (def array (types/janet-array-from-vector col-vector-ptr 0 chunk-size))
          (array/concat (columns col-idx) array)))))

  (make-columns-result column-count column-names column-types columns (length (columns 0))))

(defn generate-columns
  "Generate columns in chunks from a DuckDB result."
  [result]

  (:assert-valid result)

  (def {:column-count column-count
        :column-names column-names
        :column-types column-types
        :struct result-struct} result)

  # Track chunck offset and size across generations
  (var chunk-offset 0)
  (var chunk-size 0)

  # Process data chunks
  (generate [data-chunk-ptr :iterate (ffi/duckdb_fetch_chunk result-struct)
             :until (nil? data-chunk-ptr)]
    (+= chunk-offset chunk-size)

    (def columns (array/new column-count))

    (defer (ffi/duckdb_destroy_data_chunk (ffi/write :ptr data-chunk-ptr))
      (set chunk-size (int/to-number (ffi/duckdb_data_chunk_get_size data-chunk-ptr)))

      # Process each column in the chunk
      (for col-idx 0 column-count
        (let [col-vector-ptr (ffi/duckdb_data_chunk_get_vector data-chunk-ptr col-idx)
              array (types/janet-array-from-vector col-vector-ptr 0 chunk-size)]
          (array/push columns array))))

    (-> (make-columns-result column-count column-names column-types columns chunk-size)
        (struct/to-table)
        (put :chunk-offset chunk-offset)
        (table/to-struct))))

(defn columns-to-rows
  "convert columns result to rows result. The optional parameter `coll-type` (default `:struct`) can be one of `:tuple`,`struct`,`array` or `table`. If `keywordize` (default `true`) then column names are converted to keywords."
  [columns &keys {:keywordize keywordize
                  :coll-type coll-type}]

  (default keywordize true)
  (default coll-type :struct)

  (def {:column-count column-count
        :column-names column-names
        :columns columns
        :row-count row-count} columns)

  (def rows (array/new row-count))
  (def dict-keys (if (and keywordize (or (= coll-type :struct) (= coll-type :table)))
                   (map keyword column-names)
                   column-names))

  (case coll-type
    :table
    (for row-idx 0 row-count
      (def row (table/new column-count))
      (eachp [col-idx column] columns
        (put row (dict-keys col-idx) (column row-idx)))
      (array/push rows row))

    :struct
    (let [row (table/new column-count)]
      (for row-idx 0 row-count
        (eachp [col-idx column] columns
          (put row (dict-keys col-idx) (column row-idx)))
        (array/push rows (table/to-struct row))
        (table/clear row)))

    :tuple
    (let [row (array/new column-count)]
      (for row-idx 0 row-count
        (loop [column :in columns]
          (array/push row (column row-idx)))
        (array/push rows (tuple/slice row))
        (array/clear row)))

    :array
    (for row-idx 0 row-count
      (def row (array/new column-count))
      (loop [column :in columns]
        (array/push row (column row-idx)))
      (array/push rows row))

    (error (string/format "coll-type must be one of :table :struct :tuple :array, got %q"
                          coll-type)))

  rows)
