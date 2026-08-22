#!/bin/sh
#
# Check that in source files compiled using the precompiled header:
#   - The first included header file is "git-compat-util.h", or one of
#     those special header files that start by including
#     "git-compat-util.h" (e.g. "builtin.h").
#   - Only a select few #define directives may precede the inclusion of
#     "git-compat-util.h".

set -u

allowed_macros=" \
DISABLE_SIGN_COMPARE_WARNINGS \
GIT_TEST_PROGRESS_ONLY \
USE_THE_REPOSITORY_VARIABLE \
"

allowed_headers=" \
git-compat-util.h \
builtin.h \
test-lib.h \
test-tool.h \
unit-test.h \
xinclude.h \
"

macro_error="error: '%s' uses the precompiled header, but the unsupported macro '%s' is defined before including the first header file\n"
header_error="error: '%s' uses the precompiled header, but the unsupported header '%s' is the first included header file\n"
noinclude_error="error: '%s' uses the precompiled header, but found no #include directive\n"

list_files () {
	{
		cat <<\EOF
sayIt:
	@$(foreach o,$(PRECOMPILED_HEADER_USERS),echo XXX $o YYY;)
EOF
		cat Makefile
	} |
	make -f - sayIt 2>/dev/null |
	sed -n -e 's/.*XXX \(.*\) YYY.*/\1/p' |
	sort
}

check_source_file () {
	local src="$1"

	{
		awk '{
			# Process and list only #define and #include directives.
			if (match($0, /^ *# *(define|include) /) != 0) {
				# Space-normalize directives.
				sub(/^ *# *define */,  "#define ")
				sub(/^ *# *include */, "#include ")

				# Remove the value from #define directives.
				if (match($0, /^#define/) != 0) {
					$0 = "#define " $2
				}

				# Remove quotes and <> around the header, and
				# remove any "../" from #include directives.
				if (match($0, /^#include/) != 0) {
					gsub(/[<>"]/, "")
					gsub(/\.\.\//, "")
				}

				print

				# Stop after the first #include directive.
				if (match($0, /^#include/) != 0) {
					exit
				}
			}
		}' "$src" ||
		echo "#awk-error $?"
	} | {
		include_found=0
		ret=0

		while read line
		do
			case "$line" in
			\#define*)
				macro="${line#* }"
				case "$allowed_macros" in
				*" $macro "*)
					# Good.
					;;
				*)
					printf >&2 "$macro_error" "$src" "$macro"
					ret=1
					;;
				esac
				;;
			\#include*)
				include_found=1
				header="${line#* }"
				case "$allowed_headers" in
				*" $header "*)
					# Good.
					;;
				*)
					printf >&2 "$header_error" "$src" "$header"
					ret=1
					;;
				esac
				;;
			\#awk-error*)
				err="${line#* }"
				printf >&2 'error: awk exited with %d\n' $err
				ret=1
				;;
			esac
		done

		if test $include_found = 0
		then
			printf >&2 "$noinclude_error" "$src"
			ret=1
		fi

		return $ret
	}
}

list_files | {
	ret=0

	while read obj
	do
		src="${obj%.o}.c"

		if ! check_source_file "$src"
		then
			ret=1
		fi
	done

	exit $ret
}
