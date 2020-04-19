@echo off

:: Make sure this is a decent name and not generic
set exe_name=odin.exe

set compiler_flags= -nologo -Oi -TP -fp:precise -Gm- -MP -FC -EHsc- -GR- -GF -O2 -MT -Z7
set compiler_defines= -DLLVM_BACKEND_SUPPORT -DNO_ARRAY_BOUNDS_CHECK

set compiler_warnings= ^
    -W4 -WX ^
    -wd4100 -wd4101 -wd4127 -wd4189 ^
    -wd4201 -wd4204 ^
    -wd4456 -wd4457 -wd4480 ^
    -wd4512

set compiler_includes=
set libs= ^
    kernel32.lib ^
    bin\llvm\windows\LLVM-C.lib

set linker_flags= -incremental:no -opt:ref -subsystem:console -debug

set compiler_settings=%compiler_includes% %compiler_flags% %compiler_warnings% %compiler_defines%
set linker_settings=%libs% %linker_flags%

del *.pdb > NUL 2> NUL
del *.ilk > NUL 2> NUL

cl %compiler_settings% "src\main.cpp" /link %linker_settings% -OUT:%exe_name%
    
:end_of_build
