@echo off

if not exist "..\lib" mkdir "..\lib"

cl -nologo -MT -TC -O2 -c fast_obj.c
lib -nologo fast_obj.obj -out:..\lib\fast_obj.lib

del *.obj
