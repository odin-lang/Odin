#!/usr/bin/env bash
set -eu

mkdir -p build
pushd build
ODIN=../../../odin
COMMON="-define:ODIN_TEST_FANCY=false -vet -strict-style -ignore-unused-defineables -microarch:native"
COMMON_CHECK="-define:ODIN_TEST_FANCY=false -vet -strict-style -ignore-unused-defineables"

set -x

#########################################################################################################

# CONTRIBUTORS:
#   If your test can be run as a simple `odin test`, then please add it to
#   `test_simple.odin` instead, to CI performance acceptable.
#   Otherwise, add it here in the appropriate block, and make sure to
#   update `run.bat` as well.

# Some tests require a C compiler.
#   By default, it uses clang.  export ISSUES_TESTS_NO_CLANG=1  to disable these tests.
#   TODO: See if we can make the tests work with gcc instead?

#########################################################################################################

#
# Build prerequisites for the simple tests:
#   (nothing to do here)
#

#########################################################################################################

#
# "odin test" - All simple tests that can be tested without special arguments or error handling:
#
$ODIN test ../test_simple.odin -file -all-packages $COMMON

#########################################################################################################

#
# "odin check" tests:
#

if [[ $($ODIN check ../test_issue_5105_5569 $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error:") -eq 4 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

if [[ $($ODIN check ../test_issue_7421_tagged_duplicate $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error: Duplicate case") -eq 1 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

$ODIN check ../test_issue_7429 $COMMON_CHECK
$ODIN check ../test_issue_7260 -no-entry-point $COMMON_CHECK
$ODIN check ../test_issue_7336 -no-entry-point $COMMON_CHECK

if [[ $($ODIN check ../test_issue_ambiguous_union_literal $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error:") -eq 1 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

if [[ $($ODIN check ../test_issue_global_when_cycle -no-entry-point $COMMON_CHECK 2>&1 >/dev/null | grep -c "Contradictory global 'when'") -eq 4 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

if [[ $($ODIN check ../test_issue_global_when_cycle_ambiguous -no-entry-point $COMMON_CHECK 2>&1 >/dev/null | grep -c "Ambiguous global 'when'") -eq 1 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

if [[ $($ODIN check ../test_issue_global_when_shadowing -no-entry-point $COMMON_CHECK 2>&1 >/dev/null | grep -c "within a global 'when' shadows") -eq 2 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

$ODIN check ../test_issue_foreign_redeclaration -no-entry-point $COMMON_CHECK
$ODIN check ../test_issue_foreign_import_attributes -no-entry-point $COMMON_CHECK

if [[ $($ODIN check ../test_issue_foreign_redeclaration_mismatch -no-entry-point $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error:") -eq 1 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

if [[ $($ODIN check ../test_issue_ellipsis_type_call -no-entry-point $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error:") -eq 10 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

if [[ $($ODIN check ../test_issue_integer_literal_exponent -no-entry-point $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error:") -eq 1 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

$ODIN check ../test_issue_6484 -no-entry-point $COMMON_CHECK

if [[ $($ODIN check ../test_issue_6874 $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error:") -eq 1 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

$ODIN check ../test_issue_6979 -no-entry-point $COMMON_CHECK
$ODIN check ../test_issue_7012 -no-entry-point $COMMON_CHECK

if [[ $($ODIN check ../test_issue_7708_mismatch $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error:") -eq 2 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

if [[ $($ODIN check ../test_issue_7304 -no-entry-point $COMMON_CHECK 2>&1 >/dev/null | grep -c "9223372036854775808 is not representable by int") -eq 1 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

if [[ $($ODIN check ../test_issue_poly_proc_value $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error:") -eq 4 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

if [[ $($ODIN check ../test_issue_fixed_point_scale $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error:") -eq 4 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

if [[ $($ODIN check ../test_issue_atomic_orderings -no-entry-point $COMMON_CHECK 2>&1 >/dev/null | grep -c "Warning:") -eq 13 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

if [[ $($ODIN check ../test_issue_atomic_errors -no-entry-point $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error:") -eq 11 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

if [[ $($ODIN check ../test_issue_atomic_access -no-entry-point -vet-atomic-access $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error:") -eq 11 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

#########################################################################################################

# "odin build" tests:

$ODIN build ../test_issue_2113 $COMMON -debug

if [[ $($ODIN build ../test_issue_2395 $COMMON 2>&1 >/dev/null | grep -c "Error:") -eq 2 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

$ODIN build ../test_issue_5043 $COMMON
$ODIN build ../test_issue_5097 $COMMON
$ODIN build ../test_issue_5097-2 $COMMON
$ODIN build ../test_issue_5265 $COMMON

if [[ $($ODIN build ../test_issue_5573 $COMMON 2>&1 >/dev/null | grep -c "Error:") -eq 2 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

if [[ $($ODIN build ../test_issue_6240 $COMMON 2>&1 >/dev/null | grep -c "Error:") -eq 3 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

if [[ $($ODIN build ../test_issue_6401 $COMMON 2>&1 >/dev/null | grep -c "Error:") -eq 3 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

if [[ $($ODIN build ../test_issue_6594 $COMMON 2>&1 >/dev/null | grep -c "Error:") -eq 1 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

if [[ $($ODIN build ../test_issue_6621 $COMMON 2>&1 >/dev/null | grep -c "Error:") -eq 1 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

$ODIN build ../test_issue_7037 $COMMON -o:none

if [[ $($ODIN build ../test_issue_7073-1 $COMMON 2>&1 >/dev/null | grep -c "Error:") -eq 2 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

$ODIN build ../test_issue_7167 $COMMON
$ODIN build ../test_issue_7188 $COMMON

if [[ $($ODIN build ../test_issue_7108 $COMMON 2>&1 >/dev/null | grep -c "Error:") -eq 2 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

if [[ $($ODIN build ../test_issue_7304 $COMMON 2>&1 >/dev/null | grep -c "9223372036854775808 is not representable by int") -eq 1 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

if [[ $($ODIN build ../test_issue_7598_all_entities_checked $COMMON 2>&1 >/dev/null | grep -c "Error:") -eq 4 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

#########################################################################################################

# "odin run" tests:

$ODIN run ../test_issue_7482 $COMMON
$ODIN run ../test_issue_7562 $COMMON -no-crt -no-thread-local
$ODIN run ../test_issue_7562 $COMMON -no-crt -no-thread-local -o:speed
$ODIN run ../test_issue_7564 $COMMON
$ODIN run ../test_issue_7596 $COMMON
$ODIN run ../test_issue_7798 $COMMON

#########################################################################################################

# "odin test" tests with special needs, or others (e.g. "odin doc"):

if [[ ! -v ISSUES_TESTS_NO_CLANG ]]; then
	clang -c ../test_issue_5640/test_issue_5640.c -o test_issue_5640_c.o

	if [[ "$(uname)" != "NetBSD" ]]; then
		$ODIN test ../test_issue_5640 -o:none --sanitize:address $COMMON
	else
		$ODIN test ../test_issue_5640 -o:none $COMMON
	fi
fi

if [[ ! -v ISSUES_TESTS_NO_CLANG ]]; then
	clang -c ../test_issue_6809_6816/test_issue_6809_6816.c -o test_issue_6809_6816_c.o -O3
	$ODIN test ../test_issue_6809_6816 -o:speed $COMMON
fi

$ODIN test ../test_issue_6344 $COMMON -o:speed

if [[ $($ODIN test ../test_pr_6470 -define:TEST_EXPECT_FAILURE=true $COMMON 2>&1 >/dev/null | grep -c "Error:") -eq 1 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

if [[ ! -v ISSUES_TESTS_NO_CLANG ]]; then
	clang -c ../test_issue_7010/test_issue_7010.c -o test_issue_7010_c.o
	$ODIN test ../test_issue_7010 $COMMON
fi

$ODIN test ../test_issue_7547 $COMMON -debug

$ODIN test ../test_issue_split_globals -define:ODIN_TEST_FANCY=false -vet -strict-style -ignore-unused-defineables -microarch:native
$ODIN test ../test_issue_split_globals -define:ODIN_TEST_FANCY=false -vet -strict-style -ignore-unused-defineables -debug -microarch:native

$ODIN test ../test_issue_fast_isel_lowering $COMMON -o:none

if [[ $($ODIN test ../test_issue_equal_proc_dependencies $COMMON -build-mode:obj 2>&1 | grep -ci "missing procedure") -eq 0 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi
if [[ $($ODIN check ../test_issue_fixed_point_scale $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error:") -eq 4 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

# `asm` templates are amd64-only, so this file is empty on every other architecture
if [[ "$(uname -m)" == "x86_64" || "$(uname -m)" == "amd64" ]]; then
	if [[ $($ODIN doc ../test_issue_asm_doc_category 2>&1 | grep -c "asm templates") -eq 1 ]]; then
		echo "SUCCESSFUL 1/1"
	else
		echo "SUCCESSFUL 0/1"
		exit 1
	fi
fi

$ODIN test ../test_lifetime_markers $COMMON -o:size -lifetime-markers
$ODIN test ../test_lifetime_markers $COMMON -o:speed -lifetime-markers

if [[ ! -v ISSUES_TESTS_NO_CLANG ]]; then
	clang -c ../test_issue_sysv_abi/test_issue_sysv_abi.c -o test_issue_sysv_abi_c.o
	$ODIN test ../test_issue_sysv_abi $COMMON
fi

# AVX-512 asked for through -target-features on the default microarch; needs a CPU that has it
if [[ ! -v ISSUES_TESTS_NO_CLANG ]]; then
	if grep -qw avx512f /proc/cpuinfo 2>/dev/null; then
		clang -c ../test_issue_avx512_vector_abi/test_issue_avx512_vector_abi.c -o test_issue_avx512_vector_abi_c.o -mavx512f
		$ODIN test ../test_issue_avx512_vector_abi $COMMON_CHECK -target-features:avx512f
	fi
fi

$ODIN test ../test_issue_disabled_proc_value $COMMON -disable-assert
$ODIN test ../test_issue_loaded_pointer_alignment $COMMON -o:speed

#########################################################################################################

if [[ -v ISSUES_TESTS_NO_CLANG ]]; then
	echo "!!! WARNING !!! Tests that require clang have been skipped"
fi

#########################################################################################################

set +x

popd
rm -rf build
