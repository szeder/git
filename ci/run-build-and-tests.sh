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

export GIT_TEST_FULL_IN_PACK_ARRAY=true
export GIT_TEST_OE_SIZE=10
export GIT_TEST_OE_DELTA_SIZE=5
./t5500-fetch-pack.sh --stress -r 44

