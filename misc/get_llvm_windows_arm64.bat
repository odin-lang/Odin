@echo off

rem Fetches the arm64 build of LLVM-C (LLVM-C.dll and its import library LLVM-C.lib), which `build.bat` links
rem a native Windows arm64 Odin compiler against, into `bin\llvm\windows-arm64`. The x64 build of the same
rem LLVM version is part of the repository (`LLVM-C.dll` and `bin\llvm\windows\LLVM-C.lib`).
rem
rem Only LLVM-C is kept from the official release archive, which is downloaded to %TEMP% once (about 740 MB).

setlocal

set LLVM_VERSION=22.1.8
set LLVM_NAME=clang+llvm-%LLVM_VERSION%-aarch64-pc-windows-msvc
set LLVM_SHA256=de718c58ebbc5f61d58c17b90457fcf42983bc2c4a4aba3e010d108713bfd7f1
set LLVM_URL=https://github.com/llvm/llvm-project/releases/download/llvmorg-%LLVM_VERSION%/%LLVM_NAME%.tar.xz

set OUT_DIR=%~dp0..\bin\llvm\windows-arm64
set CACHE_DIR=%TEMP%\odin-llvm-arm64
set ARCHIVE=%CACHE_DIR%\%LLVM_NAME%.tar.xz

rem The LLVM version the files in OUT_DIR come from, so that they are replaced when LLVM_VERSION changes.
set VERSION_FILE=%OUT_DIR%\LLVM-C.version
set HAVE_VERSION=
if exist "%VERSION_FILE%" set /p HAVE_VERSION=<"%VERSION_FILE%"
if exist "%OUT_DIR%\LLVM-C.dll" if exist "%OUT_DIR%\LLVM-C.lib" if "%HAVE_VERSION%" == "%LLVM_VERSION%" (
	echo LLVM-C %LLVM_VERSION% for arm64 is already in %OUT_DIR%
	exit /b 0
)

if not exist "%CACHE_DIR%" mkdir "%CACHE_DIR%"
if not exist "%ARCHIVE%" (
	echo Downloading %LLVM_URL%
	curl.exe -L --fail --retry 3 -o "%ARCHIVE%.part" "%LLVM_URL%" || exit /b 1
	move /Y "%ARCHIVE%.part" "%ARCHIVE%" > NUL || exit /b 1
)

set HASH=
for /f "skip=1 delims=" %%h in ('certutil -hashfile "%ARCHIVE%" SHA256') do (
	if not defined HASH set "HASH=%%h"
)
set "HASH=%HASH: =%"
if /I not "%HASH%" == "%LLVM_SHA256%" (
	echo ERROR: %ARCHIVE% has the SHA-256 %HASH%, expected %LLVM_SHA256%
	echo        Delete it to download it again.
	exit /b 1
)

echo Extracting LLVM-C.dll and LLVM-C.lib
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"
"%SystemRoot%\System32\tar.exe" -xf "%ARCHIVE%" -C "%CACHE_DIR%" "%LLVM_NAME%/bin/LLVM-C.dll" "%LLVM_NAME%/lib/LLVM-C.lib" || exit /b 1
copy /Y "%CACHE_DIR%\%LLVM_NAME%\bin\LLVM-C.dll" "%OUT_DIR%\" > NUL || exit /b 1
copy /Y "%CACHE_DIR%\%LLVM_NAME%\lib\LLVM-C.lib" "%OUT_DIR%\" > NUL || exit /b 1
rmdir /S /Q "%CACHE_DIR%\%LLVM_NAME%"
> "%VERSION_FILE%" echo %LLVM_VERSION%

echo LLVM-C %LLVM_VERSION% for arm64 is in %OUT_DIR%
