@echo off
rem math/big tests
set PATH_TO_ODIN==..\..\..\..\odin
set TEST_ARGS=-fast-tests
set TEST_ARGS=-no-random
set TEST_ARGS=
set OUT_NAME=math_big_test_library.dll
set COMMON=-build-mode:shared -show-timings -no-bounds-check -define:MATH_BIG_EXE=false -vet -strict-style -define:ODIN_TEST_FANCY=false
echo ---
echo Running core:math/big tests
echo ---

%PATH_TO_ODIN% build . %COMMON% -o:speed -out:%OUT_NAME%
python3 test.py %TEST_ARGS%