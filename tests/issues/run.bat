@echo off
setlocal EnableDelayedExpansion

if not exist "build\" mkdir build
pushd build

set COMMON=-define:ODIN_TEST_FANCY=false -vet -strict-style -ignore-unused-defineables -show-timings -project-root:..
set ODIN=..\..\..\odin
set ODIN_FULL=%CD%\..\..\..\odin.exe

@echo on

@rem #########################################################################################################

@rem CONTRIBUTORS:
@rem   If your test can be run as a simple `odin test`, then please add it to
@rem   `test_simple.odin` instead, to keep CI performance acceptable.
@rem   Otherwise, add it here in the appropriate block, and make sure to
@rem   update `run.sh` as well.

@rem Some tests require a C compiler.
@rem   By default, it uses clang.  set ISSUES_TESTS_NO_CLANG=1  to use MSVC (cl.exe) instead.

@rem #########################################################################################################

@rem Build prerequisites for the simple tests:
@rem   (nothing to do here)

@rem #########################################################################################################

@rem "odin test" - All simple tests that can be tested without special arguments or error handling:
%ODIN% test "..\test_simple.odin" -file -all-packages %COMMON% || exit /b

@rem #########################################################################################################

@rem "odin check" tests:
%ODIN% check "..\test_issue_1909" %COMMON% 2>&1 | find /c "of a built-in procedure cannot be determined" | findstr /x "3" || exit /b
%ODIN% check "..\test_issue_3973" %COMMON% 2>&1 | find /c "Error:" | findstr /x "28" || exit /b
%ODIN% check "..\test_issue_5105_5569" %COMMON% 2>&1 | find /c "Error:" | findstr /x "4" || exit /b
%ODIN% check "..\test_issue_5335" %COMMON% 2>&1 | find /c "Error:" | findstr /x "2" || exit /b
%ODIN% check "..\test_issue_6484" -no-entry-point %COMMON% || exit /b
%ODIN% check "..\test_issue_6874" %COMMON% 2>&1 | find /c "Error:" | findstr /x "1" || exit /b
%ODIN% check "..\test_issue_6979" -no-entry-point %COMMON% || exit /b
%ODIN% check "..\test_issue_7012" -no-entry-point %COMMON% || exit /b
%ODIN% check "..\test_issue_7199" %COMMON% 2>&1 | find /c "..19988 chars.." | findstr /x "1" || exit /b
%ODIN% check "..\test_issue_7260" -no-entry-point %COMMON% || exit /b
%ODIN% check "..\test_issue_7304" %COMMON% 2>&1 | find /c "9223372036854775808 is not representable by int" | findstr /x "1" || exit /b
%ODIN% check "..\test_issue_7336" -no-entry-point %COMMON% || exit /b
%ODIN% check "..\test_issue_7421_tagged_duplicate" %COMMON% 2>&1 | find /c "Error: Duplicate case" | findstr /x "1" || exit /b
%ODIN% check "..\test_issue_7429" %COMMON% || exit /b
%ODIN% check "..\test_issue_7708_mismatch" %COMMON% 2>&1 | find /c "Error:" | findstr /x "2" || exit /b
%ODIN% check "..\test_issue_7938" -no-entry-point %COMMON% 2>&1 | find /c "Error: Missing return statement" | findstr /x "3" || exit /b
%ODIN% check "..\test_issue_7975_7976_mismatch" %COMMON% 2>&1 | find /c "Error:" | findstr /x "8" || exit /b
%ODIN% check "..\test_issue_ambiguous_union_literal" %COMMON% 2>&1 | find /c "Error:" | findstr /x "1" || exit /b
%ODIN% check "..\test_issue_global_when_cycle" -no-entry-point %COMMON% 2>&1 | find /c "Contradictory global" | findstr /x "4" || exit /b
%ODIN% check "..\test_issue_global_when_cycle_ambiguous" -no-entry-point %COMMON% 2>&1 | find /c "Ambiguous global" | findstr /x "1" || exit /b
%ODIN% check "..\test_issue_global_when_shadowing" -no-entry-point %COMMON% 2>&1 | find /c "within a global" | findstr /x "2" || exit /b
%ODIN% check "..\test_issue_ellipsis_type_call" -no-entry-point %COMMON% 2>&1 | find /c "Error:" | findstr /x "10" || exit /b
%ODIN% check "..\test_issue_foreign_redeclaration" -no-entry-point %COMMON% || exit /b
%ODIN% check "..\test_issue_foreign_import_attributes" -no-entry-point %COMMON% || exit /b
%ODIN% check "..\test_issue_foreign_redeclaration_mismatch" -no-entry-point %COMMON% 2>&1 | find /c "Error:" | findstr /x "1" || exit /b
%ODIN% check "..\test_issue_integer_literal_exponent" -no-entry-point %COMMON% 2>&1 | find /c "Error:" | findstr /x "1" || exit /b
%ODIN% check "..\test_issue_inferred_default_overflow" -no-entry-point %COMMON% 2>&1 | find /c "Error: Cannot convert numeric value" | findstr /x "6" || exit /b
%ODIN% check "..\test_issue_fixed_point_scale" %COMMON% 2>&1 | find /c "Error:" | findstr /x "4" || exit /b
%ODIN% check "..\test_issue_poly_proc_value" %COMMON% 2>&1 | find /c "Error:" | findstr /x "4" || exit /b
%ODIN% check "..\test_issue_poly_variadic_errors" %COMMON% 2>&1 | find /c "Error:" | findstr /x "3" || exit /b
%ODIN% check "..\test_issue_poly_variadic_errors" %COMMON% 2>&1 | find /c "Cannot infer the polymorphic type '$E' of the variadic parameter 'args'" | findstr /x "3" || exit /b
%ODIN% check "..\test_issue_atomic_orderings" -no-entry-point %COMMON% 2>&1 | find /c "Warning:" | findstr /x "13" || exit /b
%ODIN% check "..\test_issue_atomic_errors" -no-entry-point %COMMON% 2>&1 | find /c "Error:" | findstr /x "11" || exit /b
%ODIN% check "..\test_issue_atomic_access" -no-entry-point -vet-atomic-access %COMMON% 2>&1 | find /c "Error:" | findstr /x "11" || exit /b
%ODIN% check "..\test_issue_escape_stored_field" -no-entry-point %COMMON% 2>&1 | find /c "Warning:" | findstr /x "3" || exit /b
%ODIN% check "..\test_issue_escape_union_loop" -no-entry-point %COMMON% 2>&1 | find /c "Warning:" | findstr /x "1" || exit /b
%ODIN% check "..\test_issue_escape_diagnostics" -no-entry-point %COMMON% 2>&1 | find /c "Warning:" | findstr /x "4" || exit /b
%ODIN% check "..\test_issue_escape_diagnostics" -no-entry-point %COMMON% 2>&1 | find /c "holds a pointer into itself" | findstr /x "2" || exit /b
%ODIN% check "..\test_issue_escape_diagnostics" -no-entry-point %COMMON% 2>&1 | find /c "is taken at" | findstr /x "4" || exit /b
%ODIN% check "..\test_issue_escape_diagnostics" -no-entry-point %COMMON% 2>&1 | find /c "'temp.allocator.data' may refer to 'temp.arena' in the stack memory of the named result 'temp'" | findstr /x "1" || exit /b
%ODIN% check "..\test_issue_escape_nested_calls" -no-entry-point %COMMON% 2>&1 | find /c "Warning:" | findstr /x "6" || exit /b
%ODIN% check "..\test_issue_escape_cleared_stores" -no-entry-point %COMMON% 2>&1 | find /c "Warning:" | findstr /x "15" || exit /b
%ODIN% check "..\test_issue_escape_cleared_stores" -no-entry-point %COMMON% 2>&1 | find /c "local variable 'y'" | findstr /x "1" || exit /b
%ODIN% test "..\test_issue_type_info_variant_shim" %COMMON% -ignore-warnings || exit /b
%ODIN% check "..\test_issue_type_info_variant_shim" -no-entry-point %COMMON% 2>&1 | find /c "Warning:" | findstr /x "11" || exit /b
%ODIN% check "..\test_issue_type_info_variant_shim_duplicate" -no-entry-point %COMMON% 2>&1 | find /c "Error:" | findstr /x "1" || exit /b
%ODIN% check "..\test_issue_bit_field_tag_identity" -no-entry-point %COMMON% 2>&1 | find /c "Error:" | findstr /x "1" || exit /b
%ODIN% check "..\test_issue_8074" -no-entry-point %COMMON% 2>&1 | find /c "Error:" | findstr /x "34" || exit /b
%ODIN% check "..\test_issue_8258" %COMMON% 2>&1 | find /c "Error: @(test) procedures must be declared at the file scope" | findstr /x "4" || exit /b
%ODIN% test "..\test_issue_invalid_tests_only" %COMMON% 2>&1 | find /c "Error:" | findstr /x "2" || exit /b
%ODIN% check "..\test_issue_8294" %COMMON% 2>&1 | find /c "Error:" | findstr /x "2" || exit /b
%ODIN% check "..\test_issue_5024" %COMMON% 2>&1 | find /c "Error:" | findstr /x "2" || exit /b
%ODIN% check "..\test_issue_8455" %COMMON% 2>&1 | find /c "Error:" | findstr /x "3" || exit /b
%ODIN% check "..\test_issue_8455" %COMMON% 2>&1 | find /c "it is a directory" | findstr /x "3" || exit /b
%ODIN% check "..\test_issue_8513_errors" %COMMON% 2>&1 | find /c "Error:" | findstr /x "3" || exit /b
%ODIN% check "..\test_issue_7947" %COMMON% 2>&1 | find /c "Error: Unspecialized polymorphic procedure literal" | findstr /x "1" || exit /b
%ODIN% check "..\test_issue_7502_cycle" -no-entry-point %COMMON% 2>&1 | find /c "Error:" | findstr /x "3" || exit /b
%ODIN% check "..\test_issue_8097" -no-entry-point %COMMON% 2>&1 | find /c "Error: Invalid use of a polymorphic type" | findstr /x "4" || exit /b
%ODIN% check "..\test_issue_poly_record_unspecialized_field" %COMMON% 2>&1 | find /c "Error:" | findstr /x "4" || exit /b
@rem Objective-C tests target darwin, which can be checked and built for from any host
%ODIN% check "..\test_issue_objc_import_missing_selector" -no-entry-point -target:darwin_arm64 %COMMON% 2>&1 | find /c "is required for imported Objective-C methods" | findstr /x "1" || exit /b
%ODIN% check "..\test_issue_objc_deferred_import" -no-entry-point -target:darwin_arm64 %COMMON% 2>&1 | find /c "cannot be used as a deferred_out procedure" | findstr /x "1" || exit /b
%ODIN% check "..\test_issue_7980" -target:darwin_arm64 %COMMON% 2>&1 | find /c "Error:" | findstr /x "2" || exit /b

