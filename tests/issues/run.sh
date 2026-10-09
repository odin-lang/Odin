#!/usr/bin/env bash
set -eu

mkdir -p build
pushd build
ODIN=../../../odin
COMMON="-define:ODIN_TEST_FANCY=false -vet -strict-style -ignore-unused-defineables -microarch:native"
COMMON_CHECK="-define:ODIN_TEST_FANCY=false -vet -strict-style -ignore-unused-defineables"

set -x

# Build prerequisites for tests:

# "odin test" - All simple tests that can be tested without special arguments or error handling:
$ODIN test ../test_simple.odin -file -all-packages $COMMON

$ODIN build ../test_issue_2113.odin $COMMON -debug
if [[ $($ODIN build ../test_issue_2395.odin $COMMON 2>&1 >/dev/null | grep -c "Error:") -eq 2 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi
if [[ $($ODIN check ../test_issue_5105_5569.odin $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error:") -eq 4 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi
$ODIN build ../test_issue_5265.odin $COMMON
if [[ $($ODIN build ../test_issue_5573.odin $COMMON 2>&1 >/dev/null | grep -c "Error:") -eq 2 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi
$ODIN test ../test_issue_6344.odin $COMMON -o:speed

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
if [[ $($ODIN test ../test_pr_6470.odin -define:TEST_EXPECT_FAILURE=true $COMMON 2>&1 >/dev/null | grep -c "Error:") -eq 1 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi
$ODIN check ../test_issue_6484.odin -no-entry-point $COMMON_CHECK
if [[ $($ODIN check ../test_issue_6874.odin $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error:") -eq 1 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi
$ODIN check ../test_issue_6979.odin -no-entry-point $COMMON_CHECK
$ODIN check ../test_issue_7012.odin -no-entry-point $COMMON_CHECK
$ODIN build ../test_issue_7037.odin $COMMON -o:none
$ODIN test ../test_issue_7477_7506.odin $COMMON
$ODIN run ../test_issue_7482.odin $COMMON
$ODIN run ../test_issue_7564.odin $COMMON
if [[ $($ODIN check ../test_issue_7708_mismatch.odin $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error:") -eq 2 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi
$ODIN run ../test_issue_7596.odin $COMMON
$ODIN test ../test_issue_split_globals -define:ODIN_TEST_FANCY=false -vet -strict-style -ignore-unused-defineables
$ODIN test ../test_issue_split_globals -define:ODIN_TEST_FANCY=false -vet -strict-style -ignore-unused-defineables -debug
$ODIN test ../test_issue_fast_isel_lowering.odin $COMMON
$ODIN test ../test_issue_fast_isel_lowering.odin $COMMON -o:none
$ODIN test ../test_issue_equal_proc_dependencies.odin $COMMON
if [[ $($ODIN test ../test_issue_equal_proc_dependencies.odin $COMMON -build-mode:obj 2>&1 | grep -ci "missing procedure") -eq 0 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi
$ODIN test ../test_issue_7421.odin $COMMON
if [[ $($ODIN check ../test_issue_7421_tagged_duplicate.odin $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error: Duplicate case") -eq 1 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi
$ODIN check ../test_issue_7429.odin $COMMON_CHECK
$ODIN build ../test_issue_7167.odin $COMMON
$ODIN build ../test_issue_7188.odin $COMMON
$ODIN check ../test_issue_7260.odin -no-entry-point $COMMON_CHECK
if [[ $($ODIN check ../test_issue_ambiguous_union_literal.odin $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error:") -eq 1 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi
if [[ $($ODIN check ../test_issue_global_when_cycle.odin -no-entry-point $COMMON_CHECK 2>&1 >/dev/null | grep -c "Contradictory global 'when'") -eq 4 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi
if [[ $($ODIN check ../test_issue_global_when_cycle_ambiguous.odin -no-entry-point $COMMON_CHECK 2>&1 >/dev/null | grep -c "Ambiguous global 'when'") -eq 1 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi
if [[ $($ODIN check ../test_issue_global_when_shadowing.odin -no-entry-point $COMMON_CHECK 2>&1 >/dev/null | grep -c "within a global 'when' shadows") -eq 2 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

$ODIN check ../test_issue_foreign_redeclaration.odin -no-entry-point $COMMON_CHECK
$ODIN check ../test_issue_foreign_import_attributes.odin -no-entry-point $COMMON_CHECK
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

if [[ $($ODIN check ../test_issue_integer_literal_exponent.odin -no-entry-point $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error:") -eq 1 ]]; then
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

$ODIN test ../test_issue_7598.odin $COMMON

if [[ $($ODIN build ../test_issue_7598_all_entities_checked.odin $COMMON 2>&1 >/dev/null | grep -c "Error:") -eq 4 ]]; then
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

$ODIN test ../test_lifetime_markers.odin $COMMON -o:size -lifetime-markers
$ODIN test ../test_lifetime_markers.odin $COMMON -o:speed -lifetime-markers
$ODIN run ../test_issue_7798.odin $COMMON

set +x

popd
rm -rf build
