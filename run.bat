@echo off


rem call clang -c -emit-llvm -DGB_IMPLEMENTATION -DGB_DEF=GB_DLL_EXPORT ..\src\gb\gb.h

call ..\bin\odin.exe ..\examples/main.odin ^
	&& ..\misc\llvm-bin\opt.exe -mem2reg ..\examples/main.ll -o ..\examples/main.bc ^
	&& ..\misc\llvm-bin\lli.exe ..\examples/main.bc

	rem && llvm-dis ..\examples/main.bc -o - ^
rem call ..\misc\llvm-bin\opt.exe -mem2reg ..\examples/output.ll > ..\examples/main.bc
rem call llc ..\examples/main.bc
rem call llvm-dis ..\examples/main.bc -o ..\examples/output.ll
rem call clang ..\examples/main.c -O0 -S -emit-llvm -o ..\examples/main-c.ll
