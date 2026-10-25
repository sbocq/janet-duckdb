# DuckDB type conversion utilities
(import ./ffi)
(use judge)


#==------------------------------------------------------------------------==#
# Basic Type Conversions
#==------------------------------------------------------------------------==#

(defn- janet-bytes-from-string
  "Convert a duckdb string to a byte buffer."
  [duckdb-string]
  (def [[len data]] duckdb-string)

  (if (<= len 12)
    (tuple/slice data 0 len)
    (ffi/read @[:char len] (ffi/duckdb_string_t_data (ffi/write ffi/duckdb_string_t duckdb-string)))))

(defn- janet-from-string
  "Convert a duckdb string to a Janet string"
  [duckdb-string]
  (string/from-bytes ;(janet-bytes-from-string duckdb-string)))

(defn- janet-from-blob
  "Convert a duckdb string to a Janet string"
  [duckdb-string]
  (tuple/slice (janet-bytes-from-string duckdb-string)))

(def n64-min (int/s64 math/int-min))
(def n64-max (int/s64 math/int-max))

(defn- janet-from-int64 [s64]
  # Shameful attempt to shove a int64 into double-sized hole for convenience until we have 128bits
  # support.
  (if (<= n64-min s64 n64-max)
    (int/to-number s64)
    s64))

#==------------------------------------------------------------------------==#
# Date/Time Type Conversions
#==------------------------------------------------------------------------==#

(defn- janet-date-to-duckdb_date-time-tuple
  "Convert a Janet date struct to DuckDB date and time offsets"
  [janet-date]

  (def {:year year :month month :month-day month-day
        :hours hour :minutes min :seconds sec :micros micros} janet-date)

  [(when year
     [year (inc month) (inc month-day)])
   (when hour
     [hour min sec (or micros 0)])])

(test (janet-date-to-duckdb_date-time-tuple
        {:dst false :hours 14 :minutes 42 :month 5
         :month-day 24 :seconds 20 :week-day 3 :year 2025 :year-day 175})
  [[2025 6 25] [14 42 20 0]])

(defn- janet-date-from-duckdb_date-time-tuple
  "Convert DuckDB date and time offsets to a Janet date struct"
  [[date time]]

  (-> (merge
        (if date
          (let [[year month day] date]
            {:year year
             :month (dec month)
             :month-day (dec day)})
          {})
        (if time
          (let [[hour min sec micros] time]
            {:hours hour
             :minutes min
             :seconds sec
             :micros micros})
          {}))
      table/to-struct))

##==
(defn janet-to-date
  "Convert a Janet date struct to a DuckDB date"
  [janet-date]

  (def [date _] (janet-date-to-duckdb_date-time-tuple janet-date))

  (if date
    (ffi/duckdb_to_date date)
    (error (string/format "no date in %q" janet-date))))

(defn janet-from-date
  "Convert a DuckDB date to a Janet date struct"
  [date]
  (janet-date-from-duckdb_date-time-tuple [(ffi/duckdb_from_date date) nil]))

(test (-> (janet-to-date {:year 1977 :month 02 :month-day 26})
          (janet-from-date))
  {:month 2 :month-day 26 :year 1977})

(test (-> (janet-to-date {:dst false :hours 14 :minutes 42 :month 5
                          :month-day 24 :seconds 20 :week-day 3 :year 2025 :year-day 175})
          (janet-from-date))
  {:month 5 :month-day 24 :year 2025})

##==
(defn janet-to-time
  "Convert a Janet date struct to a DuckDB time"
  [janet-date]

  (def [_ time] (janet-date-to-duckdb_date-time-tuple janet-date))

  (if time
    (ffi/duckdb_to_time time)
    (error (string/format "no time in %q" janet-date))))

(defn janet-from-time
  "Convert a DuckDB time to a Janet date struct"
  [duckdb-time]

  (janet-date-from-duckdb_date-time-tuple [nil (ffi/duckdb_from_time duckdb-time)]))

