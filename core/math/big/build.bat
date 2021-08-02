@echo off
odin run . -vet
: -o:size -no-bounds-check
:odin build . -build-mode:shared -show-timings -o:minimal -use-separate-modules
:odin build . -build-mode:shared -show-timings -o:size -use-separate-modules -no-bounds-check
:odin build . -build-mode:shared -show-timings -o:size -use-separate-modules
:odin build . -build-mode:shared -show-timings -o:speed -use-separate-modules -no-bounds-check
:odin build . -build-mode:shared -show-timings -o:speed -use-separate-modules

:python test.py