@echo off

REM The ABI comparator. Every check is "Odin agrees with the platform C compiler"

if not exist "build\" mkdir build
pushd build

set COMMON=-define:ODIN_TEST_FANCY=false -file -vet -strict-style -ignore-unused-defineables

@echo on

python3 ..\gen.py . || exit /b

REM -w because the corpus deliberately uses zero-length arrays and empty
REM structs; both are the extensions under test.
clang -c abi_corpus.c -o abi_corpus_c.o -w || exit /b
..\..\..\odin test abi_corpus.odin %COMMON% || exit /b

@echo off

popd
rmdir /S /Q build
