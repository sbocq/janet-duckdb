#==----------------------------------------------------------------------------------------------==#
# FFI native bindings for libduckdb.so
#
# Make sure libduckdb.so is available on your library path or via the LD_LIBRARY_PATH environment
# variable.
#
# Convention: Snake case is preserved in the FFI interface (e.g. `function_name`, `struct_name`) to
# make it easy to search for symbols and their documentation in the C duckdb.h header file (see
# `doc` folder).
#
#==----------------------------------------------------------------------------------------------==#


(use judge)
(ffi/context "libduckdb.so" :lazy true)

#==------------------------------------------------------------------------==#
# FFI Helper Macros
#==------------------------------------------------------------------------==#

(defmacro defcstruct
  "Defines a C-style structure with a specified name and fields (field names are ignored for now)."
  [name & body]
  (let [types (map 1 (partition 2 body))]
    ~(def ,name (ffi/struct ,;types))))

(defmacro defcenum
  "Generate a C-style enumeration by defining its type name name as :uint8, the associated member
  constants, and a <enum_name>_key struct for converting enum values to keys."
  [enum-name & members]
  (let [to-key-sym (symbol (string enum-name "_key"))
        enum-syms @[]
        val-to-enum-sym @[]]
    ~(upscope
       (def ,enum-name :uint8)
       ,;(seq [[name val] :in (partition 2 members)]
           (array/push enum-syms name)
           (array/push val-to-enum-sym [val name])
           ~(def ,name ,val))
       (def ,to-key-sym (struct ,;(mapcat (fn [[k v]] [k (keyword v)]) val-to-enum-sym))))))

#==------------------------------------------------------------------------==#
# Enums
#==------------------------------------------------------------------------==#

(defcenum duckdb_state
  DuckDBSuccess 0
  DuckDBError 1
  )

(defcenum duckdb_pending_state
  DUCKDB_PENDING_RESULT_READY 0
  DUCKDB_PENDING_RESULT_NOT_READY 1
  DUCKDB_PENDING_ERROR 2
  DUCKDB_PENDING_NO_TASKS_AVAILABLE 3
  )

(defcenum duckdb_result_type
  DUCKDB_RESULT_TYPE_INVALID 0
  DUCKDB_RESULT_TYPE_CHANGED_ROWS 1
  DUCKDB_RESULT_TYPE_NOTHING 2
  DUCKDB_RESULT_TYPE_QUERY_RESULT 3
  )

(defcenum duckdb_statement_type
  DUCKDB_STATEMENT_TYPE_INVALID 0
  DUCKDB_STATEMENT_TYPE_SELECT 1
  DUCKDB_STATEMENT_TYPE_INSERT 2
  DUCKDB_STATEMENT_TYPE_UPDATE 3
  DUCKDB_STATEMENT_TYPE_EXPLAIN 4
  DUCKDB_STATEMENT_TYPE_DELETE 5
  DUCKDB_STATEMENT_TYPE_PREPARE 6
  DUCKDB_STATEMENT_TYPE_CREATE 7
  DUCKDB_STATEMENT_TYPE_EXECUTE 8
  DUCKDB_STATEMENT_TYPE_ALTER 9
  DUCKDB_STATEMENT_TYPE_TRANSACTION 10
  DUCKDB_STATEMENT_TYPE_COPY 11
  DUCKDB_STATEMENT_TYPE_ANALYZE 12
  DUCKDB_STATEMENT_TYPE_VARIABLE_SET 13
  DUCKDB_STATEMENT_TYPE_CREATE_FUNC 14
  DUCKDB_STATEMENT_TYPE_DROP 15
  DUCKDB_STATEMENT_TYPE_EXPORT 16
  DUCKDB_STATEMENT_TYPE_PRAGMA 17
  DUCKDB_STATEMENT_TYPE_VACUUM 18
  DUCKDB_STATEMENT_TYPE_CALL 19
  DUCKDB_STATEMENT_TYPE_SET 20
  DUCKDB_STATEMENT_TYPE_LOAD 21
  DUCKDB_STATEMENT_TYPE_RELATION 22
  DUCKDB_STATEMENT_TYPE_EXTENSION 23
  DUCKDB_STATEMENT_TYPE_LOGICAL_PLAN 24
  DUCKDB_STATEMENT_TYPE_ATTACH 25
  DUCKDB_STATEMENT_TYPE_DETACH 26
  DUCKDB_STATEMENT_TYPE_MULTI 27
  )

