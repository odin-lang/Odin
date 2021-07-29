@echo off
:odin run   . -vet
odin build . -build-mode:dll

:dumpbin /EXPORTS big.dll
python test.py