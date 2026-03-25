OS=$(shell uname)

ifeq ($(OS), Darwin)
all: darwin
else
all: unix
endif

wasm:
	mkdir -p ../lib
	$(CC) -c -Os --target=wasm32 --sysroot=$(shell odin root)/vendor/libc-shim fast_obj.c -o ../lib/fast_obj_wasm.o

unix:
	mkdir -p ../lib
	$(CC) -c -O2 -Os -fPIC fast_obj.c 	
	$(AR) rcs ../lib/fast_obj.a        fast_obj.o
	rm *.o

darwin:
	mkdir -p ../lib/darwin
	$(CC) -arch x86_64 -c -O2 -Os -fPIC fast_obj.c -o fast_obj-x86_64.o -mmacosx-version-min=10.12
	$(CC) -arch arm64  -c -O2 -Os -fPIC fast_obj.c -o fast_obj-arm64.o -mmacosx-version-min=10.12
	lipo -create fast_obj-x86_64.o fast_obj-arm64.o -output ../lib/darwin/fast_obj.a
	rm *.o
