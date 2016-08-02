@echo off


rem del "..\examples\test.bc"
call ..\bin\odin.exe ..\examples/test.odin && lli ..\examples/test.ll
call opt -mem2reg ..\examples/test.ll > ..\examples/test.bc
call llvm-dis ..\examples/test.bc -o ..\examples/test.ll
call clang ..\examples/test.c -O0 -S -emit-llvm -o ..\examples/test-c.ll