(defcenum duckdb_error_type
  DUCKDB_ERROR_INVALID 0
  DUCKDB_ERROR_OUT_OF_RANGE 1
  DUCKDB_ERROR_CONVERSION 2
  DUCKDB_ERROR_UNKNOWN_TYPE 3
  DUCKDB_ERROR_DECIMAL 4
  DUCKDB_ERROR_MISMATCH_TYPE 5
  DUCKDB_ERROR_DIVIDE_BY_ZERO 6
  DUCKDB_ERROR_OBJECT_SIZE 7
  DUCKDB_ERROR_INVALID_TYPE 8
  DUCKDB_ERROR_SERIALIZATION 9
  DUCKDB_ERROR_TRANSACTION 10
  DUCKDB_ERROR_NOT_IMPLEMENTED 11
  DUCKDB_ERROR_EXPRESSION 12
  DUCKDB_ERROR_CATALOG 13
  DUCKDB_ERROR_PARSER 14
  DUCKDB_ERROR_PLANNER 15
  DUCKDB_ERROR_SCHEDULER 16
  DUCKDB_ERROR_EXECUTOR 17
  DUCKDB_ERROR_CONSTRAINT 18
  DUCKDB_ERROR_INDEX 19
  DUCKDB_ERROR_STAT 20
  DUCKDB_ERROR_CONNECTION 21
  DUCKDB_ERROR_SYNTAX 22
  DUCKDB_ERROR_SETTINGS 23
  DUCKDB_ERROR_BINDER 24
  DUCKDB_ERROR_NETWORK 25
  DUCKDB_ERROR_OPTIMIZER 26
  DUCKDB_ERROR_NULL_POINTER 27
  DUCKDB_ERROR_IO 28
  DUCKDB_ERROR_INTERRUPT 29
  DUCKDB_ERROR_FATAL 30
  DUCKDB_ERROR_INTERNAL 31
  DUCKDB_ERROR_INVALID_INPUT 32
  DUCKDB_ERROR_OUT_OF_MEMORY 33
  DUCKDB_ERROR_PERMISSION 34
  DUCKDB_ERROR_PARAMETER_NOT_RESOLVED 35
  DUCKDB_ERROR_PARAMETER_NOT_ALLOWED 36
  DUCKDB_ERROR_DEPENDENCY 37
  DUCKDB_ERROR_HTTP 38
  DUCKDB_ERROR_MISSING_EXTENSION 39
  DUCKDB_ERROR_AUTOLOAD 40
  DUCKDB_ERROR_SEQUENCE 41
  DUCKDB_INVALID_CONFIGURATION 42
  )

(defcenum duckdb_cast_mode
  DUCKDB_CAST_NORMAL 0
  DUCKDB_CAST_TRY 1
  )

(defcenum duckdb_type
  DUCKDB_TYPE_INVALID 0
  DUCKDB_TYPE_BOOLEAN 1
  DUCKDB_TYPE_TINYINT 2
  DUCKDB_TYPE_SMALLINT 3
  DUCKDB_TYPE_INTEGER 4
  DUCKDB_TYPE_BIGINT 5
  DUCKDB_TYPE_UTINYINT 6
  DUCKDB_TYPE_USMALLINT 7
  DUCKDB_TYPE_UINTEGER 8
  DUCKDB_TYPE_UBIGINT 9
  DUCKDB_TYPE_FLOAT 10
  DUCKDB_TYPE_DOUBLE 11
  DUCKDB_TYPE_TIMESTAMP 12
  DUCKDB_TYPE_DATE 13
  DUCKDB_TYPE_TIME 14
  DUCKDB_TYPE_INTERVAL 15
  DUCKDB_TYPE_HUGEINT 16
  DUCKDB_TYPE_UHUGEINT 32
  DUCKDB_TYPE_VARCHAR 17
  DUCKDB_TYPE_BLOB 18
  DUCKDB_TYPE_DECIMAL 19
  DUCKDB_TYPE_TIMESTAMP_S 20
  DUCKDB_TYPE_TIMESTAMP_MS 21
  DUCKDB_TYPE_TIMESTAMP_NS 22
  DUCKDB_TYPE_ENUM 23
  DUCKDB_TYPE_LIST 24
  DUCKDB_TYPE_STRUCT 25
  DUCKDB_TYPE_MAP 26
  DUCKDB_TYPE_ARRAY 33
  DUCKDB_TYPE_UUID 27
  DUCKDB_TYPE_UNION 28
  DUCKDB_TYPE_BIT 29
  DUCKDB_TYPE_TIME_TZ 30
  DUCKDB_TYPE_TIMESTAMP_TZ 31
  DUCKDB_TYPE_ANY 34
  DUCKDB_TYPE_VARINT 35
  DUCKDB_TYPE_SQLNULL 36
  DUCKDB_TYPE_STRING_LITERAL 37
  DUCKDB_TYPE_INTEGER_LITERAL 38
  )

#==------------------------------------------------------------------------==#
# Structs and Types
#==------------------------------------------------------------------------==#
(def idx_t :uint64)

# Days are stored as days since 1970-01-01
# Use the duckdb_from_date/duckdb_to_date function to extract individual information
(defcstruct duckdb_date
  days :int32)

# Date structure with year, month, and day components
(defcstruct duckdb_date_struct
  year :int32
  month :int8
  day :int8)

# Time is stored as microseconds since 00:00:00
# Use the duckdb_from_time/duckdb_to_time function to extract individual information
(defcstruct duckdb_time
  micros :int64)

# Time structure with hour, minute, second, and microsecond components
(defcstruct duckdb_time_struct
  hour :int8
  min :int8
  sec :int8
  micros :int32)

# TIME_TZ is stored as 40 bits for int64_t micros, and 24 bits for int32_t offset
(defcstruct duckdb_time_tz
  bits :uint64)

# Time with timezone structure
(defcstruct duckdb_time_tz_struct
  time duckdb_time_tz
  offset :int32)

# TIMESTAMP values are stored as microseconds since 1970-01-01
# Use the duckdb_from_timestamp and duckdb_to_timestamp functions to extract individual information
(defcstruct duckdb_timestamp
  micros :int64)

