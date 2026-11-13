@echo off
setlocal

pushd "%~dp0" || exit /b 1

rem The library is built for the architecture that the MSVC environment targets. The x64 one goes in lib,
rem the arm64 one (Windows on ARM) in lib\windows_arm64.
set "out_dir=..\lib"
if /I "%VSCMD_ARG_TGT_ARCH%" == "arm64" set "out_dir=..\lib\windows_arm64"
if not exist "%out_dir%" mkdir "%out_dir%"

cl -nologo -MT -TC -O2 -c miniaudio.c
if errorlevel 1 (
    popd
    exit /b 1
)

lib -nologo miniaudio.obj -out:%out_dir%\miniaudio.lib
if errorlevel 1 (
    popd
    exit /b 1
)

del "*.obj"
popd
