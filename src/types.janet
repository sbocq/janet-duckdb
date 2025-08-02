# DuckDB type conversion utilities
(import ./ffi)
(use judge)

(defn dbg [x] (pp [x (type x)]) x)

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

(defn janet-from-string
  "Convert a duckdb string to a Janet string"
  [duckdb-string]
  (string/from-bytes ;(janet-bytes-from-string duckdb-string)))

(defn janet-from-blob
  "Convert a duckdb string to a Janet string"
  [duckdb-string]
  (tuple/slice (janet-bytes-from-string duckdb-string)))

(def n64-min (int/s64 math/int-min))
(def n64-max (int/s64 math/int-max))

(defn janet-from-int64 [s64]
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
  [duckdb-date]

  (def {:year year :month month :month-day month-day
        :hours hour :minutes min :seconds sec :micros micros} duckdb-date)

  [(when year
     [year (inc month) (inc month-day)])
   (when hour
     [hour min sec (or micros 0)])])

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

(defn janet-to-date
  "Convert a Janet date struct to a DuckDB date"
  [duckdb-date]

  (def [date _] (janet-date-to-duckdb_date-time-tuple duckdb-date))

  (if date
    (ffi/duckdb_to_date date)
    (error (string/format "No date in '%q'" duckdb-date))))

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

(defn janet-to-time
  "Convert a Janet date struct to a DuckDB time"
  [duckdb-date]
  
  (def [_ time] (janet-date-to-duckdb_date-time-tuple duckdb-date))
  
  (if time
    (ffi/duckdb_to_time time)
    (error (string/format "No time in '%q'" duckdb-date))))

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

(defn janet-from-timestamp [duckdb-timestamp]
  # See ffi/duckdb_timestamp, ffi/duckdb_timestamp_s and ffi/duckdb_timestamp_ms
  (int/to-number (first duckdb-timestamp)))