# TIMESTAMP_S values are stored as seconds since 1970-01-01
(defcstruct duckdb_timestamp_s
  seconds :int64)

# TIMESTAMP_MS values are stored as milliseconds since 1970-01-01
(defcstruct duckdb_timestamp_ms
  millis :int64)

# TIMESTAMP_NS values are stored as nanoseconds since 1970-01-01
(defcstruct duckdb_timestamp_ns
  nanos :int64)

# Timestamp structure with date and time components
(defcstruct duckdb_timestamp_struct
  date duckdb_date_struct
  time duckdb_time_struct)

# Interval structure with months, days, and microseconds components
(defcstruct duckdb_interval
  months :int32
  days :int32
  micros :int64)

# Hugeints are composed of a (lower, upper) component
# The value of the hugeint is upper * 2^64 + lower
# For easy usage, the functions duckdb_hugeint_to_double/duckdb_double_to_hugeint are recommended
(defcstruct duckdb_hugeint
  lower :uint64
  upper :int64)

# Unsigned hugeint structure
(defcstruct duckdb_uhugeint
  lower :uint64
  upper :uint64)

# Decimals are composed of a width and a scale, and are stored in a hugeint
(defcstruct duckdb_decimal_t
  width :uint8
  scale :uint8
  value duckdb_hugeint)

# A type holding information about the query execution progress
(defcstruct duckdb_query_progress_type
  percentage :double
  rows_processed :uint64
  total_rows_to_process :uint64)

(defcstruct duckdb_column_t
  deprecated_data :ptr
  deprecated_nullmask :ptr
  deprecated_type :ptr
  internal_data :ptr)

(def duckdb_vector :ptr)

# The internal representation of a VARCHAR (string_t)
# If the VARCHAR does not exceed 12 characters, then we inline it
# Otherwise, we inline a prefix for faster string comparisons and store a pointer to the remaining characters
(defcstruct duckdb_string_value_t
  length :uint32
  inlined @[:char 12])

# String type structure
(defcstruct duckdb_string_t
  value duckdb_string_value_t)

# BLOBs are composed of a byte pointer and a size
(defcstruct duckdb_blob_t
  data :ptr
  size idx_t)

# BITs are composed of a byte pointer and a size
# BIT byte data has 0 to 7 bits of padding
(defcstruct duckdb_bit_t
  data :uint8
  size idx_t)

# VARINTs are composed of a byte pointer, a size, and an is_negative bool
# The absolute value of the number is stored in `data` in little endian format
(defcstruct duckdb_varint
  data :uint8
  size idx_t
  is_negative :bool)

# List entry structure
(defcstruct duckdb_list_entry
  offset idx_t
  length idx_t)

# A query result consists of a pointer to its internal data
# Must be freed with 'duckdb_destroy_result'
(defcstruct duckdb_result
  deprecated_column_count idx_t
  deprecated_row_count idx_t
  deprecated_rows_changed idx_t
  deprecated_columns :ptr
  deprecated_error_message :ptr
  internal_data :ptr)

# A database instance cache object
# Must be destroyed with `duckdb_destroy_instance_cache`
(defcstruct duckdb_instance_cache_t
  internal_ptr :ptr)

# A database object
# Must be closed with `duckdb_close`
(defcstruct duckdb_database
  internal_ptr :ptr)

# A connection to a duckdb database
# Must be closed with `duckdb_disconnect`
(defcstruct duckdb_connection
  internal_ptr :ptr)

# A prepared statement is a parameterized query that allows you to bind parameters to it
# Must be destroyed with `duckdb_destroy_prepare`
(defcstruct duckdb_prepared_statement
  internal_ptr :ptr)

# Prepared statements collection
(defcstruct duckdb_prepared_statements
  internal_ptr :ptr)

# Extracted statements
# Must be destroyed with `duckdb_destroy_extracted`
(defcstruct duckdb_extracted_statements
  internal_ptr :ptr)

# The pending result represents an intermediate structure for a query that is not yet fully executed
# Must be destroyed with `duckdb_destroy_pending`
(defcstruct duckdb_pending_result_t
  internal_ptr :ptr)

# The appender enables fast data loading into DuckDB
# Must be destroyed with `duckdb_appender_destroy`
(defcstruct duckdb_appender_t
  internal_ptr :ptr)

# The table description allows querying info about the table
# Must be destroyed with `duckdb_table_description_destroy`
(defcstruct duckdb_table_description_t
  internal_ptr :ptr)

# Can be used to provide start-up options for the DuckDB instance
# Must be destroyed with `duckdb_destroy_config`
(defcstruct duckdb_config
  internal_ptr :ptr)

# Holds an internal logical type
# Must be destroyed with `duckdb_destroy_logical_type`
(defcstruct duckdb_logical_type
  internal_ptr :ptr)

# Contains a data chunk from a duckdb_result
# Must be destroyed with `duckdb_destroy_data_chunk`
(defcstruct duckdb_data_chunk_t
  internal_ptr :ptr)

# Holds a DuckDB value, which wraps a type
# Must be destroyed with `duckdb_destroy_value`
(defcstruct duckdb_value
  internal_ptr :ptr)

