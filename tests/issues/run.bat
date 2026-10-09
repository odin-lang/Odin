@echo off

if not exist "build\" mkdir build
pushd build

set COMMON=-define:ODIN_TEST_FANCY=false -vet -strict-style -ignore-unused-defineables
set ODIN=..\..\..\odin

@echo on

@rem #########################################################################################################

@rem CONTRIBUTORS:
@rem   If your test can be run as a simple `odin test`, then please add it to
@rem   `test_simple.odin` instead, to keep CI performance acceptable.
@rem   Otherwise, add it here in the appropriate block, and make sure to
@rem   update `run.sh` as well.

@rem Some tests require a C compiler.
@rem   By default, it uses clang.  set ISSUES_TESTS_NO_CLANG=1  to use MSVC (cl.exe) instead.
@rem   NOTE: Not all tests are compatible with MSVC.

@rem #########################################################################################################

@rem Build prerequisites for the simple tests:
@rem   (nothing to do here)

@rem #########################################################################################################

@rem "odin test" - All simple tests that can be tested without special arguments or error handling:
%ODIN% test "..\test_simple.odin" -file -all-packages %COMMON% || exit /b

@rem #########################################################################################################

@rem "odin check" tests:
%ODIN% check "..\test_issue_5105_5569" %COMMON% 2>&1 | find /c "Error:" | findstr /x "4" || exit /b
%ODIN% check "..\test_issue_6484" -no-entry-point %COMMON%  || exit /b
%ODIN% check "..\test_issue_6874" %COMMON% 2>&1 | find /c "Error:" | findstr /x "1" || exit /b
%ODIN% check "..\test_issue_6979" -no-entry-point %COMMON%  || exit /b
%ODIN% check "..\test_issue_7012" -no-entry-point %COMMON% || exit /b
%ODIN% check "..\test_issue_7260" -no-entry-point %COMMON% || exit /b
%ODIN% check "..\test_issue_7421_tagged_duplicate" %COMMON% 2>&1 | find /c "Error: Duplicate case" | findstr /x "1" || exit /b
%ODIN% check "..\test_issue_7429" %COMMON% || exit /b
%ODIN% check "..\test_issue_7708_mismatch" %COMMON% 2>&1 | find /c "Error:" | findstr /x "2" || exit /b
%ODIN% check "..\test_issue_ambiguous_union_literal" %COMMON% 2>&1 | find /c "Error:" | findstr /x "1" || exit /b
%ODIN% check "..\test_issue_global_when_cycle" -no-entry-point %COMMON% 2>&1 | find /c "Contradictory global" | findstr /x "4" || exit /b
%ODIN% check "..\test_issue_global_when_cycle_ambiguous" -no-entry-point %COMMON% 2>&1 | find /c "Ambiguous global" | findstr /x "1" || exit /b
%ODIN% check "..\test_issue_global_when_shadowing" -no-entry-point %COMMON% 2>&1 | find /c "within a global" | findstr /x "2" || exit /b
%ODIN% check "..\test_issue_7336" -no-entry-point %COMMON% || exit /b
%ODIN% check "..\test_issue_ellipsis_type_call" -no-entry-point %COMMON% 2>&1 | find /c "Error:" | findstr /x "10" || exit /b
%ODIN% check "..\test_issue_foreign_redeclaration" -no-entry-point %COMMON% || exit /b
%ODIN% check "..\test_issue_foreign_import_attributes" -no-entry-point %COMMON% || exit /b
%ODIN% check "..\test_issue_foreign_redeclaration_mismatch" -no-entry-point %COMMON% 2>&1 | find /c "Error:" | findstr /x "1" || exit /b
%ODIN% check "..\test_issue_integer_literal_exponent" -no-entry-point %COMMON% 2>&1 | find /c "Error:" | findstr /x "1" || exit /b

@rem #########################################################################################################

