@echo off


rem del "..\examples\test.bc"
call ..\bin\odin.exe ..\examples/test.odin
call lli ..\examples/test.ll
rem call opt -mem2reg ..\examples/test.ll > ..\examples/test.bc
rem call llvm-dis ..\examples/test.bc -o..\examples/test.ll
rem call clang ..\examples/test.c -O1 -S -emit-llvm -o ..\examples/test-c.ll