# Holds a recursive tree that matches the query plan
(defcstruct duckdb_profiling_info
  internal_ptr :ptr)

#==------------------------------------------------------------------------==#
# FFI Function Bindings
#==------------------------------------------------------------------------==#

# Database management functions
(ffi/defbind duckdb_open :int [path :string out-database :ptr])
(ffi/defbind duckdb_open_ext :int [path :string out-database :ptr config duckdb_config out-error :ptr])
(ffi/defbind duckdb_close :void [database :ptr])

# Connection management functions
(ffi/defbind duckdb_connect :int [database duckdb_database out-connection :ptr])
(ffi/defbind duckdb_interrupt :void [connection duckdb_connection])
(ffi/defbind duckdb_query_progress duckdb_query_progress_type [connection duckdb_connection])
(ffi/defbind duckdb_disconnect :void [connection :ptr])
(ffi/defbind duckdb_library_version :string [])

# Configuration functions
(ffi/defbind duckdb_create_config duckdb_state [out-config :ptr])
(ffi/defbind duckdb_config_count :size [])
(ffi/defbind duckdb_get_config_flag duckdb_state [index :size out-name :ptr out-description :ptr])
(ffi/defbind duckdb_set_config duckdb_state [config duckdb_config name :string option :string])
(ffi/defbind duckdb_destroy_config :void [config :ptr])

# Query execution functions
(ffi/defbind duckdb_query duckdb_state [connection duckdb_connection query :string out-result :ptr])
(ffi/defbind duckdb_destroy_result :void [result :ptr])
(ffi/defbind duckdb_column_name :string [result :ptr col idx_t])
(ffi/defbind duckdb_column_type duckdb_type [result :ptr col idx_t])
(ffi/defbind duckdb_result_statement_type duckdb_statement_type [result duckdb_result])
(ffi/defbind duckdb_column_logical_type duckdb_logical_type [result :ptr col idx_t])
(ffi/defbind duckdb_column_count idx_t [result :ptr])
(ffi/defbind duckdb_rows_changed idx_t [result :ptr])
(ffi/defbind duckdb_result_error :string [result :ptr])
(ffi/defbind duckdb_result_error_type duckdb_error_type [result :ptr])
(ffi/defbind duckdb_result_return_type duckdb_result_type [result duckdb_result])

# Helper functions
(ffi/defbind duckdb_malloc :ptr [size :size])
(ffi/defbind duckdb_free :void [ptr :ptr])
(ffi/defbind duckdb_vector_size idx_t [])
(ffi/defbind duckdb_string_is_inlined :bool [string duckdb_string_t])
(ffi/defbind duckdb_string_t_length :uint32 [string duckdb_string_t])
(ffi/defbind duckdb_string_t_data :string [string :ptr])

# Date/Time/Timestamp helper functions
(ffi/defbind duckdb_from_date duckdb_date_struct [date duckdb_date])
(ffi/defbind duckdb_to_date duckdb_date [date duckdb_date_struct])
(ffi/defbind duckdb_is_finite_date :bool [date duckdb_date])
(ffi/defbind duckdb_from_time duckdb_time_struct [time duckdb_time])
(ffi/defbind duckdb_create_time_tz duckdb_time_tz [micros :int64 offset :int32])
(ffi/defbind duckdb_from_time_tz duckdb_time_tz [micros duckdb_time_tz])
(ffi/defbind duckdb_to_time duckdb_time [time duckdb_time_struct])
(ffi/defbind duckdb_from_timestamp duckdb_timestamp_struct [ts duckdb_timestamp])
(ffi/defbind duckdb_to_timestamp duckdb_timestamp [ts duckdb_timestamp_struct])
(ffi/defbind duckdb_is_finite_timestamp :bool [ts duckdb_timestamp])
(ffi/defbind duckdb_is_finite_timestamp-s :bool [ts duckdb_timestamp_s])
(ffi/defbind duckdb_is_finite_timestamp-ms :bool [ts duckdb_timestamp_ms])
(ffi/defbind duckdb_is_finite_timestamp-ns :bool [ts duckdb_timestamp_ns])

# Hugeint helper functions
(ffi/defbind duckdb_hugeint_to_double :double [val duckdb_hugeint])
(ffi/defbind duckdb_double_to_hugeint duckdb_hugeint [val :double])

# Unsigned hugeint helper functions
(ffi/defbind duckdb_uhugeint_to_double :double [val duckdb_uhugeint])
(ffi/defbind duckdb_double_to_uhugeint duckdb_uhugeint [val :double])

# Decimal helper functions
(ffi/defbind duckdb_double_to_decimal duckdb_decimal_t [val :double width :uint8 scale :uint8])
(ffi/defbind duckdb_decimal_to_double :double [val duckdb_decimal_t])

# Prepared statement functions
(ffi/defbind duckdb_prepare duckdb_state [connection duckdb_connection query :string out-prepared-statement :ptr])
(ffi/defbind duckdb_destroy_prepare :void [prepared-statement :ptr])
(ffi/defbind duckdb_prepare-error :string [prepared-statement duckdb_prepared_statement])
(ffi/defbind duckdb_nparams idx_t [prepared-statement duckdb_prepared_statement])
(ffi/defbind duckdb_parameter_name :string [prepared-statement duckdb_prepared_statement index idx_t])
(ffi/defbind duckdb_param_type duckdb_type [prepared-statement duckdb_prepared_statement param-idx idx_t])
(ffi/defbind duckdb_param_logical_type duckdb_logical_type [prepared-statement duckdb_prepared_statement param-idx idx_t])
(ffi/defbind duckdb_clear_bindings duckdb_state [prepared-statement duckdb_prepared_statement])
(ffi/defbind duckdb_prepared_statementype duckdb_statement_type [statement duckdb_prepared_statement])

