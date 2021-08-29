@echo off
:odin run . -vet

set TEST_ARGS=-fast-tests
:odin build . -build-mode:shared -show-timings -o:minimal -no-bounds-check -define:MATH_BIG_EXE=false && python test.py %TEST_ARGS%
odin build . -build-mode:shared -show-timings -o:size -no-bounds-check -define:MATH_BIG_EXE=false && python test.py %TEST_ARGS%
:odin build . -build-mode:shared -show-timings -o:size -define:MATH_BIG_EXE=false && python test.py %TEST_ARGS%
:odin build . -build-mode:shared -show-timings -o:speed -no-bounds-check -define:MATH_BIG_EXE=false && python test.py %TEST_ARGS%
:odin build . -build-mode:shared -show-timings -o:speed -define:MATH_BIG_EXE=false && python test.py -fast-tests %TEST_ARGS%