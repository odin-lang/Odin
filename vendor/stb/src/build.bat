@echo off
setlocal

pushd "%~dp0" || exit /b 1

rem The libraries are built for the architecture that the MSVC environment targets. The x64 ones go in lib,
rem the arm64 ones (Windows on ARM) in lib\windows_arm64.
set "out_dir=..\lib"
if /I "%VSCMD_ARG_TGT_ARCH%" == "arm64" set "out_dir=..\lib\windows_arm64"
if not exist "%out_dir%" mkdir "%out_dir%"

cl -nologo -MT -TC -O2 -c stb_image.c stb_image_write.c stb_image_resize2.c stb_truetype.c stb_rect_pack.c stb_vorbis.c stb_sprintf.c
if errorlevel 1 (
    popd
    exit /b 1
)

lib -nologo stb_image.obj -out:%out_dir%\stb_image.lib
if errorlevel 1 (
    popd
    exit /b 1
)
lib -nologo stb_image_write.obj -out:%out_dir%\stb_image_write.lib
if errorlevel 1 (
    popd
    exit /b 1
)
lib -nologo stb_image_resize2.obj -out:%out_dir%\stb_image_resize2.lib
if errorlevel 1 (
    popd
    exit /b 1
)
lib -nologo stb_truetype.obj -out:%out_dir%\stb_truetype.lib
if errorlevel 1 (
    popd
    exit /b 1
)
lib -nologo stb_rect_pack.obj -out:%out_dir%\stb_rect_pack.lib
if errorlevel 1 (
    popd
    exit /b 1
)
lib -nologo stb_vorbis.obj -out:%out_dir%\stb_vorbis.lib
if errorlevel 1 (
    popd
    exit /b 1
)
lib -nologo stb_sprintf.obj -out:%out_dir%\stb_sprintf.lib
if errorlevel 1 (
    popd
    exit /b 1
)

del "*.obj"
popd