# Bind value functions
(ffi/defbind duckdb_bind_value duckdb_state [prepared-statement duckdb_prepared_statement param-idx idx_t val duckdb_value])
(ffi/defbind duckdb_bind_parameter_index duckdb_state [prepared-statement duckdb_prepared_statement param-idx-out :ptr name :string])
(ffi/defbind duckdb_bind_boolean duckdb_state [prepared-statement duckdb_prepared_statement param-idx idx_t val :bool])
(ffi/defbind duckdb_bind_int8 duckdb_state [prepared-statement duckdb_prepared_statement param-idx idx_t val :int8])
(ffi/defbind duckdb_bind_int16 duckdb_state [prepared-statement duckdb_prepared_statement param-idx idx_t val :int16])
(ffi/defbind duckdb_bind_int32 duckdb_state [prepared-statement duckdb_prepared_statement param-idx idx_t val :int32])
(ffi/defbind duckdb_bind_int64 duckdb_state [prepared-statement duckdb_prepared_statement param-idx idx_t val :int64])
(ffi/defbind duckdb_bind_hugeint duckdb_state [prepared-statement duckdb_prepared_statement param-idx idx_t val duckdb_hugeint])
(ffi/defbind duckdb_bind_uhugeint duckdb_state [prepared-statement duckdb_prepared_statement param-idx idx_t val duckdb_uhugeint])
(ffi/defbind duckdb_bind_decimal duckdb_state [prepared-statement duckdb_prepared_statement param-idx idx_t val duckdb_decimal_t])
(ffi/defbind duckdb_bind_uint8 duckdb_state [prepared-statement duckdb_prepared_statement param-idx idx_t val :uint8])
(ffi/defbind duckdb_bind_uint16 duckdb_state [prepared-statement duckdb_prepared_statement param-idx idx_t val :uint16])
(ffi/defbind duckdb_bind_uint32 duckdb_state [prepared-statement duckdb_prepared_statement param-idx idx_t val :uint32])
(ffi/defbind duckdb_bind_uint64 duckdb_state [prepared-statement duckdb_prepared_statement param-idx idx_t val :uint64])
(ffi/defbind duckdb_bind_float duckdb_state [prepared-statement duckdb_prepared_statement param-idx idx_t val :float])
(ffi/defbind duckdb_bind_double duckdb_state [prepared-statement duckdb_prepared_statement param-idx idx_t val :double])
(ffi/defbind duckdb_bind_date duckdb_state [prepared-statement duckdb_prepared_statement param-idx idx_t val duckdb_date])
(ffi/defbind duckdb_bind_time duckdb_state [prepared-statement duckdb_prepared_statement param-idx idx_t val duckdb_time])
(ffi/defbind duckdb_bind_timestamp duckdb_state [prepared-statement duckdb_prepared_statement param-idx idx_t val duckdb_timestamp])
(ffi/defbind duckdb_bind_timestamp-tz duckdb_state [prepared-statement duckdb_prepared_statement param-idx idx_t val duckdb_timestamp])
(ffi/defbind duckdb_bind_interval duckdb_state [prepared-statement duckdb_prepared_statement param-idx idx_t val duckdb_interval])
(ffi/defbind duckdb_bind_varchar duckdb_state [prepared-statement duckdb_prepared_statement param-idx idx_t val :string])
(ffi/defbind duckdb_bind_varchar-length duckdb_state [prepared-statement duckdb_prepared_statement param-idx idx_t val :string length idx_t])
(ffi/defbind duckdb_bind_blob duckdb_state [prepared-statement duckdb_prepared_statement param-idx idx_t data :ptr length idx_t])
(ffi/defbind duckdb_bind_null duckdb_state [prepared-statement duckdb_prepared_statement param-idx idx_t])

# Execute prepared statement functions
(ffi/defbind duckdb_execute_prepared duckdb_state [prepared-statement duckdb_prepared_statement out-result :ptr])

# Extract statements functions
(ffi/defbind duckdb_extract_statements idx_t [connection duckdb_connection query :string out-extracted-statements :ptr])
(ffi/defbind duckdb_prepare-extracted-statement duckdb_state [connection duckdb_connection extracted-statements duckdb_extracted_statements index idx_t out-prepared-statement :ptr])
(ffi/defbind duckdb_extract_statements-error :string [extracted-statements duckdb_extracted_statements])
(ffi/defbind duckdb_destroy_extracted :void [extracted-statements :ptr])

