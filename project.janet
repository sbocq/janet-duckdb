(declare-project
  :name "janet-duckdb"
  :description "A Janet library for DuckDB, an in-process SQL OLAP database management system"
  :version "0.1.0"
  :author "Sébastien Bocq"
  :license "MIT"
  :url "https://github.com/sbocq/janet-duckdb"
  :repo "git+https://github.com/sbocq/janet-duckdb.git"
  :dependencies [{:url "https://github.com/ianthehenry/judge.git"
                  :tag "v2.9.0"}])

(declare-source
  :prefix "duckdb"
  :source
  ["src/db.janet"
   "src/ffi.janet"
   "src/result.janet"
   "src/types.janet"])
