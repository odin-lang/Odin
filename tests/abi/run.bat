@echo off

REM The ABI comparator. Every check is "Odin agrees with the platform C compiler"

REM An ABI is a link-time contract, so the two sides are built independently and
REM either may be optimised: `set ABI_CFLAGS=-O2` for the C side, and any
REM argument here goes to `odin test`, e.g. `run.bat -o:speed`.

REM The corpus is run once per calling convention. "vectorcall" is checked
REM against MSVC, which defines it, and which clang disagrees with in places.
set ODIN_ARGS=%*
call :corpus c clang || exit /b
call :corpus vectorcall cl || exit /b
exit /b 0

:corpus
REM cleaned BEFORE, not after: the generated corpus is left to inspect
if exist "build\" rmdir /S /Q build
mkdir build
pushd build

set COMMON=-define:ODIN_TEST_FANCY=false -file -vet -strict-style -ignore-unused-defineables

@echo on

..\..\..\odin run ..\gen.odin -file -- . %1 || exit /b

@echo off
REM -w because the corpus deliberately uses zero-length arrays and empty
REM structs; both are the extensions under test. -Zl and -GS- keep the MSVC
REM object from choosing a C runtime for the Odin side.
if "%2"=="cl" (
	where cl >nul 2>nul || (echo cl not found: run this from a Visual Studio prompt & exit /b 1)
	set PREPROCESS=cl -nologo -EP tiers.c
	set COMPILE=cl -nologo -c -std:c11 -Zl -GS- -w %ABI_CFLAGS% abi_corpus.c -Foabi_corpus_c.o
) else (
	clang --version || exit /b
	set PREPROCESS=clang -E tiers.c
	set COMPILE=clang %ABI_CFLAGS% -c abi_corpus.c -o abi_corpus_c.o -w
)

REM Ask the C compiler which tiers it has, by preprocessing the generated
REM `tiers.c`. Clang targeting MSVC doesnt define `__GNUC__` or `_Float16`,
REM and MSVC has no `_Complex`, Odin side needs to match
set TIER_GNU=false
set TIER_F16=false
set TIER_I128=false
set TIER_COMPLEX=false
%PREPROCESS% 2>nul | findstr /C:"ABI_YES_GNU" >nul && set TIER_GNU=true
%PREPROCESS% 2>nul | findstr /C:"ABI_YES_F16" >nul && set TIER_F16=true
%PREPROCESS% 2>nul | findstr /C:"ABI_YES_I128" >nul && set TIER_I128=true
%PREPROCESS% 2>nul | findstr /C:"ABI_YES_COMPLEX" >nul && set TIER_COMPLEX=true
set TIERS=-define:ABI_TIER_GNU=%TIER_GNU% -define:ABI_TIER_F16=%TIER_F16% -define:ABI_TIER_I128=%TIER_I128% -define:ABI_TIER_COMPLEX=%TIER_COMPLEX%
echo tiers: %TIERS%

@echo on

%COMPILE% || exit /b
..\..\..\odin test abi_corpus.odin %COMMON% %TIERS% %ODIN_ARGS% || exit /b

@echo off

popd
exit /b 0
