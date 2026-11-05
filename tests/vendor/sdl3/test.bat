@echo off
setlocal enabledelayedexpansion

rem Tests that `vendor:sdl3` and its satellite libraries (SDL3_image, SDL3_mixer, SDL3_net, SDL3_ttf) link, and prints their versions.
rem The versions of the DLLs must be the ones the bindings were written for. The DLLs, and the DLLs they need, are copied next to the
rem tests first, and the .gitignore in this directory keeps them out of the repository.
rem Every library has its own test-*.odin file, which is tested on its own.

cd /d "%~dp0"

set "VENDOR=%~dp0..\..\..\vendor\sdl3"
for %%d in ("%VENDOR%" "%VENDOR%\image" "%VENDOR%\mixer" "%VENDOR%\net" "%VENDOR%\ttf") do copy /y "%%~d\*.dll" "%~dp0" >nul

set "FAILED="
for %%f in (test-*.odin) do (
	echo.
	echo ==== %%f
	odin test %%f -file -vet -vet-tabs -strict-style -vet-style -warnings-as-errors -disallow-do -define:ODIN_TEST_FANCY=false -define:ODIN_TEST_FAIL_ON_BAD_MEMORY=true > "%%~nf.log" 2>&1
	set "CODE=!ERRORLEVEL!"
	type "%%~nf.log"
	rem A test that could not even start, for example because a DLL is missing, does not make `odin test` fail: it has to say it finished.
	findstr /c:"Finished" "%%~nf.log" >nul || set "CODE=1"
	if not "!CODE!"=="0" set "FAILED=!FAILED! %%f"
	del /q "%%~nf.exe" "%%~nf.pdb" "%%~nf.log" 2>nul
)

del /q *.dll
echo.
if defined FAILED (
	echo FAILED:%FAILED%
	exit /b 1
)
echo All SDL3 tests passed.
exit /b 0
