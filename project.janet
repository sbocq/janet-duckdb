(declare-project
  :name "janet-duckdb"
  :description "A Janet library for DuckDB, an in-process SQL OLAP database management system"
  :version "0.7.0"
  :author "Sébastien Bocq"
  :license "MIT"
  :url "https://github.com/sbocq/janet-duckdb"
  :repo "git+https://github.com/sbocq/janet-duckdb.git"
  :dependencies [{:url "https://github.com/ianthehenry/judge.git"
                  :tag "v2.11.0"}])

(declare-source
  :prefix "duckdb"
  :source ["src/init.janet"])

(declare-source
  :prefix "duckdb"
  :source
  ["src/db.janet"
   "src/ffi.janet"
   "src/prepare.janet"
   "src/result.janet"
   "src/types.janet"]
)
