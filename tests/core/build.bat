@echo off
set COMMON=-show-timings -no-bounds-check -vet -strict-style
set PATH_TO_ODIN==..\..\odin
python3 download_assets.py
echo ---
echo Running core:image tests
echo ---
%PATH_TO_ODIN% test image    %COMMON%
del image.exe

echo ---
echo Running core:compress tests
echo ---
%PATH_TO_ODIN% test compress %COMMON%
del compress.exe

echo ---
echo Running core:strings tests
echo ---
%PATH_TO_ODIN% test strings %COMMON%
del strings.exe


rem math/big tests
set TEST_ARGS=-fast-tests
set TEST_ARGS=
set OUT_NAME=math_big_test_library
set COMMON=-build-mode:shared -show-timings -no-bounds-check -define:MATH_BIG_EXE=false -vet -strict-style
echo ---
echo Running core:math/big tests
echo ---

%PATH_TO_ODIN% build math/big %COMMON% -o:speed -out:%OUT_NAME%
python3 math/big/test.py %TEST_ARGS%
del %OUT_NAME%.*