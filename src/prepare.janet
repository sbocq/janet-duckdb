# Prepared statement parameter binding functions.
(import ./ffi)
(import ./types)
(import ./result)
(use judge)

#==--------------------------------------------------------------------==#
# Value creation helpers (moved from types.janet)
# Only called by janet-to-duckdb-value.
#==--------------------------------------------------------------------==#

(defn- janet-to-interval-value
  "Convert a Janet interval struct to a duckdb_value.
  Free with (ffi/duckdb_destroy_value (ffi/write :ptr v))."
  [{:months months :days days :micros micros}]
  (ffi/duckdb_create_interval [months days micros]))

(test (let [v (janet-to-interval-value {:months 1 :days 2 :micros 3000000})
            duckdb-interval (ffi/duckdb_get_interval v)]
        (ffi/duckdb_destroy_value (ffi/write :ptr v))
        (types/janet-from-interval duckdb-interval))
  {:months 1 :days 2 :micros 3000000})

(defn- janet-to-timestamp-value
  "Convert a Janet number (epoch microseconds) to a duckdb_value.
  Free with (ffi/duckdb_destroy_value (ffi/write :ptr v))."
  [epoch-micros]
  (ffi/duckdb_create_timestamp [epoch-micros]))

(test (let [v (janet-to-timestamp-value 1705305600000000)
            duckdb-ts (ffi/duckdb_get_timestamp v)]
        (ffi/duckdb_destroy_value (ffi/write :ptr v))
        (types/janet-from-timestamp duckdb-ts))
  1705305600000000)

(defn- janet-to-date-value
  "Convert a Janet date struct to a duckdb_value.
  Free with (ffi/duckdb_destroy_value (ffi/write :ptr v))."
  [janet-date]
  (ffi/duckdb_create_date (types/janet-to-date janet-date)))

(test (let [v (janet-to-date-value {:year 2025 :month 0 :month-day 15})
            duckdb-date (ffi/duckdb_get_date v)]
        (ffi/duckdb_destroy_value (ffi/write :ptr v))
        (types/janet-from-date duckdb-date))
  {:month 0 :month-day 15 :year 2025})

(defn- janet-to-time-value
  "Convert a Janet time struct to a duckdb_value.
  Free with (ffi/duckdb_destroy_value (ffi/write :ptr v))."
  [janet-time]
  (ffi/duckdb_create_time (types/janet-to-time janet-time)))

(test (let [v (janet-to-time-value {:hours 14 :minutes 42 :seconds 20 :micros 0})
            duckdb-time (ffi/duckdb_get_time v)]
        (ffi/duckdb_destroy_value (ffi/write :ptr v))
        (types/janet-from-time duckdb-time))
  {:hours 14 :minutes 42 :seconds 20 :micros 0})

(defn- janet-to-time-tz-value
  "Convert a Janet time-tz struct to a duckdb_value.
  Free with (ffi/duckdb_destroy_value (ffi/write :ptr v))."
  [janet-date]
  (ffi/duckdb_create_time_tz_value (types/janet-to-time-tz janet-date)))

(test (let [v (janet-to-time-tz-value {:hours 14 :minutes 42 :seconds 20 :micros 0
                                        :timezone-offset 3600})
            duckdb-ttz (ffi/duckdb_get_time_tz v)]
        (ffi/duckdb_destroy_value (ffi/write :ptr v))
        (types/janet-from-time-tz duckdb-ttz))
  @{:hours 13
    :minutes 42
    :seconds 20
    :micros 0
    :session-timezone-offset 3600})

(defn- janet-to-timestamp-tz-value
  "Convert a Janet number (epoch microseconds) to a duckdb_value as TIMESTAMP_TZ.
  Free with (ffi/duckdb_destroy_value (ffi/write :ptr v))."
  [epoch-micros]
  (ffi/duckdb_create_timestamp_tz [epoch-micros]))

(test (let [v (janet-to-timestamp-tz-value 1705305600000000)
            duckdb-ts (ffi/duckdb_get_timestamp_tz v)]
        (ffi/duckdb_destroy_value (ffi/write :ptr v))
        (types/janet-from-timestamp duckdb-ts))
  1705305600000000)

