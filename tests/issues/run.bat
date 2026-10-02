@echo off

if not exist "build\" mkdir build
pushd build

set COMMON=-define:ODIN_TEST_FANCY=false -file -vet -strict-style -ignore-unused-defineables

@echo on

..\..\..\odin test ..\test_issue_829.odin  %COMMON%   || exit /b
..\..\..\odin test ..\test_issue_1592.odin %COMMON%  || exit /b
..\..\..\odin test ..\test_issue_1730.odin %COMMON% || exit /b
..\..\..\odin test ..\test_issue_2056.odin %COMMON%  || exit /b
..\..\..\odin build ..\test_issue_2113.odin %COMMON% -debug || exit /b
..\..\..\odin test ..\test_issue_2466.odin %COMMON%  || exit /b
..\..\..\odin test ..\test_issue_2615.odin %COMMON%  || exit /b
..\..\..\odin test ..\test_issue_2637.odin %COMMON%  || exit /b
..\..\..\odin test ..\test_issue_2666.odin %COMMON%  || exit /b
..\..\..\odin test ..\test_issue_2694.odin %COMMON%  || exit /b
..\..\..\odin test ..\test_issue_3435.odin %COMMON%  || exit /b
..\..\..\odin test ..\test_issue_4210.odin %COMMON%  || exit /b
..\..\..\odin test ..\test_issue_4364.odin %COMMON%  || exit /b
..\..\..\odin test ..\test_issue_4584.odin %COMMON%  || exit /b
..\..\..\odin build ..\test_issue_2395.odin %COMMON% 2>&1 | find /c "Error:" | findstr /x "2" || exit /b
..\..\..\odin build ..\test_issue_5043.odin %COMMON% || exit /b
..\..\..\odin build ..\test_issue_5097.odin %COMMON% || exit /b
..\..\..\odin build ..\test_issue_5097-2.odin %COMMON% || exit /b
..\..\..\odin check ..\test_issue_5105_5569.odin %COMMON% 2>&1 | find /c "Error:" | findstr /x "4" || exit /b
..\..\..\odin build ..\test_issue_5265.odin %COMMON% || exit /b
..\..\..\odin test ..\test_issue_5318.odin %COMMON%  || exit /b
..\..\..\odin build ..\test_issue_5573.odin %COMMON% 2>&1 | find /c "Error:" | findstr /x "2" || exit /b
..\..\..\odin test ..\test_issue_5699.odin %COMMON%  || exit /b
..\..\..\odin test ..\test_issue_6068.odin %COMMON%  || exit /b
..\..\..\odin test ..\test_issue_6165.odin %COMMON%  || exit /b
..\..\..\odin test ..\test_issue_6302.odin %COMMON%  || exit /b
..\..\..\odin build ..\test_issue_6240.odin %COMMON% 2>&1 | find /c "Error:" | findstr /x "3" || exit /b
..\..\..\odin build ..\test_issue_6401.odin %COMMON% 2>&1 | find /c "Error:" | findstr /x "3" || exit /b
..\..\..\odin test ..\test_issue_6419.odin %COMMON%  || exit /b
..\..\..\odin test ..\test_pr_6470.odin %COMMON%  || exit /b
..\..\..\odin test ..\test_pr_6470.odin -define:TEST_EXPECT_FAILURE=true %COMMON% 2>&1 | find /c "Error:" | findstr /x "1" || exit /b
..\..\..\odin check ..\test_issue_6484.odin -no-entry-point %COMMON%  || exit /b
..\..\..\odin test ..\test_issue_6753.odin %COMMON%  || exit /b
..\..\..\odin check ..\test_issue_6874.odin %COMMON% 2>&1 | find /c "Error:" | findstr /x "1" || exit /b
..\..\..\odin test ..\test_issue_6951_5214.odin %COMMON%  || exit /b
..\..\..\odin check ..\test_issue_6979.odin -no-entry-point %COMMON%  || exit /b
..\..\..\odin test ..\test_issue_7008.odin %COMMON%  || exit /b
..\..\..\odin test ..\test_issue_global_address_of_literal.odin %COMMON%  || exit /b
..\..\..\odin check ..\test_issue_7012.odin -no-entry-point %COMMON% || exit /b
..\..\..\odin check ..\test_issue_7260.odin -no-entry-point %COMMON% || exit /b
..\..\..\odin test ..\test_issue_bool_to_be_conversion.odin %COMMON%  || exit /b
..\..\..\odin test ..\test_issue_bool_comparison_truthiness.odin %COMMON%  || exit /b
..\..\..\odin test ..\test_issue_const_array_broadcast.odin %COMMON%  || exit /b
..\..\..\odin test ..\test_issue_decl_order.odin %COMMON%  || exit /b
..\..\..\odin test ..\test_issue_distinct_constraint.odin %COMMON%  || exit /b
..\..\..\odin check ..\test_issue_ambiguous_union_literal.odin %COMMON% 2>&1 | find /c "Error:" | findstr /x "1" || exit /b
..\..\..\odin test ..\test_issue_proc_constant_instantiation.odin %COMMON%  || exit /b
..\..\..\odin test ..\test_issue_global_when_order.odin %COMMON%  || exit /b
..\..\..\odin check ..\test_issue_global_when_cycle.odin -no-entry-point %COMMON% 2>&1 | find /c "Contradictory global" | findstr /x "4" || exit /b
..\..\..\odin test ..\test_issue_global_when_cycle_accepted.odin %COMMON%  || exit /b
..\..\..\odin check ..\test_issue_global_when_cycle_ambiguous.odin -no-entry-point %COMMON% 2>&1 | find /c "Ambiguous global" | findstr /x "1" || exit /b
..\..\..\odin check ..\test_issue_global_when_shadowing.odin -no-entry-point %COMMON% 2>&1 | find /c "within a global" | findstr /x "2" || exit /b
..\..\..\odin check ..\test_issue_7336.odin -no-entry-point %COMMON% || exit /b
..\..\..\odin check ..\test_issue_ellipsis_type_call.odin -no-entry-point %COMMON% 2>&1 | find /c "Error:" | findstr /x "10" || exit /b
..\..\..\odin check ..\test_issue_foreign_redeclaration.odin -no-entry-point %COMMON% || exit /b
..\..\..\odin check ..\test_issue_foreign_import_attributes.odin -no-entry-point %COMMON% || exit /b
..\..\..\odin check ..\test_issue_foreign_redeclaration_mismatch.odin -no-entry-point %COMMON% 2>&1 | find /c "Error:" | findstr /x "1" || exit /b
..\..\..\odin check ..\test_issue_integer_literal_exponent.odin -no-entry-point %COMMON% 2>&1 | find /c "Error:" | findstr /x "1" || exit /b
..\..\..\odin doc ..\test_issue_asm_doc_category.odin -file 2>&1 | find /c "asm templates" | findstr /x "1" || exit /b
..\..\..\odin build ..\test_issue_7037.odin %COMMON% -o:none  || exit /b
..\..\..\odin test ..\test_issue_7421.odin %COMMON% || exit /b
..\..\..\odin check ..\test_issue_7421_tagged_duplicate.odin %COMMON% 2>&1 | find /c "Error: Duplicate case" | findstr /x "1" || exit /b
..\..\..\odin test ..\test_issue_7430.odin %COMMON%  || exit /b
..\..\..\odin build ..\test_issue_7188.odin %COMMON%  || exit /b
clang -c ..\test_issue_sysv_abi.c -o test_issue_sysv_abi_c.o || exit /b
..\..\..\odin test ..\test_issue_sysv_abi.odin %COMMON%  || exit /b
..\..\..\odin build ..\test_issue_7073-1.odin %COMMON% 2>&1 | find /c "Error:" | findstr /x "2" || exit /b
..\..\..\odin test ..\test_issue_swizzle_multi_assign.odin %COMMON%  || exit /b
..\..\..\odin test ..\test_lifetime_markers.odin %COMMON% -o:size -lifetime-markers  || exit /b
..\..\..\odin test ..\test_lifetime_markers.odin %COMMON% -o:speed -lifetime-markers  || exit /b
..\..\..\odin test ..\test_issue_7547.odin %COMMON%  || exit /b
..\..\..\odin test ..\test_issue_7477_7506.odin %COMMON%  || exit /b
..\..\..\odin run ..\test_issue_7482.odin %COMMON% || exit /b
..\..\..\odin run ..\test_issue_7562.odin %COMMON% -no-crt -no-thread-local || exit /b
..\..\..\odin run ..\test_issue_7562.odin %COMMON% -no-crt -no-thread-local -o:speed || exit /b
..\..\..\odin test ..\test_issue_7316.odin %COMMON%  || exit /b
..\..\..\odin test ..\test_issue_7566.odin %COMMON%  || exit /b
..\..\..\odin test ..\test_issue_poly_using_subtype.odin %COMMON%  || exit /b
..\..\..\odin test ..\test_issue_global_proc_lits.odin %COMMON%  || exit /b
..\..\..\odin test ..\test_issue_packed_field_by_value.odin %COMMON%  || exit /b
..\..\..\odin test ..\test_issue_7708.odin %COMMON%  || exit /b
..\..\..\odin check ..\test_issue_7708_mismatch.odin %COMMON% 2>&1 | find /c "Error:" | findstr /x "2" || exit /b
..\..\..\odin test ..\test_issue_7700.odin %COMMON%  || exit /b
..\..\..\odin test ..\test_issue_procedure_of_specialized.odin %COMMON%  || exit /b
..\..\..\odin test ..\test_issue_7587.odin %COMMON%  || exit /b
..\..\..\odin run ..\test_issue_7596.odin %COMMON% || exit /b

@echo off

popd
rmdir /S /Q build
