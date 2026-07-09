@echo off

if not exist "..\lib" mkdir ..\lib

cl -nologo -MT -TC -O2 -c -std:c17 -I "include" src\*.c
lib -nologo *.obj -out:..\lib\box3d.lib

del *.obj
