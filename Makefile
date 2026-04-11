.PHONY: valgrind

.deps.stamp:
	jpm -l deps
	touch $@

judge: .deps.stamp
	TZ=CET ./jpm_tree/bin/judge

valgrind: | judge
	TS=Europe/Brussels valgrind -s --leak-check=full --track-origins=yes janet ./jpm_tree/bin/judge

