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

cl -nologo -MT -TC -O2 -c kb_text_shape.c
if errorlevel 1 (
    popd
    exit /b 1
)

lib -nologo kb_text_shape.obj -out:"%vendor_lib_dir%\kb_text_shape.lib"
if errorlevel 1 (
    popd
    exit /b 1
)

del "*.obj"
popd