(test (-> (janet-to-time {:dst false :hours 14 :minutes 42 :month 5
                          :month-day 24 :seconds 20 :week-day 3 :year 2025 :year-day 175})
          (janet-from-time))
  {:hours 14
   :micros 0
   :minutes 42
   :seconds 20})

##==
(defn janet-to-time-tz
  "Convert a Janet date struct in seconds to a DuckDB time-tz. Optionally set timezone offset with
  by strapping a :timezone-offset <seconds> to the date struct e.g. 3600 for UTC+1."
  [janet-date]

  (def [_ time] (janet-date-to-duckdb_date-time-tuple janet-date))

  (if time
    (let [[micros] (ffi/duckdb_to_time time)]
      #janet date is in UTC. The :session-timezone-offset is used to set the time's timezone offset
      (ffi/duckdb_create_time_tz micros (or (janet-date :timezone-offset) 0)))
    (error (string/format "no time in %q" janet-date))))

(defn janet-from-time-tz
  "Convert a DuckDB time to a Janet date struct (UTC time with session timezone context)
  The :session-timezone-offset indicates the session timezone for display purposes."
  [duckdb-time-tz]

  (let [[duckdb-time-struct session-timezone-offset] (ffi/duckdb_from_time_tz duckdb-time-tz)
        [local-micros] (ffi/duckdb_to_time duckdb-time-struct)
        # Convert local microseconds to UTC by subtracting the session timezone offset
        utc-micros (- local-micros (* session-timezone-offset 1_000_000))
        # Handle overflow (next day)
        utc-micros (if (pos? utc-micros) utc-micros (+ utc-micros (* 24 3600 1_000_000)))
        utc-time-struct (janet-date-from-duckdb_date-time-tuple
                          [nil (ffi/duckdb_from_time [utc-micros]) nil])]

    (merge utc-time-struct {:session-timezone-offset session-timezone-offset})))

# 14:00 UTC+1 = 13:00 UTC
(test (-> (janet-to-time-tz {:dst false :hours 14 :minutes 42 :month 5
                             :month-day 24 :seconds 20 :week-day 3 :year 2025 :year-day 175
                             :timezone-offset 3600})
          (janet-from-time-tz))
  @{:hours 13
    :micros 0
    :minutes 42
    :seconds 20
    :session-timezone-offset 3600})

##==
(defn janet-from-timestamp [duckdb-timestamp]
  # See ffi/duckdb_timestamp, ffi/duckdb_timestamp_s and ffi/duckdb_timestamp_ms
  (int/to-number (first duckdb-timestamp)))

(defn janet-from-timestamp-ns [duckdb-timestamp]
  # See ffi/duckdb_timestamp_ns, s64 can't be safely cast to a double precision Janet number.
  (let [s64 (first duckdb-timestamp)]
    (janet-from-int64 s64)))

(defn janet-from-interval [duckdb-interval]
  (def [months days micros] duckdb-interval)
  {:months months :days days :micros (janet-from-int64 micros)})

#==------------------------------------------------------------------------==#

# Decimal Type Conversions
#==------------------------------------------------------------------------==#

(defn janet-from-decimal
  "Convert a DuckDB decimal to a Janet number"
  [duckdb-decimal]
  (ffi/duckdb_decimal_to_double duckdb-decimal))

