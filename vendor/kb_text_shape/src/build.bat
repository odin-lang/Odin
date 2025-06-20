@echo off

if not exist "..\lib" mkdir ..\lib

cl -nologo -MT -TC -O2 -c kb_text_shape.c
lib -nologo kb_text_shape.obj -out:..\lib\kb_text_shape.lib

del *.obj
