@echo off
odin run . -vet
: -define:MATH_BIG_USE_FROBENIUS_TEST=true

set TEST_ARGS=-fast-tests
:set TEST_ARGS=
:odin build . -build-mode:shared -show-timings -o:minimal -no-bounds-check -define:MATH_BIG_EXE=false && python test.py %TEST_ARGS%
:odin build . -build-mode:shared -show-timings -o:size -no-bounds-check -define:MATH_BIG_EXE=false && python test.py %TEST_ARGS%
:odin build . -build-mode:shared -show-timings -o:size -define:MATH_BIG_EXE=false && python test.py %TEST_ARGS%
:odin build . -build-mode:shared -show-timings -o:speed -no-bounds-check -define:MATH_BIG_EXE=false && python test.py %TEST_ARGS%
:odin build . -build-mode:shared -show-timings -o:speed -define:MATH_BIG_EXE=false && python test.py -fast-tests %TEST_ARGS%