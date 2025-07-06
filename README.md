# janet-duckdb
A Janet FFI wrapper around the DuckDB C API.

# Status
WIP. Tested with duckdb 1.2.2 and 1.3.1.

# Examples
See the [`test`](https://github.com/sbocq/janet-duckdb/tree/main/test) and [`examples`](https://github.com/sbocq/janet-duckdb/tree/main/examples)  folder.

# Installation Notes
Head to [DuckDB Installation](https://duckdb.org/docs/installation/?version=stable&environment=cplusplus&platform=linux&download_method=direct&architecture=x86_64), 
download the C/C++ release, extract and copy  `libduckdb.so` to `/usr/local/lib` or a folder listed in your `LD_LIBRARY_PATH`.
