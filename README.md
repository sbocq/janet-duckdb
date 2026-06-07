# janet-duckdb

Bindings for [DuckDB](https://duckdb.org/) in [Janet](https://janet-lang.org/), via FFI.

Work in progress.

## Install

First, make sure the DuckDB C client library is installed and discoverable on your system:

### Linux

1. Download the latest `libduckdb.so` from the [official site](https://duckdb.org/docs/installation/?version=stable\&environment=cplusplus\&platform=linux\&download_method=direct\&architecture=x86_64).
2. Put it in a location like `/usr/local/lib` or export the path:

```bash
export LD_LIBRARY_PATH=/path/to/libduckdb:$LD_LIBRARY_PATH
```

### macOS

1. Download the latest `libduckdb.dylib` from the [same link](https://duckdb.org/docs/installation/?version=stable\&environment=cplusplus\&platform=linux\&download_method=direct).
2. Export the path if needed:

```bash
export DYLD_FALLBACK_LIBRARY_PATH=/path/to/libduckdb:$DYLD_FALLBACK_LIBRARY_PATH
```

Then install the Janet module using jpm:

```bash
jpm install https://github.com/sbocq/janet-duckdb.git
```

Or add it as a dependency to your project:

```janet
# project.janet
(declare-project
  :dependencies ["https://github.com/sbocq/janet-duckdb"])
```

Then fetch the dependencies:

```bash
jpm -l deps
```

## Quick Start

```janet
(import duckdb)

(with [db (duckdb/open)]
  (with [conn (duckdb/connect db)]
    (def row (duckdb/query-first conn "SELECT 'Hello, DuckDB!' AS greeting"))
    (printf "Result: %s" (row :greeting))))
```

```bash
❯ jpm -l janet examples/quickstart.janet
Result: Hello, DuckDB!
```

## Convenience Functions

```janet
(import duckdb)

(with [db (duckdb/open)]
  (with [conn (duckdb/connect db)]
    (def rows (duckdb/query-rows conn "SELECT 1 AS a, 'hello' AS b"))
    (def row (duckdb/query-first conn "SELECT * FROM t"))
    (def n (duckdb/execute-sql conn "INSERT INTO t VALUES (1)"))))
```

## Prepared Statements

```janet
(import duckdb)

(with [db (duckdb/open ":memory:")]
  (with [conn (duckdb/connect db)]
    (with [stmt (duckdb/prepare conn "SELECT ?::INT, ?::VARCHAR")]

      (duckdb/bind stmt 1 42)
      (duckdb/bind stmt 2 "hello")

      (with [result (duckdb/execute stmt)]
        (def row (first (duckdb/columns-to-rows (duckdb/fetch-columns result)))))

      (duckdb/bind-named stmt "$1" 99)

      (with [result (duckdb/execute stmt [1 "world"])])

      (duckdb/clear-bindings stmt))))
```

Complex types (structs, lists, maps, arrays, unions) are supported in parameter binding.

## Result Metadata

```janet
(duckdb/return-type result)    ;; → :query-result
(duckdb/statement-type result) ;; → :select
```

## Examples

```bash
jpm -l janet examples/quickstart.janet
jpm -l janet examples/result-processing.janet
jpm -l janet examples/prepared-demo.janet
jpm -l janet examples/prepared.janet
jpm -l janet examples/convenience.janet
```

- **quickstart.janet** — Open a database, run a query, print results
- **result-processing.janet** — Column-oriented and row-oriented result access
- **prepared-demo.janet** — Positional and named parameter binding
- **prepared.janet** — Full prepared statement lifecycle
- **convenience.janet** — query-rows, query-first and execute-sql in action

- Basic FFI bindings around the DuckDB C API
- Flat public API
- Convenience functions
- Prepared statements with type-aware parameter binding
- Clean keyword mappings for result and statement types
- Most DuckDB types supported for reading and binding
- Still WIP
## Status


## Types supported

Most DuckDB types are supported out of the box. See `test/types_test.janet` for examples.

- **BOOLEAN** → `bool`
- **TINYINT**, **SMALLINT**, **INTEGER**, **UTINYINT**, **USMALLINT**, **UINTEGER**, **FLOAT**, **DOUBLE**, **DECIMAL** → `number`
- **BIGINT**, **UBIGINT**, **TIMESTAMP_NS** → `number` or `core/s64` / `core/u64`
- **HUGEINT**, **UHUGEINT** → `number`
- **TIMESTAMP_S** → `number (epoch s)`
- **TIMESTAMP_MS** → `number (epoch ms)`
- **TIMESTAMP**, **TIMESTAMP_TZ** → `number (epoch µs)`
- **TIMESTAMP_NS** → `number or core/s64 (epoch ns)`
- **DATE** → `{:month number :month-day number :year number}`
- **TIME**, **TIME_TZ** → `{:hours number :minutes number :seconds number :micros number}`
- **INTERVAL** → `{:months number :days number :micros number}`
- **VARCHAR**, **ENUM** → `string`
- **BLOB** → `bytes buffer`
- **LIST** → `array`
- **STRUCT** → `struct` (with keyword keys)
- **MAP** → `table`
- **ARRAY** → `tuple`
- **UNION** → `[:tag value]`

## TODO

- Support for more native types (e.g. UUID, BIT)
- Lispy REPL-friendly query DSL (using `:memory:` as default)
- Bug fixes
- More hacking
- And then more bug fixes I guess

# Compatibility

Releases are compatible with the following versions of DuckDB:

| Release Version | DuckDB Version   |
|-----------------|------------------|
| v0.6.x          | v1.5.x           |
| v0.5.x          | v1.5.x           |
| v0.4.x          | v1.4.x           |
| v0.3.x          | v1.4.x           |
| <= v0.2.x       | v1.3.1           |

# Changelog

## v0.6.0 2026-06-08

- Flat public API
- Convenience functions: `query-rows`, `query-first`, `execute-sql`
- Prepared statements with parameter binding for all types
- Clean keywords for result and statement types
- Code quality improvements

## v0.5.2 2026-05-24

- Upgrade to duckdb-v1.5.3 (Variegata)

## v0.5.1 2026-05-14

- Upgrade to duckdb-v1.5.2 (Variegata)

## v0.5.0 2026-04-12

- Upgrade to duckdb-v1.5.1 (Variegata)
- Return `:session-timezone-offset` info for zoned time
- Update test to handle new column names for type casting
- Fix test default timezone to CET

## v0.4.0 2026-01-11

- Upgrade to duckdb-v1.4.3 (Andium)
- Fix support for time with timezone
- Rename column type `:time-tz` to `:time_tz` for consistency with the ffi
- Rename column type `:timestampz` to `:timestamp_tz` for consistency with the ffi

## v0.3.0 2025-09-21

Upgrade to duckdb-v1.4.0 (Andium)

## v0.2.1 2025-08-05

Handle gracefully results used after being freed.

## v0.2.0 2025-08-03

Update import prefix to `duckdb` instead of `janet-duckdb`

## v0.1.1 2025-08-02

Fix several FFI memory issues using `valgrind`.

## v0.1.0 2025-07-08

Initial release of janet-duckdb against duckdb-v1.3.1 (Ossivalis)

---

Happy DuckDB hacking with Janet!
