@echo off
setlocal

pushd "%~dp0" || exit /b 1

if /I "%VSCMD_ARG_TGT_ARCH%" == "x64" (
	set "vendor_arch=amd64"
) else if /I "%VSCMD_ARG_TGT_ARCH%" == "arm64" (
	set "vendor_arch=arm64"
) else (
	echo ERROR: run this from an MSVC x64 or arm64 native tools command prompt.
	popd
	exit /b 1
)

set "vendor_lib_dir=..\lib\%vendor_arch%"
if not exist "%vendor_lib_dir%" mkdir "%vendor_lib_dir%"

cl -nologo -MT -TC -O2 -c stb_image.c stb_image_write.c stb_image_resize.c stb_truetype.c stb_rect_pack.c stb_vorbis.c stb_sprintf.c
if errorlevel 1 (
    popd
    exit /b 1
)

lib -nologo stb_image.obj -out:"%vendor_lib_dir%\stb_image.lib"
if errorlevel 1 (
    popd
    exit /b 1
)
lib -nologo stb_image_write.obj -out:"%vendor_lib_dir%\stb_image_write.lib"
if errorlevel 1 (
    popd
    exit /b 1
)
lib -nologo stb_image_resize.obj -out:"%vendor_lib_dir%\stb_image_resize.lib"
if errorlevel 1 (
    popd
    exit /b 1
)
lib -nologo stb_truetype.obj -out:"%vendor_lib_dir%\stb_truetype.lib"
if errorlevel 1 (
    popd
    exit /b 1
)
lib -nologo stb_rect_pack.obj -out:"%vendor_lib_dir%\stb_rect_pack.lib"
if errorlevel 1 (
    popd
    exit /b 1
)
lib -nologo stb_vorbis.obj -out:"%vendor_lib_dir%\stb_vorbis.lib"
if errorlevel 1 (
    popd
    exit /b 1
)
lib -nologo stb_sprintf.obj -out:"%vendor_lib_dir%\stb_sprintf.lib"
if errorlevel 1 (
    popd
    exit /b 1
)

del "*.obj"
popd
