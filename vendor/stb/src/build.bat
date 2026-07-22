@echo off
setlocal

pushd "%~dp0" || exit /b 1

if not exist "..\lib" mkdir "..\lib"

cl -nologo -MT -TC -O2 -c stb_image.c stb_image_write.c stb_image_resize.c stb_truetype.c stb_rect_pack.c stb_vorbis.c stb_sprintf.c
if errorlevel 1 (
    popd
    exit /b 1
)

lib -nologo stb_image.obj -out:..\lib\stb_image.lib
if errorlevel 1 (
    popd
    exit /b 1
)
lib -nologo stb_image_write.obj -out:..\lib\stb_image_write.lib
if errorlevel 1 (
    popd
    exit /b 1
)
lib -nologo stb_image_resize.obj -out:..\lib\stb_image_resize.lib
if errorlevel 1 (
    popd
    exit /b 1
)
lib -nologo stb_truetype.obj -out:..\lib\stb_truetype.lib
if errorlevel 1 (
    popd
    exit /b 1
)
lib -nologo stb_rect_pack.obj -out:..\lib\stb_rect_pack.lib
if errorlevel 1 (
    popd
    exit /b 1
)
lib -nologo stb_vorbis.obj -out:..\lib\stb_vorbis.lib
if errorlevel 1 (
    popd
    exit /b 1
)
lib -nologo stb_sprintf.obj -out:..\lib\stb_sprintf.lib
if errorlevel 1 (
    popd
    exit /b 1
)

del "*.obj"
popd