@rem #########################################################################################################

@rem "odin build" tests:

%ODIN% build "..\test_issue_2113" %COMMON% -debug || exit /b
%ODIN% build "..\test_issue_objc_class_method_calls" -target:darwin_arm64 -build-mode:obj %COMMON% || exit /b
%ODIN% build "..\test_issue_2395" %COMMON% 2>&1 | find /c "Error:" | findstr /x "2" || exit /b
%ODIN% build "..\test_issue_5043" %COMMON% || exit /b
%ODIN% build "..\test_issue_5097" %COMMON% || exit /b
%ODIN% build "..\test_issue_5097-2" %COMMON% || exit /b
%ODIN% build "..\test_issue_5265" %COMMON% || exit /b
%ODIN% build "..\test_issue_5573" %COMMON% 2>&1 | find /c "Error:" | findstr /x "2" || exit /b
%ODIN% build "..\test_issue_6240" %COMMON% 2>&1 | find /c "Error:" | findstr /x "3" || exit /b
%ODIN% build "..\test_issue_6401" %COMMON% 2>&1 | find /c "Error:" | findstr /x "3" || exit /b
%ODIN% build "..\test_issue_6594" %COMMON% 2>&1 | find /c "Error:" | findstr /x "1" || exit /b
%ODIN% build "..\test_issue_6621" %COMMON% 2>&1 | find /c "Error:" | findstr /x "1" || exit /b
%ODIN% build "..\test_issue_7037" %COMMON% -o:none  || exit /b
%ODIN% build "..\test_issue_7073-1" %COMMON% 2>&1 | find /c "Error:" | findstr /x "2" || exit /b
%ODIN% build "..\test_issue_7108" %COMMON% 2>&1 | find /c "Error" | findstr /x "2" || exit /b
%ODIN% build "..\test_issue_7167" %COMMON% || exit /b
%ODIN% build "..\test_issue_7188" %COMMON% || exit /b
%ODIN% build "..\test_issue_7304" %COMMON% 2>&1 | find /c "9223372036854775808 is not representable by int" | findstr /x "1" || exit /b
%ODIN% build "..\test_issue_7598_all_entities_checked" %COMMON% 2>&1 | find /c "Error:" | findstr /x "4" || exit /b
%ODIN% build "..\test_issue_8554" -build-mode:obj -microarch:native %COMMON% || exit /b
%ODIN% build "..\test_issue_8555" -build-mode:obj -target:linux_arm64 -target-features:contextidrel2,NeoverseV3ae,-CRC %COMMON% || exit /b
%ODIN% build "..\test_issue_8555" -build-mode:obj -target:linux_arm32 -target-features:+slow-load-d-subreg %COMMON% || exit /b

