@echo off
setlocal

if /I "%VSCMD_ARG_TGT_ARCH%" == "arm64" (
	set abi_arch=arm64
) else if /I "%VSCMD_ARG_TGT_ARCH%" == "x64" (
	set abi_arch=x64
) else (
	echo ERROR: run this from an MSVC x64 or arm64 native tools command prompt.
	exit /b 1
)

pushd "%~dp0"
if not exist "bin\%abi_arch%" mkdir "bin\%abi_arch%"

cl /nologo /LD /O2 /MT /W4 /WX abi_fixture.c ^
	/link /OUT:"bin\%abi_arch%\odin_windows_abi.dll" ^
	/IMPLIB:"bin\%abi_arch%\odin_windows_abi.lib"
if errorlevel 1 goto failed

"%~dp0..\..\..\odin.exe" test . -out:"bin\%abi_arch%\odin_windows_abi_test.exe" ^
	-define:ODIN_TEST_FANCY=false -vet -strict-style
if errorlevel 1 goto failed

popd
exit /b 0

:failed
popd
exit /b 1
