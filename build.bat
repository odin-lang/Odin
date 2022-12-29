@echo off

setlocal EnableDelayedExpansion

where /Q cl.exe || (
  set __VSCMD_ARG_NO_LOGO=1
  for /f "tokens=*" %%i in ('"C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe" -latest -requires Microsoft.VisualStudio.Workload.NativeDesktop -property installationPath') do set VS=%%i
  if "!VS!" equ "" (
    echo ERROR: Visual Studio installation not found
    exit /b 1
  )  
  call "!VS!\VC\Auxiliary\Build\vcvarsall.bat" amd64 || exit /b 1
)

if "%VSCMD_ARG_TGT_ARCH%" neq "x64" (
  echo ERROR: please run this from MSVC x64 native tools command prompt, 32-bit target is not supported!
  exit /b 1
)

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
	-wd4505 ^
	-wd4456 -wd4457

set compiler_includes= ^
	/Isrc\
set libs= ^
	kernel32.lib ^
	Synchronization.lib ^
	bin\llvm\windows\LLVM-C.lib

set linker_flags= -incremental:no -opt:ref -subsystem:console

if %release_mode% EQU 0 ( rem Debug
	set linker_flags=%linker_flags% -debug /NATVIS:src\odin_compiler.natvis
) else ( rem Release
	set linker_flags=%linker_flags% -debug
)

set compiler_settings=%compiler_includes% %compiler_flags% %compiler_warnings% %compiler_defines%
set linker_settings=%libs% %linker_flags%

del *.pdb > NUL 2> NUL
del *.ilk > NUL 2> NUL

cl %compiler_settings% "src\main.cpp" "src\libtommath.cpp" /link %linker_settings% -OUT:%exe_name%
if %errorlevel% neq 0 goto end_of_build

call build_vendor.bat
if %errorlevel% neq 0 goto end_of_build

if %release_mode% EQU 0 odin run examples/demo

del *.obj > NUL 2> NUL

:end_of_build
