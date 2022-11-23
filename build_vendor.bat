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
