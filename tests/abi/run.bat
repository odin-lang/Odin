@echo off

REM The ABI comparator. Every check is "Odin agrees with the platform C compiler"

if not exist "build\" mkdir build
pushd build

set COMMON=-define:ODIN_TEST_FANCY=false -file -vet -strict-style -ignore-unused-defineables

@echo on

python3 ..\gen.py . || exit /b

@echo off
REM Ask the C compiler which tiers it has, by preprocessing the generated
REM `tiers.c`. Clang targeting MSVC doesnt define `__GNUC__` or `_Float16`,
REM Odin side needs to match
set TIER_GNU=false
set TIER_F16=false
set TIER_I128=false
clang -E tiers.c 2>nul | findstr /C:"ABI_YES_GNU" >nul && set TIER_GNU=true
clang -E tiers.c 2>nul | findstr /C:"ABI_YES_F16" >nul && set TIER_F16=true
clang -E tiers.c 2>nul | findstr /C:"ABI_YES_I128" >nul && set TIER_I128=true
set TIERS=-define:ABI_TIER_GNU=%TIER_GNU% -define:ABI_TIER_F16=%TIER_F16% -define:ABI_TIER_I128=%TIER_I128%
echo tiers: %TIERS%

@echo on

REM -w because the corpus deliberately uses zero-length arrays and empty
REM structs; both are the extensions under test.
clang -c abi_corpus.c -o abi_corpus_c.o -w || exit /b
..\..\..\odin test abi_corpus.odin %COMMON% %TIERS% || exit /b

@echo off

popd
rmdir /S /Q build
