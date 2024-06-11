@echo off
if "%VSCMD_ARG_TGT_ARCH%"=="" call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" x64
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
