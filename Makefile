TEST_SHOW_DETAILS_MODE ?= direct # alternatively: always | failure | never
TEST_PROP_NUM_RUNS ?= 1000

TEST_OPTIONS = \
    --test-show-details=$(TEST_SHOW_DETAILS_MODE) \
    --test-options="--maximum-generated-tests=$(TEST_PROP_NUM_RUNS)"

gen-patch-linear-smc-1.0.1:
	diff -ur -p2 3rd-parties/linear-smc-1.0.1 pkgs/linear-smc | tee 3rd-parties/linear-smc-1.0.1.patch

dev:
	nodemon -e sol -x cabal -- test loliyul $(TEST_OPTIONS)

.PHONY: gen-* dev
