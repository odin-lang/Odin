@echo off


rem del "..\examples\test.bc"
call ..\bin\odin.exe ..\examples/test.odin
call lli ..\examples/test.ll
rem call clang ..\examples/test.c -S -emit-llvm -o -
