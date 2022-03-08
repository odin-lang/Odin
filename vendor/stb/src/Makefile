all:
	mkdir -p ../lib
	$(CC) -c -O2 -Os -fPIC stb_image.c stb_image_write.c stb_image_resize.c stb_truetype.c stb_rect_pack.c stb_vorbis.c
	$(AR) rcs ../lib/stb_image.a        stb_image.o
	$(AR) rcs ../lib/stb_image_write.a  stb_image_write.o
	$(AR) rcs ../lib/stb_image_resize.a stb_image_resize.o
	$(AR) rcs ../lib/stb_truetype.a     stb_truetype.o
	$(AR) rcs ../lib/stb_rect_pack.a    stb_rect_pack.o
	#$(AR) rcs ../lib/stb_vorbis_pack.a  stb_vorbis_pack.o
	#$(CC) -fPIC -shared -Wl,-soname=stb_image.so         -o ../lib/stb_image.so        stb_image.o
	#$(CC) -fPIC -shared -Wl,-soname=stb_image_write.so   -o ../lib/stb_image_write.so  stb_image_write.o
	#$(CC) -fPIC -shared -Wl,-soname=stb_image_resize.so  -o ../lib/stb_image_resize.so stb_image_resize.o
	#$(CC) -fPIC -shared -Wl,-soname=stb_truetype.so      -o ../lib/stb_truetype.so     stb_image_truetype.o
	#$(CC) -fPIC -shared -Wl,-soname=stb_rect_pack.so     -o ../lib/stb_rect_pack.so    stb_rect_packl.o
	#$(CC) -fPIC -shared -Wl,-soname=stb_vorbis.so        -o ../lib/stb_vorbis.so       stb_vorbisl.o
	rm *.o