(defn type-id-to-key [type-id]
  (case type-id
    ffi/DUCKDB_TYPE_BOOLEAN :bool
    ffi/DUCKDB_TYPE_TINYINT :tinyint
    ffi/DUCKDB_TYPE_SMALLINT :smallint
    ffi/DUCKDB_TYPE_INTEGER :int
    ffi/DUCKDB_TYPE_BIGINT :bigint
    ffi/DUCKDB_TYPE_UTINYINT :utinyint
    ffi/DUCKDB_TYPE_USMALLINT :usmallint
    ffi/DUCKDB_TYPE_UINTEGER :uint
    ffi/DUCKDB_TYPE_UBIGINT :ubigint
    ffi/DUCKDB_TYPE_FLOAT :float
    ffi/DUCKDB_TYPE_DOUBLE :double
    ffi/DUCKDB_TYPE_TIMESTAMP :timestamp
    ffi/DUCKDB_TYPE_DATE :date
    ffi/DUCKDB_TYPE_TIME :time
    ffi/DUCKDB_TYPE_INTERVAL :interval
    ffi/DUCKDB_TYPE_HUGEINT :hugeint
    ffi/DUCKDB_TYPE_UHUGEINT :uhugeint
    ffi/DUCKDB_TYPE_VARCHAR :varchar
    ffi/DUCKDB_TYPE_BLOB :blob
    ffi/DUCKDB_TYPE_DECIMAL :decimal
    ffi/DUCKDB_TYPE_TIMESTAMP_S :timestamp_s
    ffi/DUCKDB_TYPE_TIMESTAMP_MS :timestamp_ms
    ffi/DUCKDB_TYPE_TIMESTAMP_NS :timestamp_ns
    ffi/DUCKDB_TYPE_ENUM :enum
    ffi/DUCKDB_TYPE_LIST :list
    ffi/DUCKDB_TYPE_STRUCT :struct
    ffi/DUCKDB_TYPE_MAP :map
    ffi/DUCKDB_TYPE_ARRAY :array
    ffi/DUCKDB_TYPE_UUID :uuid
    ffi/DUCKDB_TYPE_UNION :union
    ffi/DUCKDB_TYPE_BIT :bit
    ffi/DUCKDB_TYPE_TIME_TZ :time_tz
    ffi/DUCKDB_TYPE_TIMESTAMP_TZ :timestamp_tz
    ffi/DUCKDB_TYPE_ANY :any
    ffi/DUCKDB_TYPE_BIGNUM :bignum
    ffi/DUCKDB_TYPE_SQLNULL :sqlnull
    ffi/DUCKDB_TYPE_STRING_LITERAL :string_literal
    ffi/DUCKDB_TYPE_INTEGER_LITERAL :integer_literal
    (error (string/format "type unknown: %q" (ffi/duckdb_type_key type-id)))))

(defn- type-key-mappings
  "Return type metadata for a type-key.
  Simple types: {:type-key-type :simple :type-key tk :metadata {:ffi-data-type f :janet-from-value j}}
  Complex types: {:type-key-type :complex :type-key tk}"
  [type-key]

  (def [ffi-data-type janet-from-value]
    (case type-key
      :bool [:bool nil]
      :tinyint [:int8 nil]
      :smallint [:int16 nil]
      :int [:int32 nil]
      :bigint [:int64 janet-from-int64]
      :utinyint [:uint8 nil]
      :usmallint [:uint16 nil]
      :uint [:uint32 nil]
      :ubigint [:uint64 int/to-number]
      :float [:float nil]
      :double [:double nil]
      :timestamp [ffi/duckdb_timestamp janet-from-timestamp]
      :date [ffi/duckdb_date janet-from-date]
      :time [ffi/duckdb_time janet-from-time]
      :interval [ffi/duckdb_interval janet-from-interval]
      :hugeint [ffi/duckdb_hugeint ffi/duckdb_hugeint_to_double]
      :uhugeint [ffi/duckdb_uhugeint ffi/duckdb_uhugeint_to_double]
      :varchar [ffi/duckdb_string_t janet-from-string]
      :blob [ffi/duckdb_string_t janet-from-blob]
      :decimal [nil nil]
      :timestamp_s [ffi/duckdb_timestamp_s janet-from-timestamp]
      :timestamp_ms [ffi/duckdb_timestamp_ms janet-from-timestamp]
      :timestamp_ns [ffi/duckdb_timestamp_ns janet-from-timestamp-ns]
      :enum [nil nil]
      :list [nil nil]
      :struct [nil nil]
      :map [nil nil]
      :array [nil nil]
      :uuid [ffi/duckdb_hugeint nil]
      :union [nil nil]
      :bit [ffi/duckdb_bit_t nil]
      :time_tz [ffi/duckdb_time_tz janet-from-time-tz]
      :timestamp_tz [ffi/duckdb_timestamp janet-from-timestamp]
      :any [nil nil]
      :bignum [ffi/duckdb_bignum_t nil]
      # DuckDB 2.0's NULL type: vectors are all-NULL by definition, the data
      # type is never dereferenced (dummy :int64 makes this a "simple" type).
      :sqlnull [:int64 nil]
      :string_literal [:string nil]
      :integer_literal [:int64 int/to-number]
      (error (string/format "type unknown: %q" type-key))))

  (if ffi-data-type
    {:type-key-type :simple :type-key type-key
     :metadata {:ffi-data-type ffi-data-type :janet-from-value janet-from-value}}
    {:type-key-type :complex :type-key type-key}))

