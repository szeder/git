#!/bin/sh
#
# Build and test Git
#

. ${0%/*}/lib.sh

case "$CI_OS_NAME" in
windows*) cmd //c mklink //j t\\.prove "$(cygpath -aw "$cache_dir/.prove")";;
*) ln -s "$cache_dir/.prove" t/.prove;;
esac

make
case "$jobname" in
linux-gcc)
	make test
	cat t/CD-*
	rm -rf t/CD-*
	export GIT_TEST_SPLIT_INDEX=yes
	export GIT_TEST_FULL_IN_PACK_ARRAY=true
	export GIT_TEST_OE_SIZE=10
	export GIT_TEST_OE_DELTA_SIZE=5
	export GIT_TEST_COMMIT_GRAPH=1
	export GIT_TEST_COMMIT_GRAPH_CHANGED_PATHS=1
	export GIT_TEST_MULTI_PACK_INDEX=1
	export GIT_TEST_ADD_I_USE_BUILTIN=1
	make test
	cat t/CD-*
	rm -rf t/CD-*
	;;
linux-clang)
	export GIT_TEST_DEFAULT_HASH=sha1
	make test
	cat t/CD-*
	rm -rf t/CD-*
	export GIT_TEST_DEFAULT_HASH=sha256
	make test
	cat t/CD-*
	rm -rf t/CD-*
	;;
linux-gcc-4.8)
	# Don't run the tests; we only care about whether Git can be
	# built with GCC 4.8, as it errors out on some undesired (C99)
	# constructs that newer compilers seem to quietly accept.
	;;
*)
	make test
	cat t/CD-*
	rm -rf t/CD-*
	;;
esac

check_unignored_build_artifacts

save_good_tree
