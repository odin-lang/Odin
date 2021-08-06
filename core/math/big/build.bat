@echo off
odin run . -vet -o:size
:odin build . -build-mode:shared -show-timings -o:minimal -no-bounds-check
:odin build . -build-mode:shared -show-timings -o:size -no-bounds-check
:odin build . -build-mode:shared -show-timings -o:size
:odin build . -build-mode:shared -show-timings -o:speed -no-bounds-check
:odin build . -build-mode:shared -show-timings -o:speed

:python test.py