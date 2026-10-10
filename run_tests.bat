@rem This file runs most of the tests that the CI would run.
@rem When the "slim" argument is provided, it omits time-intensive optimized core library tests and Wycheproof tests.

setlocal EnableDelayedExpansion

@echo off

set SLIM=

for %%A in (%*) do (
	if "%%A"=="slim" (
		set SLIM=1
	) else if "%%A"=="no-clang" (
		set ODIN_TESTS_NO_CLANG=1
	) else (
		echo Unrecognized argument: %%A
		exit /b
	)
)

rem Check if clang is present
if not defined ODIN_TESTS_NO_CLANG (
	clang --version
	if !ERRORLEVEL! neq 0 (
		echo ERROR: clang is not present. Some tests require this.
		echo Note: You can try using msvc instead by specifying the "no-clang" argument, or setting ODIN_TESTS_NO_CLANG=1
		echo       However, some ABI tests will be skipped.
		exit /b
	)
)

@echo on

@rem Check examples/all
@pushd .
.\odin check examples\all -vet -vet-tabs -strict-style -vet-style -warnings-as-errors -disallow-do || exit /b
@popd

@rem Check examples/all/sdl3
@pushd .
.\odin check examples\all\sdl3 -vet -vet-tabs -strict-style -vet-style -warnings-as-errors -disallow-do -no-entry-point || exit /b
@popd

@rem Internals tests
@pushd tests\internal
..\..\odin test . -all-packages -vet -vet-tabs -strict-style -vet-style -warnings-as-errors -disallow-do -define:ODIN_TEST_FANCY=false -define:ODIN_TEST_FAIL_ON_BAD_MEMORY=true -sanitize:address || exit /b
@popd

@rem Normal Core library tests
@pushd tests\core
..\..\odin test normal.odin -file -all-packages -vet -vet-tabs -strict-style -vet-style -warnings-as-errors -disallow-do -define:ODIN_TEST_FANCY=false -define:ODIN_TEST_FAIL_ON_BAD_MEMORY=true -sanitize:address || exit /b
@popd

@rem Vendor library tests
@pushd .
cd tests\vendor
mkdir build
pushd build
copy ..\..\..\vendor\lua\5.4\windows\*.dll .
..\..\..\odin test ..\ -all-packages -vet -vet-tabs -strict-style -vet-style -warnings-as-errors -disallow-do -define:ODIN_TEST_FANCY=false -define:ODIN_TEST_FAIL_ON_BAD_MEMORY=true -sanitize:address || exit /b
popd
rmdir /S /Q build
@popd

@rem Check issues
@pushd .
cd tests\issues
call run.bat || exit /b
@popd

@rem The ABI tests can be disabled here because they require clang at the moment.
@rem   TODO: Maybe try to make them work with msvc as well?
if not defined ODIN_TESTS_NO_CLANG (

	@rem Run ABI tests
	@pushd .
	cd tests\abi
	set ABI_CFLAGS=
	call run.bat || exit /b
	set ABI_CFLAGS=-O2
	call run.bat -o:speed || exit /b
	@popd

)

@rem More extensive tests (non-slim):

if not defined SLIM (

	@echo Running extended tests...

	@rem Optimized Core library tests
	@pushd tests\core
	..\..\odin test speed.odin -o:speed -file -all-packages -vet -vet-tabs -strict-style -vet-style -warnings-as-errors -disallow-do -define:ODIN_TEST_FANCY=false -define:ODIN_TEST_FAIL_ON_BAD_MEMORY=true || exit /b
	@popd

	@rem Wycheproof tests
	@pushd tests\core
	..\..\odin test crypto/wycheproof -vet -vet-tabs -strict-style -vet-style -vet-cast -warnings-as-errors -disallow-do -define:ODIN_TEST_FANCY=false -o:speed || exit /b
	@popd

	@rem Noise Protocol Framework tests
	@pushd tests\core
	..\..\odin test crypto/noise -vet -vet-tabs -strict-style -vet-style -vet-cast -warnings-as-errors -disallow-do -define:ODIN_TEST_FANCY=false -o:speed || exit /b
	@popd

	@rem X.509 limbo tests
	@pushd tests\core
	..\..\odin test crypto/x509_limbo -vet -vet-tabs -strict-style -vet-style -vet-cast -warnings-as-errors -disallow-do -define:ODIN_TEST_FANCY=false -o:speed || exit /b
	@popd

	@echo SUCCESS:  Extended tests have been executed successfully.
	@echo           Note: You can call  "run_tests slim"  to omit some of the slower tests.

) else (

	@echo SUCCESS:  Slim tests have been executed successfully.

)

if defined ODIN_TESTS_NO_CLANG (
	@echo WARNING:  ODIN_TESTS_NO_CLANG specified - ABI tests have been skipped.
)
