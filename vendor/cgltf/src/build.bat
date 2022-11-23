@echo off

if not exist "..\lib" mkdir ..\lib

cl -nologo -MT -TC -O2 -c cgltf.c
lib -nologo cgltf.obj -out:..\lib\cgltf.lib

del *.obj