(defn- janet-to-timestamp-s-value
  "Convert a Janet number (epoch seconds) to a duckdb_value as TIMESTAMP_S.
  Free with (ffi/duckdb_destroy_value (ffi/write :ptr v))."
  [epoch-seconds]
  (ffi/duckdb_create_timestamp_s [epoch-seconds]))

(test (let [v (janet-to-timestamp-s-value 1705305600)
            duckdb-ts (ffi/duckdb_get_timestamp_s v)]
        (ffi/duckdb_destroy_value (ffi/write :ptr v))
        (types/janet-from-timestamp duckdb-ts))
  1705305600)

(defn- janet-to-timestamp-ms-value
  "Convert a Janet number (epoch milliseconds) to a duckdb_value as TIMESTAMP_MS.
  Free with (ffi/duckdb_destroy_value (ffi/write :ptr v))."
  [epoch-millis]
  (ffi/duckdb_create_timestamp_ms [epoch-millis]))

(test (let [v (janet-to-timestamp-ms-value 1705305600000)
            duckdb-ts (ffi/duckdb_get_timestamp_ms v)]
        (ffi/duckdb_destroy_value (ffi/write :ptr v))
        (types/janet-from-timestamp duckdb-ts))
  1705305600000)

(defn- janet-to-timestamp-ns-value
  "Convert a Janet number (epoch nanoseconds) to a duckdb_value as TIMESTAMP_NS.
  Free with (ffi/duckdb_destroy_value (ffi/write :ptr v))."
  [epoch-nanos]
  (ffi/duckdb_create_timestamp_ns [epoch-nanos]))

(test (let [v (janet-to-timestamp-ns-value 1000)
            duckdb-ts (ffi/duckdb_get_timestamp_ns v)]
        (ffi/duckdb_destroy_value (ffi/write :ptr v))
        (types/janet-from-timestamp-ns duckdb-ts))
  1000)


