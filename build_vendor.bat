@echo off

setlocal EnableDelayedExpansion

if not exist "vendor\stb\lib\*.lib" (
	rem build the .lib fiels already exist
	pushd vendor\stb\src
		call build.bat
	popd
)