@rem "odin build" tests:
%ODIN% build "..\test_issue_2113" %COMMON% -debug || exit /b
%ODIN% build "..\test_issue_2395" %COMMON% 2>&1 | find /c "Error:" | findstr /x "2" || exit /b
%ODIN% build "..\test_issue_5043" %COMMON% || exit /b
%ODIN% build "..\test_issue_5097" %COMMON% || exit /b
%ODIN% build "..\test_issue_5097-2" %COMMON% || exit /b
%ODIN% build "..\test_issue_5265" %COMMON% || exit /b
%ODIN% build "..\test_issue_5573" %COMMON% 2>&1 | find /c "Error:" | findstr /x "2" || exit /b
%ODIN% build "..\test_issue_6240" %COMMON% 2>&1 | find /c "Error:" | findstr /x "3" || exit /b
%ODIN% build "..\test_issue_6401" %COMMON% 2>&1 | find /c "Error:" | findstr /x "3" || exit /b
%ODIN% build "..\test_issue_6594" %COMMON% 2>&1 | find /c "Error:" || exit /b
%ODIN% build "..\test_issue_6621" %COMMON% 2>&1 | find /c "Error:" || exit /b
%ODIN% build "..\test_issue_7037" %COMMON% -o:none  || exit /b
%ODIN% build "..\test_issue_7073-1" %COMMON% 2>&1 | find /c "Error:" | findstr /x "2" || exit /b
%ODIN% build "..\test_issue_7108" %COMMON% 2>&1 | find /c "Error" | findstr /x "2" || exit /b
%ODIN% build "..\test_issue_7167" %COMMON% || exit /b
%ODIN% build "..\test_issue_7188" %COMMON% || exit /b
%ODIN% build "..\test_issue_7304" %COMMON% 2>&1 | find /c "9223372036854775808 is not representable by int" || exit /b
%ODIN% build "..\test_issue_7598_all_entities_checked" %COMMON% 2>&1 | find /c "Error:" | findstr /x "4" || exit /b

@rem #########################################################################################################

@rem "odin run" tests:
%ODIN% run "..\test_issue_7482" %COMMON% || exit /b
%ODIN% run "..\test_issue_7562" %COMMON% -no-crt -no-thread-local || exit /b
%ODIN% run "..\test_issue_7562" %COMMON% -no-crt -no-thread-local -o:speed || exit /b
%ODIN% run "..\test_issue_7564" %COMMON% || exit /b
%ODIN% run "..\test_issue_7596" %COMMON% || exit /b
%ODIN% run "..\test_issue_7798" %COMMON% || exit /b

@rem #########################################################################################################

@rem "odin test" tests with special needs, or others (e.g. "odin doc"):
if "%ISSUES_TESTS_NO_CLANG%" == "" (
	clang -c "..\test_issue_5640\test_issue_5640.c" -o test_issue_5640_c.o || exit /b
) else (
	cl -c "..\test_issue_5640\test_issue_5640.c" /Fo:test_issue_5640_c.o || exit /b
)

%ODIN% test "..\test_issue_5640" %COMMON% || exit /b

if "%ISSUES_TESTS_NO_CLANG%" == "" (
	clang -c "..\test_issue_6809_6816\test_issue_6809_6816.c" -o test_issue_6809_6816_c.o -O3 || exit /b
) else (
	cl -c "..\test_issue_6809_6816\test_issue_6809_6816.c" /Fo:test_issue_6809_6816_c.o -O3 || exit /b
)

%ODIN% test "..\test_issue_6809_6816" %COMMON% || exit /b

%ODIN% test "..\test_issue_6344" %COMMON% -o:speed || exit /b

%ODIN% test "..\test_pr_6470" %COMMON% -define:TEST_EXPECT_FAILURE=true 2>&1 | find /c "Error:" | findstr /x "1" || exit /b

if "%ISSUES_TESTS_NO_CLANG%" == "" (
	clang -c "..\test_issue_7010\test_issue_7010.c" -o test_issue_7010_c.o || exit /b
	%ODIN% test "..\test_issue_7010" %COMMON% || exit /b
) else (
	@echo "!!! WARNING !!! test_issue_7010 is not compatible with MSVC."
)

%ODIN% test "..\test_issue_split_globals" -define:ODIN_TEST_FANCY=false -vet -strict-style -ignore-unused-defineables || exit /b
%ODIN% test "..\test_issue_split_globals" -define:ODIN_TEST_FANCY=false -vet -strict-style -ignore-unused-defineables -debug || exit /b

%ODIN% test "..\test_issue_fast_isel_lowering" %COMMON% -o:none || exit /b

%ODIN% test "..\test_issue_equal_proc_dependencies" %COMMON% -build-mode:obj 2>&1 | find /i /c "missing procedure" | findstr /x "0" || exit /b

@rem `asm` templates are amd64-only, assuming this is going to work on Windows (ARM?)
%ODIN% doc "..\test_issue_asm_doc_category" 2>&1 | find /c "asm templates" | findstr /x "1" || exit /b

%ODIN% test "..\test_lifetime_markers" %COMMON% -o:size -lifetime-markers || exit /b
%ODIN% test "..\test_lifetime_markers" %COMMON% -o:speed -lifetime-markers || exit /b

if "%ISSUES_TESTS_NO_CLANG%" == "" (
	clang -c "..\test_issue_sysv_abi\test_issue_sysv_abi.c" -o test_issue_sysv_abi_c.o || exit /b
) else (
	cl -c "..\test_issue_sysv_abi\test_issue_sysv_abi.c" /Fo:test_issue_sysv_abi_c.o || exit /b
)

%ODIN% test "..\test_issue_sysv_abi" %COMMON% || exit /b

@rem #########################################################################################################

@echo off

popd
rmdir /S /Q build