@rem #########################################################################################################

@rem "odin run" tests:
%ODIN% run "..\test_issue_7442" %COMMON% || exit /b
%ODIN% run "..\test_issue_7442" %COMMON% -no-crt -no-thread-local || exit /b
%ODIN% run "..\test_issue_7442" %COMMON% -subsystem:windows || exit /b
%ODIN% run "..\test_issue_7482" %COMMON% || exit /b
%ODIN% run "..\test_issue_7562" %COMMON% -no-crt -no-thread-local || exit /b
%ODIN% run "..\test_issue_7562" %COMMON% -no-crt -no-thread-local -o:speed || exit /b
%ODIN% run "..\test_issue_7564" %COMMON% || exit /b
%ODIN% run "..\test_issue_7596" %COMMON% || exit /b
%ODIN% run "..\test_issue_7798" %COMMON% || exit /b
%ODIN% run "..\test_issue_cstring_hasher_no_crt" %COMMON% -no-crt -no-thread-local -o:speed || exit /b

@rem #########################################################################################################

@rem Test clang - improve error message for users that don't have it.

@if "%ODIN_TESTS_NO_CLANG%" == "" (
	@echo Testing for clang...
	clang --version
	if !ERRORLEVEL! neq 0 (
		@echo ERROR: clang not working. This is required for some tests.
		@echo You can try msvc instead:  set ODIN_TESTS_NO_CLANG=1
		exit /b
	)
) else (
	@echo Testing for msvc...
	cl
	if !ERRORLEVEL! neq 0 (
		@echo ERROR: msvc not working. This is required for some tests.
		@echo You can try clang instead:  set ODIN_TESTS_NO_CLANG=
		exit /b
	)
)

@rem #########################################################################################################

@rem "odin test" tests with special needs, or others (e.g. "odin doc"):
@if "%ODIN_TESTS_NO_CLANG%" == "" (
	clang -c "..\test_issue_5640\test_issue_5640.c" -o test_issue_5640_c.o || exit /b
) else (
	cl -c "..\test_issue_5640\test_issue_5640.c" /Fo:test_issue_5640_c.o || exit /b
)

