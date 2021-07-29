@echo off
:odin run   . -vet
odin build . -build-mode:shared -show-timings -o:speed
:odin build . -build-mode:shared -show-timings

python test.py