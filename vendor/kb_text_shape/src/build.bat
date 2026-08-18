@echo off
setlocal

pushd "%~dp0" || exit /b 1

if not exist "..\lib" mkdir "..\lib"

cl -nologo -MT -TC -O2 -c kb_text_shape.c
if errorlevel 1 (
    popd
    exit /b 1
)

lib -nologo kb_text_shape.obj -out:..\lib\kb_text_shape.lib
if errorlevel 1 (
    popd
    exit /b 1
)

del "*.obj"
popd