%ODIN% test "..\test_issue_5640" %COMMON% || exit /b

@if "%ODIN_TESTS_NO_CLANG%" == "" (
	clang -c "..\test_issue_6809_6816\test_issue_6809_6816.c" -o test_issue_6809_6816_c.o -O3 || exit /b
) else (
	cl -c "..\test_issue_6809_6816\test_issue_6809_6816.c" /Fo:test_issue_6809_6816_c.o -O3 || exit /b
)

%ODIN% test "..\test_issue_6809_6816" %COMMON% || exit /b

%ODIN% test "..\test_issue_6344" %COMMON% -o:speed || exit /b

%ODIN% test "..\test_issue_max_simd_align" %COMMON% -o:speed || exit /b
%ODIN% test "..\test_issue_8072" %COMMON% -o:speed -lifetime-markers || exit /b

%ODIN% test "..\test_pr_6470" %COMMON% -define:TEST_EXPECT_FAILURE=true 2>&1 | find /c "Error:" | findstr /x "1" || exit /b

%ODIN% test "..\test_issue_define_config" %COMMON% -define:DEFINE_VERSION=1.0 -define:DEFINE_MODE=true -define:DEFINE_HEX=-0x7f -define:DEFINE_MAX_U8=255 -define:DEFINE_MIN_I32=-2_147_483_648 -define:DEFINE_INTEGRAL_FLOAT=2.0 -define:DEFINE_INT_FOR_FLOAT=3 -define:DEFINE_EXPONENT=1_000e-3 -define:DEFINE_SEPARATORS=1_000_000 -define:DEFINE_RUNE=65 -define:DEFINE_ENUM=C -define:DEFINE_QUOTED='x' -define:DEFINE_EMPTY= "-define:DEFINE_SPACED=a b" -define:DEFINE_CSTRING=c -define:DEFINE_DISTINCT_STRING=d || exit /b
set DEFINE_ERRORS=-define:DEFINE_NOT_A_NUMBER=abc -define:DEFINE_OUT_OF_RANGE=256 -define:DEFINE_TRUNCATED=1.5 -define:DEFINE_NOT_A_BOOL=T -define:DEFINE_EMPTY= -define:DEFINE_NOT_A_FIELD=C -define:DEFINE_NOT_SETTABLE=A -define:DEFINE_QUOTED_NUMBER='1'
%ODIN% check "..\test_issue_define_config_errors" -no-entry-point %COMMON% %DEFINE_ERRORS% 2>&1 | find /c "Error:" | findstr /x "8" || exit /b
%ODIN% check "..\test_issue_define_config_errors" -no-entry-point %COMMON% %DEFINE_ERRORS% 2>&1 | find /c "-define:DEFINE_" | findstr /x "8" || exit /b
%ODIN% check "..\test_issue_define_config" -no-entry-point -vet -strict-style -define:DEFINE_VERSION=1.0 -define:DEFINE_NOWHERE=1 2>&1 | find /c "is unused in the project" | findstr /x "1" || exit /b

%ODIN% check "..\test_pr_7848\pkg_b" "..\test_pr_7848\pkg_a" -no-entry-point -workspace -overlay:..\test_pr_7848\overlay.json %COMMON% -export-semantics:json -export-semantics-file:pr_7848.json || exit /b
%ODIN% check "..\test_pr_7848\pkg_b" "..\test_pr_7848\pkg_a" -no-entry-point -workspace -overlay:..\test_pr_7848\overlay.json %COMMON% -export-semantics:cbor -export-semantics-file:pr_7848.cbor || exit /b
%ODIN% check "..\test_pr_7848\pkg_b" "..\test_pr_7848\pkg_a" -no-entry-point -workspace -overlay:..\test_pr_7848\overlay.json %COMMON% -export-semantics:cbor -export-semantics-file:pr_7848_again.cbor || exit /b
fc /b pr_7848.cbor pr_7848_again.cbor > nul || exit /b
%ODIN% test "..\test_pr_7848" %COMMON% || exit /b

@rem It seems at this point 7010 is not for Windows.
@rem @if "%ODIN_TESTS_NO_CLANG%" == "" (
@rem 	clang -c "..\test_issue_7010\test_issue_7010.c" -o test_issue_7010_c.o || exit /b
@rem 	%ODIN% test "..\test_issue_7010" %COMMON% || exit /b
@rem ) else (
@rem 	@echo "!!! WARNING !!! test_issue_7010 is not compatible with MSVC."
@rem )

%ODIN% test "..\test_issue_7547" %COMMON% || exit /b

%ODIN% test "..\test_issue_split_globals" -define:ODIN_TEST_FANCY=false -vet -strict-style -ignore-unused-defineables || exit /b
%ODIN% test "..\test_issue_split_globals" -define:ODIN_TEST_FANCY=false -vet -strict-style -ignore-unused-defineables -debug || exit /b

%ODIN% test "..\test_issue_fast_isel_lowering" %COMMON% -o:none || exit /b

%ODIN% test "..\test_issue_equal_proc_dependencies" %COMMON% -build-mode:obj 2>&1 | find /i /c "missing procedure" | findstr /x "0" || exit /b

