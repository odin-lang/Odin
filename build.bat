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
	if "%ODIN_IGNORE_MSVC_CHECK%" == "" (
		echo ERROR: please run this from MSVC x64 native tools command prompt, 32-bit target is not supported!
		exit /b 1
	)
)

pushd misc
cl /nologo get-date.c
popd

for /f %%i in ('misc\get-date') do (
	set CURR_DATE_TIME=%%i
)
set curr_year=%CURR_DATE_TIME:~0,4%
set curr_month=%CURR_DATE_TIME:~4,2%
set curr_day=%CURR_DATE_TIME:~6,2%

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

if %release_mode% equ 0 (
	set V1=%curr_year%
	set V2=%curr_month%
	set V3=%curr_day%
) else (
	set V1=%curr_year%
	set V2=%curr_month%
	set V3=0
)
set V4=0
set odin_version_full="%V1%.%V2%.%V3%.%V4%"
set odin_version_raw="dev-%V1%-%V2%"

set compiler_flags= -nologo -Oi -TP -fp:precise -Gm- -MP -FC -EHsc- -GR- -GF
rem Parse source code as utf-8 even on shift-jis and other codepages
rem See https://learn.microsoft.com/en-us/cpp/build/reference/utf-8-set-source-and-executable-character-sets-to-utf-8?view=msvc-170
set compiler_flags= %compiler_flags% /utf-8
set compiler_defines= -DODIN_VERSION_RAW=\"%odin_version_raw%\"

rem fileversion is defined as {Major,Minor,Build,Private: u16} so a bit limited
set rc_flags=-nologo ^
-DV1=%V1% -DV2=%V2% -DV3=%V3% -DV4=%V4% ^
-DVF=%odin_version_full% -DNIGHTLY=%nightly%

where /Q git.exe || goto skip_git_hash
if not exist .git\ goto skip_git_hash
for /f "tokens=1,2" %%i IN ('git show "--pretty=%%cd %%h" "--date=format:%%Y-%%m" --no-patch --no-notes HEAD') do (
	set odin_version_raw=dev-%%i
	set GIT_SHA=%%j
)
if %ERRORLEVEL% equ 0 (
	set compiler_defines=%compiler_defines% -DGIT_SHA=\"%GIT_SHA%\"
	set rc_flags=%rc_flags% -DGIT_SHA=%GIT_SHA% -DVP=%odin_version_raw%:%GIT_SHA%
) else (
	set rc_flags=%rc_flags% -DVP=%odin_version_raw%
)
:skip_git_hash

if %nightly% equ 1 set compiler_defines=%compiler_defines% -DNIGHTLY

if %release_mode% EQU 0 ( rem Debug
	set compiler_flags=%compiler_flags% -Od -MDd -Z7
	set rc_flags=%rc_flags% -D_DEBUG
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
set odin_res=misc\odin.res
set odin_rc=misc\odin.rc

rem DO NOT TOUCH!
rem THIS TILDE STUFF IS FOR DEVELOPMENT ONLY!
set tilde_backend=0
if %tilde_backend% EQU 1 (
	set libs=%libs% src\tilde\tb.lib
	set compiler_defines=%compiler_defines% -DODIN_TILDE_BACKEND
)
rem DO NOT TOUCH!


set linker_flags= -incremental:no -opt:ref -subsystem:console -MANIFEST:EMBED

if %release_mode% EQU 0 ( rem Debug
	set linker_flags=%linker_flags% -debug /NATVIS:src\odin_compiler.natvis
) else ( rem Release
	set linker_flags=%linker_flags% -debug
)

set compiler_settings=%compiler_includes% %compiler_flags% %compiler_warnings% %compiler_defines%
set linker_settings=%libs% %odin_res% %linker_flags%

del *.pdb > NUL 2> NUL
del *.ilk > NUL 2> NUL

rc %rc_flags% %odin_rc%
cl %compiler_settings% "src\main.cpp" "src\libtommath.cpp" /link %linker_settings% -OUT:%exe_name%
mt -nologo -inputresource:%exe_name%;#1 -manifest misc\odin.manifest -outputresource:%exe_name%;#1 -validate_manifest -identity:"odin, processorArchitecture=amd64, version=%odin_version_full%, type=win32"
if %errorlevel% neq 0 goto end_of_build

call build_vendor.bat
if %errorlevel% neq 0 goto end_of_build

rem If the demo doesn't run for you and your CPU is more than a decade old, try -microarch:native
if %release_mode% EQU 0 odin run examples/demo -vet -strict-style -resource:examples/demo/demo.rc -- Hellope World

rem Many non-compiler devs seem to run debug build but don't realize.
if %release_mode% EQU 0 echo: & echo Debug compiler built. Note: run "build.bat release" if you want a faster, release mode compiler.

del *.obj > NUL 2> NUL

:end_of_build