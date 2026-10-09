package tests_issues

// CONTRIBUTORS:
//   If your test can be run normally with `odin test` and without extra build steps or custom compiler flags,
//   you can preferably add it here.
//   Otherwise, add it to `run.bat` and `run.sh`.

@(require) import "test_issue_829"
@(require) import "test_issue_1592"
@(require) import "test_issue_1730"
@(require) import "test_issue_2056"
@(require) import "test_issue_2466"
@(require) import "test_issue_2615"
@(require) import "test_issue_2637"
@(require) import "test_issue_2666"
@(require) import "test_issue_2694"
@(require) import "test_issue_3435"
@(require) import "test_issue_4210"
@(require) import "test_issue_4364"
@(require) import "test_issue_4584"
@(require) import "test_issue_5318"
@(require) import "test_issue_5699"
@(require) import "test_issue_6068"
@(require) import "test_issue_6165"
@(require) import "test_issue_6302"
@(require) import "test_issue_6419"
@(require) import "test_issue_6344"
//@(require) import "test_issue_6344.odin $COMMON -o:speed
@(require) import "test_issue_6396"
@(require) import "test_pr_6470"
//if [[ $($ODIN test ../test_pr_6470.odin -define:TEST_EXPECT_FAILURE=true $COMMON 2>&1 >/dev/null | grep -c "Error:") -eq 1 ]]; then
@(require) import "test_issue_6753"
@(require) import "test_issue_6951_5214"
@(require) import "test_issue_7008"
@(require) import "test_issue_7316"
@(require) import "test_issue_7336"
@(require) import "test_issue_7356"
@(require) import "test_issue_7421"
@(require) import "test_issue_7430"
@(require) import "test_issue_7477_7506"
@(require) import "test_issue_7490"
@(require) import "test_issue_7547"
@(require) import "test_issue_7566"
@(require) import "test_issue_7587"
@(require) import "test_issue_7598"
@(require) import "test_issue_7700"
@(require) import "test_issue_7708"
@(require) import "test_issue_7779"
@(require) import "test_issue_omitted_field_union"
@(require) import "test_issue_equal_proc_dependencies"
@(require) import "test_issue_global_address_of_literal"
@(require) import "test_issue_bool_to_be_conversion"
@(require) import "test_issue_bool_comparison_truthiness"
@(require) import "test_issue_const_array_broadcast"
@(require) import "test_issue_decl_order"
@(require) import "test_issue_distinct_constraint"
@(require) import "test_issue_proc_constant_instantiation"
@(require) import "test_issue_swizzle_multi_assign"
@(require) import "test_issue_global_when_order"
@(require) import "test_issue_global_when_cycle_accepted"
@(require) import "test_issue_poly_using_subtype"
@(require) import "test_issue_global_proc_lits"
@(require) import "test_issue_packed_field_by_value"
@(require) import "test_issue_procedure_of_specialized"
@(require) import "test_issue_sysv_abi"
//$ODIN test ../test_issue_split_globals -define:ODIN_TEST_FANCY=false -vet -strict-style -ignore-unused-defineables
//$ODIN test ../test_issue_split_globals -define:ODIN_TEST_FANCY=false -vet -strict-style -ignore-unused-defineables -debug
//@(require) import "test_issue_fast_isel_lowering.odin $COMMON
//@(require) import "test_issue_fast_isel_lowering.odin $COMMON -o:none
//@(require) import "test_issue_equal_proc_dependencies.odin $COMMON
//if [[ $($ODIN test ../test_issue_equal_proc_dependencies.odin $COMMON -build-mode:obj 2>&1 | grep -ci "missing procedure") -eq 0 ]]; then
//	echo "SUCCESSFUL 1/1"
//else
//	echo "SUCCESSFUL 0/1"
//	exit 1
//fi
//if [[ $($ODIN check ../test_issue_7421_tagged_duplicate.odin $COMMON_CHECK 2>&1 >/dev/null | grep -c "Error: Duplicate case") -eq 1 ]]; then
//	echo "SUCCESSFUL 1/1"
//else
//	echo "SUCCESSFUL 0/1"
//	exit 1
//fi






//clang -c ../test_issue_7010.c -o test_issue_7010_c.o
//$ODIN test ../test_issue_7010.odin $COMMON
//
//clang -c ../test_issue_sysv_abi.c -o test_issue_sysv_abi_c.o
//
//clang -c ../test_issue_6809_6816.c -o test_issue_6809_6816_c.o -O3
//$ODIN test ../test_issue_6809_6816.odin -o:speed $COMMON

//clang -c ../test_issue_5640.c -o test_issue_5640_c.o
//if [[ "$(uname)" != "NetBSD" ]]; then
//	$ODIN test ../test_issue_5640.odin -o:none --sanitize:address $COMMON
//else
//	$ODIN test ../test_issue_5640.odin -o:none $COMMON
//fi

//$ODIN test ../test_lifetime_markers.odin $COMMON -o:size -lifetime-markers
//$ODIN test ../test_lifetime_markers.odin $COMMON -o:speed -lifetime-markers


