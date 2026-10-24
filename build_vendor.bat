@echo off

setlocal EnableDelayedExpansion

rem build the .lib files already exist

if not exist "vendor\stb\lib\*.lib" (
	pushd vendor\stb\src
		call build.bat
	popd
)

if not exist "vendor\miniaudio\lib\*.lib" (
	pushd vendor\miniaudio\src
		call build.bat
	popd
)


if not exist "vendor\cgltf\lib\*.lib" (
	pushd vendor\cgltf\src
		call build.bat
	popd
)

if not exist "vendor\commonmark\*.lib" (
	pushd vendor\commonmark
		call build.bat
	popd
)

if not exist "vendor\box3d\lib\*.lib" (
	pushd vendor\box3d\src
		call build.bat
	popd
)

if not exist "vendor\kb_text_shape\lib\*.lib" (
	pushd vendor\kb_text_shape\src
		call build.bat
	popd
)
