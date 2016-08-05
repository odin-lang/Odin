@echo off


call ..\bin\odin.exe ..\examples/main.odin ^
	&& ..\misc\llvm-bin\lli.exe ..\examples/main.ll

rem call ..\misc\llvm-bin\opt.exe -mem2reg ..\examples/output.ll > ..\examples/main.bc
rem call llc ..\examples/main.bc
rem call llvm-dis ..\examples/main.bc -o ..\examples/output.ll
rem call clang ..\examples/main.c -O0 -S -emit-llvm -o ..\examples/main-c.ll