# Pending result functions
(ffi/defbind duckdb_pending_prepared duckdb_state [prepared-statement duckdb_prepared_statement out-result :ptr])
(ffi/defbind duckdb_destroy_pending :void [pending-result :ptr])
(ffi/defbind *duckdb_pending_error :string [pending-result duckdb_pending_result_t])
(ffi/defbind duckdb_pending_execute_task duckdb_pending_state [pending-result duckdb_pending_result_t])
(ffi/defbind duckdb_pending_execute_check_state duckdb_pending_state [pending-result duckdb_pending_result_t])
(ffi/defbind duckdb_execute_pending duckdb_state [pending-result duckdb_pending_result_t out-result :ptr])
(ffi/defbind duckdb_pending_execution_is_finished :bool [pending-state duckdb_pending_state])

# Value functions
(ffi/defbind duckdb_destroy_value :void [value :ptr])
(ffi/defbind duckdb_create_varchar duckdb_value [text :string])
(ffi/defbind duckdb_create_varchar-length duckdb_value [text :string length idx_t])
(ffi/defbind duckdb_create_bool duckdb_value [input :bool])
(ffi/defbind duckdb_create_int8 duckdb_value [input :int8])
(ffi/defbind duckdb_create_int16 duckdb_value [input :int16])
(ffi/defbind duckdb_create_int32 duckdb_value [input :int32])
(ffi/defbind duckdb_create_int64 duckdb_value [input :int64])
(ffi/defbind duckdb_create_hugeint duckdb_value [input duckdb_hugeint])
(ffi/defbind duckdb_create_uhugeint duckdb_value [input duckdb_uhugeint])
(ffi/defbind duckdb_create_uint8 duckdb_value [input :uint8])
(ffi/defbind duckdb_create_uint16 duckdb_value [input :uint16])
(ffi/defbind duckdb_create_uint32 duckdb_value [input :uint32])
(ffi/defbind duckdb_create_uint64 duckdb_value [input :uint64])
(ffi/defbind duckdb_create_float duckdb_value [input :float])
(ffi/defbind duckdb_create_double duckdb_value [input :double])
(ffi/defbind duckdb_create_date duckdb_value [input duckdb_date])
(ffi/defbind duckdb_create_time duckdb_value [input duckdb_time])
(ffi/defbind duckdb_create_timestamp duckdb_value [input duckdb_timestamp])
(ffi/defbind duckdb_create_interval duckdb_value [input duckdb_interval])
(ffi/defbind duckdb_create_null duckdb_value [])
(ffi/defbind duckdb_create_decimal duckdb_value [input duckdb_decimal_t])

# Value extraction functions
(ffi/defbind duckdb_get_varchar :string [value duckdb_value])
(ffi/defbind duckdb_get_varchar-length :string [value duckdb_value])
(ffi/defbind duckdb_get_blob :ptr [value duckdb_value out-length :ptr])
(ffi/defbind duckdb_get_bit :ptr [value duckdb_value out-length :ptr])
(ffi/defbind duckdb_get_bool :bool [value duckdb_value])
(ffi/defbind duckdb_get_int8 :int8 [value duckdb_value])
(ffi/defbind duckdb_get_int16 :int16 [value duckdb_value])
(ffi/defbind duckdb_get_int32 :int32 [value duckdb_value])
(ffi/defbind duckdb_get_int64 :int64 [value duckdb_value])
(ffi/defbind duckdb_get_hugeint duckdb_hugeint [value duckdb_value])
(ffi/defbind duckdb_get_uhugeint duckdb_uhugeint [value duckdb_value])
(ffi/defbind duckdb_get_uint8 :uint8 [value duckdb_value])
(ffi/defbind duckdb_get_uint16 :uint16 [value duckdb_value])
(ffi/defbind duckdb_get_uint32 :uint32 [value duckdb_value])
(ffi/defbind duckdb_get_uint64 :uint64 [value duckdb_value])
(ffi/defbind duckdb_get_float :float [value duckdb_value])
(ffi/defbind duckdb_get_double :double [value duckdb_value])
(ffi/defbind duckdb_get_date duckdb_date [value duckdb_value])
(ffi/defbind duckdb_get_time duckdb_time [value duckdb_value])
(ffi/defbind duckdb_get_timestamp duckdb_timestamp [value duckdb_value])
(ffi/defbind duckdb_get_interval duckdb_interval [value duckdb_value])
(ffi/defbind duckdb_get_decimal duckdb_decimal_t [value duckdb_value])

