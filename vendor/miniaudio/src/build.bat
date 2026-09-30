@echo off
setlocal

pushd "%~dp0" || exit /b 1

if not exist "..\lib" mkdir "..\lib"

cl -nologo -MT -TC -O2 -c miniaudio.c
if errorlevel 1 (
    popd
    exit /b 1
)

lib -nologo miniaudio.obj -out:..\lib\miniaudio.lib
if errorlevel 1 (
    popd
    exit /b 1
)

del "*.obj"
popd
