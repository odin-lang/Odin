@echo off

if not exist "..\lib" mkdir ..\lib

cl -nologo -MT -TC -O2 -c stb_image.c stb_image_write.c stb_image_resize.c stb_truetype.c stb_rect_pack.c stb_vorbis.c stb_sprintf.c
lib -nologo stb_image.obj -out:..\lib\stb_image.lib
lib -nologo stb_image_write.obj -out:..\lib\stb_image_write.lib
lib -nologo stb_image_resize.obj -out:..\lib\stb_image_resize.lib
lib -nologo stb_truetype.obj -out:..\lib\stb_truetype.lib
lib -nologo stb_rect_pack.obj -out:..\lib\stb_rect_pack.lib
lib -nologo stb_vorbis.obj -out:..\lib\stb_vorbis.lib
lib -nologo stb_sprintf.obj -out:..\lib\stb_sprintf.lib

del *.obj
