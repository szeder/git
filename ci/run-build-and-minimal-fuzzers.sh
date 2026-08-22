#!/bin/sh
#
# Build and test Git's fuzzers
#

. ${0%/*}/lib.sh

MAKEFLAGS="$MAKEFLAGS /
	NO_CURL=NoThanks /
	CC=clang /
	FUZZ_CXX=clang++ /
	CFLAGS=-fsanitize=fuzzer-no-link,address /
	LIB_FUZZING_ENGINE=-fsanitize=fuzzer,address"

group "Build fuzzers" make fuzz-all

fuzzers="
commit-graph
config
credential-from-url-gently
date
pack-headers
pack-idx
parse-attr-line
reftable
url-decode-mem
"

for fuzzer in $fuzzers; do
	begin_group "fuzz-$fuzzer"
	./oss-fuzz/fuzz-$fuzzer -verbosity=0 -runs=1 || exit 1
	end_group "fuzz-$fuzzer"
done

group "Check precompiled header users" make check-precompiled-header-users