# Internal — used by result.janet, db.janet and prepare.janet. Not part of public API.
(defn destroy-logical-type-ptr [logical-type-ptr]
  (ffi/duckdb_destroy_logical_type (ffi/write :ptr logical-type-ptr)))

# Internal — used by result.janet and db.janet. Not part of public API.
(defn logical-type-from-ptr [logical-type-ptr]
  (def type-key (type-id-to-key (ffi/duckdb_get_type_id logical-type-ptr)))
  (def key-mappings (type-key-mappings type-key))

  (case (key-mappings :type-key-type)
    :simple
    key-mappings
    :complex
    (case type-key
      :decimal
      (let [internal-type-id (ffi/duckdb_decimal_internal_type logical-type-ptr)
            scale (ffi/duckdb_decimal_scale logical-type-ptr)]
        {:type-key-type :complex :type-key type-key
         :metadata {:scale scale :internal-type-key (type-id-to-key internal-type-id)}})

      :enum
      (let [internal-type-id (ffi/duckdb_enum_internal_type logical-type-ptr)
            enum-size (int/to-number (ffi/duckdb_enum_dictionary_size logical-type-ptr))
            dict (table/new enum-size)]
        (for i 0 enum-size
          (def enum-val-ptr (ffi/duckdb_enum_dictionary_value logical-type-ptr i))
          (defer (ffi/duckdb_free enum-val-ptr)
            (put dict i (ffi/deref-c-string-ptr enum-val-ptr))))
        {:type-key-type :complex :type-key type-key
         :metadata {:dict (table/to-struct dict)
                    :internal-type-key (type-id-to-key internal-type-id)}})

      :list
      (let [child-type-ptr (ffi/duckdb_list_type_child_type logical-type-ptr)]
        (defer (destroy-logical-type-ptr child-type-ptr)
          {:type-key-type :complex :type-key type-key
           :metadata {:child-type (logical-type-from-ptr child-type-ptr)}}))

      :struct
      (let [struct-size (int/to-number (ffi/duckdb_struct_type_child_count logical-type-ptr))
            struct-keys (array/new struct-size)
            struct-types (array/new struct-size)]
        # collect struct field names and values
        (for i 0 struct-size
          (def struct-name-ptr (ffi/duckdb_struct_type_child_name logical-type-ptr i))
          (defer (ffi/duckdb_free struct-name-ptr)
            (array/push struct-keys (keyword (ffi/deref-c-string-ptr struct-name-ptr))))
          (def child-type-ptr (ffi/duckdb_struct_type_child_type logical-type-ptr i))
          (defer (destroy-logical-type-ptr child-type-ptr)
            (let [child-type (logical-type-from-ptr child-type-ptr)]
              (array/push struct-types child-type))))
        {:type-key-type :complex :type-key type-key
         :metadata {:keys (tuple/slice struct-keys)
                    :key-types (tuple/slice struct-types)}})

      :map
      {:type-key-type :complex :type-key type-key
       :metadata {:key-type (let [key-type-ptr (ffi/duckdb_map_type_key_type logical-type-ptr)]
                              (defer (destroy-logical-type-ptr key-type-ptr)
                                (logical-type-from-ptr key-type-ptr)))
                  :val-type (let [val-type-ptr (ffi/duckdb_map_type_value_type logical-type-ptr)]
                              (defer (destroy-logical-type-ptr val-type-ptr)
                                  (logical-type-from-ptr val-type-ptr)))}}

      :array
      (let [array-size (int/to-number (ffi/duckdb_array_type_array_size logical-type-ptr))
            child-type-ptr (ffi/duckdb_array_type_child_type logical-type-ptr)]
        (defer (destroy-logical-type-ptr child-type-ptr)
          {:type-key-type :complex :type-key type-key
           :metadata {:child-type (logical-type-from-ptr child-type-ptr) :array-size array-size}}))

      :union
      (let [union-size (int/to-number (ffi/duckdb_union_type_member_count logical-type-ptr))
            union-tags (array/new union-size)
            union-types (array/new union-size)]
        # collect union field names and values
        (for i 0 union-size
          (def union-name-ptr (ffi/duckdb_union_type_member_name logical-type-ptr i))
          (defer (ffi/duckdb_free union-name-ptr)
            (put union-tags i (keyword (ffi/deref-c-string-ptr union-name-ptr))))
          (def child-type-ptr (ffi/duckdb_union_type_member_type logical-type-ptr i))
          (defer (destroy-logical-type-ptr child-type-ptr)
            (put union-types i (logical-type-from-ptr child-type-ptr))))
        {:type-key-type :complex :type-key type-key
         :metadata {:tag-keys (slice union-tags)
                    :tag-types (slice union-types)}})

      # Default
      (error (string/format "type not supported: %q" type-key)))))

