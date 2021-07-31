@echo off
odin run   . -vet
:odin build . -build-mode:shared -show-timings -o:minimal -use-separate-modules
:odin build . -build-mode:shared -show-timings -o:size -use-separate-modules
:odin build . -build-mode:shared -show-timings -o:speed -use-separate-modules

python test.py
:del big.*