(defn janet-from-timestamp-ns [duckdb-timestamp]
  # See ffi/duckdb_timestamp_ns, s64 can't be safely case to a double precision Janet number.
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

(defn type-id-spec [type-id]

  (def [type-key ffi-data-type janet-from-value]
    (case type-id
      #
      ffi/DUCKDB_TYPE_BOOLEAN [:bool :bool nil]
      ffi/DUCKDB_TYPE_TINYINT [:tinyint :int8 nil]
      ffi/DUCKDB_TYPE_SMALLINT [:smallint :int16 nil]
      ffi/DUCKDB_TYPE_INTEGER [:int :int32 nil]
      ffi/DUCKDB_TYPE_BIGINT [:bigint :int64 janet-from-int64]
      ffi/DUCKDB_TYPE_UTINYINT [:utinyint :uint8 nil]
      ffi/DUCKDB_TYPE_USMALLINT [:usmallint :uint16 nil]
      ffi/DUCKDB_TYPE_UINTEGER [:uint :uint32 nil]
      ffi/DUCKDB_TYPE_UBIGINT [:ubigint :uint64 int/to-number]
      ffi/DUCKDB_TYPE_FLOAT [:float :float nil]
      ffi/DUCKDB_TYPE_DOUBLE [:double :double nil]
      #
      ffi/DUCKDB_TYPE_TIMESTAMP [:timestamp ffi/duckdb_timestamp janet-from-timestamp]
      ffi/DUCKDB_TYPE_DATE [:date ffi/duckdb_date janet-from-date]
      ffi/DUCKDB_TYPE_TIME [:time ffi/duckdb_time janet-from-time]
      ffi/DUCKDB_TYPE_INTERVAL [:interval ffi/duckdb_interval janet-from-interval]
      ffi/DUCKDB_TYPE_HUGEINT [:hugeint ffi/duckdb_hugeint ffi/duckdb_hugeint_to_double]
      ffi/DUCKDB_TYPE_UHUGEINT [:uhugeint ffi/duckdb_uhugeint ffi/duckdb_uhugeint_to_double]
      ffi/DUCKDB_TYPE_VARCHAR [:varchar ffi/duckdb_string_t janet-from-string]
      ffi/DUCKDB_TYPE_BLOB [:blob ffi/duckdb_string_t janet-from-blob]
      ffi/DUCKDB_TYPE_DECIMAL [:decimal nil nil]
      #
      ffi/DUCKDB_TYPE_TIMESTAMP_S [:timestamp_s ffi/duckdb_timestamp_s janet-from-timestamp]
      ffi/DUCKDB_TYPE_TIMESTAMP_MS [:timestamp_ms ffi/duckdb_timestamp_ms janet-from-timestamp]
      ffi/DUCKDB_TYPE_TIMESTAMP_NS [:timestamp_ns ffi/duckdb_timestamp_ns janet-from-timestamp-ns]
      #
      ffi/DUCKDB_TYPE_ENUM [:enum nil nil]                #OK
      ffi/DUCKDB_TYPE_LIST [:list nil nil]                #OK
      ffi/DUCKDB_TYPE_STRUCT [:struct nil nil]            #OK
      ffi/DUCKDB_TYPE_MAP [:map nil nil]                  #OK
      ffi/DUCKDB_TYPE_ARRAY [:array nil nil]              #OK
      #
      ffi/DUCKDB_TYPE_UUID [:uuid ffi/duckdb_hugeint nil] #TODO
      ffi/DUCKDB_TYPE_UNION [:union nil nil]              #OK
      ffi/DUCKDB_TYPE_BIT [:bit ffi/duckdb_bit_t nil]     #TODO
      ffi/DUCKDB_TYPE_TIME_TZ [:time-tz ffi/duckdb_time_tz janet-from-time]
      ffi/DUCKDB_TYPE_TIMESTAMP_TZ [:timestampz ffi/duckdb_time_tz janet-from-timestamp]
      #
      ffi/DUCKDB_TYPE_ANY [:any nil nil]                     #TODO
      ffi/DUCKDB_TYPE_VARINT [:varint ffi/duckdb_varint nil] #TODO
      ffi/DUCKDB_TYPE_SQLNULL [:sqlnull nil nil]             #TODO
      ffi/DUCKDB_TYPE_STRING_LITERAL [:string_literal :string nil]            #TODO
      ffi/DUCKDB_TYPE_INTEGER_LITERAL [:integer_literal :int64 int/to-number] #TODO
      # ???
      (error (string/format "Type unkown:'%s'" (ffi/duckdb_type_key type-id)))))

  {:type-key type-key :ffi-data-type ffi-data-type :janet-from-value janet-from-value})

(defn destroy-logical-type [logical-type-ptr]
  (ffi/duckdb_destroy_logical_type (ffi/write :ptr logical-type-ptr)))

(defn logical-type-spec [logical-type-ptr]

  (def type-id (ffi/duckdb_get_type_id logical-type-ptr))
  (def type-spec (type-id-spec type-id))
  (def type-key (type-spec :type-key))

  (if-let [ffi-data-type (type-spec :ffi-data-type)]
    # simple types
    type-key
    # complex types
    (case type-id
      ffi/DUCKDB_TYPE_DECIMAL
      type-key
      
      ffi/DUCKDB_TYPE_ENUM
      (let [type-spec (type-id-spec (ffi/duckdb_enum_internal_type logical-type-ptr))
            enum-size (int/to-number (ffi/duckdb_enum_dictionary_size logical-type-ptr))
            dict (table/new enum-size)]
        (for i 0 enum-size
          (def enum-val-ptr (ffi/duckdb_enum_dictionary_value logical-type-ptr i))
          (defer (ffi/duckdb_free enum-val-ptr)
            (put dict i (ffi/deref-c-string-ptr enum-val-ptr))))
        [type-key {:members (tuple/slice (values dict))}])
        
      ffi/DUCKDB_TYPE_LIST
      (let [child-type-ptr (ffi/duckdb_list_type_child_type logical-type-ptr)]
        (defer (destroy-logical-type child-type-ptr)
          [type-key (logical-type-spec child-type-ptr)]))

      ffi/DUCKDB_TYPE_STRUCT
      (let [struct-size (int/to-number (ffi/duckdb_struct_type_child_count logical-type-ptr))
            struct-keys (array/new struct-size)
            struct-types (array/new struct-size)]
        # collect struct field names and values
        (for i 0 struct-size
          (def struct-name-ptr (ffi/duckdb_struct_type_child_name logical-type-ptr i))
          (defer (ffi/duckdb_free struct-name-ptr)
            (put struct-keys i (ffi/deref-c-string-ptr struct-name-ptr)))
          (def child-type-ptr (ffi/duckdb_struct_type_child_type logical-type-ptr i))
          (defer (destroy-logical-type child-type-ptr)
            (put struct-types i (logical-type-spec child-type-ptr))))
        [type-key (struct ;(mapcat array struct-keys struct-types))])
      
      ffi/DUCKDB_TYPE_MAP
      # Internally map vectors are stored as a LIST[STRUCT(key KEY_TYPE, value VALUE_TYPE)].
      (let [child-type-ptr (ffi/duckdb_list_type_child_type logical-type-ptr)]
        (defer (destroy-logical-type child-type-ptr)
          (def [_ {"key" key-type "value" val-type}] (logical-type-spec child-type-ptr))
          [type-key {key-type val-type}]))

      ffi/DUCKDB_TYPE_ARRAY
      (let [array-size (int/to-number (ffi/duckdb_array_type_array_size logical-type-ptr))]
        (def child-type-ptr (ffi/duckdb_array_type_child_type logical-type-ptr))
        (defer (destroy-logical-type child-type-ptr)
          [type-key [(logical-type-spec child-type-ptr) array-size]]))

      ffi/DUCKDB_TYPE_UNION
      (let [union-size (int/to-number (ffi/duckdb_union_type_member_count logical-type-ptr))
            union-tags (array/new union-size)
            union-types (array/new union-size)]
        # collect union field names and values
        (for i 0 union-size
          (def union-name-ptr (ffi/duckdb_union_type_member_name logical-type-ptr i))
          (defer (ffi/duckdb_free union-name-ptr)
            (put union-tags i (keyword (ffi/deref-c-string-ptr union-name-ptr))))
          (def child-type-ptr (ffi/duckdb_union_type_member_type logical-type-ptr i))
          (defer (destroy-logical-type child-type-ptr)
            (put union-types i (logical-type-spec child-type-ptr))))
        [type-key (struct ;(mapcat array union-tags union-types))])
        
      # Default
      (error (string/format "Type not supported:'%s'" (type-spec :type-key)))))
  )

(defn janet-array-from-data [data-ptr validity-mask ffi-data-type janet-from-value offset len]
  (assert ffi-data-type)

  (def sz (ffi/size ffi-data-type))

  (if (nil? validity-mask)
    # All valid
    (let [duckdb-array (ffi/read @[ffi-data-type len] data-ptr (* offset sz))]
      (if janet-from-value
        # janet-from-value required
        (let [janet-array (array/new len)]
          (eachp [idx duckdb-value] duckdb-array
            (put janet-array idx (janet-from-value duckdb-value)))
          janet-array)
        # Same binary representation
        duckdb-array))
    # Some invalid (todo: optimize row-is-valid with 64 rows at a time)
    (let [janet-array (array/new len)
          janet-from-value (or janet-from-value identity)]
      (var row-idx offset)
      (for i 0 len
        (put janet-array i (when (ffi/duckdb_validity_row_is_valid validity-mask row-idx)
                             (janet-from-value (ffi/read ffi-data-type data-ptr (* row-idx sz)))))
        (+= row-idx 1))
      janet-array)))

(defn janet-array-from-vector [duckdb-vector-ptr offset len]

  (def logical-type-ptr (ffi/duckdb_vector_get_column_type duckdb-vector-ptr))
  (defer (destroy-logical-type logical-type-ptr)
    (def type-id (ffi/duckdb_get_type_id logical-type-ptr))
    (def type-spec (type-id-spec type-id))
  
    (def validity-mask (ffi/duckdb_vector_get_validity duckdb-vector-ptr))
    (def data-ptr (ffi/duckdb_vector_get_data duckdb-vector-ptr))

    (if-let [ffi-data-type (type-spec :ffi-data-type)]
      # simple types
      (janet-array-from-data data-ptr
                             validity-mask
                             ffi-data-type
                             (type-spec :janet-from-value)
                             offset
                             len)
      # logical types
      (case type-id
        ffi/DUCKDB_TYPE_DECIMAL
        (let [scale (math/pow 10 (ffi/duckdb_decimal_scale logical-type-ptr))
              type-spec (type-id-spec (ffi/duckdb_decimal_internal_type logical-type-ptr))]
          (janet-array-from-data data-ptr
                                 validity-mask
                                 (type-spec :ffi-data-type)
                                 (if-let [janet-from-value (type-spec :janet-from-value)]
                                   (fn [v] (/ (janet-from-value v) scale))
                                   (fn [v] (/ v scale)))
                                 offset
                                 len))
      
        ffi/DUCKDB_TYPE_ENUM
        (let [type-spec (type-id-spec (ffi/duckdb_enum_internal_type logical-type-ptr))
              enum-size (int/to-number (ffi/duckdb_enum_dictionary_size logical-type-ptr))
              dict (table/new enum-size)]
          (for i 0 enum-size
            (def enum-val-ptr (ffi/duckdb_enum_dictionary_value logical-type-ptr i))
            (defer (ffi/duckdb_free enum-val-ptr)
              (put dict i (ffi/deref-c-string-ptr enum-val-ptr))))
          (janet-array-from-data data-ptr
                                 validity-mask
                                 (type-spec :ffi-data-type)
                                 dict
                                 offset
                                 len))
        
        ffi/DUCKDB_TYPE_LIST
        (let [child-vector-ptr (ffi/duckdb_list_vector_get_child duckdb-vector-ptr)]
          (seq [list-entry :in (janet-array-from-data data-ptr
                                                      validity-mask
                                                      ffi/duckdb_list_entry
                                                      nil
                                                      offset
                                                      len)]
            (when list-entry
              (def [offset len] list-entry)
              (janet-array-from-vector child-vector-ptr (int/to-number offset) (int/to-number len)))))

        ffi/DUCKDB_TYPE_STRUCT
        (let [struct-size (int/to-number (ffi/duckdb_struct_type_child_count logical-type-ptr))
              struct-keys (array/new struct-size)
              struct-vals (array/new struct-size)]
          # collect struct field names and values
          (for i 0 struct-size
            (def struct-name-ptr (ffi/duckdb_struct_type_child_name logical-type-ptr i))
            (defer (ffi/duckdb_free struct-name-ptr)
              (put struct-keys i (keyword (ffi/deref-c-string-ptr struct-name-ptr))))
            (put struct-vals i (janet-array-from-vector
                                 (ffi/duckdb_struct_vector_get_child duckdb-vector-ptr i)
                                 offset
                                 len)))

          # create structs excepted for null rows
          (var row-idx (dec offset))
          (seq [i :range [0 len]]
            (when (ffi/duckdb_validity_row_is_valid validity-mask (+= row-idx 1))
              (struct ;(mapcat array struct-keys (map |(get $0 i) struct-vals))))))
      
        ffi/DUCKDB_TYPE_MAP
        # Internally map vectors are stored as a LIST[STRUCT(key KEY_TYPE, value VALUE_TYPE)].
        (let [child-vector-ptr (ffi/duckdb_list_vector_get_child duckdb-vector-ptr)]
          (seq [list-entry :in (janet-array-from-data data-ptr
                                                      validity-mask
                                                      ffi/duckdb_list_entry
                                                      nil
                                                      offset
                                                      len)]
            (when list-entry
              (def [offset len] list-entry)
              (def kv-structs (janet-array-from-vector child-vector-ptr
                                                       (int/to-number offset)
                                                       (int/to-number len)))
              (def tbl (table/new (length kv-structs)))
              (loop [{:key key :value val} :in kv-structs]
                (put tbl key val))
              tbl)))

        ffi/DUCKDB_TYPE_ARRAY
        (let [array-size (int/to-number (ffi/duckdb_array_type_array_size logical-type-ptr))
              child-vector-ptr (ffi/duckdb_array_vector_get_child duckdb-vector-ptr)]
          (var row-idx (dec offset))
          (seq [offset :range [offset (+ offset (* len array-size)) array-size]]
            (when (ffi/duckdb_validity_row_is_valid validity-mask (+= row-idx 1))
              (tuple/slice (janet-array-from-vector child-vector-ptr offset array-size)))))

        ffi/DUCKDB_TYPE_UNION
        (let [struct-size (int/to-number (ffi/duckdb_struct_type_child_count logical-type-ptr))
              struct-keys (array/new struct-size)
              struct-vals (array/new struct-size)]
          # collect struct field names and values
          (for i 0 struct-size
            (def struct-name-ptr (ffi/duckdb_struct_type_child_name logical-type-ptr i))
            (defer (ffi/duckdb_free struct-name-ptr)
              (put struct-keys i (keyword (ffi/deref-c-string-ptr struct-name-ptr))))
            (put struct-vals i (janet-array-from-vector
                                 (ffi/duckdb_struct_vector_get_child duckdb-vector-ptr i)
                                 offset
                                 len)))
          (def union-count (int/to-number (ffi/duckdb_union_type_member_count logical-type-ptr)))
          (def tag-id-to-key (table/new union-count))
          (def tag-key-to-id (table/new union-count))
          (def tag-id-to-val-idx (table/new union-count))

          # collect tag ids
          (for i 0 union-count
            (def union-tag-ptr (ffi/duckdb_union_type_member_name logical-type-ptr i))
            (defer (ffi/duckdb_free union-tag-ptr)
              (let [tag-key (keyword (ffi/deref-c-string-ptr union-tag-ptr))]
                (put tag-id-to-key i tag-key)
                (put tag-key-to-id tag-key i))))
          # map a tag-id to the index of a struct column
          (eachp [i struct-key] struct-keys
            (put tag-id-to-val-idx (tag-key-to-id struct-key) i))

          # create tagged union [<tag> <val>]
          (def tag-column (struct-vals 0))
          (var row-idx (dec offset))
          (seq [i :range [0 len]]
            (when (ffi/duckdb_validity_row_is_valid validity-mask (+= row-idx 1))
              (def tag-id (get tag-column i))
              [(tag-id-to-key tag-id) ((struct-vals (tag-id-to-val-idx tag-id)) i)])))
        
        # Default
        (error (string/format "Type not supported:'%s'" (type-spec :type-key)))))))
