.PHONY: valgrind

.deps.stamp:
	jpm -l deps
	jpm -l install
	touch $@

judge: .deps.stamp
	./jpm_tree/bin/judge

valgrind: | judge
	JANET_DUCKDB_CONFIG_THREADS=1 JANET_DUCKDB_CONFIG_ASYNC_THREADS=1 valgrind -s --leak-check=full --track-origins=yes janet ./jpm_tree/bin/judge

