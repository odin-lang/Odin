@echo off


rem del "..\examples\test.bc"
call ..\bin\odin.exe ..\examples/test.odin && ..\misc\llvm-bin\lli.exe ..\examples/test.ll
call ..\misc\llvm-bin\opt.exe -mem2reg ..\examples/test.ll > ..\examples/test.bc
call llc ..\examples/test.bc
rem call llvm-dis ..\examples/test.bc -o ..\examples/test.ll
rem call clang ..\examples/test.c -O0 -S -emit-llvm -o ..\examples/test-c.ll
