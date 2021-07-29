@echo off
:odin run   . -vet
odin build . -build-mode:dll -show-timings -opt:3
:odin build . -build-mode:dll -show-timings

:dumpbin /EXPORTS big.dll
python test.py