(defn- janet-to-duckdb-value
  "Convert a Janet value to a duckdb_value pointer given a simplified type
   and its corresponding logical-type-ptr.

   simplified-type is either a keyword (simple) or [type-key metadata] (complex).
   logical-type-ptr is the duckdb_logical_type for this value's type.

   For complex types, child logical types are extracted from logical-type-ptr
   via FFI and destroyed after recursing.

   Returns a duckdb_value pointer. Caller must destroy with:
     (ffi/duckdb_destroy_value (ffi/write :ptr value-ptr))"
  [janet-value simplified-type logical-type-ptr]

  (cond
    (nil? janet-value)
    (ffi/duckdb_create_null_value)

    (keyword? simplified-type)
    (case simplified-type
      :bool (ffi/duckdb_create_bool janet-value)
      :tinyint (ffi/duckdb_create_int8 janet-value)
      :smallint (ffi/duckdb_create_int16 janet-value)
      :int (ffi/duckdb_create_int32 janet-value)
      :bigint (ffi/duckdb_create_int64 janet-value)
      :utinyint (ffi/duckdb_create_uint8 janet-value)
      :usmallint (ffi/duckdb_create_uint16 janet-value)
      :uint (ffi/duckdb_create_uint32 janet-value)
      :ubigint (ffi/duckdb_create_uint64 janet-value)
      :float (ffi/duckdb_create_float janet-value)
      :double (ffi/duckdb_create_double janet-value)
      :varchar (ffi/duckdb_create_varchar janet-value)
      :blob (ffi/duckdb_create_varchar janet-value)
      :date (janet-to-date-value janet-value)
      :time (janet-to-time-value janet-value)
      :timestamp (janet-to-timestamp-value janet-value)
      :interval (janet-to-interval-value janet-value)
      (error (string/format "unsupported simple type for value creation: %q" simplified-type)))

    (tuple? simplified-type)
    (let [[type-key meta] simplified-type]
      (case type-key
        :struct
        (let [field-keys (meta :keys)
              field-types (meta :key-types)
              field-count (length field-keys)
              field-ptrs (array/new field-count)]
          (defer (each v field-ptrs (ffi/duckdb_destroy_value (ffi/write :ptr v)))
            (for i 0 field-count
              (def field-key (field-keys i))
              (def field-type (field-types i))
              (def field-value (janet-value field-key))
              (def child-type-ptr (ffi/duckdb_struct_type_child_type logical-type-ptr i))
              (defer (types/destroy-logical-type-ptr child-type-ptr)
                (array/push field-ptrs
                            (janet-to-duckdb-value field-value field-type child-type-ptr))))

            (def values-ptr (ffi/write @[:ptr field-count] field-ptrs))
            (ffi/duckdb_create_struct_value logical-type-ptr values-ptr)))

        :list
        (let [len (length janet-value)
              child-type (meta :child-type)
              child-type-ptr (ffi/duckdb_list_type_child_type logical-type-ptr)]
          (defer (types/destroy-logical-type-ptr child-type-ptr)
            (if (zero? len)
              (ffi/duckdb_create_list_value child-type-ptr (ffi/write :ptr nil) 0)
              (let [elem-ptrs (array/new len)]
                (defer (each v elem-ptrs (ffi/duckdb_destroy_value (ffi/write :ptr v)))
                  (each v janet-value
                    (array/push elem-ptrs (janet-to-duckdb-value v child-type child-type-ptr)))

                  (def values-ptr (ffi/write @[:ptr len] elem-ptrs))
                  (ffi/duckdb_create_list_value child-type-ptr values-ptr len))))))

        :map
        (let [key-type (meta :key-type)
              val-type (meta :val-type)
              entry-count (length janet-value)]
          (if (zero? entry-count)
            (ffi/duckdb_create_map_value logical-type-ptr
                                         (ffi/write :ptr nil) (ffi/write :ptr nil) 0)
            (do
              (def key-type-ptr (ffi/duckdb_map_type_key_type logical-type-ptr))
              (def val-type-ptr (ffi/duckdb_map_type_value_type logical-type-ptr))
              (defer (do
                       (types/destroy-logical-type-ptr key-type-ptr)
                       (types/destroy-logical-type-ptr val-type-ptr))
                (def key-ptrs (array/new entry-count))
                (def val-ptrs (array/new entry-count))
                (defer (do
                         (each v key-ptrs (ffi/duckdb_destroy_value (ffi/write :ptr v)))
                         (each v val-ptrs (ffi/duckdb_destroy_value (ffi/write :ptr v))))
                  (eachp [k v] janet-value
                    (array/push key-ptrs (janet-to-duckdb-value k key-type key-type-ptr))
                    (array/push val-ptrs (janet-to-duckdb-value v val-type val-type-ptr)))

                  (def keys-ptr (ffi/write @[:ptr entry-count] key-ptrs))
                  (def vals-ptr (ffi/write @[:ptr entry-count] val-ptrs))
                  (ffi/duckdb_create_map_value logical-type-ptr keys-ptr vals-ptr entry-count))))))

        :array
        (let [child-type (meta :child-type)
              expected-size (meta :array-size)]
          (when (not= (length janet-value) expected-size)
            (error (string/format "array requires %d elements, got %d"
                                  expected-size (length janet-value))))
          (def child-type-ptr (ffi/duckdb_array_type_child_type logical-type-ptr))
          (defer (types/destroy-logical-type-ptr child-type-ptr)
            (def elem-ptrs (array/new expected-size))
            (defer (each v elem-ptrs (ffi/duckdb_destroy_value (ffi/write :ptr v)))
              (each v janet-value
                (array/push elem-ptrs (janet-to-duckdb-value v child-type child-type-ptr)))

              (def values-ptr (ffi/write @[:ptr expected-size] elem-ptrs))
              (ffi/duckdb_create_array_value child-type-ptr values-ptr expected-size))))

        :union
        (let [tag-keys (meta :tag-keys)
              tag-types (meta :tag-types)
              [tag value] janet-value
              tag-idx (index-of tag tag-keys)]
          (when (nil? tag-idx)
            (error (string/format "union tag %q not found" tag)))
          (def member-type (tag-types tag-idx))
          (def member-type-ptr (ffi/duckdb_union_type_member_type logical-type-ptr tag-idx))
          (defer (types/destroy-logical-type-ptr member-type-ptr)
            (def duckdb-val (janet-to-duckdb-value value member-type member-type-ptr))
            (ffi/duckdb_create_union_value logical-type-ptr tag-idx duckdb-val)))

        (error (string/format "unsupported complex type: %q" type-key))))))