@rem `asm` templates are amd64-only, assuming this is going to work on Windows (ARM?)
%ODIN% doc "..\test_issue_asm_doc_category" 2>&1 | find /c "asm templates" | findstr /x "1" || exit /b
%ODIN% check "..\test_issue_asm_deferred_errors" %COMMON% 2>&1 | find /c "Unknown mnemonic" | findstr /x "5" || exit /b
%ODIN% check "..\test_issue_asm_target_features" %COMMON% 2>&1 | find /c "Error:" | findstr /x "3" || exit /b
%ODIN% check "..\test_issue_asm_target_features" %COMMON% 2>&1 | find /c "enables target feature 'avx'" | findstr /x "3" || exit /b
%ODIN% test "..\test_issue_asm_pinned_clobbers" %COMMON% -o:speed || exit /b
%ODIN% test "..\test_issue_asm_named_register_clobbers" %COMMON% -o:speed || exit /b
%ODIN% test "..\test_issue_asm_call_clobbers" %COMMON% -o:speed || exit /b
%ODIN% test "..\test_issue_asm_written_inputs" %COMMON% -o:speed || exit /b
%ODIN% check "..\test_issue_asm_clobber_pinned_output" %COMMON% 2>&1 | find /c "which '#clobber' also names" | findstr /x "3" || exit /b
%ODIN% check "..\test_issue_asm_call_flow" %COMMON% 2>&1 | find /c "Error:" | findstr /x "1" || exit /b
%ODIN% check "..\test_issue_asm_call_flow" %COMMON% 2>&1 | find /c "can fall through the end" | findstr /x "1" || exit /b
%ODIN% check "..\test_issue_asm_call_flow" %COMMON% 2>&1 | find /c "Warning:" | findstr /x "0" || exit /b
%ODIN% check "..\test_issue_asm_align_stack" %COMMON% 2>&1 | find /c "Error:" | findstr /x "4" || exit /b
%ODIN% check "..\test_issue_asm_align_stack" %COMMON% 2>&1 | find /c "must declare #align_stack" | findstr /x "4" || exit /b
%ODIN% check "..\test_issue_asm_align_stack" %COMMON% 2>&1 | find /c "#align_stack is redundant" | findstr /x "1" || exit /b
%ODIN% check "..\test_issue_asm_call_targets" %COMMON% 2>&1 | find /c "Error:" | findstr /x "8" || exit /b
%ODIN% check "..\test_issue_asm_call_targets" %COMMON% 2>&1 | find /c "uses the Odin calling convention" | findstr /x "3" || exit /b
%ODIN% check "..\test_issue_asm_call_targets" %COMMON% 2>&1 | find /c "as the target of a call" | findstr /x "2" || exit /b
%ODIN% check "..\test_issue_asm_call_targets" %COMMON% 2>&1 | find /c "Assertion Failure" | findstr /x "0" || exit /b
%ODIN% check "..\test_issue_asm_shift_cl_errors" %COMMON% 2>&1 | find /c "Error:" | findstr /x "12" || exit /b
%ODIN% check "..\test_issue_asm_shift_cl_errors" %COMMON% 2>&1 | find /c "8-bit operand pinned to" | findstr /x "5" || exit /b
%ODIN% check "..\test_issue_asm_shift_cl_errors" %COMMON% 2>&1 | find /c "expects 3 operands, got 2" | findstr /x "1" || exit /b
%ODIN% check "..\test_issue_asm_shift_cl_errors" %COMMON% 2>&1 | find /c "is declared but never used" | findstr /x "1" || exit /b
%ODIN% check "..\test_issue_asm_accumulator_forms" %COMMON% 2>&1 | find /c "Error:" | findstr /x "4" || exit /b
%ODIN% check "..\test_issue_asm_accumulator_forms" %COMMON% 2>&1 | find /c "takes no implicit accumulator" | findstr /x "4" || exit /b
%ODIN% check "..\test_issue_asm_writeback_errors" -target:linux_arm64 %COMMON% 2>&1 | find /c "Error:" | findstr /x "4" || exit /b
%ODIN% check "..\test_issue_asm_writeback_errors" -target:linux_arm64 %COMMON% 2>&1 | find /c "writes back its base register" | findstr /x "1" || exit /b
%ODIN% check "..\test_issue_asm_writeback_errors" -target:linux_arm64 %COMMON% 2>&1 | find /c "takes only a base register and a constant offset" | findstr /x "1" || exit /b
%ODIN% check "..\test_issue_asm_writeback_errors" -target:linux_arm64 %COMMON% 2>&1 | find /c "needs a base register" | findstr /x "1" || exit /b
%ODIN% check "..\test_issue_asm_baseless_errors" -target:linux_arm64 %COMMON% 2>&1 | find /c "Error:" | findstr /x "2" || exit /b
%ODIN% check "..\test_issue_asm_baseless_errors" -target:linux_arm64 %COMMON% 2>&1 | find /c "needs a base register" | findstr /x "2" || exit /b
%ODIN% check "..\test_issue_asm_baseless_errors" -target:linux_riscv64 %COMMON% 2>&1 | find /c "Error:" | findstr /x "2" || exit /b
%ODIN% check "..\test_issue_asm_baseless_errors" -target:linux_riscv64 %COMMON% 2>&1 | find /c "must be from -2048 to 2047" | findstr /x "2" || exit /b
%ODIN% build "..\test_issue_asm_baseless_riscv" -target:linux_riscv64 -build-mode:obj %COMMON% || exit /b
%ODIN% build "..\test_issue_asm_keyword_mnemonic" -target:linux_amd64 -build-mode:obj %COMMON% || exit /b

