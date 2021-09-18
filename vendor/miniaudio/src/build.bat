@echo off

if not exist "..\lib" mkdir ..\lib

cl -nologo -MT -TC -O2 -c miniaudio.c
lib -nologo miniaudio.obj -out:..\lib\miniaudio.lib

del *.obj