# Logical type functions
(ffi/defbind duckdb_create_logical_type duckdb_logical_type [type duckdb_type])
(ffi/defbind duckdb_create_list_type duckdb_logical_type [child-type duckdb_logical_type])
(ffi/defbind duckdb_create_map_type duckdb_logical_type [key-type duckdb_logical_type value-type duckdb_logical_type])
(ffi/defbind duckdb_create_struct_type duckdb_logical_type [child-types :ptr child-names :ptr child-count idx_t])
(ffi/defbind duckdb_create_decimal-type duckdb_logical_type [width :uint8 scale :uint8])
(ffi/defbind duckdb_create_enum_type duckdb_logical_type [enum-name :string enum-values :ptr enum-count idx_t])
(ffi/defbind duckdb_destroy_logical_type :void [type :ptr])
(ffi/defbind duckdb_get_type_id duckdb_type [type duckdb_logical_type])
(ffi/defbind duckdb_logical_type_child_count idx_t [type duckdb_logical_type])
(ffi/defbind duckdb_logical_type_child duckdb_logical_type [type duckdb_logical_type index idx_t])
(ffi/defbind duckdb_logical_type_child-name :string [type duckdb_logical_type index idx_t])
(ffi/defbind duckdb_enum_dictionary_size idx_t [type duckdb_logical_type])
(ffi/defbind duckdb_enum_dictionary_value :ptr [type duckdb_logical_type index idx_t])
(ffi/defbind duckdb_enum_internal_type duckdb_type [type duckdb_logical_type])
(ffi/defbind duckdb_decimal_scale :uint8 [type duckdb_logical_type])
(ffi/defbind duckdb_decimal_internal_type duckdb_type [type duckdb_logical_type])
(ffi/defbind duckdb_list_type_child_type duckdb_logical_type [type duckdb_logical_type])
(ffi/defbind duckdb_array_type_child_type duckdb_logical_type [type duckdb_logical_type])
(ffi/defbind duckdb_array_type_array_size idx_t [type duckdb_logical_type])
(ffi/defbind duckdb_map_type_key_type duckdb_logical_type [type duckdb_logical_type])
(ffi/defbind duckdb_map_type_value_type duckdb_logical_type [type duckdb_logical_type])
(ffi/defbind duckdb_struct_type_child_count idx_t [type duckdb_logical_type])
(ffi/defbind duckdb_struct_type_child_name :ptr [type duckdb_logical_type index idx_t])
(ffi/defbind duckdb_struct_type_child_type duckdb_logical_type [type duckdb_logical_type index idx_t])
(ffi/defbind duckdb_union_type_member_count idx_t [type duckdb_logical_type])
(ffi/defbind duckdb_union_type_member_name :ptr [type duckdb_logical_type index idx_t])
(ffi/defbind duckdb_union_type_member_type duckdb_logical_type [type duckdb_logical_type index idx_t])


# Data chunk functions
(ffi/defbind duckdb_create_data_chunk duckdb_data_chunk_t [types :ptr column-count idx_t])
(ffi/defbind duckdb_destroy_data_chunk :void [chunk :ptr])
(ffi/defbind duckdb_data_chunk_get_column_count idx_t [chunk duckdb_data_chunk_t])
#(ffi/defbind duckdb_data_chunk_get_vector duckdb_vector [chunk duckdb_data_chunk_t col-idx idx_t])
(ffi/defbind duckdb_data_chunk_get_vector duckdb_vector [chunk :ptr col-idx idx_t])
#(ffi/defbind duckdb_data_chunk_get_size idx_t [chunk duckdb_data_chunk_t])
(ffi/defbind duckdb_data_chunk_get_size idx_t [chunk :ptr])
(ffi/defbind duckdb_data_chunk_set_size :void [chunk duckdb_data_chunk_t size idx_t])
(ffi/defbind duckdb_data_chunk_reset :void [chunk duckdb_data_chunk_t])
(ffi/defbind duckdb_vector_get_column_type duckdb_logical_type [vector duckdb_vector])
(ffi/defbind duckdb_vector_get_data :ptr [vector duckdb_vector])
(ffi/defbind duckdb_vector_get_validity :ptr [vector duckdb_vector])
(ffi/defbind duckdb_validity_row_is_valid :bool [validity-mask :ptr row-idx idx_t])
(ffi/defbind duckdb_array_vector_get_child duckdb_vector [vector duckdb_vector])
(ffi/defbind duckdb_list_vector_get_child duckdb_vector [vector duckdb_vector])
(ffi/defbind duckdb_struct_vector_get_child duckdb_vector [vector duckdb_vector index idx_t])
(ffi/defbind duckdb_vector_assign_string_element :void [vector duckdb_vector index idx_t str :string])
(ffi/defbind duckdb_vector_assign_string_element-len :void [vector duckdb_vector index idx_t str :string str-len idx_t])
(ffi/defbind duckdb_vector_get_entry_valid :bool [vector duckdb_vector index idx_t])
(ffi/defbind duckdb_vector_get_entry_null :bool [vector duckdb_vector index idx_t])
(ffi/defbind duckdb_vector_set_entry_null :void [vector duckdb_vector index idx_t])