(defn logical-type-simplify
  "Simplify a logical-type-meta structure for human consumption.
  Simple types become just a keyword, complex types become [type-key metadata]."
  [logical-type]

  (def type-key (logical-type :type-key))

  (case (logical-type :type-key-type)
    :simple
    type-key

    :complex
    (let [meta (logical-type :metadata)]
      [type-key (case type-key
                  :struct
                  {:keys (meta :keys)
                   :key-types (tuple/slice (map logical-type-simplify (meta :key-types)))}

                  :union
                  {:tag-keys (meta :tag-keys)
                   :tag-types (slice (map logical-type-simplify (meta :tag-types)))}

                  :list
                  {:child-type (logical-type-simplify (meta :child-type))}

                  :map
                  {:key-type (logical-type-simplify (meta :key-type))
                   :val-type (logical-type-simplify (meta :val-type))}

                  :array
                  {:child-type (logical-type-simplify (meta :child-type))
                   :array-size (meta :array-size)}

                  # Default
                  meta)])))

# Internal — called by janet-array-from-vector. Not part of public API.
(defn janet-array-from-data [data-ptr ffi-data-type offset len validity-mask
                             &keys {:cast-fn cast-fn}]
  (assert ffi-data-type)

  (def sz (ffi/size ffi-data-type))

  (if (nil? validity-mask)
    # All valid
    (let [duckdb-array (ffi/read @[ffi-data-type len] data-ptr (* offset sz))]
      (if cast-fn
        (let [janet-array (array/new len)]
          (eachp [idx duckdb-value] duckdb-array
            (put janet-array idx (cast-fn duckdb-value)))
          janet-array)
        duckdb-array))
    # Some invalid (todo: optimize row-is-valid with 64 rows at a time)
    (let [janet-array (array/new len)
          cast-fn (or cast-fn identity)]
      (var row-idx offset)
      (for i 0 len
        (put janet-array i (when (ffi/duckdb_validity_row_is_valid validity-mask row-idx)
                             (cast-fn (ffi/read ffi-data-type data-ptr (* row-idx sz)))))
        (+= row-idx 1))
      janet-array)))
# Internal — used by result.janet. Not part of public API.

