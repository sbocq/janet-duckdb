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
export DYLD_FALLBACK_LIBRARY_PATH=/path/to/libduckdb;$DYLD_FALLBACK_LIBRARY_PATH
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

## Usage

Assuming you've added `janet-duckdb` as a dependency and run `jpm -l deps`:

```janet
(import janet-duckdb/db :as db)

(with [db (db/open)]
  (pp (db/library-version)))
```

```bash
❯ jpm -l janet test.janet
"v1.3.1"
```

## Status

- Basic FFI bindings around the DuckDB C API
- Usable for simple integrations
- Still WIP — expect breaking changes
- Most types are supported

### Types supported

## Status

- Basic FFI bindings around the DuckDB C API
- Most types are supported
- Usable for simple integrations
- Still WIP — expect breaking changes

### Type Support

Most DuckDB types are supported out of the box. See `test/types_test.janet` for examples.

- **BOOLEAN** → `bool`
- **TINYINT**, **SMALLINT**, **INTEGER**, **UTINYINT**, **USMALLINT**, **UINTEGER**, **FLOAT**, **DOUBLE**, **DECIMAL** → `number`
- **BIGINT**, **UBIGINT**, **TIMESTAMP_NS** → `number` or `core/s64` / `core/u64`
- **HUGEINT**, **UHUGEINT** → `number`
- **TIMESTAMP_S** → `number (epoch s)`
- **TIMESTAMP_MS** → `number (epoch ms)`
- **TIMESTAMP**, **TIMESTAMPZ** → `number (epoch µs)`
- **TIMESTAMP_NS** → `number or core/s64 (epoch ns)`
- **DATE** → `{:month number :month-day number :year number}`
- **TIME** → `{:hours number :minutes number :seconds number :micros number}`
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
- Lispy REPL-friendly query DSL (using `:memory:` as default) (TBD)
- Support for prepared statements
- Bug fixes (of course)
- More hacking
- And then more bug fixes I guess (TBD)

---

Happy DuckDB hacking with Janet!
