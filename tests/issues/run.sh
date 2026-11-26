#!/usr/bin/env bash
set -eu

mkdir -p build
pushd build
ODIN=../../../odin
ODIN_FULL="$(pwd)/../../../odin"
COMMON="-define:ODIN_TEST_FANCY=false -vet -strict-style -ignore-unused-defineables -show-timings -microarch:native"
COMMON_CHECK="-define:ODIN_TEST_FANCY=false -vet -strict-style -ignore-unused-defineables -show-timings"

set -x

#########################################################################################################

# CONTRIBUTORS:
#   If your test can be run as a simple `odin test`, then please add it to
#   `test_simple.odin` instead, to keep CI performance acceptable.
#   Otherwise, add it here in the appropriate block, and make sure to
#   update `run.bat` as well.

# Some tests require a C compiler.
#   By default, it uses clang.  export ODIN_TESTS_NO_CLANG=1  to disable these tests.
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

if [[ $($ODIN check ../test_issue_1909 $COMMON_CHECK 2>&1 >/dev/null | grep -c "of a built-in procedure cannot be determined") -eq 3 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

if [[ $($ODIN check ../test_issue_3973 $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error:") -eq 28 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

if [[ $($ODIN check ../test_issue_5105_5569 $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error:") -eq 4 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

if [[ $($ODIN check ../test_issue_5335 $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error:") -eq 2 ]]; then
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
$ODIN check ../test_issue_soa_no_rtti -target:freestanding_amd64_sysv -no-rtti -no-entry-point $COMMON_CHECK

if [[ $($ODIN check ../test_issue_soa_field_unroll $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error:") -eq 1 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

if [[ $($ODIN check ../test_issue_soa_of_soa $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error:") -eq 8 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

if [[ $($ODIN check ../test_issue_soa_column_not_addressable $COMMON_CHECK 2>&1 >/dev/null | grep -c "value is not addressable") -eq 3 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

if [[ $($ODIN check ../test_issue_soa_column_escape $COMMON_CHECK 2>&1 >/dev/null | grep -c "It is unsafe to return") -eq 1 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

if [[ $($ODIN check ../test_issue_array_conversion_parens $COMMON_CHECK 2>&1 >/dev/null | grep -c "needs parentheses") -eq 3 ]] &&
   [[ $($ODIN check ../test_issue_array_conversion_parens $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error:") -eq 3 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

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

if [[ $($ODIN check ../test_issue_nesting_limit $COMMON_CHECK 2>&1 >/dev/null | grep -c "nested too deeply") -eq 1 ]]; then
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

if [[ $($ODIN check ../test_issue_inferred_default_overflow -no-entry-point $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error: Cannot convert numeric value") -eq 6 ]]; then
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

if [[ $($ODIN check ../test_issue_7199 $COMMON_CHECK 2>&1 >/dev/null | grep -c "\.\.19988 chars\.\.") -eq 1 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

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

if [[ $($ODIN check ../test_issue_7938 -no-entry-point $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error: Missing return statement") -eq 3 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

if [[ $($ODIN check ../test_issue_7975_7976_mismatch $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error:") -eq 8 ]]; then
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

if [[ $($ODIN check ../test_issue_poly_variadic_errors $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error:") -eq 3 &&
      $($ODIN check ../test_issue_poly_variadic_errors $COMMON_CHECK 2>&1 >/dev/null | grep -cF "Cannot infer the polymorphic type '\$E' of the variadic parameter 'args'") -eq 3 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

if [[ $($ODIN check ../test_issue_poly_recursion_limit $COMMON_CHECK 2>&1 >/dev/null | grep -c "Polymorphic instantiations are nested too deeply") -eq 1 &&
      $($ODIN check ../test_issue_poly_recursion_limit_record $COMMON_CHECK 2>&1 >/dev/null | grep -c "Polymorphic instantiations are nested too deeply") -eq 1 ]]; then
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

if [[ $($ODIN check ../test_issue_escape_stored_field -no-entry-point $COMMON_CHECK 2>&1 >/dev/null | grep -c "Warning:") -eq 3 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

if [[ $($ODIN check ../test_issue_escape_union_loop -no-entry-point $COMMON_CHECK 2>&1 >/dev/null | grep -c "Warning:") -eq 1 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

ESCAPE_OUT=$($ODIN check ../test_issue_escape_diagnostics -no-entry-point $COMMON_CHECK 2>&1 >/dev/null)
if [[ $(grep -c "Warning:" <<< "$ESCAPE_OUT") -eq 5 &&
      $(grep -c "holds a pointer into itself" <<< "$ESCAPE_OUT") -eq 3 &&
      $(grep -c "is taken at" <<< "$ESCAPE_OUT") -eq 5 &&
      $(grep -c "'temp.allocator.data' may refer to 'temp.arena' in the stack memory of the named result 'temp'" <<< "$ESCAPE_OUT") -eq 1 &&
      $(grep -c "The call to" <<< "$ESCAPE_OUT") -eq 3 &&
      $(grep -c "returns its parameter 'mem' in '.memory' of its result" <<< "$ESCAPE_OUT") -eq 1 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

if [[ $($ODIN check ../test_issue_escape_nested_calls -no-entry-point $COMMON_CHECK 2>&1 >/dev/null | grep -c "Warning:") -eq 6 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

ESCAPE_OUT=$($ODIN check ../test_issue_escape_cleared_stores -no-entry-point $COMMON_CHECK 2>&1 >/dev/null)
if [[ $(grep -c "Warning:" <<< "$ESCAPE_OUT") -eq 28 &&
      $(grep -c "local variable 'y'" <<< "$ESCAPE_OUT") -eq 1 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

ESCAPE_OUT=$($ODIN check ../test_issue_escape_deferred_procs -no-entry-point $COMMON_CHECK 2>&1 >/dev/null)
if [[ $(grep -c "Warning:" <<< "$ESCAPE_OUT") -eq 8 &&
      $(grep -c "deferred by" <<< "$ESCAPE_OUT") -eq 7 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

$ODIN test ../test_issue_type_info_variant_shim $COMMON -ignore-warnings
if [[ $($ODIN check ../test_issue_type_info_variant_shim -no-entry-point $COMMON_CHECK 2>&1 >/dev/null | grep -c "Warning:") -eq 11 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

if [[ $($ODIN check ../test_issue_type_info_variant_shim_duplicate -no-entry-point $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error:") -eq 1 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

if [[ $($ODIN check ../test_issue_bit_field_tag_identity -no-entry-point $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error:") -eq 1 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

if [[ $($ODIN check ../test_issue_8074 -no-entry-point $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error:") -eq 34 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

if [[ $($ODIN check ../test_issue_8258 $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error: @(test) procedures must be declared at the file scope") -eq 4 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

if [[ $($ODIN test ../test_issue_invalid_tests_only $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error:") -eq 2 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

if [[ $($ODIN check ../test_issue_8294 $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error:") -eq 2 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

if [[ $($ODIN check ../test_issue_5024 $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error:") -eq 2 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

if [[ $($ODIN check ../test_issue_8455 $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error:") -eq 3 ]] && [[ $($ODIN check ../test_issue_8455 $COMMON_CHECK 2>&1 >/dev/null | grep -c "it is a directory") -eq 3 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

if [[ $($ODIN check ../test_issue_8513_errors $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error:") -eq 3 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

if [[ $($ODIN check ../test_issue_7947 $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error: Unspecialized polymorphic procedure literal") -eq 1 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

if [[ $($ODIN check ../test_issue_7502_cycle -no-entry-point $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error:") -eq 3 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

if [[ $($ODIN check ../test_issue_8097 -no-entry-point $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error: Invalid use of a polymorphic type") -eq 4 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

if [[ $($ODIN check ../test_issue_poly_record_unspecialized_field $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error:") -eq 4 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

# Objective-C tests target darwin, which can be checked and built for from any host
if [[ $($ODIN check ../test_issue_objc_import_missing_selector -no-entry-point -target:darwin_arm64 $COMMON_CHECK 2>&1 >/dev/null | grep -c "is required for imported Objective-C methods") -eq 1 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

if [[ $($ODIN check ../test_issue_objc_deferred_import -no-entry-point -target:darwin_arm64 $COMMON_CHECK 2>&1 >/dev/null | grep -c "cannot be used as a deferred_out procedure") -eq 1 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

if [[ $($ODIN check ../test_issue_7980 -target:darwin_arm64 $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error:") -eq 2 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

#########################################################################################################

#
# "odin build" tests:
#

$ODIN build ../test_issue_2113 $COMMON -debug

# $COMMON_CHECK, as $COMMON's -microarch:native does not apply to a darwin_arm64 cross build
$ODIN build ../test_issue_objc_class_method_calls -target:darwin_arm64 -build-mode:obj $COMMON_CHECK

if [[ $($ODIN build ../test_issue_2395 $COMMON 2>&1 >/dev/null | grep -c "Error:") -eq 2 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

$ODIN build ../test_issue_5043 $COMMON
$ODIN build ../test_issue_8554 -build-mode:obj $COMMON
$ODIN build ../test_issue_8555 -build-mode:obj -target:linux_arm64 -target-features:contextidrel2,NeoverseV3ae,-CRC $COMMON_CHECK
$ODIN build ../test_issue_8555 -build-mode:obj -target:linux_arm32 -target-features:+slow-load-d-subreg $COMMON_CHECK
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

#
# "odin run" tests:
#

# 7442 is Windows only. TODO: Being in run.sh doesn't necessarily mean we're not on Windows.
#$ODIN run ../test_issue_7442 $COMMON
#$ODIN run ../test_issue_7442 $COMMON -no-crt -no-thread-local
#$ODIN run ../test_issue_7442 $COMMON -subsystem:windows
$ODIN run ../test_issue_7482 $COMMON
# 7562 is Windows only. TODO: Being in run.sh doesn't necessarily mean we're not on Windows.
#$ODIN run ../test_issue_7562 $COMMON -no-crt -no-thread-local
#$ODIN run ../test_issue_7562 $COMMON -no-crt -no-thread-local -o:speed
$ODIN run ../test_issue_7564 $COMMON
$ODIN run ../test_issue_7596 $COMMON
$ODIN run ../test_issue_7798 $COMMON

#########################################################################################################

#
# Test clang - improve error message for users that don't have it.
#

if [[ -z ${ODIN_TESTS_NO_CLANG+x} ]]; then
	if ! clang --version; then
		set +x
		echo "ERROR: clang not working. This is required for some tests."
		echo "You can disable tests that require clang:  export ODIN_TESTS_NO_CLANG=1"
		exit 1
	fi
fi

#########################################################################################################

#
# "odin test" tests with special needs, or others (e.g. "odin doc"):
#

if [[ -z ${ODIN_TESTS_NO_CLANG+x} ]]; then
	clang -c ../test_issue_5640/test_issue_5640.c -o test_issue_5640_c.o

	if [[ "$(uname)" != "NetBSD" && "$(uname)" != "OpenBSD" ]]; then
		$ODIN test ../test_issue_5640 -o:none --sanitize:address $COMMON
	else
		$ODIN test ../test_issue_5640 -o:none $COMMON
	fi
fi

if [[ -z ${ODIN_TESTS_NO_CLANG+x} ]]; then
	clang -c ../test_issue_6809_6816/test_issue_6809_6816.c -o test_issue_6809_6816_c.o -O3
	$ODIN test ../test_issue_6809_6816 -o:speed $COMMON
fi

$ODIN test ../test_issue_6344 $COMMON -o:speed

if [[ "$(uname)" != "NetBSD" && "$(uname)" != "OpenBSD" ]]; then
	$ODIN test ../test_issue_8072 -o:minimal --sanitize:address $COMMON
fi
$ODIN test ../test_issue_8072 -o:speed -lifetime-markers $COMMON

if [[ $($ODIN test ../test_pr_6470 -define:TEST_EXPECT_FAILURE=true $COMMON 2>&1 >/dev/null | grep -c "Error:") -eq 1 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

$ODIN test ../test_issue_define_config $COMMON -define:DEFINE_VERSION=1.0 -define:DEFINE_MODE=true -define:DEFINE_HEX=-0x7f -define:DEFINE_MAX_U8=255 -define:DEFINE_MIN_I32=-2_147_483_648 -define:DEFINE_INTEGRAL_FLOAT=2.0 -define:DEFINE_INT_FOR_FLOAT=3 -define:DEFINE_EXPONENT=1_000e-3 -define:DEFINE_SEPARATORS=1_000_000 -define:DEFINE_RUNE=65 -define:DEFINE_ENUM=C "-define:DEFINE_QUOTED='x'" -define:DEFINE_EMPTY= "-define:DEFINE_SPACED=a b" -define:DEFINE_CSTRING=c -define:DEFINE_DISTINCT_STRING=d
DEFINE_ERRORS=(-define:DEFINE_NOT_A_NUMBER=abc -define:DEFINE_OUT_OF_RANGE=256 -define:DEFINE_TRUNCATED=1.5 -define:DEFINE_NOT_A_BOOL=T -define:DEFINE_EMPTY= -define:DEFINE_NOT_A_FIELD=C -define:DEFINE_NOT_SETTABLE=A "-define:DEFINE_QUOTED_NUMBER='1'")
if [[ $($ODIN check ../test_issue_define_config_errors -no-entry-point $COMMON_CHECK "${DEFINE_ERRORS[@]}" 2>&1 >/dev/null | grep -c "Error:") -eq 8 &&
      $($ODIN check ../test_issue_define_config_errors -no-entry-point $COMMON_CHECK "${DEFINE_ERRORS[@]}" 2>&1 >/dev/null | grep -c -- "-define:DEFINE_") -eq 8 &&
      $($ODIN check ../test_issue_define_config -no-entry-point -vet -strict-style -define:DEFINE_VERSION=1.0 -define:DEFINE_NOWHERE=1 2>&1 >/dev/null | grep -c "is unused in the project") -eq 1 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

$ODIN check ../test_pr_7848/pkg_b ../test_pr_7848/pkg_a -no-entry-point -workspace -overlay:../test_pr_7848/overlay.json $COMMON_CHECK -export-semantics:json -export-semantics-file:pr_7848.json
$ODIN check ../test_pr_7848/pkg_b ../test_pr_7848/pkg_a -no-entry-point -workspace -overlay:../test_pr_7848/overlay.json $COMMON_CHECK -export-semantics:cbor -export-semantics-file:pr_7848.cbor
$ODIN check ../test_pr_7848/pkg_b ../test_pr_7848/pkg_a -no-entry-point -workspace -overlay:../test_pr_7848/overlay.json $COMMON_CHECK -export-semantics:cbor -export-semantics-file:pr_7848_again.cbor
cmp pr_7848.cbor pr_7848_again.cbor
$ODIN test ../test_pr_7848 $COMMON

if [[ -z ${ODIN_TESTS_NO_CLANG+x} ]]; then
	clang -c ../test_issue_7010/test_issue_7010.c -o test_issue_7010_c.o
	$ODIN test ../test_issue_7010 $COMMON
fi

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
	if [[ $($ODIN check ../test_issue_asm_deferred_errors $COMMON_CHECK 2>&1 >/dev/null | grep -c "Unknown mnemonic") -eq 5 ]]; then
		echo "SUCCESSFUL 1/1"
	else
		echo "SUCCESSFUL 0/1"
		exit 1
	fi
	if [[ $($ODIN check ../test_issue_asm_target_features $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error:") -eq 3 &&
	      $($ODIN check ../test_issue_asm_target_features $COMMON_CHECK 2>&1 >/dev/null | grep -c "enables target feature 'avx'") -eq 3 ]]; then
		echo "SUCCESSFUL 1/1"
	else
		echo "SUCCESSFUL 0/1"
		exit 1
	fi
	$ODIN test ../test_issue_asm_pinned_clobbers $COMMON -o:speed
	$ODIN test ../test_issue_asm_named_register_clobbers $COMMON -o:speed
	$ODIN test ../test_issue_asm_call_clobbers $COMMON -o:speed
	$ODIN test ../test_issue_asm_written_inputs $COMMON -o:speed
	if [[ $($ODIN check ../test_issue_asm_clobber_pinned_output $COMMON_CHECK 2>&1 >/dev/null | grep -c "which '#clobber' also names") -eq 3 ]]; then
		echo "SUCCESSFUL 1/1"
	else
		echo "SUCCESSFUL 0/1"
		exit 1
	fi
	if [[ $($ODIN check ../test_issue_asm_call_flow $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error:") -eq 1 &&
	      $($ODIN check ../test_issue_asm_call_flow $COMMON_CHECK 2>&1 >/dev/null | grep -c "can fall through the end") -eq 1 &&
	      $($ODIN check ../test_issue_asm_call_flow $COMMON_CHECK 2>&1 >/dev/null | grep -c "Warning:") -eq 0 ]]; then
		echo "SUCCESSFUL 1/1"
	else
		echo "SUCCESSFUL 0/1"
		exit 1
	fi
	if [[ $($ODIN check ../test_issue_asm_align_stack $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error:") -eq 4 &&
	      $($ODIN check ../test_issue_asm_align_stack $COMMON_CHECK 2>&1 >/dev/null | grep -c "must declare #align_stack") -eq 4 &&
	      $($ODIN check ../test_issue_asm_align_stack $COMMON_CHECK 2>&1 >/dev/null | grep -c "#align_stack is redundant") -eq 1 ]]; then
		echo "SUCCESSFUL 1/1"
	else
		echo "SUCCESSFUL 0/1"
		exit 1
	fi
	if [[ $($ODIN check ../test_issue_asm_call_targets $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error:") -eq 8 &&
	      $($ODIN check ../test_issue_asm_call_targets $COMMON_CHECK 2>&1 >/dev/null | grep -c "uses the Odin calling convention") -eq 3 &&
	      $($ODIN check ../test_issue_asm_call_targets $COMMON_CHECK 2>&1 >/dev/null | grep -c "as the target of a call") -eq 2 &&
	      $($ODIN check ../test_issue_asm_call_targets $COMMON_CHECK 2>&1 >/dev/null | grep -c "Assertion Failure") -eq 0 ]]; then
		echo "SUCCESSFUL 1/1"
	else
		echo "SUCCESSFUL 0/1"
		exit 1
	fi
	if [[ $($ODIN check ../test_issue_asm_shift_cl_errors $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error:") -eq 12 &&
	      $($ODIN check ../test_issue_asm_shift_cl_errors $COMMON_CHECK 2>&1 >/dev/null | grep -c "8-bit operand pinned to") -eq 5 &&
	      $($ODIN check ../test_issue_asm_shift_cl_errors $COMMON_CHECK 2>&1 >/dev/null | grep -c "expects 3 operands, got 2") -eq 1 &&
	      $($ODIN check ../test_issue_asm_shift_cl_errors $COMMON_CHECK 2>&1 >/dev/null | grep -c "is declared but never used") -eq 1 ]]; then
		echo "SUCCESSFUL 1/1"
	else
		echo "SUCCESSFUL 0/1"
		exit 1
	fi
	if [[ $($ODIN check ../test_issue_asm_accumulator_forms $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error:") -eq 4 &&
	      $($ODIN check ../test_issue_asm_accumulator_forms $COMMON_CHECK 2>&1 >/dev/null | grep -c "takes no implicit accumulator") -eq 4 ]]; then
		echo "SUCCESSFUL 1/1"
	else
		echo "SUCCESSFUL 0/1"
		exit 1
	fi
fi
if [[ $($ODIN check ../test_issue_asm_writeback_errors -target:linux_arm64 $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error:") -eq 4 &&
      $($ODIN check ../test_issue_asm_writeback_errors -target:linux_arm64 $COMMON_CHECK 2>&1 >/dev/null | grep -c "writes back its base register") -eq 1 &&
      $($ODIN check ../test_issue_asm_writeback_errors -target:linux_arm64 $COMMON_CHECK 2>&1 >/dev/null | grep -c "takes only a base register and a constant offset") -eq 1 &&
      $($ODIN check ../test_issue_asm_writeback_errors -target:linux_arm64 $COMMON_CHECK 2>&1 >/dev/null | grep -c "needs a base register") -eq 1 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi
if [[ $($ODIN check ../test_issue_asm_baseless_errors -target:linux_arm64 $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error:") -eq 2 &&
      $($ODIN check ../test_issue_asm_baseless_errors -target:linux_arm64 $COMMON_CHECK 2>&1 >/dev/null | grep -c "needs a base register") -eq 2 &&
      $($ODIN check ../test_issue_asm_baseless_errors -target:linux_riscv64 $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error:") -eq 2 &&
      $($ODIN check ../test_issue_asm_baseless_errors -target:linux_riscv64 $COMMON_CHECK 2>&1 >/dev/null | grep -c "must be from -2048 to 2047") -eq 2 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi
$ODIN build ../test_issue_asm_baseless_riscv -target:linux_riscv64 -build-mode:obj $COMMON_CHECK
$ODIN build ../test_issue_asm_keyword_mnemonic -target:linux_amd64 -build-mode:obj $COMMON_CHECK

$ODIN run ../test_issue_wasm_union_i128 $COMMON
$ODIN build ../test_issue_wasm_union_i128 -target:js_wasm32 -build-mode:obj $COMMON_CHECK
$ODIN build ../test_issue_wasm_union_i128 -target:js_wasm64p32 -build-mode:obj $COMMON_CHECK
$ODIN build ../test_issue_wasm_union_i128 -target:wasi_wasm32 -build-mode:obj $COMMON_CHECK
if command -v wasmtime > /dev/null; then
	$ODIN build ../test_issue_wasm_union_i128 -target:wasi_wasm32 $COMMON_CHECK
	wasmtime ./test_issue_wasm_union_i128.wasm
fi

$ODIN test ../test_lifetime_markers $COMMON -o:size -lifetime-markers
$ODIN test ../test_lifetime_markers $COMMON -o:speed -lifetime-markers

$ODIN test ../test_issue_udivmod128_zero_divisor $COMMON -integer-division-by-zero:zero
$ODIN test ../test_issue_udivmod128_zero_divisor $COMMON -integer-division-by-zero:self
$ODIN test ../test_issue_udivmod128_zero_divisor $COMMON -integer-division-by-zero:all-bits

if [[ -z ${ODIN_TESTS_NO_CLANG+x} ]]; then
	clang -c ../test_issue_sysv_abi/test_issue_sysv_abi.c -o test_issue_sysv_abi_c.o
	$ODIN test ../test_issue_sysv_abi $COMMON
fi

# AVX-512 asked for through -target-features on the default microarch; needs a CPU that has it
if [[ -z ${ODIN_TESTS_NO_CLANG+x} ]]; then
	if grep -qw avx512f /proc/cpuinfo 2>/dev/null; then
		clang -c ../test_issue_avx512_vector_abi/test_issue_avx512_vector_abi.c -o test_issue_avx512_vector_abi_c.o -mavx512f
		$ODIN test ../test_issue_avx512_vector_abi $COMMON_CHECK -target-features:avx512f
	fi
fi

# 32-byte vectors in YMM registers, both sides built with AVX2; needs a CPU that has it
if [[ -z ${ODIN_TESTS_NO_CLANG+x} ]]; then
	if grep -qw avx2 /proc/cpuinfo 2>/dev/null; then
		clang -c ../test_issue_sysv_wide_vectors/test_issue_sysv_wide_vectors.c -o test_issue_sysv_wide_vectors_c.o -mavx2
		$ODIN test ../test_issue_sysv_wide_vectors $COMMON_CHECK -microarch:haswell
	fi
fi

$ODIN test ../test_issue_disabled_proc_value $COMMON -disable-assert
$ODIN test ../test_issue_loaded_pointer_alignment $COMMON -o:speed
$ODIN test ../test_issue_max_simd_align $COMMON -o:speed

$ODIN build ../test_issue_wasi_wasm64p32_target -target:wasi_wasm32 -build-mode:obj $COMMON_CHECK
$ODIN build ../test_issue_wasi_wasm64p32_target -target:wasi_wasm64p32 -build-mode:obj $COMMON_CHECK
if command -v wasmtime > /dev/null; then
	for target in wasi_wasm32 wasi_wasm64p32; do
		for microarch in generic mvp; do
			$ODIN build ../test_issue_wasi_wasm64p32_target -target:$target -microarch:$microarch $COMMON_CHECK
			wasmtime run --dir . --env ODIN_WASI_TEST=value ./test_issue_wasi_wasm64p32_target.wasm first second
		done
	done
fi

$ODIN run ../test_issue_8177 $COMMON
$ODIN build ../test_issue_8177 -target:js_wasm64p32 -build-mode:obj $COMMON_CHECK
$ODIN build ../test_issue_8177 -target:wasi_wasm64p32 -build-mode:obj $COMMON_CHECK
if command -v wasmtime > /dev/null; then
	$ODIN build ../test_issue_8177 -target:wasi_wasm64p32 $COMMON_CHECK
	wasmtime run ./test_issue_8177.wasm
fi

# wasm32 C vectors, both sides without and with simd128; needs wasmtime and a clang that targets wasm32
if [[ -z ${ODIN_TESTS_NO_CLANG+x} ]] && command -v wasmtime > /dev/null; then
	for simd in "" simd128; do
		if clang --target=wasm32 ${simd:+-m$simd} -c ../test_issue_wasm_c_vectors/test_issue_wasm_c_vectors.c -o test_issue_wasm_c_vectors_c.o 2> /dev/null; then
			$ODIN build ../test_issue_wasm_c_vectors -target:wasi_wasm32 ${simd:+-target-features:$simd} $COMMON_CHECK
			wasmtime run ./test_issue_wasm_c_vectors.wasm
		fi
	done
fi
rm -rf issue_7990
mkdir -p issue_7990/test_issue_7990/build issue_7990/test_issue_7990/deep/build issue_7990/directory.data issue_7990/collision issue_7990/.hiddendir
cp ../test_issue_7990/test_issue_7990.odin issue_7990/test_issue_7990/
cp ../test_issue_7990/.hidden.odin issue_7990/
cp ../test_issue_7990/directory.data/main.odin issue_7990/directory.data/
cp ../test_issue_7990/collision.odin issue_7990/
cp ../test_issue_7990/.hiddendir/main.odin issue_7990/.hiddendir/

pushd issue_7990/test_issue_7990/build
"$ODIN_FULL" build ..
test -f test_issue_7990
popd

pushd issue_7990/test_issue_7990/deep/build
"$ODIN_FULL" build ../..
test -f test_issue_7990
popd

$ODIN build issue_7990/directory.data
test -f directory.data

$ODIN build issue_7990/.hiddendir
test -f .hiddendir

"$ODIN_FULL" build issue_7990/.hidden.odin -file
test -f .hidden

pushd issue_7990
"$ODIN_FULL" build collision.odin -file
# This script could be run on Windows as well.
test -f collision.bin || test -f collision.exe
popd

"$ODIN_FULL" build issue_7990/collision.odin -file
test -f collision || test -f collision.exe
test ! -e collision.bin

mkdir -p links
ln -s ../issue_7990/.hiddendir links/spelled_link
$ODIN build links/spelled_link
test -f spelled_link || test -f spelled_link.exe

if [[ $($ODIN build issue_7990/.hiddendir -out:no_such_dir/x 2>&1 | grep -c "does not exist") -eq 1 &&
      $($ODIN build issue_7990/.hiddendir -out:issue_7990 2>&1 | grep -c "is a directory") -eq 1 &&
      $($ODIN build issue_7990/.hiddendir -out:no_such_dir/ 2>&1 | grep -c "give a file name") -eq 1 &&
      $($ODIN build issue_7990/collision.odin -file -out:issue_7990/collision.odin 2>&1 | grep -c "would overwrite the input") -eq 1 &&
      $($ODIN build issue_7990/.hiddendir -build-mode:llvm-ir -out:x.ll 2>&1 | grep -c "existing directory") -eq 1 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi
test ! -e no_such_dir

$ODIN build issue_7990/.hiddendir -build-mode:dll -out:no_extension
test -f no_extension.so || test -f no_extension.dylib || test -f no_extension.dll

DIRECTIVES_OUT=$($ODIN check ../test_paths_directives -no-entry-point $COMMON_CHECK 2>&1 || true)
if [[ $(echo "$DIRECTIVES_OUT" | grep -c "it contains a NUL byte") -eq 1 &&
      $(echo "$DIRECTIVES_OUT" | grep -c "Unknown library collection") -eq 1 &&
      $(echo "$DIRECTIVES_OUT" | grep -c "Error:") -eq 2 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

rm -rf identity
cp -R ../test_paths_identity identity
ln -s pkg identity/alias
$ODIN build identity/main -out:identity_main $COMMON
./identity_main
mkdir identity/loaddir/files
echo b > identity/loaddir/files/b.txt
echo a > identity/loaddir/files/a.txt
echo z > identity/loaddir/z_target.txt
ln -s ../z_target.txt identity/loaddir/files/c_link.txt
$ODIN build identity/loaddir -out:identity_loaddir $COMMON
[[ "$(./identity_loaddir)" == $'a.txt\nb.txt\nc_link.txt' ]]
mkdir -p identity/r4/d identity/r4/src
mv identity/reached/f.odin identity/r4/src/f.odin
cp -R identity/helper identity/r4/d/helper
ln -s ../src/f.odin identity/r4/d/f.odin
$ODIN build identity/r4/d -out:identity_reached $COMMON
./identity_reached

QDIR='q 100%s "x" \y'
rm -rf "$QDIR"
mkdir "$QDIR"
$ODIN build ../test_paths_quoting $COMMON '-define:S=a"b"' '-define:T=c d\' "-out:$QDIR/q"
"./$QDIR/q"
$ODIN build ../test_paths_quoting $COMMON '-define:S=a"b"' '-define:T=c d\' -build-mode:lib "-out:$QDIR/q.a"
[[ -f "$QDIR/q.a" ]]

rm -rf tempfiles
mkdir -p tempfiles/dll
echo keep > tempfiles/t-helper.ll
echo keep > tempfiles/dll/t-helper.o
$ODIN build ../test_paths_tempfiles $COMMON -out:tempfiles/t
./tempfiles/t
$ODIN build ../test_paths_tempfiles $COMMON -build-mode:dll -out:tempfiles/dll/t.so
[[ -f tempfiles/t-helper.ll ]]
[[ -f tempfiles/dll/t-helper.o ]]

rm -rf needed
mkdir -p needed
cp -R ../test_paths_needed/lib ../test_paths_needed/app needed/
if [[ $(uname) == Darwin ]]; then
	$ODIN build ../test_paths_needed/darwin $COMMON -out:needed/darwin_system_dylib
	./needed/darwin_system_dylib
elif command -v readelf > /dev/null; then
	$ODIN build needed/lib $COMMON -build-mode:dll -out:needed/lib/libtpneeded.so
	$ODIN build needed/app $COMMON -out:needed/lib/app
	./needed/lib/app
	[[ $(readelf -d needed/lib/app | grep -c -F '[libtpneeded.so]') -eq 1 ]]
fi

SYMBOLIZER=""
for candidate in llvm-symbolizer-22 llvm-symbolizer-21 llvm-symbolizer-20 llvm-symbolizer-19 llvm-symbolizer; do
	if command -v $candidate > /dev/null; then
		SYMBOLIZER=$candidate
		break
	fi
done
if [[ $(uname) != Darwin ]] && [[ -n $SYMBOLIZER ]] && command -v nm > /dev/null; then
	$ODIN build ../test_paths_debug $COMMON -debug -out:debug_names
	DEBUG_ADDR=$(nm debug_names | grep ' lib::hello$' | awk '{print $1}')
	[[ $($SYMBOLIZER --obj=debug_names 0x$DEBUG_ADDR | grep -c -F 'test_paths_debug/lib/main.odin:') -eq 1 ]]
fi

rm -rf sdk_loop walk_outside walk_cache
mkdir -p sdk_loop/lib walk_outside walk_cache/.odin-cache
ln -s .. sdk_loop/lib/up
if command -v timeout > /dev/null; then
	WALK_STATUS=0
	timeout 120 $ODIN build ../test_paths_debug -target:windows_amd64 -linker:lld -windows-sdk-root:sdk_loop -out:walk.exe > /dev/null 2>&1 || WALK_STATUS=$?
	[[ $WALK_STATUS -ne 124 ]]
fi
echo keep > walk_outside/keep.txt
ln -s ../../walk_outside walk_cache/.odin-cache/outside
echo gone > walk_cache/.odin-cache/gone.txt
(cd walk_cache && "$ODIN_FULL" clear-cache)
[[ ! -e walk_cache/.odin-cache ]]
[[ -f walk_outside/keep.txt ]]

ROOT_OUT="$($ODIN root)"
ODIN_ROOT="$ROOT_OUT" $ODIN check ../test_paths_debug $COMMON_CHECK
ODIN_ROOT="$ROOT_OUT//" $ODIN check ../test_paths_debug $COMMON_CHECK
ODIN_ROOT="${ROOT_OUT%/}" $ODIN check ../test_paths_debug $COMMON_CHECK
rm -f "space_out "
$ODIN build ../test_paths_debug $COMMON "-out:space_out "
[[ -f "space_out " ]]

rm -rf cache_test
mkdir -p cache_test/src
cp -R ../test_paths_debug/. cache_test/src/
$ODIN build cache_test/src -internal-cached -show-timings -out:cache_test/one
CACHE_OUT=$($ODIN build cache_test/src -internal-cached -show-timings -out:cache_test/two 2>&1)
[[ $(grep -c "type check" <<< "$CACHE_OUT") -eq 0 ]]
./cache_test/two
echo "// changed" >> cache_test/src/lib/main.odin
CACHE_OUT=$($ODIN build cache_test/src -internal-cached -show-timings -out:cache_test/three 2>&1)
[[ $(grep -c "type check" <<< "$CACHE_OUT") -eq 1 ]]
"$ODIN_FULL" clear-cache -out:cache_test/x
[[ ! -e cache_test/.odin-cache ]]

PREFIX_DIR="$(cd ../test_paths_prefix_map && pwd -P)"
$ODIN build ../test_paths_prefix_map $COMMON -debug "-path-prefix-map:..=wrong" "-path-prefix-map:$ROOT_OUT=root" "-path-prefix-map:../test_paths_prefix_map=src" -out:prefix_map
./prefix_map
if grep -qaF "$PREFIX_DIR" prefix_map; then exit 1; fi
if grep -qaF "${ROOT_OUT%/}" prefix_map; then exit 1; fi

rm -rf deps_test
mkdir -p 'deps_test/q"x b#$'
cp -R ../test_paths_deps/. 'deps_test/q"x b#$/'
$ODIN build 'deps_test/q"x b#$' $COMMON -export-dependencies:make -export-dependencies-file:deps.d -out:deps
grep -qF 'q"x\ b\#$$/data.txt' deps.d
$ODIN build 'deps_test/q"x b#$' $COMMON -export-dependencies:json -export-dependencies-file:deps.json -out:deps
grep -qF 'q\"x b#$/data.txt"' deps.json

printf '#!/bin/sh\nexit 128\n' > fake_cc_128
printf '#!/bin/sh\nkill -TERM $$\n' > fake_cc_sig
chmod +x fake_cc_128 fake_cc_sig
if ODIN_CLANG_PATH="$PWD/fake_cc_128" $ODIN build ../test_paths_debug $COMMON -out:fake_link; then exit 1; fi
SIG_OUT=$(ODIN_CLANG_PATH="$PWD/fake_cc_sig" $ODIN build ../test_paths_debug $COMMON -out:fake_link 2>&1 || true)
grep -q "terminated by signal 15" <<< "$SIG_OUT"

SB=../test_paths_sandbox
LOAD_OUT=$($ODIN check $SB/load -no-entry-point -sandbox-root:$SB/load -collection:foo=$SB/coll 2>&1 || true)
FOREIGN_OUT=$($ODIN check $SB/foreign -no-entry-point -sandbox-root:$SB/foreign 2>&1 || true)
ROOTS_OUT=$($ODIN check $SB/roots -no-entry-point -sandbox-root:$SB/roots 2>&1 || true)
MAIN_OUT=$($ODIN check $SB/roots -no-entry-point -sandbox-root:../test_issue_6165 2>&1 || true)
if [[ $(echo "$LOAD_OUT" | grep -c "is outside every -sandbox-root") -eq 8 &&
      $(echo "$LOAD_OUT" | grep -c "it contains a NUL byte") -eq 1 &&
      $(echo "$LOAD_OUT" | grep -c "collection and every -sandbox-root") -eq 2 &&
      $(echo "$LOAD_OUT" | grep -c "Error:") -eq 11 &&
      $(echo "$FOREIGN_OUT" | grep -c "must be a name, not a path") -eq 2 &&
      $(echo "$FOREIGN_OUT" | grep -c "is outside every -sandbox-root") -eq 1 &&
      $(echo "$ROOTS_OUT" | grep -c "is outside every -sandbox-root") -eq 2 &&
      $(echo "$MAIN_OUT" | grep -c "The main package") -eq 1 ]]; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi
$ODIN check $SB/foreign -no-entry-point
$ODIN check $SB/roots -no-entry-point
$ODIN check $SB/roots -no-entry-point -sandbox-root:$SB/roots -sandbox-root:../../..
rm -rf sb_link
mkdir -p sb_link/root
printf 'ok\n' > sb_link/root/x.txt
ln -sfn "$PWD/sb_link" sb_link/root/up
printf 'package sb_link\n\nA :: #load("up/root/x.txt", string)\nB :: #exists("up/root/missing.txt")\n\n#assert(A == "ok\\n")\n#assert(!B)\n' > sb_link/root/main.odin
$ODIN check sb_link/root -no-entry-point -sandbox-root:sb_link/root

#########################################################################################################

if [[ ! -z ${ODIN_TESTS_NO_CLANG+x} ]]; then
	echo "!!! WARNING !!! Tests that require clang have been skipped"
fi

#########################################################################################################

set +x

popd
rm -rf build

echo "Issue tests successful."
