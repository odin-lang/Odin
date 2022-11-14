@echo off

if not exist "..\lib" mkdir ..\lib

cl -nologo -MT -TC -O2 -c lib.c
lib -nologo lib.obj -out:..\lib\miniz.lib

del *.obj
