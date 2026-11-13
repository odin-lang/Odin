@echo off
setlocal

pushd "%~dp0" || exit /b 1

rem The libraries are built for the architecture that the MSVC environment targets. The x64 ones go in lib,
rem the arm64 ones (Windows on ARM) in lib\windows_arm64.
set "out_dir=..\lib"
if /I "%VSCMD_ARG_TGT_ARCH%" == "arm64" set "out_dir=..\lib\windows_arm64"
if not exist "%out_dir%" mkdir "%out_dir%"

cl -nologo -MT -TC -O2 -c -std:c17 -I"include" src\*.c
if errorlevel 1 (
    popd
    exit /b 1
)

lib -nologo *.obj -out:%out_dir%\box3d.lib
if errorlevel 1 (
    popd
    exit /b 1
)

cl -nologo -MT -TC -O2 -LD -std:c17 -Dbox3d_EXPORTS -I"include" src\*.c -link -out:%out_dir%\box3d.dll -implib:%out_dir%\box3ddll.lib
if errorlevel 1 (
    popd
    exit /b 1
)

del "*.obj" "%out_dir%\box3ddll.exp"
popd