%ODIN% run "..\test_issue_wasm_union_i128" %COMMON% || exit /b
%ODIN% build "..\test_issue_wasm_union_i128" -target:js_wasm32 -build-mode:obj %COMMON% || exit /b
%ODIN% build "..\test_issue_wasm_union_i128" -target:js_wasm64p32 -build-mode:obj %COMMON% || exit /b
%ODIN% build "..\test_issue_wasm_union_i128" -target:wasi_wasm32 -build-mode:obj %COMMON% || exit /b

%ODIN% test "..\test_lifetime_markers" %COMMON% -o:size -lifetime-markers || exit /b
%ODIN% test "..\test_lifetime_markers" %COMMON% -o:speed -lifetime-markers || exit /b

%ODIN% test "..\test_issue_udivmod128_zero_divisor" %COMMON% -integer-division-by-zero:zero     || exit /b
%ODIN% test "..\test_issue_udivmod128_zero_divisor" %COMMON% -integer-division-by-zero:self     || exit /b
%ODIN% test "..\test_issue_udivmod128_zero_divisor" %COMMON% -integer-division-by-zero:all-bits || exit /b

%ODIN% build "..\test_issue_wasi_wasm64p32_target" -target:wasi_wasm32 -build-mode:obj %COMMON% || exit /b
%ODIN% build "..\test_issue_wasi_wasm64p32_target" -target:wasi_wasm64p32 -build-mode:obj %COMMON% || exit /b

@if "%ODIN_TESTS_NO_CLANG%" == "" (
	clang -c "..\test_issue_sysv_abi\test_issue_sysv_abi.c" -o test_issue_sysv_abi_c.o || exit /b
) else (
	cl -c "..\test_issue_sysv_abi\test_issue_sysv_abi.c" /Fo:test_issue_sysv_abi_c.o || exit /b
)

%ODIN% test "..\test_issue_sysv_abi" %COMMON% || exit /b

@if "%ODIN_TESTS_NO_CLANG%" == "" (
	clang -c "..\test_issue_win64_wide_vector_args\test_issue_win64_wide_vector_args.c" -o test_issue_win64_wide_vector_args_c.o -mavx2 || exit /b
) else (
	cl -c "..\test_issue_win64_wide_vector_args\test_issue_win64_wide_vector_args.c" /Fo:test_issue_win64_wide_vector_args_c.o /arch:AVX2 || exit /b
)

%ODIN% test "..\test_issue_win64_wide_vector_args" %COMMON% || exit /b
%ODIN% test "..\test_issue_win64_wide_vector_args" %COMMON% -microarch:haswell || exit /b
if exist issue_7990 rmdir /S /Q issue_7990
mkdir issue_7990\test_issue_7990\build
mkdir issue_7990\test_issue_7990\deep\build
mkdir issue_7990\directory.data
mkdir issue_7990\collision
mkdir issue_7990\.hiddendir
copy ..\test_issue_7990\test_issue_7990.odin issue_7990\test_issue_7990\ > nul || exit /b
copy ..\test_issue_7990\.hidden.odin issue_7990\ > nul || exit /b
copy ..\test_issue_7990\directory.data\main.odin issue_7990\directory.data\ > nul || exit /b
copy ..\test_issue_7990\collision.odin issue_7990\ > nul || exit /b
copy ..\test_issue_7990\.hiddendir\main.odin issue_7990\.hiddendir\ > nul || exit /b
pushd issue_7990\test_issue_7990\build
"%ODIN_FULL%" build .. || exit /b
if not exist test_issue_7990.exe exit /b
popd
pushd issue_7990\test_issue_7990\deep\build
"%ODIN_FULL%" build ..\.. || exit /b
if not exist test_issue_7990.exe exit /b
popd
%ODIN% build "issue_7990\directory.data" || exit /b
if not exist directory.data.exe exit /b
%ODIN% build "issue_7990\.hiddendir" || exit /b
if not exist .hiddendir.exe exit /b
"%ODIN_FULL%" build "issue_7990\.hidden.odin" -file || exit /b
if not exist .hidden.exe exit /b
pushd issue_7990
"%ODIN_FULL%" build collision.odin -file || exit /b
if not exist collision.exe exit /b
popd
"%ODIN_FULL%" build issue_7990\collision.odin -file || exit /b
if not exist collision.exe exit /b 1
mklink /J spelled_link issue_7990\.hiddendir > nul || exit /b
%ODIN% build spelled_link || exit /b
if not exist spelled_link.exe exit /b 1
%ODIN% build issue_7990\.hiddendir -out:no_such_dir\x.exe 2>&1 | find /c "does not exist" | findstr /x "1" || exit /b
%ODIN% build issue_7990\.hiddendir -out:issue_7990 2>&1 | find /c "is a directory" | findstr /x "1" || exit /b
%ODIN% build issue_7990\.hiddendir -out:no_such_dir\ 2>&1 | find /c "give a file name" | findstr /x "1" || exit /b
%ODIN% build issue_7990\collision.odin -file -out:issue_7990\collision.odin 2>&1 | find /c "would overwrite the input" | findstr /x "1" || exit /b
%ODIN% build issue_7990\.hiddendir -build-mode:llvm-ir -out:x.ll 2>&1 | find /c "existing directory" | findstr /x "1" || exit /b
%ODIN% build issue_7990\.hiddendir -out:nul.exe 2>&1 | find /c "reserved device name" | findstr /x "1" || exit /b
%ODIN% build issue_7990\.hiddendir -out:ab:c.exe 2>&1 | find /c "not a valid file name" | findstr /x "1" || exit /b
%ODIN% build C:\ 2>&1 | find /c "is the filesystem root" | findstr /x "1" || exit /b
if exist no_such_dir exit /b 1
%ODIN% build issue_7990\.hiddendir -out:no_extension || exit /b
if not exist no_extension.exe exit /b 1
%ODIN% build issue_7990\.hiddendir -build-mode:dll -out:no_extension || exit /b
if not exist no_extension.dll exit /b 1
rmdir spelled_link

