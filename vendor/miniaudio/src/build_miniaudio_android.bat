@echo off
rem Builds lib\android\<abi>\miniaudio.a for every Android ABI with the NDK's clang.
rem Needs ODIN_ANDROID_NDK to point at an NDK.
setlocal

if "%ODIN_ANDROID_NDK%"=="" (
    echo ODIN_ANDROID_NDK is not set
    exit /b 1
)

rem Odin's minimum Android API level.
set API=29
set BIN=%ODIN_ANDROID_NDK%\toolchains\llvm\prebuilt\windows-x86_64\bin

pushd "%~dp0" || exit /b 1

for %%P in (arm64-v8a:aarch64-linux-android x86_64:x86_64-linux-android armeabi-v7a:armv7a-linux-androideabi x86:i686-linux-android) do (
    for /f "tokens=1,2 delims=:" %%A in ("%%P") do (
        if not exist "..\lib\android\%%A" mkdir "..\lib\android\%%A"
        "%BIN%\clang.exe" --target=%%B%API% -c -O2 -fPIC miniaudio.c -o miniaudio_%%A.o
        if errorlevel 1 (
            popd
            exit /b 1
        )
        "%BIN%\llvm-ar.exe" rcs "..\lib\android\%%A\miniaudio.a" miniaudio_%%A.o
        if errorlevel 1 (
            popd
            exit /b 1
        )
        del miniaudio_%%A.o
    )
)

popd
