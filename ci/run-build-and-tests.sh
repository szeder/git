#!/bin/sh
#
# Build and test Git
#

. ${0%/*}/lib.sh

case "$CI_OS_NAME" in
windows*) cmd //c mklink //j t\\.prove "$(cygpath -aw "$cache_dir/.prove")";;
*) ln -s "$cache_dir/.prove" t/.prove;;
esac

make -k

cd t

export GIT_TEST_SPLIT_INDEX=yes
export GIT_TEST_FULL_IN_PACK_ARRAY=true
export GIT_TEST_OE_SIZE=10
export GIT_TEST_OE_DELTA_SIZE=5
export GIT_TEST_COMMIT_GRAPH=1
export GIT_TEST_COMMIT_GRAPH_CHANGED_PATHS=1
export GIT_TEST_MULTI_PACK_INDEX=1
export GIT_TEST_ADD_I_USE_BUILTIN=1
./t5500-fetch-pack.sh --stress -r 44

