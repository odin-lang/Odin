@echo off


rem call clang -c -emit-llvm -DGB_IMPLEMENTATION -DGB_DEF=GB_DLL_EXPORT ..\src\gb\gb.h

pushd ..\examples
call ..\bin\odin.exe ..\examples/main.odin ^
	&& opt -mem2reg main.ll -o main.bc ^
	&& clang main.bc -o main.exe ^
		-Wno-override-module -lkernel32.lib -luser32.lib ^
	&& main.exe
popd

	rem && llvm-dis ..\examples/main.bc -o - ^
rem call ..\misc\llvm-bin\opt.exe -mem2reg ..\examples/output.ll > ..\examples/main.bc
rem call llc ..\examples/main.bc
rem call llvm-dis ..\examples/main.bc -o ..\examples/output.ll
rem call clang ..\examples/main.c -O0 -S -emit-llvm -o ..\examples/main-c.ll
