@echo off
setlocal

pushd "%~dp0" || exit /b 1

if not exist "..\lib" mkdir "..\lib"

cl -nologo -MT -TC -O2 -c cgltf.c
if errorlevel 1 (
    popd
    exit /b 1
)

lib -nologo cgltf.obj -out:..\lib\cgltf.lib
if errorlevel 1 (
    popd
    exit /b 1
)

del "*.obj"
popd
