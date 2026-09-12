@echo off
setlocal

pushd "%~dp0" || exit /b 1

if not exist "..\lib" mkdir "..\lib"

cl -nologo -MT -TC -O2 -c -std:c17 -I"include" src\*.c
if errorlevel 1 (
    popd
    exit /b 1
)

lib -nologo *.obj -out:..\lib\box3d.lib
if errorlevel 1 (
    popd
    exit /b 1
)

cl -nologo -MT -TC -O2 -LD -std:c17 -Dbox3d_EXPORTS -I"include" src\*.c -link -out:..\lib\box3d.dll -implib:..\lib\box3ddll.lib
if errorlevel 1 (
    popd
    exit /b 1
)

del "*.obj"
popd