%ODIN% check ..\test_paths_directives -no-entry-point %COMMON% 2>&1 | find /c "it contains a NUL byte" | findstr /x "1" || exit /b
%ODIN% check ..\test_paths_directives -no-entry-point %COMMON% 2>&1 | find /c "Unknown library collection" | findstr /x "1" || exit /b
%ODIN% check ..\test_paths_directives -no-entry-point %COMMON% 2>&1 | find /c "Error:" | findstr /x "2" || exit /b

if exist identity\alias rmdir identity\alias
if exist identity rmdir /S /Q identity
%SystemRoot%\System32\xcopy.exe /E /I /Q ..\test_paths_identity identity > nul || exit /b
mklink /J identity\alias identity\pkg > nul || exit /b
%ODIN% build identity\main -out:identity_main.exe %COMMON% || exit /b
.\identity_main.exe || exit /b
%ODIN% build identity\main_case -out:identity_case.exe %COMMON% || exit /b
.\identity_case.exe || exit /b
mkdir identity\loaddir\files
echo b> identity\loaddir\files\b.txt
echo a> identity\loaddir\files\a.txt
%ODIN% build identity\loaddir -out:identity_loaddir.exe %COMMON% || exit /b
.\identity_loaddir.exe > identity_loaddir.txt || exit /b
%SystemRoot%\System32\findstr.exe /n "^" identity_loaddir.txt | %SystemRoot%\System32\findstr.exe /b /l /c:"1:a.txt" || exit /b
%SystemRoot%\System32\findstr.exe /n "^" identity_loaddir.txt | %SystemRoot%\System32\findstr.exe /b /l /c:"2:b.txt" || exit /b
%SystemRoot%\System32\find.exe /c /v "" identity_loaddir.txt | %SystemRoot%\System32\findstr.exe /e ": 2" || exit /b
rmdir identity\alias

if exist "quote 100%%" rmdir /S /Q "quote 100%%"
mkdir "quote 100%%"
%ODIN% build ..\test_paths_quoting %COMMON% -define:S=a\"b\" "-define:T=c d\\" "-out:quote 100%%\q.exe" || exit /b
"quote 100%%\q.exe" || exit /b

if exist tempfiles rmdir /S /Q tempfiles
mkdir tempfiles\dll
echo keep> tempfiles\t-helper.ll
echo keep> tempfiles\dll\t-helper.obj
%ODIN% build ..\test_paths_tempfiles %COMMON% -out:tempfiles\t.exe || exit /b
.\tempfiles\t.exe || exit /b
%ODIN% build ..\test_paths_tempfiles %COMMON% -build-mode:dll -out:tempfiles\dll\t.dll || exit /b
if not exist tempfiles\t-helper.ll exit /b 1
if not exist tempfiles\dll\t-helper.obj exit /b 1

%ODIN% build ..\test_paths_resource %COMMON% -resource:..\test_paths_resource\res.rc -out:resource_default.exe || exit /b
.\resource_default.exe || exit /b
%ODIN% build ..\test_paths_resource %COMMON% -resource:..\test_paths_resource\res.rc -linker:lld -out:resource_lld.exe || exit /b
.\resource_lld.exe || exit /b

if exist walk_cache\.odin-cache\outside rmdir walk_cache\.odin-cache\outside
if exist walk_cache rmdir /S /Q walk_cache
if exist walk_outside rmdir /S /Q walk_outside
mkdir walk_cache\.odin-cache\sub
mkdir walk_outside
echo keep> walk_outside\keep.txt
echo gone> walk_cache\.odin-cache\sub\gone.txt
mklink /J walk_cache\.odin-cache\outside walk_outside > nul || exit /b
pushd walk_cache
"%ODIN_FULL%" clear-cache || exit /b
popd
if exist walk_cache\.odin-cache exit /b 1
if not exist walk_outside\keep.txt exit /b 1

for /f "delims=" %%R in ('%ODIN% root') do set "ROOT_OUT=%%R"
setlocal
set "ODIN_ROOT=%ROOT_OUT%"
%ODIN% check ..\test_paths_debug %COMMON% || exit /b
set "ODIN_ROOT=%ROOT_OUT:\=/%"
%ODIN% check ..\test_paths_debug %COMMON% || exit /b
set "ODIN_ROOT=%ROOT_OUT%\"
%ODIN% check ..\test_paths_debug %COMMON% || exit /b
endlocal

