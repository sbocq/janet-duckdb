.PHONY: valgrind

.deps.stamp:
	jpm -l deps
	jpm -l install
	touch $@

judge: .deps.stamp
	./jpm_tree/bin/judge

valgrind: | judge
	valgrind -s --leak-check=full --track-origins=yes janet ./jpm_tree/bin/judge

