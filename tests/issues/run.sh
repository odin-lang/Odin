#!/usr/bin/env bash
set -eu

mkdir -p build
pushd build
ODIN=../../../odin
COMMON="-define:ODIN_TEST_FANCY=false -file -vet -strict-style -ignore-unused-defineables -microarch:native"
COMMON_CHECK="-define:ODIN_TEST_FANCY=false -file -vet -strict-style -ignore-unused-defineables"

set -x

$ODIN test ../test_issue_829.odin $COMMON
$ODIN test ../test_issue_1592.odin $COMMON
$ODIN test ../test_issue_1730.odin $COMMON
$ODIN test ../test_issue_2056.odin $COMMON
$ODIN build ../test_issue_2113.odin $COMMON -debug
$ODIN test ../test_issue_2466.odin $COMMON
$ODIN test ../test_issue_2615.odin $COMMON
$ODIN test ../test_issue_2637.odin $COMMON
$ODIN test ../test_issue_2666.odin $COMMON
$ODIN test ../test_issue_2694.odin $COMMON
$ODIN test ../test_issue_3435.odin $COMMON
$ODIN test ../test_issue_4210.odin $COMMON
$ODIN test ../test_issue_4364.odin $COMMON
$ODIN test ../test_issue_4584.odin $COMMON
if [[ $($ODIN build ../test_issue_2395.odin $COMMON 2>&1 >/dev/null | grep -c "Error:") -eq 2 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi
$ODIN build ../test_issue_5043.odin $COMMON
$ODIN build ../test_issue_5097.odin $COMMON
$ODIN build ../test_issue_5097-2.odin $COMMON
$ODIN build ../test_issue_5265.odin $COMMON
if [[ $($ODIN build ../test_issue_5573.odin $COMMON 2>&1 >/dev/null | grep -c "Error:") -eq 2 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi
$ODIN test ../test_issue_5699.odin $COMMON
$ODIN test ../test_issue_6068.odin $COMMON
$ODIN test ../test_issue_6165.odin $COMMON
$ODIN test ../test_issue_6344.odin $COMMON
$ODIN test ../test_issue_6344.odin $COMMON -o:speed
$ODIN test ../test_issue_6396.odin $COMMON

if [[ $($ODIN build ../test_issue_6240.odin $COMMON 2>&1 >/dev/null | grep -c "Error:") -eq 3 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi
if [[ $($ODIN build ../test_issue_6401.odin $COMMON 2>&1 >/dev/null | grep -c "Error:") -eq 3 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi
if [[ $($ODIN build ../test_issue_6594.odin $COMMON 2>&1 >/dev/null | grep -c "Error:") -eq 1 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi
if [[ $($ODIN build ../test_issue_6621.odin $COMMON 2>&1 >/dev/null | grep -c "Error:") -eq 1 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi
$ODIN test ../test_issue_6419.odin $COMMON
$ODIN test ../test_pr_6470.odin $COMMON
if [[ $($ODIN test ../test_pr_6470.odin -define:TEST_EXPECT_FAILURE=true $COMMON 2>&1 >/dev/null | grep -c "Error:") -eq 1 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi
$ODIN check ../test_issue_6484.odin -no-entry-point $COMMON_CHECK
$ODIN test ../test_issue_6753.odin $COMMON
if [[ $($ODIN check ../test_issue_6874.odin $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error:") -eq 1 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi
$ODIN check ../test_issue_6979.odin -no-entry-point $COMMON_CHECK
$ODIN test ../test_issue_7008.odin $COMMON
$ODIN check ../test_issue_7012.odin -no-entry-point $COMMON_CHECK
$ODIN build ../test_issue_7037.odin $COMMON -o:none
$ODIN test ../test_issue_7421.odin $COMMON
if [[ $($ODIN check ../test_issue_7421_tagged_duplicate.odin $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error: Duplicate case") -eq 1 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi
$ODIN check ../test_issue_7429.odin $COMMON_CHECK
$ODIN test ../test_issue_7356.odin $COMMON
$ODIN test ../test_issue_7336.odin $COMMON
$ODIN build ../test_issue_7167.odin $COMMON
$ODIN build ../test_issue_7188.odin $COMMON
$ODIN check ../test_issue_7260.odin -no-entry-point $COMMON_CHECK
$ODIN test ../test_issue_bool_to_be_conversion.odin $COMMON
$ODIN test ../test_issue_bool_comparison_truthiness.odin $COMMON
$ODIN test ../test_issue_const_array_broadcast.odin $COMMON
$ODIN test ../test_issue_swizzle_multi_assign.odin $COMMON

$ODIN check ../test_issue_foreign_redeclaration.odin -no-entry-point $COMMON_CHECK
if [[ $($ODIN check ../test_issue_foreign_redeclaration_mismatch.odin -no-entry-point $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error:") -eq 1 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

if [[ $($ODIN check ../test_issue_ellipsis_type_call.odin -no-entry-point $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error:") -eq 10 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

# `asm` templates are amd64-only, so this file is empty on every other architecture
if [[ "$(uname -m)" == "x86_64" || "$(uname -m)" == "amd64" ]]; then
	if [[ $($ODIN doc ../test_issue_asm_doc_category.odin -file 2>&1 | grep -c "asm templates") -eq 1 ]]; then
		echo "SUCCESSFUL 1/1"
	else
		echo "SUCCESSFUL 0/1"
		exit 1
	fi
fi

if [[ $($ODIN build ../test_issue_7108.odin $COMMON 2>&1 >/dev/null | grep -c "Error:") -eq 2 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

if [[ $($ODIN build ../test_issue_7073-1.odin $COMMON 2>&1 >/dev/null | grep -c "Error:") -eq 2 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

if [[ $($ODIN check ../test_issue_7304.odin -no-entry-point $COMMON_CHECK 2>&1 >/dev/null | grep -c "9223372036854775808 is not representable by int") -eq 1 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

clang -c ../test_issue_7010.c -o test_issue_7010_c.o
$ODIN test ../test_issue_7010.odin $COMMON

clang -c ../test_issue_sysv_abi.c -o test_issue_sysv_abi_c.o
$ODIN test ../test_issue_sysv_abi.odin $COMMON

clang -c ../test_issue_6809_6816.c -o test_issue_6809_6816_c.o -O3
$ODIN test ../test_issue_6809_6816.odin -o:speed $COMMON

clang -c ../test_issue_5640.c -o test_issue_5640_c.o
if [[ "$(uname)" != "NetBSD" ]]; then
	$ODIN test ../test_issue_5640.odin -o:none --sanitize:address $COMMON
else
	$ODIN test ../test_issue_5640.odin -o:none $COMMON
fi

# -cached: an entry may only be reused when nothing that affects the executable has changed.
# skipped on freebsd: the emulated ci vm sigills on the -cached build, though it passes on every
# native target plus netbsd.
if [[ "$(uname)" != "FreeBSD" ]]; then
	clang -c ../test_cached_foreign_libs.c -o cached_foreign_libs_c.o
	ar rcs libcached_foreign_libs.a cached_foreign_libs_c.o
	CACHED_HOME="$PWD/cached_test_home"
	rm -rf "$CACHED_HOME"
	# -microarch:native like $COMMON: `odin run` refuses to execute a binary built for a newer
	# microarch than the host, and CI runners are sometimes an emulated CPU older than the default.
	cached_build() { ODIN_CACHE_DIR="$CACHED_HOME" $ODIN build ../test_cached_foreign_libs.odin -file -cached -microarch:native -show-debug-messages -out:cached_foreign_libs_app "$@" 2>&1; }
	# $1 is what the next build must do: from_cache (reuse) or to_cache (rebuild). Rest are flags.
	# The output is captured before being searched: `grep -q` exits on its first match and would
	# SIGPIPE the compiler, which prints this line before it writes the manifests.
	expect_cache() {
		local want="$1"; shift
		local out
		out=$(cached_build "$@")
		if echo "$out" | grep -q "try_copy_executable_${want}_cache"; then
			echo "SUCCESSFUL 1/1"
		else
			echo "SUCCESSFUL 0/1 (-cached: expected ${want}_cache for '$*')"
			exit 1
		fi
	}

	cached_build >/dev/null # cold build, fills the cache
	expect_cache from
	# a static foreign lib is baked into the executable, so changing one must rebuild
	touch -t 203012312359 libcached_foreign_libs.a
	expect_cache to
	expect_cache from

	# build flags are part of the identity of an entry: the cache directory is keyed on source
	# paths alone, so without this check -o:speed would be handed the -o:none executable.
	expect_cache to   -o:speed
	expect_cache from -o:speed

	# the compiler itself is an input; a newer one must invalidate what an older one produced.
	touch "$ODIN"
	expect_cache to   -o:speed
	expect_cache from -o:speed

	# cache entries are published via a temp + rename: no temps may survive, and the restored
	# executable must keep its permissions (gb_file_copy creates new files as 0666).
	rm -rf "$CACHED_HOME"
	cached_build >/dev/null
	cached_build >/dev/null
	leftover_temps=$(find "$CACHED_HOME" -name '*.tmp' | wc -l | tr -d ' ')
	if [[ "$leftover_temps" == "0" ]] && [[ -x cached_foreign_libs_app ]] && ./cached_foreign_libs_app; then
		echo "SUCCESSFUL 1/1"
	else
		echo "SUCCESSFUL 0/1 (-cached leaked temps, or the restored executable is broken)"
		exit 1
	fi

	# `odin run` deletes the executable once it has run, so a cache hit hard-links it rather than
	# copying. The entry must survive that unlink, still be runnable, and keep the cache correct.
	ODIN_CACHE_DIR="$CACHED_HOME" $ODIN run ../test_cached_foreign_libs.odin -file -cached -microarch:native
	ODIN_CACHE_DIR="$CACHED_HOME" $ODIN run ../test_cached_foreign_libs.odin -file -cached -microarch:native
	entry=$(find "$CACHED_HOME" -name 'cached-exe*.bin' | head -1)
	if [[ -x "$entry" ]] && "$entry"; then
		echo "SUCCESSFUL 1/1"
	else
		echo "SUCCESSFUL 0/1 (-cached: the cache entry did not survive 'odin run')"
		exit 1
	fi
fi

set +x

popd
rm -rf build