if exist cache_test rmdir /S /Q cache_test
mkdir cache_test\src
%SystemRoot%\System32\xcopy.exe /E /I /Q ..\test_paths_debug cache_test\src > nul || exit /b
%ODIN% build cache_test\src -internal-cached -show-timings -out:cache_test\one.exe || exit /b
%ODIN% build cache_test\src -internal-cached -show-timings -out:cache_test\two.exe 2>&1 | %SystemRoot%\System32\find.exe /c "type check" | findstr /x "0" || exit /b
.\cache_test\two.exe || exit /b
%ODIN% build cache_test\src -internal-cached -debug -show-timings -out:cache_test\dbg.exe || exit /b
del cache_test\dbg.pdb
%ODIN% build cache_test\src -internal-cached -debug -show-timings -out:cache_test\dbg.exe 2>&1 | %SystemRoot%\System32\find.exe /c "type check" | findstr /x "0" || exit /b
if not exist cache_test\dbg.pdb exit /b 1
echo // changed>> cache_test\src\lib\main.odin
%ODIN% build cache_test\src -internal-cached -show-timings -out:cache_test\three.exe 2>&1 | %SystemRoot%\System32\find.exe /c "type check" | findstr /x "1" || exit /b
%ODIN% clear-cache -out:cache_test\x.exe || exit /b
if exist cache_test\.odin-cache exit /b 1

set "SEG=long_path_segment_0123456789_0123456789_0123456789_0123456789"
set "LP=%CD%\long_path\%SEG%\%SEG%\%SEG%\%SEG%\%SEG%"
if exist long_path rmdir /S /Q "\\?\%CD%\long_path"
md "\\?\%LP%\lib" || exit /b
echo package main> "\\?\%LP%\main.odin"
echo import "lib">> "\\?\%LP%\main.odin"
echo main :: proc() { lib.f() }>> "\\?\%LP%\main.odin"
echo package lib> "\\?\%LP%\lib\lib.odin"
echo f :: proc() {}>> "\\?\%LP%\lib\lib.odin"
%ODIN% check "%LP%" %COMMON% || exit /b
%ODIN% build "%LP%" %COMMON% -linker:lld -internal-cached "-out:%LP%\out.exe" || exit /b
%ODIN% build "%LP%" %COMMON% -linker:lld -internal-cached "-out:%LP%\out.exe" 2>&1 | %SystemRoot%\System32\find.exe /c "type check" | findstr /x "0" || exit /b
%ODIN% clear-cache "-out:%LP%\out.exe" || exit /b
if exist "\\?\%LP%\.odin-cache" exit /b 1
if not exist "\\?\%LP%\out.exe" exit /b 1
rmdir /S /Q "\\?\%CD%\long_path" || exit /b

%ODIN% build ..\test_paths_prefix_map %COMMON% -debug "-path-prefix-map:..=wrong" "-path-prefix-map:%ROOT_OUT%=root" "-path-prefix-map:..\test_paths_prefix_map=src" -out:prefix_map.exe || exit /b
.\prefix_map.exe || exit /b

if exist deps_test rmdir /S /Q deps_test
%SystemRoot%\System32\xcopy.exe /E /I /Q ..\test_paths_deps "deps_test\a b#$" > nul || exit /b
%ODIN% build "deps_test\a b#$" %COMMON% -export-dependencies:make -export-dependencies-file:deps.d -out:deps.exe || exit /b
%SystemRoot%\System32\find.exe "deps_test/a\ b\#$$/data.txt" deps.d || exit /b
%ODIN% build "deps_test\a b#$" %COMMON% -export-dependencies:json -export-dependencies-file:deps.json -out:deps.exe || exit /b
%SystemRoot%\System32\find.exe "deps_test/a b#$/data.txt" deps.json || exit /b

set CONFINE=..\test_paths_confinement
%ODIN% check %CONFINE%\load -no-entry-point -project-root:.. -collection:foo=%CONFINE%\coll 2>&1 | find /c "is outside the project root" | findstr /x "6" || exit /b
%ODIN% check %CONFINE%\load -no-entry-point -project-root:.. -collection:foo=%CONFINE%\coll 2>&1 | find /c "it contains a NUL byte" | findstr /x "1" || exit /b
%ODIN% check %CONFINE%\load -no-entry-point -project-root:.. -collection:foo=%CONFINE%\coll 2>&1 | find /c "leaves the" | findstr /x "2" || exit /b
%ODIN% check %CONFINE%\load -no-entry-point -project-root:.. -collection:foo=%CONFINE%\coll 2>&1 | find /c "Error:" | findstr /x "9" || exit /b
%ODIN% check %CONFINE%\foreign -no-entry-point -project-root:.. 2>&1 | find /c "is a name, not a path" | findstr /x "2" || exit /b
%ODIN% check %CONFINE%\foreign -no-entry-point -project-root:.. 2>&1 | find /c "is outside the project root" | findstr /x "1" || exit /b
%ODIN% check %CONFINE%\widen -no-entry-point -project-root:..\..\.. || exit /b
%ODIN% check %CONFINE%\widen -no-entry-point -project-root:..\test_issue_6165 2>&1 | find /c "is outside -project-root" | findstr /x "1" || exit /b

@rem #########################################################################################################

@echo off

popd
rmdir /S /Q build

@echo Issue tests successful.