(defn bind
  "Bind a Janet value to a prepared statement parameter by index (1-based)."
  [prepared-statement param-idx janet-value]

  (def prepared-ptr (prepared-statement :ptr))
  (def param-count (prepared-statement :param-count))

  (unless (and (pos? param-idx) (< param-idx (inc param-count)))
    (error (string/format "parameter index %d out of range (statement has %d params)"
                          param-idx param-count)))

  (def cached-type ((prepared-statement :param-types) (dec param-idx)))

  (if (nil? janet-value)
    (when (= (ffi/duckdb_bind_null prepared-ptr param-idx) ffi/DuckDBError)
      (error (string/format "failed to bind NULL to parameter %d" param-idx)))
    (let [logical-type-ptr (ffi/duckdb_param_logical_type prepared-ptr param-idx)]
      (defer (types/destroy-logical-type-ptr logical-type-ptr)
        (def duckdb-value (janet-to-duckdb-value janet-value cached-type logical-type-ptr))
        (defer (ffi/duckdb_destroy_value (ffi/write :ptr duckdb-value))
          (when (= (ffi/duckdb_bind_value prepared-ptr param-idx duckdb-value) ffi/DuckDBError)
            (error (string/format "failed to bind parameter %d" param-idx))))))))

(defn bind-named
  "Bind a Janet value to a prepared statement parameter by name."
  [prepared-statement param-name janet-value]
  (def param-idx-ptr (ffi/write ffi/idx_t 0))
  (when (= (ffi/duckdb_bind_parameter_index (prepared-statement :ptr) param-idx-ptr (string param-name))
           ffi/DuckDBError)
    (error (string/format "parameter %q not found" param-name)))
  (bind prepared-statement (int/to-number (ffi/read ffi/idx_t param-idx-ptr)) janet-value))

#==--------------------------------------------------------------------==#
# Prepared statement lifecycle
#==--------------------------------------------------------------------==#

(defn prepare
  "Create a prepared statement object from a query. Free with :close.

   The prepared statement object caches parameter metadata
   (:param-count, :param-names, :param-types) for efficient access."
  [connection query]

  (def prepared-statement-ptr-ptr (ffi/write :ptr (ffi/write ffi/duckdb_prepared_statement [nil])))

  (when (= (ffi/duckdb_prepare (connection :ptr) query prepared-statement-ptr-ptr)
           ffi/DuckDBError)
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

(defn execute
  "Execute a prepared statement. If params are provided, bind them first.

   Positional parameters:
     (prepare/execute stmt [1 \"Alice\"])

   Named parameters:
     (prepare/execute stmt {:id 1 :name \"Alice\"})

   No parameters:
     (prepare/execute stmt)

   Free with :close."
  [prepared-statement &opt params]
  (default params [])

  (cond
    (indexed? params)
    (eachp [i v] params
      (bind prepared-statement (inc i) v))

    (dictionary? params)
    (eachp [k v] params
      (bind-named prepared-statement (string k) v))

    (error (string/format "params must be an array/tuple or struct/table, got %T" params)))

  (def result-ptr (ffi/write ffi/duckdb_result [0 0 0 nil nil nil]))

  (when (= (ffi/duckdb_execute_prepared (prepared-statement :ptr) result-ptr)
           ffi/DuckDBError)
    (error (ffi/duckdb_result_error result-ptr)))

  (result/make-result result-ptr))

(defn clear-bindings
  "Clear all parameter bindings from a prepared statement."
  [prepared-statement]
  (ffi/duckdb_clear_bindings (prepared-statement :ptr)))
