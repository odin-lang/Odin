@echo off

set exe_name=odin.exe

set compiler_flags= -nologo -Oi -TP -fp:precise -Gm- -MP -FC -GS- -EHsc- -GR- -O2 -MT -Z7 -DNO_ARRAY_BOUNDS_CHECK
set compiler_warnings= ^
    -W4 -WX ^
    -wd4100 -wd4101 -wd4127 -wd4189 ^
    -wd4201 -wd4204 ^
    -wd4456 -wd4457 -wd4480 ^
    -wd4512

set compiler_includes=
set libs= ^
    kernel32.lib

set linker_flags= -incremental:no -opt:ref -subsystem:console -debug

set compiler_settings=%compiler_includes% %compiler_flags% %compiler_warnings%
set linker_settings=%libs% %linker_flags%

cl %compiler_settings% "src\main.cpp" ^
    /link %linker_settings% -OUT:%exe_name% ^

