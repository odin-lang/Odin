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

set "box2d_version=3.1.1"
set "archive=build\v%box2d_version%.tar.gz"
set "source_dir=build\box2d-%box2d_version%"
set "common_flags=-G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreaded -DBOX2D_SAMPLES=OFF -DBOX2D_BENCHMARKS=OFF -DBOX2D_DOCS=OFF -DBOX2D_PROFILE=OFF -DBOX2D_VALIDATE=OFF -DBOX2D_UNIT_TESTS=OFF"

if not exist "build" mkdir "build"
if not exist "%source_dir%\CMakeLists.txt" (
	echo Downloading Box2D %box2d_version%...
	curl.exe -fL "https://github.com/erincatto/box2d/archive/refs/tags/v%box2d_version%.tar.gz" -o "%archive%"
	if errorlevel 1 goto :error
	cmake -E tar xzf "%archive%"
	if errorlevel 1 goto :error
	move "box2d-%box2d_version%" "%source_dir%" >nul
	if errorlevel 1 goto :error
)

if not exist "lib\%vendor_arch%" mkdir "lib\%vendor_arch%"

if /I "%VSCMD_ARG_TGT_ARCH%" == "arm64" (
	call :build_one "build\windows-arm64" OFF "lib\arm64\box2d_windows_arm64.lib"
	if errorlevel 1 goto :error
) else (
	call :build_one "build\windows-amd64-avx2" ON "lib\amd64\box2d_windows_amd64_avx2.lib"
	if errorlevel 1 goto :error
	call :build_one "build\windows-amd64-sse2" OFF "lib\amd64\box2d_windows_amd64_sse2.lib"
	if errorlevel 1 goto :error
)

echo Box2D %box2d_version% %vendor_arch% build complete.
popd
exit /b 0

:build_one
set "build_dir=%~1"
set "box2d_avx2=%~2"
set "output_lib=%~3"

cmake -S "%source_dir%" -B "%build_dir%" %common_flags% -DBOX2D_AVX2=%box2d_avx2%
if errorlevel 1 exit /b 1
cmake --build "%build_dir%"
if errorlevel 1 exit /b 1
copy /Y "%build_dir%\src\box2d.lib" "%output_lib%" >nul
if errorlevel 1 exit /b 1
exit /b 0

:error
echo ERROR: Box2D build failed.
popd
exit /b 1
