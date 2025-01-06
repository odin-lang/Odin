OS=$(shell uname)

ifeq ($(OS), Darwin)
all: darwin
else
all: unix
endif

wasm:
	mkdir -p ../lib
	$(CC) -c -Os --target=wasm32 --sysroot=$(shell odin root)/vendor/libc stb_image.c        -o ../lib/stb_image_wasm.o        -DSTBI_NO_STDIO
	$(CC) -c -Os --target=wasm32 --sysroot=$(shell odin root)/vendor/libc stb_image_write.c  -o ../lib/stb_image_write_wasm.o  -DSTBI_WRITE_NO_STDIO 
	$(CC) -c -Os --target=wasm32 --sysroot=$(shell odin root)/vendor/libc stb_image_resize.c -o ../lib/stb_image_resize_wasm.o
	$(CC) -c -Os --target=wasm32 --sysroot=$(shell odin root)/vendor/libc stb_truetype.c     -o ../lib/stb_truetype_wasm.o
	# $(CC) -c -Os --target=wasm32 --sysroot=$(shell odin root)/vendor/libc stb_vorbis.c       -o ../lib/stb_vorbis_wasm.o       -DSTB_VORBIS_NO_STDIO
	$(CC) -c -Os --target=wasm32 --sysroot=$(shell odin root)/vendor/libc stb_rect_pack.c    -o ../lib/stb_rect_pack_wasm.o
	$(CC) -c -Os --target=wasm32                                          stb_sprintf.c      -o ../lib/stb_sprintf_wasm.o

unix:
	mkdir -p ../lib
	$(CC) -c -O2 -Os -fPIC stb_image.c stb_image_write.c stb_image_resize.c stb_truetype.c stb_rect_pack.c stb_vorbis.c stb_sprintf.c
	$(AR) rcs ../lib/stb_image.a        stb_image.o
	$(AR) rcs ../lib/stb_image_write.a  stb_image_write.o
	$(AR) rcs ../lib/stb_image_resize.a stb_image_resize.o
	$(AR) rcs ../lib/stb_truetype.a     stb_truetype.o
	$(AR) rcs ../lib/stb_rect_pack.a    stb_rect_pack.o
	$(AR) rcs ../lib/stb_vorbis.a       stb_vorbis.o
	$(AR) rcs ../lib/stb_sprintf.a      stb_sprintf.o
	#$(CC) -fPIC -shared -Wl,-soname=stb_image.so         -o ../lib/stb_image.so        stb_image.o
	#$(CC) -fPIC -shared -Wl,-soname=stb_image_write.so   -o ../lib/stb_image_write.so  stb_image_write.o
	#$(CC) -fPIC -shared -Wl,-soname=stb_image_resize.so  -o ../lib/stb_image_resize.so stb_image_resize.o
	#$(CC) -fPIC -shared -Wl,-soname=stb_truetype.so      -o ../lib/stb_truetype.so     stb_image_truetype.o
	#$(CC) -fPIC -shared -Wl,-soname=stb_rect_pack.so     -o ../lib/stb_rect_pack.so    stb_rect_packl.o
	#$(CC) -fPIC -shared -Wl,-soname=stb_vorbis.so        -o ../lib/stb_vorbis.so       stb_vorbisl.o
	rm *.o

darwin:
	mkdir -p ../lib
	$(CC) -arch x86_64 -c -O2 -Os -fPIC stb_image.c -o stb_image-x86_64.o -mmacosx-version-min=10.12
	$(CC) -arch arm64  -c -O2 -Os -fPIC stb_image.c -o stb_image-arm64.o -mmacosx-version-min=10.12
	lipo -create stb_image-x86_64.o stb_image-arm64.o -output ../lib/darwin/stb_image.a
	$(CC) -arch x86_64 -c -O2 -Os -fPIC stb_image_write.c -o stb_image_write-x86_64.o -mmacosx-version-min=10.12
	$(CC) -arch arm64  -c -O2 -Os -fPIC stb_image_write.c -o stb_image_write-arm64.o -mmacosx-version-min=10.12
	lipo -create stb_image_write-x86_64.o stb_image_write-arm64.o -output ../lib/darwin/stb_image_write.a
	$(CC) -arch x86_64 -c -O2 -Os -fPIC stb_image_resize.c -o stb_image_resize-x86_64.o -mmacosx-version-min=10.12
	$(CC) -arch arm64  -c -O2 -Os -fPIC stb_image_resize.c -o stb_image_resize-arm64.o -mmacosx-version-min=10.12
	lipo -create stb_image_resize-x86_64.o stb_image_resize-arm64.o -output ../lib/darwin/stb_image_resize.a
	$(CC) -arch x86_64 -c -O2 -Os -fPIC stb_truetype.c -o stb_truetype-x86_64.o -mmacosx-version-min=10.12
	$(CC) -arch arm64  -c -O2 -Os -fPIC stb_truetype.c -o stb_truetype-arm64.o -mmacosx-version-min=10.12
	lipo -create stb_truetype-x86_64.o stb_truetype-arm64.o -output ../lib/darwin/stb_truetype.a
	$(CC) -arch x86_64 -c -O2 -Os -fPIC stb_rect_pack.c -o stb_rect_pack-x86_64.o -mmacosx-version-min=10.12
	$(CC) -arch arm64  -c -O2 -Os -fPIC stb_rect_pack.c -o stb_rect_pack-arm64.o -mmacosx-version-min=10.12
	lipo -create stb_rect_pack-x86_64.o stb_rect_pack-arm64.o -output ../lib/darwin/stb_rect_pack.a
	$(CC) -arch x86_64 -c -O2 -Os -fPIC stb_vorbis.c -o stb_vorbis-x86_64.o -mmacosx-version-min=10.12
	$(CC) -arch arm64  -c -O2 -Os -fPIC stb_vorbis.c -o stb_vorbis-arm64.o -mmacosx-version-min=10.12
	lipo -create stb_vorbis-x86_64.o stb_vorbis-arm64.o -output ../lib/darwin/stb_vorbis.a
	$(CC) -arch x86_64 -c -O2 -Os -fPIC stb_sprintf.c -o stb_sprintf-x86_64.o -mmacosx-version-min=10.12
	$(CC) -arch arm64  -c -O2 -Os -fPIC stb_sprintf.c -o stb_sprintf-arm64.o -mmacosx-version-min=10.12
	lipo -create stb_sprintf-x86_64.o stb_sprintf-arm64.o -output ../lib/darwin/stb_sprintf.a
	rm *.o
