@echo off
set TEST_ARGS=-fast-tests
set TEST_ARGS=
set OUT_NAME=test_library
set COMMON=-build-mode:shared -show-timings -no-bounds-check -define:MATH_BIG_EXE=false -vet -strict-style
:odin build . %COMMON% -o:minimal -out:%OUT_NAME% && python test.py %TEST_ARGS%
:odin build . %COMMON% -o:size    -out:%OUT_NAME% && python test.py %TEST_ARGS%
odin build . %COMMON% -o:speed   -out:%OUT_NAME% && python test.py %TEST_ARGS%