@echo off

setlocal EnableDelayedExpansion

for /f "usebackq tokens=1,2 delims=,=- " %%i in (`wmic os get LocalDateTime /value`) do @if %%i==LocalDateTime (
	set CURR_DATE_TIME=%%j
)

set curr_year=%CURR_DATE_TIME:~0,4%
set curr_month=%CURR_DATE_TIME:~4,2%

:: Make sure this is a decent name and not generic
set exe_name=odin.exe

:: Debug = 0, Release = 1
if "%1" == "1" (
	set release_mode=1
) else if "%1" == "release" (
	set release_mode=1
) else (
	set release_mode=0
)

:: Normal = 0, CI Nightly = 1
if "%2" == "1" (
	set nightly=1
) else (
	set nightly=0
)

set odin_version_raw="dev-%curr_year%-%curr_month%"

set compiler_flags= -nologo -Oi -TP -fp:precise -Gm- -MP -FC -EHsc- -GR- -GF
set compiler_defines= -DODIN_VERSION_RAW=\"%odin_version_raw%\"

for /f %%i in ('git rev-parse --short HEAD') do set GIT_SHA=%%i
if %ERRORLEVEL% equ 0 set compiler_defines=%compiler_defines% -DGIT_SHA=\"%GIT_SHA%\"
if %nightly% equ 1 set compiler_defines=%compiler_defines% -DNIGHTLY

if %release_mode% EQU 0 ( rem Debug
	set compiler_flags=%compiler_flags% -Od -MDd -Z7
) else ( rem Release
	set compiler_flags=%compiler_flags% -O2 -MT -Z7
	set compiler_defines=%compiler_defines% -DNO_ARRAY_BOUNDS_CHECK
)

set compiler_warnings= ^
	-W4 -WX ^
	-wd4100 -wd4101 -wd4127 -wd4146 ^
	-wd4456 -wd4457

set compiler_includes= ^
	/Isrc\
set libs= ^
	kernel32.lib ^
	bin\llvm\windows\LLVM-C.lib

set linker_flags= -incremental:no -opt:ref -subsystem:console

if %release_mode% EQU 0 ( rem Debug
	set linker_flags=%linker_flags% -debug
) else ( rem Release
	set linker_flags=%linker_flags% -debug
)

set compiler_settings=%compiler_includes% %compiler_flags% %compiler_warnings% %compiler_defines%
set linker_settings=%libs% %linker_flags%

del *.pdb > NUL 2> NUL
del *.ilk > NUL 2> NUL

rem cl %compiler_settings% "src\main.cpp" "src\libtommath.cpp" /link %linker_settings% -OUT:%exe_name%
rem if %errorlevel% neq 0 goto end_of_build

odin run examples/bug
rem odin build examples/demo -use-separate-modules
rem odin run examples/demo -o:minimal
rem odin run examples/demo -o:size
rem odin run examples/demo -o:speed -keep-temp-files
rem odin run examples/demo -o:speed -keep-temp-files

rem set small_hellope_flags=-strict-style -no-bounds-check -default-to-nil-allocator -disable-assert -no-crt -o:size 
rem set small_hellope_flags=-strict-style -no-bounds-check -default-to-nil-allocator -disable-assert -o:size 

rem odin build examples/small_hellope %small_hellope_flags% -build-mode:asm
rem odin run examples/small_hellope %small_hellope_flags% -keep-temp-files
rem FOR /F "usebackq" %%A IN ('small_hellope.exe') DO echo %%~zA

rem cl /nologo examples\small_hellope\small_hellope.c /O1 /link Kernel32.lib -out:small_hellope_c.exe /NODEFAULTLIB /entry:mainCRTStartup /subsystem:console
rem small_hellope_c.exe
rem FOR /F "usebackq" %%A IN ('small_hellope_c.exe') DO echo %%~zA


rem odin run examples/demo
rem odin run examples/sdl2 -vet
rem odin check examples/all -vet
rem odin run examples/bug

rem odin check examples/wasm -strict-style -target:wasi_wasm32 
rem odin check examples/demo -strict-style
rem odin build examples/wasm -strict-style -target:wasi_wasm32 -keep-temp-files
rem "C:\Program Files\WAVM\bin\wavm.exe" disassemble wasm.wasm > wasm.wast
rem "C:\Program Files\WAVM\bin\wavm.exe" run --abi=wasi --function=weird_add wasm.wasm 2 3

rem wasmer inspect wasm.wasm
rem wasmer run wasm.wasm

rem odin run examples/demo -strict-style

rem call build_vendor.bat
rem if %errorlevel% neq 0 goto end_of_build

rem if %release_mode% EQU 0 odin check examples/bug -strict-style

rem odin run examples/demo -strict-style

del *.obj > NUL 2> NUL

:end_of_build