(defn janet-array-from-vector [duckdb-vector-ptr offset len]
  (def logical-type-ptr (ffi/duckdb_vector_get_column_type duckdb-vector-ptr))
  (defer (destroy-logical-type-ptr logical-type-ptr)
    (def logical-type (logical-type-from-ptr logical-type-ptr))
    (def meta (logical-type :metadata))
    (def validity-mask (ffi/duckdb_vector_get_validity duckdb-vector-ptr))
    (def data-ptr (ffi/duckdb_vector_get_data duckdb-vector-ptr))

    (case (logical-type :type-key-type)
      :simple
      (janet-array-from-data data-ptr (meta :ffi-data-type) offset len validity-mask
                             :cast-fn (meta :janet-from-value))
      :complex
      (let [type-key (logical-type :type-key)]
        (case type-key
          :decimal
          (let [scale (math/pow 10 (meta :scale))
                internal-meta ((type-key-mappings (meta :internal-type-key)) :metadata)]
            (janet-array-from-data data-ptr (internal-meta :ffi-data-type) offset len validity-mask
                                   :cast-fn (if-let [jf (internal-meta :janet-from-value)]
                                              (fn [v] (/ (jf v) scale))
                                              (fn [v] (/ v scale)))))

          :enum
          (let [internal-meta ((type-key-mappings (meta :internal-type-key)) :metadata)]
            (janet-array-from-data data-ptr (internal-meta :ffi-data-type) offset len validity-mask
                                   :cast-fn (meta :dict)))

          :list
          (let [child-vector-ptr (ffi/duckdb_list_vector_get_child duckdb-vector-ptr)]
            (seq [list-entry :in (janet-array-from-data data-ptr ffi/duckdb_list_entry
                                                        offset len validity-mask)]
              (when list-entry
                (def [offset len] list-entry)
                (janet-array-from-vector child-vector-ptr
                                         (int/to-number offset) (int/to-number len)))))

          :struct
          (let [struct-keys (meta :keys)
                struct-size (length struct-keys)
                struct-vals (array/new struct-size)]
            # collect struct field values
            (for i 0 struct-size
              (array/push struct-vals (janet-array-from-vector
                                        (ffi/duckdb_struct_vector_get_child duckdb-vector-ptr i)
                                        offset
                                        len)))
            # create structs excepted for null rows
            (var row-idx (dec offset))
            (seq [i :range [0 len]]
              (when (ffi/duckdb_validity_row_is_valid validity-mask (+= row-idx 1))
                (struct ;(mapcat array struct-keys (map |(get $0 i) struct-vals))))))

          :map
          # Internally map vectors are stored as a LIST[STRUCT(key KEY_TYPE, value VALUE_TYPE)].
          (let [child-vector-ptr (ffi/duckdb_list_vector_get_child duckdb-vector-ptr)]
            (seq [list-entry :in (janet-array-from-data data-ptr ffi/duckdb_list_entry
                                                        offset len validity-mask)]
              (when list-entry
                (def [offset len] list-entry)
                (def kv-structs (janet-array-from-vector child-vector-ptr
                                                         (int/to-number offset)
                                                         (int/to-number len)))
                (def tbl (table/new (length kv-structs)))
                (loop [{:key key :value val} :in kv-structs]
                  (put tbl key val))
                tbl)))

          :array
          (let [array-size (meta :array-size)
                child-vector-ptr (ffi/duckdb_array_vector_get_child duckdb-vector-ptr)]
            (var row-idx (dec offset))
            (seq [offset :range [offset (+ offset (* len array-size)) array-size]]
              (when (ffi/duckdb_validity_row_is_valid validity-mask (+= row-idx 1))
                (tuple/slice (janet-array-from-vector child-vector-ptr offset array-size)))))

          :union
          # Under the hood, UNION types are implemented on top of STRUCT types, and simply keep the
          # “tag” as the first entry.
          (let [{:tag-keys tag-keys :tag-types tag-types} meta
                struct-size (inc (length tag-keys))
                struct-vals (array/new struct-size)]

            (for i 0 struct-size
              (array/push struct-vals (janet-array-from-vector
                                        (ffi/duckdb_struct_vector_get_child duckdb-vector-ptr i)
                                        offset
                                        len)))
            # create tagged union [<tag> <val>]
            (def tag-ids (struct-vals 0))
            (var row-idx (dec offset))
            (seq [i :range [0 len]]
              (when (ffi/duckdb_validity_row_is_valid validity-mask (+= row-idx 1))
                (def tag-id (get tag-ids i))
                [(tag-keys tag-id) ((struct-vals (inc tag-id)) i)])))

          # Default
          (error (string/format "type not supported: %q" type-key)))))))
