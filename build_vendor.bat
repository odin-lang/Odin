@echo off

setlocal EnableDelayedExpansion

rem Build the vendor .lib files that don't exist yet, for the architecture that the MSVC environment targets.
rem The x64 libraries are in each package's lib directory, the arm64 ones (Windows on ARM) in lib\windows_arm64.
set lib_dir=lib
if /I "%VSCMD_ARG_TGT_ARCH%" == "arm64" set lib_dir=lib\windows_arm64

for %%p in (stb miniaudio cgltf kb_text_shape) do (
	if not exist "vendor\%%p\%lib_dir%\*.lib" (
		call vendor\%%p\src\build.bat
		if errorlevel 1 exit /b 1
	)
)