# Appender functions
(ffi/defbind duckdb_appender_create duckdb_state [connection duckdb_connection schema :string table :string out-appender :ptr])
(ffi/defbind duckdb_appender_destroy :void [appender :ptr])
(ffi/defbind duckdb_appender_begin_row duckdb_state [appender duckdb_appender_t])
(ffi/defbind duckdb_appender_end_row duckdb_state [appender duckdb_appender_t])
(ffi/defbind duckdb_appender_flush duckdb_state [appender duckdb_appender_t])
(ffi/defbind duckdb_appender_close duckdb_state [appender duckdb_appender_t])
(ffi/defbind duckdb_appender_error :string [appender duckdb_appender_t])
(ffi/defbind duckdb_appender_append_bool duckdb_state [appender duckdb_appender_t value :bool])
(ffi/defbind duckdb_appender_append_int8 duckdb_state [appender duckdb_appender_t value :int8])
(ffi/defbind duckdb_appender_append_int16 duckdb_state [appender duckdb_appender_t value :int16])
(ffi/defbind duckdb_appender_append_int32 duckdb_state [appender duckdb_appender_t value :int32])
(ffi/defbind duckdb_appender_append_int64 duckdb_state [appender duckdb_appender_t value :int64])
(ffi/defbind duckdb_appender_append_hugeint duckdb_state [appender duckdb_appender_t value duckdb_hugeint])
(ffi/defbind duckdb_appender_append_uhugeint duckdb_state [appender duckdb_appender_t value duckdb_uhugeint])
(ffi/defbind duckdb_appender_append_uint8 duckdb_state [appender duckdb_appender_t value :uint8])
(ffi/defbind duckdb_appender_append_uint16 duckdb_state [appender duckdb_appender_t value :uint16])
(ffi/defbind duckdb_appender_append_uint32 duckdb_state [appender duckdb_appender_t value :uint32])
(ffi/defbind duckdb_appender_append_uint64 duckdb_state [appender duckdb_appender_t value :uint64])
(ffi/defbind duckdb_appender_append_float duckdb_state [appender duckdb_appender_t value :float])
(ffi/defbind duckdb_appender_append_double duckdb_state [appender duckdb_appender_t value :double])
(ffi/defbind duckdb_appender_append_date duckdb_state [appender duckdb_appender_t value duckdb_date])
(ffi/defbind duckdb_appender_append_time duckdb_state [appender duckdb_appender_t value duckdb_time])
(ffi/defbind duckdb_appender_append_timestamp duckdb_state [appender duckdb_appender_t value duckdb_timestamp])
(ffi/defbind duckdb_appender_append_interval duckdb_state [appender duckdb_appender_t value duckdb_interval])
(ffi/defbind duckdb_appender_append_varchar duckdb_state [appender duckdb_appender_t value :string])
(ffi/defbind duckdb_appender_append_varchar-length duckdb_state [appender duckdb_appender_t value :string length idx_t])
(ffi/defbind duckdb_appender_append_blob duckdb_state [appender duckdb_appender_t value :ptr length idx_t])
(ffi/defbind duckdb_appender_append_null duckdb_state [appender duckdb_appender_t])
(ffi/defbind duckdb_appender_append_value duckdb_state [appender duckdb_appender_t value duckdb_value])

# Table functions
(ffi/defbind duckdb_table_description_create duckdb_state [connection duckdb_connection schema :string table :string out-description :ptr])
(ffi/defbind duckdb_table_description_destroy :void [description :ptr])
(ffi/defbind duckdb_table_description_column_count idx_t [description duckdb_table_description_t])
(ffi/defbind duckdb_table_description_column_name :string [description duckdb_table_description_t column-index idx_t])
(ffi/defbind duckdb_table_description_column_type duckdb_logical_type [description duckdb_table_description_t column-index idx_t])

# Row functions
(ffi/defbind duckdb_row_count idx_t [result :ptr])
(ffi/defbind duckdb_value_boolean :bool [result :ptr col idx_t row idx_t])
(ffi/defbind duckdb_value_int8 :int8 [result :ptr col idx_t row idx_t])
(ffi/defbind duckdb_value_int16 :int16 [result :ptr col idx_t row idx_t])
(ffi/defbind duckdb_value_int32 :int32 [result :ptr col idx_t row idx_t])
(ffi/defbind duckdb_value_int64 :int64 [result :ptr col idx_t row idx_t])
(ffi/defbind duckdb_value_hugeint duckdb_hugeint [result :ptr col idx_t row idx_t])
(ffi/defbind duckdb_value_uhugeint duckdb_uhugeint [result :ptr col idx_t row idx_t])
(ffi/defbind duckdb_value_uint8 :uint8 [result :ptr col idx_t row idx_t])
(ffi/defbind duckdb_value_uint16 :uint16 [result :ptr col idx_t row idx_t])
(ffi/defbind duckdb_value_uint32 :uint32 [result :ptr col idx_t row idx_t])
(ffi/defbind duckdb_value_uint64 :uint64 [result :ptr col idx_t row idx_t])
(ffi/defbind duckdb_value_float :float [result :ptr col idx_t row idx_t])
(ffi/defbind duckdb_value_double :double [result :ptr col idx_t row idx_t])
(ffi/defbind duckdb_value_date duckdb_date [result :ptr col idx_t row idx_t])
(ffi/defbind duckdb_value_time duckdb_time [result :ptr col idx_t row idx_t])
(ffi/defbind duckdb_value_timestamp duckdb_timestamp [result :ptr col idx_t row idx_t])
(ffi/defbind duckdb_value_interval duckdb_interval [result :ptr col idx_t row idx_t])
(ffi/defbind duckdb_value_varchar :string [result :ptr col idx_t row idx_t])
(ffi/defbind duckdb_value_varchar-length :string [result :ptr col idx_t row idx_t length :ptr])
(ffi/defbind duckdb_value_blob :ptr [result :ptr col idx_t row idx_t length :ptr])
(ffi/defbind duckdb_value_bit :ptr [result :ptr col idx_t row idx_t length :ptr])
(ffi/defbind duckdb_value_is_null :bool [result :ptr col idx_t row idx_t])

# Streaming result functions
#(ffi/defbind duckdb_fetch_chunk duckdb_data_chunk [result duckdb_result])
(ffi/defbind duckdb_fetch_chunk :ptr [result duckdb_result])

# Profiling functions
(ffi/defbind duckdb_get_profiling_info :ptr [connection duckdb_connection])
(ffi/defbind duckdb_destroy_profiling_info :void [info :ptr])
