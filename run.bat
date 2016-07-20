@echo off


rem del "..\examples\test.bc"
call ..\bin\odin.exe ..\examples/test.odin
rem clang -S -emit-llvm ..\examples/test.c -o ..\examples/test.ll
call llvm-as < ..\examples/test.ll
rem call lli ..\examples/test.ll

rem call lli ..\examples/test.bc rem JIT
rem llc ..\examples/test.bc -march=x86-64 -o ..\examples/test.exe

