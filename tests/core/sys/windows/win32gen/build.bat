@echo off

setlocal EnableDelayedExpansion

where /Q cl.exe || (
	set __VSCMD_ARG_NO_LOGO=1
	for /f "tokens=*" %%i in ('"C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath') do set VS=%%i
	if "!VS!" equ "" (
		echo ERROR: MSVC installation not found
		exit /b 1
	)
	call "!VS!\Common7\Tools\vsdevcmd.bat" -arch=x64 -host_arch=x64 || exit /b 1
)

if "%VSCMD_ARG_TGT_ARCH%" neq "x64" (
	if "%ODIN_IGNORE_MSVC_CHECK%" == "" (
		echo ERROR: please run this from MSVC x64 native tools command prompt, 32-bit target is not supported!
		exit /b 1
	)
)

set genconfig=Release
pushd %~dp0

set genname=win32gen
set cl_output_path=%genname%\x64\%genconfig%
set gen_output_path=x64\%genconfig%
set genexe=%gen_output_path%\%genname%.exe

if exist "%genexe%" (del /f "%genexe%" > NUL 2> NUL)

:compiling
echo Compiling...
mkdir %cl_output_path% > NUL 2> NUL
set compiler_flags=^
/c /Zi /nologo /W3 /WX- ^
/diagnostics:column /sdl /O2 /Oi /GL ^
/D NDEBUG /D _CONSOLE /D _UNICODE /D UNICODE ^
/Gm- /EHsc /MD /GS /Gy /fp:precise ^
/Zc:wchar_t /Zc:forScope /Zc:inline ^
/std:c++20 /permissive- /Fo"%cl_output_path%\\" ^
/external:W3 /Gd /TP /FC /errorReport:queue

@echo on
cl %compiler_flags% win32gen.cpp
@echo off
if %ERRORLEVEL% NEQ 0 (goto error)

:linking
echo Linking...
mkdir "%gen_output_path%" > NUL 2> NUL
set libs=^
kernel32.lib ^
user32.lib ^
gdi32.lib ^
comdlg32.lib ^
advapi32.lib ^
shell32.lib ^
ole32.lib ^
uuid.lib
set linker_flags=^
/ERRORREPORT:QUEUE ^
/OUT:%genexe% ^
/NOLOGO ^
%libs% ^
/MANIFEST /MANIFESTUAC:"level='asInvoker' uiAccess='false'" /manifest:embed ^
/SUBSYSTEM:CONSOLE ^
/OPT:REF /OPT:ICF /LTCG:incremental ^
/LTCGOUT:"%cl_output_path%\%genname%.iobj" ^
/TLBID:1 /DYNAMICBASE /NXCOMPAT ^
/IMPLIB:"%gen_output_path%\%genname%.lib" ^
/MACHINE:X64

@echo on
link %linker_flags% %cl_output_path%\%genname%.obj
@echo off
if %ERRORLEVEL% NEQ 0 (goto error)

:generate
echo Generating...
%genexe% ..\test_windows_generated.odin
goto done

:error
echo Last command returned %ERRORLEVEL%

:done
popd
echo Done.
