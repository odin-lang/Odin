@rem This file runs most of the tests that the CI would run.
@rem It omits time-intensive optimized core library tests and Wycheproof tests.

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

@rem Run ABI tests
@pushd .
cd tests\abi
set ABI_CFLAGS=
call run.bat || exit /b
set ABI_CFLAGS=-O2
call run.bat -o:speed || exit /b
@popd
